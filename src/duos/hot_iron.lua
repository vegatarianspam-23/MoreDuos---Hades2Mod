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

		OnProjectileCreationFunction = {
			Name = _PLUGIN.guid .. '.HotIronSize',
		},
	},
})


local function hot_iron_held()
	if not duo_on('HotIron') or not game.CurrentRun or not game.CurrentRun.Hero then return false end
	return game.HeroHasTrait(duo_traits.HotIron) == true
end


local function hot_iron_strike(victim, attacker, triggerArgs)
	if not triggerArgs or triggerArgs.EffectName or not triggerArgs.SourceProjectile then return nil end
	if FIREBALLS[triggerArgs.SourceProjectile] then return nil end
	if not attacker or not game.CurrentRun or attacker ~= game.CurrentRun.Hero then return nil end
	if not hot_iron_held() then return nil end

	local weapon = triggerArgs.SourceWeapon
	if not weapon then return nil end
	local sets = game.WeaponSets
	if not (game.Contains(sets.HeroPrimaryWeapons, weapon) or game.Contains(sets.HeroSecondaryWeapons, weapon)) then
		return nil
	end

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


local function fireballs_first(traits)
	local first, rest = {}, {}
	for _, trait in ipairs(traits) do
		local action = trait.OnEnemyDamagedAction
		if action and fireball_keyed(action.ValidProjectilesLookup) then
			table.insert(first, trait)
		else
			table.insert(rest, trait)
		end
	end
	if #first == 0 then return nil end

	for _, trait in ipairs(rest) do table.insert(first, trait) end
	return first
end


local function restore_traits(hero, original, reordered)
	if hero.Traits ~= reordered then return end

	local kept = game.ToLookup(reordered)
	local merged = {}
	for _, trait in ipairs(original) do
		if kept[trait] then table.insert(merged, trait) end
	end
	local listed = game.ToLookup(merged)
	for _, trait in ipairs(reordered) do
		if not listed[trait] then table.insert(merged, trait) end
	end

	for i = #original, 1, -1 do original[i] = nil end
	for i, trait in ipairs(merged) do original[i] = trait end
	hero.Traits = original
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
	local projectile = hot_iron_strike(victim, attacker, args)
	if not projectile then return base(victim, attacker, args) end

	local hero = game.CurrentRun.Hero
	local original = hero.Traits
	local reordered = original and fireballs_first(original)
	if not reordered then return as_fireball(projectile, base, victim, attacker, args) end

	hero.Traits = reordered
	local ok, result = pcall(as_fireball, projectile, base, victim, attacker, args)
	restore_traits(hero, original, reordered)
	if not ok then error(result, 0) end
	return result
end


local weapon_projectiles


local function strike_projectiles()
	if weapon_projectiles then return weapon_projectiles end

	local lookup = {}
	for _, set in ipairs({ game.WeaponSets.HeroPrimaryWeapons, game.WeaponSets.HeroSecondaryWeapons }) do
		for _, name in ipairs(game.AddLinkedWeapons(set)) do
			lookup[name] = true
			local data = game.WeaponData[name]
			if data and data.ProjectileName then lookup[data.ProjectileName] = true end
		end
	end
	for name in pairs(FIREBALLS) do lookup[name] = nil end

	weapon_projectiles = lookup
	return lookup
end


---@diagnostic disable-next-line: unused-local
function mod.HotIronSize(triggerArgs, _args)
	if not hot_iron_held() then return end
	if not triggerArgs or not triggerArgs.ProjectileId or not triggerArgs.name then return end
	if FIREBALLS[triggerArgs.name] or not strike_projectiles()[triggerArgs.name] then return end
	if not game.HeroHasTrait('BurnSprintBoon') then return end

	local creation = game.TraitData.BurnSprintBoon and game.TraitData.BurnSprintBoon.OnProjectileCreationFunction
	local mult = creation and creation.Args and creation.Args.AreaMultiplier
	if not mult then return end

	game.SetDamageRadiusMultiplier({
		Id = triggerArgs.ProjectileId,
		Fraction = mult,
		Duration = 0,
	})
end
