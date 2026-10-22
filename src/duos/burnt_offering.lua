---@meta _


local BURNT_OFFERING_LIMITED = type(mod.tuning.BurntOffering.PurgesPerBiome) == 'number'


register_duo({
	key = 'BurntOffering',

	StatLines = BURNT_OFFERING_LIMITED
		and { 'SWuBurntOfferingGoldStatDisplay', 'SWuBurntOfferingPurgesStatDisplay' }
		or { 'SWuBurntOfferingGoldStatDisplay' },
	ExtractValues = {
		{ Key = 'SWuFirstPurgeGold', ExtractAs = 'TooltipFirstPurgeGold' },
		{ Key = 'SWuPurgesPerBiome', ExtractAs = 'TooltipPurgesPerBiome' },
		{ Key = 'SWuManaPerGold', ExtractAs = 'TooltipManaPerGold', Format = 'Percent' },
		{ Key = 'SWuHealthPerGold', ExtractAs = 'TooltipHealthPerGold', Format = 'Percent' },
	},

	ExtraFields = {
		SWuManaPerGold = mod.tuning.BurntOffering.ManaPerGold,
		SWuHealthPerGold = mod.tuning.BurntOffering.HealthPerGold,
		SWuFirstPurgeGold = mod.tuning.BurntOffering.FirstPurgeGold,
		SWuPurgesPerBiome = BURNT_OFFERING_LIMITED and mod.tuning.BurntOffering.PurgesPerBiome or 0,

		AcquireFunctionName = _PLUGIN.guid .. '.BurntOfferingAcquire',
	},
})


local function burnt_offering_bonus_owed()
	local run = game.CurrentRun
	return run ~= nil and run.SWuBurntOfferingOffering and not run.SWuBurntOfferingBonusPaid
end


function burnt_offering_has_boon()
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return false end

	local own = duo_traits.BurntOffering

	for _, trait in ipairs(hero.Traits or {}) do
		if trait.Name and trait.Name ~= own and trait.Rarity and game.IsGodTrait(trait.Name, { ForShop = true }) then
			return true
		end
	end
	return false
end


function burnt_offering_meets_requirements(base, traitName)
	local met = base(traitName)
	if not met then return false end
	if not duo_on('BurntOffering') then return met end
	if traitName ~= duo_traits.BurntOffering then return met end

	return burnt_offering_has_boon()
end


function burnt_offering_pay(gold)
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero or type(gold) ~= 'number' or gold <= 0 then return end

	local tuning = mod.tuning.BurntOffering

	local mana = math.floor(gold * tuning.ManaPerGold + 0.5)
	if mana > 0 then
		game.AddMaxMana(mana, 'SWuBurntOffering', { Silent = true })
	end

	local health = math.floor(gold * tuning.HealthPerGold + 0.5)
	if health > 0 then
		game.AddMaxHealth(health, 'SWuBurntOffering', { NoHealing = true, Silent = true })

		game.FrameState.RequestUpdateHealthUI = true

		game.Heal(hero, {
			HealAmount = game.round(health * game.CalculateHealingMultiplier()),
			SourceName = 'SWuBurntOffering',
		})
	end
end


local function burnt_offering_purges_left()
	local limit = mod.tuning.BurntOffering.PurgesPerBiome
	if type(limit) ~= 'number' then return true end

	local run = game.CurrentRun
	if not run then return false end

	local purges = run.SWuBurntOfferingPurges
	return (purges and purges[run.EnteredBiomes or 0] or 0) < limit
end


function burnt_offering_allows_purge(base, reward)
	local vanilla = base(reward)
	if vanilla then
		if reward then reward.SWuBurntOfferingPurge = false end
		return true
	end

	local answer = false
	if duo_on('BurntOffering')
		and game.HeroHasTrait(duo_traits.BurntOffering)
		and reward and reward.GoldConversionEligible
		and not (reward.ResourceCosts and game.HasResourceCost(reward.ResourceCosts))
		and burnt_offering_purges_left() then

		answer = true
	end

	if reward then reward.SWuBurntOfferingPurge = answer end

	return answer
end


local burntOfferingFullValue = false


function burnt_offering_minor(reward)
	local name = reward and reward.Name
	return name ~= nil and game.ConsumableData ~= nil and game.ConsumableData[name] ~= nil
end


function burnt_offering_purge_gold(base, reward)
	local value = base(reward)
	if not duo_on('BurntOffering') then return value end

	local minor = mod.tuning.BurntOffering.MinorFindMultiplier
	if burnt_offering_minor(reward) and type(minor) == 'number' and minor < 1 then
		value = math.floor(value * minor + 0.5)
	end

	if burntOfferingFullValue then return value end
	if not (reward and reward.SWuBurntOfferingPurge) then return value end

	local multiplier = mod.tuning.BurntOffering.PurgeGoldMultiplier
	if type(multiplier) ~= 'number' or multiplier >= 1 then return value end

	return math.floor(value * multiplier + 0.5)
end


local function burnt_offering_reward_worth(reward)
	burntOfferingFullValue = true
	local ok, value = pcall(game.GetRewardGoldifyValue, reward)
	burntOfferingFullValue = false

	if not ok then error(value) end
	return value
end


function burnt_offering_demand()
	local run = game.CurrentRun
	local room = run and run.CurrentRoom
	if not room then return end

	room.SellOptions = nil
	game.GenerateSellTraitShop(room, { ExclusionNames = { duo_traits.BurntOffering } })

	run.SWuBurntOfferingOffering = true
	game.OpenSellTraitMenu({})
	run.SWuBurntOfferingOffering = nil
end


function burnt_offering_close_store(base, screen, button)
	local room = game.CurrentRun and game.CurrentRun.CurrentRoom
	local lent = room ~= nil and room.Store == nil

	if lent then room.Store = { StoreOptions = {}, Buttons = {} } end
	local result = base(screen, button)
	if lent then room.Store = nil end
	return result
end


function burnt_offering_sold(button)
	if not duo_on('BurntOffering') then return end
	if not game.HeroHasTrait(duo_traits.BurntOffering) then return end

	local gold = button and button.Value
	if type(gold) ~= 'number' then gold = 0 end

	if burnt_offering_bonus_owed() then
		game.CurrentRun.SWuBurntOfferingBonusPaid = true

		local bonus = mod.tuning.BurntOffering.FirstPurgeGold
		game.AddResource('Money', bonus, 'TraitSell')
		gold = gold + bonus
	end

	burnt_offering_pay(gold)
end


function burnt_offering_purged(reward)
	if not duo_on('BurntOffering') then return end
	if not game.HeroHasTrait(duo_traits.BurntOffering) then return end

	local run = game.CurrentRun
	if run and reward and reward.SWuBurntOfferingPurge then
		local biome = run.EnteredBiomes or 0
		run.SWuBurntOfferingPurges = run.SWuBurntOfferingPurges or {}
		run.SWuBurntOfferingPurges[biome] = (run.SWuBurntOfferingPurges[biome] or 0) + 1
	end

	burnt_offering_pay(burnt_offering_reward_worth(reward))
end


---@diagnostic disable-next-line: unused-local
function mod.BurntOfferingAcquire(args, traitData)
	if not duo_on('BurntOffering') then return end

	game.thread(function()
		game.wait(mod.tuning.BurntOffering.DemandDelay)
		burnt_offering_demand()
	end)
end
