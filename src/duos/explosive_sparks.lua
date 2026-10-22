---@meta _


register_duo({
	key = 'ExplosiveSparks',

	StatLines = { 'SWuExplosiveSparksStatDisplay', 'SWuExplosiveSparksDamageStatDisplay' },
	ExtractValues = {
		{ Key = 'SWuSparkChance', ExtractAs = 'Chance', Format = 'LuckModifiedPercent', HideSigns = true },
		{ Key = 'SWuSparkDamage', ExtractAs = 'TooltipSparkDamage' },
	},

	ExtraFields = {
		SWuSparkChance = mod.tuning.ExplosiveSparks.Chance,
		SWuSparkDamage = mod.tuning.ExplosiveSparks.Damage,

		OnProjectileDeathFunction = {
			ValidProjectiles = { 'HephCastBlast' },
			ValidProjectilesLookup = game.ToLookup({ 'HephCastBlast' }),
			Name = _PLUGIN.guid .. '.ExplosiveSparks',
		},
	},
})


function mod.ExplosiveSparks(triggerArgs)
	if not duo_on('ExplosiveSparks') then return end
	if not triggerArgs or not triggerArgs.ProjectileId then return end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end

	local tuning = mod.tuning.ExplosiveSparks
	local luck = game.GetTotalHeroTraitValue('LuckMultiplier', { IsMultiplier = true })
	if not game.RandomChance(tuning.Chance * luck) then return end

	local base = game.GetBaseDataValue({ Type = 'Projectile', Name = 'MassiveSlamBlast', Property = 'Damage' })
	if type(base) ~= 'number' or base <= 0 then base = 100 end

	game.CreateProjectileFromUnit({
		Name = 'MassiveSlamBlast',
		Id = hero.ObjectId,
		ProjectileDestinationId = triggerArgs.ProjectileId,
		DamageMultiplier = tuning.Damage / base,
		FireFromTarget = true,
	})
end
