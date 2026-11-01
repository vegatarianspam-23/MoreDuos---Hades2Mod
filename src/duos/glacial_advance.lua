---@meta _


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


register_duo({
	key = 'GlacialAdvance',

	StatLines = { 'SWuGlacialAdvanceStatDisplay' },
	ExtractValues = with_keyword_extracts({
		{ Key = 'SWuWaveDamage', ExtractAs = 'TooltipWaveDamage', IncludeSigns = true },
	}, 'Root'),

	ExtraFields = {
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
	},
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


function mod.GlacialAdvance(victim, args, triggerArgs)
	if not duo_on('GlacialAdvance') then return end
	local source = triggerArgs and triggerArgs.SourceProjectile
	if CIRCLES[source] and not glacial_advance_circle_splashes(source) then return end
	game.ApplyRoot(victim, args, triggerArgs)
end


function glacial_advance_power(attacker, triggerArgs)
	if not duo_on('GlacialAdvance') then return 0 end
	if not triggerArgs or triggerArgs.EffectName or not CIRCLES[triggerArgs.SourceProjectile] then return 0 end
	if attacker ~= (game.CurrentRun and game.CurrentRun.Hero) then return 0 end
	if not game.HeroHasTrait(duo_traits.GlacialAdvance) then return 0 end
	if not glacial_advance_circle_splashes(triggerArgs.SourceProjectile) then return 0 end

	return mod.tuning.GlacialAdvance.BonusDamage
end


---@diagnostic disable-next-line: unused-local
function mod.GlacialAdvanceSize(triggerArgs, _args)
	if not duo_on('GlacialAdvance') then return end
	if not triggerArgs or not triggerArgs.ProjectileId then return end

	game.SetDamageRadiusMultiplier({
		Id = triggerArgs.ProjectileId,
		Fraction = mod.tuning.GlacialAdvance.WaveScale,
		Duration = 0,
	})
end
