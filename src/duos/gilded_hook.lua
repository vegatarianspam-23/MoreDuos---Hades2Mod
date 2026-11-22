---@meta _


register_duo({
	key = 'GildedHook',

	StatLines = { 'SWuGildedHookStatDisplay' },
	ExtractValues = {
		{ Key = 'SWuGildedHookDuplicateChance', ExtractAs = 'TooltipDuplicateChance', Format = 'LuckModifiedPercent', HideSigns = true },
	},

	ExtraFields = {
		SWuGildedHookDuplicateChance = { BaseValue = mod.tuning.GildedHook.DuplicateChance },
		AcquireFunctionName = _PLUGIN.guid .. '.GildedHookAcquire',
	},
})


once('GildedHook', function()
	modutil.mod.Path.Wrap('HandleUpgradeChoiceSelection', function(base, screen, button, args)
		local source = screen and screen.Source
		local name = source and source.Name
		local duplicable = source and source.CanDuplicate == nil
			and (source.GodLoot or source.TreatAsGodLootByShops or name == 'WeaponUpgrade')
		local anchor = duplicable and source.ObjectId and duo_on('GildedHook') and game.HeroHasTrait(duo_traits.GildedHook)
			and game.SpawnObstacle({ Name = 'InvisibleTarget', Group = 'Standing', DestinationId = source.ObjectId })

		local result = base(screen, button, args)

		if duplicable and gilded_hook_rolls() then
			local loot = game.CreateLoot({ Name = name, SpawnPoint = anchor or nil, AutoLoadPackages = true })
			if loot then
				loot.CanDuplicate = false
				game.thread(gilded_hook_presentation, loot.ObjectId)
			end
		end

		gilded_hook_grant()
		return result
	end)

	modutil.mod.Path.Wrap('RecordConsumableItem', function(base, item, ...)
		local result = base(item, ...)
		gilded_hook_anvil(item)
		return result
	end)
end)


function gilded_hook_rolls()
	return duo_on('GildedHook') and game.HeroHasTrait(duo_traits.GildedHook)
		and game.RandomChance(game.GetTotalHeroTraitValue('SWuGildedHookDuplicateChance')
			* game.GetTotalHeroTraitValue('LuckMultiplier', { IsMultiplier = true }))
end


function gilded_hook_anvil(item)
	local anvil = mod.tuning.GildedHook.Anvil
	if type(item) ~= 'table' or item.Name ~= anvil or item.SWuGildedHookCopy or not item.ObjectId then return end
	if not gilded_hook_rolls() then return end

	local anchor = game.SpawnObstacle({ Name = 'InvisibleTarget', Group = 'Standing', DestinationId = item.ObjectId })
	local copy = gilded_hook_drop(anchor, anvil)
	if copy then
		copy.SWuGildedHookCopy = true
		game.thread(gilded_hook_presentation, copy.ObjectId)
	end
end


---@diagnostic disable-next-line: unused-local
function mod.GildedHookAcquire(args, traitData)
	if not duo_on('GildedHook') or not game.MapState then return end
	game.MapState.SWuGildedHookOwed = (game.MapState.SWuGildedHookOwed or 0) + 1
end


function gilded_hook_grant()
	local state = game.MapState
	local owed = state and state.SWuGildedHookOwed
	if not owed or owed <= 0 then return end
	state.SWuGildedHookOwed = nil

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero or not hero.ObjectId or not duo_on('GildedHook') then return end

	for _ = 1, owed do
		local anchor = game.SpawnObstacle({ Name = 'InvisibleTarget', Group = 'Standing', DestinationId = hero.ObjectId })
		local loot
		if game.RandomChance(mod.tuning.GildedHook.MysteryBoonChance) then
			loot = gilded_hook_drop(anchor, mod.tuning.GildedHook.MysteryBoon)
		else
			loot = game.CreateWeaponLoot({ SpawnPoint = anchor, AutoLoadPackages = true })
		end
		if loot then
			loot.CanDuplicate = false
			game.thread(gilded_hook_presentation, loot.ObjectId)
		end
	end
end


function gilded_hook_drop(anchor, name)
	local id = game.SpawnObstacle({ Name = name, DestinationId = anchor, Group = 'Standing' })
	if not id or id <= 0 then return end

	local box = game.CreateConsumableItem(id, name, 0, { AutoLoadPackages = true })
	if not box then return end
	box.BlockBoughtTextLines = true
	game.SetObstacleProperty({ Property = 'MagnetismWhileBlocked', Value = 0, DestinationId = id })
	game.SetObstacleProperty({ Property = 'CollidesWithObstacles', Value = false, DestinationId = id })
	return box
end


function gilded_hook_presentation(objectId)
	if not objectId then return end
	game.CreateAnimation({ Name = 'PoseidonElementalKnockupFxAlt', DestinationId = objectId })
	game.ApplyUpwardForce({ Id = objectId, Speed = game.RandomFloat(500, 700) })
	game.ApplyForce({ Id = objectId, Speed = game.RandomFloat(75, 260), Angle = game.RandomFloat(0, 360) })
	game.wait(0.75)

	local hero = game.CurrentRun and game.CurrentRun.Hero
	game.PlaySound({ Name = '/SFX/Menu Sounds/PortraitEmoteSparklySFX' })
	if hero and hero.ObjectId then
		local toast = game.SpawnObstacle({ Name = 'BlankObstacle', DestinationId = hero.ObjectId, Group = 'Combat_Menu_Additive' })
		game.DrawScreenRelative({ Id = toast })
		game.CreateAnimation({ Name = 'BiomeStateGoldFx', DestinationId = toast, OffsetX = 0, OffsetY = 0, Group = 'Combat_Menu_Additive' })
	end
	game.thread(game.InCombatText, objectId, 'SWuGildedHookReward', 0.75)
end
