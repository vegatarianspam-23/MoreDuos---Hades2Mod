---@meta _


local WAVES = {
	'PoseidonSplashSplinter',
	'PoseidonSprintBlast',
	'PoseidonSprintSecondaryBlast',
	'PoseidonOmegaWave',
	'PoseidonCollisionBlast',
}

local BALL = 'ProjectileSprintBall'

local STRUCK = game.ConcatTableValues(game.ShallowCopyTable(WAVES), { BALL })


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


function glacial_advance_ball_splashes()
	local group = game.LinkedTraitData.SWuSplashBonusTraits
	return group ~= nil and game.Contains(group, 'PoseidonSplashSprintBoon')
end


function mod.GlacialAdvance(victim, args, triggerArgs)
	if not duo_on('GlacialAdvance') then return end
	if triggerArgs and triggerArgs.SourceProjectile == BALL and not glacial_advance_ball_splashes() then return end
	game.ApplyRoot(victim, args, triggerArgs)
end


function glacial_advance_power(attacker, triggerArgs)
	if not duo_on('GlacialAdvance') then return 0 end
	if not triggerArgs or triggerArgs.EffectName or triggerArgs.SourceProjectile ~= BALL then return 0 end
	if attacker ~= (game.CurrentRun and game.CurrentRun.Hero) then return 0 end
	if not game.HeroHasTrait(duo_traits.GlacialAdvance) or not glacial_advance_ball_splashes() then return 0 end

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
