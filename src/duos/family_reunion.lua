---@meta _


register_duo({
	key = 'FamilyReunion',

	StatLines = { 'SWuFamilyReunionLegendaryStatDisplay' },
	ExtractValues = {
		{ Key = 'SWuLegendaryBonus', ExtractAs = 'TooltipLegendaryBonus', Format = 'Percent' },
		{ Key = 'SWuDuoBonus', ExtractAs = 'TooltipDuoBonus', Format = 'Percent' },
	},

	ExtraFields = {
		SWuLegendaryBonus = mod.tuning.FamilyReunion.LegendaryRarityBonus,
		SWuDuoBonus = mod.tuning.FamilyReunion.DuoRarityBonus,

		AcquireFunctionName = _PLUGIN.guid .. '.FamilyReunionAcquire',

		RarityBonus = {
			Legendary = mod.tuning.FamilyReunion.LegendaryRarityBonus,
			Duo = mod.tuning.FamilyReunion.DuoRarityBonus,
		},
	},
})


local FAMILY_GODS = {
	'AphroditeUpgrade', 'ApolloUpgrade', 'AresUpgrade', 'DemeterUpgrade', 'HephaestusUpgrade',
	'HeraUpgrade', 'HermesUpgrade', 'HestiaUpgrade', 'PoseidonUpgrade', 'ZeusUpgrade',
}


local FAMILY_FIELD_GODS = { 'Artemis', 'Athena', 'Dionysus' }


local function family_reunion_roster()
	local roster = game.ShallowCopyTable(FAMILY_GODS)
	for _, godName in ipairs(FAMILY_FIELD_GODS) do
		local lootName = extra_god_loot and extra_god_loot[godName]
		if lootName then
			table.insert(roster, lootName)
		end
	end
	return roster
end


local function family_reunion_own_duo_loot(traitName)
	for key, name in pairs(duo_traits or {}) do
		if name == traitName then
			local gods = ((duo_requirements or {})[key] or {}).Gods
			if not gods then return nil end

			local lootNames = {}
			for _, godName in ipairs(gods) do
				table.insert(lootNames, (extra_god_loot and extra_god_loot[godName]) or (godName .. 'Upgrade'))
			end
			return lootNames
		end
	end
	return nil
end


local function family_reunion_heard_from()
	local heard = {}
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return heard end

	local roster = family_reunion_roster()

	for _, trait in ipairs(hero.Traits or {}) do
		if trait.Name then
			for _, lootName in ipairs(roster) do
				local loot = game.LootData[lootName]
				if loot and loot.TraitIndex and loot.TraitIndex[trait.Name] then
					heard[lootName] = true
				end
			end

			for _, lootName in ipairs(family_reunion_own_duo_loot(trait.Name) or {}) do
				if game.LootData[lootName] then
					heard[lootName] = true
				end
			end
		end
	end
	return heard
end


local function family_reunion_anchor()
	local room = game.CurrentRun and game.CurrentRun.CurrentRoom
	if not room or not room.Store then return nil end

	local pointId = game.SelectLootSpawnPoint(room)
	if not pointId or pointId <= 0 then return nil end
	return pointId
end


function family_reunion_gather()
	game.waitUnmodified(0.5)

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end

	local heard = family_reunion_heard_from()
	local tuning = mod.tuning.FamilyReunion

	local pending = {}
	for _, lootName in ipairs(family_reunion_roster()) do
		if game.LootData[lootName] and not heard[lootName] then
			table.insert(pending, lootName)
		end
	end
	if game.IsEmpty(pending) then return end

	local anchorId = family_reunion_anchor()
	if not anchorId then
		anchorId = game.SpawnObstacle({
			Name = 'InvisibleTarget',
			LocationX = game.GetLocation({ Id = hero.ObjectId }).X,
			LocationY = game.GetLocation({ Id = hero.ObjectId }).Y,
		})
	end

	for index, lootName in ipairs(pending) do
		local lootData = game.DeepCopyTable(game.LootData[lootName])
		lootData.SWuFamilyReunion = true

		local angle = (index / #pending) * 2 * math.pi
		game.CreateLoot({
			Name = lootName,
			LootData = lootData,
			DoesNotBlockExit = true,
			AutoLoadPackages = true,
			SpawnPoint = anchorId,
			OffsetX = math.cos(angle) * tuning.ScatterRadius,
			OffsetY = math.sin(angle) * tuning.ScatterRadius,
		})
		game.waitUnmodified(tuning.DropInterval)
	end
end


---@diagnostic disable-next-line: unused-local
function mod.FamilyReunionAcquire(args, traitData)
	if not duo_on('FamilyReunion') then return end
	game.thread(family_reunion_gather)
end
