---@meta _


local INTERTWINED_HITCH = 'DamageShareEffect'


local intertwinedFatePulsedAt = {}
local intertwinedFateCaughtAt = {}


local function intertwined_fate_fields()
	local tuning = mod.tuning.IntertwinedFate

	local fields = {
		SWuSharePerHitched = tuning.SharePerHitched,

		SetupFunction = {
			Threaded = true,
			Name = _PLUGIN.guid .. '.IntertwinedFateBind',
			RepeatOnEncounterStart = true,
			Args = { Interval = tuning.BindInterval },
		},

		OnEffectApplyFunction = {
			FunctionName = _PLUGIN.guid .. '.IntertwinedFateApply',
			FunctionArgs = {},
		},
	}

	if tuning.Revenge then
		fields.OnSelfDamagedFunction = { Name = _PLUGIN.guid .. '.IntertwinedFateRevenge' }
	end

	return fields
end


register_duo({
	key = 'IntertwinedFate',

	StatLines = { 'SWuIntertwinedFateStatDisplay' },
	ExtractValues = with_keyword_extracts({ { Key = 'SWuSharePerHitched', ExtractAs = 'TooltipSharePerHitched', Format = 'Percent' } }, 'Link'),

	ExtraFields = intertwined_fate_fields(),
})


local INTERTWINED_FATE_ALT_TRAIT = gods.GetInternalBoonName('IntertwinedFateAltBoon')

if duo_traits.IntertwinedFate and game.TraitData[duo_traits.IntertwinedFate]
	and not game.TraitData[INTERTWINED_FATE_ALT_TRAIT]
then
	local legacy = game.DeepCopyTable(game.TraitData[duo_traits.IntertwinedFate])
	legacy.Name = INTERTWINED_FATE_ALT_TRAIT
	game.TraitData[INTERTWINED_FATE_ALT_TRAIT] = legacy
end


function intertwined_fate_alt_migrate()
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero or not duo_traits.IntertwinedFate then return end

	local legacy = game.GetHeroTrait(INTERTWINED_FATE_ALT_TRAIT)
	if not legacy then return end

	local rarity = legacy.Rarity
	game.RemoveTrait(hero, INTERTWINED_FATE_ALT_TRAIT)
	if not game.HeroHasTrait(duo_traits.IntertwinedFate) then
		game.AddTraitToHero({ TraitName = duo_traits.IntertwinedFate, Rarity = rarity })
	end
	game.UpdateHeroTraitDictionary()
end


local INTERTWINED_UNLIMITED_RANGE = 3000


local function intertwined_fate_radius()
	local tuning = mod.tuning.IntertwinedFate
	if tuning.NearbyExclusionBoon and game.HeroHasTrait(tuning.NearbyExclusionBoon) then
		return INTERTWINED_UNLIMITED_RANGE
	end
	return tuning.NearbyRadius
end


function intertwined_fate_pulse(sourceId, caught)
	local struck = {}
	local fresh = 0
	local nearby = game.GetClosestIds({
		Id = sourceId,
		DestinationName = 'EnemyTeam',
		IgnoreInvulnerable = true,
		StopsProjectiles = true,
		IgnoreHomingIneligible = true,
		IgnoreSelf = true,
		Distance = intertwined_fate_radius(),
		PreciseCollision = true,
	}) or {}

	for _, id in ipairs(nearby) do
		local unit = game.ActiveEnemies and game.ActiveEnemies[id]
		if unit and intertwined_fate_bindable(unit) then
			if not caught[id] then
				caught[id] = true
				fresh = fresh + 1
				intertwinedFateCaughtAt[id] = game._worldTime or 0
				duo_hitch(unit, mod.tuning.IntertwinedFate.NearbyDuration)
			end
			table.insert(struck, unit)
		end
	end

	if mod.tuning.IntertwinedFate.PulseDecal and mod.tuning.IntertwinedFate.PulseFx and fresh > 0 then
		game.CreateAnimation({
			Name = mod.tuning.IntertwinedFate.PulseFx,
			DestinationId = sourceId,
			ScaleRadius = mod.tuning.IntertwinedFate.NearbyRadius,
		})
	end

	return struck
end


local function intertwined_fate_may_pulse(id)
	local now = game._worldTime or 0
	local last = intertwinedFatePulsedAt[id]
	if last and now - last < mod.tuning.IntertwinedFate.PulseCooldown then return false end
	intertwinedFatePulsedAt[id] = now
	return true
end


function intertwined_fate_ripple(sourceId)
	if not intertwined_fate_may_pulse(sourceId) then return end

	local pulsed = { [sourceId] = true }
	local caught = {}
	local wave = { sourceId }

	while #wave > 0 do
		local nextWave = {}
		for _, id in ipairs(wave) do
			for _, unit in ipairs(intertwined_fate_pulse(id, caught)) do
				if not pulsed[unit.ObjectId] then
					pulsed[unit.ObjectId] = true
					table.insert(nextWave, unit.ObjectId)
				end
			end
		end
		intertwined_fate_set_share()

		if #nextWave == 0 or not mod.tuning.IntertwinedFate.Ripple then return end
		game.wait(mod.tuning.IntertwinedFate.ChainDelay, game.RoomThreadName)
		if not duo_running(duo_traits.IntertwinedFate) then return end

		wave = {}
		for _, id in ipairs(nextWave) do
			local unit = game.ActiveEnemies and game.ActiveEnemies[id]
			if unit and not unit.IsDead and intertwined_fate_may_pulse(id) then
				table.insert(wave, id)
			end
		end
	end
end


function intertwined_fate_combat_active()
	local run = game.CurrentRun
	local encounter = run and run.CurrentRoom and run.CurrentRoom.Encounter
	return game.IsCombatEncounterActive(run)
		or not encounter
		or (encounter.DelayedStart and encounter.StartTime)
		or not game.IsEmpty(game.MapState.AggroedUnits)
end


function mod.IntertwinedFateBind(_hero, args)
	local interval = (args and args.Interval) or mod.tuning.IntertwinedFate.BindInterval

	intertwinedFatePulsedAt = {}
	intertwinedFateCaughtAt = {}
	intertwined_fate_set_share()

	local loop = duo_loop_claim(duo_traits.IntertwinedFate)
	if not loop then return end

	while duo_running(duo_traits.IntertwinedFate) do

		if not duo_on('IntertwinedFate') then return end

		if mod.tuning.IntertwinedFate.NearbyOnly then
			if intertwined_fate_combat_active() then
				if mod.tuning.IntertwinedFate.Ripple then
					game.thread(intertwined_fate_ripple, game.CurrentRun.Hero.ObjectId)
				else
					intertwined_fate_pulse(game.CurrentRun.Hero.ObjectId, {})
				end
			end
		else
			for _, unit in pairs(game.ShallowCopyTable(game.ActiveEnemies or {})) do
				if intertwined_fate_bindable(unit) then
					duo_hitch(unit)
				end
			end
		end

		intertwined_fate_set_share()
		game.wait(interval, loop)
	end

	intertwined_fate_set_share()
end


function mod.IntertwinedFateApply(victim, args, triggerArgs)
	if not duo_on('IntertwinedFate') then return end

	local effectName = triggerArgs and triggerArgs.EffectName
	if effectName == INTERTWINED_HITCH then
		return intertwined_fate_chain(victim)
	end
end


function intertwined_fate_chain(victim)
	if not mod.tuning.IntertwinedFate.NearbyOnly then return end
	if not mod.tuning.IntertwinedFate.Ripple then return end
	if not duo_running(duo_traits.IntertwinedFate) then return end
	if not victim or not victim.ObjectId or victim.IsDead then return end
	if victim == game.CurrentRun.Hero then return end

	local caughtAt = intertwinedFateCaughtAt[victim.ObjectId]
	if caughtAt and (game._worldTime or 0) - caughtAt < mod.tuning.IntertwinedFate.PulseCooldown then return end

	game.thread(intertwined_fate_ripple, victim.ObjectId)
end


function intertwined_fate_bindable(unit)
	if not duo_foe(unit) then return false end
	if not mod.tuning.IntertwinedFate.BindSummons and is_allied_summon(unit) then return false end
	return true
end


function intertwined_fate_wears_hitch(unit)
	return unit ~= nil and not unit.IsDead
		and unit.ActiveEffects ~= nil and unit.ActiveEffects[INTERTWINED_HITCH] ~= nil
end


function intertwined_fate_hitched()
	local total = 0
	for _, unit in pairs(game.ActiveEnemies or {}) do
		if intertwined_fate_wears_hitch(unit) then
			total = total + 1
		end
	end
	return total
end


function intertwined_fate_set_share(hitched)
	local trait = game.GetHeroTrait(duo_traits.IntertwinedFate)
	local tuning = mod.tuning.IntertwinedFate

	if not trait or not duo_running(duo_traits.IntertwinedFate) then
		hitched = 0
	elseif hitched == nil then
		hitched = intertwined_fate_hitched()
	end

	if trait then
		trait.DamageShareAmountIncrease = math.min(hitched * tuning.SharePerHitched, tuning.MaxBonus)
	end

	local amount = game.EffectData[INTERTWINED_HITCH].EffectData.Amount
		+ game.GetTotalHeroTraitValue('DamageShareAmountIncrease')

	for _, unit in pairs(game.ActiveEnemies or {}) do
		if intertwined_fate_wears_hitch(unit) then
			unit.DamageShareAmount = amount
		end
	end
end


function intertwined_fate_lethal_blow(victim, triggerArgs)
	local damage = triggerArgs and triggerArgs.DamageAmount
	if type(damage) ~= 'number' or damage <= 0 then return false end
	if (victim.HealthBuffer or 0) > 0 then return false end
	if game.HasLastStand(victim) then return false end

	return (victim.Health or 0) - damage <= 0
end


function intertwined_fate_last_word(victim, triggerArgs)
	if not duo_on('IntertwinedFate') then return end
	if not mod.tuning.IntertwinedFate.Revenge then return end
	if not mod.tuning.IntertwinedFate.RevengeOnLethal then return end
	if not duo_running(duo_traits.IntertwinedFate) then return end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero or victim ~= hero then return end
	if triggerArgs and triggerArgs.EffectName then return end
	if not intertwined_fate_lethal_blow(victim, triggerArgs) then return end

	local attacker = triggerArgs and triggerArgs.AttackerTable
	if not attacker or attacker == hero then return end

	mod.IntertwinedFateRevenge(attacker, nil, triggerArgs)
end


function intertwined_fate_ally_revenge(victim, attacker, args)
	if not duo_on('IntertwinedFate') then return end
	if not mod.tuning.IntertwinedFate.Revenge then return end
	if not duo_running(duo_traits.IntertwinedFate) then return end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero or not victim or victim == hero or victim.IsDead then return end
	if not attacker or attacker == hero or attacker == victim then return end

	if not is_allied_summon(victim) then return end

	if game.HeroHasTrait('SummonRetaliateTalent')
		and game.Contains(game.MapState.SpellSummons or {}, victim)
	then
		return
	end

	mod.IntertwinedFateRevenge(attacker, nil, args)
end


function mod.IntertwinedFateRevenge(attacker, _args, triggerArgs)
	if not duo_on('IntertwinedFate') then return end
	if not mod.tuning.IntertwinedFate.Revenge then return end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end

	local taken = heinous_affront_damage(attacker, triggerArgs)
	if type(taken) ~= 'number' or taken <= 0 then return end

	local foe = duo_live_foe(attacker)
	if foe then duo_hitch(foe) end

	local tuning = mod.tuning.IntertwinedFate
	local damage = taken * tuning.RevengeMultiplier
	if tuning.CapRevenge then
		damage = math.min(damage, tuning.RevengeCap)
	end
	if damage <= 0 then return end

	local struck = {}
	local function strike(unit)
		if not unit or not unit.ObjectId or unit.IsDead or unit == hero then return end
		if struck[unit.ObjectId] then return end
		if is_allied_summon(unit) then return end
		struck[unit.ObjectId] = true

		game.CreateAnimationsBetween({
			Animation = 'HeraRope',
			DestinationId = unit.ObjectId,
			Id = hero.ObjectId,
			Stretch = true,
			UseZLocation = false,
		})

		duo_meter_record(mod.tuning.IntertwinedFate.RevengeSource, unit, damage)

		game.Damage(unit, {
			AttackerTable = hero,
			AttackerId = hero.ObjectId,
			EffectName = INTERTWINED_HITCH,
			DamageAmount = damage,
			PureDamage = true,
		})
	end

	strike(foe)
	for _, unit in pairs(game.ShallowCopyTable(game.ActiveEnemies or {})) do
		if unit.ActiveEffects and unit.ActiveEffects[INTERTWINED_HITCH] then
			strike(unit)
		end
	end
end
