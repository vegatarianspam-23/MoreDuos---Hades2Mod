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

	game.AddTraitToHero({
		FromLoot = true,
		TraitData = game.GetProcessedTraitData({
			Unit = hero,
			TraitName = pick.ItemName,
			Rarity = pick.Rarity or 'Common',
		}),
	})

	game.thread(game.HammerKeepsakeAcquiredPresentation, pick.ItemName)
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
