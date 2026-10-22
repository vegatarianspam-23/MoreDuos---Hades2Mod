---@meta _


duo_meter = {}


DUO_METER_FREE = 'Free'

DUO_METER_UNSET = 'Unset'

DUO_METER_ALIASED = 'Aliased'


function duo_meter_add(key, source, cost)
	duo_meter[source] = { Key = key, Text = duo_meter_text_id(key), Cost = cost }
end


function duo_meter_text_id(key)
	return 'SWuMoreDuos' .. key .. '_DamageSource'
end


function duo_meter_apply()
	local screen = game.ScreenData and game.ScreenData.RunClear
	if not screen or not screen.DamageSourceMap then return end

	for source, entry in pairs(duo_meter) do
		if duo_on(entry.Key) then
			screen.DamageSourceMap[source] = entry.Text
		else
			screen.DamageSourceMap[source] = nil
		end
	end
end


function duo_meter_record(source, victim, amount)
	if type(amount) ~= 'number' or amount <= 0 then return end
	if not victim or (victim.MaxHealth or 0) <= 0 then return end

	local entry = duo_meter[source]
	if not entry or not duo_on(entry.Key) then return end

	local dealt = math.min(amount, victim.Health or 0)
	if dealt <= 0 then return end

	for _, state in ipairs({ game.CurrentRun, game.GameState }) do
		local record = state and state.DamageDealtByHeroRecord
		if record then
			record[source] = (record[source] or 0) + dealt
		end
	end
end


duo_meter_add('AirControl', mod.tuning.AirControl.GuardProjectile, DUO_METER_FREE)

duo_meter_add('LandMine', mod.tuning.LandMine.BlastProjectile, DUO_METER_ALIASED)

duo_meter_add('IntertwinedFate', mod.tuning.IntertwinedFate.RevengeSource, DUO_METER_FREE)
duo_meter_add('GoddessSpite', mod.tuning.GoddessSpite.ReflectSource, DUO_METER_FREE)

duo_meter_add('VolcanicCrown', mod.tuning.VolcanicCrown.EmberProjectile, DUO_METER_FREE)
duo_meter_add('VolcanicCrown', mod.tuning.VolcanicCrown.BlastProjectile, DUO_METER_ALIASED)
duo_meter_add('VolcanicCrown', mod.tuning.VolcanicCrown.FireballProjectile, DUO_METER_ALIASED)
