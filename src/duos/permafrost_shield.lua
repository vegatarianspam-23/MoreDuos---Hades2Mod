---@meta _


register_duo({
	key = 'PermafrostShield',

	StatLines = { 'SWuPermafrostShieldStatDisplay' },
	ExtractValues = {
		{ Key = 'ActivatedDamageCap', ExtractAs = 'TooltipDamageCap' },
	},

	ExtraFields = {
		ActivatedDamageCap = mod.tuning.PermafrostShield.DamageCap,

		OnSelfDamagedFunction = {
			Name = _PLUGIN.guid .. '.PermafrostShieldHit',
		},
	},
})


---@diagnostic disable-next-line: unused-local
function mod.PermafrostShieldHit(_attacker, _args, triggerArgs)
	if not duo_on('PermafrostShield') then return end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero or not triggerArgs then return end
	if (triggerArgs.DamageAmount or 0) < mod.tuning.PermafrostShield.DamageCap then return end

	game.thread(game.InCombatTextArgs, {
		TargetId = hero.ObjectId,
		Text = 'SWuPermafrostShield_CombatText',
		Duration = 0.6,
		Cooldown = 0.5,
	})
end
