---@meta _


local GODDESS_SPITE_HITCH = 'DamageShareEffect'


register_duo({
	key = 'GoddessSpite',

	StatLines = { 'SWuGoddessSpiteStatDisplay' },
	ExtractValues = with_keyword_extracts({
		{ Key = 'SWuReflectMultiplier', ExtractAs = 'TooltipReflectMultiplier', Format = 'Percent', HideSigns = true },
		{ Key = 'SWuNearbyMultiplier', ExtractAs = 'TooltipNearbyMultiplier', SkipAutoExtract = true },
	}, 'Link'),

	ExtraFields = {
		SWuReflectMultiplier = mod.tuning.GoddessSpite.ReflectMultiplier,
		SWuNearbyMultiplier = mod.tuning.GoddessSpite.NearbyMultiplier,

		OnSelfDamagedFunction = { Name = _PLUGIN.guid .. '.GoddessSpiteReflect' },
	},
})


local function goddess_spite_near(hero, unit)
	local tuning = mod.tuning.GoddessSpite
	if tuning.NearbyExclusionBoon and game.HeroHasTrait(tuning.NearbyExclusionBoon) then return true end

	local distance = game.GetDistance({ Id = hero.ObjectId, DestinationId = unit.ObjectId })
	return distance ~= nil and distance <= tuning.Radius
end


local function goddess_spite_damage(victim, args)
	local source = mod.tuning.GoddessSpite.ReflectSource
	local states = { game.CurrentRun, game.GameState }
	local before = {}
	for i, state in ipairs(states) do
		local record = state and state.DamageDealtByHeroRecord
		before[i] = record and record[GODDESS_SPITE_HITCH] or 0
	end

	game.Damage(victim, args)

	for i, state in ipairs(states) do
		local record = state and state.DamageDealtByHeroRecord
		local dealt = record and (record[GODDESS_SPITE_HITCH] or 0) - before[i] or 0
		if dealt > 0 then
			record[GODDESS_SPITE_HITCH] = record[GODDESS_SPITE_HITCH] - dealt
			if record[GODDESS_SPITE_HITCH] <= 0 then record[GODDESS_SPITE_HITCH] = nil end
			record[source] = (record[source] or 0) + dealt
		end
	end
end


local function goddess_spite_share(hero, foe, amount)
	if not foe.DamageShareAmount or not game.HasEffectWithEffectGroup(foe, 'DamageShare') then return end
	if foe.SkipModifiers and not foe.TrainingTarget then return end

	local range = game.EffectData.DamageShareEffect.Range
	local damage = amount * foe.DamageShareAmount

	for _, enemy in pairs(game.ShallowCopyTable(game.ActiveEnemies or {})) do
		if enemy and enemy ~= foe and enemy.ObjectId and not enemy.IsDead and not enemy.AlwaysTraitor
			and not game.IsInvulnerable({ Id = enemy.ObjectId })
			and game.HasEffectWithEffectGroup(enemy, 'DamageShare')
			and game.GetDistance({ Id = foe.ObjectId, DestinationId = enemy.ObjectId }) <= range then

			game.CreateAnimationsBetween({
				Animation = 'HeraRope',
				DestinationId = enemy.ObjectId,
				Id = foe.ObjectId,
				Stretch = true,
				UseZLocation = false,
			})

			goddess_spite_damage(enemy, {
				EffectName = GODDESS_SPITE_HITCH,
				DamageAmount = damage,
				AttackerTable = hero,
				AttackerId = hero.ObjectId,
				Silent = false,
				PureDamage = true,
				ImpactAngle = 0,
			})
		end
		game.wait(0.02, game.RoomThreadName)
	end
end


local function goddess_spite_strike(hero, foe, damage, shared)
	local tuning = mod.tuning.GoddessSpite

	game.wait(tuning.ShareDelay, game.RoomThreadName)
	if foe.IsDead then return end

	game.CreateAnimationsBetween({
		Animation = 'HeraRope',
		DestinationId = foe.ObjectId,
		Id = hero.ObjectId,
		Stretch = true,
		UseZLocation = false,
	})

	goddess_spite_share(hero, foe, shared)
	if foe.IsDead then return end

	goddess_spite_damage(foe, {
		AttackerTable = hero,
		AttackerId = hero.ObjectId,
		EffectName = GODDESS_SPITE_HITCH,
		DamageAmount = damage,
		PureDamage = true,
	})
end


---@diagnostic disable-next-line: unused-local
function mod.GoddessSpiteReflect(attacker, _args, triggerArgs)
	if not duo_on('GoddessSpite') then return end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end

	local foe = duo_live_foe(attacker)
	if not foe or foe.IsDead or is_allied_summon(foe) then return end

	local tuning = mod.tuning.GoddessSpite
	local taken = triggerArgs and triggerArgs.DamageAmount
	if triggerArgs and triggerArgs.ManuallyTriggered then
		taken = tuning.HeinousAffrontDamage
	end
	if type(taken) ~= 'number' or taken <= 0 then return end

	for _, unit in pairs(game.ShallowCopyTable(game.ActiveEnemies or {})) do
		if duo_live_foe(unit) and not is_allied_summon(unit) then
			duo_hitch(unit)
		end
	end

	local shared = math.min(taken * tuning.ReflectMultiplier, tuning.ReflectCap)
	if shared <= 0 then return end

	local damage = shared
	local struck = duo_revenge_for_summon() and duo_damaged_victim or hero
	if goddess_spite_near(struck, foe) then
		damage = math.min(shared * tuning.NearbyMultiplier, tuning.ReflectCap)
	end

	game.thread(goddess_spite_strike, hero, foe, damage, shared)
end
