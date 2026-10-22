---@meta _


local GODDESS_SPITE_HITCH = 'DamageShareEffect'


register_duo({
	key = 'GoddessSpite',

	StatLines = { 'SWuGoddessSpiteStatDisplay' },
	ExtractValues = with_keyword_extracts({
		{ Key = 'SWuReflectMultiplier', ExtractAs = 'TooltipReflectMultiplier' },
	}, 'Link'),

	ExtraFields = {
		SWuReflectMultiplier = mod.tuning.GoddessSpite.ReflectMultiplier,

		OnSelfDamagedFunction = { Name = _PLUGIN.guid .. '.GoddessSpiteReflect' },
	},
})


---@diagnostic disable-next-line: unused-local
function mod.GoddessSpiteReflect(attacker, _args, triggerArgs)
	if not duo_on('GoddessSpite') then return end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end

	local foe = duo_live_foe(attacker)
	if not foe or foe.IsDead or is_allied_summon(foe) then return end

	local taken = heinous_affront_damage(attacker, triggerArgs)
	if type(taken) ~= 'number' or taken <= 0 then return end

	duo_hitch(foe)

	local tuning = mod.tuning.GoddessSpite
	local damage = math.min(taken * tuning.ReflectMultiplier, tuning.ReflectCap)
	if damage <= 0 then return end

	local struck = {}
	local function strike(unit)
		if not unit or not unit.ObjectId or unit.IsDead or unit == hero then return end
		if struck[unit.ObjectId] or is_allied_summon(unit) then return end
		struck[unit.ObjectId] = true

		game.CreateAnimationsBetween({
			Animation = 'HeraRope',
			DestinationId = unit.ObjectId,
			Id = hero.ObjectId,
			Stretch = true,
			UseZLocation = false,
		})

		duo_meter_record(tuning.ReflectSource, unit, damage)

		game.Damage(unit, {
			AttackerTable = hero,
			AttackerId = hero.ObjectId,
			EffectName = GODDESS_SPITE_HITCH,
			DamageAmount = damage,
			PureDamage = true,
		})
	end

	strike(foe)
	for _, unit in pairs(game.ShallowCopyTable(game.ActiveEnemies or {})) do
		if unit.ActiveEffects and unit.ActiveEffects[GODDESS_SPITE_HITCH] then
			strike(unit)
		end
	end
end
