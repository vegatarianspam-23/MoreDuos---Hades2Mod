---@meta _


register_duo({
	key = 'WishingWell',

	StatLines = { 'SWuWishingWellStatDisplay' },
	ExtractValues = {
		{ Key = 'SWuFountainRate', ExtractAs = 'TooltipFountainRate', Format = 'Percent', HideSigns = true },
	},

	ExtraFields = {
		SWuFountainRate = 1,

		AcquireFunctionName = _PLUGIN.guid .. '.WishingWellAcquire',
	},
})


local WISHING_WELL_REPRIEVES = {
	'F_Reprieve01', 'G_Reprieve01', 'I_Reprieve01', 'O_Reprieve01', 'P_Reprieve01',
}


local WISHING_WELL_IS_REPRIEVE = {}
for _, name in ipairs(WISHING_WELL_REPRIEVES) do
	WISHING_WELL_IS_REPRIEVE[name] = true
end


local WISHING_WELL_FIELD_GODS = { 'Artemis', 'Athena', 'Dionysus', 'Hades' }


function wishing_well_zagreus_journey()
	if not (config.Experimental and config.Experimental.ZagreusJourney == true) then return false end
	local guid = mod.tuning.WishingWell.ZagreusJourney
	if not guid then return false end

	local ok, present = pcall(function() return rom.mods[guid] ~= nil end)
	return ok and present
end


function wishing_well_npc_choices(record)
	local npc = game.EnemyData[record]
	if not npc then return nil end

	for _, set in pairs(npc.InteractTextLineSets or {}) do
		for _, line in ipairs(type(set) == 'table' and set or {}) do
			local choices = type(line) == 'table' and line.Choices
			if type(choices) == 'table' and choices.UpgradeOptions then return choices end
		end
	end
	return nil
end


local function wishing_well_roster()
	local roster = {}
	for _, godName in ipairs(WISHING_WELL_FIELD_GODS) do
		local lootName = extra_god_loot and extra_god_loot[godName]
		if lootName then
			table.insert(roster, { Name = godName, Loot = lootName })
		end
	end

	local zagreus = wishing_well_zagreus_journey()
	for _, ally in ipairs(zagreus and mod.tuning.WishingWell.ZagreusAllies or {}) do
		local choices = wishing_well_npc_choices(ally.Record)
		if choices then
			table.insert(roster, { Name = ally.Name, Record = ally.Record, Choices = choices })
		end
	end

	return roster
end


local function wishing_well_as_source(source)
	local hero = game.CurrentRun.Hero
	source.ObjectId = hero.ObjectId
	source.DestroyOnPickup = nil
	source.CanDuplicate = nil
	source.Traits = source.Traits or {}
	source.PriorityUpgrades = source.PriorityUpgrades or {}
	return source
end


local WISHING_WELL_NPCS = {
	Artemis   = 'NPC_Artemis_Field_01',
	Athena    = 'NPC_Athena_01',
	Dionysus  = 'NPC_Dionysus_01',
	Hades     = 'NPC_Hades_Field_01',
}


local function wishing_well_god_offer(ally)
	local lootData = game.LootData[ally.Loot]
	if not lootData then return false end

	local offer = wishing_well_as_source(game.DeepCopyTable(lootData))
	game.SetTraitsOnLoot(offer)

	if game.IsEmpty(offer.UpgradeOptions) then return false end

	wishing_well_borrow_voice(ally.Name, offer)

	defer_screen_open(game.OpenUpgradeChoiceMenu, offer, {})
	return true
end


local WISHING_WELL_NPC_ARGS_SKIPPED = {
	OnCloseFinishedFunctionName = true,
	PortraitShift = true,
	PortraitName = true,
	UpgradeOptions = true,
}


local function wishing_well_npc_options(source, choices)
	local priority, eligible = {}, {}
	for _, option in ipairs(game.DeepCopyTable(choices.UpgradeOptions or {})) do
		local trait = game.TraitData[option.ItemName]
		local valid = option.GameStateRequirements == nil or game.IsGameStateEligible(source, option.GameStateRequirements)
		if valid and trait and game.IsTraitEligible(trait) then
			if option.PriorityRequirements and game.IsGameStateEligible(source, option.PriorityRequirements) then
				option.SlotEntranceAnimation = option.PrioritySlotEntranceAnimation
				table.insert(priority, option)
			else
				table.insert(eligible, option)
			end
		end
	end

	local picked = {}
	for _ = 1, 3 do
		local pool = not game.IsEmpty(priority) and priority or eligible
		if game.IsEmpty(pool) then break end
		table.insert(picked, game.RemoveRandomValue(pool))
	end

	local order = source.Traits or {}
	table.sort(picked, function(a, b)
		return (game.GetIndex(order, a.ItemName) or 0) < (game.GetIndex(order, b.ItemName) or 0)
	end)
	return picked
end


local function wishing_well_npc_offer(ally)
	local npc = game.EnemyData[ally.Record]
	local source = wishing_well_as_source({
		Name = ally.Record,
		MenuTitle = ally.Record,
		Portrait = npc.Portrait,
		Traits = npc.Traits,
		BlockReroll = true,
	})

	source.UpgradeOptions = wishing_well_npc_options(source, ally.Choices)
	if game.IsEmpty(source.UpgradeOptions) then return false end

	local args = {}
	for key, value in pairs(ally.Choices) do
		if not WISHING_WELL_NPC_ARGS_SKIPPED[key] then args[key] = game.DeepCopyTable(value) end
	end

	defer_screen_open(game.OpenUpgradeChoiceMenu, source, args)
	return true
end


local function wishing_well_npc(unitName)
	if not unitName then return nil end

	for _, set in pairs(game.UnitSetData or {}) do
		if type(set) == 'table' and set[unitName] then return set[unitName] end
	end

	return nil
end


local WISHING_WELL_GREETING = { 'InteractVoiceLines', 'UpgradeMenuOpenVoiceLines' }
local WISHING_WELL_FAREWELL = { 'ExitVoiceLines', 'EncounterEndVoiceLines' }


local function wishing_well_lines(npc, fields)
	for _, field in ipairs(fields) do
		if not game.IsEmpty(npc[field]) then return npc[field] end
	end

	return nil
end


function wishing_well_borrow_voice(godName, offer)
	if not mod.tuning.WishingWell.VoiceLines then return end
	if not offer then return end

	local npc = wishing_well_npc(WISHING_WELL_NPCS[godName or ''])
	if not npc then return end

	offer.UpgradeMenuOpenVoiceLines =
		wishing_well_lines(npc, WISHING_WELL_GREETING) or offer.UpgradeMenuOpenVoiceLines

	offer.UpgradePickedVoiceLines =
		wishing_well_lines(npc, WISHING_WELL_FAREWELL) or offer.UpgradePickedVoiceLines
end


function wishing_well_unlock_exits()
	local run = game.CurrentRun
	local room = run and run.CurrentRoom
	if not room then return end

	local roomData = game.RoomData[room.Name] or room
	if game.IsEmpty(game.MapState.OfferedExitDoors or {}) and not roomData.UnlockWithoutDoors then return end

	for _ = 1, 20 do
		if room.ExitsUnlocked then return end
		if game.CheckRoomExitsReady(room) then
			game.UnlockRoomExits(run, room)
			return
		end
		game.waitUnmodified(0.25)
	end
end


function wishing_well_offer()
	if not duo_on('WishingWell') then return end
	if not game.HeroHasTrait(duo_traits.WishingWell) then return end
	if not game.CurrentRun or not game.CurrentRun.Hero then return end

	local remaining = wishing_well_roster()
	while not game.IsEmpty(remaining) do
		local ally = game.RemoveRandomValue(remaining)
		local offered = ally.Choices and wishing_well_npc_offer(ally) or (ally.Loot and wishing_well_god_offer(ally))
		if offered then
			wishing_well_unlock_exits()
			return
		end
	end
end


local function wishing_well_is_reprieve_door(exitDoor)
	if not duo_on('WishingWell') then return false end
	if not game.HeroHasTrait(duo_traits.WishingWell) then return false end

	local room = exitDoor and exitDoor.Room
	return (room and WISHING_WELL_IS_REPRIEVE[room.Name]) == true
end


function wishing_well_add_door_icon(exitDoor, subIcons)
	if not subIcons or not wishing_well_is_reprieve_door(exitDoor) then return end
	table.insert(subIcons, {
		Name = 'SWuWishingWellReprieve',
		Animation = mod.tuning.WishingWell.DoorIcon,
	})
end


function wishing_well_mark_door(exitDoor)
	if not wishing_well_is_reprieve_door(exitDoor) then return end

	for _, backingId in ipairs(exitDoor.RewardPreviewBackingIds or {}) do
		game.SetColor({ Id = backingId, Color = mod.tuning.WishingWell.DoorGlow })
	end

	local iconId = (exitDoor.AdditionalIcons or {}).SWuWishingWellReprieve
	if iconId then
		game.SetScale({ Id = iconId, Fraction = mod.tuning.WishingWell.DoorIconScale })
	end
end


function wishing_well_keep_reprieve_offered()
	if not duo_on('WishingWell') then return end
	if not in_run() or not game.HeroHasTrait(duo_traits.WishingWell) then return end

	local run = game.CurrentRun
	if not run or not run.CurrentRoom or not run.RoomCreations then return end

	run.SWuReprievesEntered = run.SWuReprievesEntered or {}
	for _, name in ipairs(WISHING_WELL_REPRIEVES) do
		if run.CurrentRoom.Name == name then
			run.SWuReprievesEntered[name] = true
		end
		if not run.SWuReprievesEntered[name] then
			run.RoomCreations[name] = nil
		end
	end
end


---@diagnostic disable-next-line: unused-local
function mod.WishingWellForcesFountain(_source, _functionArgs, _args)
	if not duo_on('WishingWell') then return false end
	return game.HeroHasTrait(duo_traits.WishingWell) == true
end


function wishing_well_drink()
	game.thread(function()
		wait_for_screens(mod.tuning.WishingWell.OfferDelay)
		wishing_well_offer()
	end)
end


---@diagnostic disable-next-line: unused-local
function mod.WishingWellAcquire(args, traitData)
	if not duo_on('WishingWell') then return end
	game.thread(function()
		wait_for_screens(mod.tuning.WishingWell.AcquireDelay)
		wishing_well_offer()
	end)
end
