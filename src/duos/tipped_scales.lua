---@meta _


local TIPPED_SCALES_STRIKE = 'ZeusRetaliateStrike'
local TIPPED_SCALES_BOLT = mod.tuning.TippedScales.BoltProjectile

duo_alias_projectile(TIPPED_SCALES_STRIKE, TIPPED_SCALES_BOLT)
do
	local sources = game.ScreenData.RunClear.DamageSourceMap
	sources[TIPPED_SCALES_BOLT] = sources[TIPPED_SCALES_BOLT] or sources[TIPPED_SCALES_STRIKE]
end


register_duo({
	key = 'TippedScales',

	StatLines = {
		'SWuTippedScalesBaseStatDisplay',
		'SWuTippedScalesBoltStatDisplay',
	},
	ExtractValues = {
		{ Key = 'SWuBaseFavor', ExtractAs = 'BaseChance', Format = 'Percent', HideSigns = true },
		{ Key = 'SWuBoltDamage', ExtractAs = 'TooltipBoltDamage' },
	},

	ExtraFields = {
		SWuBaseFavor = mod.tuning.TippedScales.BaseFavor,
		SWuBoltDamage = mod.tuning.TippedScales.BoltDamage,

		LuckMultiplier = 1 + mod.tuning.TippedScales.BaseFavor,
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


local tippedScalesChunks = {}

local function tipped_scales_chunk(shortSrc)
	if type(shortSrc) ~= 'string' then return nil end

	local cached = tippedScalesChunks[shortSrc]
	if cached then return cached end

	local quoted = shortSrc:match('^%[string "(.+)"%]$')
	local name = quoted or shortSrc:match('([^\\/]+)$') or shortSrc
	name = name:gsub('%.lua$', '')
	tippedScalesChunks[shortSrc] = name
	return name
end


local tippedScalesArmed = false

local tippedScalesMultiplier = 1

local tippedScalesBoltUntil = 0

local tippedScalesNextStrike = 0


local function tipped_scales_bolt_table(value)
	return type(value) == 'table'
		and (value.SourceProjectile == TIPPED_SCALES_BOLT or value.ProjectileName == TIPPED_SCALES_BOLT)
end


local function tipped_scales_from_bolt(source)
	if (game._worldTime or 0) > tippedScalesBoltUntil then return false end

	for level = source, source + mod.tuning.TippedScales.BoltFrames do
		if level > source and not debug.getinfo(level, 'S') then return false end

		for index = 1, 60 do
			local name, value = debug.getlocal(level, index)
			if name == nil then break end
			if tipped_scales_bolt_table(value) then return true end
		end
	end
	return false
end


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

	for level = 2, 40 do
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
			return name, level
		end
	end
	return nil
end


function tipped_scales_arm(multiplier)
	if not duo_on('TippedScales') then return end
	if not game.HeroHasTrait(duo_traits.TippedScales) then return end

	local matched, level = tipped_scales_caller()
	local fromBolt = matched ~= nil and tipped_scales_from_bolt(level)
	if fromBolt then matched = nil end
	tippedScalesArmed = matched ~= nil
	tippedScalesMultiplier = (type(multiplier) == 'number' and multiplier > 0) and multiplier or 1
	return matched, fromBolt
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

	local favor = mod.tuning.TippedScales.BaseFavor
	local others = math.max(tippedScalesMultiplier - favor, 0)
	return base * others + favor
end


local function tipped_scales_target(hero)
	local ids = game.GetClosestIds({
		Id = hero.ObjectId,
		DestinationName = 'EnemyTeam',
		IgnoreInvulnerable = true,
		IgnoreHomingIneligible = true,
		StopsProjectiles = true,
		Distance = mod.tuning.TippedScales.Range,
		ScaleY = 0.65,
		MaximumCount = 99,
		PreciseCollision = true,
	}) or {}

	local foes = {}
	for _, id in pairs(ids) do
		local unit = (game.ActiveEnemies or {})[id]
		if duo_foe(unit) and not is_allied_summon(unit) then
			table.insert(foes, unit)
		end
	end

	if #foes == 0 then return nil end
	return foes[game.RandomInt(1, #foes)]
end


local function tipped_scales_strike()
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return false end

	local now = game._worldTime or 0
	if now < tippedScalesNextStrike then return false end

	local foe = tipped_scales_target(hero)
	if not foe then return false end
	tippedScalesNextStrike = now + mod.tuning.TippedScales.BoltCooldown

	local name = game.ProjectileData[TIPPED_SCALES_BOLT] and TIPPED_SCALES_BOLT or TIPPED_SCALES_STRIKE
	local base = game.GetBaseDataValue({ Type = 'Projectile', Name = name, Property = 'Damage' })
	if type(base) ~= 'number' or base <= 0 then base = 100 end

	tippedScalesBoltUntil = (game._worldTime or 0) + mod.tuning.TippedScales.BoltWindow

	game.thread(game.CreateZeusBolt, {
		SourceId = hero.ObjectId,
		TargetId = foe.ObjectId,
		ProjectileName = name,
		DamageMultiplier = mod.tuning.TippedScales.BoltDamage / base,
		Range = 1,
		SeekTarget = true,
		Count = 1,
	})
	return true
end


function tipped_scales_answer(chance, succeeded)
	if not tippedScalesArmed then return end

	local base = tipped_scales_base(chance)
	tippedScalesArmed = false

	if not base or succeeded then return end
	if not game.HeroHasTrait(duo_traits.TippedScales) then return end

	return tipped_scales_strike()
end
