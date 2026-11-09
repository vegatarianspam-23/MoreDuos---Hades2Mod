---@meta _


register_duo({
	key = 'IngeniousInvention',

	StatLines = { 'SWuIngeniousInventionStatDisplay' },
	ExtractValues = {
		{ Key = 'SWuEncountersPerUpgrade', ExtractAs = 'TooltipEncounters' },
	},

	ExtraFields = {
		SWuEncountersPerUpgrade = mod.tuning.IngeniousInvention.EncountersPerHammer,

		AcquireFunctionName = _PLUGIN.guid .. '.IngeniousInventionAcquire',

		CurrentRoom = 0,
		RoomsPerUpgrade = {
			Amount = { BaseValue = mod.tuning.IngeniousInvention.EncountersPerHammer },
		},
	},
})


function ingenious_invention_grant()
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end

	local source = game.DeepCopyTable(game.LootData.WeaponUpgrade)
	game.SetTraitsOnLoot(source)

	local options = source.UpgradeOptions
	if not options or game.IsEmpty(options) then return end

	local pick = options[game.RandomInt(1, #options)]
	if not pick or not pick.ItemName then return end

	ingenious_invention_debug_hammers('before granting ' .. pick.ItemName)

	game.AddTraitToHero({
		FromLoot = true,
		TraitData = game.GetProcessedTraitData({
			Unit = hero,
			TraitName = pick.ItemName,
			Rarity = pick.Rarity or 'Common',
		}),
	})

	ingenious_invention_debug_hammers('after granting ' .. pick.ItemName)

	game.thread(game.HammerKeepsakeAcquiredPresentation, pick.ItemName)
end


local function ingenious_invention_debug(message)
	if not mod.tuning.IngeniousInvention.Debug then return end
	print('[' .. _PLUGIN.guid .. '] IngeniousInvention: ' .. message)
end


function ingenious_invention_debug_hammers(label)
	if not mod.tuning.IngeniousInvention.Debug then return end
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end

	local held = {}
	for _, trait in ipairs(hero.Traits or {}) do
		if trait.IsHammerTrait then
			table.insert(held, tostring(trait.Name) .. '(' .. tostring(trait.Rarity) .. ')')
		end
	end
	ingenious_invention_debug(label .. ': hammers = ' .. (#held > 0 and table.concat(held, ', ') or 'none'))
end


function ingenious_invention_debug_removed(unit, trait)
	if not mod.tuning.IngeniousInvention.Debug then return end
	if not trait or not trait.IsHammerTrait then return end
	if not game.CurrentRun or unit ~= game.CurrentRun.Hero then return end
	local trace = (debug and debug.traceback) and debug.traceback('', 2) or '(no traceback available)'
	ingenious_invention_debug('removing hammer ' .. tostring(trait.Name) .. '\n' .. trace)
end


---@diagnostic disable-next-line: unused-local
function mod.IngeniousInventionAcquire(args, traitData)
	if not duo_on('IngeniousInvention') then return end
	ingenious_invention_grant()
end


function ingenious_invention_check()
	if not duo_on('IngeniousInvention') then return end
	if not game.CurrentRun or not game.CurrentRun.Hero then return end

	local trait = game.GetHeroTrait(duo_traits.IngeniousInvention)
	if not trait or not trait.RoomsPerUpgrade then return end
	if trait.CurrentRoom ~= 0 then return end

	ingenious_invention_grant()
end
