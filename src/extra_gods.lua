---@meta _


local DROPPABLE_GODS = 'zannc-Droppable_Gods'

extra_god_loot = {}

for _, godName in ipairs({ 'Artemis', 'Athena', 'Dionysus', 'Hades' }) do
	local lootName = DROPPABLE_GODS .. '-' .. godName .. 'Upgrade'
	if game.LootData[lootName] then
		extra_god_loot[godName] = lootName
	end
end

local extra_gods_stripped = {}
local extra_gods_opened = false


local function extra_gods_strip(list)
	if not list then return end
	for index = #list, 1, -1 do
		local name = list[index] and list[index].Name
		for _, lootName in pairs(extra_god_loot) do
			if name == lootName or name == 'Shop' .. lootName then
				table.insert(extra_gods_stripped, { List = list, Entry = list[index] })
				table.remove(list, index)
				break
			end
		end
	end
end

local HADES_TRAITS = {
	'HadesLifestealBoon',
	'HadesCastProjectileBoon',
	'HadesPreDamageBoon',
	'HadesDeathDefianceDamageBoon',
	'HadesChronosDebuffBoon',
	'HadesDashSweepBoon',
	'HadesInvisibilityRetaliateBoon',
	'HadesManaUrnBoon',
}

function extra_gods_hide_hades_rarity()
	local settings = mod.tuning.Systems.ExtraGods
	if not settings.HideHadesRarity then return end

	for _, traitName in ipairs(HADES_TRAITS) do
		local trait = game.TraitData[traitName]
		if trait then

			local levels = trait.RarityLevels or {}
			trait.RarityLevels = { Common = levels.Common or { Multiplier = 1 } }

			trait.CustomRarityName = ' '
			trait.CustomRarityColor = game.Color.White
			trait.ExcludeFromRarityCount = true
		end
	end
end

function extra_gods_close_doors()
	local settings = mod.tuning.Systems.ExtraGods
	if settings.DoorRewards then return end

	for _, lootName in pairs(extra_god_loot) do
		local loot = game.LootData[lootName]
		if loot then
			loot.GodLoot = false
			loot.TreatAsGodLootByShops = true
		end
	end

	extra_gods_strip(game.RewardStoreData and game.RewardStoreData.HubRewards)
	extra_gods_strip(game.RewardStoreData and game.RewardStoreData.RunProgress)

	for _, storeName in ipairs({ 'SurfaceShop', 'WorldShop', 'I_WorldShop', 'Q_WorldShop' }) do
		local store = game.StoreData and game.StoreData[storeName]
		for _, group in ipairs((store and store.GroupsOf) or {}) do
			extra_gods_strip(group.OptionsData)
		end
	end
end


function extra_gods_open_doors(open)
	open = open == true

	local settings = mod.tuning.Systems.ExtraGods
	if settings.DoorRewards or game.IsEmpty(extra_god_loot) then return end
	if open == extra_gods_opened then return end

	extra_gods_opened = open

	for _, lootName in pairs(extra_god_loot) do
		local loot = game.LootData[lootName]
		if loot then loot.GodLoot = open end
	end

	for _, held in ipairs(extra_gods_stripped) do
		local present = game.Contains(held.List, held.Entry)
		if open and not present then
			table.insert(held.List, held.Entry)
		elseif not open and present then
			game.RemoveValue(held.List, held.Entry)
		end
	end
end
