---@meta _


register_duo({
	key = 'BloodBorn',

	StatLines = { 'SWuBloodBornStatDisplay', 'SWuBloodBornMaxStatDisplay' },

	ExtractValues = with_keyword_extracts({
		{
			Key = 'SWuDamagePerKill',
			ExtractAs = 'TooltipPerKill',
			Format = 'Percent',
		},
		{
			Key = 'SWuMaxBonus',
			ExtractAs = 'TooltipMaxBonus',
			Format = 'Percent',
		},
		{ Key = 'SWuZombies', ExtractAs = 'TooltipZombies', SkipAutoExtract = true },
	}, mod.tuning.BloodBorn.Hitch and 'Link' or nil),

	ExtraFields = {
		SWuDamagePerKill = mod.tuning.BloodBorn.DamagePerKill,
		SWuMaxBonus = mod.tuning.BloodBorn.MaxBonus,
		SWuZombies = mod.tuning.BloodBorn.Zombies,

		LoadPackages = mod.tuning.BloodBorn.ZombiePackages,

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
	},
})


function mod.BloodBornSetup()
	game.LoadPackages({ Names = mod.tuning.BloodBorn.ZombiePackages })

	local room = game.CurrentRun and game.CurrentRun.CurrentRoom
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


function blood_born_raise(victim)
	local tuning = mod.tuning.BloodBorn

	local enemyData = game.EnemyData[tuning.ZombieEnemy]
	if not enemyData then return end

	local headroom = math.max(tuning.MaxAlive - blood_born_risen(), 0)
	local count = math.min(tuning.Zombies, headroom)
	if count <= 0 then return end

	local graveId = game.SpawnObstacle({ Name = 'InvisibleTarget', DestinationId = victim.ObjectId })
	if not graveId then return end

	for index = 1, count do
		if not blood_born_fighting() then break end
		if blood_born_risen() >= tuning.MaxAlive then break end

		local offset = game.CalcOffset(math.rad(index * (360 / count)), tuning.SummonSpread)

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


function blood_born_clear()
	local lastKilled = game.LastEnemyKilled
	for _, unit in pairs(game.ShallowCopyTable(game.ActiveEnemies or {})) do
		if unit.SWuBloodBorn and not unit.IsDead then
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

	if victim.SWuBloodBorn then return end

	room.SWuBloodBornKills = (room.SWuBloodBornKills or 0) + 1
	blood_born_set_bonus(room.SWuBloodBornKills)

	blood_born_raise(victim)
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
	local bonus = math.min(kills * tuning.DamagePerKill, tuning.MaxBonus)
	entry.ValidWeaponMultiplier = 1 + bonus
	duo_show_percent(duo_traits.BloodBorn, 'SWuBloodBornPercent', bonus)
end
