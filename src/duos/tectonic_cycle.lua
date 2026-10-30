---@meta _


register_duo({
	key = 'TectonicCycle',

	StatLines = { 'SWuTectonicCycleStatDisplay' },
	ExtractValues = {
		{ Key = 'SWuCycleInterval', ExtractAs = 'TooltipCycleInterval' },
	},

	ExtraFields = {
		SWuCycleInterval = mod.tuning.TectonicCycle.Interval,

		SetupFunction = {
			Threaded = true,
			Name = _PLUGIN.guid .. '.TectonicCycle',
			RepeatOnEncounterStart = true,
		},
	},
})


local CYCLED_SETUPS = {
	ReserveManaHitShieldBoon = true,
	SprintShieldBoon = true,
}


local OLD_GRUDGE = 'HadesPreDamageBoon'
local PERFECT_IMAGE = 'PerfectDamageBonusBoon'


local function tectonic_cycle_grudge()
	local trait = game.GetHeroTrait(OLD_GRUDGE)
	local damageData = trait and trait.EncounterPreDamage
	if not damageData then return end

	local share = damageData.PreDamage
	if type(share) ~= 'number' or share <= 0 then return end
	for _, unit in pairs(game.ShallowCopyTable(game.ActiveEnemies or {})) do
		if unit and unit.IsBoss and not unit.IsDead and (unit.Health or 0) > 0 then

			game.thread(game.PreDamageBoss, unit, (unit.MaxHealth or unit.Health) * share, damageData)
		end
	end
end


local function tectonic_cycle_perfect_image()
	if not game.HeroHasTrait(PERFECT_IMAGE) then return end
	if not game.SessionMapState.DeactivatePerfectDamageBonus then return end

	game.killTaggedThreads('PerfectDamageReset')
	game.SessionMapState.DeactivatePerfectDamageBonus = nil
	game.PerfectDamageBoonRenewed()
end


function tectonic_cycle_restart()
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end

	for _, trait in pairs(hero.Traits or {}) do
		if trait.EncounterStartWeapon then
			game.FireWeaponFromUnit({
				Weapon = trait.EncounterStartWeapon,
				Id = hero.ObjectId,
				DestinationId = hero.ObjectId,
			})
		end

		if trait.EncounterStartEffect then
			local data = game.EffectData[trait.EncounterStartEffect.Name]
			if data then
				game.ApplyEffect({
					DestinationId = hero.ObjectId,
					Id = hero.ObjectId,
					EffectName = trait.EncounterStartEffect.Name,
					DataProperties = game.MergeAllTables({
						data.EffectData,
						trait.EncounterStartEffect.EffectData or {},
					}),
				})
			end
		end

		if trait.OnEncounterStartFunction then
			game.thread(game.CallFunctionName, trait.OnEncounterStartFunction.Name, hero, trait.OnEncounterStartFunction.Args)
		end

		if trait.SetupFunction and (trait.SetupFunction.SWuCycleSetup or (CYCLED_SETUPS[trait.Name or ''] and not trait.OnEncounterStartFunction)) then
			game.thread(game.CallFunctionName, trait.SetupFunction.Name, hero, trait.SetupFunction.Args)
		end
	end

	tectonic_cycle_grudge()
	tectonic_cycle_perfect_image()
end


local function tectonic_cycle_announce()
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end

	game.thread(game.InCombatTextArgs, {
		TargetId = hero.ObjectId,
		Text = 'SWuTectonicCycle_CombatText',
		Duration = mod.tuning.TectonicCycle.TextDuration,
		PreDelay = 0.1,
	})
end


local PRESENTATION_THROTTLES = { 'Presentation', 'Text', 'Sound', 'Message', 'Played', 'Bark', 'Voice' }


local function is_presentation_throttle(name)
	if type(name) ~= 'string' then return false end
	for _, word in ipairs(PRESENTATION_THROTTLES) do
		if name:find(word, 1, true) then return true end
	end
	return false
end


local function tectonic_cycle_reset_cooldowns()
	local state = game.SessionState
	if not state then return end

	for _, store in ipairs({ 'GlobalCooldowns', 'GlobalCounts' }) do
		for name in pairs(state[store] or {}) do
			if not is_presentation_throttle(name) then
				state[store][name] = nil
			end
		end
	end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	for _, trait in pairs(hero and hero.Traits or {}) do
		local blast = (trait.OnEnemyDamagedAction and trait.OnEnemyDamagedAction.Args)
			or (trait.OnBlinkEndAction and trait.OnBlinkEndAction.FunctionArgs)
		if blast and blast.TraitName and blast.Name and blast.Cooldown then
			game.SetThreadWait(blast.TraitName, 0.01)
		end
	end

	distress_call_reset_cooldown()

	game.TraitUIActivateTraits({ IgnoreFlash = true })
end


local function tectonic_cycle_precharge()
	local run = game.CurrentRun
	if not run then return end
	local preparation = game.GetHeroTrait('PreChargeTalent')
	if preparation and preparation.OnEncounterStartFunction then return end
	if (game.GetTotalHeroTraitValue('SpellPreCharge') or 0) <= 0 then return end

	local held = run.SpellCharge or 0
	game.SpellPrecharge()

	if (run.SpellCharge or 0) < held then
		run.SpellCharge = held
	end
end


function mod.TectonicCycle(_hero, _args)
	mod.TectonicCycleGeneration = (mod.TectonicCycleGeneration or 0) + 1
	local generation = mod.TectonicCycleGeneration
	local interval = mod.tuning.TectonicCycle.Interval

	while duo_running(duo_traits.TectonicCycle) and generation == mod.TectonicCycleGeneration do
		game.wait(duo_recharge(interval), game.RoomThreadName)
		if generation ~= mod.TectonicCycleGeneration then return end
		if not duo_running(duo_traits.TectonicCycle) then return end
		if duo_on('TectonicCycle') then
			tectonic_cycle_announce()
			if config.Options and config.Options.TectonicCycleResetsCooldowns == true then
				tectonic_cycle_reset_cooldowns()
			end
			tectonic_cycle_precharge()
			tectonic_cycle_restart()
		end
	end
end
