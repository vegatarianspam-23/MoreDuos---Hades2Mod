---@meta _


local NASTY_COMEBACK_HITCH = 'DamageShareEffect'
local NASTY_COMEBACK_SOURCE = mod.tuning.NastyComeback.ReflectSource


once('NastyComebackSource', function()
	local hitch = game.EffectData[NASTY_COMEBACK_HITCH]
	if hitch and not game.EffectData[NASTY_COMEBACK_SOURCE] then
		game.EffectData[NASTY_COMEBACK_SOURCE] = game.DeepCopyTable(hitch)
	end
	if game.EffectData[NASTY_COMEBACK_SOURCE] then
		game.EffectData[NASTY_COMEBACK_SOURCE].Name = NASTY_COMEBACK_SOURCE
	end
end)


register_duo({
	key = 'NastyComeback',

	StatLines = { 'SWuNastyComebackStatDisplay' },
	ExtractValues = with_keyword_extracts({
		{ Key = 'SWuReflectMultiplier', ExtractAs = 'TooltipReflectMultiplier', Format = 'Percent', HideSigns = true },
	}, 'Link'),

	ExtraFields = {
		SWuReflectMultiplier = mod.tuning.NastyComeback.ReflectMultiplier,

		OnSelfDamagedFunction = { Name = _PLUGIN.guid .. '.NastyComebackReflect' },
	},
})


local function nasty_comeback_damage(victim, args)
	if not victim or not victim.ObjectId or game.IsInvulnerable({ Id = victim.ObjectId }) then return end
	if victim.InvulnerableFlags and not game.IsEmpty(victim.InvulnerableFlags) then return end

	args.EffectName = game.EffectData[NASTY_COMEBACK_SOURCE] and NASTY_COMEBACK_SOURCE or NASTY_COMEBACK_HITCH
	args.AttackerName = '_PlayerUnit'
	game.Damage(victim, args)
end


local function nasty_comeback_share(hero, foe, amount)
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

			nasty_comeback_damage(enemy, {
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


local function nasty_comeback_strike(hero, foe, damage)
	local tuning = mod.tuning.NastyComeback

	game.wait(tuning.ShareDelay, game.RoomThreadName)
	if foe.IsDead then return end

	game.CreateAnimationsBetween({
		Animation = 'HeraRope',
		DestinationId = foe.ObjectId,
		Id = hero.ObjectId,
		Stretch = true,
		UseZLocation = false,
	})

	nasty_comeback_share(hero, foe, damage)
	if foe.IsDead then return end

	nasty_comeback_damage(foe, {
		AttackerTable = hero,
		AttackerId = hero.ObjectId,
		DamageAmount = damage,
		PureDamage = true,
	})
end


local nastyComebackBypassed = false


---@diagnostic disable-next-line: unused-local
function mod.NastyComebackReflect(attacker, _args, triggerArgs)
	if not duo_on('NastyComeback') then return end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end

	local foe = duo_live_foe(attacker)
	if not foe or foe.IsDead or is_allied_summon(foe) then return end

	local tuning = mod.tuning.NastyComeback
	local affront = triggerArgs and triggerArgs.ManuallyTriggered
	local taken = triggerArgs and triggerArgs.DamageAmount
	if affront then
		taken = tuning.HeinousAffrontDamage
	end
	if type(taken) ~= 'number' or taken <= 0 then return end

	for _, unit in pairs(game.ShallowCopyTable(game.ActiveEnemies or {})) do
		if duo_live_foe(unit) and not is_allied_summon(unit) then
			duo_hitch(unit)
		end
	end

	if affront and not tuning.HeinousAffront then return end

	local shared = math.min(taken * tuning.ReflectMultiplier, tuning.ReflectCap)
	if nastyComebackBypassed then shared = tuning.BypassReflect end
	if shared <= 0 then return end

	game.thread(nasty_comeback_strike, hero, foe, shared)
end


function nasty_comeback_bypassed(victim, attacker, args)
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero or victim ~= hero or hero.IsDead or not args then return end
	if not duo_on('NastyComeback') or not game.HeroHasTrait(duo_traits.NastyComeback) then return end

	local projectile = args.SourceProjectile and game.ProjectileData[args.SourceProjectile]
	if not projectile or not projectile.BypassDamagingRetaliate or projectile.BypassRetaliate then return end

	nastyComebackBypassed = true
	local ok, err = pcall(mod.NastyComebackReflect, attacker, nil, args)
	nastyComebackBypassed = false
	if not ok then error(err, 0) end
end
