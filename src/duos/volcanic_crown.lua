---@meta _


local EMBER = mod.tuning.VolcanicCrown.EmberProjectile


once('VolcanicCrownProjectiles', function()
	duo_alias_projectile('HestiaSprintPuddle', EMBER)
	duo_alias_projectile('MassiveSlamBlast', mod.tuning.VolcanicCrown.BlastProjectile)
	duo_alias_projectile('ProjectileFireball', mod.tuning.VolcanicCrown.FireballProjectile)
end)


register_duo({
	key = 'VolcanicCrown',

	StatLines = { 'SWuVolcanicCrownBlastStatDisplay', 'SWuVolcanicCrownStatDisplay' },
	ExtractValues = {
		{ Key = 'SWuBlastDamage', ExtractAs = 'TooltipBlastDamage' },
		{ Key = 'SWuFireballDamage', ExtractAs = 'TooltipFireballDamage' },
	},

	ExtraFields = {
		SWuBlastDamage = mod.tuning.VolcanicCrown.CentreDamage,
		SWuFireballDamage = mod.tuning.VolcanicCrown.FireballDamage,

		OnProjectileDeathFunction = {
			ValidProjectiles = { 'ProjectileCast' },
			ValidProjectilesLookup = game.ToLookup({ 'ProjectileCast' }),
			Name = _PLUGIN.guid .. '.VolcanicCrown',
		},
	},
})


local function volcanic_crown_damage(projectileName, wanted)
	local base = game.GetBaseDataValue({ Type = 'Projectile', Name = projectileName, Property = 'Damage' })
	if type(base) ~= 'number' or base <= 0 then return 1 end
	return wanted / base
end


---@diagnostic disable-next-line: unused-local
function mod.VolcanicCrown(triggerArgs, _args)
	if not duo_on('VolcanicCrown') then return end
	if not triggerArgs or not triggerArgs.Armed or not triggerArgs.Detonated then return end
	if not triggerArgs.LocationX or not triggerArgs.LocationY then return end

	local repeats = game.SessionMapState.InvalidRepeatCastIds
	if repeats and repeats[triggerArgs.ProjectileId] then return end

	game.SessionMapState.SWuVolcanicCrownFired = game.SessionMapState.SWuVolcanicCrownFired or {}
	if game.SessionMapState.SWuVolcanicCrownFired[triggerArgs.ProjectileId] then return end
	game.SessionMapState.SWuVolcanicCrownFired[triggerArgs.ProjectileId] = true

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end

	local tuning = mod.tuning.VolcanicCrown
	local centerId = game.SpawnObstacle({
		Name = 'InvisibleTarget',
		LocationX = triggerArgs.LocationX,
		LocationY = triggerArgs.LocationY,
	})

	local radius = volcanic_crown_cast_radius(triggerArgs)

	game.thread(volcanic_crown_blast, triggerArgs.LocationX, triggerArgs.LocationY, radius)

	local fireballScale = (radius / tuning.CastRadius) * tuning.FireballSize

	for i = 1, tuning.Fireballs do
		game.CreateProjectileFromUnit({
			Name = tuning.FireballProjectile,
			Id = hero.ObjectId,
			DestinationId = centerId,
			Angle = (i - 1) * (360 / tuning.Fireballs),
			FireFromTarget = true,
			DamageMultiplier = volcanic_crown_damage(tuning.FireballProjectile, tuning.FireballDamage),
			ScaleMultiplier = fireballScale,
		})
	end

	game.thread(volcanic_crown_embers, triggerArgs.LocationX, triggerArgs.LocationY, radius)
	game.DestroyOnDelay({ centerId }, 1)
end


function volcanic_crown_blast(x, y, radius)
	local tuning = mod.tuning.VolcanicCrown
	game.waitUnmodified(tuning.BlastDelay)

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end

	local wanted = (radius or tuning.CastRadius) * tuning.BlastSize
	local scale = wanted / tuning.BlastRadius

	local centerId = game.SpawnObstacle({ Name = 'InvisibleTarget', LocationX = x, LocationY = y })
	local blastId = game.CreateProjectileFromUnit({
		Name = tuning.BlastProjectile,
		Id = hero.ObjectId,
		DestinationId = centerId,
		FireFromTarget = true,
		DamageMultiplier = volcanic_crown_damage(tuning.BlastProjectile, tuning.CentreDamage),
		ScaleMultiplier = scale,
	})
	if blastId then
		game.SetAnimation({ DestinationId = blastId, Name = 'Blank' })
	end

	local impactId = game.SpawnObstacle({ Name = 'BlankObstacle', LocationX = x, LocationY = y })
	game.SetAnimation({
		Name = 'HephMassiveHitFixed',
		DestinationId = impactId,
		Scale = tuning.CentreScale * scale,
	})

	game.DestroyOnDelay({ centerId }, 1)
	game.DestroyOnDelay({ impactId }, 2)
end


function volcanic_crown_embers(x, y, radius)
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end

	local tuning = mod.tuning.VolcanicCrown
	local scale = ((radius or tuning.CastRadius) * tuning.EmberSize) / tuning.EmberRadius
	local elapsed = 0

	while elapsed < tuning.EmberDuration do
		local markId = game.SpawnObstacle({ Name = 'InvisibleTarget', LocationX = x, LocationY = y })
		game.CreateProjectileFromUnit({
			Name = tuning.EmberProjectile,
			Id = hero.ObjectId,
			DestinationId = markId,
			FireFromTarget = true,
			DamageMultiplier = volcanic_crown_damage(tuning.EmberProjectile, tuning.CoalDamage),
			ScaleMultiplier = scale,
		})
		game.DestroyOnDelay({ markId }, 1)

		game.wait(tuning.EmberRefresh, game.RoomThreadName)
		elapsed = elapsed + tuning.EmberRefresh
	end
end


function volcanic_crown_ember(triggerArgs)
	return triggerArgs ~= nil and triggerArgs.SourceProjectile == EMBER
end


function volcanic_crown_cast_radius(triggerArgs)
	local tuning = mod.tuning.VolcanicCrown

	if triggerArgs and triggerArgs.ProjectileId then
		local ok, modified = pcall(game.GetProjectileProperty, {
			ProjectileId = triggerArgs.ProjectileId,
			Property = 'ModifiedDamageRadius',
		})
		if ok and type(modified) == 'number' and modified > 0 then return modified end
	end

	local radius = tuning.CastRadius

	for _, traitArgs in pairs(game.GetHeroTraitValues('CastProjectileModifiers')) do
		local increase = traitArgs and traitArgs.AreaIncrease
		if type(increase) == 'number' and increase > 0 then
			radius = radius * increase
		end
	end

	return radius
end
