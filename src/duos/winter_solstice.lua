---@meta _


local WINTER_SOLSTICE_ALT = duo_alt('WinterSolstice')

function winter_solstice_variant()
	local tuning = mod.tuning.WinterSolstice
	return tuning.SlowVariants[tuning.SlowVariant] or tuning.SlowVariants.Long
end


register_duo({
	key = 'WinterSolstice',

	StatLines = WINTER_SOLSTICE_ALT
		and { 'SWuWinterSolsticeAltFrostStatDisplay' }
		or { 'SWuWinterSolsticeStatDisplay' },
	ExtractValues = with_keyword_extracts(WINTER_SOLSTICE_ALT
		and {
			{ Key = 'SWuFrostAmplifier', ExtractAs = 'TooltipFrostBonus', Format = 'PercentDelta' },
		}
		or {
			{ Key = 'SWuSolsticeDuration', ExtractAs = 'TooltipSolsticeDuration' },
		}, 'SlowField'),

	ExtraFields = {
		SWuSolsticeDuration = winter_solstice_variant().SolsticeDuration,
		SWuFrostAmplifier = mod.tuning.WinterSolstice.FrostAmplifier,

		SetupFunction = {
			Threaded = true,
			Name = _PLUGIN.guid .. '.WinterSolstice',
			RepeatOnEncounterStart = true,
			Args = {
				PollInterval = mod.tuning.WinterSolstice.PollInterval,
				SweepInterval = mod.tuning.WinterSolstice.SweepInterval,
			},
		},
	},
})


local CHILL = 'LegacyChillEffect'

local winterSolsticeGusts = {}


local FROST_GROUPS = { Root = true, Chill = true }

local winterSolsticeFrost = nil

local function winter_solstice_is_frost(effectName)
	if not winterSolsticeFrost then
		winterSolsticeFrost = {}
		for name, data in pairs(game.EffectData or {}) do
			if type(data) == 'table' and FROST_GROUPS[data.EffectGroup or ''] then
				winterSolsticeFrost[name] = true
			end
		end
	end
	return winterSolsticeFrost[effectName] == true
end


function winter_solstice_frost(args)
	if not args or not args.EffectName or not args.DataProperties then return args end
	if not duo_on('WinterSolstice') or not WINTER_SOLSTICE_ALT then return args end

	local amplifier = mod.tuning.WinterSolstice.FrostAmplifier
	if type(amplifier) ~= 'number' or amplifier <= 1 then return args end

	local slow = args.DataProperties.ElapsedTimeMultiplier
	if type(slow) ~= 'number' or slow <= 0 or slow >= 1 then return args end

	if not winter_solstice_is_frost(args.EffectName) then return args end
	if not in_run() or not game.HeroHasTrait(duo_traits.WinterSolstice) then return args end

	local hero = game.CurrentRun.Hero
	if args.Id ~= hero.ObjectId or args.DestinationId == hero.ObjectId then return args end

	winter_solstice_raise_resistance(game.ActiveEnemies[args.DestinationId], amplifier)

	args = game.ShallowCopyTable(args)
	args.DataProperties = game.ShallowCopyTable(args.DataProperties)
	args.DataProperties.ElapsedTimeMultiplier = slow / amplifier
	return args
end


local SLOW_MODIFIER = 'SlowEffectModifier'


function winter_solstice_raise_resistance(unit, amplifier)
	if not unit or not unit.ObjectId or unit.IsDead then return end
	if unit.SWuSlowModifierBase ~= nil then return end

	local base = game.GetUnitDataValue({ Id = unit.ObjectId, Property = SLOW_MODIFIER })
	if type(base) ~= 'number' then return end

	unit.SWuSlowModifierBase = base

	local raised = math.min(base * amplifier, 1)
	if raised ~= base then
		game.SetUnitProperty({ DestinationId = unit.ObjectId, Property = SLOW_MODIFIER, Value = raised })
	end
end


function winter_solstice_restore_resistance()
	for _, unit in pairs(game.ActiveEnemies or {}) do
		if unit and unit.ObjectId and unit.SWuSlowModifierBase ~= nil then
			if not unit.IsDead then
				game.SetUnitProperty({
					DestinationId = unit.ObjectId,
					Property = SLOW_MODIFIER,
					Value = unit.SWuSlowModifierBase,
				})
			end
			unit.SWuSlowModifierBase = nil
		end
	end
end


local function winter_solstice_chill(unit)
	local hero = game.CurrentRun and game.CurrentRun.Hero
	local chill = game.EffectData and game.EffectData[CHILL]
	if not hero or not chill then return end

	local remaining = game.GetEffectTimeRemaining({ Id = unit.ObjectId, EffectName = CHILL }) or 0
	if remaining > mod.tuning.WinterSolstice.ChillRefreshAt then return end

	game.ApplyEffect({
		DestinationId = unit.ObjectId,
		Id = hero.ObjectId,
		EffectName = CHILL,
		DataProperties = game.MergeAllTables({ chill.EffectData }),
	})
end


local function winter_solstice_squall(unit)
	local hero = game.CurrentRun and game.CurrentRun.Hero
	local effectName = mod.tuning.WinterSolstice.SquallEffect
	local effect = game.EffectData and game.EffectData[effectName]
	if not hero or not effect or not effect.DataProperties then return end
	if (unit.ActiveEffects or {})[effectName] then return end

	game.ApplyEffect({
		DestinationId = unit.ObjectId,
		Id = hero.ObjectId,
		EffectName = effectName,
		DataProperties = game.MergeAllTables({
			effect.DataProperties,
			{ Amount = mod.tuning.WinterSolstice.SquallDamage },
		}),
	})
end


local function winter_solstice_calm()
	local effectName = mod.tuning.WinterSolstice.SquallEffect

	for _, unit in pairs(game.ActiveEnemies or {}) do
		if unit and unit.ObjectId then
			game.ClearEffect({ Id = unit.ObjectId, Name = effectName })
		end
	end
end


function winter_solstice_ring()
	local hero = game.CurrentRun and game.CurrentRun.Hero
	local tuning = mod.tuning.WinterSolstice
	if not hero or not tuning.RingFx then return end

	game.CreateAnimation({
		Name = tuning.RingFx,
		DestinationId = hero.ObjectId,
		ScaleRadius = tuning.RingRadius,
	})
end


local function winter_solstice_gust_raise(now, endsAt)
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end

	local tuning = mod.tuning.WinterSolstice
	local spot = game.SpawnObstacle({ Name = 'InvisibleTarget', DestinationId = hero.ObjectId })

	local id = game.CreateProjectileFromUnit({
		Name = tuning.GustProjectile,
		Id = hero.ObjectId,
		DestinationId = spot,
		FireFromTarget = true,
		DataProperties = { AttachToOwner = false },
	})

	game.Destroy({ Id = spot })
	if id then
		table.insert(winterSolsticeGusts, { Id = id, EndsAt = endsAt, FadesAt = now + tuning.GustLinger * 2 })
	end
end


local function winter_solstice_gusts_hold(now, endsAt)
	if #winterSolsticeGusts == 0 then
		winter_solstice_gust_raise(now, endsAt)
		return
	end
	for _, gust in ipairs(winterSolsticeGusts) do
		gust.EndsAt = math.max(gust.EndsAt, endsAt)
	end
end


local function winter_solstice_gusts_expire(now)
	for i = #winterSolsticeGusts, 1, -1 do
		local gust = winterSolsticeGusts[i]
		if not now or now >= gust.EndsAt then
			game.ExpireProjectiles({ ProjectileIds = { gust.Id } })
			table.remove(winterSolsticeGusts, i)
		elseif now >= gust.FadesAt then
			table.remove(winterSolsticeGusts, i)
		end
	end
end


local function winter_solstice_charging()
	for weaponName in pairs(game.MapState.ChargedManaWeapons or {}) do
		if game.GetWeaponChargeFraction({ Name = weaponName }) > 0 then return true end
	end
	return false
end


local function winter_solstice_in_gust(unit)
	local gust = mod.tuning.WinterSolstice.GustProjectile
	local inside = game.GetInProjectilesBlast({
		Id = unit.ObjectId,
		DestinationNames = { gust, mod.tuning.StormFront.Enlarged[gust] },
		UseDamageRadius = true,
		ReturnFirst = true,
	})
	return not game.IsEmpty(inside)
end


local function winter_solstice_squall_reach()
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return {} end

	local tuning = mod.tuning.WinterSolstice
	local everywhere = tuning.NearbyExclusionBoon and game.HeroHasTrait(tuning.NearbyExclusionBoon)
	return game.ToLookup(game.GetClosestIds({
		Id = hero.ObjectId,
		DestinationName = 'EnemyTeam',
		IgnoreInvulnerable = true,
		StopsProjectiles = true,
		IgnoreHomingIneligible = true,
		IgnoreSelf = true,
		Distance = everywhere and 3000 or tuning.SquallRadius,
		ScaleY = not everywhere and tuning.SquallScaleY or nil,
		PreciseCollision = true,
	}))
end


local function winter_solstice_sweep(gusting, chilling)
	local reach = gusting and {} or winter_solstice_squall_reach()
	local squallEffect = mod.tuning.WinterSolstice.SquallEffect

	for _, unit in pairs(game.ShallowCopyTable(game.ActiveEnemies or {})) do
		if unit and unit.ObjectId and not unit.IsDead and not duo_ignores(unit) then
			if not gusting and not reach[unit.ObjectId] then
				if (unit.ActiveEffects or {})[squallEffect] then
					game.ClearEffect({ Id = unit.ObjectId, Name = squallEffect })
				end
			elseif not gusting then
				if chilling then winter_solstice_chill(unit) end
				winter_solstice_squall(unit)
			elseif winter_solstice_in_gust(unit) then
				winter_solstice_chill(unit)
			end
		end
	end
end


function winter_solstice_slow_presentation(hero, phaseShift)
	if phaseShift then return end
	local fade = 0.25
	game.SetAudioEffectState({ Name = 'SpellCharge', Value = 1 })
	game.AdjustColorGrading({ Name = 'MoonDust', Duration = fade })
	game.AdjustRadialBlurDistance({ Fraction = 0.05, Duration = fade })
	game.AdjustRadialBlurStrength({ Fraction = 2, Duration = fade })
	if hero and game.ConfigOptionCache.GraphicsQualityPreset ~= 'GraphicsQualityPreset_Low' then
		game.CreateAnimation({ Name = 'SpellSlowFx', DestinationId = hero.ObjectId })
	end
end


function winter_solstice_recharge()
	return duo_recharge(mod.tuning.WinterSolstice.SlowCooldown)
end


function mod.WinterSolstice(_hero, args)
	local tuning = mod.tuning.WinterSolstice
	local poll = (args and args.PollInterval) or tuning.PollInterval
	local sweepEvery = (args and args.SweepInterval) or tuning.SweepInterval
	local loop = duo_loop_claim(duo_traits.WinterSolstice)
	if not loop then return end

	local gusting = WINTER_SOLSTICE_ALT
	local last = game._worldTime
	local channelled = 0
	local fired = false
	local squallSince = 0
	local sinceSweep = sweepEvery
	local chillStarted = false
	local slowing = false
	local slowUntil = 0
	local slowWarns = {}
	local slowSound = nil
	local slowFired = false
	local slowEndedAt = nil
	local variant = gusting and tuning or winter_solstice_variant()

	local function setSlow(on, quiet)
		if on == slowing then return end
		slowing = on
		if not on then slowEndedAt = game._worldTimeUnmodified end
		local hero = game.CurrentRun and game.CurrentRun.Hero
		local phaseShift = game.SessionMapState and game.SessionMapState.TimeSlowActive
		game.GameplaySetElapsedTimeMultiplier({
			ElapsedTimeMultiplier = tuning.TimeSlow,
			Name = 'SWuWinterSolstice',
			Force = on or nil,
			Reverse = not on or nil,
		})
		if on then
			slowSound = game.PlaySound({ Name = tuning.SlowLoopSound })
			winter_solstice_slow_presentation(hero, phaseShift)
		else
			if slowSound then
				game.StopSound({ Id = slowSound, Duration = 0.2 })
				slowSound = nil
			end
			slowWarns = {}
			if not phaseShift then
				game.SetAudioEffectState({ Name = 'SpellCharge', Value = 0 })
			end
			if hero and not quiet then
				game.PlaySound({ Name = tuning.SlowEndSfx, Id = hero.ObjectId })
				game.PlaySound({ Name = tuning.SlowEndSound, Id = hero.ObjectId })
			end
		end
	end

	local decalOn = nil

	local function setDecal(on)
		local hero = game.CurrentRun and game.CurrentRun.Hero
		local id = on and hero and hero.ObjectId or nil
		if id == decalOn then return end
		if decalOn then
			game.StopAnimation({ Name = tuning.ChannelDecal, DestinationId = decalOn })
		end
		decalOn = id
		if id then
			game.CreateAnimation({ Name = tuning.ChannelDecal, DestinationId = id })
			game.CreateAnimation({ Name = tuning.ChannelDecalFlash, DestinationId = id })
		end
	end

	while duo_running(duo_traits.WinterSolstice) do
		local now = game._worldTime
		local charging = duo_on('WinterSolstice') and winter_solstice_charging()
		setDecal(charging)

		if charging then
			channelled = channelled > 0 and channelled + (now - last) or 0.001
		else
			if fired and not gusting then winter_solstice_calm() end
			channelled = 0
			fired = false
			slowFired = false
		end
		last = now

		if channelled > 0 and not fired and (channelled >= channel_hold(variant.HoldSeconds) or omega_charged()) then
			fired = true
			squallSince = now
			chillStarted = false
			sinceSweep = sweepEvery
			if gusting then winter_solstice_ring() end
			if gusting then winter_solstice_gust_raise(now, now + tuning.GustLinger) end
		elseif fired and gusting then
			winter_solstice_gusts_hold(now, now + tuning.GustLinger)
		end

		local slowTriggered = fired and not slowFired and not slowing
			and channelled >= channel_hold(variant.SlowHoldSeconds)
			and (not slowEndedAt or game._worldTimeUnmodified - slowEndedAt >= variant.SlowMinGap)
		if not gusting and slowTriggered
			and (not tuning.SlowCooldownEnabled or game.CheckCooldownNoTrigger('SWuWinterSolstice', winter_solstice_recharge())) then
			if tuning.SlowCooldownEnabled then game.CheckCooldown('SWuWinterSolstice', winter_solstice_recharge()) end
			slowFired = true
			local real = game._worldTimeUnmodified
			slowUntil = real + variant.SolsticeDuration
			slowWarns = {}
			local warns = math.min(tuning.SlowEndWarnNum, math.ceil(variant.SolsticeDuration) - 1)
			for i = warns, 1, -1 do
				table.insert(slowWarns, slowUntil - i)
			end
			setSlow(true)
		end

		if slowing then
			local real = game._worldTimeUnmodified
			while slowWarns[1] and real >= slowWarns[1] do
				table.remove(slowWarns, 1)
				game.SpellSlowWarnPresentation()
			end
			if real >= slowUntil then setSlow(false) end
		end

		winter_solstice_gusts_expire(now)

		local sweeping = (gusting and #winterSolsticeGusts > 0) or (not gusting and fired)
		local chilling = not gusting and fired and now - squallSince >= tuning.SquallChillDelay
		if sweeping then
			sinceSweep = sinceSweep + poll
			if sinceSweep >= sweepEvery or (chilling and not chillStarted) then
				sinceSweep = 0
				chillStarted = chillStarted or chilling
				winter_solstice_sweep(gusting, chilling)
			end
		else
			sinceSweep = sweepEvery
		end

		game.wait(poll, loop)
	end

	setSlow(false, true)
	setDecal(false)
	winter_solstice_calm()
	winter_solstice_gusts_expire(nil)

	if not in_run() or not game.HeroHasTrait(duo_traits.WinterSolstice) then
		winter_solstice_restore_resistance()
	end
end
