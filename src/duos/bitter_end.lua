---@meta _


register_duo({
	key = 'BitterEnd',

	StatLines = { 'SWuBitterEndStatDisplay' },
	ExtractValues = with_keyword_extracts({
		{
			Key = 'SWuInflictMultiplier',
			ExtractAs = 'TooltipInflictDamage',
			Format = 'PercentDelta',
		},
	}, 'Rend', 'Root'),

	ExtraFields = {
		SWuInflictMultiplier = mod.tuning.BitterEnd.InflictMultiplier,
	},
})


local function bitter_end_kind(effectName)
	if effectName == 'AresStatus' then return 'Rend' end
	local data = effectName and game.EffectData[effectName]
	if data and data.EffectGroup == 'Root' then return 'Root' end
	return nil
end


local function bitter_end_action_kinds(action)
	local kinds = {}
	kinds[bitter_end_kind(action.EffectName) or ''] = true
	for _, name in ipairs(action.EffectNames or {}) do
		kinds[bitter_end_kind(name) or ''] = true
	end
	if action.FunctionName == 'ApplyRoot' and action.Args then
		kinds[bitter_end_kind(action.Args.EffectName) or ''] = true
	end
	kinds[''] = nil
	return kinds
end


local function bitter_end_action_hits(trait, action, triggerArgs)
	if action.ValidEffectName or action.Chance then return false end

	local weapon = triggerArgs.SourceWeapon
	local weapons = action.ValidWeaponsLookup or (action.ValidWeapons and game.ToLookup(action.ValidWeapons))
	local validWeapon = weapons == nil or weapons[weapon] ~= nil
	if not validWeapon and trait.Slot then
		for _, shared in pairs((game.CurrentRun.Hero.HeroTraitValuesCache or {}).AddWeaponsToTraits or {}) do
			if shared.Slot == trait.Slot and (shared.WeaponName == weapon
				or (shared.WeaponNamesLookup and shared.WeaponNamesLookup[weapon])) then
				validWeapon = true
			end
		end
	end
	if not validWeapon then return false end

	local projectile = triggerArgs.SourceProjectile
	local projectiles = action.ValidProjectilesLookup or (action.ValidProjectiles and game.ToLookup(action.ValidProjectiles))
	if projectiles and not projectiles[projectile] then return false end
	if action.ExcludeProjectilesLookup and action.ExcludeProjectilesLookup[projectile] then return false end

	return true
end


local function bitter_end_afflicted(victim, kind)
	if kind == 'Rend' then return victim.ActiveEffects.AresStatus ~= nil end
	return game.HasEffectWithEffectGroup(victim, 'Root')
end


function bitter_end_applies(attacker, victim, triggerArgs)
	if not duo_on('BitterEnd') then return false end
	if not triggerArgs or triggerArgs.EffectName then return false end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if attacker ~= hero then return false end
	if not game.HeroHasTrait(duo_traits.BitterEnd) then return false end

	if not victim or not victim.TriggersOnDamageEffects or not victim.ActiveEffects then return false end

	if not game.WeaponSetLookups.HeroPrimarySecondaryWeaponsLinked[triggerArgs.SourceWeapon] then
		return false
	end

	for _, trait in ipairs(hero.Traits or {}) do
		local action = trait.OnEnemyDamagedAction
		if action and bitter_end_action_hits(trait, action, triggerArgs) then
			for kind in pairs(bitter_end_action_kinds(action)) do
				if not bitter_end_afflicted(victim, kind) then return true end
			end
		end
	end
	return false
end
