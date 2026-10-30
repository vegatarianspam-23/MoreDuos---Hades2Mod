---@meta _


register_duo({
	key = 'DifferentLeague',

	StatLines = { 'SWuDifferentLeagueDodgeStatDisplay' },
	ExtractValues = with_keyword_extracts({
		{ Key = 'SWuDodgeBonus', ExtractAs = 'TooltipDodgeBonus', Format = 'Percent', IncludeSigns = true },
	}, 'Blind'),

	ExtraFields = {
		SWuDodgeBonus = mod.tuning.DifferentLeague.DodgeBonus,
		SWuDifferentLeagueMultiplier = 1,

		AddOutgoingDamageModifiers = {
			UseTraitValue = 'SWuDifferentLeagueMultiplier',
			IsMultiplier = true,
		},

		SetupFunction = {
			Threaded = true,
			Name = _PLUGIN.guid .. '.DifferentLeague',
			RepeatOnEncounterStart = true,
			Args = { Interval = mod.tuning.DifferentLeague.MissInterval },
		},
	},
})


local DIFFERENT_LEAGUE_MISS = 'SWuDifferentLeagueMiss'

game.EffectData[DIFFERENT_LEAGUE_MISS] = {
	DataProperties = {
		Stacks = false,
		Duration = mod.tuning.DifferentLeague.MissDuration,
		MissChance = mod.tuning.DifferentLeague.DodgeBonus,
		IgnoreName = '_PlayerUnit',
	},
}


differentLeagueDodge = differentLeagueDodge or { Id = nil, Value = 0 }


function different_league_reset_dodge()
	differentLeagueDodge.Id = nil
	differentLeagueDodge.Value = 0
end


function different_league_track_dodge(args)
	if not args or args.Property ~= 'DodgeChance' or type(args.Value) ~= 'number' then return end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero or not hero.ObjectId or args.DestinationId ~= hero.ObjectId then return end

	local dodge = differentLeagueDodge
	if dodge.Id ~= hero.ObjectId then
		dodge.Id = hero.ObjectId
		dodge.Value = 0
	end

	local change = args.ValueChangeType
	if change == 'Add' then
		dodge.Value = dodge.Value + args.Value
	elseif change == 'Multiply' then
		dodge.Value = dodge.Value * args.Value
	else
		dodge.Value = args.Value
	end
end


local function different_league_hero_dodge()
	local hero = game.CurrentRun and game.CurrentRun.Hero
	local dodge = differentLeagueDodge
	if not hero or dodge.Id ~= hero.ObjectId then return 0 end
	return math.max(0, math.min(dodge.Value, 1))
end


function different_league_record_miss(args)
	local miss = args and args.DataProperties and args.DataProperties.MissChance
	if type(miss) ~= 'number' or not args.EffectName or not args.DestinationId then return end

	local foe = game.ActiveEnemies and game.ActiveEnemies[args.DestinationId]
	if not foe then return end

	foe.SWuMissChances = foe.SWuMissChances or {}
	foe.SWuMissChances[args.EffectName] = miss
end


local function different_league_effect_miss(foe, effectName)
	local miss = foe.SWuMissChances and foe.SWuMissChances[effectName]

	if type(miss) ~= 'number' then
		local effect = game.EffectData[effectName]
		local data = effect and (effect.EffectData or effect.DataProperties)
		miss = data and data.MissChance
	end

	if type(miss) ~= 'number' then return 0 end
	return math.max(0, math.min(miss, 1))
end


function different_league_dodge_against(foe)
	local through = 1 - different_league_hero_dodge()

	for effectName in pairs((foe and foe.ActiveEffects) or {}) do
		through = through * (1 - different_league_effect_miss(foe, effectName))
	end

	return 1 - through
end


local function different_league_near(hero, unit)
	local boon = mod.tuning.DifferentLeague.NearbyExclusionBoon
	if boon and game.HeroHasTrait(boon) then return true end

	local distance = game.GetDistance({ Id = hero.ObjectId, DestinationId = unit.ObjectId })
	return distance ~= nil and distance <= mod.tuning.DifferentLeague.Radius
end


local function different_league_multiplier(attacker, victim)
	if not duo_on('DifferentLeague') then return 1 end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero or attacker ~= hero then return 1 end
	if not victim or not victim.ObjectId then return 1 end

	return 1 + different_league_dodge_against(victim) * mod.tuning.DifferentLeague.DamagePerDodge
end


function different_league_refresh(attacker, victim)
	local trait = duo_traits.DifferentLeague and game.GetHeroTrait(duo_traits.DifferentLeague)
	if not trait then return end

	trait.SWuDifferentLeagueMultiplier = different_league_multiplier(attacker, victim)
end


function mod.DifferentLeague(_hero, args)
	local interval = (args and args.Interval) or mod.tuning.DifferentLeague.MissInterval
	local loop = duo_loop_claim(duo_traits.DifferentLeague)
	if not loop then return end

	while duo_running(duo_traits.DifferentLeague) do
		local hero = game.CurrentRun.Hero
		if duo_on('DifferentLeague') and hero and hero.ObjectId then
			for _, enemy in pairs(game.ActiveEnemies or {}) do
				if enemy and enemy.ObjectId and not enemy.IsDead and not duo_ignores(enemy)
					and different_league_near(hero, enemy) then
					game.ApplyEffect({
						DestinationId = enemy.ObjectId,
						Id = hero.ObjectId,
						EffectName = DIFFERENT_LEAGUE_MISS,
						DataProperties = game.EffectData[DIFFERENT_LEAGUE_MISS].DataProperties,
					})
				end
			end
		end
		game.wait(interval, loop)
	end
end
