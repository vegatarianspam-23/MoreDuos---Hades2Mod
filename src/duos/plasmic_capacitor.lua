---@meta _


local PLASMIC_CAPACITOR_DROPS = duo_alt('PlasmicCapacitor', 'Alt')
local PLASMIC_CAPACITOR_SPARKS = duo_alt('PlasmicCapacitor', 'Alt2')
local PLASMIC_CAPACITOR_OVERFLOW = not duo_alt('PlasmicCapacitor')


local function plasmic_capacitor_spec()
	local tuning = mod.tuning.PlasmicCapacitor

	if PLASMIC_CAPACITOR_OVERFLOW then
		return {
			StatLines = { 'SWuPlasmicCapacitorBonusStatDisplay' },
			ExtractValues = {
				{ Key = 'SWuPlasmaBonus', ExtractAs = 'TooltipPlasmaBonus', Format = 'Percent', IncludeSigns = true },
				{ Key = 'SWuArcDamage', ExtractAs = 'TooltipArcDamage', SkipAutoExtract = true },
				{ Key = 'SWuPlasmaCap', ExtractAs = 'TooltipPlasmaCap', SkipAutoExtract = true },
			},
			ExtraFields = {
				SWuPlasmaBonus = tuning.PlasmaBonus,
				SWuArcDamage = tuning.ArcDamage,
				SWuPlasmaCap = tuning.PlasmaCap,

				BloodDropMultiplier = 1 + tuning.PlasmaBonus,
			},
		}
	end

	return {
		StatLines = {
			PLASMIC_CAPACITOR_DROPS and 'SWuPlasmicCapacitorAltCeilingStatDisplay'
				or 'SWuPlasmicCapacitorAlt2CeilingStatDisplay',
		},
		ExtractValues = with_keyword_extracts({
			{ Key = 'SWuArcDamage', ExtractAs = 'TooltipArcDamage' },
			{ Key = 'SWuPlasmaCeiling', ExtractAs = 'TooltipPlasmaCeiling' },
			{ Key = 'SWuPlasmaMin', ExtractAs = 'TooltipPlasmaMin', SkipAutoExtract = true },
			{ Key = 'SWuPlasmaMax', ExtractAs = 'TooltipPlasmaMax', SkipAutoExtract = true },
			{ Key = 'SWuPlasmaMultiplier', ExtractAs = 'TooltipPlasmaMultiplier', DecimalPlaces = 1,
				SkipAutoExtract = true },
		}, 'Echo'),
		ExtraFields = {
			SWuArcDamage = tuning.ArcDamage,
			SWuPlasmaCeiling = tuning.PlasmaCeiling,
			SWuPlasmaMin = tuning.PlasmaMin,
			SWuPlasmaMax = tuning.PlasmaMax,
			SWuPlasmaMultiplier = tuning.Alt2PlasmaMultiplier,

			BloodDropMultiplier = PLASMIC_CAPACITOR_SPARKS and tuning.Alt2PlasmaMultiplier or nil,
		},
	}
end


local spec = plasmic_capacitor_spec()
spec.key = 'PlasmicCapacitor'
local plasmicCapacitor = register_duo(spec)


if plasmicCapacitor and not PLASMIC_CAPACITOR_OVERFLOW then
	game.ConsumableData.BloodDrop.SpawnCap = mod.tuning.PlasmicCapacitor.PlasmaSpawnCap
end


function plasmic_capacitor_drop(enemy)
	if not duo_on('PlasmicCapacitor') or not PLASMIC_CAPACITOR_DROPS then return end
	if not game.HeroHasTrait(duo_traits.PlasmicCapacitor) then return end
	if not enemy or not enemy.ObjectId then return end

	local tuning = mod.tuning.PlasmicCapacitor
	for _ = 1, game.RandomInt(tuning.PlasmaMin, tuning.PlasmaMax) do
		game.thread(game.CreateBloodDrop, enemy, { Name = 'BloodDrop' })
	end
end


function plasmic_capacitor_update_speed(base, functionArgs, healthChange)
	local room = game.CurrentRun and game.CurrentRun.CurrentRoom
	local cap = mod.tuning.PlasmicCapacitor.PlasmaCap
	local count = room and room.BloodDropCount or 0
	if not PLASMIC_CAPACITOR_OVERFLOW or not duo_on('PlasmicCapacitor') or count <= cap
		or not game.HeroHasTrait(duo_traits.PlasmicCapacitor) then
		return base(functionArgs, healthChange)
	end

	room.BloodDropCount = cap
	base(functionArgs, healthChange)
	room.BloodDropCount = math.max(room.BloodDropCount or 0, count)
	room.BloodDropBonus = math.min(room.BloodDropBonus or 0, cap * game.ConsumableData.BloodDrop.SpeedBonus * 100)
end


function plasmic_capacitor_raise_ceiling()
	if not duo_on('PlasmicCapacitor') or PLASMIC_CAPACITOR_OVERFLOW then return end
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


local function plasmic_capacitor_fires()
	if PLASMIC_CAPACITOR_DROPS then return true end
	if not PLASMIC_CAPACITOR_OVERFLOW then return false end

	local room = game.CurrentRun and game.CurrentRun.CurrentRoom
	return room ~= nil and (room.BloodDropCount or 0) > mod.tuning.PlasmicCapacitor.PlasmaCap
end


function plasmic_capacitor_bolt()
	if not duo_on('PlasmicCapacitor') or not plasmic_capacitor_fires() then return end
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
		Angle = game.GetAngleBetween({ Id = hero.ObjectId, DestinationId = targetId }),
		ProjectileCap = 5,
		DamageMultiplier = mod.tuning.PlasmicCapacitor.ArcDamage / base,
		DataProperties = duo_spark_properties(),
	})
end


function plasmic_capacitor_spark_power(attacker, _victim, triggerArgs)
	if not duo_on('PlasmicCapacitor') or not PLASMIC_CAPACITOR_SPARKS then return 0 end
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
