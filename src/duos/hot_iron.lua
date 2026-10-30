---@meta _


local GLOW = 'DelayedKnockbackEffect'
local FIREBALLS = fireball_lookup()


register_duo({
	key = 'HotIron',

	StatLines = { 'SWuHotIronStatDisplay' },
	ExtractValues = with_keyword_extracts({
		{ Key = 'SWuGlowMultiplier', ExtractAs = 'TooltipGlowDamage', Format = 'PercentDelta' },
	}, 'DelayedKnockback'),

	ExtraFields = {
		SWuGlowMultiplier = mod.tuning.HotIron.GlowMultiplier,

		OnEnemyDamagedAction = {
			ValidProjectiles = fireball_projectiles(),
			ValidProjectilesLookup = fireball_lookup(),
			EffectName = GLOW,
		},

		AddOutgoingDamageModifiers = {
			ValidProjectiles = fireball_projectiles(),
			ValidProjectilesLookup = fireball_lookup(),
			ValidActiveEffects = { GLOW },
			ValidWeaponMultiplier = mod.tuning.HotIron.GlowMultiplier,
		},
	},
})


local function hot_iron_held()
	if not duo_on('HotIron') or not game.CurrentRun or not game.CurrentRun.Hero then return false end
	return game.HeroHasTrait(duo_traits.HotIron) == true
end


local strike_weapons


local function hot_iron_strike_weapons()
	if strike_weapons then return strike_weapons end

	local lookup = {}
	for _, set in ipairs({ game.WeaponSets.HeroPrimaryWeapons, game.WeaponSets.HeroSecondaryWeapons }) do
		for _, name in ipairs(game.AddLinkedWeapons(set)) do lookup[name] = true end
	end

	strike_weapons = lookup
	return lookup
end


local function hot_iron_strike(victim, attacker, triggerArgs)
	if not triggerArgs or triggerArgs.EffectName or not triggerArgs.SourceProjectile then return nil end
	if FIREBALLS[triggerArgs.SourceProjectile] then return nil end
	if not attacker or not game.CurrentRun or attacker ~= game.CurrentRun.Hero then return nil end
	if not hot_iron_held() then return nil end

	local weapon = triggerArgs.SourceWeapon
	if not weapon or not hot_iron_strike_weapons()[weapon] then return nil end

	return triggerArgs.SourceProjectile
end


local function fireball_keyed(lookup)
	if type(lookup) ~= 'table' then return false end
	for name in pairs(FIREBALLS) do
		if lookup[name] then return true end
	end
	return false
end


local function collect_lookups(node, found, seen, depth)
	if type(node) ~= 'table' or seen[node] or depth > 5 then return end
	seen[node] = true

	for key, value in pairs(node) do
		if key == 'ValidProjectilesLookup' then
			if fireball_keyed(value) and not seen[value] then
				seen[value] = true
				table.insert(found, value)
			end
		elseif type(value) == 'table' then
			collect_lookups(value, found, seen, depth + 1)
		end
	end
end


function hot_iron_invalidate()
	mod.HotIronLookups = nil
end


local function hot_iron_lookups(hero)
	local signature = #(hero.Traits or {}) .. ':' .. #(hero.OutgoingDamageModifiers or {})
	local cache = mod.HotIronLookups
	if cache and cache.Hero == hero and cache.Signature == signature then return cache.Lookups end

	local found, seen = {}, {}
	collect_lookups(hero.Traits, found, seen, 0)
	collect_lookups(hero.OutgoingDamageModifiers, found, seen, 0)
	collect_lookups(hero.HeroTraitValuesCache, found, seen, 0)

	mod.HotIronLookups = { Hero = hero, Signature = signature, Lookups = found }
	return found
end


local function hot_iron_fireball_actions(victim, args)
	local hero = game.CurrentRun.Hero
	if not victim.TriggersOnDamageEffects or victim.IsPolymorphed then return end

	local alive = victim.Health ~= nil
		and ((victim.HealthBuffer and victim.HealthBuffer > 0) or victim.Health > 0 or game.HasLastStand(victim))
	local luck = game.GetTotalHeroTraitValue('LuckMultiplier', { IsMultiplier = true })

	for _, trait in ipairs(hero.Traits or {}) do
		local action = trait.OnEnemyDamagedAction
		if action and not action.ValidEffectName and fireball_keyed(action.ValidProjectilesLookup) then
			if action.FunctionName and (not action.FirstHitOnly
				or not game.ProjectileHasUnitHit(args.ProjectileId, action.FunctionName))
			then
				game.ProjectileRecordUnitHit(args.ProjectileId, action.FunctionName)
				local actionArgs = game.ShallowCopyTable(action.Args) or {}
				actionArgs.VictimWillBeAlive = alive
				game.thread(game.CallFunctionName, action.FunctionName, victim, actionArgs, args)
			end

			local chance = action.Chance == nil or game.RandomChance(action.Chance * luck)
			if (action.EffectName or action.EffectNames) and alive and chance then
				local names = game.ShallowCopyTable(action.EffectNames) or {}
				local effectArgs = game.ShallowCopyTable(action.Args) or {}
				if action.EffectName then
					table.insert(names, action.EffectName)
					table.insert(effectArgs, action.Args or {})
				end
				for i, name in pairs(names) do
					game.ApplyEffect({
						DestinationId = victim.ObjectId,
						Id = hero.ObjectId,
						EffectName = name,
						ImpactAngle = args.ImpactAngle and math.rad(args.ImpactAngle),
						DataProperties = game.MergeTables(game.EffectData[name].EffectData, effectArgs[i]),
					})
				end
			end
		end
	end
end


local function as_fireball(projectile, call, ...)
	local hero = game.CurrentRun.Hero
	local injected = {}
	for _, lookup in ipairs(hot_iron_lookups(hero)) do
		if lookup[projectile] == nil then
			lookup[projectile] = true
			table.insert(injected, lookup)
		end
	end

	local ok, result = pcall(call, ...)

	for _, lookup in ipairs(injected) do
		lookup[projectile] = nil
	end
	if not ok then error(result, 0) end
	return result
end


function hot_iron_damage(base, victim, triggerArgs)
	local projectile = hot_iron_strike(victim, triggerArgs and triggerArgs.AttackerTable, triggerArgs)
	if not projectile then return base(victim, triggerArgs) end

	return as_fireball(projectile, base, victim, triggerArgs)
end


function hot_iron_on_damaged(base, victim, attacker, args)
	if hot_iron_strike(victim, attacker, args) and not args.SkipOnDamagedPowers then
		hot_iron_fireball_actions(victim, args)
	end
	return base(victim, attacker, args)
end


local SIZE_PROPERTIES = { 'ProjectileScaleMultiplier', 'BlastRadiusMultiplier' }


local function hot_iron_size_multiplier()
	if not duo_on('HotIron') then return 1 end
	local creation = game.TraitData.BurnSprintBoon and game.TraitData.BurnSprintBoon.OnProjectileCreationFunction
	local mult = creation and creation.Args and creation.Args.AreaMultiplier
	return type(mult) == 'number' and mult or 1
end


local function hot_iron_size_changes(trait, mult)
	trait.PropertyChanges = trait.PropertyChanges or {}
	local found = {}
	for _, change in ipairs(trait.PropertyChanges) do
		if change.SWuHotIronSize then
			change.ChangeValue = mult
			found[change.WeaponProperty] = true
		end
	end

	local weapons = game.ConcatTableValues(
		game.ShallowCopyTable(game.WeaponSets.HeroPrimaryWeapons),
		game.WeaponSets.HeroSecondaryWeapons)
	for _, property in ipairs(SIZE_PROPERTIES) do
		if not found[property] then
			table.insert(trait.PropertyChanges, {
				SWuHotIronSize = true,
				TraitName = 'BurnSprintBoon',
				WeaponNames = weapons,
				WeaponProperty = property,
				ChangeValue = mult,
				ChangeType = 'Multiply',
			})
		end
	end
end


function hot_iron_sync_size()
	local name = duo_traits.HotIron
	if not name or not game.TraitData[name] then return end

	local mult = hot_iron_size_multiplier()
	hot_iron_size_changes(game.TraitData[name], mult)

	local hero = game.CurrentRun and game.CurrentRun.Hero
	for _, trait in ipairs(hero and hero.Traits or {}) do
		if trait.Name == name then hot_iron_size_changes(trait, mult) end
	end
end
