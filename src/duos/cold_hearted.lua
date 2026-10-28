---@meta _


register_duo({
	key = 'ColdHearted',

	StatLines = { 'SWuColdHeartedPerSecondStatDisplay' },
	ExtractValues = with_keyword_extracts({
		{ Key = 'SWuColdHeartedPower', ExtractAs = 'TooltipPower', SkipAutoExtract = true },
		{ Key = 'SWuColdHeartedPerSecond', ExtractAs = 'TooltipPerSecond' },
		{ Key = 'SWuFreezeMultiplier', ExtractAs = 'TooltipFreezeMultiplier', SkipAutoExtract = true },
	}, 'Root', 'Weak'),

	ExtraFields = {
		SWuColdHeartedPower = mod.tuning.ColdHearted.Power,
		SWuColdHeartedPerSecond = mod.tuning.ColdHearted.PowerPerSecond,
		SWuFreezeMultiplier = mod.tuning.ColdHearted.FreezeMultiplier,
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
	local effect = effectName and game.EffectData[effectName]
	local data = effect and effect.EffectData
	if not data then return functionArgs end

	local effectArgs = functionArgs.EffectArgs or {}
	local duration = effectArgs.Duration or data.Duration
	local threshold = effectArgs.ExpiringTimeThreshold or data.ExpiringTimeThreshold
	if type(duration) ~= 'number' or type(threshold) ~= 'number' then return functionArgs end

	local extension = 0
	if game.HeroHasTrait('RootDurationBoon') then
		extension = game.GetTotalHeroTraitValue('RootDurationExtension')
	end

	local held = (duration - threshold + extension) * mod.tuning.ColdHearted.FreezeMultiplier
	local scaled = game.ShallowCopyTable(functionArgs)
	scaled.EffectArgs = game.ShallowCopyTable(effectArgs)
	scaled.EffectArgs.ExpiringTimeThreshold = math.max(extension, duration - held + extension)
	return scaled
end
