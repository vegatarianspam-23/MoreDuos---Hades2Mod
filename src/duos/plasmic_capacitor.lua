---@meta _


local PLASMIC_CAPACITOR_ALT = duo_alt('PlasmicCapacitor')


local plasmicCapacitor = register_duo({
	key = 'PlasmicCapacitor',

	StatLines = { PLASMIC_CAPACITOR_ALT and 'SWuPlasmicCapacitorAltCeilingStatDisplay' or 'SWuPlasmicCapacitorCeilingStatDisplay' },
	ExtractValues = with_keyword_extracts({
		{ Key = 'SWuArcDamage', ExtractAs = 'TooltipArcDamage' },
		{ Key = 'SWuPlasmaCeiling', ExtractAs = 'TooltipPlasmaCeiling' },
		{ Key = 'SWuPlasmaMin', ExtractAs = 'TooltipPlasmaMin', SkipAutoExtract = true },
		{ Key = 'SWuPlasmaMax', ExtractAs = 'TooltipPlasmaMax', SkipAutoExtract = true },
		{ Key = 'SWuPlasmaMultiplier', ExtractAs = 'TooltipPlasmaMultiplier', DecimalPlaces = 1,
			SkipAutoExtract = true },
	}, 'Echo'),

	ExtraFields = {
		SWuArcDamage = mod.tuning.PlasmicCapacitor.ArcDamage,
		SWuPlasmaCeiling = mod.tuning.PlasmicCapacitor.PlasmaCeiling,
		SWuPlasmaMin = mod.tuning.PlasmicCapacitor.PlasmaMin,
		SWuPlasmaMax = mod.tuning.PlasmicCapacitor.PlasmaMax,
		SWuPlasmaMultiplier = mod.tuning.PlasmicCapacitor.PlasmaMultiplier,

		BloodDropMultiplier = not PLASMIC_CAPACITOR_ALT and mod.tuning.PlasmicCapacitor.PlasmaMultiplier or nil,
	},
})


local function plasmic_capacitor_sparking()
	return not PLASMIC_CAPACITOR_ALT
end


if plasmicCapacitor then
	game.ConsumableData.BloodDrop.SpawnCap = mod.tuning.PlasmicCapacitor.PlasmaSpawnCap
end


function plasmic_capacitor_drop(enemy)
	if not duo_on('PlasmicCapacitor') or plasmic_capacitor_sparking() then return end
	if not game.HeroHasTrait(duo_traits.PlasmicCapacitor) then return end
	if not enemy or not enemy.ObjectId then return end

	local tuning = mod.tuning.PlasmicCapacitor
	for _ = 1, game.RandomInt(tuning.PlasmaMin, tuning.PlasmaMax) do
		game.thread(game.CreateBloodDrop, enemy, { Name = 'BloodDrop' })
	end
end


function plasmic_capacitor_raise_ceiling()
	if not duo_on('PlasmicCapacitor') then return end
	if not game.HeroHasTrait(duo_traits.PlasmicCapacitor) then return end

	local room = game.CurrentRun and game.CurrentRun.CurrentRoom
	if not room then return end

	local count = math.min(room.BloodDropCount or 0, mod.tuning.PlasmicCapacitor.PlasmaCeiling)
	room.BloodDropBonus = count * game.ConsumableData.BloodDrop.SpeedBonus * 100
end


function plasmic_capacitor_show_counter()
	if not duo_on('PlasmicCapacitor') then return end
	if not in_run() or not game.HeroHasTrait(duo_traits.PlasmicCapacitor) then return end
	game.SetupBloodDropDisplay()
end


function plasmic_capacitor_bolt()
	if not duo_on('PlasmicCapacitor') or plasmic_capacitor_sparking() then return end
	if not game.HeroHasTrait(duo_traits.PlasmicCapacitor) then return end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end

	local targetId = (game.GetClosestIds({
		Id = hero.ObjectId,
		DestinationName = 'EnemyTeam',
		IgnoreInvulnerable = true,
		StopsProjectiles = true,
		IgnoreHomingIneligible = true,
		IgnoreSelf = true,
		Distance = mod.tuning.PlasmicCapacitor.BoltRange,
	}) or {})[1]
	if not targetId then return end

	local base = game.GetBaseDataValue({ Type = 'Projectile', Name = 'ProjectileZeusSpark', Property = 'Damage' })
	if type(base) ~= 'number' or base <= 0 then base = 30 end

	game.CreateProjectileFromUnit({
		Name = 'ProjectileZeusSpark',
		Id = hero.ObjectId,
		DestinationId = targetId,
		FireFromTarget = true,
		ProjectileCap = 5,
		DamageMultiplier = mod.tuning.PlasmicCapacitor.ArcDamage / base,
		DataProperties = duo_spark_properties(),
	})
end


function plasmic_capacitor_spark_power(attacker, _victim, triggerArgs)
	if not duo_on('PlasmicCapacitor') or PLASMIC_CAPACITOR_ALT then return 0 end
	if not triggerArgs or triggerArgs.EffectName or triggerArgs.SourceProjectile ~= 'ProjectileZeusSpark' then
		return 0
	end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if attacker ~= hero then return 0 end
	if not game.HeroHasTrait(duo_traits.PlasmicCapacitor) then return 0 end

	local tuning = mod.tuning.PlasmicCapacitor
	local room = game.CurrentRun.CurrentRoom
	local held = math.min((room and room.BloodDropCount) or 0, tuning.PlasmaCeiling)
	return math.max(held - tuning.SparkPowerThreshold, 0) * tuning.SparkPowerPerPlasma
end
