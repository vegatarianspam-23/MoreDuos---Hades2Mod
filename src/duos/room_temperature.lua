---@meta _


local FREEZE_EFFECT = 'ChillEffect'


register_duo({
	key = 'RoomTemperature',

	StatLines = { 'SWuRoomTemperatureDamageStatDisplay' },
	ExtractValues = with_keyword_extracts({
		{ Key = 'SWuFrozenBonusDamage', ExtractAs = 'TooltipFrozenDamage' },
		{ Key = 'SWuThawSeconds', ExtractAs = 'TooltipThawSeconds' },
	}, 'Root'),

	ExtraFields = {
		SWuThawSeconds = mod.tuning.RoomTemperature.ThawSeconds,
		SWuFrozenBonusDamage = mod.tuning.RoomTemperature.FrozenBonusDamage,

		AddOutgoingDamageModifiers = {
			ValidProjectiles = fireball_projectiles(),
			ValidProjectilesLookup = fireball_lookup(),
			ValidActiveEffects = { FREEZE_EFFECT },
			ValidBaseDamageAddition = mod.tuning.RoomTemperature.FrozenBonusDamage,
			ReportValues = { ReportedFrozenDamage = 'ValidBaseDamageAddition' },
		},

		OnEnemyDamagedAction = {
			ValidProjectiles = fireball_projectiles(),
			ValidProjectilesLookup = fireball_lookup(),
			FunctionName = _PLUGIN.guid .. '.RoomTemperatureThaw',
		},
	},
})


---@diagnostic disable-next-line: unused-local
function mod.RoomTemperatureThaw(victim, _args, _triggerArgs)
	if not duo_on('RoomTemperature') then return end
	if not victim or not victim.ObjectId then return end
	if not victim.ActiveEffects or not victim.ActiveEffects[FREEZE_EFFECT] then return end

	local tuning = mod.tuning.RoomTemperature

	if tuning.ClearFreeze then
		game.ClearEffect({ Id = victim.ObjectId, Name = FREEZE_EFFECT })
		return
	end

	room_temperature_shorten(victim, tuning.ThawSeconds)
end


function room_temperature_shorten(victim, seconds)
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero or not seconds or seconds <= 0 then return end

	local remaining = game.GetEffectTimeRemaining({ Id = victim.ObjectId, EffectName = FREEZE_EFFECT }) or 0
	if remaining <= 0 then return end

	if remaining <= seconds then
		game.ClearEffect({ Id = victim.ObjectId, Name = FREEZE_EFFECT })
		return
	end

	local dataProperties = game.MergeAllTables({ game.EffectData[FREEZE_EFFECT].EffectData })
	dataProperties.Duration = remaining - seconds

	game.ApplyEffect({
		DestinationId = victim.ObjectId,
		Id = hero.ObjectId,
		EffectName = FREEZE_EFFECT,
		DataProperties = dataProperties,
	})
end
