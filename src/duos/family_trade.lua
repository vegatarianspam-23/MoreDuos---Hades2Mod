---@meta _


register_duo({
	key = 'FamilyTrade',

	StatLines = { 'SWuFamilyTradeLevelsStatDisplay' },
	ExtractValues = {
		{ Key = 'ExchangeLevelBonus', ExtractAs = 'TooltipLevels', IncludeSigns = true },
		{ Key = 'SWuTradeChoices', ExtractAs = 'TooltipChoices', SkipAutoExtract = true },
	},

	ExtraFields = {
		ExchangeLevelBonus = mod.tuning.FamilyTrade.ExchangeLevelBonus,
		SWuTradeChoices = mod.tuning.FamilyTrade.Choices,

		AcquireFunctionName = _PLUGIN.guid .. '.FamilyTradeAcquire',
	},
})


local FAMILY_TRADE_GODS = { 'ZeusUpgrade', 'HeraUpgrade' }


local function family_trade_held()
	if not duo_on('FamilyTrade') then return false end
	return game.HeroHasTrait(duo_traits.FamilyTrade) == true
end


local familyTradeForcing = false


function family_trade_offer_sacrifice(base, lootData, args)
	local hero = game.CurrentRun and game.CurrentRun.Hero
	local boons = hero and hero.BoonData
	if not boons or not family_trade_held() then return base(lootData, args) end

	local heldChance = boons.ReplaceChance
	local heldRequirements = boons.GameStateRequirements

	boons.ReplaceChance = 1
	boons.GameStateRequirements = { Force = true }
	familyTradeForcing = true

	local ok, result = pcall(base, lootData, args)

	familyTradeForcing = false
	boons.ReplaceChance = heldChance
	boons.GameStateRequirements = heldRequirements

	if not ok then error(result) end
	return result
end


local familyTradeReplacing = false


function family_trade_replacements(base, traitNames, onlyFromLootName)
	if not family_trade_held() then return base(traitNames, onlyFromLootName) end

	familyTradeReplacing = true
	local ok, result = pcall(base, traitNames, onlyFromLootName)
	familyTradeReplacing = false

	if not ok then error(result) end
	return result
end


function family_trade_rarity(base, baseRarity, rarityUpgradeOrder)
	local upgraded = base(baseRarity, rarityUpgradeOrder)
	if upgraded ~= nil or not familyTradeReplacing then return upgraded end
	return baseRarity
end


local familyTradeAnchored = {
	PoseidonManaBoon = true,
	HephaestusWeaponBoon = true,
	HephaestusSpecialBoon = true,
}


local function family_trade_unslot(trait)
	if not trait or not trait.Slot then return end

	local run = game.CurrentRun
	if not run then return end

	run.SWuFamilyTradeUnslotted = run.SWuFamilyTradeUnslotted or {}
	run.SWuFamilyTradeUnslotted[trait.Name] = true

	game.TraitUIRemove(trait)
	trait.Slot = nil
end


local function family_trade_share_slot(taken)
	if not taken.Slot then return end

	local kept = game.GetHeroTrait(taken.TraitToReplace)
	if kept and familyTradeAnchored[taken.Name] and not familyTradeAnchored[kept.Name] then
		family_trade_unslot(kept)
		return
	end

	family_trade_unslot(taken)
end


local function family_trade_slot_contested(hero, trait)
	for _, other in ipairs(hero.Traits or {}) do
		if other ~= trait and other.Slot == trait.Slot then return true end
	end
	return false
end


function family_trade_reslot()
	local run = game.CurrentRun
	local hero = run and run.Hero
	local unslotted = run and run.SWuFamilyTradeUnslotted
	if not hero or not unslotted then return end

	for _, trait in ipairs(hero.Traits or {}) do
		if trait.Name and unslotted[trait.Name] and trait.Slot
			and family_trade_slot_contested(hero, trait) then

			family_trade_unslot(trait)
		end
	end
end


local familyTradeKeeping = nil


function family_trade_choose(base, screen, button, args)
	local data = button and button.Data
	if data and data.TraitToReplace and family_trade_held() then
		familyTradeKeeping = data.TraitToReplace
		family_trade_share_slot(data)
	end

	local result = base(screen, button, args)

	familyTradeKeeping = nil
	return result
end


function family_trade_keep(base, traitName, args)
	if familyTradeKeeping == nil or traitName ~= familyTradeKeeping then
		return base(traitName, args)
	end

	familyTradeKeeping = nil
end


local function family_trade_slots(hero)
	local slots = {}
	for _, trait in ipairs(hero.Traits or {}) do
		if trait.Slot then
			local slot = slots[trait.Slot]
			if not slot then
				slot = { TraitName = trait.Name, Rarity = 'Common' }
				slots[trait.Slot] = slot
			end
			if trait.Rarity and game.GetRarityValue(trait.Rarity) > game.GetRarityValue(slot.Rarity) then
				slot.Rarity = trait.Rarity
			end
		end
	end
	return slots
end


local function family_trade_sacrifices(lootName, slots, offered)
	local options = {}
	local loot = game.LootData[lootName]

	for _, traitName in ipairs((loot and loot.PriorityUpgrades) or {}) do
		local data = game.TraitData[traitName]
		local slot = data and data.Slot and slots[data.Slot]
		if slot and not offered[traitName] and not game.HeroHasTrait(traitName) and game.IsTraitEligible(data) then
			local rarity = game.GetUpgradedRarity(slot.Rarity) or slot.Rarity
			if data.RarityLevels and data.RarityLevels[rarity] then
				table.insert(options, {
					ItemName = traitName,
					Type = 'Trait',
					TraitToReplace = slot.TraitName,
					OldRarity = slot.Rarity,
					Rarity = rarity,
					SWuLoot = lootName,
				})
			end
		end
	end

	return options
end


local function family_trade_other_gods()
	local gods = {}
	for name, loot in pairs(game.LootData) do
		if loot.GodLoot and loot.PriorityUpgrades and not game.Contains(FAMILY_TRADE_GODS, name) then
			table.insert(gods, name)
		end
	end
	return gods
end


local function family_trade_take(picked, offered, pool, count)
	while #picked < count and not game.IsEmpty(pool) do
		local option = game.RemoveRandomValue(pool)
		if option and not offered[option.ItemName] then
			offered[option.ItemName] = true
			table.insert(picked, option)
		end
	end
end


local function family_trade_as_source(lootName)
	local source = game.DeepCopyTable(game.LootData[lootName])
	source.ObjectId = game.CurrentRun.Hero.ObjectId
	source.DestroyOnPickup = nil
	source.CanDuplicate = nil
	source.BlockReroll = true
	source.Traits = source.Traits or {}
	source.PriorityUpgrades = source.PriorityUpgrades or {}
	return source
end


local function family_trade_normal(lootName, offered)
	local offer = family_trade_as_source(lootName)
	game.SetTraitsOnLoot(offer)

	local options = {}
	for _, option in ipairs(offer.UpgradeOptions or {}) do
		if not option.TraitToReplace and not offered[option.ItemName] then
			option.SWuLoot = lootName
			table.insert(options, option)
		end
	end
	return options
end


function family_trade_offer()
	if not family_trade_held() then return end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end

	local count = mod.tuning.FamilyTrade.Choices
	local slots = family_trade_slots(hero)
	local offered, picked = {}, {}

	local family = {}
	for _, lootName in ipairs(FAMILY_TRADE_GODS) do
		for _, option in ipairs(family_trade_sacrifices(lootName, slots, offered)) do
			table.insert(family, option)
		end
	end
	family_trade_take(picked, offered, family, count)

	local others = {}
	for _, lootName in ipairs(family_trade_other_gods()) do
		for _, option in ipairs(family_trade_sacrifices(lootName, slots, offered)) do
			table.insert(others, option)
		end
	end
	family_trade_take(picked, offered, others, count)

	local normal = {}
	for _, lootName in ipairs(FAMILY_TRADE_GODS) do
		for _, option in ipairs(family_trade_normal(lootName, offered)) do
			table.insert(normal, option)
		end
	end
	family_trade_take(picked, offered, normal, count)

	if game.IsEmpty(picked) then return end

	local source = family_trade_as_source(picked[1].SWuLoot or game.GetRandomValue(FAMILY_TRADE_GODS))
	source.UpgradeOptions = picked

	defer_screen_open(game.OpenUpgradeChoiceMenu, source, {})
	wishing_well_unlock_exits()
end


---@diagnostic disable-next-line: unused-local
function mod.FamilyTradeAcquire(args, traitData)
	if not duo_on('FamilyTrade') then return end
	game.thread(function()
		wait_for_screens(mod.tuning.FamilyTrade.AcquireDelay)
		family_trade_offer()
	end)
end
