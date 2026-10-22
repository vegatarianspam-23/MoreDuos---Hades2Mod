---@meta _


register_duo({
	key = 'ColdHearted',

	StatLines = { 'SWuColdHeartedStatDisplay', 'SWuColdHeartedPerSecondStatDisplay' },
	ExtractValues = with_keyword_extracts({
		{ Key = 'SWuColdHeartedPower', ExtractAs = 'TooltipPower' },
		{ Key = 'SWuColdHeartedPerSecond', ExtractAs = 'TooltipPerSecond' },
		{ Key = 'SWuFreezeExtension', ExtractAs = 'TooltipFreezeExtension', SkipAutoExtract = true },
	}, 'Root', 'Weak'),

	ExtraFields = {
		SWuColdHeartedPower = mod.tuning.ColdHearted.Power,
		SWuColdHeartedPerSecond = mod.tuning.ColdHearted.PowerPerSecond,
		SWuFreezeExtension = mod.tuning.ColdHearted.FreezeExtension,
	},
})


function cold_hearted_power(attacker, victim, triggerArgs)
	if not duo_on('ColdHearted') then return 0 end
	if not triggerArgs or triggerArgs.EffectName then return 0 end
	if not victim or not victim.RootActive then return 0 end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if attacker ~= hero then return 0 end
	if not game.HeroHasTrait(duo_traits.ColdHearted) then return 0 end

	if not game.WeaponSetLookups.HeroPrimarySecondaryWeaponsLinked[triggerArgs.SourceWeapon] then
		return 0
	end

	local tuning = mod.tuning.ColdHearted
	local seconds = victim.SWuRootSince and math.max(math.ceil(game._worldTime - victim.SWuRootSince), 0) or 0
	return tuning.Power + tuning.PowerPerSecond * seconds
end


function cold_hearted_root_started(victim)
	if victim then victim.SWuRootSince = game._worldTime end
end


function cold_hearted_root_args(victim, functionArgs)
	if not duo_on('ColdHearted') then return functionArgs end
	if not game.HeroHasTrait(duo_traits.ColdHearted) then return functionArgs end
	if not victim or not victim.ActiveEffects or not victim.ActiveEffects.WeakEffect then
		return functionArgs
	end

	local effectName = functionArgs and functionArgs.EffectName
	local base = effectName and game.EffectData[effectName]
	base = base and base.EffectData and base.EffectData.ExpiringTimeThreshold
	if not base then return functionArgs end

	local scaled = game.ShallowCopyTable(functionArgs)
	scaled.EffectArgs = game.ShallowCopyTable(functionArgs.EffectArgs or {})
	scaled.EffectArgs.ExpiringTimeThreshold = base - mod.tuning.ColdHearted.FreezeExtension
	return scaled
end
