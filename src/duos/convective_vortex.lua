---@meta _


local RIFT = 'AresProjectile'


register_duo({
	key = 'ConvectiveVortex',

	StatLines = { 'SWuConvectiveVortexStatDisplay', 'SWuConvectiveVortexDurationStatDisplay' },
	ExtractValues = with_keyword_extracts({
		{ Key = 'SWuScorchPerHit', ExtractAs = 'TooltipScorchPerHit' },
		{ Key = 'SWuRiftDuration', ExtractAs = 'TooltipRiftDuration', Format = 'PercentDelta' },
	}, 'Burn', 'BladeRift'),

	ExtraFields = {
		SWuScorchPerHit = mod.tuning.ConvectiveVortex.ScorchPerHit,
		SWuRiftDuration = mod.tuning.ConvectiveVortex.DurationMultiplier,

		OnEnemyDamagedAction = {
			ValidProjectiles = { RIFT },
			ValidProjectilesLookup = game.ToLookup({ RIFT }),
			FunctionName = _PLUGIN.guid .. '.ConvectiveVortex',
		},
	},
})


function mod.ConvectiveVortex(victim, functionArgs)
	if not duo_on('ConvectiveVortex') then return end
	if functionArgs and functionArgs.VictimWillBeAlive == false then return end
	if not victim or not victim.ObjectId or victim.IsDead or duo_ignores(victim) then return end

	local tuning = mod.tuning.ConvectiveVortex
	victim.SWuConvectiveVortexUntil = (game._worldTime or 0) + tuning.InsideWindow

	game.ApplyBurn(victim, { EffectName = 'BurnEffect', NumStacks = tuning.ScorchPerHit })
end


function convective_vortex_reverse(victim, args)
	if not victim or not victim.SWuConvectiveVortexUntil then return end
	if victim.SWuConvectiveVortexUntil < (game._worldTime or 0) then return end
	if not args or type(args.Stacks) ~= 'number' or args.Stacks <= 0 then return end
	if not duo_on('ConvectiveVortex') then return end

	local effectName = args.EffectData and args.EffectData.Name
	local stacks = effectName and victim.ActiveEffects and victim.ActiveEffects[effectName]
	if type(stacks) ~= 'number' then return end

	victim.ActiveEffects[effectName] = stacks + 2 * args.Stacks
	args.StartingStacks = victim.ActiveEffects[effectName]
	args.Stacks = -args.Stacks
end


function convective_vortex_rift(args)
	if not args or args.Name ~= RIFT then return args end
	if not duo_on('ConvectiveVortex') then return args end
	if not game.HeroHasTrait(duo_traits.ConvectiveVortex) then return args end

	local tuning = mod.tuning.ConvectiveVortex
	args.ThingProperties = game.MergeTables(args.ThingProperties, {
		Graphic = tuning.RiftFx.In,
		AttachedAnim = tuning.RiftFx.Shadow,
	})

	local lifetime = (args.DataProperties and args.DataProperties.TotalFuse)
		or game.GetBaseDataValue({ Type = 'Projectile', Name = RIFT, Property = 'TotalFuse' })
	if type(lifetime) == 'number' then
		args.DataProperties = game.ShallowCopyTable(args.DataProperties or {})
		args.DataProperties.TotalFuse = lifetime * tuning.DurationMultiplier
	end
	return args
end
