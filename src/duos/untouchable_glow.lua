---@meta _


register_duo({
	key = 'UntouchableGlow',

	StatLines = { 'SWuUntouchableGlowMaxStatDisplay' },
	ExtractValues = {
		{ Key = 'SWuMaxBonus', ExtractAs = 'TooltipMaxBonus', Format = 'Percent', IncludeSigns = true },
		{ Key = 'SWuStepInterval', ExtractAs = 'TooltipInterval', SkipAutoExtract = true },
	},

	ExtraFields = {
		SWuMaxBonus = mod.tuning.UntouchableGlow.MaxPercent,
		SWuStepInterval = mod.tuning.UntouchableGlow.StepInterval,
		SWuUntouchableMultiplier = 1,
		SWuUntouchableDefense = 1,

		AddOutgoingDamageModifiers = {
			ValidWeapons = DUO_SCOPE_WEAPON.ValidWeapons,
			ValidWeaponsLookup = DUO_SCOPE_WEAPON.ValidWeaponsLookup,
			UseTraitValue = 'SWuUntouchableMultiplier',
			IsMultiplier = true,
		},

		AddIncomingDamageModifiers = {
			UseTraitValue = 'SWuUntouchableDefense',
			IsMultiplier = true,
			IncludeObstacleDamage = mod.tuning.UntouchableGlow.IncludeTraps,
		},

		ShowInHUD = true,

		CustomLabel = {
			DisplayType = 'RoomValue',
			Key = 'SWuUntouchedPercent',
			Text = 'UI_TimedKillBuff',
		},

		SetupFunction = {
			Threaded = true,
			Name = _PLUGIN.guid .. '.UntouchableGlow',
			RepeatOnEncounterStart = true,
			Args = { Interval = mod.tuning.UntouchableGlow.StepInterval },
		},
	},
})


local function untouchable_glow_bonus(run)
	local tuning = mod.tuning.UntouchableGlow
	return math.min((run.SWuUntouchedSteps or 0) * tuning.PercentPerStep, tuning.MaxPercent)
end


local function untouchable_glow_defense(run)
	local tuning = mod.tuning.UntouchableGlow
	return math.min((run.SWuUntouchedSteps or 0) * tuning.DefensePerStep, tuning.MaxDefense)
end


local function untouchable_glow_show(run)
	local trait = game.GetHeroTrait(duo_traits.UntouchableGlow)
	if trait then trait.SWuUntouchableDefense = 1 - untouchable_glow_defense(run) end

	local room = run.CurrentRoom
	if not room then return end

	local percent = math.floor(untouchable_glow_bonus(run) * 100 + 0.5)
	if room.SWuUntouchedPercent == percent then return end

	room.SWuUntouchedPercent = percent
	if trait then game.UpdateTraitNumber(trait) end
end


local function untouchable_glow_everywhere()
	local boon = mod.tuning.UntouchableGlow.NearbyExclusionBoon
	return boon and game.HeroHasTrait(boon)
end


local function untouchable_glow_foe(enemy)
	return enemy ~= nil and not enemy.IsDead and not duo_ignores(enemy)
end


local function untouchable_glow_foes_near()
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return false end

	if untouchable_glow_everywhere() then
		for _, enemy in pairs(game.ActiveEnemies or {}) do
			if untouchable_glow_foe(enemy) then return true end
		end
		return false
	end

	local nearby = game.GetClosestIds({
		Id = hero.ObjectId,
		DestinationName = 'EnemyTeam',
		IgnoreInvulnerable = true,
		IgnoreHomingIneligible = true,
		IgnoreSelf = true,
		Distance = mod.tuning.UntouchableGlow.Radius,
		PreciseCollision = true,
	})

	for _, id in pairs(nearby or {}) do
		if untouchable_glow_foe(game.ActiveEnemies[id]) then return true end
	end

	return false
end


function mod.UntouchableGlow(_hero, args)
	local interval = (args and args.Interval) or mod.tuning.UntouchableGlow.StepInterval

	local run = game.CurrentRun
	if not run then return end

	untouchable_glow_show(run)

	local loop = duo_loop_claim(duo_traits.UntouchableGlow)
	if not loop then return end

	while duo_running(duo_traits.UntouchableGlow) do
		game.wait(interval, loop)
		run = game.CurrentRun
		if not run then return end

		if untouchable_glow_foes_near() then
			run.SWuUntouchedSteps = (run.SWuUntouchedSteps or 0) + 1
		end
		untouchable_glow_show(run)
	end
end


local function untouchable_glow_attack(victim, triggerArgs)
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero or victim ~= hero or not triggerArgs then return false end
	if triggerArgs.ManuallyTriggered or triggerArgs.PureDamage or triggerArgs.EffectName then return false end

	local attacker = triggerArgs.AttackerTable
	if attacker == hero then return false end
	if attacker == nil and triggerArgs.AttackerName == nil then return false end

	local raw = triggerArgs.SWuUntouchableRawDamage or triggerArgs.DamageAmount
	return type(raw) == 'number' and raw > 0
end


local function untouchable_glow_expire_presentation()
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end

	local sound = mod.tuning.UntouchableGlow.ExpireSound
	if sound then game.PlaySound({ Name = sound, Id = hero.ObjectId }) end
	game.thread(game.InCombatTextArgs, {
		TargetId = hero.ObjectId,
		Text = 'SWuUntouchableGlowExpired',
		Duration = 1.45,
		PreDelay = 0.1,
	})
end


function untouchable_glow_struck(victim, triggerArgs)
	if not duo_on('UntouchableGlow') then return end
	if not game.HeroHasTrait(duo_traits.UntouchableGlow) then return end
	if not untouchable_glow_attack(victim, triggerArgs) then return end

	local state = game.SessionMapState
	local now = game._worldTime or 0
	if state.SWuUntouchedGraceUntil and now < state.SWuUntouchedGraceUntil then return end
	state.SWuUntouchedGraceUntil = now + mod.tuning.UntouchableGlow.ResetGrace

	local run = game.CurrentRun
	local had = (run.SWuUntouchedSteps or 0) > 0
	run.SWuUntouchedSteps = 0
	untouchable_glow_show(run)

	if had then untouchable_glow_expire_presentation() end
end


local function untouchable_glow_multiplier(attacker, victim, triggerArgs)
	if not duo_on('UntouchableGlow') then return 1 end
	if not triggerArgs or triggerArgs.EffectName then return 1 end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if attacker ~= hero then return 1 end
	if not game.HeroHasTrait(duo_traits.UntouchableGlow) then return 1 end

	if not game.WeaponSetLookups.HeroPrimarySecondaryWeaponsLinked[triggerArgs.SourceWeapon] then
		return 1
	end

	return 1 + untouchable_glow_bonus(game.CurrentRun)
end


function untouchable_glow_refresh(attacker, victim, triggerArgs)
	local trait = duo_traits.UntouchableGlow and game.GetHeroTrait(duo_traits.UntouchableGlow)
	if not trait then return end

	trait.SWuUntouchableMultiplier = untouchable_glow_multiplier(attacker, victim, triggerArgs)

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if hero and victim == hero then
		local multiplier = 1 - untouchable_glow_defense(game.CurrentRun)
		local raw = triggerArgs and triggerArgs.DamageAmount
		if triggerArgs then triggerArgs.SWuUntouchableRawDamage = raw end
		if type(raw) == 'number' and raw > 0 then
			multiplier = math.max(multiplier, math.min(1, 1 / raw))
		end
		trait.SWuUntouchableDefense = multiplier
	end
end
