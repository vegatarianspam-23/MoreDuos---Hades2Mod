---@meta _


local GLOW = 'DelayedKnockbackEffect'


register_duo({
	key = 'GlowingBrand',

	StatLines = { 'SWuGlowingBrandPotencyStatDisplay', 'SWuGlowingBrandDurationStatDisplay' },
	ExtractValues = with_keyword_extracts({
		{ Key = 'SWuGlowPotency', ExtractAs = 'TooltipGlowPotency', Format = 'PercentDelta' },
		{ Key = 'SWuGlowDuration', ExtractAs = 'TooltipGlowDuration', Format = 'PercentDelta' },
	}, 'DelayedKnockback'),

	ExtraFields = {
		SWuGlowPotency = mod.tuning.GlowingBrand.GlowPotency,
		SWuGlowDuration = mod.tuning.GlowingBrand.GlowDuration,

		OnEnemyDamagedAction = {
			ValidProjectiles = fireball_projectiles(),
			ValidProjectilesLookup = fireball_lookup(),
			EffectName = GLOW,
		},
	},
})


local function glowing_brand_held()
	if not duo_on('GlowingBrand') or not game.CurrentRun then return false end
	return game.HeroHasTrait(duo_traits.GlowingBrand) == true
end


local function glowing_brand_data()
	local effect = game.EffectData[GLOW]
	return effect and effect.EffectData
end


function glowing_brand_sync()
	local data = glowing_brand_data()
	if not data then return end

	local effect = game.EffectData[GLOW]
	local held = glowing_brand_held()

	mod.GlowingBrandBaseVfx = mod.GlowingBrandBaseVfx or effect.Vfx
	effect.Vfx = held and mod.tuning.GlowingBrand.BrandFx or mod.GlowingBrandBaseVfx

	mod.GlowingBrandBaseDuration = mod.GlowingBrandBaseDuration or data.Duration
	local base = mod.GlowingBrandBaseDuration
	if type(base) ~= 'number' then return end

	data.Duration = held and base * mod.tuning.GlowingBrand.GlowDuration or base
end


function glowing_brand_glow(args)
	if not args or args.EffectName ~= GLOW then return args end

	glowing_brand_sync()
	if not glowing_brand_held() then return args end

	local properties = args.DataProperties
	if type(properties) ~= 'table' or type(properties.Modifier) ~= 'number' then return args end

	local boosted = game.ShallowCopyTable(args)
	boosted.DataProperties = game.ShallowCopyTable(properties)
	boosted.DataProperties.Modifier = 1 + (properties.Modifier - 1) * mod.tuning.GlowingBrand.GlowPotency
	boosted.DataProperties.Duration = glowing_brand_data().Duration
	return boosted
end
