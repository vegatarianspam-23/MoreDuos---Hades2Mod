---@meta _


register_duo({
	key = 'RoyalBanquet',

	StatLines = mod.tuning.RoyalBanquet.PayHeroicPomLevels
		and { 'SWuRoyalBanquetStatDisplay', 'SWuRoyalBanquetPomStatDisplay' }
		or { 'SWuRoyalBanquetStatDisplay' },
	ExtractValues = {
		{ Key = 'SWuRarityLevels', ExtractAs = 'TooltipRarityLevels' },
		{ Key = 'SWuHeroicPomLevels', ExtractAs = 'TooltipHeroicPomLevels' },
	},

	ExtraFields = {
		SWuRarityLevels = 1,
		SWuHeroicPomLevels = mod.tuning.RoyalBanquet.HeroicPomLevels,

		AcquireFunctionName = _PLUGIN.guid .. '.RoyalBanquetAcquire',
	},
})


local PROPER_UPBRINGING = 'ElementalRarityUpgradeBoon'
local UNCOMMON_GRACE = 'CommonGlobalDamageBoon'


local function royal_banquet_settle_grace()
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero or not game.HeroHasTrait(UNCOMMON_GRACE) then return end

	game.CheckActivatedTraits(hero, { OnlyCheckTraitName = UNCOMMON_GRACE })
end


local function royal_banquet_upgradable(trait)
	if not trait or not trait.Rarity or not trait.RarityLevels then return false end
	local nextRarity = game.GetUpgradedRarity(trait.Rarity)
	return nextRarity ~= nil and trait.RarityLevels[nextRarity] ~= nil
end


local function royal_banquet_pay_heroic(traitName)
	if not mod.tuning.RoyalBanquet.PayHeroicPomLevels then return end

	local run = game.CurrentRun
	if not run then return end
	run.SWuRoyalBanquetPaid = run.SWuRoyalBanquetPaid or {}
	if run.SWuRoyalBanquetPaid[traitName] then return end

	local trait = game.GetHeroTrait(traitName)
	if not trait or trait.Rarity ~= 'Heroic' or trait.BlockStacking then return end

	run.SWuRoyalBanquetPaid[traitName] = true
	game.IncreaseTraitLevel(trait, mod.tuning.RoyalBanquet.HeroicPomLevels)
end


local function royal_banquet_eligible(trait)
	return trait and trait.Name and trait.Rarity and not trait.BlockInRunRarify
		and game.IsGodTrait(trait.Name, { ForShop = true })
end


local function royal_banquet_apply(traits)
	local raise = {}
	for _, trait in ipairs(traits) do
		if royal_banquet_upgradable(trait) then
			table.insert(raise, trait)
		end
	end

	mod.RoyalBanquetBlessing = true
	if not game.IsEmpty(raise) then
		game.AddRarityToTraits(nil, { ForceUpgrade = raise })
	end
	for _, trait in ipairs(traits) do
		royal_banquet_pay_heroic(trait.Name)
	end
	mod.RoyalBanquetBlessing = nil
end


function royal_banquet_bless_traits(traits)
	game.waitUnmodified(0.1)

	local run = game.CurrentRun
	if not run then return end

	run.SWuRoyalBanquetBlessed = run.SWuRoyalBanquetBlessed or {}
	local blessed = run.SWuRoyalBanquetBlessed

	local live = {}
	for _, name in ipairs(traits) do
		local trait = game.GetHeroTrait(name)
		if trait then
			local level = trait.StackNum or 1
			local last = blessed[name]
			if last ~= nil and type(last) ~= 'number' then
				last = level
				blessed[name] = last
			end
			if last == nil or level > last then
				blessed[name] = level
				table.insert(live, trait)
			end
		end
	end
	if not game.IsEmpty(live) then
		royal_banquet_apply(live)
	end

	royal_banquet_settle_grace()
end


local function royal_banquet_upbringing_active()
	local trait = game.GetHeroTrait(PROPER_UPBRINGING)
	if not trait then return false end
	if trait.Activated then return true end

	local requirements = trait.ActivationRequirements
	return requirements ~= nil and game.IsGameStateEligible(trait, requirements)
end


local function royal_banquet_settle_upbringing()
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end
	if not royal_banquet_upbringing_active() then return end

	local names = {}
	for _, trait in ipairs(hero.Traits or {}) do
		if royal_banquet_eligible(trait) and trait.Rarity == 'Rare' then
			table.insert(names, trait.Name)
		end
	end
	if not game.IsEmpty(names) then
		game.thread(royal_banquet_bless_traits, names)
	end
end


function royal_banquet_bless(trait)
	if mod.RoyalBanquetBlessing then return end
	if not duo_on('RoyalBanquet') then return end
	if not game.CurrentRun or not game.CurrentRun.Hero then return end
	if not game.HeroHasTrait(duo_traits.RoyalBanquet) then return end

	if not trait or not trait.Name then return end

	if trait.Name == PROPER_UPBRINGING then
		royal_banquet_settle_upbringing()
		return
	end

	if not royal_banquet_eligible(trait) then return end
	game.thread(royal_banquet_bless_traits, { trait.Name })
end


---@diagnostic disable-next-line: unused-local
function mod.RoyalBanquetAcquire(args, traitData)
	if not duo_on('RoyalBanquet') then return end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end

	local names = {}
	for _, trait in ipairs(hero.Traits or {}) do
		if royal_banquet_eligible(trait) then
			table.insert(names, trait.Name)
		end
	end

	game.thread(royal_banquet_bless_traits, names)
end
