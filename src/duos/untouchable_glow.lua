---@meta _


register_duo({
	key = 'UntouchableGlow',

	StatLines = { 'SWuUntouchableGlowMaxStatDisplay' },
	ExtractValues = {
		{ Key = 'SWuPercentPerSecond', ExtractAs = 'TooltipPerSecond', Format = 'Percent', IncludeSigns = true },
		{ Key = 'SWuMaxPercent', ExtractAs = 'TooltipMaxBonus', Format = 'Percent', IncludeSigns = true },
	},

	ExtraFields = {
		SWuPercentPerSecond = mod.tuning.UntouchableGlow.PercentPerSecond,
		SWuMaxPercent = mod.tuning.UntouchableGlow.MaxPercent,
		SWuUntouchableMultiplier = 1,

		AddOutgoingDamageModifiers = {
			ValidWeapons = DUO_SCOPE_WEAPON.ValidWeapons,
			ValidWeaponsLookup = DUO_SCOPE_WEAPON.ValidWeaponsLookup,
			UseTraitValue = 'SWuUntouchableMultiplier',
			IsMultiplier = true,
		},

		ShowInHUD = true,

		CustomLabel = {
			DisplayType = 'RoomValue',
			Key = 'SWuUntouchedPercent',
			Text = 'UI_TimedKillBuff',
		},

		OnSelfDamagedFunction = { Name = _PLUGIN.guid .. '.UntouchableGlowReset' },
		SetupFunction = {
			Threaded = true,
			Name = _PLUGIN.guid .. '.UntouchableGlow',
			RepeatOnEncounterStart = true,
			Args = { Interval = 1.0 },
		},
	},
})


local function untouchable_glow_show(run)
	local room = run.CurrentRoom
	if not room then return end

	local percent = math.floor((run.SWuUntouchedBonus or 0) * 100 + 0.5)
	if room.SWuUntouchedPercent == percent then return end

	room.SWuUntouchedPercent = percent

	local trait = game.GetHeroTrait(duo_traits.UntouchableGlow)
	if trait then game.UpdateTraitNumber(trait) end
end


---@diagnostic disable-next-line: unused-local
function mod.UntouchableGlowReset(_attacker, _args, triggerArgs)
	if not triggerArgs or triggerArgs.HealthProtected then return end
	if triggerArgs.ManuallyTriggered then return end
	if not triggerArgs.DamageAmount or triggerArgs.DamageAmount <= 0 then return end

	local run = game.CurrentRun
	if not run then return end
	run.SWuUntouchedSeconds = 0
	run.SWuUntouchedBonus = 0
	untouchable_glow_show(run)
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
	local interval = (args and args.Interval) or 1.0
	local tuning = mod.tuning.UntouchableGlow

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
			run.SWuUntouchedSeconds = (run.SWuUntouchedSeconds or 0) + interval
			run.SWuUntouchedBonus =
				math.min(run.SWuUntouchedSeconds * tuning.PercentPerSecond, tuning.MaxPercent)
		end
		untouchable_glow_show(run)
	end
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

	local bonus = game.CurrentRun and game.CurrentRun.SWuUntouchedBonus
	if not bonus or bonus <= 0 then return 1 end

	if not victim or not victim.ObjectId then return 1 end
	if untouchable_glow_everywhere() then return 1 + bonus end
	local distance = game.GetDistance({ Id = hero.ObjectId, DestinationId = victim.ObjectId })
	if not distance or distance > mod.tuning.UntouchableGlow.Radius then return 1 end

	return 1 + bonus
end


function untouchable_glow_refresh(attacker, victim, triggerArgs)
	local trait = duo_traits.UntouchableGlow and game.GetHeroTrait(duo_traits.UntouchableGlow)
	if not trait then return end

	trait.SWuUntouchableMultiplier = untouchable_glow_multiplier(attacker, victim, triggerArgs)
end
