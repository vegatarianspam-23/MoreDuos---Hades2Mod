---@meta _


local BLADES = {
	'ProjectileAresSwordWake',
	'ProjectileAresSwordCast',
	'ProjectileAresSwordEx',
	'ProjectileAresSwordGenerated',
}


register_duo({
	key = 'BleedingHeart',

	StatLines = { 'SWuBleedingHeartStatDisplay', 'SWuBleedingHeartWeakStatDisplay' },
	ExtractValues = with_keyword_extracts({
		{ Key = 'SWuBladeDamage', ExtractAs = 'TooltipBladeDamage' },
		{ Key = 'SWuWeakMultiplier', ExtractAs = 'TooltipWeakDamage', Format = 'PercentDelta' },
	}, 'Rend', 'Weak'),

	ExtraFields = {
		SWuBladeDamage = mod.tuning.BleedingHeart.BladeDamage,
		SWuWeakMultiplier = mod.tuning.BleedingHeart.WeakMultiplier,

		AddOutgoingDamageModifiers = {
			ValidProjectiles = BLADES,
			ValidProjectilesLookup = game.ToLookup(BLADES),
			ValidActiveEffects = { 'WeakEffect' },
			ValidWeaponMultiplier = mod.tuning.BleedingHeart.WeakMultiplier,
		},
	},
})


function bleeding_heart_blade(triggerArgs)
	if not duo_on('BleedingHeart') then return end
	if not game.HeroHasTrait(duo_traits.BleedingHeart) then return end
	if not triggerArgs or triggerArgs.Reapplied then return end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	local victim = triggerArgs.Victim
	if not hero or not victim or not victim.ObjectId or victim.IsDead then return end
	if not victim.ActiveEffects or not victim.ActiveEffects.WeakEffect then return end

	local tuning = mod.tuning.BleedingHeart
	local base = game.GetBaseDataValue({ Type = 'Projectile', Name = tuning.Blade, Property = 'Damage' })
	if type(base) ~= 'number' or base <= 0 then base = 100 end

	local bladeId = game.CreateProjectileFromUnit({
		Name = tuning.Blade,
		Id = hero.ObjectId,
		DestinationId = victim.ObjectId,
		DamageMultiplier = tuning.BladeDamage / base,
		FireFromTarget = true,
	})

	if bladeId then
		local blades = game.SessionMapState.SWuBleedingHeartBlades or {}
		game.SessionMapState.SWuBleedingHeartBlades = blades
		blades[bladeId] = true
	end
end


function bleeding_heart_meter(base, victim, triggerArgs)
	local blades = game.SessionMapState.SWuBleedingHeartBlades
	local projectileId = triggerArgs and triggerArgs.ProjectileId
	if not blades or not projectileId or not blades[projectileId] then return base(victim, triggerArgs) end

	local blade = mod.tuning.BleedingHeart.Blade
	local states = { game.CurrentRun, game.GameState }
	local before = {}
	for i, state in ipairs(states) do
		local record = state and state.DamageDealtByHeroRecord
		before[i] = record and record[blade] or 0
	end

	local result = base(victim, triggerArgs)

	local source = mod.tuning.BleedingHeart.MeterSource
	for i, state in ipairs(states) do
		local record = state and state.DamageDealtByHeroRecord
		local dealt = record and (record[blade] or 0) - before[i] or 0
		if dealt > 0 then
			record[blade] = record[blade] - dealt
			if record[blade] <= 0 then record[blade] = nil end
			record[source] = (record[source] or 0) + dealt
		end
	end

	return result
end
