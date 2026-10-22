---@meta _


local ENLARGED = mod.tuning.StormFront.Enlarged

local STORM_FRONT_ALT = duo_alt('StormFront')

local STORMS = {}
for original, copy in pairs(ENLARGED) do
	table.insert(STORMS, original)
	table.insert(STORMS, copy)
	duo_alias_projectile(original, copy)

	local sources = game.ScreenData.RunClear.DamageSourceMap
	sources[copy] = sources[copy] or sources[original]
end


register_duo({
	key = 'StormFront',

	StatLines = STORM_FRONT_ALT
		and { 'SWuStormFrontAltStatDisplay', 'SWuStormFrontAltSizeStatDisplay' }
		or { 'SWuStormFrontSizeStatDisplay' },
	ExtractValues = with_keyword_extracts({
		{ Key = 'SWuBlitzDamage', ExtractAs = 'TooltipBlitzDamage', SkipAutoExtract = not STORM_FRONT_ALT },
		{ Key = 'SWuStormSize', ExtractAs = 'TooltipStormSize', Format = 'PercentDelta' },
	}, 'Echo', 'SlowField'),

	ExtraFields = {
		SWuBlitzDamage = STORM_FRONT_ALT and mod.tuning.StormFront.BlitzDamage or mod.tuning.StormFront.SparkDamage,
		SWuStormSize = mod.tuning.StormFront.ScaleMultiplier,

		OnEnemyDamagedAction = {
			ValidProjectiles = STORMS,
			ValidProjectilesLookup = game.ToLookup(STORMS),
			FunctionName = _PLUGIN.guid .. '.StormFront',
		},
	},
})


local function storm_front_spark(victim)
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end

	local base = game.GetBaseDataValue({ Type = 'Projectile', Name = 'ProjectileZeusSpark', Property = 'Damage' })
	if type(base) ~= 'number' or base <= 0 then base = 30 end

	game.CreateProjectileFromUnit({
		Name = 'ProjectileZeusSpark',
		Id = hero.ObjectId,
		DestinationId = victim.ObjectId,
		FireFromTarget = true,
		ProjectileCap = 5,
		DamageMultiplier = mod.tuning.StormFront.SparkDamage / base,
		DataProperties = duo_spark_properties(),
	})
end


---@diagnostic disable-next-line: unused-local
function mod.StormFront(victim, _args, _triggerArgs)
	if not duo_on('StormFront') then return end
	if not victim or not victim.ObjectId or victim.IsDead then return end
	local tuning = mod.tuning.StormFront

	if not STORM_FRONT_ALT then
		if game.CheckCooldown('SWuStormFrontSpark' .. victim.ObjectId, tuning.SparkInterval) then
			storm_front_spark(victim)
		end
		return
	end

	if not game.CheckCooldown('SWuStormFrontApply' .. victim.ObjectId, tuning.ApplyInterval) then return end

	duo_apply_blitz(victim, tuning.BlitzDamage)
end


local function storm_front_enlarging(name)
	if not duo_on('StormFront') then return false end
	if not name or not ENLARGED[name] then return false end
	return game.HeroHasTrait(duo_traits.StormFront)
end


function storm_front_enlarge(args)
	if not storm_front_enlarging(args and args.Name) then return args end

	args = game.ShallowCopyTable(args)
	args.Name = ENLARGED[args.Name]
	return args
end


function storm_front_cyclone_args(args)
	if not args or not args.TargetProjectileNames then return args end

	local names = game.ShallowCopyTable(args.TargetProjectileNames)
	table.insert(names, mod.tuning.WinterSolstice.GustProjectile)
	for original, copy in pairs(ENLARGED) do
		if game.Contains(names, original) then table.insert(names, copy) end
	end

	args = game.ShallowCopyTable(args)
	args.TargetProjectileNames = names
	return args
end


function storm_front_clear_recharge(triggerArgs)
	if not duo_on('StormFront') or not STORM_FRONT_ALT then return end
	if not game.HeroHasTrait(duo_traits.StormFront) then return end

	local victim = triggerArgs and triggerArgs.Victim
	local echoes = victim and victim.ActiveEchoes
	local echo = echoes and triggerArgs.EffectName and echoes[triggerArgs.EffectName]
	if not echo then return end

	if not game.CheckCooldown('SWuStormFrontBlitz' .. tostring(victim.ObjectId), mod.tuning.StormFront.BlitzInterval) then
		return
	end

	echo.Cooldown = nil
end
