---@meta _


local SACROSANCT_ALMS_LIMITED = type(mod.tuning.SacrosanctAlms.PurgesPerBiome) == 'number'


register_duo({
	key = 'SacrosanctAlms',

	StatLines = SACROSANCT_ALMS_LIMITED
		and { 'SWuSacrosanctAlmsGoldStatDisplay', 'SWuSacrosanctAlmsPurgesStatDisplay' }
		or { 'SWuSacrosanctAlmsGoldStatDisplay' },
	ExtractValues = {
		{ Key = 'SWuFirstPurgeGold', ExtractAs = 'TooltipFirstPurgeGold' },
		{ Key = 'SWuPurgesPerBiome', ExtractAs = 'TooltipPurgesPerBiome' },
		{ Key = 'SWuManaPerGold', ExtractAs = 'TooltipManaPerGold', Format = 'Percent' },
		{ Key = 'SWuHealthPerGold', ExtractAs = 'TooltipHealthPerGold', Format = 'Percent' },
	},

	ExtraFields = {
		SWuManaPerGold = mod.tuning.SacrosanctAlms.ManaPerGold,
		SWuHealthPerGold = mod.tuning.SacrosanctAlms.HealthPerGold,
		SWuFirstPurgeGold = mod.tuning.SacrosanctAlms.FirstPurgeGold,
		SWuPurgesPerBiome = SACROSANCT_ALMS_LIMITED and mod.tuning.SacrosanctAlms.PurgesPerBiome or 0,

		AcquireFunctionName = _PLUGIN.guid .. '.SacrosanctAlmsAcquire',
	},
})


local function sacrosanct_alms_bonus_owed()
	local run = game.CurrentRun
	return run ~= nil and run.SWuSacrosanctAlmsOffering and not run.SWuSacrosanctAlmsBonusPaid
end


function sacrosanct_alms_has_boon()
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return false end

	local own = duo_traits.SacrosanctAlms

	for _, trait in ipairs(hero.Traits or {}) do
		if trait.Name and trait.Name ~= own and trait.Rarity and game.IsGodTrait(trait.Name, { ForShop = true }) then
			return true
		end
	end
	return false
end


function sacrosanct_alms_meets_requirements(base, traitName)
	local met = base(traitName)
	if not met then return false end
	if not duo_on('SacrosanctAlms') then return met end
	if traitName ~= duo_traits.SacrosanctAlms then return met end

	return sacrosanct_alms_has_boon()
end


function sacrosanct_alms_pay(gold)
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero or type(gold) ~= 'number' or gold <= 0 then return end

	local tuning = mod.tuning.SacrosanctAlms

	local mana = math.floor(gold * tuning.ManaPerGold + 0.5)
	if mana > 0 then
		game.AddMaxMana(mana, 'SWuSacrosanctAlms', { Silent = true })
	end

	local health = math.floor(gold * tuning.HealthPerGold + 0.5)
	if health > 0 then
		game.AddMaxHealth(health, 'SWuSacrosanctAlms', { NoHealing = true, Silent = true })

		game.FrameState.RequestUpdateHealthUI = true

		game.Heal(hero, {
			HealAmount = game.round(health * game.CalculateHealingMultiplier()),
			SourceName = 'SWuSacrosanctAlms',
		})
	end
end


local function sacrosanct_alms_purges_left()
	local limit = mod.tuning.SacrosanctAlms.PurgesPerBiome
	if type(limit) ~= 'number' then return true end

	local run = game.CurrentRun
	if not run then return false end

	local purges = run.SWuSacrosanctAlmsPurges
	return (purges and purges[run.EnteredBiomes or 0] or 0) < limit
end


function sacrosanct_alms_allows_purge(base, reward)
	local vanilla = base(reward)
	if vanilla then
		if reward then reward.SWuSacrosanctAlmsPurge = false end
		return true
	end

	local answer = false
	if duo_on('SacrosanctAlms')
		and game.HeroHasTrait(duo_traits.SacrosanctAlms)
		and reward and reward.GoldConversionEligible
		and not (reward.ResourceCosts and game.HasResourceCost(reward.ResourceCosts))
		and sacrosanct_alms_purges_left() then

		answer = true
	end

	if reward then reward.SWuSacrosanctAlmsPurge = answer end

	return answer
end


local sacrosanctAlmsFullValue = false


function sacrosanct_alms_minor(reward)
	local name = reward and reward.Name
	return name ~= nil and game.ConsumableData ~= nil and game.ConsumableData[name] ~= nil
end


function sacrosanct_alms_purge_gold(base, reward)
	local value = base(reward)
	if not duo_on('SacrosanctAlms') then return value end

	local minor = mod.tuning.SacrosanctAlms.MinorFindMultiplier
	if reward and reward.SWuSacrosanctAlmsPurge and sacrosanct_alms_minor(reward) and type(minor) == 'number' and minor < 1 then
		value = math.floor(value * minor + 0.5)
	end

	if sacrosanctAlmsFullValue then return value end
	if not (reward and reward.SWuSacrosanctAlmsPurge) then return value end

	local multiplier = mod.tuning.SacrosanctAlms.PurgeGoldMultiplier
	if type(multiplier) ~= 'number' or multiplier >= 1 then return value end

	return math.floor(value * multiplier + 0.5)
end


local function sacrosanct_alms_reward_worth(reward)
	sacrosanctAlmsFullValue = true
	local ok, value = pcall(game.GetRewardGoldifyValue, reward)
	sacrosanctAlmsFullValue = false

	if not ok then error(value) end
	return value
end


function sacrosanct_alms_demand()
	local run = game.CurrentRun
	local room = run and run.CurrentRoom
	if not room then return end

	room.SellOptions = nil
	game.GenerateSellTraitShop(room, { ExclusionNames = { duo_traits.SacrosanctAlms } })

	run.SWuSacrosanctAlmsOffering = true
	game.OpenSellTraitMenu({})
	run.SWuSacrosanctAlmsOffering = nil
end


function sacrosanct_alms_close_store(base, screen, button)
	local room = game.CurrentRun and game.CurrentRun.CurrentRoom
	local lent = room ~= nil and room.Store == nil

	if lent then room.Store = { StoreOptions = {}, Buttons = {} } end
	local result = base(screen, button)
	if lent then room.Store = nil end
	return result
end


function sacrosanct_alms_sold(button)
	if not duo_on('SacrosanctAlms') then return end
	if not game.HeroHasTrait(duo_traits.SacrosanctAlms) then return end

	local gold = button and button.Value
	if type(gold) ~= 'number' then gold = 0 end

	if sacrosanct_alms_bonus_owed() then
		game.CurrentRun.SWuSacrosanctAlmsBonusPaid = true

		local bonus = mod.tuning.SacrosanctAlms.FirstPurgeGold
		game.AddResource('Money', bonus, 'TraitSell')
		gold = gold + bonus
	end

	sacrosanct_alms_pay(gold)
end


function sacrosanct_alms_purged(reward)
	if not duo_on('SacrosanctAlms') then return end
	if not game.HeroHasTrait(duo_traits.SacrosanctAlms) then return end

	local run = game.CurrentRun
	if run and reward and reward.SWuSacrosanctAlmsPurge then
		local biome = run.EnteredBiomes or 0
		run.SWuSacrosanctAlmsPurges = run.SWuSacrosanctAlmsPurges or {}
		run.SWuSacrosanctAlmsPurges[biome] = (run.SWuSacrosanctAlmsPurges[biome] or 0) + 1
	end

	sacrosanct_alms_pay(sacrosanct_alms_reward_worth(reward))
end


---@diagnostic disable-next-line: unused-local
function mod.SacrosanctAlmsAcquire(args, traitData)
	if not duo_on('SacrosanctAlms') then return end

	game.thread(function()
		game.wait(mod.tuning.SacrosanctAlms.DemandDelay)
		sacrosanct_alms_demand()
	end)
end
