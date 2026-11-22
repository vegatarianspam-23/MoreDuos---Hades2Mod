---@meta _


local DIFFERENT_LEAGUE_DODGED = 'SWuDifferentLeagueDodged'


local function different_league_scaling()
	return mod.tuning.DifferentLeague.DodgeScaling == true
end


local function different_league_avoid()
	return mod.tuning.DifferentLeague.AvoidDamage == true
end


register_duo({
	key = 'DifferentLeague',

	StatLines = different_league_scaling()
		and { 'SWuDifferentLeagueStackStatDisplay', 'SWuDifferentLeagueDodgeStatDisplay' }
		or { 'SWuDifferentLeagueStackStatDisplay' },
	ExtractValues = with_keyword_extracts({
		{ Key = 'SWuDamagePerDodge', ExtractAs = 'TooltipPerDodge', Format = 'Percent' },
		{ Key = 'SWuDodgeBonus', ExtractAs = 'TooltipDodgeBonus', Format = 'Percent', IncludeSigns = true,
			SkipAutoExtract = not different_league_scaling() or nil },
		{ Key = 'SWuMaxBonus', ExtractAs = 'TooltipMaxBonus', Format = 'Percent', SkipAutoExtract = true },
	}, 'Blind'),

	ExtraFields = {
		SWuDamagePerDodge = mod.tuning.DifferentLeague.StackDamage,
		SWuMaxBonus = mod.tuning.DifferentLeague.StackMax,
		SWuDodgeBonus = mod.tuning.DifferentLeague.DodgeBonus,
		SWuDifferentLeagueMultiplier = 1,

		AddOutgoingDamageModifiers = different_league_avoid() and {
			UseTraitValue = 'SWuDifferentLeagueMultiplier',
			IsMultiplier = true,
		} or nil,

		ShowInHUD = true,
		CustomLabel = {
			DisplayType = 'RoomValue',
			Key = 'SWuDifferentLeaguePercent',
			Text = 'UI_TimedKillBuff',
		},

		OnDodgeFunction = {
			FunctionName = DIFFERENT_LEAGUE_DODGED,
			RunOnce = true,
			FunctionArgs = {},
		},

		SetupFunction = {
			Threaded = true,
			Name = _PLUGIN.guid .. '.DifferentLeague',
			RepeatOnEncounterStart = true,
			Args = { Interval = mod.tuning.DifferentLeague.MissInterval },
		},
	},
})


local function different_league_bonus()
	local room = game.CurrentRun and game.CurrentRun.CurrentRoom
	if not room then return 0 end
	local tuning = mod.tuning.DifferentLeague

	return math.min((room.SWuDifferentLeagueDodges or 0) * tuning.StackDamage, tuning.StackMax)
end


local function different_league_apply()
	local bonus = different_league_bonus()
	duo_set_multiplier('DifferentLeague', 1 + bonus)
	duo_show_percent(duo_traits.DifferentLeague, 'SWuDifferentLeaguePercent', bonus)
end


function different_league_clear()
	duo_set_multiplier('DifferentLeague', 1)
end


local function different_league_new_encounter()
	local room = game.CurrentRun and game.CurrentRun.CurrentRoom
	if not room then return end

	room.SWuDifferentLeagueDodges = 0
	different_league_apply()
end


local function different_league_revenge(attacker)
	local tuning = mod.tuning.DifferentLeague
	if not tuning.RevengeOnDodge then return end
	if not attacker or not attacker.ObjectId or attacker.IsDead then return end
	if not game.ActiveEnemies or game.ActiveEnemies[attacker.ObjectId] ~= attacker then return end
	if duo_ignores(attacker) then return end

	local cooldown = tuning.RevengeCooldown
		* game.GetTotalHeroTraitValue('OlympianRechargeMultiplier', { IsMultiplier = true })
	if not game.CheckCooldown(attacker.ObjectId .. 'SWuDifferentLeagueRevenge', cooldown) then return end

	local triggerArgs = { ManuallyTriggered = true, Victim = game.CurrentRun.Hero, DamageAmount = 10 }
	for _, functionData in pairs(game.GetHeroTraitValues('OnSelfDamagedFunction')) do
		game.thread(game.CallFunctionName, functionData.Name, attacker, functionData.FunctionArgs, triggerArgs)
	end
end


modutil.mod.Path.Set(DIFFERENT_LEAGUE_DODGED, function(attacker)
	if not duo_on('DifferentLeague') then return end
	if not game.HeroHasTrait(duo_traits.DifferentLeague) then return end

	local room = game.CurrentRun and game.CurrentRun.CurrentRoom
	if not room then return end

	room.SWuDifferentLeagueDodges = (room.SWuDifferentLeagueDodges or 0) + 1
	different_league_apply()
	different_league_revenge(attacker)
end)


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
	if not different_league_avoid() then return end
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


local function different_league_multiplier(attacker, victim)
	if not duo_on('DifferentLeague') or not different_league_avoid() then return 1 end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero or attacker ~= hero then return 1 end
	if not victim or not victim.ObjectId then return 1 end

	return 1 + different_league_dodge_against(victim) * mod.tuning.DifferentLeague.DamagePerDodge
end


function different_league_refresh(attacker, victim)
	if not different_league_avoid() then return end
	local trait = duo_traits.DifferentLeague and game.GetHeroTrait(duo_traits.DifferentLeague)
	if not trait then return end

	trait.SWuDifferentLeagueMultiplier = different_league_multiplier(attacker, victim)
end


local function different_league_near(hero, unit)
	local boon = mod.tuning.DifferentLeague.NearbyExclusionBoon
	if boon and game.HeroHasTrait(boon) then return true end

	local distance = game.GetDistance({ Id = hero.ObjectId, DestinationId = unit.ObjectId })
	return distance ~= nil and distance <= mod.tuning.DifferentLeague.Radius
end


function mod.DifferentLeague(_hero, args)
	if not duo_on('DifferentLeague') then return end
	different_league_new_encounter()
	if not different_league_scaling() then return end

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
