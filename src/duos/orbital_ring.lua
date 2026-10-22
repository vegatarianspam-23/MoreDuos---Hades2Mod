---@meta _


register_duo({
	key = 'OrbitalRing',

	StatLines = { 'SWuOrbitalRingStatDisplay' },
	ExtractValues = with_keyword_extracts({
		{ Key = 'SWuDamagePerCast', ExtractAs = 'TooltipPerCast', Format = 'Percent' },
	}, 'Link'),

	ExtraFields = {
		SWuDamagePerCast = mod.tuning.OrbitalRing.DamagePerCast,
		SWuOrbitalRingMultiplier = 1,

		AddOutgoingDamageModifiers = {
			UseTraitValue = 'SWuOrbitalRingMultiplier',
			IsMultiplier = true,
		},

		OnWeaponFiredFunctions = {
			ValidWeapons = game.WeaponSets.HeroNonPhysicalWeapons,
			ValidWeaponsLookup = game.ToLookup(game.WeaponSets.HeroNonPhysicalWeapons),
			FunctionName = _PLUGIN.guid .. '.OrbitalRingPull',
			ExcludeLinked = true,
		},

		OnProjectileCreationFunction = {
			ValidProjectiles = { 'ProjectileCast' },
			ValidProjectilesLookup = game.ToLookup({ 'ProjectileCast' }),
			Name = _PLUGIN.guid .. '.OrbitalRingLaid',
		},
	},
})


local function orbital_ring_movable(unit)
	if not unit or not unit.ObjectId or unit.IsDead then return false end

	if is_allied_summon(unit) then return true end

	if unit.IsBoss or unit.UseBossHealthBar then return false end
	if unit.ImmuneToPolymorph or unit.ImmobileRaise then return false end
	if duo_ignores(unit) then return false end

	return unit.ActiveEffects ~= nil and unit.ActiveEffects.DamageShareEffect ~= nil
end


---@diagnostic disable-next-line: unused-local
function mod.OrbitalRingPull(_weaponData, _args, triggerArgs)
	if not duo_on('OrbitalRing') then return end
	if not triggerArgs or not triggerArgs.ProjectileX or not triggerArgs.ProjectileY then return end

	local caught = {}
	for _, unit in pairs(game.ActiveEnemies or {}) do
		if orbital_ring_movable(unit) then
			table.insert(caught, unit)
		end
	end
	if game.IsEmpty(caught) then return end

	local circleId = game.SpawnObstacle({
		Name = 'InvisibleTarget',
		LocationX = triggerArgs.ProjectileX,
		LocationY = triggerArgs.ProjectileY,
	})

	local scatter = mod.tuning.OrbitalRing.Scatter
	for index, unit in ipairs(caught) do
		local offset = game.CalcOffset(math.rad(index * (360 / #caught)), scatter)

		game.TeleportSummonPresentation(unit.ObjectId)
		game.Teleport({
			Id = unit.ObjectId,
			DestinationId = circleId,
			OffsetX = offset.X,
			OffsetY = offset.Y,
		})
		game.TeleportSummonPresentation(unit.ObjectId)
	end

	game.DestroyOnDelay({ circleId }, 1)
end


---@diagnostic disable-next-line: unused-local
function mod.OrbitalRingLaid(triggerArgs, _args)
	if not duo_on('OrbitalRing') then return end
	if not triggerArgs or not triggerArgs.ProjectileId then return end

	game.SessionMapState.SWuOrbitalRings = game.SessionMapState.SWuOrbitalRings or {}
	game.SessionMapState.SWuOrbitalRings[triggerArgs.ProjectileId] = true
end


local function orbital_ring_casts_holding(victim)
	local rings = game.SessionMapState and game.SessionMapState.SWuOrbitalRings
	if not rings or not victim or not victim.ObjectId then return 0 end

	local count = 0
	for projectileId in pairs(rings) do
		if not game.ProjectileExists({ Id = projectileId }) then
			rings[projectileId] = nil
		else
			local location = game.GetLocation({ IsProjectile = true, Id = projectileId })
			local radius = game.GetProjectileProperty({ ProjectileId = projectileId, Property = 'ModifiedDamageRadius' })

			if location and radius then
				local centerId = game.SpawnObstacle({
					Name = 'InvisibleTarget',
					LocationX = location.X,
					LocationY = location.Y,
				})
				local distance = game.GetDistance({ Id = centerId, DestinationId = victim.ObjectId })
				game.Destroy({ Id = centerId })

				if distance and distance <= radius then
					count = count + 1
				end
			end
		end
	end

	return count
end


local function orbital_ring_multiplier(victim)
	if not duo_on('OrbitalRing') then return 1 end
	if not game.HeroHasTrait(duo_traits.OrbitalRing) then return 1 end
	if not victim or duo_ignores(victim) then return 1 end

	if not victim.ActiveEffects or not victim.ActiveEffects.ImpactSlow then return 1 end

	local casts = orbital_ring_casts_holding(victim)
	if casts <= 0 then return 1 end

	return 1 + casts * mod.tuning.OrbitalRing.DamagePerCast
end


function orbital_ring_refresh(attacker, victim)
	local trait = duo_traits.OrbitalRing and game.GetHeroTrait(duo_traits.OrbitalRing)
	if not trait then return end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	trait.SWuOrbitalRingMultiplier = (hero and attacker == hero) and orbital_ring_multiplier(victim) or 1
end
