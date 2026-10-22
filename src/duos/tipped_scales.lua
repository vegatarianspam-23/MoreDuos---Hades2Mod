---@meta _


register_duo({
	key = 'TippedScales',

	StatLines = {
		'SWuTippedScalesBaseStatDisplay',
		'SWuTippedScalesStatDisplay',
	},
	ExtractValues = {
		{ Key = 'SWuBaseFavor', ExtractAs = 'BaseChance', Format = 'Percent', HideSigns = true },
		{ Key = 'SWuFavorPerMiss', ExtractAs = 'Chance', Format = 'Percent', HideSigns = true },
	},

	ExtraFields = {
		SWuBaseFavor = mod.tuning.TippedScales.BaseFavor,
		SWuFavorPerMiss = mod.tuning.TippedScales.FavorPerMiss,
		SWuMaxFavor = mod.tuning.TippedScales.MaxFavor,

		LuckMultiplier = 1 + mod.tuning.TippedScales.BaseFavor,

		ShowInHUD = true,
		CustomLabel = {
			DisplayType = 'RoomValue',
			Key = 'SWuTippedScalesFavor',
			Text = 'UI_TimedKillBuff',
		},
	},
})


local TIPPED_SCALES_SOURCES = {
	PowersLogic = true,
	WeaponLogic = true,
	SpellLogic = true,
	EffectLogic = true,
	EventLogic = true,

	CombatLogic = true,
}


local TIPPED_SCALES_BLOCKED = {
	CalculateBaseDamage = true,
	CheckOnKillWeaponUpgrades = true,
}


local function tipped_scales_notable_roll(level)
	for index = 1, 60 do
		local name, value = debug.getlocal(level + 1, index)
		if name == nil then break end

		if type(value) == 'table' and type(value.Value) == 'number' and value.Chance ~= nil then
			return value.TriggerArgsKey ~= nil or value.DamagePresentationFunctionName ~= nil
		end
	end
	return false
end


local function tipped_scales_non_enemy(level)
	for index = 1, 60 do
		local name, value = debug.getlocal(level + 1, index)
		if name == nil then break end

		if name == 'victim' and type(value) == 'table' and value.ObjectId ~= nil then
			return (game.ActiveEnemies or {})[value.ObjectId] == nil
		end
	end
	return false
end


local function tipped_scales_chunk(shortSrc)
	if type(shortSrc) ~= 'string' then return nil end

	local quoted = shortSrc:match('^%[string "(.+)"%]$')
	local name = quoted or shortSrc:match('([^\\/]+)$') or shortSrc
	return (name:gsub('%.lua$', ''))
end


local tippedScalesArmed = false

local tippedScalesMultiplier = 1


local function tipped_scales_no_foes()
	for _, unit in pairs(game.ActiveEnemies or {}) do
		if unit and not unit.IsDead and not duo_ignores(unit) and not is_allied_summon(unit) then
			return false
		end
	end
	return true
end


local function tipped_scales_caller()
	if tipped_scales_no_foes() then return nil end

	for level = 2, 16 do
		local info = debug.getinfo(level, 'Sn')
		if not info then return nil end

		if info.name and TIPPED_SCALES_BLOCKED[info.name] then
			if info.name ~= 'CalculateBaseDamage' or not tipped_scales_notable_roll(level) then
				return nil
			end
		end

		local name = tipped_scales_chunk(info.short_src)
		if name and TIPPED_SCALES_SOURCES[name] then
			if name == 'CombatLogic' and tipped_scales_non_enemy(level) then return nil end
			return name
		end
	end
	return nil
end


function tipped_scales_arm(multiplier)
	if not duo_on('TippedScales') then return end
	if not game.HeroHasTrait(duo_traits.TippedScales) then return end

	local matched = tipped_scales_caller()
	tippedScalesArmed = matched ~= nil
	tippedScalesMultiplier = (type(multiplier) == 'number' and multiplier > 0) and multiplier or 1
end


local function tipped_scales_draw(trait, favor)
	local room = game.CurrentRun and game.CurrentRun.CurrentRoom
	if not room or not trait then
		return
	end

	room.SWuTippedScalesFavor = math.floor(favor * 100)
	game.UpdateTraitNumber(trait)
end


local function tipped_scales_set(favor)
	local trait = game.GetHeroTrait(duo_traits.TippedScales)
	if not trait then return end

	local tuning = mod.tuning.TippedScales
	favor = math.max(tuning.BaseFavor, math.min(favor, tuning.MaxFavor))
	trait.SWuFavor = favor
	trait.LuckMultiplier = 1 + favor
	tipped_scales_draw(trait, favor)
end


function tipped_scales_refresh()
	if not duo_on('TippedScales') then return end
	local name = duo_traits.TippedScales
	local trait = name and in_run() and game.GetHeroTrait(name)

	if not trait then return end
	tipped_scales_draw(trait, trait.SWuFavor or mod.tuning.TippedScales.BaseFavor)
end


local function tipped_scales_base(chance)
	if not tippedScalesArmed then return nil end
	if type(chance) ~= 'number' or tippedScalesMultiplier <= 0 then return nil end

	local base = chance / tippedScalesMultiplier
	if base <= 0 or base >= 1 then return nil end
	return base
end


function tipped_scales_chance(chance)
	local base = tipped_scales_base(chance)
	if not base then return chance end

	local trait = game.GetHeroTrait(duo_traits.TippedScales)
	local favor = (trait and trait.SWuFavor) or mod.tuning.TippedScales.BaseFavor

	local others = math.max(tippedScalesMultiplier - favor, 0)
	return base * others + favor
end


function tipped_scales_answer(chance, succeeded)
	if not tippedScalesArmed then return end

	local base = tipped_scales_base(chance)
	tippedScalesArmed = false

	if not base then
		return
	end

	local trait = game.GetHeroTrait(duo_traits.TippedScales)
	if not trait then
		return
	end

	local tuning = mod.tuning.TippedScales
	local before = trait.SWuFavor or tuning.BaseFavor

	if not succeeded then
		tipped_scales_set(before + tuning.FavorPerMiss)
	else
		tipped_scales_set(tuning.BaseFavor)
	end
end
