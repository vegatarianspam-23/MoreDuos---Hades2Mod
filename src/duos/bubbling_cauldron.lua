---@meta _


register_duo({
	key = 'BubblingCauldron',

	StatLines = { 'SWuBubblingCauldronChanceStatDisplay', 'SWuBubblingCauldronStatDisplay' },
	ExtractValues = with_keyword_extracts({
		{ Key = 'SWuFrothChanceMultiplier', ExtractAs = 'TooltipChanceBonus', Format = 'PercentDelta' },
		{ Key = 'SWuFrothCooldown', ExtractAs = 'TooltipCooldown', DecimalPlaces = 1 },
	}, 'Burn', 'KnockbackAmplify'),

	ExtraFields = {
		SWuFrothChanceMultiplier = mod.tuning.BubblingCauldron.ChanceMultiplier,
		SWuFrothCooldown = mod.tuning.BubblingCauldron.Cooldown,
	},
})


function bubbling_cauldron_font(base, victim, triggerArgs)
	if not duo_on('BubblingCauldron') then
		return base(victim, triggerArgs)
	end

	if not duo_running(duo_traits.BubblingCauldron) then
		return base(victim, triggerArgs)
	end

	local froth = game.EffectData.AmplifyKnockbackEffect
	local chance = froth.Chance
	froth.Chance = chance * mod.tuning.BubblingCauldron.ChanceMultiplier

	local cooldown = froth.Cooldown
	if victim and victim.ActiveEffects and victim.ActiveEffects.BurnEffect then
		froth.Cooldown = mod.tuning.BubblingCauldron.Cooldown
	end

	local ok, err = pcall(base, victim, triggerArgs)

	froth.Cooldown = cooldown
	froth.Chance = chance
	if not ok then error(err) end
end
