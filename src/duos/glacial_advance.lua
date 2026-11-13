---@meta _


local GLACIAL_ADVANCE_ALT = duo_alt('GlacialAdvance')

local SWELL = 'PoseidonOmegaWave'
local CHILL = 'LegacyChillEffect'
local ICY_SWELL = mod.tuning.GlacialAdvance.SwellProjectile

duo_alias_projectile(SWELL, ICY_SWELL)
do
	local sources = game.ScreenData.RunClear.DamageSourceMap
	sources[ICY_SWELL] = sources[ICY_SWELL] or sources[SWELL]
end

local SWELLS = { [SWELL] = true, [ICY_SWELL] = true }

local WAVES = {
	'PoseidonSplashSplinter',
	'PoseidonSprintBlast',
	'PoseidonSprintSecondaryBlast',
	'PoseidonOmegaWave',
	'PoseidonCollisionBlast',
}

local CIRCLES = {
	ProjectileSprintBall = { 'PoseidonSplashSprintBoon' },
	PoseidonCastSplashSplinter = { 'PoseidonCastBoon', 'PoseidonExCastBoon', 'PoseidonSplashSprintBoon' },
	PoseidonCastImpulse = { 'PoseidonExCastBoon' },
}

local STRUCK = game.ShallowCopyTable(WAVES)
for name in pairs(CIRCLES) do table.insert(STRUCK, name) end
table.insert(STRUCK, ICY_SWELL)


local function glacial_advance_alt_fields()
	return {
		SWuWaveDamage = mod.tuning.GlacialAdvance.BonusDamage,

		OnEnemyDamagedAction = {
			ValidProjectiles = STRUCK,
			ValidProjectilesLookup = game.ToLookup(STRUCK),
			FunctionName = _PLUGIN.guid .. '.GlacialAdvance',
			Args = { EffectName = 'ChillEffect' },
		},

		AddOutgoingDamageModifiers = {
			ValidProjectiles = WAVES,
			ValidProjectilesLookup = game.ToLookup(WAVES),
			ValidBaseDamageAddition = mod.tuning.GlacialAdvance.BonusDamage,
		},

		OnProjectileCreationFunction = {
			ValidProjectiles = WAVES,
			ValidProjectilesLookup = game.ToLookup(WAVES),
			Name = _PLUGIN.guid .. '.GlacialAdvanceSize',
		},
	}
end


local function glacial_advance_fields()
	return {
		SWuSwellChance = mod.tuning.GlacialAdvance.SwellChance,
		SWuSwellDamage = mod.tuning.GlacialAdvance.SwellDamage,

		OnEnemyDamagedAction = {
			ValidProjectiles = STRUCK,
			ValidProjectilesLookup = game.ToLookup(STRUCK),
			FunctionName = _PLUGIN.guid .. '.GlacialAdvance',
			Args = { EffectName = 'ChillEffect' },
		},
	}
end


register_duo({
	key = 'GlacialAdvance',

	StatLines = GLACIAL_ADVANCE_ALT
		and { 'SWuGlacialAdvanceStatDisplay' }
		or { 'SWuGlacialAdvanceChanceStatDisplay', 'SWuGlacialAdvanceDamageStatDisplay' },
	ExtractValues = GLACIAL_ADVANCE_ALT
		and with_keyword_extracts({
			{ Key = 'SWuWaveDamage', ExtractAs = 'TooltipWaveDamage', IncludeSigns = true },
		}, 'Root')
		or with_keyword_extracts({
			{ Key = 'SWuSwellChance', ExtractAs = 'Chance', Format = 'LuckModifiedPercent', HideSigns = true },
			{ Key = 'SWuSwellDamage', ExtractAs = 'TooltipSwellDamage' },
		}, 'SlowField'),

	ExtraFields = GLACIAL_ADVANCE_ALT and glacial_advance_alt_fields() or glacial_advance_fields(),
})


function glacial_advance_circle_splashes(projectileName)
	local sources = CIRCLES[projectileName]
	local group = game.LinkedTraitData.SWuSplashBonusTraits
	if not sources or not group then return false end

	for _, traitName in ipairs(sources) do
		if game.Contains(group, traitName) then return true end
	end
	return false
end


local glacialAdvanceChill = { EffectName = CHILL }

local function glacial_advance_chill(victim)
	local hero = game.CurrentRun and game.CurrentRun.Hero
	local chill = game.EffectData and game.EffectData[CHILL]
	if not hero or not chill or not victim or not victim.ObjectId or victim.IsDead then return end

	if glacialAdvanceChill.Source ~= chill.EffectData then
		glacialAdvanceChill.Source = chill.EffectData
		glacialAdvanceChill.DataProperties = game.MergeAllTables({ chill.EffectData })
	end

	game.ApplyEffect({
		DestinationId = victim.ObjectId,
		Id = hero.ObjectId,
		EffectName = CHILL,
		DataProperties = glacialAdvanceChill.DataProperties,
	})
end


local function glacial_advance_swell(victim, triggerArgs)
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero or not victim or not victim.ObjectId or victim.IsDead then return end

	local tuning = mod.tuning.GlacialAdvance
	local luck = game.GetTotalHeroTraitValue('LuckMultiplier', { IsMultiplier = true })
	if not game.RandomChance(tuning.SwellChance * luck) then return end
	if tuning.SwellCooldown > 0 and not game.CheckCooldown('SWuGlacialAdvanceSwell', tuning.SwellCooldown) then return end

	local name = game.ProjectileData[ICY_SWELL] and ICY_SWELL or SWELL
	local base = game.GetBaseDataValue({ Type = 'Projectile', Name = name, Property = 'Damage' })
	if type(base) ~= 'number' or base <= 0 then base = tuning.SwellDamage end

	local angle = triggerArgs and triggerArgs.ImpactAngle
	if type(angle) ~= 'number' then
		angle = game.GetAngleBetween({ Id = hero.ObjectId, DestinationId = victim.ObjectId })
	end

	game.CreateProjectileFromUnit({
		Name = name,
		Id = hero.ObjectId,
		Angle = angle,
		DamageMultiplier = tuning.SwellDamage / base,
		FireFromTarget = true,
		ProjectileCap = 2,
	})
end


function mod.GlacialAdvance(victim, args, triggerArgs)
	if not duo_on('GlacialAdvance') then return end
	local source = triggerArgs and triggerArgs.SourceProjectile
	if CIRCLES[source] and not glacial_advance_circle_splashes(source) then return end

	if GLACIAL_ADVANCE_ALT then
		game.ApplyRoot(victim, args, triggerArgs)
		return
	end

	if SWELLS[source] then
		glacial_advance_chill(victim)
		return
	end

	glacial_advance_swell(victim, triggerArgs)
end


function glacial_advance_power(attacker, triggerArgs)
	if not duo_on('GlacialAdvance') or not GLACIAL_ADVANCE_ALT then return 0 end
	if not triggerArgs or triggerArgs.EffectName or not CIRCLES[triggerArgs.SourceProjectile] then return 0 end
	if attacker ~= (game.CurrentRun and game.CurrentRun.Hero) then return 0 end
	if not game.HeroHasTrait(duo_traits.GlacialAdvance) then return 0 end
	if not glacial_advance_circle_splashes(triggerArgs.SourceProjectile) then return 0 end

	return mod.tuning.GlacialAdvance.BonusDamage
end


---@diagnostic disable-next-line: unused-local
function mod.GlacialAdvanceSize(triggerArgs, _args)
	if not duo_on('GlacialAdvance') or not GLACIAL_ADVANCE_ALT then return end
	if not triggerArgs or not triggerArgs.ProjectileId then return end

	game.SetDamageRadiusMultiplier({
		Id = triggerArgs.ProjectileId,
		Fraction = mod.tuning.GlacialAdvance.WaveScale,
		Duration = 0,
	})
end
