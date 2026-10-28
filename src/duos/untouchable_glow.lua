---@meta _


local UNTOUCHABLE_GLOW_ALT = duo_alt('UntouchableGlow')


if UNTOUCHABLE_GLOW_ALT then
	register_duo({
		key = 'UntouchableGlow',

		StatLines = { 'SWuUntouchableGlowAltDodgeStatDisplay' },
		ExtractValues = {
			{ Key = 'SWuDodgeBonus', ExtractAs = 'TooltipDodgeBonus', Format = 'Percent', IncludeSigns = true },
		},

		ExtraFields = {
			SWuDodgeBonus = mod.tuning.UntouchableGlow.AltDodgeBonus,
			SWuUntouchableMultiplier = 1,

			PropertyChanges = {
				{
					LifeProperty = 'DodgeChance',
					ChangeValue = mod.tuning.UntouchableGlow.AltDodgeBonus,
					ChangeType = 'Add',
					DataValue = false,
				},
			},

			AddOutgoingDamageModifiers = {
				UseTraitValue = 'SWuUntouchableMultiplier',
				IsMultiplier = true,
			},
		},
	})
else
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
end


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


local UNTOUCHABLE_UNLIMITED_RANGE = 3000


local function untouchable_glow_everywhere()
	local boon = mod.tuning.UntouchableGlow.NearbyExclusionBoon
	return boon and game.HeroHasTrait(boon)
end


local function untouchable_glow_foes_near()
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return false end

	local nearby = game.GetClosestIds({
		Id = hero.ObjectId,
		DestinationName = 'EnemyTeam',
		IgnoreInvulnerable = true,
		IgnoreHomingIneligible = true,
		IgnoreSelf = true,
		Distance = untouchable_glow_everywhere() and UNTOUCHABLE_UNLIMITED_RANGE or mod.tuning.UntouchableGlow.Radius,
		PreciseCollision = true,
	})

	for _, id in pairs(nearby or {}) do
		local enemy = game.ActiveEnemies[id]
		if enemy and not enemy.IsDead and not duo_ignores(enemy) then return true end
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
	if UNTOUCHABLE_GLOW_ALT or not duo_on('UntouchableGlow') then return end
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


untouchableGlowDodge = untouchableGlowDodge or { Id = nil, Value = 0 }


function untouchable_glow_track_dodge(args)
	if not args or args.Property ~= 'DodgeChance' or type(args.Value) ~= 'number' then return end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero or not hero.ObjectId or args.DestinationId ~= hero.ObjectId then return end

	local dodge = untouchableGlowDodge
	if dodge.Id ~= hero.ObjectId then
		dodge.Id = hero.ObjectId
		dodge.Value = 0
	end

	local change = args.ValueChangeType
	if change == 'Add' then
		dodge.Value = dodge.Value + args.Value
	elseif change == 'Multiply' then
		dodge.Value = dodge.Value * args.Value
	else
		dodge.Value = args.Value
	end
end


local function untouchable_glow_hero_dodge()
	local hero = game.CurrentRun and game.CurrentRun.Hero
	local dodge = untouchableGlowDodge
	if not hero or dodge.Id ~= hero.ObjectId then return 0 end
	return math.max(0, math.min(dodge.Value, 1))
end


local function untouchable_glow_effect_miss(effectName)
	local effect = game.EffectData[effectName]
	if not effect then return 0 end

	local data = effect.EffectData or effect.DataProperties
	local miss = data and data.MissChance
	if type(miss) ~= 'number' then return 0 end
	return math.max(0, math.min(miss, 1))
end


function untouchable_glow_dodge_against(foe)
	local through = 1 - untouchable_glow_hero_dodge()

	for effectName in pairs((foe and foe.ActiveEffects) or {}) do
		through = through * (1 - untouchable_glow_effect_miss(effectName))
	end

	return 1 - through
end


local function untouchable_glow_alt_multiplier(attacker, victim)
	if not duo_on('UntouchableGlow') then return 1 end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero or attacker ~= hero then return 1 end
	if not game.HeroHasTrait(duo_traits.UntouchableGlow) then return 1 end
	if not victim or not victim.ObjectId then return 1 end

	if not untouchable_glow_everywhere() then
		local distance = game.GetDistance({ Id = hero.ObjectId, DestinationId = victim.ObjectId })
		if not distance or distance > mod.tuning.UntouchableGlow.Radius then return 1 end
	end

	return 1 + untouchable_glow_dodge_against(victim) * mod.tuning.UntouchableGlow.AltDamagePerDodge
end


function untouchable_glow_refresh(attacker, victim, triggerArgs)
	local trait = duo_traits.UntouchableGlow and game.GetHeroTrait(duo_traits.UntouchableGlow)
	if not trait then return end

	if UNTOUCHABLE_GLOW_ALT then
		trait.SWuUntouchableMultiplier = untouchable_glow_alt_multiplier(attacker, victim)
		return
	end

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
