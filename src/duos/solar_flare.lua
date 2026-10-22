---@meta _


register_duo({
	key = 'SolarFlare',

	StatLines = { 'SWuSolarFlareStatDisplay', 'SWuSolarFlareScorchStatDisplay' },
	ExtractValues = with_keyword_extracts({
		{ Key = 'SWuScorchPerSecond', ExtractAs = 'TooltipScorchPerSecond' },
		{ Key = 'SWuScorchBonus', ExtractAs = 'TooltipScorchBonus', Format = 'Percent' },
	}, 'Burn'),

	ExtraFields = {
		SWuScorchPerSecond = mod.tuning.SolarFlare.PulseScorch / mod.tuning.SolarFlare.PulseInterval,
		SWuScorchBonus = mod.tuning.SolarFlare.ScorchBonus,

		SetupFunction = {
			Threaded = true,
			Name = _PLUGIN.guid .. '.SolarFlare',
			RepeatOnEncounterStart = true,
			Args = { Interval = mod.tuning.SolarFlare.PollInterval },
		},
	},
})


local RING = mod.tuning.SolarFlare.RingProjectile

local solarFlareRingId = nil

local solarFlareHeld = 0


local solarFlareCarry = {}

local solarFlareUntilPulse = 0

local solarFlarePulses = 0



local function solar_flare_raise_cap()
	if not mod.tuning.SolarFlare.LiftCeiling then return end

	local burn = game.EffectData and game.EffectData.BurnEffect
	if not burn then return end

	if mod.SolarFlareBaseCap == nil then
		mod.SolarFlareBaseCap = burn.MaxStacks
	end
	burn.MaxStacks = mod.tuning.SolarFlare.ScorchCap
end


local function solar_flare_restore_cap()
	local burn = game.EffectData and game.EffectData.BurnEffect
	if not burn or mod.SolarFlareBaseCap == nil then return end
	burn.MaxStacks = mod.SolarFlareBaseCap
	mod.SolarFlareBaseCap = nil
end


local function solar_flare_raise_ring()
	if solarFlareRingId then return false end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return false end

	solarFlareRingId = game.CreateProjectileFromUnit({
		Name = RING,
		Id = hero.ObjectId,
		DestinationId = hero.ObjectId,
		FireFromTarget = true,
		DataProperties = {
			AttachToOwner = true,
			DamageRadius = mod.tuning.SolarFlare.Radius,
		},
	})

	local tuning = mod.tuning.SolarFlare
	if solarFlareRingId and tuning.Expand and tuning.Expand > 1 then
		game.SetDamageRadiusMultiplier({
			Id = solarFlareRingId,
			Fraction = tuning.Expand,
			Duration = tuning.ExpandTime,
		})
	end

	solarFlareHeld = 0
	solar_flare_raise_cap()
	solarFlarePulses = 0
	solarFlareUntilPulse = channel_hold(tuning.PulseDelay)
	return true
end


local function solar_flare_drop_ring()
	solar_flare_restore_cap()

	if not solarFlareRingId then return end
	game.ExpireProjectiles({ ProjectileIds = { solarFlareRingId } })
	solarFlareRingId = nil
	solarFlareHeld = 0
	solarFlarePulses = 0
	solarFlareCarry = {}
end


local function solar_flare_expansion()
	local tuning = mod.tuning.SolarFlare
	if not tuning.Expand or tuning.Expand <= 1 then return 1 end
	if not tuning.ExpandTime or tuning.ExpandTime <= 0 then return tuning.Expand end

	local through = math.min(solarFlareHeld / tuning.ExpandTime, 1)
	return 1 + (tuning.Expand - 1) * through
end


local function solar_flare_radius()
	return mod.tuning.SolarFlare.Radius * solar_flare_expansion()
end


local function solar_flare_caught(radius)
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return {} end

	local caught = {}
	local nearby = game.GetClosestIds({
		Id = hero.ObjectId,
		DestinationName = 'EnemyTeam',
		IgnoreInvulnerable = true,
		StopsProjectiles = true,
		IgnoreHomingIneligible = true,
		IgnoreSelf = true,
		Distance = radius,
		ScaleY = mod.tuning.SolarFlare.CatchScaleY,
		PreciseCollision = true,
	})

	for _, id in pairs(nearby) do
		local unit = game.ActiveEnemies[id]
		if unit and not unit.IsDead and not duo_ignores(unit) then
			table.insert(caught, unit)
		end
	end
	return caught
end


local function solar_flare_pulse(caught)
	local hero = game.CurrentRun and game.CurrentRun.Hero
	local tuning = mod.tuning.SolarFlare

	if hero and tuning.PulseFx then
		local flare = { Name = tuning.PulseFx, DestinationId = hero.ObjectId }

		if tuning.PulseFxScalesByRadius then
			flare.ScaleRadius = solar_flare_radius()
		else
			flare.Scale = solar_flare_expansion()
		end

		game.CreateAnimation(flare)
	end

	local stacks = tuning.PulseScorch
	if solarFlarePulses == 0 and type(tuning.FirstPulseScorch) == 'number' then
		stacks = tuning.FirstPulseScorch
	end

	if type(stacks) ~= 'number' or stacks <= 0 then return end

	for _, unit in ipairs(caught) do
		game.ApplyBurn(unit, { EffectName = 'BurnEffect', NumStacks = stacks }, nil)
	end
end


local function solar_flare_stoke(interval, caught)
	if not mod.tuning.SolarFlare.Stoke then return end

	local burn = game.EffectData.BurnEffect
	if not burn or not burn.DamagePerSecond then return end

	local perSecond = burn.DamagePerSecond * game.GetTotalHeroTraitValue('BurnDamageMultiplier', { IsMultiplier = true })
	local perTick = perSecond * interval * mod.tuning.SolarFlare.StokeMultiplier
	if perTick <= 0 then return end

	for _, unit in ipairs(caught) do
		if unit.ActiveEffects and unit.ActiveEffects.BurnEffect then
			local carried = (solarFlareCarry[unit.ObjectId] or 0) + perTick
			local stacks = math.floor(carried)
			solarFlareCarry[unit.ObjectId] = carried - stacks

			if stacks > 0 then
				game.ApplyBurn(unit, { EffectName = 'BurnEffect', NumStacks = stacks }, nil)
			end
		end
	end
end


local solarFlareScorchCarry = 0

function solar_flare_scorch(stacks)
	if not duo_on('SolarFlare') then return stacks end
	if type(stacks) ~= 'number' or stacks <= 0 then return stacks end
	if not game.HeroHasTrait(duo_traits.SolarFlare) then return stacks end

	local bonus = mod.tuning.SolarFlare.ScorchBonus
	if type(bonus) ~= 'number' or bonus <= 0 then return stacks end

	local raised = stacks * (1 + bonus) + solarFlareScorchCarry
	local whole = math.floor(raised)
	solarFlareScorchCarry = raised - whole

	return whole
end


function mod.SolarFlare(_hero, args)
	local interval = (args and args.Interval) or mod.tuning.SolarFlare.PollInterval
	local loop = duo_loop_claim(duo_traits.SolarFlare)
	if not loop then return end

	local last = game._worldTime

	while duo_running(duo_traits.SolarFlare) do
		local now = game._worldTime
		local elapsed = (now - last) * game._elapsedTimeMultiplier
		last = now

		if duo_on('SolarFlare') and channelling_omega() then
			if solar_flare_raise_ring() then elapsed = 0 end
			solarFlareHeld = solarFlareHeld + elapsed

			local caught = solar_flare_caught(solar_flare_radius())

			solarFlareUntilPulse = solarFlareUntilPulse - elapsed
			if solarFlareUntilPulse <= 0 or (solarFlarePulses == 0 and omega_charged()) then
				solarFlareUntilPulse = math.min(solarFlareUntilPulse, 0) + channel_hold(mod.tuning.SolarFlare.PulseInterval)
				solar_flare_pulse(caught)
				solarFlarePulses = solarFlarePulses + 1
			end

			solar_flare_stoke(elapsed, caught)
		else
			solar_flare_drop_ring()
		end

		game.wait(interval, loop)
	end

	solar_flare_drop_ring()
end
