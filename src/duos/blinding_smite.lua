---@meta _


local DAZE = 'BlindEffect'

local BOLT = 'ZeusRetaliateStrike'

local LIGHTNING = {
	'ZeusEchoStrike',
	'ZeusCastStrike',
	'ZeusRootStrike',
	'ZeusSprintStrike',
	'ZeusZeroManaStrike',
	'ZeusRetaliateStrike',
	'ProjectileZeusSpark',
	'ZeusCastAnywhereBlast',
	'ZeusApolloSynergyStrike',
}


local DODGE_FUNCTION = 'SWuBlindingSmiteStrike'


register_duo({
	key = 'BlindingSmite',

	StatLines = { 'SWuBlindingSmiteBoltStatDisplay', 'SWuBlindingSmiteStatDisplay' },
	ExtractValues = with_keyword_extracts({
		{
			Key = 'SWuBoltDamage',
			ExtractAs = 'TooltipBoltDamage',
		},
		{
			Key = 'SWuDazedMultiplier',
			ExtractAs = 'TooltipDazedDamage',
			Format = 'PercentDelta',
		},
		{ Key = 'SWuMinBolts', ExtractAs = 'TooltipMinBolts', SkipAutoExtract = true },
		{ Key = 'SWuMaxBolts', ExtractAs = 'TooltipMaxBolts', SkipAutoExtract = true },
	}, 'Blind'),

	ExtraFields = {
		SWuBoltDamage = mod.tuning.BlindingSmite.BoltDamage,
		SWuDazedMultiplier = mod.tuning.BlindingSmite.DazedMultiplier,
		SWuMinBolts = mod.tuning.BlindingSmite.MinBolts,
		SWuMaxBolts = mod.tuning.BlindingSmite.MaxBolts,

		OnDodgeFunction = {
			FunctionName = DODGE_FUNCTION,
			RunOnce = true,
			FunctionArgs = {},
		},

		AddOutgoingDamageModifiers = {
			ValidProjectiles = LIGHTNING,
			ValidProjectilesLookup = game.ToLookup(LIGHTNING),
			ValidActiveEffects = { DAZE },
			ValidWeaponMultiplier = mod.tuning.BlindingSmite.DazedMultiplier,
		},
	},
})


---@diagnostic disable-next-line: unused-local
function mod.BlindingSmiteStrike(attacker, _args)
	if not duo_on('BlindingSmite') then return end

	local foe = duo_live_foe(attacker)
	if not foe or foe.IsDead then return end
	if not foe.ActiveEffects or not foe.ActiveEffects[DAZE] then return end
	if game.IsUntargetable({ Id = foe.ObjectId }) then return end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end

	local tuning = mod.tuning.BlindingSmite
	local base = game.GetBaseDataValue({ Type = 'Projectile', Name = BOLT, Property = 'Damage' })
	if type(base) ~= 'number' or base <= 0 then base = 100 end

	for index = 1, game.RandomInt(tuning.MinBolts, tuning.MaxBolts) do
		game.thread(game.CreateZeusBolt, {
			SourceId = hero.ObjectId,
			TargetId = foe.ObjectId,
			ProjectileName = BOLT,
			DamageMultiplier = tuning.BoltDamage / base,
			Range = 1,
			SeekTarget = true,
			Delay = tuning.BoltInterval * (index - 1),
			Count = 1,
		})
	end
end


local LIGHT_SMITE = 'ApolloRetaliateBoon'

local function blinding_smite_light_smite(attacker)
	if not duo_on('BlindingSmite') then return end
	if not attacker then return end
	if not game.HeroHasTrait(LIGHT_SMITE) then return end

	local trait = game.GetHeroTrait(LIGHT_SMITE)
	local args = trait and trait.OnSelfDamagedFunction and trait.OnSelfDamagedFunction.FunctionArgs
	if not args then return end

	game.ApolloRetaliate(attacker, args)
end


modutil.mod.Path.Set(DODGE_FUNCTION, function(attacker, args)
	mod.BlindingSmiteStrike(attacker, args)
	blinding_smite_light_smite(attacker)
end)
