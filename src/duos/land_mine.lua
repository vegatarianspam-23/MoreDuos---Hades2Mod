---@meta _


local BLAST = mod.tuning.LandMine.BlastProjectile


once('LandMineBlast', function()
	duo_alias_projectile('MassiveSlamBlast', BLAST)
end)


register_duo({
	key = 'LandMine',

	StatLines = mod.tuning.LandMine.UseFixedManaCost
		and { 'SWuLandMineManaStatDisplay', 'SWuLandMineRechargeStatDisplay' }
		or { 'SWuLandMineFuseStatDisplay', 'SWuLandMineRechargeStatDisplay' },
	ExtractValues = {
		mod.tuning.LandMine.UseFixedManaCost
			and { Key = 'SWuManaCost', ExtractAs = 'TooltipManaCost' }
			or { Key = 'SWuTriggerFuse', ExtractAs = 'TooltipFuse', DecimalPlaces = 1 },
		{ Key = 'SWuRecharge', ExtractAs = 'TooltipRecharge' },
		{ Key = 'SWuBlastDamage', ExtractAs = 'TooltipBlastDamage', SkipAutoExtract = true },
	},

	ExtraFields = {
		SWuManaCost = mod.tuning.LandMine.OmegaCastManaCost,
		SWuTriggerFuse = mod.tuning.LandMine.TriggerFuse,
		SWuRecharge = mod.tuning.LandMine.Recharge,
		SWuBlastDamage = mod.tuning.LandMine.BlastDamage,

		OnProjectileCreationFunction = {
			ValidProjectiles = { 'ProjectileCast' },
			ValidProjectilesLookup = game.ToLookup({ 'ProjectileCast' }),
			Name = _PLUGIN.guid .. '.LandMineArmed',
		},

		OnProjectileDeathFunction = {
			ValidProjectiles = { 'ProjectileCast' },
			ValidProjectilesLookup = game.ToLookup({ 'ProjectileCast' }),
			Name = _PLUGIN.guid .. '.LandMineDetonated',
		},

		SetupFunction = {
			Threaded = true,
			Name = _PLUGIN.guid .. '.LandMine',
			RepeatOnEncounterStart = true,
			Args = { Interval = 0.2 },
		},
	},
})


---@diagnostic disable-next-line: unused-local
function mod.LandMineArmed(triggerArgs, _args)
	if not duo_on('LandMine') then return end
	if not triggerArgs or not triggerArgs.ProjectileId then return end

	game.SessionMapState.SWuLandMines = game.SessionMapState.SWuLandMines or {}
	game.SessionMapState.SWuLandMines[triggerArgs.ProjectileId] = true
end


local function land_mine_cost()
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return 0 end

	local tuning = mod.tuning.LandMine
	if tuning.UseFixedManaCost then return tuning.OmegaCastManaCost end

	local armData = game.GetWeaponData(hero, 'WeaponCastArm')
	if not armData then return 0 end
	return game.GetManaCost(armData, false) or 0
end


local function land_mine_blast_multiplier()
	local base = game.GetBaseDataValue({ Type = 'Projectile', Name = BLAST, Property = 'Damage' })
	if type(base) ~= 'number' or base <= 0 then return 1 end
	return mod.tuning.LandMine.BlastDamage / base
end


local function land_mine_blast(x, y, radius)
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return nil end

	local centerId = game.SpawnObstacle({ Name = 'BlankObstacle', LocationX = x, LocationY = y })
	local blastId = game.CreateProjectileFromUnit({
		Name = BLAST,
		Id = hero.ObjectId,
		DestinationId = centerId,
		FireFromTarget = true,
		CollideWithGroups = { 'EnemyTeam' },
		DamageMultiplier = land_mine_blast_multiplier(),
		DataProperties = { DamageRadius = radius * mod.tuning.LandMine.BlastSize },
	})
	game.CreateAnimation({ Name = 'HephMassiveHit', DestinationId = centerId })
	game.thread(game.DestroyOnDelay, { centerId }, 2)

	return blastId
end


local function land_mine_erupt(projectileId, via, triggerArgs)
	if not duo_on('LandMine') then return end

	local tripped = game.SessionMapState.SWuLandMineTripped
	local mine = tripped and tripped[projectileId]
	if not mine then return end
	tripped[projectileId] = nil

	local x = (triggerArgs and triggerArgs.LocationX) or mine.X
	local y = (triggerArgs and triggerArgs.LocationY) or mine.Y
	local blastId = land_mine_blast(x, y, mine.Radius)
end


local function land_mine_await(projectileId)
	local waited = 0
	while game.ProjectileExists({ Id = projectileId }) do
		if waited >= 10 then
			local tripped = game.SessionMapState.SWuLandMineTripped
			if tripped then tripped[projectileId] = nil end
			return
		end
		game.wait(0.05, game.RoomThreadName)
		waited = waited + 0.05
	end

	game.wait(0.1, game.RoomThreadName)
	land_mine_erupt(projectileId, 'watch')
end


local function land_mine_trip(projectileId, cost, location, radius)
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end

	local tuning = mod.tuning.LandMine

	if cost > 0 then
		game.ManaDelta(-cost)
	end

	game.SessionMapState.SWuLandMineTripped = game.SessionMapState.SWuLandMineTripped or {}
	game.SessionMapState.SWuLandMineTripped[projectileId] = { X = location.X, Y = location.Y, Radius = radius }

	local supercharge = game.SessionMapState.SuperchargeCast
	if game.HeroHasTrait('ApolloExCastBoon') and game.HeroHasTrait('ApolloSecondStageCastBoon') then
		game.SessionMapState.SuperchargeCast = true
	end

	game.RunWeaponMethod({ Id = hero.ObjectId, Weapon = 'WeaponCastArm', Method = 'ArmProjectiles' })

	game.SessionMapState.SuperchargeCast = supercharge

	game.SetProjectileProperty({
		ProjectileId = projectileId,
		Property = 'Fuse',
		Value = tuning.TriggerFuse,
	})

	game.Flash({
		Id = projectileId,
		Speed = tuning.FlashSpeed,
		MinFraction = 0,
		MaxFraction = 0.5,
		Color = game.Color.Yellow,
		Duration = tuning.TriggerFuse,
	})
	game.PlaySound({ Name = tuning.ReadySound, Id = projectileId })

	game.thread(land_mine_await, projectileId)
end


local landMineWasReady = true


local function land_mine_recharge()
	local tuning = mod.tuning.LandMine
	local seconds = tuning.Recharge

	if game.HeroHasTrait('MassiveCastBoon') then
		seconds = seconds - tuning.SeismicHammerReduction
	end

	return duo_recharge(seconds, tuning.MinimumRecharge)
end


local function land_mine_announce()
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end

	local tuning = mod.tuning.LandMine
	local ready = game.CheckCooldownNoTrigger('SWuLandMine', land_mine_recharge())

	if ready and not landMineWasReady then
		game.PlaySound({ Name = tuning.ReadySound, Id = hero.ObjectId })
		game.thread(game.InCombatTextArgs, {
			TargetId = hero.ObjectId,
			Text = 'SWuLandMine_CombatText',
			Duration = 1.45,
			PreDelay = 0.1,
		})
	end
	landMineWasReady = ready
end


local function land_mine_watch()
	land_mine_announce()

	local mines = game.SessionMapState.SWuLandMines
	if not mines then return end

	local ids = {}
	for projectileId in pairs(mines) do
		table.insert(ids, projectileId)
	end

	for _, projectileId in ipairs(ids) do
		if not game.ProjectileExists({ Id = projectileId }) then
			mines[projectileId] = nil
		else
			local location = game.GetLocation({ IsProjectile = true, Id = projectileId })
			local radius = game.GetProjectileProperty({ ProjectileId = projectileId, Property = 'ModifiedDamageRadius' })

			if location and radius then
				local centerId = game.SpawnObstacle({ Name = 'InvisibleTarget', LocationX = location.X, LocationY = location.Y })
				local caught = land_mine_caught(centerId, radius)
				game.Destroy({ Id = centerId })

				local hero = game.CurrentRun.Hero
				local cost = land_mine_cost()

				if not game.IsEmpty(caught) and (hero.Mana or 0) >= cost
					and game.CheckCooldown('SWuLandMine', land_mine_recharge()) then

					mines[projectileId] = nil
					land_mine_trip(projectileId, cost, location, radius)
				end
			end
		end
	end
end


function mod.LandMine(_hero, args)
	local interval = (args and args.Interval) or 0.2
	local loop = duo_loop_claim(duo_traits.LandMine)
	if not loop then return end

	while duo_running(duo_traits.LandMine) do
		if duo_on('LandMine') then
			land_mine_watch()
		end
		game.wait(interval, loop)
	end
end


function land_mine_caught(centerId, radius)
	local caught = game.GetClosestIds({
		Id = centerId,
		DestinationName = 'EnemyTeam',
		IgnoreInvulnerable = true,
		IgnoreHomingIneligible = true,
		Distance = radius,
		PreciseCollision = true,
	}) or {}

	local seen = {}
	for _, id in pairs(caught) do
		seen[id] = true
	end

	for id, unit in pairs(game.ActiveEnemies or {}) do
		if not seen[id] and land_mine_reaches(centerId, unit, radius) then
			table.insert(caught, id)
			seen[id] = true
		end
	end

	return caught
end


function land_mine_reaches(centerId, unit, radius)
	if not unit or not unit.ObjectId or unit.IsDead then return false end
	if duo_ignores(unit) or is_allied_summon(unit) then return false end
	if game.IsInvulnerable({ Id = unit.ObjectId }) then return false end

	local distance = game.GetDistance({ Id = centerId, DestinationId = unit.ObjectId })
	if not distance then return false end

	return distance <= radius + (unit.BlockOverheadSize or unit.Radius or 0)
end


function mod.LandMineDetonated(triggerArgs)
	if not triggerArgs or not triggerArgs.ProjectileId then return end
	land_mine_erupt(triggerArgs.ProjectileId, 'death', triggerArgs)
end
