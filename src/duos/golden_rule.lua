---@meta _


register_duo({
	key = 'GoldenRule',

	StatLines = { 'SWuGoldenRuleStatDisplay', 'SWuGoldenRuleMaxStatDisplay' },
	ExtractValues = {
		{ Key = 'SWuDamagePerGold', ExtractAs = 'TooltipPerGold', Format = 'Percent', DecimalPlaces = 2 },
		{ Key = 'SWuMaxBonus', ExtractAs = 'TooltipMaxBonus', Format = 'Percent' },
	},

	ExtraFields = {
		SWuDamagePerGold = mod.tuning.GoldenRule.DamagePerGold,
		SWuMaxBonus = mod.tuning.GoldenRule.MaxBonus,
		SWuInterest = mod.tuning.GoldenRule.Interest,

		SetupFunction = {
			Threaded = true,
			Name = _PLUGIN.guid .. '.GoldenRule',
			RepeatOnEncounterStart = true,
			Args = { Interval = mod.tuning.GoldenRule.PollInterval },
		},

		LeaveRoomFunctionName = _PLUGIN.guid .. '.GoldenRuleInterest',
	},
})


local goldenRuleApplied = false


function golden_rule_apply()
	local held = duo_on('GoldenRule') and in_run()
		and game.HeroHasTrait(duo_traits.GoldenRule)

	if not held then
		if goldenRuleApplied then
			duo_set_multiplier('GoldenRule', 1)
			goldenRuleApplied = false
		end
		return
	end

	local tuning = mod.tuning.GoldenRule
	local bonus = math.min(game.GetResourceAmount('Money') * tuning.DamagePerGold, tuning.MaxBonus)

	duo_set_multiplier('GoldenRule', 1 + bonus)
	goldenRuleApplied = true
end


function mod.GoldenRule(_hero, args)
	local interval = (args and args.Interval) or mod.tuning.GoldenRule.PollInterval
	local loop = duo_loop_claim(duo_traits.GoldenRule)
	if not loop then return end

	while duo_running(duo_traits.GoldenRule) do
		golden_rule_apply()
		game.wait(interval, loop)
	end
end


---@diagnostic disable-next-line: unused-local
function mod.GoldenRuleInterest(_currentRun, _door)
	if not duo_on('GoldenRule') then return end
	if not game.HeroHasTrait(duo_traits.GoldenRule) then return end

	local interest = math.floor(game.GetResourceAmount('Money') * mod.tuning.GoldenRule.Interest)
	if interest <= 0 then return end

	game.AddResource('Money', interest, 'SWuGoldenRule', { Silent = true })

	local delay = (game.SessionMapState.DoorTextCount or 0) * game.UIData.DoorTextCumulativeDelay
	game.thread(function()
		game.waitUnmodified(delay, game.RoomThreadName)
		game.PlaySound({
			Name = '/Leftovers/Menu Sounds/MakingMoneyChaChing',
			Id = game.CurrentRun.Hero.ObjectId,
		})
		game.thread(game.InCombatTextArgs, {
			TargetId = game.CurrentRun.Hero.ObjectId,
			Text = 'GoldIncrease',
			FontSize = 30,
			Duration = 0.7,
			LuaKey = 'TooltipData',
			SkipShadow = true,
			OffsetY = -100,
			LuaValue = { Amount = interest },
		})
	end)
	game.IncrementTableValue(game.SessionMapState, 'DoorTextCount')
end
