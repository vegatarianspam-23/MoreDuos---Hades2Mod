---@meta _


local function blood_born_ring()
	return mod.tuning.BloodBorn.RingSummon == true
end


local function blood_born_spec()
	local tuning = mod.tuning.BloodBorn

	local extraFields = {
		SWuDamagePerKill = tuning.DamagePerKill,
		SWuMaxBonus = tuning.MaxBonus,
		SWuRaiseChance = tuning.RaiseChance,

		LoadPackages = tuning.ZombiePackages,

		ShowInHUD = true,
		CustomLabel = {
			DisplayType = 'RoomValue',
			Key = 'SWuBloodBornPercent',
			Text = 'UI_TimedKillBuff',
		},

		OnEnemyDeathFunction = {
			Name = _PLUGIN.guid .. '.BloodBornSlain',
		},

		SetupFunction = {
			Name = _PLUGIN.guid .. '.BloodBornSetup',
			RepeatOnEncounterStart = true,
		},
	}

	extraFields.OnSelfDamagedFunction = { Name = _PLUGIN.guid .. '.BloodBornHit' }

	return {
		StatLines = blood_born_ring()
			and { 'SWuBloodBornStatDisplay' }
			or { 'SWuBloodBornStatDisplay', 'SWuBloodBornRaiseStatDisplay' },

		ExtractValues = with_keyword_extracts({
			{
				Key = 'SWuDamagePerKill',
				ExtractAs = 'TooltipPerKill',
				Format = 'Percent',
			},
			{ Key = 'SWuRaiseChance', ExtractAs = 'TooltipRaiseChance', Format = 'Percent',
				SkipAutoExtract = blood_born_ring() or nil },
			{ Key = 'SWuMaxBonus', ExtractAs = 'TooltipMaxBonus', Format = 'Percent', SkipAutoExtract = true },
		}, tuning.Hitch and 'Link' or nil),

		ExtraFields = extraFields,
	}
end


local spec = blood_born_spec()
spec.key = 'BloodBorn'
register_duo(spec)


function mod.BloodBornSetup()
	game.LoadPackages({ Names = mod.tuning.BloodBorn.ZombiePackages })

	local room = game.CurrentRun and game.CurrentRun.CurrentRoom
	if room and mod.tuning.BloodBorn.PerEncounter then
		room.SWuBloodBornKills = 0
	end
	blood_born_set_bonus((room and room.SWuBloodBornKills) or 0)
end


local function blood_born_risen()
	local total = 0
	for _, unit in pairs(game.ActiveEnemies or {}) do
		if unit and unit.SWuBloodBorn and not unit.IsDead then
			total = total + 1
		end
	end
	return total
end


local function blood_born_fighting()
	local room = game.CurrentRun and game.CurrentRun.CurrentRoom
	for _, encounter in ipairs((room and room.ActiveEncounters) or {}) do
		if encounter.InProgress then return true end
	end
	return false
end


local function blood_born_count()
	local weights = mod.tuning.BloodBorn.ZombieWeights
	local total = 0
	for _, weight in ipairs(weights) do total = total + weight end

	local roll = game.RandomFloat(0, total)
	for count, weight in ipairs(weights) do
		roll = roll - weight
		if roll <= 0 then return count end
	end
	return #weights
end


function blood_born_raise(source)
	local tuning = mod.tuning.BloodBorn

	local enemyData = game.EnemyData[tuning.ZombieEnemy]
	if not enemyData then return end

	local headroom = math.max(tuning.MaxAlive - blood_born_risen(), 0)
	local count = math.min(blood_born_count(), headroom)
	if count <= 0 then return end

	local graveId = game.SpawnObstacle({ Name = 'InvisibleTarget', DestinationId = source.ObjectId })
	if not graveId then return end

	local start = game.RandomFloat(0, 360)
	for index = 1, count do
		if not blood_born_fighting() then break end
		if blood_born_risen() >= tuning.MaxAlive then break end

		local offset = game.CalcOffset(math.rad(start + index * (360 / count)), tuning.SummonSpread)

		local zombie = game.DeepCopyTable(enemyData)
		zombie.ObjectId = game.SpawnUnit({
			Name = enemyData.Name,
			Group = 'Standing',
			DestinationId = graveId,
			OffsetX = offset.X,
			OffsetY = offset.Y,
		})

		zombie.SWuBloodBorn = true

		zombie.RequiredKill = false
		zombie.BlocksLootInteraction = false
		zombie.MoneyDropOnDeath = nil
		zombie.DropItemsOnDeath = false

		game.thread(game.SetupUnit, zombie, game.CurrentRun)

		game.wait(tuning.SummonInterval, game.RoomThreadName)

		if tuning.Hitch then
			game.thread(blood_born_hitch_risen, zombie)
		end
	end

	game.DestroyOnDelay({ graveId }, 1)
end


local function blood_born_roll_raise(source)
	if not source or not source.ObjectId then return end

	local luck = game.GetTotalHeroTraitValue('LuckMultiplier', { IsMultiplier = true })
	if not game.RandomChance(mod.tuning.BloodBorn.RaiseChance * luck) then return end

	game.thread(blood_born_raise, source)
end


function blood_born_clear()
	local lastKilled = game.LastEnemyKilled
	for _, unit in pairs(game.ShallowCopyTable(game.ActiveEnemies or {})) do
		if unit.SWuBloodBorn and not unit.IsDead then
			unit.SWuBloodBornCleared = true
			game.thread(game.Kill, unit, { BlockRespawns = true })
		end
	end
	game.LastEnemyKilled = lastKilled
end


function blood_born_hitch_risen(zombie)
	if not duo_unit_ready(zombie) then return end
	duo_hitch(zombie)
end


---@diagnostic disable-next-line: unused-local
function mod.BloodBornSlain(victim, _args, _triggerArgs)
	if not duo_on('BloodBorn') then return end

	local room = game.CurrentRun and game.CurrentRun.CurrentRoom
	if not room or not victim or not victim.ObjectId then return end

	if victim.SWuBloodBornCleared then return end

	room.SWuBloodBornKills = (room.SWuBloodBornKills or 0) + 1
	blood_born_set_bonus(room.SWuBloodBornKills)

	if victim.SWuBloodBorn then return end

	if blood_born_ring() then
		blood_born_raise(victim)
	else
		blood_born_roll_raise(victim)
	end
end


function mod.BloodBornHit(_unit, _args, triggerArgs)
	if not duo_on('BloodBorn') or blood_born_ring() then return end
	if not game.HeroHasTrait(duo_traits.BloodBorn) then return end
	if not triggerArgs or triggerArgs.ManuallyTriggered or not duo_blow_attacker(triggerArgs) then return end

	blood_born_roll_raise(game.CurrentRun.Hero)
end


function blood_born_set_bonus(kills)
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end
	hero.OutgoingDamageModifiers = hero.OutgoingDamageModifiers or {}

	local entry
	for _, modifier in ipairs(hero.OutgoingDamageModifiers) do
		if modifier.SWuBloodBorn then
			entry = modifier
			break
		end
	end
	if not entry then
		entry = { SWuBloodBorn = true, ValidWeaponMultiplier = 1 }
		game.AddOutgoingDamageModifier(hero, entry)
	end

	local tuning = mod.tuning.BloodBorn
	local perKill = tuning.DamagePerKill
	local bonus = math.min(kills * perKill, tuning.MaxBonus)
	entry.ValidWeaponMultiplier = 1 + bonus
	duo_show_percent(duo_traits.BloodBorn, 'SWuBloodBornPercent', bonus)
end
