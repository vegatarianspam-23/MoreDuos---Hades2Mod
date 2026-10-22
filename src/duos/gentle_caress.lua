---@meta _


register_duo({
	key = 'GentleCaress',

	StatLines = mod.tuning.GentleCaress.CapArmor and { 'SWuGentleCaressStatDisplay' } or nil,
	ExtractValues = {
		{ Key = 'SWuArmorCapFloor', ExtractAs = 'TooltipArmorCap' },
	},

	ExtraFields = {
		SWuArmorCapFloor = mod.tuning.GentleCaress.ArmorCapFloor,

		SetupFunction = {
			Threaded = true,
			Name = _PLUGIN.guid .. '.GentleCaress',
			RepeatOnEncounterStart = true,
			SWuCycleSetup = true,
		},

		OnSelfDamagedFunction = { Name = _PLUGIN.guid .. '.GentleCaressRevenge' },
	},
})


local function gentle_caress_armor_held()
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return 0 end

	local held = 0
	for _, trait in ipairs(hero.Traits or {}) do
		if trait.CostumeTrait and not trait.IsRenewableArmor then
			held = held + (trait.CurrentArmor or 0)
		end
	end
	return held
end


local function gentle_caress_armor_room(hero)
	local tuning = mod.tuning.GentleCaress
	if not tuning.CapArmor then return math.huge end

	local cap = math.max(tuning.ArmorCapFloor, hero.MaxHealth or 0)
	return math.max(cap - gentle_caress_armor_held(), 0)
end


function gentle_caress_overheal(victim, triggerArgs)
	if not duo_on('GentleCaress') then return end
	if not game.HeroHasTrait(duo_traits.GentleCaress) then return end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero or victim ~= hero or not triggerArgs then return end

	local amount = triggerArgs.HealAmount
	if triggerArgs.HealFraction then
		amount = game.round((hero.MaxHealth or 0) * triggerArgs.HealFraction)
	end
	if type(amount) ~= 'number' or amount <= 0 then return end

	local spill = amount - math.max((hero.MaxHealth or 0) - (hero.Health or 0), 0)
	if spill <= 0 then return end

	local room = gentle_caress_armor_room(hero)
	if room <= 0 then return end
	spill = math.min(spill, room)

	game.AddArmor(spill)
end


---@diagnostic disable-next-line: unused-local
function mod.GentleCaressHealthGate(source, functionArgs, args)
	if duo_on('GentleCaress') and game.HeroHasTrait(duo_traits.GentleCaress) then
		return true
	end
	return game.RequiredHealthFraction(source, functionArgs)
end


local GENTLE_CARESS_SHIELD = 'FirstHitHealTrait'


function mod.GentleCaress(_hero, _args)
	if not duo_on('GentleCaress') then return end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero or game.HeroHasTrait(GENTLE_CARESS_SHIELD) then return end

	local shield = game.GetProcessedTraitData({
		Unit = hero,
		TraitName = GENTLE_CARESS_SHIELD,
	})
	if shield.SetupFunction then
		shield.SetupFunction = game.ShallowCopyTable(shield.SetupFunction)
		shield.SetupFunction.Args = game.ShallowCopyTable(shield.SetupFunction.Args or {})
		shield.SetupFunction.Args.CombatText = 'SWuGentleCaress_CombatText'
	end

	game.AddTraitToHero({
		SkipNewTraitHighlight = true,
		TraitData = shield,
	})
end


---@diagnostic disable-next-line: unused-local
function mod.GentleCaressRevenge(foe, _args, triggerArgs)
	if not duo_on('GentleCaress') then return end
	if not (triggerArgs and triggerArgs.ManuallyTriggered) then return end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero or not game.HeroHasTrait(GENTLE_CARESS_SHIELD) then return end

	local dealt = heinous_affront_damage(foe, triggerArgs)
	if type(dealt) ~= 'number' or dealt <= 0 then return end

	game.RemoveTrait(hero, GENTLE_CARESS_SHIELD)
	game.UpdateHeroTraitDictionary()

	game.Heal(hero, {
		HealAmount = game.round(dealt * game.CalculateHealingMultiplier()),
		SourceName = 'SWuGentleCaress',
	})
end
