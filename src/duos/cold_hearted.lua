---@meta _


register_duo({
	key = 'ColdHearted',

	StatLines = { 'SWuColdHeartedPowerStatDisplay' },
	ExtractValues = with_keyword_extracts({
		{ Key = 'SWuColdHeartedPower', ExtractAs = 'TooltipPower', IncludeSigns = true },
	}, 'Root', 'Weak'),

	ExtraFields = {
		SWuColdHeartedPower = mod.tuning.ColdHearted.Power,
	},
})


function cold_hearted_power(attacker, victim, triggerArgs)
	if not duo_on('ColdHearted') then return 0 end
	if not triggerArgs or triggerArgs.EffectName then return 0 end
	if not victim or not victim.RootActive then return 0 end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if attacker ~= hero then return 0 end
	if not game.HeroHasTrait(duo_traits.ColdHearted) then return 0 end

	if not game.WeaponSetLookups.HeroPrimarySecondaryWeaponsLinked[triggerArgs.SourceWeapon] then
		return 0
	end

	return mod.tuning.ColdHearted.Power
end


local coldHeartedNames = {}

local function cold_hearted_root_names(victim)
	local names = coldHeartedNames
	for i = #names, 1, -1 do names[i] = nil end
	for name in pairs(victim.ActiveEffects or {}) do
		local data = game.EffectData[name]
		if data and data.EffectGroup == 'Root' then table.insert(names, name) end
	end
	return names
end


local function cold_hearted_hold(victim, token)
	local interval = mod.tuning.ColdHearted.HoldInterval
	local last = game._worldTime

	while victim.SWuColdHeartedHold == token and not victim.IsDead do
		game.wait(interval, game.RoomThreadName)
		if victim.SWuColdHeartedHold ~= token or victim.IsDead or not victim.RootActive then break end

		local now = game._worldTime
		local elapsed = now - last
		last = now

		if duo_on('ColdHearted') and game.HeroHasTrait(duo_traits.ColdHearted)
			and victim.ActiveEffects and victim.ActiveEffects.WeakEffect and elapsed > 0 then
			local names = cold_hearted_root_names(victim)
			if #names > 0 then
				game.ModifyEffect({ Id = victim.ObjectId, Names = names, AddTime = elapsed })
			end
		end
	end

	if victim.SWuColdHeartedHold == token then victim.SWuColdHeartedHold = nil end
end


function cold_hearted_root_started(victim)
	if not victim or not victim.ObjectId then return end
	if not duo_on('ColdHearted') then return end
	if not game.HeroHasTrait(duo_traits.ColdHearted) then return end

	local token = {}
	victim.SWuColdHeartedHold = token
	game.thread(cold_hearted_hold, victim, token)
end
