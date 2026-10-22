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

	game.CreateProjectileFromUnit({
		Name = tuning.Blade,
		Id = hero.ObjectId,
		DestinationId = victim.ObjectId,
		DamageMultiplier = tuning.BladeDamage / base,
		FireFromTarget = true,
	})
end
