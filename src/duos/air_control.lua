---@meta _


local AIR_CONTROL_DASH = { 'WeaponBlink', 'WeaponSprint' }


function air_control_fired_weapons()
	local weapons = game.ConcatTableValues({}, game.WeaponSets.HeroNonPhysicalWeapons)
	return game.ConcatTableValues(weapons, AIR_CONTROL_DASH)
end


local function air_control_is_dash(weaponName)
	return weaponName ~= nil and game.Contains(AIR_CONTROL_DASH, weaponName)
end


register_duo({
	key = 'AirControl',

	StatLines = { 'SWuAirControlStatDisplay' },
	ExtractValues = {
		{ Key = 'SWuBoltDamage', ExtractAs = 'TooltipBoltDamage' },
	},

	ExtraFields = {
		SWuBoltDamage = mod.tuning.AirControl.BoltDamage,

		EnemyProjectileSpeedMultiplier = {
			BaseValue = mod.tuning.AirControl.ProjectileSpeed,
			SourceIsMultiplier = true,
		},

		OnBlockDamageFunction = {
			Name = _PLUGIN.guid .. '.AirControlBlock',
			Args = {
				ProjectileName = mod.tuning.AirControl.GuardProjectile,
			},
		},

		OnWeaponFiredFunctions = {
			ValidWeapons = air_control_fired_weapons(),
			ValidWeaponsLookup = game.ToLookup(air_control_fired_weapons()),
			FunctionName = _PLUGIN.guid .. '.AirControlFired',
		},

		OnProjectileDeathFunction = {
			ValidProjectiles = { 'ProjectileCast' },
			ValidProjectilesLookup = game.ToLookup({ 'ProjectileCast' }),
			Name = _PLUGIN.guid .. '.AirControlCastEnd',
		},

		SetupFunction = {
			Threaded = true,
			Name = _PLUGIN.guid .. '.AirControl',
			RepeatOnEncounterStart = true,
			Args = { Interval = mod.tuning.AirControl.PollInterval },
		},
	},
})


function mod.AirControlStretchFuse(args)
	if not args or not args.Name then return args end

	local multiplier = args.SpeedMultiplier
	if type(multiplier) ~= 'number' or multiplier <= 0 or multiplier >= 1 then return args end
	if not game.Contains(mod.tuning.AirControl.StretchFuseProjectiles, args.Name) then return args end
	if not duo_on('AirControl') or not game.HeroHasTrait(duo_traits.AirControl) then return args end

	local properties = game.ShallowCopyTable(args.DataProperties or {})
	local fuse = properties.Fuse or game.GetBaseDataValue({ Type = 'Projectile', Name = args.Name, Property = 'Fuse' })
	if type(fuse) ~= 'number' or fuse <= 0 then return args end

	properties.Fuse = fuse / multiplier
	local stretched = game.ShallowCopyTable(args)
	stretched.DataProperties = properties
	return stretched
end


once('AirControlStretchFuse', function()
	modutil.mod.Path.Wrap('CreateProjectileFromUnit', function(base, args)
		return base(mod.AirControlStretchFuse(args))
	end)
end)


local AIR_CONTROL_GUARD = mod.tuning.AirControl.GuardProjectile
local airControlChannelId = nil
local airControlSprintId = nil
local airControlSprintLeft = 0

airControlCastGuards = {}


local function air_control_channelling()
	if not game.MapState.ShowManaChargeIndicator then return false end

	for weaponName in pairs(game.MapState.ChargedManaWeapons or {}) do
		if game.GetWeaponChargeFraction({ Name = weaponName }) > 0 then return true end
	end
	return false
end


local function air_control_raise()
	if airControlChannelId then return end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end

	airControlChannelId = game.CreateProjectileFromUnit({
		Name = AIR_CONTROL_GUARD,
		Id = hero.ObjectId,
		DestinationId = hero.ObjectId,
		FireFromTarget = true,
		DataProperties = { AttachToOwner = true },
	})

	if airControlChannelId then
		game.SetAnimation({ DestinationId = airControlChannelId, Name = 'Blank' })
	end
end


local function air_control_cast_guards_prune(all)
	for i = #airControlCastGuards, 1, -1 do
		local held = airControlCastGuards[i]
		if all or (held.Cast and not game.ProjectileExists({ Id = held.Cast })) then
			game.ExpireProjectiles({ ProjectileIds = { held.Guard } })
			if held.Anchor then game.Destroy({ Id = held.Anchor }) end
			table.remove(airControlCastGuards, i)
		end
	end
end


local function air_control_drop()
	if not airControlChannelId then return end
	game.ExpireProjectiles({ ProjectileIds = { airControlChannelId } })
	airControlChannelId = nil
end


local function air_control_sprint_drop()
	if not airControlSprintId then return end

	game.ExpireProjectiles({ ProjectileIds = { airControlSprintId } })
	airControlSprintId = nil

	local hero = game.CurrentRun and game.CurrentRun.Hero
	local buff = mod.tuning.AirControl.SprintBuffVfx
	if hero and buff then
		game.StopAnimation({ Name = buff, DestinationId = hero.ObjectId })
	end
end


local function air_control_sprint_guard()
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end

	airControlSprintLeft = mod.tuning.AirControl.SprintLinger
	if airControlSprintId and game.ProjectileExists({ Id = airControlSprintId }) then return end

	airControlSprintId = game.CreateProjectileFromUnit({
		Name = AIR_CONTROL_GUARD,
		Id = hero.ObjectId,
		DestinationId = hero.ObjectId,
		FireFromTarget = true,
		DataProperties = { AttachToOwner = true },
	})

	if not airControlSprintId then return end

	game.SetAnimation({ DestinationId = airControlSprintId, Name = 'Blank' })

	local buff = mod.tuning.AirControl.SprintBuffVfx
	if buff then
		game.StopAnimation({ Name = buff, DestinationId = hero.ObjectId, PreventChain = true })
		game.CreateAnimation({ Name = buff, DestinationId = hero.ObjectId })
	end
end


function mod.AirControl(_hero, args)
	local interval = (args and args.Interval) or mod.tuning.AirControl.PollInterval
	local loop = duo_loop_claim(duo_traits.AirControl)
	if not loop then return end

	local last = game._worldTime

	while duo_running(duo_traits.AirControl) do
		local now = game._worldTime
		local elapsed = (now - last) * game._elapsedTimeMultiplier
		last = now

		local channelling = duo_on('AirControl') and air_control_channelling()

		if channelling then
			air_control_raise()
		else
			air_control_drop()
		end

		air_control_cast_guards_prune(false)

		if airControlSprintId and not game.SessionMapState.SprintActive then
			airControlSprintLeft = airControlSprintLeft - elapsed
			if airControlSprintLeft <= 0 then air_control_sprint_drop() end
		end

		game.wait(interval, loop)
	end

	air_control_drop()
	air_control_sprint_drop()
	air_control_cast_guards_prune(true)
end


---@diagnostic disable-next-line: unused-local
function mod.AirControlFired(weaponData, args, triggerArgs)
	if not duo_on('AirControl') then return end

	if air_control_is_dash(weaponData and weaponData.Name) then
		air_control_sprint_guard()
		return
	end

	mod.AirControlCast(weaponData, args, triggerArgs)
end


---@diagnostic disable-next-line: unused-local
function mod.AirControlCast(_weaponData, _args, triggerArgs)
	if not duo_on('AirControl') then return end
	if not triggerArgs or not triggerArgs.ProjectileX or not triggerArgs.ProjectileY then return end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end

	local properties = { StartDelay = mod.tuning.AirControl.CastStartDelay, AttachToOwner = false }
	if game.HeroHasTrait('SelfCastBoon') and game.IsControlDown({ Name = 'Attack1' })
		and not triggerArgs.UnitIdOverride then
		properties.AttachToOwner = true
		properties.IgnoreCancelAttachedProjectiles = true
	end

	local anchorId = game.SpawnObstacle({
		Name = 'InvisibleTarget',
		LocationX = triggerArgs.ProjectileX,
		LocationY = triggerArgs.ProjectileY,
	})

	local guardId = game.CreateProjectileFromUnit({
		Name = AIR_CONTROL_GUARD,
		Id = hero.ObjectId,
		DestinationId = anchorId,
		FireFromTarget = true,
		DataProperties = properties,
		BlastRadiusModifier = game.GetProjectileProperty({
			ProjectileId = triggerArgs.ProjectileId,
			Property = 'BlastRadiusModifier',
		}),
	})

	if guardId then
		local baseDuration = game.GetBaseDataValue({ Type = 'Projectile', Name = 'ProjectileCast', Property = 'FuseStart' })
		for _, modifiers in pairs(game.GetHeroTraitValues('CastProjectileModifiers')) do
			game.SetDamageRadiusMultiplier({ Id = guardId, Fraction = modifiers.AreaIncrease, Duration = baseDuration })
		end
		table.insert(airControlCastGuards, { Guard = guardId, Anchor = anchorId, Cast = triggerArgs.ProjectileId })
	elseif anchorId then
		game.Destroy({ Id = anchorId })
	end
end


---@diagnostic disable-next-line: unused-local
function mod.AirControlCastEnd(_projectile, _args, _triggerArgs)
	for _, held in ipairs(airControlCastGuards) do
		game.ExpireProjectiles({ ProjectileIds = { held.Guard } })
		if held.Anchor then game.Destroy({ Id = held.Anchor }) end
	end

	airControlCastGuards = {}
end


---@diagnostic disable-next-line: unused-local
function mod.AirControlBlock(_victim, functionArgs, triggerArgs)
	if not duo_on('AirControl') then return end
	if not triggerArgs or triggerArgs.BlockingProjectileName ~= functionArgs.ProjectileName then return end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	local attacker = triggerArgs.Attacker
	if not hero or not attacker or not attacker.ObjectId then return end
	if attacker == hero or attacker.IsDead or duo_ignores(attacker) then return end
	if game.IsUntargetable({ Id = attacker.ObjectId }) then return end
	local tuning = mod.tuning.AirControl
	if not game.CheckCooldown('SWuAirControl' .. attacker.ObjectId, tuning.BlockCooldown) then return end
	local base = game.GetBaseDataValue({ Type = 'Projectile', Name = 'ZeusRetaliateStrike', Property = 'Damage' })
	if type(base) ~= 'number' or base <= 0 then base = 100 end

	game.thread(game.CreateZeusBolt, {
		SourceId = hero.ObjectId,
		TargetId = attacker.ObjectId,
		ProjectileName = 'ZeusRetaliateStrike',
		DamageMultiplier = tuning.BoltDamage / base,
		Range = 1,
		SeekTarget = true,
		Delay = 0.15,
		Count = 1,
	})
end
