---@meta _


DISTRESS_CALL_TRAIT = gods.GetInternalBoonName('DistressCallBoon')

local DISTRESS_CALL_LEGENDARY_TEMPLATE = 'TimeStopLastStandBoon'


function distress_call_on()
	return config.enabled ~= false and config.Experimental.DistressCall == true
end


function distress_call_held()
	if not distress_call_on() or not in_run() then return false end
	return game.HeroHasTrait(DISTRESS_CALL_TRAIT) == true
end


mod.DistressCallHeld = mod.DistressCallHeld or {}

local function distress_call_hold(id, tbl, field, value)
	if not tbl then return end
	if mod.DistressCallHeld[id] == nil then
		mod.DistressCallHeld[id] = { Table = tbl, Field = field, Was = tbl[field] }
	end
	tbl[field] = value
end

local function distress_call_release(id)
	local held = mod.DistressCallHeld[id]
	if not held then return end
	held.Table[held.Field] = held.Was
	mod.DistressCallHeld[id] = nil
end


local function distress_call_room_encounter_name()
	local room = game.CurrentRun and game.CurrentRun.CurrentRoom
	local encounter = room and room.Encounter
	return encounter and encounter.Name
end


function distress_call_present(unitName)
	local ids = game.GetIdsByType({ Name = unitName })
	return ids ~= nil and next(ids) ~= nil
end


function distress_call_available(ally)
	if not ally.Requires then return true end
	if not (config.Experimental and config.Experimental.ZagreusJourney == true) then return false end

	local ok, present = pcall(function() return rom.mods[ally.Requires] ~= nil end)
	return ok and present
end


function distress_call_barred(ally)
	local name = distress_call_room_encounter_name()
	if type(name) ~= 'string' then return false end

	for _, match in ipairs(ally.BlockedIn or {}) do
		if name:find(match, 1, true) then return true end
	end
	return false
end


function distress_call_expected(ally)
	local name = distress_call_room_encounter_name()
	if type(name) ~= 'string' or not ally.Key then return false end
	return name:find(ally.Key, 1, true) ~= nil
end


function distress_call_boss_unit()
	for _, enemy in pairs(game.ActiveEnemies or {}) do
		if enemy and enemy.IsBoss and not enemy.IsDead then return enemy end
	end
	return nil
end


function distress_call_has_boss()
	return distress_call_boss_unit() ~= nil
end


function distress_call_boss_target()
	local hero = game.CurrentRun and game.CurrentRun.Hero
	local best, bestDistance = nil, nil

	for _, enemy in pairs(game.ActiveEnemies or {}) do
		if enemy and enemy.IsBoss and not enemy.IsDead and enemy.ObjectId
			and not game.IsInvulnerable({ Id = enemy.ObjectId })
		then
			local distance = hero
				and game.GetDistance({ Id = hero.ObjectId, DestinationId = enemy.ObjectId })

			if best == nil or (distance ~= nil and bestDistance ~= nil and distance < bestDistance) then
				best, bestDistance = enemy, distance
			end
		end
	end

	return best
end


function distress_call_in_boss()
	local room = game.CurrentRun and game.CurrentRun.CurrentRoom
	local encounter = room and room.Encounter

	if not encounter or encounter.EncounterType ~= 'Boss' then return false end
	if encounter.SkipBossTraits then return false end

	return distress_call_has_boss()
end


function distress_call_blocked(ally)
	if not distress_call_available(ally) then return true end
	if distress_call_present(ally.Unit) then return true end
	if distress_call_expected(ally) then return true end
	if distress_call_barred(ally) then return true end
	if ally.NoBoss and distress_call_has_boss() then return true end
	if ally.BossOnly and not distress_call_in_boss() then return true end
	if not ally.BlockedBy then return false end

	for _, enemy in pairs(game.ActiveEnemies or {}) do
		if enemy and not enemy.IsDead and enemy.Name == ally.BlockedBy then return true end
	end
	return false
end


function distress_call_pick()
	local available = {}
	local total = 0

	for _, ally in ipairs(mod.tuning.DistressCall.Allies) do
		local weight = ally.Weight or 1
		if weight > 0 and not distress_call_blocked(ally) then
			total = total + weight
			table.insert(available, { Ally = ally, UpTo = total })
		end
	end

	if total <= 0 then return nil end

	local roll = math.random() * total
	for _, entry in ipairs(available) do
		if roll <= entry.UpTo then return entry.Ally end
	end
	return available[#available].Ally
end


function distress_call_aim(data, boss)
	data.DefaultAIData.UseTargetId = boss and boss.ObjectId or nil
	data.DefaultAIData.TargetTypes = boss and { boss.Name } or nil
end


function distress_call_track(data, generation)
	game.wait(0.5, game.RoomThreadName)

	while mod.DistressCallGeneration == generation and mod.DistressCallAlly ~= nil do
		distress_call_aim(data, distress_call_boss_target())
		game.wait(0.5, game.RoomThreadName)
	end
end


function distress_call_focus(data, generation)
	local tuning = mod.tuning.DistressCall

	data.DefaultAIData.TargetMaxDistance = tuning.TargetReach

	if not tuning.FocusBoss then return end

	local boss = distress_call_boss_unit()
	if not boss or not boss.Name then return end

	distress_call_aim(data, distress_call_boss_target())
	game.thread(distress_call_track, data, generation)

	local reach = (game.EnemyData[boss.Name] or {}).CatFamiliarAttackDistance

	local names = game.ShallowCopyTable(data.WeaponOptions or {})
	if data.WeaponName then table.insert(names, data.WeaponName) end

	for _, weaponName in ipairs(names) do
		local weapon = game.WeaponData[weaponName]

		if weapon and weapon.AIData then
			if reach and (weapon.AIData.AttackDistance or 0) < reach then
				distress_call_hold(weaponName .. '/Reach', weapon.AIData, 'AttackDistance', reach)
			end

			distress_call_hold(weaponName .. '/Projectile', weapon.AIData, 'ProjectileDataOverrides',
				tuning.BossProjectile)
		end
	end
end


function distress_call_hasten(ally)
	for weaponName, overrides in pairs(ally.Weapons or {}) do
		local weapon = game.WeaponData[weaponName]

		if weapon and weapon.AIData then
			for field, value in pairs(overrides) do
				if field == 'Requirements' then
					weapon.Requirements = weapon.Requirements or {}
					for key, requirement in pairs(value) do
						distress_call_hold(weaponName .. '/Req/' .. key, weapon.Requirements, key, requirement)
					end
				else
					distress_call_hold(weaponName .. '/' .. field, weapon.AIData, field, value)
				end
			end
		end
	end
end


function distress_call_restore()
	for id in pairs(mod.DistressCallHeld) do
		distress_call_release(id)
	end
end


function distress_call_spawn_point(ally, hero)
	local room = game.CurrentRun and game.CurrentRun.CurrentRoom
	local roomData = room and game.RoomData[room.Name]

	if ally.SpawnAtEntrance and roomData and roomData[ally.SpawnAtEntrance] then
		local ids = game.GetIdsByType({ Name = 'HeroStart' })
		if ids and next(ids) then return game.GetRandomValue(ids), false end
	end

	for _, name in ipairs(ally.SpawnAt or {}) do
		local ids = game.GetIds({ Name = name })
		if not ids or not next(ids) then ids = game.GetIdsByType({ Name = name }) end

		if ids and next(ids) then
			return game.GetRandomValue(ids), false
		end
	end

	return game.SpawnObstacle({ Name = 'BlankObstacle', DestinationId = hero.ObjectId }), true
end


local DISTRESS_CALL_VOICE_FIELDS = {
	'EncounterStartVoiceLines', 'EncounterEndVoiceLines', 'ExitVoiceLines',
	'KillingEnemyVoiceLines', 'SpawnVoiceLines',
}


function distress_call_load(ally)
	local voice = ally.Voice
	if voice and voice.Bank then
		game.LoadVoiceBanks(voice.Bank, nil, true)
	end

	if ally.Packages then
		game.LoadPackages({ Names = ally.Packages, IgnoreAssert = true })
	end
end


function distress_call_voice(ally, data)
	local voice = ally.Voice
	local source = voice and voice.From and game.EnemyData[voice.From]
	if not source then return end

	for _, field in ipairs(DISTRESS_CALL_VOICE_FIELDS) do
		if data[field] == nil then data[field] = source[field] end
	end

	data.SpeakerName = data.SpeakerName or source.SpeakerName
end


function distress_call_grudge(ally)
	local grudge = ally.Grudge
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end

	distress_call_load(ally)

	local damageData = {
		Delay = grudge.Delay,
		DamageSourceName = grudge.DamageSourceName,
		PresentationFunctionName = grudge.Presentation,
		Text = grudge.Text,
		VoiceLines = game.GlobalVoiceLines and game.GlobalVoiceLines[grudge.VoiceLines],
	}

	for _, unit in pairs(game.ShallowCopyTable(game.ActiveEnemies or {})) do
		if unit.IsBoss and not unit.IsDead and unit.MaxHealth then
			game.thread(game.PreDamageBoss, unit, unit.MaxHealth * grudge.Fraction, damageData)
		end
	end

	distress_call_darken(grudge)
end


function distress_call_darken(grudge)
	local hero = game.CurrentRun and game.CurrentRun.Hero
	local effect = game.EffectData[grudge.Effect]
	if not hero or not effect then return end

	local dataProperties = game.DeepCopyTable(effect.EffectData)
	dataProperties.Duration = mod.tuning.DistressCall.Duration

	game.ApplyEffect({
		DestinationId = hero.ObjectId,
		Id = hero.ObjectId,
		EffectName = grudge.Effect,
		DataProperties = dataProperties,
	})

	game.thread(game.HadesInvisibility)

	distress_call_set_dark(grudge.Multiplier, grudge.Effect)
end


function distress_call_set_dark(multiplier, effect)
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end
	hero.OutgoingDamageModifiers = hero.OutgoingDamageModifiers or {}

	local entry
	for _, modifier in ipairs(hero.OutgoingDamageModifiers) do
		if modifier.SWuDistressDark then
			entry = modifier
			break
		end
	end

	if not entry then
		if multiplier == 1 then return end
		entry = {
			SWuDistressDark = true,
			RequiredEffects = { effect },
			RequiredSelfEffectsMultiplier = 1,
		}
		game.AddOutgoingDamageModifier(hero, entry)
	end

	entry.RequiredSelfEffectsMultiplier = multiplier
end


function distress_call_revel(ally, generation)
	local revel = ally.Revel
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero or mod.DistressCallRevel then return end

	distress_call_load(ally)

	mod.DistressCallRevelSpec = revel
	mod.DistressCallRevel = generation

	distress_call_ball(revel)

	for _ = 1, revel.Drinks or 0 do
		distress_call_drink(revel, hero)
	end

	distress_call_anchors(revel, hero)

	game.thread(game.PlayVoiceLines, game.GlobalVoiceLines.SkippedEncounterVoiceLines)
	game.thread(distress_call_fog, revel, generation)
	game.thread(distress_call_hangover, revel, generation)
end


function distress_call_ball(revel)
	local hero = game.CurrentRun.Hero

	game.CreateGroup({ Name = 'DiscoBall' })
	game.InsertGroupInFront({ Name = 'DiscoBall', DestinationName = 'Combat_UI' })
	game.CreateGroup({ Name = 'DiscoBallAdditive', BlendMode = 'Additive' })
	game.InsertGroupInFront({ Name = 'DiscoBallAdditive', DestinationName = 'DiscoBall' })

	local ball = game.SpawnObstacle({
		Name = revel.Ball, DestinationId = hero.ObjectId, OffsetY = revel.Height, Group = 'DiscoBall',
	})
	local chain = game.SpawnObstacle({
		Name = revel.Chain, DestinationId = hero.ObjectId, OffsetY = revel.Height, Group = 'DiscoBall',
	})
	if not ball or not chain then return end

	game.SetScale({ Id = chain, Fraction = revel.ChainScale })
	game.Attach({ Id = chain, DestinationId = ball, OffsetY = revel.ChainOffset })

	local drop = revel.Drop
	if game.ConfigOptionCache and game.ConfigOptionCache.UseZoomFractionAlt then drop = revel.DropAlt end
	game.Attach({ Id = ball, DestinationId = hero.ObjectId, OffsetY = drop })

	mod.DistressCallBall = { ball, chain }

	game.SetAlpha({ Ids = { ball, chain }, Fraction = 0 })
	game.CreateAnimation({ Name = 'ProjectileTempFlare', DestinationId = ball, Scale = 2.0, OffsetY = 200 })
	game.SetAlpha({ Ids = { ball, chain }, Fraction = 1.0, Duration = 0.2 })

	game.PlaySound({ Name = revel.Sound })

	if revel.Music and not mod.DistressCallMusic then
		mod.DistressCallMusic = game.PlaySound({ Name = revel.Music })
	end
end


function distress_call_anchors(revel, hero)
	local anchors = {}
	local placed = {}

	local pool = {}
	for _, id in pairs(game.GetIds({ Name = 'SpawnPoints' }) or {}) do
		table.insert(pool, id)
	end

	while #placed < revel.Clouds and not game.IsEmpty(pool) do
		local point = game.RemoveRandomValue(pool)
		local clear = true

		for _, taken in ipairs(placed) do
			if game.IsWithinDistance({
				Id = point, DestinationId = taken, Distance = revel.MinGap, ScaleY = revel.SpreadY,
			}) then
				clear = false
				break
			end
		end

		if clear then
			table.insert(placed, point)

			local anchor = game.SpawnObstacle({
				Name = 'InvisibleTarget', DestinationId = point, Group = 'Scripting',
			})
			if anchor then table.insert(anchors, anchor) end
		end
	end

	for index = #anchors + 1, revel.Clouds do
		local ratio = math.sqrt(index / revel.Clouds)
		local offset = game.CalcOffset(math.rad(index * revel.Drift), revel.Spread * ratio)

		local anchor = game.SpawnObstacle({
			Name = 'InvisibleTarget',
			DestinationId = hero.ObjectId,
			Group = 'Scripting',
			OffsetX = offset.X,
			OffsetY = offset.Y * revel.SpreadY,
		})

		if anchor then table.insert(anchors, anchor) end
	end

	mod.DistressCallAnchors = anchors
end


function distress_call_fog(revel, generation)
	local pass = 0

	while mod.DistressCallRevel == generation do
		local hero = game.CurrentRun and game.CurrentRun.Hero
		if not hero or hero.IsDead then return end

		for index, anchor in ipairs(mod.DistressCallAnchors or {}) do
			game.CreateProjectileFromUnit({
				Name = revel.Fog,
				Id = hero.ObjectId,
				DestinationId = anchor,
				FireFromTarget = true,
				Angle = index * revel.Drift + (pass % 2) * 180,
			})
		end

		pass = pass + 1
		game.wait(revel.Refresh, game.RoomThreadName)
	end
end


function distress_call_hangover(revel, generation)
	local properties = game.ShallowCopyTable(game.EffectData[revel.Hangover].DataProperties)
	properties.Amount = revel.Damage

	while mod.DistressCallRevel == generation do
		local hero = game.CurrentRun and game.CurrentRun.Hero
		if not hero or hero.IsDead then return end

		for _, anchor in ipairs(mod.DistressCallAnchors or {}) do
			local ids = game.GetClosestIds({
				Id = anchor,
				DestinationName = 'EnemyTeam',
				Distance = revel.Radius,
				ScaleY = 0.6,
			})

			for _, id in pairs(ids or {}) do
				local enemy = game.ActiveEnemies[id]

				if enemy and not enemy.IsDead and not enemy.SkipModifiers
					and enemy.TriggersOnHitEffects and not is_allied_summon(enemy) then

					game.ApplyEffect({
						DestinationId = enemy.ObjectId,
						Id = hero.ObjectId,
						EffectName = revel.Hangover,
						DataProperties = properties,
					})
				end
			end
		end

		game.wait(revel.Sweep, game.RoomThreadName)
	end
end


function distress_call_drink(revel, hero)
	game.SessionMapState.OccupiedSpawnPoints = game.SessionMapState.OccupiedSpawnPoints or {}
	local taken = game.SessionMapState.OccupiedSpawnPoints

	local far, near = {}, {}

	for _, point in pairs(game.GetIds({ Name = 'SpawnPoints' }) or {}) do
		if not taken[point] then
			if game.IsWithinDistance({
				Id = hero.ObjectId, DestinationId = point, Distance = revel.DrinkMin, ScaleY = 0.6,
			}) then
				table.insert(near, point)
			else
				table.insert(far, point)
			end
		end
	end

	local point = game.GetRandomValue(far) or game.GetRandomValue(near)
	if not point then return end

	local drop = game.SpawnObstacle({ Name = revel.Drink, DestinationId = point, Group = 'Standing' })
	if not drop then return end

	taken[point] = drop
	game.CreateConsumableItem(drop, revel.Drink, 0)

	game.PlaySound({ Name = revel.DrinkSound, Id = drop, ManagerCap = 46 })
	game.CreateAnimation({ Name = revel.DrinkVfx, DestinationId = drop })
end


function distress_call_revel_end()
	local ids = mod.DistressCallBall
	local anchors = mod.DistressCallAnchors
	local revel = mod.DistressCallRevelSpec

	mod.DistressCallRevel = nil
	mod.DistressCallRevelSpec = nil
	mod.DistressCallBall = nil
	mod.DistressCallAnchors = nil

	if anchors then game.Destroy({ Ids = anchors }) end

	if mod.DistressCallMusic then
		game.StopSound({ Id = mod.DistressCallMusic, Duration = 0.3 })
		mod.DistressCallMusic = nil
	end

	if not ids then return end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if revel and revel.EndSound then game.PlaySound({ Name = revel.EndSound }) end
	if revel and revel.Reflections then
		game.StopAnimation({ Name = revel.Reflections, DestinationId = ids[1] })
	end

	if hero then game.Unattach({ Id = ids[1], DestinationId = hero.ObjectId }) end
	game.Move({ Ids = ids, Angle = 90, Speed = 500, EaseIn = 0.99, EaseOut = 1.0 })
	game.SetAlpha({ Ids = ids, Fraction = 0, Duration = 0.2 })
	game.thread(game.DestroyOnDelay, ids, 1)
end


function distress_call_smite(ally, source)
	local smite = ally.Smite
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end

	distress_call_load(ally)

	local athena = game.DeepCopyTable(source)
	local spawnPointId = game.SelectSpawnPoint(game.CurrentRun.CurrentRoom, athena, {
		SpawnNearId = hero.ObjectId, SpawnRadius = 700, SpawnRadiusMin = 400,
	}) or hero.ObjectId

	athena.ObjectId = game.SpawnUnit({
		Name = ally.Unit, Group = 'Standing', DestinationId = spawnPointId,
	})
	if not athena.ObjectId then return end

	distress_call_voice(ally, athena)

	athena.RequiredRoomInteraction = nil
	athena.CanReceiveGift = false
	athena.OnUsedFunctionName = nil
	athena.UseActivatePresentation = false

	game.SetupUnit(athena, game.CurrentRun, { IgnoreAI = true, IgnorePackages = true })
	game.UseableOff({ Id = athena.ObjectId })

	game.SetAlpha({ Id = athena.ObjectId, Fraction = 0, Duration = 0 })
	game.AdjustZLocation({
		Id = athena.ObjectId,
		Distance = smite.Height - game.GetZLocation({ Id = athena.ObjectId }),
	})
	game.IgnoreGravity({ Id = athena.ObjectId })

	game.thread(game.PlayVoiceLines, athena.EncounterStartVoiceLines, nil, athena)

	game.AdjustColorGrading({ Name = 'Gold', Duration = 2.5 })
	game.BloomRequestStart({
		SourceName = 'SWuDistressAthena', BloomType = 'AthenaDivineInterventionBloom', Duration = 2.5,
	})
	game.AdjustRadialBlurDistance({ Fraction = 0.5, Duration = 2.0 })
	game.AdjustRadialBlurStrength({ Fraction = 1.5, Duration = 2.0 })

	game.wait(smite.Descend, game.RoomThreadName)

	game.AngleTowardTarget({ Id = athena.ObjectId, DestinationId = hero.ObjectId })
	game.SetAnimation({ Name = smite.Entrance, DestinationId = athena.ObjectId })
	game.SetAlpha({ Id = athena.ObjectId, Fraction = 1.0, Duration = 0.05 })
	game.AdjustZLocation({
		Id = athena.ObjectId,
		Distance = 0 - game.GetZLocation({ Id = athena.ObjectId }),
		Duration = 0.1,
	})

	game.wait(0.1, game.RoomThreadName)

	game.CreateProjectileFromUnit({ Name = smite.Nova, Id = athena.ObjectId })
	game.ShakeScreen({ Speed = 500, Distance = 4, FalloffSpeed = 1000, Duration = 0.75 })

	game.AdjustRadialBlurDistance({ Fraction = 0, Duration = 0.25 })
	game.AdjustRadialBlurStrength({ Fraction = 0, Duration = 0.25 })
	game.BloomRequestEnd({ SourceName = 'SWuDistressAthena', Duration = 0.25 })
	game.AdjustColorGrading({ Name = 'Off', Duration = 0.5 })

	game.ObeyGravity({ Id = athena.ObjectId })

	distress_call_smite_field(smite)

	game.ExpireProjectiles({
		ExcludeNames = game.WeaponSets.ExpireProjectileExcludeProjectileNames,
	})
	game.PlaySound({ Name = smite.Sound, Id = athena.ObjectId })
	game.thread(game.PlayVoiceLines, athena.EncounterEndVoiceLines, nil, athena)

	game.wait(smite.Linger, game.RoomThreadName)

	game.SetAnimation({ Name = smite.Departure, DestinationId = athena.ObjectId })
	game.wait(0.45, game.RoomThreadName)

	game.AdjustZLocation({ Id = athena.ObjectId, Distance = smite.Height, Duration = 0.1 })
	game.IgnoreGravity({ Id = athena.ObjectId })

	game.wait(0.1, game.RoomThreadName)
	game.SetAlpha({ Id = athena.ObjectId, Fraction = 0, Duration = 0.05 })

	game.wait(0.2, game.RoomThreadName)
	game.Destroy({ Id = athena.ObjectId })
end


function distress_call_smite_field(smite)
	for _, enemy in pairs(game.ShallowCopyTable(game.RequiredKillEnemies or {})) do
		distress_call_strike(enemy, smite)
	end

	for _, enemy in pairs(game.ShallowCopyTable(game.ActiveEnemies or {})) do
		if enemy.IsAggroed then
			distress_call_strike(enemy, smite)
		end
	end
end


function distress_call_strike(enemy, smite)
	if not enemy or enemy.IsDead or is_allied_summon(enemy) then return end

	game.thread(game.DisplayDamageText, enemy, {
		DamageAmount = smite.Damage, SourceProjectile = 'Athena', IsCrit = true,
	})
	game.thread(game.Kill, enemy)
	game.waitUnmodified(smite.Interval)
end


function distress_call_conceal(summoned, ally)
	if not ally.Invisible or not summoned.ObjectId then return end

	game.SetAlpha({ Id = summoned.ObjectId, Fraction = 0, Duration = 0 })

	if type(ally.Invisible) == 'string' then
		game.SetAnimation({ DestinationId = summoned.ObjectId, Name = ally.Invisible })
		game.SetThingProperty({
			Property = 'Graphic', Value = ally.Invisible, DestinationId = summoned.ObjectId,
		})
	end
end


function distress_call_fighter(ally, source, generation)
	local hero = game.CurrentRun.Hero
	local room = game.CurrentRun.CurrentRoom
	local tuning = mod.tuning.DistressCall

	distress_call_load(ally)

	local data = game.DeepCopyTable(source)
	local variant = ally.Variant and game.NPCVariantData and game.NPCVariantData[ally.Variant]
	if variant then game.OverwriteSelf(data, variant) end

	data.Name = ally.Unit
	data.MaxHealth = data.MaxHealth or tuning.NominalHealth
	data.DefaultAIData = data.DefaultAIData or {}
	data.Groups = data.Groups or {}
	data.OutgoingDamageModifiers = data.OutgoingDamageModifiers or {}
	data.IncomingDamageModifiers = {
		{ Name = 'Innate', PlayerMultiplier = 0.0, NonPlayerMultiplier = 0.0 },
	}

	data.RequiredRoomInteraction = nil
	data.SkipAISetupOnActivate = nil
	data.CanReceiveGift = false
	data.OnUsedFunctionName = nil
	data.PostCombatAI = nil

	if ally.WakeDelay ~= nil then
		data.AIWakeDelay = ally.WakeDelay
	end

	distress_call_voice(ally, data)
	distress_call_hasten(ally)
	distress_call_focus(data, generation)

	local anchor, temporary = distress_call_spawn_point(ally, hero)
	if not anchor then return false end

	local summoned = data
	summoned.ObjectId = game.SpawnUnit({ Name = ally.Unit, Group = 'Standing', DestinationId = anchor })
	if temporary then game.DestroyOnDelay({ anchor }, 0.1) end
	if not summoned.ObjectId then return false end

	distress_call_conceal(summoned, ally)
	summoned.UseActivatePresentation = false

	game.SetupUnit(summoned, game.CurrentRun, { IgnoreAI = true, IgnorePackages = true })
	game.UseableOff({ Id = summoned.ObjectId })
	game.thread(game.SetupAI, summoned)

	summoned.Charmed = false
	summoned.RequiredRoomInteraction = nil
	summoned.SWuCycleStart = #(summoned.WeaponHistory or {})

	if ally.Greet and summoned.EncounterStartVoiceLines then
		game.thread(game.PlayVoiceLines, summoned.EncounterStartVoiceLines, nil, summoned)
	end

	distress_call_conceal(summoned, ally)

	if ally.Haste then
		game.SetThingProperty({
			Property = 'ElapsedTimeMultiplier',
			Value = ally.Haste,
			ValueChangeType = 'Multiply',
			DataValue = false,
			DestinationId = summoned.ObjectId,
		})
	end

	mod.DistressCallAlly = summoned
	mod.DistressCallExit = ally.Exit

	if room.DestroyAssistUnitOnEncounterEndId == nil then
		room.DestroyAssistUnitOnEncounterEndId = summoned.ObjectId
		room.AssistUnitName = ally.Unit
	end

	return true
end


function distress_call_busy(ally)
	local key = ally.SurroundAIKey or ally.Name
	local attacking = game.SurroundEnemiesAttacking and game.SurroundEnemiesAttacking[key]
	return (attacking and attacking[ally.ObjectId]) == true
end


function distress_call_finish(ally, exit)
	local target = (ally.SWuCycleStart or 0) + (exit.Cycles or 0)
	local limit = exit.Grace or exit.Finish or 0
	local waited = 0

	while waited < limit and not ally.IsDead do
		local fired = #(ally.WeaponHistory or {})
		if fired >= target and not distress_call_busy(ally) then return end

		game.wait(0.1, game.RoomThreadName)
		waited = waited + 0.1
	end
end


function distress_call_depart(ally, exit)
	if exit.Finish or exit.Cycles then
		distress_call_finish(ally, exit)
	end

	if exit.Settle then
		game.wait(exit.Settle, game.RoomThreadName)
	end

	ally.Exiting = true

	game.killTaggedThreads(ally.AIThreadName)
	game.killWaitUntilThreads(ally.AINotifyName)
	game.UseableOff({ Id = ally.ObjectId })

	game.SetUnitProperty({ DestinationId = ally.ObjectId, Property = 'CollideWithUnits', Value = false })
	game.SetThingProperty({ DestinationId = ally.ObjectId, Property = 'StopsProjectiles', Value = false })

	if exit.Voice and ally.ExitVoiceLines then
		game.thread(game.PlayVoiceLines, ally.ExitVoiceLines, nil, ally, { IgnoreMute = true })
	end

	if exit.Animation then
		game.SetAnimation({ Name = exit.Animation, DestinationId = ally.ObjectId })
	end

	game.wait(exit.Wind or 0, game.RoomThreadName)

	if exit.Rise then
		game.AdjustZLocation({ Id = ally.ObjectId, Distance = exit.Rise, Duration = exit.RiseTime })
		game.IgnoreGravity({ Id = ally.ObjectId })

		if exit.Shake then
			game.ShakeScreen({ Speed = 200, Distance = 2, FalloffSpeed = 1000, Duration = 0.5 })
		end

		game.wait(exit.RiseTime, game.RoomThreadName)
	end

	if exit.Fx then
		game.CreateAnimation({ Name = exit.Fx, DestinationId = ally.ObjectId })
	end

	game.SetAlpha({ Id = ally.ObjectId, Fraction = 0, Duration = exit.Fade })

	game.wait(exit.Fade, game.RoomThreadName)
	game.Destroy({ Id = ally.ObjectId })
end


function distress_call_dismiss(generation)
	if generation and generation ~= mod.DistressCallGeneration then return end

	local ally = mod.DistressCallAlly
	local exit = mod.DistressCallExit

	distress_call_restore()
	distress_call_set_dark(1, 'HadesInvisible')
	distress_call_revel_end()

	mod.DistressCallActive = nil
	mod.DistressCallAlly = nil
	mod.DistressCallExit = nil
	if not ally then return end

	local room = game.CurrentRun and game.CurrentRun.CurrentRoom
	if room and room.DestroyAssistUnitOnEncounterEndId == ally.ObjectId then
		room.DestroyAssistUnitOnEncounterEndId = nil
		room.AssistUnitName = nil
	end

	if ally.IsDead or not ally.ObjectId or ally.Exiting then return end

	if not exit then
		game.killTaggedThreads(ally.AIThreadName)
		game.killWaitUntilThreads(ally.AINotifyName)
		game.Destroy({ Id = ally.ObjectId })
		return
	end

	game.thread(distress_call_depart, ally, exit)
end


function distress_call_reset()
	distress_call_restore()
	mod.DistressCallGeneration = (mod.DistressCallGeneration or 0) + 1
	mod.DistressCallActive = nil
	mod.DistressCallAlly = nil
	mod.DistressCallExit = nil
	mod.DistressCallRevel = nil
	mod.DistressCallRevelSpec = nil
	mod.DistressCallBall = nil
	mod.DistressCallAnchors = nil
	mod.DistressCallMusic = nil
	distress_call_set_dark(1, 'HadesInvisible')
end


local function distress_call_recharge()
	return duo_recharge(mod.tuning.DistressCall.Cooldown)
end


local function distress_call_ready()
	return game.CheckCooldownNoTrigger('SWuDistressCall', distress_call_recharge())
end


function distress_call_reset_cooldown()
	game.ResetCooldown('SWuDistressCall')
end


local function distress_call_expire(generation)
	game.wait(mod.tuning.DistressCall.Duration, game.RoomThreadName)
	distress_call_dismiss(generation)
end


function distress_call_summon()
	if not distress_call_held() or mod.DistressCallActive then return end
	if not distress_call_ready() then return end

	local hero = game.CurrentRun.Hero
	local room = game.CurrentRun.CurrentRoom
	if not hero or hero.IsDead or not room then return end
	if not mod.tuning.DistressCall.AllowInBoss and distress_call_in_boss() then return end

	local ally = distress_call_pick()
	if not ally then return end

	mod.DistressCallGeneration = (mod.DistressCallGeneration or 0) + 1
	local generation = mod.DistressCallGeneration

	local started = true
	if ally.Revel then
		game.thread(distress_call_revel, ally, generation)
	elseif ally.Grudge then
		game.thread(distress_call_grudge, ally)
	else
		local source = game.EnemyData[ally.Unit]
		if not source then return end

		if ally.Smite then
			game.thread(distress_call_smite, ally, source)
		else
			started = distress_call_fighter(ally, source, generation)
		end
	end

	if not started then
		distress_call_restore()
		return
	end

	mod.DistressCallActive = true
	game.CheckCooldown('SWuDistressCall', distress_call_recharge())
	game.thread(distress_call_expire, generation)
end


---@diagnostic disable-next-line: unused-local
function mod.DistressCallDamaged(_attacker, _args, triggerArgs)
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end
	if triggerArgs and triggerArgs.triggeredById and triggerArgs.triggeredById ~= hero.ObjectId then return end

	distress_call_summon()
end


local function create_distress_call()
	if not distress_call_on() then return end
	if game.TraitData[DISTRESS_CALL_TRAIT] then return end

	local text = duo_text.DistressCall
	if not text then
		print('[' .. _PLUGIN.guid .. '] no text.lua entry for "DistressCall"')
		return
	end

	gods.CreateBoon({
		pluginGUID = _PLUGIN.guid,
		characterName = 'Hermes',
		internalBoonName = 'DistressCallBoon',
		isLegendary = true,
		InheritFrom = { 'LegendaryTrait', 'EarthBoon' },
		addToExistingGod = { boonPosition = 13 },
		reuseBaseIcons = true,
		boonIconPath = 'GUI\\Screens\\BoonIcons\\Hermes_01',

		displayName = text.Name,
		description = text.Description,
		flavourText = text.Flavour,

		StatLines = { 'SWuDistressCallCooldownStatDisplay' },
		ExtractValues = {
			{ Key = 'SWuDistressCallCooldown', ExtractAs = 'TooltipCooldown' },
		},

		ExtraFields = {
			SWuDistressCallCooldown = mod.tuning.DistressCall.Cooldown,

			OnSelfDamagedFunction = { Name = _PLUGIN.guid .. '.DistressCallDamaged' },
		},
	})

	local template = game.TraitRequirements[DISTRESS_CALL_LEGENDARY_TEMPLATE]
	if template then
		game.TraitRequirements[DISTRESS_CALL_TRAIT] = game.DeepCopyTable(template)
	end
end


once('DistressCall', create_distress_call)
