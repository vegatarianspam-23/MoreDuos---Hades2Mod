---@meta _


import 'tuning.lua'
import 'text.lua'
import 'requirements.lua'
import 'meter.lua'


for _, entry in pairs(duo_text) do
	for id in pairs(entry.Keywords or {}) do
		if not game.Contains(game.KeywordList, id) then
			table.insert(game.KeywordList, id)
		end
	end
end


modutil.mod.Path.Wrap("CalculateDamageMultipliers", function(base, attacker, victim, weaponData, triggerArgs)
	spiteful_strength_refresh(attacker, triggerArgs)
	orbital_ring_refresh(attacker, victim)
	untouchable_glow_refresh(attacker, victim, triggerArgs)
	different_league_refresh(attacker, victim)
	solar_eclipse_refresh(attacker)
	local multipliers = base(attacker, victim, weaponData, triggerArgs)
	if bitter_end_applies(attacker, victim, triggerArgs) then
		multipliers = multipliers * mod.tuning.BitterEnd.InflictMultiplier
	end
	return wrathful_hubris_total(attacker, multipliers)
end)


modutil.mod.Path.Wrap("Damage", function(base, victim, triggerArgs)
	return hot_iron_damage(function(...)
		return bleeding_heart_meter(base, ...)
	end, victim, triggerArgs)
end)

modutil.mod.Path.Wrap("CheckOnDamagedPowers", function(base, victim, attacker, args)
	return hot_iron_on_damaged(base, victim, attacker, args)
end)


modutil.mod.Path.Wrap("DoAttack", function(base, enemy, aiData)
	if distress_call_attack_started(enemy, aiData) then return true end
	return base(enemy, aiData)
end)


modutil.mod.Path.Wrap("AresStatusApply", function(base, triggerArgs)
	base(triggerArgs)
	razor_shoals_shorten(triggerArgs)
	bleeding_heart_blade(triggerArgs)
end)


modutil.mod.Path.Wrap("CalculateBaseDamageAdditions", function(base, attacker, victim, triggerArgs)
	local additive = base(attacker, victim, triggerArgs)
	heinous_affront_record(attacker, victim, triggerArgs)
	additive = additive + cold_hearted_power(attacker, victim, triggerArgs)
	additive = additive + plasmic_capacitor_spark_power(attacker, victim, triggerArgs)
	return additive + glacial_advance_power(attacker, triggerArgs)
end)


modutil.mod.Path.Wrap("OnAllEnemiesDead", function(base, currentRoom, currentEncounter)
	blood_born_clear()
	return base(currentRoom, currentEncounter)
end)


modutil.mod.Path.Wrap("ApplyRoot", function(base, victim, functionArgs, triggerArgs)
	return base(victim, cold_hearted_root_args(victim, functionArgs), triggerArgs)
end)


modutil.mod.Path.Wrap("ApplyEffect", function(base, args)
	if args and args.EffectName == 'BurnEffect' and volcanic_crown_ember(args.TriggerArgs) then return end
	different_league_record_miss(args)
	return base(winter_solstice_frost(glowing_brand_glow(args)))
end)


modutil.mod.Path.Wrap("AddResource", function(base, name, amount, source, args)
	local result = base(name, amount, source, args)
	if name == 'Money' then golden_rule_apply() end
	return result
end)

modutil.mod.Path.Wrap("SpendResource", function(base, name, amount, source, args)
	local result = base(name, amount, source, args)
	if name == 'Money' then golden_rule_apply() end
	return result
end)


modutil.mod.Path.Wrap("HandleBurnStacks", function(base, victim, args)
	convective_vortex_reverse(victim, args)
	return base(victim, args)
end)


modutil.mod.Path.Wrap("ApplyBurn", function(base, victim, functionArgs, triggerArgs)
	if volcanic_crown_ember(triggerArgs) then return end
	local stacks = solar_flare_scorch((functionArgs and functionArgs.NumStacks) or 1)

	if functionArgs then
		functionArgs = game.ShallowCopyTable(functionArgs)
		functionArgs.NumStacks = stacks
	else
		functionArgs = { EffectName = 'BurnEffect', NumStacks = stacks }
	end

	return base(victim, functionArgs, triggerArgs)
end)


modutil.mod.Path.Wrap("BloodDropUse", function(base, args, consumable)
	boiling_blood_heal()
	local result = base(args, consumable)
	plasmic_capacitor_bolt()
	return result
end)


modutil.mod.Path.Wrap("DamageEchoApply", function(base, triggerArgs)
	base(triggerArgs)
	storm_front_clear_recharge(triggerArgs)
end)

modutil.mod.Path.Wrap("DamageEchoTrigger", function(base, enemy, effectName, damageMultiplier, additive, cooldown)
	base(enemy, effectName, damageMultiplier, additive, cooldown)
	plasmic_capacitor_drop(enemy)
end)


modutil.mod.Path.Wrap("HandleLootPickup", function(base, currentRun, loot, args)
	if not (loot and loot.SWuFamilyReunion and currentRun) then
		return base(currentRun, loot, args)
	end

	local name = loot.Name
	local seen = currentRun.LootTypeHistory and currentRun.LootTypeHistory[name]
	local biome = currentRun.LootBiomeRecord and currentRun.LootBiomeRecord[name]

	local ok, err = pcall(base, currentRun, loot, args)

	if currentRun.LootTypeHistory then currentRun.LootTypeHistory[name] = seen end
	if currentRun.LootBiomeRecord then currentRun.LootBiomeRecord[name] = biome end
	if not ok then error(err) end
end)

modutil.mod.Path.Wrap("SetTraitsOnLoot", function(base, lootData, args)
	local sacrifice = function(loot, lootArgs)
		return family_trade_offer_sacrifice(base, loot, lootArgs)
	end

	if not (lootData and lootData.SWuFamilyReunion) then
		return sacrifice(lootData, args)
	end

	local reunion = game.GetHeroTrait(duo_traits.FamilyReunion)
	local heldBonus = reunion and reunion.RarityBonus

	if reunion then
		reunion.RarityBonus = { Duo = mod.tuning.FamilyReunion.DuoBonus }
		game.UpdateHeroTraitDictionary()
	end

	local ok, err = pcall(sacrifice, lootData, args)

	if reunion then
		reunion.RarityBonus = heldBonus
		game.UpdateHeroTraitDictionary()
	end
	if not ok then error(err) end
end)


modutil.mod.Path.Wrap("ManaDelta", function(base, delta, args)
	return base(energy_overflow_delta(delta, args), args)
end)


modutil.mod.Path.Wrap("ManaOverTimeRefund", function(base, duration, interval, value, force)
	energy_overflow_owe(value)
	return base(duration, interval, value, force)
end)

modutil.mod.Path.Wrap("CanGoldifyReward", function(base, reward)
	return burnt_offering_allows_purge(base, reward)
end)

modutil.mod.Path.Wrap("GetRewardGoldifyValue", function(base, reward)
	return burnt_offering_purge_gold(base, reward)
end)

modutil.mod.Path.Wrap("GoldifyPresentation", function(base, source)
	local result = base(source)
	burnt_offering_purged(source)
	return result
end)

modutil.mod.Path.Wrap("HandleSellChoiceSelection", function(base, screen, button)
	local result = base(screen, button)
	burnt_offering_sold(button)
	return result
end)

modutil.mod.Path.Wrap("CloseStoreScreen", function(base, screen, button)
	return burnt_offering_close_store(base, screen, button)
end)

modutil.mod.Path.Wrap("GetReplacementTraits", function(base, traitNames, onlyFromLootName)
	return family_trade_replacements(base, traitNames, onlyFromLootName)
end)

modutil.mod.Path.Wrap("GetUpgradedRarity", function(base, baseRarity, rarityUpgradeOrder)
	return family_trade_rarity(base, baseRarity, rarityUpgradeOrder)
end)

modutil.mod.Path.Wrap("HandleUpgradeChoiceSelection", function(base, screen, button, args)
	return family_trade_choose(base, screen, button, args)
end)

modutil.mod.Path.Wrap("RemoveWeaponTrait", function(base, traitName, args)
	return family_trade_keep(base, traitName, args)
end)

modutil.mod.Path.Wrap("HasTraitRequirements", function(base, traitName)
	return burnt_offering_meets_requirements(base, traitName)
end)


modutil.mod.Path.Wrap("Heal", function(base, victim, triggerArgs)
	gentle_caress_overheal(victim, triggerArgs)
	return base(victim, triggerArgs)
end)


modutil.mod.Path.Wrap("AddTraitToHero", function(base, args)
	local added = base(args)
	royal_banquet_bless(added or (args and args.TraitData))
	family_trade_reslot()
	glowing_brand_sync()
	hot_iron_invalidate()
	return added
end)


modutil.mod.Path.Wrap("ClampSprintSpeed", function(base, hero)
	local before = solar_eclipse_clamp_snapshot(hero)
	base(hero)
	solar_eclipse_clamp_record(hero, before)
end)


modutil.mod.Path.Wrap("CheckChamberTraits", function(base, ...)
	base(...)
	ingenious_invention_check()
end)


modutil.mod.Path.Wrap("CreateProjectileFromUnit", function(base, args)
	return base(convective_vortex_rift(storm_front_enlarge(args)))
end)

modutil.mod.Path.Wrap("CheckDemeterStormSpawn", function(base, hero, args)
	return base(hero, storm_front_cyclone_args(args))
end)


for _, roomName in ipairs({ 'F_Reprieve01', 'G_Reprieve01', 'I_Reprieve01', 'O_Reprieve01', 'P_Reprieve01' }) do
	local roomData = game.RoomData[roomName]
	if roomData then
		roomData.AlwaysForceRequirements = {
			{ FunctionName = _PLUGIN.guid .. '.WishingWellForcesFountain' },
		}
	end
end


modutil.mod.Path.Wrap("InCombatTextArgs", function(base, args)
	return base(combat_text_stack(args))
end)


modutil.mod.Path.Wrap("CleanupRaiseDeadEncounter", function(base, currentRoom)
	return distress_call_encounter_cleanup(base, currentRoom)
end)


modutil.mod.Path.Wrap("SetupHeroObject", function(base, ...)
	different_league_reset_dodge()
	return base(...)
end)


modutil.mod.Path.Wrap("SetLifeProperty", function(base, args)
	different_league_track_dodge(args)
	return base(args)
end)


modutil.mod.Path.Wrap("DamageHero", function(base, victim, triggerArgs)
	wrathful_hubris_taken(victim, triggerArgs)
	intertwined_fate_last_word(victim, triggerArgs)
	local result = base(victim, triggerArgs)
	untouchable_glow_struck(victim, triggerArgs)
	return result
end)


modutil.mod.Path.Wrap("CheckOnDamagedPowers", function(base, victim, attacker, args)
	base(victim, attacker, args)
	intertwined_fate_ally_revenge(victim, attacker, args)
end)


modutil.mod.Path.Wrap("CheckPoseidonFont", function(base, victim, triggerArgs)
	return bubbling_cauldron_font(base, victim, triggerArgs)
end)


modutil.mod.Path.Wrap("CheckBloodDropDisplay", function(base, ...)
	base(...)
	plasmic_capacitor_show_counter()
end)


modutil.mod.Path.Wrap("UpdateBloodDropSpeed", function(base, functionArgs, healthChange)
	base(functionArgs, healthChange)
	plasmic_capacitor_raise_ceiling()
end)


modutil.mod.Path.Wrap("GetTotalHeroTraitValue", function(base, propertyName, args)
	local value = base(propertyName, args)
	if propertyName == 'LuckMultiplier' then
		tipped_scales_arm(value)
	end
	return value
end)

modutil.mod.Path.Wrap("RandomChance", function(base, chance, rng)
	local rolled = tipped_scales_chance(chance)
	local result = base(rolled, rng)
	tipped_scales_answer(chance, result)
	return result
end)

modutil.mod.Path.Wrap("TraitUIActivateTraits", function(base, args)
	local result = base(args)
	tipped_scales_refresh()
	return result
end)


modutil.mod.Path.Wrap("CreateSpellButtons", function(base, screen)
	base(screen)
	discerning_taste_discount_hex(screen)
end)

modutil.mod.Path.Wrap("CreateBoonLootButtons", function(base, screen, lootData, reroll, args)
	local result = discerning_taste_free_boons(base, screen, lootData, reroll, args)
	discerning_taste_discount_boons(screen, lootData)
	return result
end)


modutil.mod.Path.Wrap("RootApplyPresentation", function(base, victim, victimId)
	if victim and victim.RootActive then return end
	cold_hearted_root_started(victim)
	return base(victim, victimId)
end)

modutil.mod.Path.Wrap("ChillApplyPresentation", function(base, victim, victimId)
	if victim then
		if victim.SWuChillTinted then return end
		victim.SWuChillTinted = true
	end
	return base(victim, victimId)
end)

modutil.mod.Path.Wrap("ChillClearPresentation", function(base, victim, victimId)
	if victim then victim.SWuChillTinted = nil end
	return base(victim, victimId)
end)


modutil.mod.Path.Wrap("AttemptPanelReroll", function(base, screen, button)
	discerning_taste_settle_cost(screen, button)
	return discerning_taste_panel_reroll(base, screen, button)
end)

modutil.mod.Path.Wrap("UpdateStoreReroll", function(base, screen, options, rerollFunctionName)
	local result = discerning_taste_free_store(base, screen, options, rerollFunctionName)
	discerning_taste_discount_store(screen)
	return result
end)

modutil.mod.Path.Wrap("GetUseText", function(base, useTarget)
	return discerning_taste_free_prompt(base, useTarget)
end)

modutil.mod.Path.Wrap("GetShipWheelUseText", function(base, useTarget, args)
	return discerning_taste_free_prompt(base, useTarget, args)
end)

modutil.mod.Path.Wrap("AssignRoomToExitDoor", function(base, door, room)
	return discerning_taste_free_prompt(base, door, room)
end)

modutil.mod.Path.Wrap("ShowUseButton", function(base, objectId, useTarget)
	local result = base(objectId, useTarget)
	discerning_taste_free_control(useTarget)
	return result
end)

modutil.mod.Path.Wrap("AttemptReroll", function(base, run, target)
	return discerning_taste_door_reroll(base, run, target)
end)

modutil.mod.Path.Wrap("RerollSpendPresentation", function(base, amount)
	if discerning_taste_swallow_spend() then return end
	return base(amount)
end)


modutil.mod.Path.Wrap("HeroHasTrait", function(base, traitName)
	if traitName == 'PanelRerollMetaUpgrade' then
		if discerning_taste_held() then return true end
	end
	return base(traitName)
end)


local extraBoons = mod.tuning.Systems.ExtraBoonRewards or 0

if extraBoons > 0 then
	for _, storeName in ipairs({ 'RunProgress', 'MinorRunProgress', 'HubRewards' }) do
		local store = game.RewardStoreData[storeName]
		if store then
			for _ = 1, extraBoons do
				table.insert(store, { Name = 'Boon', AllowDuplicates = true, GameStateRequirements = {} })
			end
		end
	end
end


local surfaceActionBar = game.ScreenData.SurfaceShop.ComponentData.ActionBar

if surfaceActionBar.Children.RerollButton == nil then
	table.insert(surfaceActionBar.ChildrenOrder, 'RerollButton')
	surfaceActionBar.Children.RerollButton = {
		Graphic = 'ContextualActionButton',
		Alpha = 0.0,
		BottomOffset = game.UIData.ContextualButtonBottomOffset,
		Data = {
			OnMouseOverFunctionName = 'MouseOverContextualAction',
			OnMouseOffFunctionName = 'MouseOffContextualAction',
			OnPressedFunctionName = 'AttemptPanelReroll',
			ControlHotkeys = { 'Reroll' },
		},
		Text = ' ',
		TextArgs = game.UIData.ContextualButtonFormatRight,
	}
end


modutil.mod.Path.Wrap("RerollStore", function(base, screen, button)
	local room = game.CurrentRun and game.CurrentRun.CurrentRoom
	local store = room and room.Store
	if not fresh_rerolls_enabled() or not store or game.IsEmpty(store.StoreOptions) then
		return base(screen, button)
	end

	game.DestroyStoreButtons(screen)

	local names = {}
	for _, option in pairs(store.StoreOptions) do
		if option and option.Name then table.insert(names, option.Name) end
	end

	local storeData = game.StoreData.RoomShop
	store.StoreOptions = shop_reroll_options(
		storeData, room.Name, names, storeData.MaxOffers or game.TableLength(store.StoreOptions))

	if not game.IsEmpty(room.IndexesPurchased) then
		for _, index in pairs(room.IndexesPurchased) do
			store.StoreOptions[index] = nil
		end
		store.StoreOptions = game.CollapseTable(store.StoreOptions)
	end

	game.CreateStoreButtons(screen)
end)


modutil.mod.Path.Wrap("CreateSurfaceShopButtons", function(base, screen)
	local result = base(screen)
	surface_shop_draw_reroll(screen)
	return result
end)


modutil.mod.Path.Wrap("OpenUpgradeChoiceMenu", function(base, source, args)
	discerning_taste_unblock_reroll(source)
	return base(source, args)
end)


modutil.mod.Path.Wrap("PopulateDoorRewardPreviewSubIcons", function(base, exitDoor, args)
	local subIcons = base(exitDoor, args)
	wishing_well_add_door_icon(exitDoor, subIcons)
	return subIcons
end)


modutil.mod.Path.Wrap("CreateDoorRewardPreview", function(base, exitDoor, rewardType, lootName, index, args)
	local result = base(exitDoor, rewardType, lootName, index, args)
	wishing_well_mark_door(exitDoor)
	return result
end)


modutil.mod.Path.Wrap("UseHealthFountain", function(base, used, user)
	wishing_well_drink()
	base(used, user)
end)

modutil.mod.Path.Wrap("GiveRandomConsumables", function(base, args, trait, contextArgs)
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if hero and args and args.DestinationId and not game.IsAlive({ Id = args.DestinationId }) then
		args = game.ShallowCopyTable(args)
		args.DestinationId = hero.ObjectId
		args.ForceToValidLocation = true
	end
	return base(args, trait, contextArgs)
end)


modutil.mod.Path.Wrap("LeaveRoom", function(base, currentRun, door)
	mod.TectonicCycleGeneration = (mod.TectonicCycleGeneration or 0) + 1
	return base(currentRun, door)
end)


modutil.mod.Path.Wrap("StartRoom", function(base, currentRun, currentRoom)
	if currentRoom and currentRoom.BiomeStartRoom then distress_call_reset_cooldown() end
	return base(currentRun, currentRoom)
end)


modutil.mod.Path.Wrap("SetupMap", function(base, ...)
	prefix_SetupMap()
	local result = base(...)
	suffix_SetupMap()
	return result
end)


for _, data in pairs(game.ConsumableData) do
	for _, requirement in ipairs(data.PurchaseRequirements or {}) do
		if requirement.FunctionName == 'RequiredHealthFraction' then
			requirement.FunctionName = _PLUGIN.guid .. '.GentleCaressHealthGate'
		end
	end
end


local POOLED = true

local PLACEHOLDER_ICON = _PLUGIN.guid .. 'BoonIcons\\Placeholder'

local function cross_list_duo(other, traitName)
	if not POOLED or not other or not traitName then return end

	local loot = game.LootData[other .. 'Upgrade']
	if loot then
		loot.Traits = loot.Traits or {}
		if not game.Contains(loot.Traits, traitName) then
			table.insert(loot.Traits, traitName)
		end
	end

	local sortOrder = game.ScreenData.BoonInfo.TraitSortOrder[other .. 'Upgrade']
	if sortOrder and not game.Contains(sortOrder, traitName) then
		table.insert(sortOrder, traitName)
	end
end

function create_duo(spec)
	if not duo_on(spec.key) then return nil end

	local id = duo_variant(spec.key)
	local text = duo_text[id]
	local requirements = duo_requirements[id]
	if not text or not requirements then
		local missing = not text and 'text.lua' or 'requirements.lua'
		print('[' .. _PLUGIN.guid .. '] no ' .. missing .. ' entry for duo "' .. tostring(id) .. '"')
		return nil
	end

	local traitName = gods.GetInternalBoonName(id .. 'Boon')
	if game.TraitData[traitName] then
		return game.TraitData[traitName]
	end

	gods.CreateBoon({
		pluginGUID = _PLUGIN.guid,
		characterName = requirements.Gods[1],
		internalBoonName = id .. 'Boon',
		InheritFrom = { 'SynergyTrait' },
		addToExistingGod = POOLED,
		reuseBaseIcons = true,
		boonIconPath = spec.icon or PLACEHOLDER_ICON,

		displayName = text.Name,
		description = text.Description,
		StatLines = spec.StatLines,
		customStatLine = spec.customStatLine,
		ExtractValues = spec.ExtractValues,
		ExtraFields = spec.ExtraFields,
		requirements = { OneFromEachSet = duo_offer_sets(id) }
	})

	cross_list_duo(requirements.Gods[2], traitName)

	if requirements.Requires then
		game.TraitRequirements[traitName] = requirements.Requires
	end

	return game.TraitData[traitName]
end

duo_traits = {}
duo_variants = {}

function register_duo(spec)
	local trait = create_duo(spec)
	if trait then
		local id = duo_variant(spec.key)
		duo_traits[spec.key] = gods.GetInternalBoonName(id .. 'Boon')
		duo_variants[spec.key] = id
	end
	return trait
end


local shellText = rom.path.combine(rom.paths.Content, 'Game/Text/en/ShellText.en.sjson')
sjson.hook(shellText, function(data)
	return sjson_ShellText(data)
end)

local macroText = rom.path.combine(rom.paths.Content, 'Game/Text/en/MacroText.en.sjson')
sjson.hook(macroText, function(data)
	return sjson_MacroText(data)
end)

local aphroditeVfx = rom.path.combine(rom.paths.Content, 'Game/Animations/Melinoe_Aphrodite_VFX.sjson')
sjson.hook(aphroditeVfx, function(data)
	return sjson_Animations(data)
end)

local hestiaVfx = rom.path.combine(rom.paths.Content, 'Game/Animations/Melinoe_Hestia_VFX.sjson')
sjson.hook(hestiaVfx, function(data)
	return sjson_HestiaAnimations(data)
end)

local castVfx = rom.path.combine(rom.paths.Content, 'Game/Animations/Melinoe_Cast_VFX.sjson')
sjson.hook(castVfx, function(data)
	return sjson_CastAnimations(data)
end)

local aresVfx = rom.path.combine(rom.paths.Content, 'Game/Animations/Melinoe_Ares_VFX.sjson')
sjson.hook(aresVfx, function(data)
	return sjson_AresAnimations(data)
end)

local hephaestusVfx = rom.path.combine(rom.paths.Content, 'Game/Animations/Melinoe_Hephaestus_VFX.sjson')
sjson.hook(hephaestusVfx, function(data)
	return sjson_HephaestusAnimations(data)
end)

local playerProjectiles = rom.path.combine(rom.paths.Content, 'Game/Projectiles/PlayerProjectiles.sjson')
sjson.hook(playerProjectiles, function(data)
	return sjson_PlayerProjectiles(data)
end)

local traitText = rom.path.combine(rom.paths.Content, 'Game/Text/en/TraitText.en.sjson')
sjson.hook(traitText, function(data)
	return sjson_TraitText(data)
end)

local helpText = rom.path.combine(rom.paths.Content, 'Game/Text/en/HelpText.en.sjson')
sjson.hook(helpText, function(data)
	return sjson_HelpText(data)
end)
