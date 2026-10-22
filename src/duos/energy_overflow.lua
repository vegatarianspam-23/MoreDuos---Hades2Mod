---@meta _


register_duo({
	key = 'EnergyOverflow',

	StatLines = { 'SWuEnergyOverflowStatDisplay', 'SWuEnergyOverflowCapStatDisplay' },
	ExtractValues = {
		{ Key = 'SWuBonusRestore', ExtractAs = 'TooltipBonusRestore', Format = 'Percent' },
		{ Key = 'SWuMaxMana', ExtractAs = 'TooltipMaxMana' },
	},

	ExtraFields = {
		SWuBonusRestore = mod.tuning.EnergyOverflow.BonusRestore,
		SWuMaxMana = mod.tuning.EnergyOverflow.MaxMana,

		SetupFunction = {
			Name = _PLUGIN.guid .. '.EnergyOverflowSetup',
			RepeatOnEncounterStart = true,
		},
	},
})


local function energy_overflow_is_tick(args)
	return args ~= nil and args.Silent ~= nil
end


local function energy_overflow_stalled(hero, available)
	return (hero.Mana or 0) >= available and available < (hero.MaxMana or 0)
end


local function energy_overflow_earned(args)
	if args ~= nil and args.SWuManaDrip then return true end
	return not game.IsEmpty((game.MapState or {}).ChargedManaWeapons or {})
end


function energy_overflow_owe(value)
	local run = game.CurrentRun
	if not run or type(value) ~= 'number' or value <= 0 then return end

	run.SWuEnergyOverflowOwed = (run.SWuEnergyOverflowOwed or 0) + value
end


local function energy_overflow_refunded(delta)
	local run = game.CurrentRun
	local owed = run and run.SWuEnergyOverflowOwed or 0
	if owed <= 0 then return false end

	run.SWuEnergyOverflowOwed = math.max(owed - delta, 0)
	return true
end


local function energy_overflow_now()
	local worldTime = game._worldTime
	if type(worldTime) == 'number' then return worldTime end
	return game.GetTime({}) or 0
end


local function energy_overflow_drip_allowance(spill)
	local run = game.CurrentRun
	local rate = mod.tuning.EnergyOverflow.DripCeilingPerSecond or 0
	if rate <= 0 then return 0 end

	local now = energy_overflow_now()
	local last = run.SWuEnergyOverflowDripTime or now
	local budget = (run.SWuEnergyOverflowDripBudget or rate) + math.max(now - last, 0) * rate
	if budget > rate then budget = rate end

	local paid = math.min(spill, budget)
	run.SWuEnergyOverflowDripBudget = budget - paid
	run.SWuEnergyOverflowDripTime = now

	return paid
end


function energy_overflow_delta(delta, args)
	if not duo_on('EnergyOverflow') then return delta end
	if type(delta) ~= 'number' or delta <= 0 then return delta end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return delta end
	if not game.HeroHasTrait(duo_traits.EnergyOverflow) then return delta end

	local tuning = mod.tuning.EnergyOverflow

	local available = game.GetHeroMaxAvailableMana()

	local tick = energy_overflow_is_tick(args) and not energy_overflow_refunded(delta)
	if tick and not energy_overflow_earned(args) and energy_overflow_stalled(hero, available) then
		return delta
	end

	local carried = (game.CurrentRun.SWuEnergyOverflowCarry or 0) + delta * tuning.BonusRestore
	local bonus = math.floor(carried)
	game.CurrentRun.SWuEnergyOverflowCarry = carried - bonus

	local boosted = delta + bonus

	local headroom = math.max(available - (hero.Mana or 0), 0)
	local spill = math.max(boosted - headroom, 0)

	if tick then
		spill = spill > 0 and energy_overflow_drip_allowance(spill) or 0
	end

	if spill > 0 then
		local owed = (game.CurrentRun.SWuEnergyOverflowCeilingCarry or 0) + spill
		local whole = math.floor(owed)
		game.CurrentRun.SWuEnergyOverflowCeilingCarry = owed - whole

		if whole > 0 then
			local raise = math.min(whole, tuning.MaxMana - (hero.MaxMana or 0))
			if raise > 0 then
				energy_overflow_raise(hero, raise)
			end
		end
	end

	return boosted
end


local function energy_overflow_ceiling(trait)
	for _, change in ipairs(trait.PropertyChanges or {}) do
		if change.SWuEnergyOverflow then return change end
	end

	local entry = {
		SWuEnergyOverflow = true,
		LuaProperty = 'MaxMana',
		ChangeType = 'Add',
		ChangeValue = 0,
	}
	trait.PropertyChanges = trait.PropertyChanges or {}
	table.insert(trait.PropertyChanges, entry)
	return entry
end


---@diagnostic disable-next-line: unused-local
function energy_overflow_raise(_hero, raise)
	local trait = game.GetHeroTrait(duo_traits.EnergyOverflow)
	if not trait then return end

	local multiplier = game.GetTotalHeroTraitValue('MaxManaMultiplier', { IsMultiplier = true })
	if type(multiplier) ~= 'number' or multiplier <= 0 then multiplier = 1 end

	local entry = energy_overflow_ceiling(trait)
	entry.ChangeValue = (entry.ChangeValue or 0) + raise / multiplier
	game.ValidateMaxMana()

	game.thread(game.ManaRegen)
end


function mod.EnergyOverflowSetup()
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end

	local trait = game.GetHeroTrait(duo_traits.EnergyOverflow)
	if trait then
		local entry = energy_overflow_ceiling(trait)
		if (entry.ChangeValue or 0) ~= 0 then
			entry.ChangeValue = 0
			game.ValidateMaxMana()
		end
	end

	game.CurrentRun.SWuEnergyOverflowCarry = 0
	game.CurrentRun.SWuEnergyOverflowCeilingCarry = 0
	game.CurrentRun.SWuEnergyOverflowOwed = nil
	game.CurrentRun.SWuEnergyOverflowDripBudget = nil
	game.CurrentRun.SWuEnergyOverflowDripTime = nil
end
