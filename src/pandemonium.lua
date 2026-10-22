---@meta _


PANDEMONIUM = 'SWuPandemoniumBlessing'

local BLESSING_FIELD = 'SWuPandemoniumBlessing'

local BLESSING_PREVIEW = 'ChaosPreview'

local DOUBLE_BOON_TEXT = 'SWuPandemoniumDoubleBoon'


function pandemonium_on()
	return config.enabled ~= false and config.Experimental.Pandemonium == true
end


function pandemonium_held()
	if not pandemonium_on() then return false end
	return in_run() and game.HeroHasTrait(PANDEMONIUM)
end


local function pandemonium_rarity_bonus()
	local step = mod.tuning.Pandemonium.RarityBonus
	return { GodLootOnly = true, Heroic = step, Duo = step, Legendary = step }
end


function pandemonium_add_wrath_bonus()
	if not pandemonium_on() then return end
	if not (config.Experimental and config.Experimental.WrathOfOlympus == true) then return end

	local bonus = (game.TraitData[PANDEMONIUM] or {}).RarityBonus
	if not bonus then return end

	for rarity in pairs(game.TraitRarityData.RarityValues or {}) do
		if string.find(rarity, 'Wrath') then
			bonus[rarity] = mod.tuning.Pandemonium.RarityBonus
		end
	end
end


local function pandemonium_roll_heroic()
	local order = game.TraitRarityData.BoonRarityRollOrder
	if not order or game.Contains(order, 'Heroic') then return end

	for i, rarity in ipairs(order) do
		if rarity == 'Epic' then
			table.insert(order, i + 1, 'Heroic')
			return
		end
	end
end


local function pandemonium_take_all_room()
	return pandemonium_blessing(game.CurrentRun and game.CurrentRun.CurrentRoom) == 'TakeAll'
end


local function pandemonium_double_boon()
	local tuning = mod.tuning.Pandemonium
	local takeAll = pandemonium_take_all_room()

	return {
		Name = PANDEMONIUM,
		DoubleBoonChance = takeAll and 1 or tuning.DoubleBoonChance,
		Uses = takeAll and (tuning.TakeAllUses or 9) or 1,
		DoesNotAutomaticallyExpire = true,
	}
end


function pandemonium_chaos_lines()
	local spoken = game.GlobalVoiceLines[mod.tuning.Pandemonium.VoiceLines]
	if not spoken then return nil end

	local lines = game.DeepCopyTable(spoken)
	lines.ChanceToPlay = nil
	lines.GameStateRequirements = nil
	return lines
end


local function pandemonium_ours(source)
	if not pandemonium_held() then return false end

	local held = game.HasHeroTraitValue('DoubleBoonChance')
	return held ~= nil and held.Name == PANDEMONIUM
end


local PANDEMONIUM_HAMMER_RULES = { 'HammerLootRequirements', 'LateHammerLootRequirements' }


function pandemonium_hammers_remain()
	local pool = game.LootData.WeaponUpgrade

	for _, traitName in ipairs((pool and pool.Traits) or {}) do
		local traitData = game.TraitData[traitName]
		if traitData and not game.HeroHasTrait(traitName) and game.IsTraitEligible(traitData) then
			return true
		end
	end

	return false
end


local function pandemonium_free_hammers()
	for _, name in ipairs(PANDEMONIUM_HAMMER_RULES) do
		local rules = game.NamedRequirementsData[name]

		for index, rule in ipairs(rules or {}) do
			local path = rule.Path or rule.PathFalse
			if path and path[#path] == 'WeaponUpgrade' then
				rules[index] = {
					FunctionName = _PLUGIN.guid .. '.PandemoniumHammers',
					FunctionArgs = { Rule = rule },
				}
			end
		end
	end
end


function pandemonium_meta_reward(name)
	local data = name and game.ConsumableData[name]
	return data ~= nil and data.MetaConversionEligible == true
end


local function pandemonium_room_is_guardian(room)
	for _, name in ipairs(room.LegalEncounters or {}) do
		local data = game.EncounterData[name]
		if data and data.EncounterType == 'Boss' then return true end
	end
	return false
end


local function pandemonium_room_is_wing(room)
	return room ~= nil and room.WingRoom == true
end

local function pandemonium_room_is_wing_end(room)
	return room ~= nil and room.WingEndRoom == true
end


local function pandemonium_room_is_shop(room)
	return room ~= nil and room.StoreDataName ~= nil
end


function pandemonium_reroll_room(room)
	if room == nil or room.NoReroll then return false end
	if pandemonium_room_is_guardian(room) then return false end
	if pandemonium_room_is_wing(room) then return false end
	if pandemonium_room_is_shop(room) then return false end
	return true
end


function pandemonium_blessing(room)
	return room and room[BLESSING_FIELD] or nil
end


local function pandemonium_pick_blessing()
	local entries = mod.tuning.Pandemonium.Blessings or {}

	local total = 0
	for _, entry in ipairs(entries) do
		total = total + (entry.Weight or 0)
	end
	if total <= 0 then return nil end

	local roll = game.RandomFloat(0, total)
	for _, entry in ipairs(entries) do
		roll = roll - (entry.Weight or 0)
		if roll <= 0 then return entry.Key end
	end

	return nil
end


local BLESSING_SAVED_FIELDS = {
	BLESSING_FIELD,
	'RewardPreviewOverride',
	'BoonRaritiesOverride',
	'ForcedReward',
	'LegalEncounters',
	'LegalEncountersDictionary',
}


function pandemonium_bless(room, key)
	if not room or not key then return end

	room[BLESSING_FIELD] = key
	room.RewardPreviewOverride = BLESSING_PREVIEW

	room.SaveWhitelist = room.SaveWhitelist or {}
	for _, field in ipairs(BLESSING_SAVED_FIELDS) do
		room.SaveWhitelist[field] = true
	end
end


local DOOR_BLESSINGS = 'SWuPandemoniumDoorBlessings'


local function pandemonium_door_record(hub)
	if not hub or not hub.PersistentRoomForDoors then return nil end

	hub[DOOR_BLESSINGS] = hub[DOOR_BLESSINGS] or {}

	hub.SaveWhitelist = hub.SaveWhitelist or {}
	hub.SaveWhitelist[DOOR_BLESSINGS] = true

	return hub[DOOR_BLESSINGS]
end


local function pandemonium_door_memory(door, room)
	if not door or not room or not pandemonium_held() then return nil end

	local record = pandemonium_door_record(game.CurrentRun and game.CurrentRun.CurrentRoom)
	if not record then return nil end

	local remembered = record[door.ObjectId]
	if remembered == nil then
		remembered = { Key = pandemonium_blessing(room) }
		record[door.ObjectId] = remembered
	elseif remembered.Key and pandemonium_blessing(room) == nil then
		if not pandemonium_apply(room, remembered.Key) then remembered.Key = nil end
	end

	return remembered
end


local function pandemonium_room_set()
	local room = game.CurrentRun and game.CurrentRun.CurrentRoom
	return room and room.RoomSetName or nil
end


local function pandemonium_room_named(suffix)
	local set = pandemonium_room_set()
	if not set then return nil end

	return game.RoomData[set .. suffix]
end


function pandemonium_ally_available(ally)
	if not ally then return false end
	if not ally.Requires then return true end
	if not (config.Experimental and config.Experimental.ZagreusJourney == true) then return false end

	local ok, present = pcall(function() return rom.mods[ally.Requires] ~= nil end)
	return ok and present
end


function pandemonium_open_allies()
	local run = game.CurrentRun

	for _, ally in ipairs(mod.tuning.Pandemonium.Allies or {}) do
		if pandemonium_ally_available(ally) then
			if run and run.UseRecord then run.UseRecord[ally.Record] = nil end

			if ally.GlobalRecord and game.GameState and game.GameState.UseRecord then
				game.GameState.UseRecord[ally.Record] = nil
			end
		end
	end
end


function pandemonium_open_fated()
	local run = game.CurrentRun

	for _, record in ipairs(mod.tuning.Pandemonium.Fated or {}) do
		if run and run.UseRecord then run.UseRecord[record] = nil end
		if game.GameState and game.GameState.UseRecord then
			game.GameState.UseRecord[record] = nil
		end
	end
end


local function pandemonium_fated_npc(roomData)
	for _, name in ipairs((roomData and roomData.LegalEncounters) or {}) do
		local suffix = name:match('^Story_(.+)$')
		local record = suffix and ('NPC_' .. suffix)

		for _, fated in ipairs(mod.tuning.Pandemonium.Fated or {}) do
			if record == fated then return record end
		end
	end

	return nil
end


function pandemonium_fated_offers(roomData)
	local record = pandemonium_fated_npc(roomData)
	if not record then return false end

	local source = game.EnemyData[record]
	local sets = source and source.InteractTextLineSets
	if not sets then return false end

	local run = game.CurrentRun
	local runRecord = run and run.UseRecord
	local gameRecord = game.GameState and game.GameState.UseRecord

	local metThisRun = runRecord and runRecord[record]
	local metEver = gameRecord and gameRecord[record]
	if runRecord then runRecord[record] = nil end
	if gameRecord then gameRecord[record] = nil end

	local offers = false
	for _, data in pairs(sets) do
		local resolved = game.CheckPartnerConversationData(data)
		if resolved and resolved.PlayOnce
			and game.IsTextLineEligible(run, source, resolved, nil, nil,
				{ IgnorePartnerExists = true, PartnerName = data.Partner }) then
			offers = true
			break
		end
	end

	if runRecord then runRecord[record] = metThisRun end
	if gameRecord then gameRecord[record] = metEver end

	return offers
end


local BLESSING_RARITY = {
	Heroic = 'Heroic',
	Forbidden = 'Legendary',
	Trial = 'Duo',
}

function pandemonium_force_rarity(lootData, key)
	local rarity = key and BLESSING_RARITY[key]
	if not rarity or not lootData then return end

	for _, option in ipairs(lootData.UpgradeOptions or {}) do
		local data = option.ItemName and game.TraitData[option.ItemName]
		local levels = data and data.RarityLevels

		if levels and levels[rarity] then
			option.Rarity = rarity
		end
	end
end


function pandemonium_major_reward(room)
	return game.GetRandomValue(pandemonium_eligible_rewards(room))
end


local function pandemonium_force_encounter(room, name)
	if not room or not name then return false end

	local data = game.EncounterData[name]
	if not data then return false end

	local legal = room.LegalEncounters
	local dictionary = room.LegalEncountersDictionary

	room.LegalEncounters = { name }
	room.LegalEncountersDictionary = { [name] = true }

	if game.IsEncounterEligible(game.CurrentRun, room, data) then
		room.Encounter = nil
		return true
	end

	room.LegalEncounters = legal
	room.LegalEncountersDictionary = dictionary
	return false
end


local function pandemonium_shuffled(list)
	local pool, order = {}, {}
	for _, entry in ipairs(list or {}) do table.insert(pool, entry) end

	while #pool > 0 do
		table.insert(order, table.remove(pool, game.RandomInt(1, #pool)))
	end
	return order
end


local BLESSING_SETUP = {}


function pandemonium_pays_reward(room)
	if not room then return false end
	if room.NoReward then return false end

	local data = game.RoomData[room.Name]
	if data and data.RewardGameStateRequirements then return false end

	return not game.IsEmpty(room.LegalEncounters or {})
end


local function pandemonium_ally_encounters(room)
	local found = {}

	for _, name in ipairs(room and room.LegalEncounters or {}) do
		for _, ally in ipairs(mod.tuning.Pandemonium.Allies or {}) do
			if ally.Prefix and string.sub(name, 1, #ally.Prefix) == ally.Prefix
				and pandemonium_ally_available(ally) then
				table.insert(found, name)
				break
			end
		end
	end

	return found
end


BLESSING_SETUP.Aid = function(room)
	if not pandemonium_pays_reward(room) then return false end

	local candidates = pandemonium_ally_encounters(room)
	if game.IsEmpty(candidates) then return false end

	pandemonium_open_allies()

	for _, name in ipairs(pandemonium_shuffled(candidates)) do
		if pandemonium_force_encounter(room, name) then return true end
	end

	return false
end


function pandemonium_blessing_fits(key, roomData)
	if key ~= 'Aid' then return true end
	if roomData == nil then return false end

	return not game.IsEmpty(pandemonium_ally_encounters(roomData))
end


BLESSING_SETUP.Fated = function(room)
	pandemonium_open_fated()
	return room ~= nil
end


BLESSING_SETUP.Respite = function(room)
	room.ForcedReward = pandemonium_major_reward(room)
	if not room.ForcedReward then return false end

	room.ChosenRewardType = room.ForcedReward
	return true
end


BLESSING_SETUP.Trial = function(room)
	if game.IsEmpty(room.DevotionEncounters or {}) then return false end

	room.ForcedReward = 'Devotion'
	room.BoonRaritiesOverride = { Duo = 1 }
	return true
end


BLESSING_SETUP.Heroic = function(room)
	room.BoonRaritiesOverride = { Heroic = 1 }
end


BLESSING_SETUP.Forbidden = function(room)
	room.BoonRaritiesOverride = { Legendary = 1, Duo = 1 }
end


function pandemonium_apply(room, key)
	if not room or not key then return false end

	local setup = BLESSING_SETUP[key]
	if setup and setup(room) == false then return false end

	pandemonium_bless(room, key)
	return true
end


local BLESSING_REWARD = {
	Heroic = 'Boon',
	Forbidden = 'Boon',
	TakeAll = 'Boon',
	Trial = 'Devotion',
}


local BLESSING_KEEPS_REWARD = {
	FreeShop = true,
	Fountain = true,
	Respite = true,
	Elysium = true,
	Asphodel = true,
	Aid = true,
	Fated = true,
}


local function pandemonium_reward_entry(name, rewardStoreName)
	local store = game.RewardStoreData[rewardStoreName or 'RunProgress']

	for _, entry in ipairs(store or {}) do
		if entry.Name == name then return entry end
	end

	return nil
end


function pandemonium_eligible_rewards(room, previouslyChosenRewards, rewardStoreName)
	local eligible = {}

	for _, name in ipairs(mod.tuning.Pandemonium.BlessedRewards or {}) do
		local entry = pandemonium_reward_entry(name, rewardStoreName)
		if entry == nil
			or game.IsRoomRewardEligible(game.CurrentRun, room, entry, previouslyChosenRewards, {}) then
			table.insert(eligible, name)
		end
	end

	return eligible
end


local function pandemonium_blessed_reward(key, pool)
	if BLESSING_KEEPS_REWARD[key] then return nil end

	local named = BLESSING_REWARD[key]
	if named then return named end

	return game.GetRandomValue(pool or {})
end


local function pandemonium_reward_taken(name, previouslyChosenRewards)
	for _, prev in ipairs(previouslyChosenRewards or {}) do
		if prev.RewardType == name then return true end
	end
	return false
end


local function pandemonium_avoid_collision(name, previouslyChosenRewards, pool)
	pool = pool or {}
	if not name or not game.Contains(pool, name) or not pandemonium_reward_taken(name, previouslyChosenRewards) then
		return name
	end

	local available = {}
	for _, candidate in ipairs(pool) do
		if candidate ~= name and not pandemonium_reward_taken(candidate, previouslyChosenRewards) then
			table.insert(available, candidate)
		end
	end

	return game.GetRandomValue(available) or name
end


local function pandemonium_take_all(screen)
	if not screen or not screen.UpgradeButtons then return false end

	return pandemonium_take_all_room()
end


local DOUBLE_BOON_FLASHES = { { 0.7, 1.0 }, { 0.4, 1.0 }, { 0.2, 0.8 } }


local function pandemonium_double_boon_presentation(nextButton)
	game.wait(0.05)
	game.PlaySound({ Name = mod.tuning.Pandemonium.DoubleBoonSound })

	local lines = pandemonium_chaos_lines()
	if lines then game.thread(game.PlayVoiceLines, lines, true) end

	game.CreateAnimation({
		Name = 'BiomeStateGoldFx',
		DestinationId = nextButton.Id,
		OffsetX = 0,
		OffsetY = 0,
		Group = 'Combat_Menu_Additive',
	})

	game.thread(game.InCombatTextArgs, {
		TargetId = nextButton.Id,
		Text = DOUBLE_BOON_TEXT,
		ScreenSpace = true,
		SkipRise = true,
		PreDelay = 0.05,
		Duration = 1.0,
		OffsetX = 0,
		OffsetY = 0,
		Group = 'Combat_Menu_Additive',
		Justification = 'Center',
		FontSize = 30,
	})

	for _, flash in ipairs(DOUBLE_BOON_FLASHES) do
		game.Flash({
			Id = nextButton.Id,
			Duration = 1.0,
			Speed = 1,
			MinFraction = 0,
			MaxFraction = flash[1],
			Color = game.Color.White,
		})
		game.wait(flash[2])
	end
end


local function pandemonium_ephyra_order(usee)
	local locations = usee and game.ObstacleData[usee.Name] and game.ObstacleData[usee.Name].ScreenLocations
	if not locations then return nil end

	local offered = game.MapState and game.MapState.OfferedExitDoors
	if not offered then return nil end

	local doors = {}
	for _, door in ipairs(game.CollapseTableOrdered(offered) or {}) do
		local raw = door and not door.SkipUnlock and locations[door.ObjectId]
		if raw then
			door.ScreenLocationX = raw.X
			door.ScreenLocationY = raw.Y
			table.insert(doors, door)
		end
	end

	table.sort(doors, game.EphyraZoomOutDoorSort)

	local blessed = {}
	for index, door in ipairs(doors) do
		blessed[index] = pandemonium_blessing(door.Room) ~= nil
	end

	return { Blessed = blessed, Index = 0, Room = game.CurrentRun.CurrentRoom }
end


local function pandemonium_ephyra_hidden()
	local drawing = mod.PandemoniumEphyra
	if not drawing then return nil end

	if drawing.Room ~= game.CurrentRun.CurrentRoom then
		mod.PandemoniumEphyra = nil
		return nil
	end

	local index = drawing.Index + 1
	drawing.Index = index
	if index >= #drawing.Blessed then mod.PandemoniumEphyra = nil end

	if not drawing.Blessed[index] then return nil end

	return { Name = PANDEMONIUM, HiddenRoomReward = true }
end


local function pandemonium_forced_room(base, run, key)
	local set = (mod.tuning.Pandemonium.RoomSets or {})[key]
	if set then
		return base(run, { ForceNextRoomSet = set, SWuPandemonium = true })
	end

	local suffix = (mod.tuning.Pandemonium.Rooms or {})[key]
	if suffix then return pandemonium_room_named(suffix) end

	return nil
end


function pandemonium_encounter_available(room)
	local legal = room and room.LegalEncounters
	if not legal then return true end

	for _, name in ipairs(legal) do
		local data = game.EncounterData[name]
		if data and game.IsEncounterEligible(game.CurrentRun, room, data) then return true end
	end

	return false
end


local function pandemonium_room_suits(key, roomData)
	local set = (mod.tuning.Pandemonium.RoomSets or {})[key]
	if set then
		if not roomData or roomData.RoomSetName ~= set then return false end
		return pandemonium_encounter_available(roomData)
	end

	if (mod.tuning.Pandemonium.Rooms or {})[key] then
		if roomData == nil or not pandemonium_encounter_available(roomData) then return false end
		if key == 'Fated' then return pandemonium_fated_offers(roomData) end

		return true
	end

	return true
end


once('Pandemonium', function()
	if not pandemonium_on() then return end

	local trial = game.LootData.TrialUpgrade
	if not trial then return end

	game.TraitData[PANDEMONIUM] = {
		Name = PANDEMONIUM,
		InheritFrom = { 'ChaosBlessing' },
		DebugOnly = false,
		Icon = 'Boon_Chaos_59',
		CustomName = PANDEMONIUM .. '_Complete',
		AcquireFunctionName = _PLUGIN.guid .. '.PandemoniumAcquire',
		FlavorText = PANDEMONIUM .. '_FlavorText',

		RarityLevels = {
			Legendary = { MinMultiplier = 1, MaxMultiplier = 1 },
		},

		RarityBonus = pandemonium_rarity_bonus(),
	}

	game.ProcessDataInheritance(game.TraitData[PANDEMONIUM], game.TraitData)

	table.insert(trial.PermanentTraits, PANDEMONIUM)
	if trial.TraitSortOrder then
		table.insert(trial.TraitSortOrder, 1, PANDEMONIUM)
	end

	pandemonium_roll_heroic()
	pandemonium_free_hammers()

	modutil.mod.Path.Wrap("ReachedMaxGods", function(base, excludedGods)
		if pandemonium_held() then return false end
		return base(excludedGods)
	end)

	modutil.mod.Path.Wrap("ChooseNextRoomData", function(base, run, args, otherDoors)
		local roomData = base(run, args, otherDoors)
		mod.PandemoniumRolled = true
		if args and args.SWuPandemonium then return roomData end
		if not pandemonium_held() or not pandemonium_reroll_room(roomData) then return roomData end
		if not game.RandomChance(mod.tuning.Pandemonium.BlessingChance) then return roomData end

		local key = nil
		for _ = 1, mod.tuning.Pandemonium.PickTries do
			local picked = pandemonium_pick_blessing()
			if picked == nil then break end
			if pandemonium_blessing_fits(picked, roomData) then
				key = picked
				break
			end
		end
		if not key then return roomData end

		local forced = pandemonium_forced_room(base, run, key)
		if not pandemonium_room_suits(key, forced) then return roomData end

		mod.PandemoniumPending = key
		return forced or roomData
	end)

	modutil.mod.Path.Wrap("CreateRoom", function(base, roomData, args)
		local rolled = mod.PandemoniumRolled
		mod.PandemoniumRolled = nil

		local key = mod.PandemoniumPending
		mod.PandemoniumPending = nil

		if not rolled and key == nil and not mod.PandemoniumDoorPass
			and pandemonium_held() and pandemonium_reroll_room(roomData)
			and game.RandomChance(mod.tuning.Pandemonium.BlessingChance) then
			local picked = pandemonium_pick_blessing()
			local eligible = picked and not (mod.tuning.Pandemonium.Rooms or {})[picked]
				and pandemonium_blessing_fits(picked, roomData)
				and pandemonium_room_suits(picked, roomData)

			if eligible then key = picked end
		end

		local borrowed = key ~= nil and (mod.tuning.Pandemonium.Rooms or {})[key] ~= nil
		local name = borrowed and roomData and roomData.Name or nil
		local run = game.CurrentRun

		local spent = nil
		local spentHere = nil
		if name and run then
			spent = (run.RoomCreations or {})[name]
			spentHere = run.CurrentRoom and (run.CurrentRoom.RoomCreations or {})[name] or nil
		end

		mod.PandemoniumBlessing = (key and pandemonium_held()) and key or nil
		local room = base(roomData, args)
		mod.PandemoniumBlessing = nil

		if room and room.UseOptionalOverrides and room.OptionalOverrides == nil then
			room.OptionalOverrides = {}
		end

		if name and run then
			if run.RoomCreations then run.RoomCreations[name] = spent end
			if run.CurrentRoom and run.CurrentRoom.RoomCreations then
				run.CurrentRoom.RoomCreations[name] = spentHere
			end
		end

		return room
	end)

	modutil.mod.Path.Wrap("RoomInit", function(base, room)
		base(room)
		if not room then return end

		if pandemonium_held() and pandemonium_room_is_wing(room) then
			if mod.PandemoniumWingKey == nil then
				mod.PandemoniumWingKey = false
				if game.RandomChance(mod.tuning.Pandemonium.BlessingChance) then
					local picked = pandemonium_pick_blessing()
					if picked and not (mod.tuning.Pandemonium.Rooms or {})[picked]
						and pandemonium_blessing_fits(picked, room)
						and pandemonium_room_suits(picked, room) then
						mod.PandemoniumWingKey = picked
					end
				end
			end

			if pandemonium_room_is_wing_end(room) then
				local wingKey = mod.PandemoniumWingKey
				mod.PandemoniumWingKey = nil
				if wingKey and not pandemonium_room_is_shop(room) then
					pandemonium_apply(room, wingKey)
				end
			end
		else
			mod.PandemoniumWingKey = nil
		end

		local key = mod.PandemoniumBlessing
		if not key then return end

		mod.PandemoniumBlessing = nil
		if pandemonium_room_is_guardian(room) then return end
		if pandemonium_room_is_shop(room) and not (mod.tuning.Pandemonium.Rooms or {})[key] then return end

		pandemonium_apply(room, key)
	end)

	modutil.mod.Path.Wrap("ChooseEncounter", function(base, run, room, args)
		if not room or not pandemonium_blessing(room) or pandemonium_encounter_available(room) then
			return base(run, room, args)
		end

		local data = game.RoomData[room.Name]
		room.LegalEncounters = data and data.LegalEncounters or nil
		room.LegalEncountersDictionary = data and data.LegalEncountersDictionary or nil

		if pandemonium_encounter_available(room) then
			return base(run, room, args)
		end

		local name = room.LegalEncounters and room.LegalEncounters[1]
		local forced = name and game.EncounterData[name]
		if not forced then return base(run, room, args) end

		local previous = run.ForceNextEncounterData
		run.ForceNextEncounterData = forced
		local encounter = base(run, room, args)
		run.ForceNextEncounterData = previous

		return encounter
	end)

	modutil.mod.Path.Wrap("DoUnlockRoomExits", function(base, run, room)
		mod.PandemoniumDoorPass = (room ~= nil and room.PersistentRoomForDoors == true) or nil
		base(run, room)
		mod.PandemoniumDoorPass = nil
	end)

	modutil.mod.Path.Wrap("CreateDoorRewardPreview", function(base, exitDoor, chosenRewardType, chosenLootName, index, args)
		local room = exitDoor and exitDoor.Room
		if not room or not pandemonium_blessing(room) then
			return base(exitDoor, chosenRewardType, chosenLootName, index, args)
		end

		local roomHidden, doorHidden = room.HideRewardPreview, exitDoor.HideRewardPreview
		room.HideRewardPreview, exitDoor.HideRewardPreview = nil, nil

		local ok, err = pcall(base, exitDoor, chosenRewardType, chosenLootName, index, args)

		room.HideRewardPreview, exitDoor.HideRewardPreview = roomHidden, doorHidden
		if not ok then error(err) end

		pandemonium_force_preview(exitDoor, index)
	end)

	modutil.mod.Path.Wrap("HandleManualCapturePointStart", function(base, encounter)
		local room = game.CurrentRun and game.CurrentRun.CurrentRoom
		if not pandemonium_blessing(room) then return base(encounter) end

		return pandemonium_capture_point(encounter)
	end)

	modutil.mod.Path.Wrap("ChooseRoomReward", function(base, run, room, rewardStoreName, previouslyChosenRewards, args)
		local remembered = pandemonium_door_memory(args and args.Door, room)

		local chosen = base(run, room, rewardStoreName, previouslyChosenRewards, args)
		if chosen == nil or not pandemonium_held() then return chosen end

		local key = pandemonium_blessing(room)
		local final = remembered and remembered.Reward

		if not final then
			local pool = pandemonium_eligible_rewards(room, previouslyChosenRewards, rewardStoreName)
			final = chosen

			if key then
				final = pandemonium_avoid_collision(
					pandemonium_blessed_reward(key, pool) or chosen, previouslyChosenRewards, pool)
			end

			if final == chosen and pandemonium_meta_reward(chosen) then
				final = pandemonium_avoid_collision(game.GetRandomValue(pool), previouslyChosenRewards, pool)
			end

			if remembered then remembered.Reward = final end
		end

		if not final or final == chosen then return chosen end

		room.Reward = { Name = final, AllowDuplicates = true }
		return final
	end)

	modutil.mod.Path.Wrap("HasHeroTraitValue", function(base, propertyName)
		local held = base(propertyName)
		if not pandemonium_held() then return held end

		if propertyName == 'DoubleBoonChance' and pandemonium_take_all_room() then
			return pandemonium_double_boon()
		end

		if held ~= nil then return held end

		if propertyName == 'DoubleBoonChance' then return pandemonium_double_boon() end
		if propertyName == 'HiddenRoomReward' then return pandemonium_ephyra_hidden() end

		return held
	end)

	modutil.mod.Path.Wrap("EphyraZoomOut", function(base, usee)
		mod.PandemoniumEphyra = pandemonium_held() and pandemonium_ephyra_order(usee) or nil

		base(usee)

		mod.PandemoniumEphyra = nil
	end)

	modutil.mod.Path.Wrap("DoubleBoonPresentation", function(base, screen, nextButton)
		if not nextButton or not pandemonium_ours() then return base(screen, nextButton) end

		pandemonium_double_boon_presentation(nextButton)
	end)

	modutil.mod.Path.Wrap("HandleUpgradeChoiceSelection", function(base, screen, button, args)

		local source = screen and screen.Source
		if source and (source.StackNum or 1) > 1
			and pandemonium_blessing(game.CurrentRun and game.CurrentRun.CurrentRoom) == 'Duplicate' then
			mod.PandemoniumStackNum = source.StackNum
		end

		if not button or not pandemonium_held() or not pandemonium_take_all(screen) then
			local outcome = base(screen, button, args)
			mod.PandemoniumStackNum = nil
			return outcome
		end

		local state = mod.PandemoniumTakeAll
		if state and state.Screen ~= screen then state = nil end

		local outermost = state == nil
		if outermost then
			state = { Screen = screen, Buttons = screen.UpgradeButtons, Taken = {} }
			mod.PandemoniumTakeAll = state
		end
		state.Taken[button] = true

		local remaining = {}
		for _, other in ipairs(state.Buttons) do
			if not state.Taken[other] then table.insert(remaining, other) end
		end
		screen.UpgradeButtons = remaining

		base(screen, button, args)
		mod.PandemoniumStackNum = nil

		if outermost then
			screen.UpgradeButtons = state.Buttons
			mod.PandemoniumTakeAll = nil
		end
	end)

	modutil.mod.Path.Wrap("SetTransformingTraitsOnLoot", function(base, lootData, upgradeChoiceData)
		base(lootData, upgradeChoiceData)
		pandemonium_favour_offer(lootData, upgradeChoiceData)
	end)

	modutil.mod.Path.Wrap("GetShopCostMultiplier", function(base, ...)
		if pandemonium_blessing(game.CurrentRun and game.CurrentRun.CurrentRoom) == 'FreeShop' then
			return 0
		end
		return base(...)
	end)

	modutil.mod.Path.Wrap("HandleEncounterPreSpawns", function(base, encounter)
		if encounter and encounter.CanEncounterSkip
			and pandemonium_blessing(game.CurrentRun and game.CurrentRun.CurrentRoom) == 'Peace' then
			encounter.SpawnsSkipped = true
		end
		return base(encounter)
	end)

	local PANDEMONIUM_SKIP_TEXT_IDS = {
		Hint_EncounterSkip = true,
		SkipEncounterKeepsakeExpired = true,
	}

	modutil.mod.Path.Wrap("InCombatText", function(base, targetId, combatText, textDuration, args)
		local key = pandemonium_blessing(game.CurrentRun and game.CurrentRun.CurrentRoom)

		if combatText == 'Hint_DoubleItem' and key == 'Duplicate' then
			game.PlaySound({ Name = mod.tuning.Pandemonium.DoubleBoonSound })
			return base(targetId, DOUBLE_BOON_TEXT, textDuration, args)
		end

		if PANDEMONIUM_SKIP_TEXT_IDS[combatText] and key == 'Peace' then
			game.PlaySound({ Name = mod.tuning.Pandemonium.DoubleBoonSound })
			return base(targetId, DOUBLE_BOON_TEXT, textDuration, args)
		end

		return base(targetId, combatText, textDuration, args)
	end)

	modutil.mod.Path.Wrap("SetTraitsOnLoot", function(base, lootData, args)
		local key = pandemonium_blessing(game.CurrentRun and game.CurrentRun.CurrentRoom)

		if lootData and key == 'Forbidden' then
			lootData.StripRequirements = true
		end

		local result = base(lootData, args)
		pandemonium_force_rarity(lootData, key)
		return result
	end)

	modutil.mod.Path.Wrap("GetTotalHeroTraitValue", function(base, propertyName, args)
		if propertyName == 'DoubleRewardChance'
			and pandemonium_blessing(game.CurrentRun and game.CurrentRun.CurrentRoom) == 'Duplicate' then
			return 1
		end
		return base(propertyName, args)
	end)

	modutil.mod.Path.Wrap("CreateLoot", function(base, args)
		if args and args.StackNum == nil and mod.PandemoniumStackNum then
			args.StackNum = mod.PandemoniumStackNum
		end

		local loot = base(args)
		if loot and pandemonium_blessing(game.CurrentRun and game.CurrentRun.CurrentRoom) == 'Duplicate' then
			loot.CanDuplicate = true
		end
		return loot
	end)

	modutil.mod.Path.Wrap("CreateConsumableItemFromData", function(base, consumableId, consumableItem, costOverride, args)
		local item = base(consumableId, consumableItem, costOverride, args)
		if item and pandemonium_blessing(game.CurrentRun and game.CurrentRun.CurrentRoom) == 'Duplicate' then
			item.CanDuplicate = true
		end
		return item
	end)

	modutil.mod.Path.Wrap("DoubleRewardPresentation", function(base, args)
		if pandemonium_blessing(game.CurrentRun and game.CurrentRun.CurrentRoom) ~= 'Duplicate' then
			return base(args)
		end

		local lines = pandemonium_chaos_lines()
		local spoken = game.GlobalVoiceLines.PoseidonDoubleRewardReactionLines
		if lines then game.GlobalVoiceLines.PoseidonDoubleRewardReactionLines = lines end

		local ok, err = pcall(base, args)

		game.GlobalVoiceLines.PoseidonDoubleRewardReactionLines = spoken
		if not ok then error(err) end
	end)

	modutil.mod.Path.Wrap("RecordEncounterClearStats", function(base, encounter)
		base(encounter)
		pandemonium_spoils(game.CurrentRun and game.CurrentRun.CurrentRoom)
	end)

	modutil.mod.Path.Wrap("UnlockRoomExits", function(base, run, room, delay)
		pandemonium_spoils(room)
		return base(run, room, delay)
	end)

	modutil.mod.Path.Wrap("UseHealthFountain", function(base, used, user)
		local hero = game.CurrentRun and game.CurrentRun.Hero
		local before = hero and hero.Health or 0

		local ok, err = pcall(base, used, user)

		if pandemonium_blessing(game.CurrentRun and game.CurrentRun.CurrentRoom) == 'Fountain' then
			pandemonium_swell(before)
		end

		if not ok then error(err) end
	end)
end)


function pandemonium_speak(lines)
	game.waitUnmodified(mod.tuning.Pandemonium.AnnounceDelay, game.RoomThreadName)
	game.PlayVoiceLines(lines, true)
end


function pandemonium_announce()
	if not pandemonium_held() then return end
	if not pandemonium_blessing(game.CurrentRun and game.CurrentRun.CurrentRoom) then return end

	local lines = pandemonium_chaos_lines()
	if not lines then return end

	game.thread(pandemonium_speak, lines)
end


function pandemonium_list_blessing()
	local boonInfo = game.ScreenData and game.ScreenData.BoonInfo
	if not boonInfo or not game.TraitData[PANDEMONIUM] then return end

	boonInfo.TraitSortOrder.TrialUpgrade = boonInfo.TraitSortOrder.TrialUpgrade or {}
	boonInfo.TraitDictionary.TrialUpgrade = boonInfo.TraitDictionary.TrialUpgrade or {}

	local sortOrder = boonInfo.TraitSortOrder.TrialUpgrade
	if not game.Contains(sortOrder, PANDEMONIUM) then
		table.insert(sortOrder, PANDEMONIUM)
	end

	boonInfo.TraitDictionary.TrialUpgrade[PANDEMONIUM] = true
end


local PONY_MENU = 'PonyWarrior-PonyMenu'


local function pandemonium_pony()
	local ok, pony = pcall(function()
		local registry = modutil.mod.Mods and modutil.mod.Mods.Data
		return (registry and registry[PONY_MENU]) or game[PONY_MENU]
	end)
	if not ok or type(pony) ~= 'table' then return nil end
	if type(pony.BoonData) ~= 'table' or type(pony.PopulateBoonData) ~= 'function' then return nil end

	return pony
end


function pandemonium_refresh_pony_menu()
	local pony = pandemonium_pony()
	if not pony then return end

	local list = pony.BoonData.TrialUpgrade
	if not list or game.Contains(list, PANDEMONIUM) then return end

	pony.BoonData.TrialUpgrade = {}
	pcall(pony.PopulateBoonData, 'TrialUpgrade')
end


function pandemonium_swell(before)
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end

	local gained = math.max((hero.Health or 0) - (before or 0), 0)
	if gained <= 0 then return end

	game.AddMaxHealth(gained, PANDEMONIUM)
	game.AddMaxMana(gained, PANDEMONIUM)
end


function pandemonium_force_preview(exitDoor, index)
	local iconId = (exitDoor.RewardPreviewIconIds or {})[index or 1]
	if not iconId or exitDoor.RewardPreviewAnimName == BLESSING_PREVIEW then return end

	exitDoor.RewardPreviewAnimName = BLESSING_PREVIEW
	game.SetAnimation({ DestinationId = iconId, Name = BLESSING_PREVIEW })
end


function pandemonium_capture_point(encounter)
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end

	local room = game.CurrentRun.CurrentRoom

	local spawnPointId = game.SelectSpawnPoint(room, { PreferredSpawnPoint = 'EnemyPoint' }, {
		SpawnNearId = hero.ObjectId,
		SpawnRadius = encounter.CapturePointSpawnRadius or 9999,
		SpawnRadiusMin = encounter.CapturePointSpawnRadiusMin
			or mod.tuning.Pandemonium.CapturePointRadiusMin,
	})

	if spawnPointId == nil then
		spawnPointId = game.GetRandomValue(game.GetIdsByType({ Name = 'EnemyPoint' }))
	end
	if spawnPointId == nil then
		spawnPointId = room.HeroEndPoint or hero.ObjectId
	end

	game.SpawnObstacle({ Name = 'CapturePointSwitch', DestinationId = spawnPointId, Group = 'Standing' })

	game.waitUntil('StartCapturePoint')
end


function pandemonium_spoils(room)
	if not room or room.SWuPandemoniumSpoilsGiven then return end

	local key = pandemonium_blessing(room)
	local spoils = (mod.tuning.Pandemonium.Spoils or {})[key]
	if not spoils then return end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end

	local where = game.GetLocation({ Id = hero.ObjectId })
	if not where then return end

	room.SWuPandemoniumSpoilsGiven = true

	local anchorId = game.SpawnObstacle({
		Name = 'InvisibleTarget',
		LocationX = where.X,
		LocationY = where.Y,
	})

	local radius = mod.tuning.Pandemonium.SpoilsRadius
	for index, name in ipairs(spoils) do
		local offset = game.CalcOffset(math.rad(360 * (index - 1) / #spoils), radius)

		if name == 'Boon' then
			local lootName = game.GetRandomValue(game.GetEligibleLootNames() or {})
			if lootName then
				game.CreateLoot({
					Name = lootName,
					AutoLoadPackages = true,
					DoesNotBlockExit = true,
					SpawnPoint = anchorId,
					OffsetX = offset.X,
					OffsetY = offset.Y,
				})
			end
		elseif game.ConsumableData[name] then
			local dropId = game.SpawnObstacle({
				Name = 'BlankObstacle',
				DestinationId = anchorId,
				Group = 'Standing',
				OffsetX = offset.X,
				OffsetY = offset.Y,
			})
			game.CreateConsumableItem(dropId, name, 0)
		end
	end
end


---@diagnostic disable-next-line: unused-local
function mod.PandemoniumAcquire(acquireArgs, traitData, args)
	if not pandemonium_held() then return end

	local run = game.CurrentRun
	if not run or not run.CurrentRoom then return end

	for _, door in pairs(game.MapState.OfferedExitDoors or {}) do
		local room = door and door.Room
		if room and room.ChosenRewardType and pandemonium_reroll_room(room) then
			game.CallFunctionName(door.RerollFunctionName or 'AttemptRerollDoor', run, door)
		end
	end
end


---@diagnostic disable-next-line: unused-local
function mod.PandemoniumHammers(source, functionArgs, args)
	if not pandemonium_hammers_remain() then return false end
	if pandemonium_held() then return true end

	local rule = functionArgs and functionArgs.Rule
	if not rule then return true end

	return game.IsGameStateEligible(source, { rule })
end


function pandemonium_favour_offer(lootData, upgradeChoiceData)
	if not pandemonium_on() then return end
	if not in_run() or game.HeroHasTrait(PANDEMONIUM) then return end

	local pool = upgradeChoiceData and upgradeChoiceData.PermanentTraits
	if not pool or not game.Contains(pool, PANDEMONIUM) then return end

	local options = lootData and lootData.UpgradeOptions
	if not options or game.IsEmpty(options) then return end

	for _, option in ipairs(options) do
		if option.ItemName == PANDEMONIUM then return end
	end

	if not game.IsTraitEligible(game.TraitData[PANDEMONIUM]) then return end
	if not game.RandomChance(mod.tuning.Pandemonium.OfferChance) then return end

	local last = options[#options]
	last.ItemName = PANDEMONIUM
	last.Rarity = 'Legendary'
end
