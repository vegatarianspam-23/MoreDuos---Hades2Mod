---@meta _


register_duo({
	key = 'WrathfulHubris',

	StatLines = { 'SWuWrathfulHubrisDealtStatDisplay', 'SWuWrathfulHubrisTakenStatDisplay' },
	ExtractValues = {
		{ Key = 'SWuDamageDealt', ExtractAs = 'TooltipDamageDealt', Format = 'Percent' },
		{ Key = 'SWuDamageTaken', ExtractAs = 'TooltipDamageTaken', Format = 'Percent' },
	},

	ExtraFields = {
		SWuDamageDealt = mod.tuning.WrathfulHubris.DamageDealt,
		SWuDamageTaken = mod.tuning.WrathfulHubris.DamageTaken,

		AcquireFunctionName = _PLUGIN.guid .. '.WrathfulHubrisAcquire',
	},
})


local wrathfulHubrisHeld = false


function wrathful_hubris_apply()
	local held = duo_on('WrathfulHubris') and in_run()
		and duo_traits.WrathfulHubris ~= nil and game.HeroHasTrait(duo_traits.WrathfulHubris)

	wrathfulHubrisHeld = held == true
end


function wrathful_hubris_total(attacker, multipliers)
	if not wrathfulHubrisHeld then return multipliers end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero or attacker ~= hero then return multipliers end

	return multipliers * (1 + mod.tuning.WrathfulHubris.DamageDealt)
end


---@diagnostic disable-next-line: unused-local
function mod.WrathfulHubrisAcquire(args, traitData)
	game.thread(function()
		wait_for_screens(0)
		wrathful_hubris_apply()
	end)
end


function wrathful_hubris_taken(victim, triggerArgs)
	if not wrathfulHubrisHeld or not triggerArgs then return end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero or victim ~= hero or triggerArgs.AttackerTable == hero then return end

	local damage = triggerArgs.DamageAmount
	if type(damage) ~= 'number' or damage <= 0 then return end

	triggerArgs.DamageAmount = damage * (1 + mod.tuning.WrathfulHubris.DamageTaken)
end
