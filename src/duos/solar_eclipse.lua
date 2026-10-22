---@meta _


register_duo({
	key = 'SolarEclipse',

	StatLines = { 'SWuSolarEclipseStatDisplay', 'SWuSolarEclipseSpeedStatDisplay' },
	ExtractValues = with_keyword_extracts({
		{ Key = 'SWuEclipseDamage', ExtractAs = 'TooltipEclipseDamage', Format = 'PercentDelta' },
		{ Key = 'SWuSpeedPerDazed', ExtractAs = 'TooltipSpeedPerDazed', Format = 'Percent' },
		{ Key = 'SWuEclipseDuration', ExtractAs = 'TooltipEclipseDuration', SkipAutoExtract = true },
		{ Key = 'SWuEclipseDuration', ExtractAs = 'Duration', SkipAutoExtract = true },
		{ Key = 'SWuEclipseCooldown', ExtractAs = 'Cooldown', SkipAutoExtract = true },
	}, 'Blind'),

	ExtraFields = {
		SWuEclipseDamage = mod.tuning.SolarEclipse.DamageMultiplier,
		SWuSpeedPerDazed = mod.tuning.SolarEclipse.SpeedPerDazed,
		SWuEclipseDuration = mod.tuning.SolarEclipse.Duration,
		SWuEclipseCooldown = 0,

		ShowInHUD = true,
		CustomLabel = {
			DisplayType = 'RoomValue',
			Key = 'SWuEclipseSpeedPercent',
			Text = 'UI_TimedKillBuff',
		},

		AddOutgoingDamageModifiers = {
			RequiredSelfEffectsMultiplier = {
				BaseValue = mod.tuning.SolarEclipse.DamageMultiplier,
				SourceIsMultiplier = true,
			},
			RequiredEffects = { 'HadesInvisible' },
		},

		SetupFunction = {
			Threaded = true,
			Name = _PLUGIN.guid .. '.SolarEclipse',
			RepeatOnEncounterStart = true,
			Args = { Interval = mod.tuning.SolarEclipse.PollInterval },
		},
	},
})


local DAZE = 'BlindEffect'


local function solar_eclipse_counts(unit)
	if not duo_foe(unit) or is_allied_summon(unit) then return false end
	if unit.IgnoreInvisibility or not unit.TriggersOnHitEffects then return false end
	if unit.InvulnerableFlags and not game.IsEmpty(unit.InvulnerableFlags) then return false end

	if unit.BlockEffectWhileRootActive == DAZE then return false end
	if unit.EffectBlocks and game.Contains(unit.EffectBlocks, DAZE) then return false end

	return true
end


function solar_eclipse_ready()
	if not game.CheckCooldownNoTrigger('SWuSolarEclipse', solar_eclipse_recharge()) then
		return false
	end

	local counted = 0
	for _, unit in pairs(game.ActiveEnemies or {}) do
		if solar_eclipse_counts(unit) then
			if not unit.ActiveEffects or not unit.ActiveEffects[DAZE] then return false end
			counted = counted + 1
		end
	end
	return counted > 0
end


local function solar_eclipse_dazed()
	local counted = 0
	for _, unit in pairs(game.ActiveEnemies or {}) do
		if solar_eclipse_counts(unit) and unit.ActiveEffects and unit.ActiveEffects[DAZE] then
			counted = counted + 1
		end
	end
	return counted
end


local SPEED_KEY = 'SWuSolarEclipseSpeed'

local function solar_eclipse_speed(count)
	local hero = game.CurrentRun and game.CurrentRun.Hero
	local weapons = game.WeaponData
	local tuning = mod.tuning.SolarEclipse
	if not hero or not weapons or not weapons.DefaultWeaponValues then return 0 end

	local bonus = math.min(count * tuning.SpeedPerDazed, tuning.MaxSpeedBonus)
	if hero.Invisible then bonus = math.max(bonus, tuning.DarkSpeedBonus) end
	local total = 1 / (1 + bonus)

	local state = game.SessionMapState
	local last = (state and state.SWuEclipseLastSpeed) or 1
	if math.abs(total - last) < 0.0001 then return bonus end

	local step = total / last
	local changes = {}

	for weaponName in pairs(hero.Weapons or {}) do
		if game.WeaponSetLookups.HeroPrimarySecondaryWeapons[weaponName] then
			for _, linked in ipairs(game.AddLinkedWeapons({ weaponName })) do
				local entries = (weapons[linked] and weapons[linked].SpeedPropertyChanges)
					or weapons.DefaultWeaponValues.DefaultSpeedPropertyChanges

				for _, entry in ipairs(entries) do
					if entry.WeaponProperty ~= 'ChargeTime' then
						local change = game.DeepCopyTable(entry)
						change.WeaponNames = nil
						change.WeaponName = linked
						change.ChangeType = 'Multiply'
						change.ChangeValue = change.InvertSource and (1 / step) or step
						table.insert(changes, change)
					end
				end
			end
		end
	end

	table.insert(changes, { UnitProperty = 'Speed', ChangeType = 'Multiply', ChangeValue = 1 / step })
	table.insert(changes, { WeaponNames = { 'WeaponSprint' }, WeaponProperty = 'SelfVelocity',
		ChangeValue = 1100 * (1 - step), ChangeType = 'Add', ExcludeLinked = true })
	table.insert(changes, { WeaponNames = { 'WeaponSprint' }, WeaponProperty = 'SelfVelocityCap',
		ChangeValue = 740 * (1 - step), ChangeType = 'Add', ExcludeLinked = true })

	if state then state.SWuEclipseLastSpeed = total end
	game.SetPlayerAttackSpecialChargeSpeed(SPEED_KEY, total)
	game.ApplyUnitPropertyChanges(hero, changes)

	return bonus
end


local function solar_eclipse_show(bonus)
	local room = game.CurrentRun and game.CurrentRun.CurrentRoom
	if not room then return end

	local percent = math.floor(bonus * 100 + 0.5)
	if room.SWuEclipseSpeedPercent == percent then return end

	room.SWuEclipseSpeedPercent = percent

	local trait = game.GetHeroTrait(duo_traits.SolarEclipse)
	if trait then game.UpdateTraitNumber(trait) end
end


function solar_eclipse_recharge()
	return duo_recharge(mod.tuning.SolarEclipse.Recharge)
end


local function solar_eclipse_announce()
	local tuning = mod.tuning.SolarEclipse
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero or not hero_live() or not tuning.AnnounceText then return end

	game.thread(game.InCombatTextArgs, {
		TargetId = hero.ObjectId,
		Text = tuning.AnnounceText,
		Duration = tuning.AnnounceDuration,
		PreDelay = 0.1,
	})
end


local solarEclipseWasReady = true
local function solar_eclipse_ready_announce()
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end
	local tuning = mod.tuning.SolarEclipse
	local ready = game.CheckCooldownNoTrigger('SWuSolarEclipse', solar_eclipse_recharge())
	if ready and not solarEclipseWasReady and hero_live() then
		if tuning.ReadySound then
			game.PlaySound({ Name = tuning.ReadySound, Id = hero.ObjectId })
		end
		solar_eclipse_announce()
	end
	solarEclipseWasReady = ready
end


local function solar_eclipse_warn()
	local tuning = mod.tuning.SolarEclipse
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero or not hero_live() then return end

	if tuning.WarnSound then
		game.PlaySound({ Name = tuning.WarnSound, Id = hero.ObjectId })
	end

	if tuning.WarnFlash then
		game.Flash({
			Id = hero.ObjectId,
			Speed = 2,
			MinFraction = 0,
			MaxFraction = 0.5,
			Color = game.Color.White,
			ExpireAfterCycle = true,
		})
	end
end


local function solar_eclipse_countdown(mine)
	local tuning = mod.tuning.SolarEclipse
	local pings = math.min(tuning.WarnCount or 0, tuning.Duration)
	if pings <= 0 then return end

	game.waitUnmodified(tuning.Duration - pings, game.RoomThreadName)

	for _ = 1, pings do
		if mine ~= mod.SolarEclipseGeneration then return end
		solar_eclipse_warn()
		game.waitUnmodified(tuning.WarnInterval or 1, game.RoomThreadName)
	end
end


function solar_eclipse_darken()
	local tuning = mod.tuning.SolarEclipse
	game.CheckCooldown('SWuSolarEclipse', solar_eclipse_recharge())

	local hero = game.CurrentRun and game.CurrentRun.Hero
	local effect = game.EffectData.HadesInvisible
	if not hero or not effect then return end

	game.ApplyEffect({
		DestinationId = hero.ObjectId,
		Id = hero.ObjectId,
		EffectName = 'HadesInvisible',
		DataProperties = game.MergeAllTables({ effect.EffectData, { Duration = tuning.Duration } }),
	})

	game.thread(game.HadesInvisibility)

	solar_eclipse_announce()

	mod.SolarEclipseGeneration = (mod.SolarEclipseGeneration or 0) + 1
	game.thread(solar_eclipse_countdown, mod.SolarEclipseGeneration)
end


function mod.SolarEclipse(_hero, args)
	local interval = (args and args.Interval) or mod.tuning.SolarEclipse.PollInterval
	local loop = duo_loop_claim(duo_traits.SolarEclipse)
	if not loop then return end

	while duo_running(duo_traits.SolarEclipse) do
		if duo_on('SolarEclipse') then
			solar_eclipse_ready_announce()
			solar_eclipse_show(solar_eclipse_speed(solar_eclipse_dazed()))

			if solar_eclipse_ready() then
				solar_eclipse_darken()
			end
		end

		game.wait(interval, loop)
	end
end
