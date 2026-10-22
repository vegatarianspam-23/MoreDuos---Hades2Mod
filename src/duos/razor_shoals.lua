---@meta _


register_duo({
	key = 'RazorShoals',

	StatLines = { 'SWuRazorShoalsStatDisplay' },
	ExtractValues = with_keyword_extracts({
		{ Key = 'SWuRefreshDelay', ExtractAs = 'TooltipRefreshDelay', DecimalPlaces = 1 },
	}, 'Rend', 'KnockbackAmplify'),

	ExtraFields = {
		SWuRefreshDelay = mod.tuning.RazorShoals.RefreshDelay,
	},
})


function razor_shoals_shorten(triggerArgs)
	if not duo_on('RazorShoals') then return end
	if not triggerArgs or triggerArgs.Reapplied then return end
	if not game.HeroHasTrait(duo_traits.RazorShoals) then return end

	local victim = triggerArgs.Victim
	if not victim or not victim.ObjectId then return end

	game.thread(razor_shoals_clear, victim)
end


function razor_shoals_clear(victim)
	game.wait(mod.tuning.RazorShoals.RefreshDelay, game.RoomThreadName)

	if not victim or victim.IsDead or not victim.ObjectId then return end
	if not game.HeroHasTrait(duo_traits.RazorShoals) then return end

	local effects = victim.ActiveEffects
	if not effects or not effects.AresStatus or not effects.AmplifyKnockbackEffect then return end

	game.ClearEffect({ Id = victim.ObjectId, Name = 'AresStatus' })
end
