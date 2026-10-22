---@meta _


register_duo({
	key = 'KindledSpirit',

	StatLines = { 'SWuKindledSpiritStatDisplay', 'SWuKindledSpiritHealStatDisplay' },
	ExtractValues = with_keyword_extracts({
		{ Key = 'SWuDamagePerHealth', ExtractAs = 'TooltipDamagePerHealth' },
		{ Key = 'SWuHealOnHit', ExtractAs = 'TooltipHealOnHit' },
	}, 'Burn'),

	ExtraFields = {
		SWuDamagePerHealth = mod.tuning.KindledSpirit.DamagePerHealth,
		SWuHealOnHit = mod.tuning.KindledSpirit.HealOnHit,

		OnSelfDamagedFunction = { Name = _PLUGIN.guid .. '.KindledSpiritHit' },

		OnPlayerHealthChangedFunctionName = {
			FunctionName = _PLUGIN.guid .. '.KindledSpirit',
		},
	},
})


---@diagnostic disable-next-line: unused-local
function mod.KindledSpiritHit(unit, _args, triggerArgs)
	if not duo_on('KindledSpirit') then return end
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end

	if not triggerArgs then return end

	if triggerArgs.ManuallyTriggered then
		if not mod.tuning.KindledSpirit.HeinousAffront then return end

		if not unit or unit == hero then return end
	else
		if mod.tuning.KindledSpirit.HealthLossOnly and triggerArgs.HealthProtected then return end
		if triggerArgs.EffectName or not unit or unit == hero or duo_ignores(unit) then return end
	end

	game.Heal(hero, {
		HealAmount = game.round(mod.tuning.KindledSpirit.HealOnHit * game.CalculateHealingMultiplier()),
		SourceName = 'SWuKindledSpirit',
	})
end


---@diagnostic disable-next-line: unused-local
function mod.KindledSpirit(_args, healed)
	if not duo_on('KindledSpirit') then return end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero or type(healed) ~= 'number' or healed <= 0 then return end

	local tuning = mod.tuning.KindledSpirit
	local stacks = math.floor(healed * tuning.DamagePerHealth + 0.5)
	if stacks <= 0 then return end

	local everywhere = tuning.NearbyExclusionBoon and game.HeroHasTrait(tuning.NearbyExclusionBoon)

	for _, unit in pairs(game.ActiveEnemies or {}) do
		if unit and unit.ObjectId and not unit.IsDead and not duo_ignores(unit) then
			local distance = not everywhere and game.GetDistance({ Id = hero.ObjectId, DestinationId = unit.ObjectId })
			if everywhere or (distance and distance <= tuning.Radius) then
				game.ApplyBurn(unit, { EffectName = 'BurnEffect', NumStacks = stacks }, nil)
			end
		end
	end
end
