---@meta _


mod.SetupDone = mod.SetupDone or {}

function once(key, setup)
	if mod.SetupDone[key] then return end
	mod.SetupDone[key] = true
	setup()
end


function duo_on(key)
	if config.enabled == false then return false end
	return config.Duos[key] == true or config.Experimental[key] == true or config.Experimental[key .. 'Alt'] == true
end

function duo_variant(key)
	local alt = key .. 'Alt'
	if config.Experimental[alt] == true and duo_text[alt] and duo_requirements[alt] then return alt end
	return key
end

function duo_alt(key)
	return duo_variant(key) ~= key
end


import 'tuning.lua'


SCREEN_WAIT_TRIES = 40
SCREEN_WAIT_STEP = 0.1


ICON_PACKAGE = _PLUGIN.guid .. 'BoonIcons'

function load_icon_package()
	game.LoadPackages({ Name = ICON_PACKAGE })
end

local DUO_ROOM_COOLDOWNS = { 'SWuSolarEclipse', 'SWuLandMine', 'SWuWinterSolstice' }

function duo_reset_room_cooldowns()
	for _, name in ipairs(DUO_ROOM_COOLDOWNS) do
		game.ResetCooldown(name)
	end
end


function prefix_SetupMap()
	reload_config()
	load_icon_package()
	duo_meter_apply()
	hot_iron_sync_size()
	wishing_well_keep_reprieve_offered()
	discerning_taste_sync()
	golden_rule_apply()
	wrathful_hubris_apply()
	boiling_blood_clear()
	duo_reset_room_cooldowns()
	distress_call_reset()
	if pandemonium_list_blessing then pandemonium_list_blessing() end
	if pandemonium_refresh_pony_menu then pandemonium_refresh_pony_menu() end
	if pandemonium_held and pandemonium_held() then pandemonium_open_allies() end
	if extra_gods_open_doors then extra_gods_open_doors(pandemonium_held and pandemonium_held()) end
	if pandemonium_announce then pandemonium_announce() end
end


function suffix_SetupMap()
	duo_sync_requirements()
	glowing_brand_sync()
	hot_iron_invalidate()
	tipped_scales_refresh()
	plasmic_capacitor_show_counter()
end


function sjson_ShellText(data)
	local order = { 'Id', 'InheritFrom', 'DisplayName', 'Description' }

	for _, duo in pairs(duo_text) do
		for id, entry in pairs(duo.StatLines or {}) do
			table.insert(data.Texts, sjson.to_object({
				Id = id,
				InheritFrom = 'BaseStatLine',
				DisplayName = '{!Icons.Bullet}{#PropertyFormat}' .. entry.Name,
				Description = '{#UpgradeFormat}{$TooltipData.StatDisplay' .. entry.Index .. '}' ..
					(entry.Suffix or ''),
			}, order))
		end
	end
end


function sjson_Animations(data)
	if not data or not data.Animations then return end

	local name = mod.tuning.SolarFlare.PulseFxNova
	if not name then return end
	for _, animation in ipairs(data.Animations) do
		if animation.Name == name then return end
	end

	table.insert(data.Animations, sjson.to_object({
		Name = name,
		InheritFrom = 'AphroditeDashNova',
		ScaleRadius = mod.tuning.SolarFlare.Radius,
		Scale = mod.tuning.SolarFlare.PulseFxScale,
		StartRed = 1,
		StartGreen = 0.2,
		StartBlue = 0,
		EndRed = 0.999,
		EndGreen = 1,
		EndBlue = 1,
	}, { 'Name', 'InheritFrom' }))
end


function sjson_HestiaAnimations(data)
	if not data or not data.Animations then return end

	local existing = {}
	for _, animation in ipairs(data.Animations) do
		existing[animation.Name] = true
	end

	local air = mod.tuning.AirControl
	local flames = air.FlameFx and {
		{ Name = air.FlameFx .. 'A', InheritFrom = 'HestiaCastDefenseParticleA', RadialOffsetScaleRadius = air.RingRadius },
		{ Name = air.FlameFx .. 'B', InheritFrom = 'HestiaCastDefenseParticleB', RadialOffsetScaleRadius = air.RingRadius },
		{ Name = air.FlameFx .. 'Pick', Random = {
			sjson.to_object({ Name = air.FlameFx .. 'A' }, { 'Name' }),
			sjson.to_object({ Name = air.FlameFx .. 'B' }, { 'Name' }),
		} },
		{ Name = air.FlameFx, InheritFrom = 'HestiaCastDefenseParticleSpawner', VisualFx = air.FlameFx .. 'Pick' },
	} or {}

	for _, flame in ipairs(flames) do
		if not existing[flame.Name] then
			table.insert(data.Animations, sjson.to_object(flame, { 'Name', 'InheritFrom' }))
		end
	end

	local rings = {
		{ Name = mod.tuning.SolarFlare.RingFx, Radius = mod.tuning.SolarFlare.Radius, Scale = mod.tuning.SolarFlare.RingFxScale },
		{ Name = air.RingFx, Radius = air.RingRadius, Scale = 1.0, Flames = air.FlameFx },
	}

	for _, ring in ipairs(rings) do
		if ring.Name and not existing[ring.Name] then
			table.insert(data.Animations, sjson.to_object({
				Name = ring.Name,
				InheritFrom = 'HestiaCastDefenseCircleA',
				ScaleRadius = ring.Radius,
				Scale = ring.Scale,

				Loop = true,
				Duration = 3600,
				RandomDurationMin = 3600,
				RandomDurationMax = 3600,
				StartAlpha = 1,
				EndAlpha = 1,
				EaseIn = 0,
				EaseOut = 0,

				CreateAnimation = ring.Flames or 'HestiaCastDefenseParticleSpawner',
			}, { 'Name', 'InheritFrom' }))
		end
	end
end


function sjson_CastAnimations(data)
	if not data or not data.Animations then return end

	local existing = {}
	for _, animation in ipairs(data.Animations) do
		existing[animation.Name] = true
	end

	local circles = {
		{ Name = mod.tuning.SolarFlare.PulseFxCircle, InheritFrom = 'CastCircleOutHestia' },
		{ Name = mod.tuning.WinterSolstice.RingFx, InheritFrom = 'CastCircleOutPoseidon' },
	}

	for _, circle in ipairs(circles) do
		if circle.Name and not existing[circle.Name] then
			table.insert(data.Animations, sjson.to_object({
				Name = circle.Name,
				InheritFrom = circle.InheritFrom,
				Sound = 'null',
			}, { 'Name', 'InheritFrom', 'Sound' }))
		end
	end

	local ring = mod.tuning.IntertwinedFate.PulseFx
	if ring and not existing[ring] then
		table.insert(data.Animations, sjson.to_object({
			Name = ring,
			InheritFrom = 'CastCircleOutHera',
			Sound = 'null',
			Alpha = mod.tuning.IntertwinedFate.PulseFxAlpha,
			ColorFromOwner = 'Ignore',
			ScaleFromOwner = 'Ignore',
			ClearCreateAnimations = true,
			CreateAnimations = { sjson.to_object({ Name = 'CastCircleOutDisplacement' }, { 'Name' }) },
		}, { 'Name', 'InheritFrom', 'Sound', 'Alpha', 'ColorFromOwner', 'ScaleFromOwner', 'ClearCreateAnimations', 'CreateAnimations' }))
	end
end


local function sjson_color(color)
	return sjson.to_object({ Red = color.Red, Green = color.Green, Blue = color.Blue }, { 'Red', 'Green', 'Blue' })
end


function sjson_AresAnimations(data)
	if not data or not data.Animations then return end

	local tuning = mod.tuning.ConvectiveVortex
	local fx = tuning.RiftFx
	for _, animation in ipairs(data.Animations) do
		if animation.Name == fx.In then return end
	end

	local function particle(name)
		return sjson.to_object({ Name = name }, { 'Name' })
	end

	local copies = {
		{ Name = fx.In, InheritFrom = 'AresBladeSpinIn', ChainTo = fx.Spin, VisualFx = fx.Particles, Hue = tuning.RiftHue },
		{ Name = fx.Spin, InheritFrom = 'AresBladeSpin', ChainTo = fx.Out, VisualFx = fx.Particles, Hue = tuning.RiftHue },
		{ Name = fx.Out, InheritFrom = 'AresBladeSpinOut', VisualFx = fx.Particles, Hue = tuning.RiftHue },
		{
			Name = fx.Particles,
			InheritFrom = 'AresBladeSpinParticles',
			Random = {
				particle('AresBladeSpinParticleA'),
				particle('AresBladeSpinParticleB'),
				particle(fx.Slice),
				particle('AresBladeSpinParticleD'),
			},
		},
		{ Name = fx.Slice, InheritFrom = 'AresBladeSpinParticleC', Color = sjson_color(tuning.RiftColor) },
		{ Name = fx.Shadow, InheritFrom = 'AresBladeSpinShadow', VisualFx = fx.GlowRing },
		{ Name = fx.GlowRing, InheritFrom = 'AresBladeSpinGlowRing', Color = sjson_color(tuning.RiftColor) },
	}

	for _, copy in ipairs(copies) do
		table.insert(data.Animations, sjson.to_object(copy, { 'Name', 'InheritFrom' }))
	end
end


function sjson_HephaestusAnimations(data)
	if not data or not data.Animations then return end

	local tuning = mod.tuning.GlowingBrand
	local glowScale = 1
	for _, animation in ipairs(data.Animations) do
		if animation.Name == tuning.BrandFx then return end
		if animation.Name == 'HephaestusVentDecal' and type(animation.Scale) == 'number' then
			glowScale = animation.Scale
		end
	end

	local scale = glowScale * tuning.BrandFxSize
	local color = tuning.BrandColor

	local copies = {
		{
			Name = tuning.BrandFx,
			InheritFrom = 'HephaestusVentDecal',
			ChildAnimation = tuning.BrandFxPulse,
			ChainTo = tuning.BrandFxOut,
			GroupName = tuning.BrandFxGroup,
			Scale = scale,
			Red = color.Red,
			Green = color.Green,
			Blue = color.Blue,
			Sound = 'null',
		},
		{
			Name = tuning.BrandFxPulse,
			InheritFrom = 'HephaestusVentDecalB',
			GroupName = tuning.BrandFxGroup,
			Scale = scale,
			StartRed = color.Red,
			StartGreen = color.Green,
			StartBlue = color.Blue,
		},
		{
			Name = tuning.BrandFxOut,
			InheritFrom = 'HephaestusVentDecalOut',
			GroupName = tuning.BrandFxGroup,
			Scale = scale,
			Red = color.Red,
			Green = color.Green,
			Blue = color.Blue,
		},
	}

	for _, copy in ipairs(copies) do
		table.insert(data.Animations, sjson.to_object(copy, { 'Name', 'InheritFrom' }))
	end
end


function sjson_PlayerProjectiles(data)
	if not data or not data.Projectiles then return end

	local existing = {}
	for _, projectile in ipairs(data.Projectiles) do
		existing[projectile.Name] = true
	end

	local copies = {
		{ Name = mod.tuning.LandMine.BlastProjectile, InheritFrom = 'MassiveSlamBlast' },
		{ Name = mod.tuning.VolcanicCrown.EmberProjectile, InheritFrom = 'HestiaSprintPuddle' },
		{ Name = mod.tuning.VolcanicCrown.BlastProjectile, InheritFrom = 'MassiveSlamBlast' },
		{ Name = mod.tuning.VolcanicCrown.FireballProjectile, InheritFrom = 'ProjectileFireball' },
		{
			Name = mod.tuning.AirControl.GuardProjectile,
			InheritFrom = 'HestiaSprintDefense',
			Thing = sjson.to_object({ Graphic = mod.tuning.AirControl.RingFx }, { 'Graphic' }),
		},
		{
			Name = mod.tuning.AirControl.SlowZoneProjectile,
			InheritFrom = 'DemeterSprintDefense',
			DamageRadius = mod.tuning.AirControl.RingRadius,
			DamageRadiusScaleX = 1.0,
			DamageRadiusScaleY = 0.5,
			TotalFuse = 3600,
			SpeedMultiplierOfEnemyProjectilesInside = mod.tuning.AirControl.InsideProjectileSpeed,
		},

		{
			Name = mod.tuning.SolarFlare.RingProjectile,
			InheritFrom = 'HestiaSprintDefense',
			Thing = sjson.to_object({ Graphic = mod.tuning.SolarFlare.RingFx }, { 'Graphic' }),
			ProjectileDefenseBlockSpawns = false,
			UseDetonationForProjectileDefense = false,
		},

		{
			Name = mod.tuning.WinterSolstice.GustProjectile,
			InheritFrom = 'DemeterSprintStorm',
			DamageRadius = mod.tuning.WinterSolstice.GustRadius,
			Damage = mod.tuning.WinterSolstice.GustDamage,
			TotalFuse = mod.tuning.WinterSolstice.GustLinger * 2,
			Thing = sjson.to_object({
				Graphic = 'DemeterSprintStormFxIn',
				Scale = mod.tuning.WinterSolstice.GustScale,
			}, { 'Graphic', 'Scale' }),
		},
	}

	for _, copy in ipairs(copies) do
		if copy.Name and not existing[copy.Name] then
			table.insert(data.Projectiles, sjson.to_object(copy, { 'Name', 'InheritFrom' }))
		end
	end

	sjson_StormFrontCopies(data)
	sjson_AirControlHadesProjectiles(data)
end


function sjson_AirControlHadesProjectiles(data)
	local ok, zagreus = pcall(function() return rom.mods['NikkelM-Zagreus_Journey'] end)
	local names = ok and zagreus and zagreus.HadesSjsonProjectilesTable
	if not names then return end

	local byName = {}
	for _, projectile in ipairs(data.Projectiles) do
		byName[projectile.Name] = projectile
	end

	local settled = {
		['1_BaseEnemyProjectileUndestroyable'] = true,
		['1_BaseEnemyProjectileUnblockable'] = true,
		['1_BaseEnemyProjectileReflectable'] = true,
	}

	local function blockable(name)
		local seen = {}
		local current = name
		while current and not seen[current] do
			seen[current] = true
			if settled[current] then return false end

			local projectile = byName[current]
			if not projectile then return true end
			if projectile.CanBeProjectileDefenseDestroyedByLayer ~= nil then return false end
			if projectile.CanBeProjectileDefenseDestroyedByName2 == 'null' then return false end

			current = projectile.InheritFrom
		end
		return true
	end

	for name in pairs(names) do
		local projectile = byName[name]
		if projectile and blockable(name) then
			projectile.CanBeProjectileDefenseDestroyedByLayer = 'BoonDefense'
		end
	end
end


function sjson_StormFrontCopies(data)
	local byName = {}
	for _, projectile in ipairs(data.Projectiles) do
		byName[projectile.Name] = projectile
	end

	local function inherited(name, key)
		local projectile = byName[name]
		while projectile do
			if projectile[key] ~= nil then return projectile[key] end
			projectile = byName[projectile.InheritFrom]
		end
	end

	local scale = mod.tuning.StormFront.ScaleMultiplier
	for original, copy in pairs(mod.tuning.StormFront.Enlarged) do
		local radius = inherited(original, 'DamageRadius')
		local thing = inherited(original, 'Thing')

		if not byName[copy] and type(radius) == 'number' and thing and thing.Graphic then
			table.insert(data.Projectiles, sjson.to_object({
				Name = copy,
				InheritFrom = original,
				DamageRadius = radius * scale,
				Thing = sjson.to_object({
					Graphic = thing.Graphic,
					Scale = (thing.Scale or 1) * scale,
				}, { 'Graphic', 'Scale' }),
			}, { 'Name', 'InheritFrom' }))
		end
	end
end


function sjson_TraitText(data)
	local rewritten = {}

	for _, entry in ipairs(data.Texts) do
		local rewrite = blessing_text[entry.Id]
		if rewrite then
			rewritten[entry.Id] = true
			if rewrite.DisplayName then entry.DisplayName = rewrite.DisplayName end
			if rewrite.Description then entry.Description = rewrite.Description end
		end
	end

	for id, entry in pairs(blessing_text) do
		if not rewritten[id] then
			local text = { Id = id }
			local order = { 'Id' }

			if entry.DisplayName then
				text.DisplayName = entry.DisplayName
				table.insert(order, 'DisplayName')
			end
			if entry.Description then
				text.Description = entry.Description
				table.insert(order, 'Description')
			end

			table.insert(data.Texts, sjson.to_object(text, order))
		end
	end
end


function sjson_HelpText(data)
	local keywords = {}
	for key, entry in pairs(duo_text) do
		if duo_on(key) then
			for id, keyword in pairs(entry.Keywords or {}) do
				keywords[id] = keyword
			end
		end
	end

	for _, entry in ipairs(data.Texts) do
		local keyword = keywords[entry.Id]
		if keyword then
			if keyword.Description then entry.Description = keyword.Description end
			if keyword.DisplayName then entry.DisplayName = keyword.DisplayName end
			keywords[entry.Id] = nil
		end
	end

	local keywordOrder = { 'Id', 'DisplayName', 'Description' }
	for id, keyword in pairs(keywords) do
		table.insert(data.Texts, sjson.to_object({
			Id = id,
			DisplayName = keyword.DisplayName,
			Description = keyword.Description,
		}, keywordOrder))
	end

	local order = { 'Id', 'DisplayName' }
	for _, entry in pairs(duo_text) do
		for id, text in pairs(entry.CombatText or {}) do
			table.insert(data.Texts, sjson.to_object({ Id = id, DisplayName = text }, order))
		end
	end

	for _, entry in pairs(blessing_text) do
		for id, text in pairs(entry.CombatText or {}) do
			table.insert(data.Texts, sjson.to_object({ Id = id, DisplayName = text }, order))
		end
	end

	local claimed = {}
	for _, entry in pairs(duo_meter) do
		claimed[entry.Text] = entry.Key
	end

	for id, key in pairs(claimed) do
		local name = (duo_text[key] or {}).Name
		if name then
			table.insert(data.Texts, sjson.to_object({ Id = id, DisplayName = name }, order))
		end
	end
end


function sjson_MacroText(data)
	local order = { 'Id', 'InheritFrom', 'DisplayName', 'Description' }

	local function add(entry)
		table.insert(data.Texts, sjson.to_object(entry, order))
	end

	for _, god in ipairs({ 'Artemis', 'Athena', 'Dionysus', 'Hades' }) do
		local lootName = god .. 'Upgrade'
		add({ Id = 'UpgradeChoiceMenu_Title_' .. lootName, DisplayName = 'Boons of ' .. god })
		add({ Id = 'Player_GodDispleased_' .. lootName, DisplayName = god .. ' Grew Displeased!' })
		add({
			Id = 'SuperSacrifice_CombatText_' .. lootName,
			DisplayName = '{#CombatTextHighlightFormat}Boons of ' .. god ..
				' {#Prev}{#UpgradeFormat}+{$TempTextData.Amount}{#Prev}{!Icons.PomLevel}!',
		})
		add({
			Id = 'EchoLastRewardBoon_' .. lootName,
			InheritFrom = 'BaseBoon',
			Description = 'Manifest a copy of your most recently claimed {#ItalicFormat}Reward: ' ..
				'{#Prev}{#BoldFormat}{$Keywords.GodBoon} of ' .. god,
		})
	end
end


function channelling_omega()
	return not game.IsEmpty(game.MapState.ChargedManaWeapons or {})
end


local function channel_staged(hero, weaponName)
	if (game.MapState.WeaponCharge or {})[weaponName] ~= nil then return true end

	local data = game.GetWeaponData(hero, weaponName)
	for _, functionName in ipairs((data or {}).OnChargeFunctionNames or {}) do
		if functionName == 'DoWeaponCharge' then return true end
	end
	return false
end


local function channel_scale(hero, weaponName)
	local multiplier = game.GetLuaWeaponSpeedMultiplier(weaponName) or 1
	if channel_staged(hero, weaponName) then return multiplier end

	local current = game.GetWeaponDataValue({ Id = hero.ObjectId, WeaponName = weaponName, Property = 'ChargeTime' })
	local baseCharge = game.GetBaseDataValue({ Type = 'Weapon', Name = weaponName, Property = 'ChargeTime' })
	if not current or not baseCharge or baseCharge <= 0 then return nil end

	multiplier = multiplier * (current / baseCharge)
	for _, value in pairs((game.SessionMapState or {}).GlobalAttackSpecialSpeed or {}) do
		multiplier = multiplier * value
	end
	return multiplier
end


function channel_hold(base)
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero or base <= 0 then return base end

	local fastest = nil
	for weaponName in pairs(game.MapState.ChargedManaWeapons or {}) do
		local scale = channel_scale(hero, weaponName)
		if scale and (not fastest or scale < fastest) then fastest = scale end
	end

	if not fastest then return base end

	return base * fastest
end


function omega_charged()
	local reached = game.MapState.WeaponCharge or {}
	for weaponName in pairs(game.MapState.ChargedManaWeapons or {}) do
		if (reached[weaponName] or 0) >= 1 then return true end
	end
	return false
end


local heinousAffrontFoeId = nil
local heinousAffrontDamage = nil

function heinous_affront_record(attacker, victim, triggerArgs)
	local bite = triggerArgs and triggerArgs.MissingEffectDamageIncrease
	if type(bite) ~= 'number' or bite <= 0 then return end
	if not victim or not victim.ObjectId then return end
	if attacker ~= (game.CurrentRun and game.CurrentRun.Hero) then return end

	heinousAffrontFoeId = victim.ObjectId
	heinousAffrontDamage = bite
end

function heinous_affront_damage(foe, triggerArgs)
	local reported = triggerArgs and triggerArgs.DamageAmount

	if not (triggerArgs and triggerArgs.ManuallyTriggered) then return reported end

	local id = foe and foe.ObjectId
	if id and id == heinousAffrontFoeId and heinousAffrontDamage then
		return heinousAffrontDamage
	end
	return reported
end


local function duo_alias_in_table(node, original, copy, depth)
	if type(node) ~= 'table' or depth > 6 then return end

	local list = rawget(node, 'ValidProjectiles')
	if type(list) == 'table' and game.Contains(list, original) and not game.Contains(list, copy) then
		table.insert(list, copy)

		local lookup = rawget(node, 'ValidProjectilesLookup')
		if type(lookup) == 'table' then lookup[copy] = true end
	end

	for key, value in pairs(node) do
		if type(value) == 'table' and key ~= 'ValidProjectilesLookup' then
			duo_alias_in_table(value, original, copy, depth + 1)
		end
	end
end


function duo_spark_properties()
	local jumps = game.GetBaseDataValue({ Type = 'Projectile', Name = 'ProjectileZeusSpark', Property = 'NumJumps' })
	local properties = {
		NumJumps = (type(jumps) == 'number' and jumps or 0) + game.GetTotalHeroTraitValue('ZeusSparkBonusBounces'),
	}

	if game.HeroHasTrait('ReboundingSparkBoon') then
		properties.AllowRepeatedOwnerJumpHit = true
		properties.AffectsSelf = true
	end
	return properties
end


function duo_apply_blitz(victim, damage)
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero or not victim or not victim.ObjectId then return end

	local base = game.GetBaseDataValue({ Type = 'Projectile', Name = 'ZeusEchoStrike', Property = 'Damage' })
	if type(base) ~= 'number' or base <= 0 then base = 60 end

	local effectName = 'DamageEchoEffect'
	game.ApplyEffect({
		DestinationId = victim.ObjectId,
		Id = hero.ObjectId,
		EffectName = effectName,
		DataProperties = game.MergeAllTables({
			game.EffectData[effectName].EffectData,
			{ Modifier = damage / base },
		}),
	})
end


function duo_recharge(seconds, floor)
	if type(seconds) ~= 'number' then return seconds end

	local scaled = seconds * game.GetTotalHeroTraitValue('OlympianRechargeMultiplier', { IsMultiplier = true })
	if type(floor) == 'number' then return math.max(floor, scaled) end

	return scaled
end


function duo_alias_projectile(original, copy)
	if not original or not copy then return end

	if game.ProjectileData[original] and not game.ProjectileData[copy] then
		game.ProjectileData[copy] = game.DeepCopyTable(game.ProjectileData[original])
	end

	if game.ProjectileData[copy] then
		game.ProjectileData[copy].Name = copy
	end

	for _, set in pairs(game.WeaponSets or {}) do
		if type(set) == 'table' and game.Contains(set, original) and not game.Contains(set, copy) then
			table.insert(set, copy)
		end
	end

	for _, trait in pairs(game.TraitData or {}) do
		duo_alias_in_table(trait, original, copy, 0)
	end
end


function fireball_projectiles()
	return mod.tuning.Fireballs.Projectiles
end


function fireball_lookup()
	return game.ToLookup(fireball_projectiles())
end


function is_allied_summon(unit)
	if not unit then return false end
	if unit.AlwaysTraitor or unit.Charmed then return true end
	if unit.ObjectId and game.IsCharmed({ Id = unit.ObjectId }) then return true end
	return game.Contains(game.MapState.SpellSummons or {}, unit)
end


function duo_ignores(unit)
	return unit.SkipModifiers and not unit.TrainingTarget
end


function duo_foe(unit)
	if not unit or not unit.ObjectId or unit.IsDead then return false end
	if duo_ignores(unit) then return false end

	if not game.GetThingDataValue({ Id = unit.ObjectId, Property = 'StopsProjectiles' }) then return false end
	if game.IsInvulnerable({ Id = unit.ObjectId }) then return false end
	if game.IsUntargetable({ Id = unit.ObjectId }) then return false end

	return true
end


DUO_HITCH_EFFECT = 'DamageShareEffect'


function duo_hitch(unit, duration)
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero or not unit or not unit.ObjectId or unit.IsDead then return end

	local effect = game.EffectData[DUO_HITCH_EFFECT]
	if not effect then return end

	local dataProperties = game.MergeAllTables({ effect.EffectData })
	dataProperties.Duration = (duration or dataProperties.Duration or 0)
		+ game.GetTotalHeroTraitValue('DamageShareDurationIncrease')
	dataProperties.Amount = (dataProperties.Amount or 0)
		+ game.GetTotalHeroTraitValue('DamageShareAmountIncrease')

	game.ApplyEffect({
		DestinationId = unit.ObjectId,
		Id = hero.ObjectId,
		EffectName = DUO_HITCH_EFFECT,
		DataProperties = dataProperties,
	})
end


function duo_unit_ready(unit, timeout)
	local waited = 0
	timeout = timeout or 2

	while unit and not unit.IsDead and waited < timeout
		and not (unit.ActivationFinished and unit.Health) do
		game.wait(0.05, game.RoomThreadName)
		waited = waited + 0.05
	end

	return unit ~= nil and unit.ActivationFinished == true and unit.Health ~= nil and not unit.IsDead
end


function duo_blow_attacker(triggerArgs)
	if not triggerArgs or triggerArgs.EffectName then return nil end
	return duo_live_foe(triggerArgs.AttackerTable or triggerArgs.Attacker)
end

function duo_live_foe(unit)
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero or not unit or unit == hero or not unit.ObjectId then return nil end
	if not (game.ActiveEnemies or {})[unit.ObjectId] then return nil end
	if duo_ignores(unit) then return nil end
	return unit
end


local COMBAT_TEXT_SPACING = 60
local COMBAT_TEXT_DEFAULT_OFFSET = -140

function combat_text_stack(args)
	if type(args) ~= 'table' or args.SWuTextStacked then return args end
	if args.UseProgressiveStack or args.ScreenSpace or args.SkipRise then return args end

	local targetId = args.TargetId
	if args.TargetHero and game.CurrentRun and game.CurrentRun.Hero then
		targetId = game.CurrentRun.Hero.ObjectId
	end
	if not targetId or targetId <= 0 then return args end

	local stacks = game.SWuCombatTextStacks or {}
	game.SWuCombatTextStacks = stacks
	local slots = stacks[targetId] or {}
	stacks[targetId] = slots

	local start = (game._worldTime or 0) + (args.PreDelay or 0)
	local finish = start + (args.Duration or 0.4) + (args.FadeDuration or 0.3)

	local slot = 0
	while slots[slot] and slots[slot] > start do
		slot = slot + 1
	end
	slots[slot] = finish

	local stacked = game.ShallowCopyTable(args)
	stacked.SWuTextStacked = true
	if slot > 0 then
		stacked.OffsetY = (args.OffsetY or COMBAT_TEXT_DEFAULT_OFFSET) - slot * COMBAT_TEXT_SPACING
	end
	return stacked
end


local DUO_WEAPON_NAMES = game.AddLinkedWeapons(game.WeaponSets.HeroPrimarySecondaryWeapons)

DUO_SCOPE_WEAPON = {
	ValidWeapons = DUO_WEAPON_NAMES,
	ValidWeaponsLookup = game.ToLookup(DUO_WEAPON_NAMES),
}


DUO_SCOPE_OLYMPIAN_PROJECTILES = {
	ValidProjectiles = game.WeaponSets.OlympianProjectileNames,
	ValidProjectilesLookup = game.ToLookup(game.WeaponSets.OlympianProjectileNames),
}


DUO_SCOPE_OLYMPIAN_EFFECTS = {
	ValidEffects = game.WeaponSets.OlympianEffectNames,
}


function duo_show_percent(traitName, key, bonus)
	local room = game.CurrentRun and game.CurrentRun.CurrentRoom
	if not room then return end

	local percent = math.floor(bonus * 100 + 0.5)
	if room[key] == percent then return end
	room[key] = percent

	local trait = game.GetHeroTrait(traitName)
	if trait then game.UpdateTraitNumber(trait) end
end


function duo_set_multiplier(key, multiplier, scope)
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end
	hero.OutgoingDamageModifiers = hero.OutgoingDamageModifiers or {}

	local entry
	for _, modifier in ipairs(hero.OutgoingDamageModifiers) do
		if modifier.SWuDuoKey == key then
			entry = modifier
			break
		end
	end
	if not entry then
		entry = { SWuDuoKey = key, ValidWeaponMultiplier = 1 }
		for field, value in pairs(scope or {}) do
			entry[field] = value
		end
		game.AddOutgoingDamageModifier(hero, entry)
	end

	entry.ValidWeaponMultiplier = multiplier
end



local KEYWORD_EXTRACTS = {
	Rend = {
		{ ExtractAs = 'AresCurseDuration', SkipAutoExtract = true, External = true,
			BaseType = 'EffectData', BaseName = 'AresStatus', BaseProperty = 'Duration' },
		{ ExtractAs = 'AresCursePowerBonus', SkipAutoExtract = true, External = true,
			BaseType = 'EffectLuaData', BaseName = 'AresStatus', BaseProperty = 'BonusBaseDamageOnInflict' },
	},
	Root = {
		{ ExtractAs = 'ChillDuration', SkipAutoExtract = true, External = true,
			BaseType = 'EffectData', BaseName = 'ChillEffect', BaseProperty = 'Duration' },
		{ ExtractAs = 'ChillActiveDuration', SkipAutoExtract = true, External = true,
			BaseType = 'EffectData', BaseName = 'ChillEffect', BaseProperty = 'ActiveDuration' },
	},
	Blind = {
		{ ExtractAs = 'BlindChance', SkipAutoExtract = true, External = true,
			BaseType = 'EffectData', BaseName = 'BlindEffect', BaseProperty = 'MissChance' },
		{ ExtractAs = 'BlindDuration', SkipAutoExtract = true, External = true,
			BaseType = 'EffectData', BaseName = 'BlindEffect', BaseProperty = 'Duration' },
	},
	Weak = {
		{ ExtractAs = 'TooltipWeakModifier', SkipAutoExtract = true, External = true,
			BaseType = 'EffectData', BaseName = 'WeakEffect', BaseProperty = 'Modifier',
			Format = 'NegativePercentDelta' },
		{ ExtractAs = 'TooltipWeakDuration', SkipAutoExtract = true, External = true,
			BaseType = 'EffectData', BaseName = 'WeakEffect', BaseProperty = 'Duration' },
	},
	Burn = {
		{ ExtractAs = 'BurnRate', SkipAutoExtract = true, External = true,
			BaseType = 'EffectLuaData', BaseName = 'BurnEffect', BaseProperty = 'DamagePerSecond',
			DecimalPlaces = 1 },
	},
	BladeRift = {
		{ ExtractAs = 'BladeRiftDuration', SkipAutoExtract = true, External = true,
			BaseType = 'ProjectileBase', BaseName = 'AresProjectile', BaseProperty = 'TotalFuse' },
	},
	DelayedKnockback = {
		{ ExtractAs = 'DelayedKnockbackModifier', SkipAutoExtract = true, External = true,
			BaseType = 'EffectData', BaseName = 'DelayedKnockbackEffect', BaseProperty = 'Modifier',
			Format = 'PercentDelta' },
		{ ExtractAs = 'DelayedKnockbackDuration', SkipAutoExtract = true, External = true,
			BaseType = 'EffectData', BaseName = 'DelayedKnockbackEffect', BaseProperty = 'Duration',
			DecimalPlaces = 1 },
	},
	Link = {
		{ ExtractAs = 'DamageShareDuration', SkipAutoExtract = true, External = true,
			BaseType = 'EffectData', BaseName = 'DamageShareEffect', BaseProperty = 'Duration' },
		{ ExtractAs = 'DamageShareAmount', SkipAutoExtract = true, External = true,
			BaseType = 'EffectData', BaseName = 'DamageShareEffect', BaseProperty = 'Amount',
			Format = 'Percent' },
	},
	Echo = {
		{ ExtractAs = 'EchoDuration', SkipAutoExtract = true, External = true,
			BaseType = 'EffectData', BaseName = 'DamageEchoEffect', BaseProperty = 'Duration' },
		{ ExtractAs = 'EchoThreshold', SkipAutoExtract = true, External = true,
			BaseType = 'EffectData', BaseName = 'DamageEchoEffect', BaseProperty = 'DamageThreshold' },
	},
	SlowField = {
		{ ExtractAs = 'Duration', SkipAutoExtract = true, External = true,
			BaseType = 'ProjectileBase', BaseName = 'DemeterSprintStorm', BaseProperty = 'TotalFuse',
			DecimalPlaces = 2 },
		{ ExtractAs = 'ProjectileSlow', SkipAutoExtract = true, External = true,
			BaseType = 'ProjectileBase', BaseName = 'DemeterSprintDefense',
			BaseProperty = 'SpeedMultiplierOfEnemyProjectilesInside', Format = 'NegativePercentDelta' },
		{ ExtractAs = 'ChillAmount', SkipAutoExtract = true, External = true,
			BaseType = 'EffectData', BaseName = 'LegacyChillEffect',
			BaseProperty = 'ElapsedTimeMultiplier', Format = 'NegativePercentDelta' },
	},
	KnockbackAmplify = {
		{ ExtractAs = 'KnockbackAmplifyDuration', SkipAutoExtract = true, External = true,
			BaseType = 'EffectData', BaseName = 'AmplifyKnockbackEffect', BaseProperty = 'Duration',
			DecimalPlaces = 1 },
		{ ExtractAs = 'FontChance', SkipAutoExtract = true, External = true,
			BaseType = 'EffectLuaData', BaseName = 'AmplifyKnockbackEffect', BaseProperty = 'Chance',
			Format = 'LuckModifiedPercent' },
		{ ExtractAs = 'FontDamage', SkipAutoExtract = true, External = true,
			BaseType = 'ProjectileBase', BaseName = 'PoseidonEffectFont', BaseProperty = 'Damage' },
	},
}


function with_keyword_extracts(own, ...)
	local combined = {}
	for _, entry in ipairs(own or {}) do table.insert(combined, entry) end

	for _, keyword in ipairs({ ... }) do
		for _, entry in ipairs(KEYWORD_EXTRACTS[keyword] or {}) do
			table.insert(combined, entry)
		end
	end
	return combined
end


function in_run()
	return game.CurrentRun ~= nil and game.CurrentRun.Hero ~= nil
end


function training_grounds()
	local hub = game.CurrentHubRoom
	return hub ~= nil and hub.AllowEnemyAIActive == true
end

function hero_live()
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return false end
	return not hero.IsDead or training_grounds()
end


function duo_running(traitName)
	return game.CurrentRun and game.CurrentRun.CurrentRoom and hero_live() and game.HeroHasTrait(traitName)
end


function duo_loop_claim(traitName)
	if not traitName then return nil end

	local tag = traitName .. 'Loop'
	if game.HasThread(tag) then return nil end
	return tag
end


local SURFACE_SHOP_SLOT_COMPONENTS = {
	'PurchaseButton', 'PurchaseButtonHighlight', 'PurchaseButtonQuestIcon',
	'PurchaseButtonTitle', 'PurchaseButtonCost', 'PurchaseButtonDelivery',
	'IconBacking', 'Icon', 'HermesSpeedUp', 'Backing',
}

local SURFACE_SHOP_SLOT_SUFFIXES = {
	PurchaseButtonHighlight = 'Highlight',
	PurchaseButtonQuestIcon = 'QuestIcon',
}


function fresh_rerolls_enabled()
	return mod.tuning.Systems.FreshRerolls == true
end

function shop_reroll_options(storeData, roomName, currentNames, wanted, alwaysExclude)
	local function fill(exclusions)
		return game.FillInShopOptions({
			StoreData = storeData,
			RoomName = roomName,
			ExclusionNames = not game.IsEmpty(exclusions) and exclusions or nil,
		}).StoreOptions
	end

	local function vanilla()
		local exclusions = game.ShallowCopyTable(alwaysExclude or {})
		if not game.IsEmpty(currentNames) then
			table.insert(exclusions, game.GetRandomValue(currentNames))
		end
		return fill(exclusions)
	end

	if not fresh_rerolls_enabled() or game.IsEmpty(currentNames) then return vanilla() end

	local exclusions = game.ShallowCopyTable(alwaysExclude or {})
	for _, name in ipairs(currentNames) do
		table.insert(exclusions, name)
	end

	local options = fill(exclusions)
	if game.TableLength(options) >= (wanted or 0) then return options end

	return vanilla()
end


function surface_shop_reroll_enabled()
	return mod.tuning.Systems.SurfaceShopReroll == true
end

local function surface_shop_slot_count()
	local data = game.StoreData.SurfaceShop
	if data.MaxOffers then return data.MaxOffers end

	local total = 0
	for _, groupData in pairs(data.GroupsOf or {}) do
		total = total + (groupData.Offers or 0)
	end
	return total
end

local function surface_shop_clear_slots(screen)
	local components = screen and screen.Components
	if not components then return end

	for index = 1, surface_shop_slot_count() do
		for _, name in ipairs(SURFACE_SHOP_SLOT_COMPONENTS) do
			local suffix = SURFACE_SHOP_SLOT_SUFFIXES[name]
			local key = suffix and ('PurchaseButton' .. index .. suffix) or (name .. index)
			local component = components[key]
			if component and component.Id then
				game.Destroy({ Id = component.Id })
			end
			components[key] = nil
		end
	end
end

function surface_shop_draw_reroll(screen)
	if not surface_shop_reroll_enabled() then return end

	local store = game.CurrentRun and game.CurrentRun.CurrentRoom and game.CurrentRun.CurrentRoom.Store
	if not store or not screen.Components or not screen.Components.RerollButton then return end

	game.UpdateStoreReroll(screen, store.StoreOptions, _PLUGIN.guid .. '.RerollSurfaceShop')
	discerning_taste_discount_store(screen)
end

---@diagnostic disable-next-line: unused-local
function mod.RerollSurfaceShop(screen, _button)
	local room = game.CurrentRun and game.CurrentRun.CurrentRoom
	local store = room and room.Store
	if not store or game.IsEmpty(store.StoreOptions) then return end

	local kept, keptNames = {}, {}
	for index, option in pairs(store.StoreOptions) do
		if option and option.Purchased then
			kept[index] = option
			if option.Name then table.insert(keptNames, option.Name) end
		end
	end

	local available = {}
	for index, option in pairs(store.StoreOptions) do
		if option and not kept[index] and option.Name then table.insert(available, option.Name) end
	end

	surface_shop_clear_slots(screen)
	store.Buttons = {}

	store.StoreOptions = shop_reroll_options(
		game.StoreData.SurfaceShop, room.Name, available, surface_shop_slot_count(), keptNames)

	for index, option in pairs(kept) do
		store.StoreOptions[index] = option
	end

	game.CreateSurfaceShopButtons(screen)
end


function reload_config()
	local ok, reloaded = pcall(function()
		local loaded = chalk.auto('config.lua')
		return loaded
	end)
	if ok and reloaded then
		config = reloaded
		public.config = config
	else
		print('[' .. _PLUGIN.guid .. '] config reload failed: ' .. tostring(reloaded))
	end
end


import 'duos/permafrost_shield.lua'
import 'duos/bubbling_cauldron.lua'
import 'duos/bitter_end.lua'
import 'duos/blinding_smite.lua'
import 'duos/untouchable_glow.lua'
import 'duos/different_league.lua'
import 'duos/cold_hearted.lua'
import 'duos/golden_rule.lua'
import 'duos/boiling_blood.lua'
import 'duos/convective_vortex.lua'
import 'duos/volcanic_crown.lua'
import 'duos/wrathful_hubris.lua'
import 'duos/goddess_spite.lua'
import 'duos/bleeding_heart.lua'
import 'duos/explosive_sparks.lua'
import 'duos/glacial_advance.lua'
import 'duos/kindled_spirit.lua'
import 'duos/room_temperature.lua'
import 'duos/intertwined_fate.lua'
import 'duos/spiteful_strength.lua'
import 'duos/family_trade.lua'
import 'duos/blood_born.lua'
import 'duos/razor_shoals.lua'
import 'duos/storm_front.lua'
import 'duos/plasmic_capacitor.lua'
import 'duos/solar_eclipse.lua'
import 'duos/winter_solstice.lua'
import 'duos/solar_flare.lua'
import 'duos/tectonic_cycle.lua'
import 'duos/burnt_offering.lua'
import 'duos/orbital_ring.lua'
import 'duos/royal_banquet.lua'
import 'duos/ingenious_invention.lua'
import 'duos/land_mine.lua'
import 'duos/glowing_brand.lua'
import 'duos/hot_iron.lua'
import 'duos/energy_overflow.lua'
import 'duos/gentle_caress.lua'
import 'duos/family_reunion.lua'
import 'duos/air_control.lua'
import 'duos/wishing_well.lua'
import 'duos/discerning_taste.lua'
import 'duos/tipped_scales.lua'
import 'distress_call.lua'

function wait_for_screens(settle)
	settle = settle or 0

	for _ = 1, SCREEN_WAIT_TRIES do
		if not game.IsEmpty(game.ActiveScreenOrder or {}) then
			game.waitUnmodified(SCREEN_WAIT_STEP)
		else
			if settle > 0 then game.waitUnmodified(settle) end
			if game.IsEmpty(game.ActiveScreenOrder or {}) then return end
		end
	end
end

function defer_screen_open(open, ...)
	if game.IsEmpty(game.ActiveScreenOrder or {}) then
		return open(...)
	end

	local args = table.pack(...)
	game.thread(function()
		wait_for_screens(0)
		open(table.unpack(args, 1, args.n))
	end)
end


local POST_HASTE = 'SlowProjectileBoon'

local function duo_recharge_traits()
	local traits = {}
	for _, key in ipairs({ 'LandMine', 'SolarEclipse', 'TectonicCycle' }) do
		local noRecharge = key == 'SolarEclipse' and not duo_alt(key)
		if duo_on(key) and duo_traits[key] and not noRecharge then
			table.insert(traits, duo_traits[key])
		end
	end
	if distress_call_on() and not distress_call_on_encounter_start() then table.insert(traits, DISTRESS_CALL_TRAIT) end
	return traits
end


function duo_post_haste_requirements()
	local haste = game.TraitData[POST_HASTE]
	if not haste or not haste.OlympianRechargeMultiplier then return end

	local requirement = game.TraitRequirements[POST_HASTE]
	local list = requirement and requirement.OneOf
	if not list then return end

	for _, traitName in ipairs(duo_recharge_traits()) do
		if game.TraitData[traitName] and not game.Contains(list, traitName) then
			table.insert(list, traitName)
		end
	end
end


function duo_sync_requirements()
	duo_roles_ensure()
	canon_sync_requirements()
	duo_post_haste_requirements()

	for key, traitName in pairs(duo_traits or {}) do
		local id = duo_variants[key] or key
		local spec = duo_requirements and duo_requirements[id]
		if spec and not spec.Requires and game.TraitData[traitName] then
			game.TraitRequirements[traitName] = {
				OneFromEachSet = duo_offer_sets(id),
			}
		end
	end
end
