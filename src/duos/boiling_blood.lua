---@meta _


register_duo({
	key = 'BoilingBlood',

	StatLines = { 'SWuBoilingBloodHealStatDisplay', 'SWuBoilingBloodHitStatDisplay' },
	ExtractValues = {
		{ Key = 'SWuHealPerPlasma', ExtractAs = 'TooltipHealPerPlasma' },
		{ Key = 'SWuDamagePerHit', ExtractAs = 'TooltipPerHit', Format = 'Percent' },
		{ Key = 'SWuMaxBonus', ExtractAs = 'TooltipMaxBonus', Format = 'Percent', SkipAutoExtract = true },
	},

	ExtraFields = {
		SWuHealPerPlasma = mod.tuning.BoilingBlood.HealPerPlasma,
		SWuDamagePerHit = mod.tuning.BoilingBlood.DamagePerHit,
		SWuMaxBonus = mod.tuning.BoilingBlood.MaxBonus,

		ShowInHUD = true,
		CustomLabel = {
			DisplayType = 'RoomValue',
			Key = 'SWuBoilingBloodPercent',
			Text = 'UI_TimedKillBuff',
		},

		OnSelfDamagedFunction = { Name = _PLUGIN.guid .. '.BoilingBloodHit' },

		SetupFunction = {
			Name = _PLUGIN.guid .. '.BoilingBlood',
			RepeatOnEncounterStart = true,
		},
	},
})


local function boiling_blood_bonus()
	local room = game.CurrentRun and game.CurrentRun.CurrentRoom
	if not room then return 0 end
	local tuning = mod.tuning.BoilingBlood

	return math.min((room.SWuBoilingBloodHits or 0) * tuning.DamagePerHit, tuning.MaxBonus)
end


local function boiling_blood_apply()
	local bonus = boiling_blood_bonus()
	duo_set_multiplier('BoilingBlood', 1 + bonus)
	duo_show_percent(duo_traits.BoilingBlood, 'SWuBoilingBloodPercent', bonus)
end


function boiling_blood_clear()
	duo_set_multiplier('BoilingBlood', 1)
end


function mod.BoilingBlood()
	if not duo_on('BoilingBlood') then return end

	boiling_blood_apply()
end


function mod.BoilingBloodHit(unit, _args, triggerArgs)
	if not duo_on('BoilingBlood') then return end

	local room = game.CurrentRun and game.CurrentRun.CurrentRoom
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not room or not hero then return end
	if not triggerArgs then return end

	if triggerArgs.ManuallyTriggered then
		if not mod.tuning.BoilingBlood.HeinousAffront then return end
		if not unit or unit == hero then return end
	else
		if not duo_blow_attacker(triggerArgs) then return end
	end

	room.SWuBoilingBloodHits = (room.SWuBoilingBloodHits or 0) + 1
	boiling_blood_apply()

	local tuning = mod.tuning.BoilingBlood
	local filled = boiling_blood_bonus() / tuning.MaxBonus

	game.CreateAnimation({
		Name = tuning.HitVfx,
		DestinationId = hero.ObjectId,
		Scale = tuning.VfxMinScale + (1 - tuning.VfxMinScale) * filled,
	})
end


function boiling_blood_heal()
	if not duo_on('BoilingBlood') then return end
	if not game.HeroHasTrait(duo_traits.BoilingBlood) then return end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end

	local plasma = game.GetTotalHeroTraitValue('BloodDropMultiplier', { IsMultiplier = true })
	local amount = plasma * mod.tuning.BoilingBlood.HealPerPlasma
	if amount <= 0 then return end

	game.Heal(hero, {
		HealAmount = game.round(amount * game.CalculateHealingMultiplier()),
		SourceName = duo_traits.BoilingBlood,
	})
end
