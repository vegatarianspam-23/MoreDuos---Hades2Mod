---@meta _


local RIFT = mod.tuning.VolcanicRift.RiftProjectile
local FINE_LINE = mod.tuning.VolcanicRift.FineLineProjectile
local FIREBALL = mod.tuning.VolcanicRift.FireballProjectile
local PUDDLE = mod.tuning.VolcanicRift.PuddleProjectile

local SPRINT_TRAIL = mod.tuning.VolcanicRift.SprintTrail
local SWORN = 'BlinkTrailProjectileHeraOmega'
local ERUPTS = { [RIFT] = true, [FINE_LINE] = true, [SWORN] = true, SWuSwornBlinkRift = true }


local function volcanic_rift_erupts(name)
	return ERUPTS[name]
end


once('VolcanicRiftProjectiles', function()
	duo_alias_projectile(FINE_LINE, RIFT)
	duo_alias_projectile('HestiaSprintPuddle', PUDDLE)

	if mod.tuning.VolcanicRift.CountsAsHestiaFireball then
		duo_alias_projectile('ProjectileFireball', FIREBALL)
	elseif game.ProjectileData.ProjectileFireball and not game.ProjectileData[FIREBALL] then
		game.ProjectileData[FIREBALL] = game.DeepCopyTable(game.ProjectileData.ProjectileFireball)
		game.ProjectileData[FIREBALL].Name = FIREBALL
	end
end)


local PUDDLES_SCORCH = mod.tuning.VolcanicRift.PuddlesScorch


register_duo({
	key = 'VolcanicRift',

	StatLines = SPRINT_TRAIL
		and { 'SWuVolcanicRiftStatDisplay', 'SWuVolcanicRiftFireballStatDisplay' }
		or { 'SWuVolcanicRiftFireballStatDisplay' },
	ExtractValues = with_keyword_extracts({
		{ Key = 'SWuRiftDamage', ExtractAs = 'TooltipRiftDamage', SkipAutoExtract = not SPRINT_TRAIL },
		{ Key = 'SWuFireballDamage', ExtractAs = 'TooltipFireballDamage' },
		{ Key = 'SWuPuddleDamage', ExtractAs = 'TooltipPuddleDamage', SkipAutoExtract = true },
		{ Key = 'SWuPuddleInterval', ExtractAs = 'TooltipPuddleInterval', SkipAutoExtract = true },
	}, 'Burn'),

	ExtraFields = {
		SWuRiftDamage = mod.tuning.VolcanicRift.RiftDamage,
		SWuFireballDamage = mod.tuning.VolcanicRift.FireballDamage,
		SWuPuddleDamage = mod.tuning.VolcanicRift.PuddleDamage,
		SWuPuddleInterval = mod.tuning.VolcanicRift.PuddleInterval,

		OnSprintAction = SPRINT_TRAIL and {
			FunctionName = _PLUGIN.guid .. '.VolcanicRiftSprint',
			RunOnce = true,
			Args = {},
		} or nil,

		OnProjectileDeathFunction = {
			Name = _PLUGIN.guid .. '.VolcanicRiftDeath',
			ValidProjectiles = { RIFT, FINE_LINE, FIREBALL, SWORN },
			ValidProjectilesLookup = game.ToLookup({ RIFT, FINE_LINE, FIREBALL, SWORN }),
		},

		OnEnemyDamagedAction = PUDDLES_SCORCH and {
			FunctionName = _PLUGIN.guid .. '.VolcanicRiftScorch',
		} or nil,
	},
})


if duo_traits.VolcanicRift then
	local sources = game.ScreenData.RunClear.DamageSourceMap
	sources[RIFT] = duo_traits.VolcanicRift
	sources[FIREBALL] = duo_traits.VolcanicRift
	sources[PUDDLE] = duo_traits.VolcanicRift
end


local FIRE_PUDDLES = game.ToLookup(mod.tuning.VolcanicRift.FirePuddles)


local function volcanic_rift_damage(projectileName, wanted)
	local base = game.GetBaseDataValue({ Type = 'Projectile', Name = projectileName, Property = 'Damage' })
	if type(base) ~= 'number' or base <= 0 then return 1 end
	return wanted / base
end


local function volcanic_rift_held()
	return duo_on('VolcanicRift') and duo_traits.VolcanicRift ~= nil and game.HeroHasTrait(duo_traits.VolcanicRift)
end


local function volcanic_rift_spot(x, y, name, damage)
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end

	local spotId = game.SpawnObstacle({ Name = 'InvisibleTarget', LocationX = x, LocationY = y })
	game.CreateProjectileFromUnit({
		Name = name,
		Id = hero.ObjectId,
		DestinationId = spotId,
		FireFromTarget = true,
		DamageMultiplier = volcanic_rift_damage(name, damage),
	})
	game.thread(game.DestroyOnDelay, { spotId }, 1)
end


function volcanic_rift_tint(args)
	if not args or not volcanic_rift_erupts(args.Name) or not volcanic_rift_held() then return args end

	local tuning = mod.tuning.VolcanicRift
	local tinted = game.ShallowCopyTable(args)
	tinted.ThingProperties = game.MergeTables(args.ThingProperties, { Graphic = tuning.FissureAnim })
	tinted.DataProperties = game.MergeTables(args.DataProperties, { DetonateFx = tuning.FissureDetonateAnim })
	return tinted
end


local SWORN_TRAIL = game.ToLookup(mod.tuning.VolcanicRift.SwornTrailAnims)


function volcanic_rift_trail(args)
	if type(args) ~= 'table' or not SWORN_TRAIL[args.Animation] or not volcanic_rift_held() then return args end

	local tinted = game.ShallowCopyTable(args)
	tinted.Animation = mod.tuning.VolcanicRift.SwornTrailPrefix .. args.Animation
	return tinted
end


function volcanic_rift_track(args, id)
	if not id or not args or not volcanic_rift_erupts(args.Name) then return end
	if not volcanic_rift_held() then return end

	local hero = game.CurrentRun.Hero
	local session = game.SessionMapState
	session.SWuVolcanicRifts = session.SWuVolcanicRifts or {}
	session.SWuVolcanicRifts[id] = args.Angle or game.GetAngle({ Id = hero.ObjectId }) or 0
end


---@diagnostic disable-next-line: unused-local
function mod.VolcanicRiftSprint(_args, _triggerArgs)
	if not SPRINT_TRAIL or not volcanic_rift_held() or not hero_live() then return end

	local session = game.SessionMapState
	if not session.SprintActive or not session.SprintStartTime then return end

	local hero = game.CurrentRun.Hero
	local here = game.GetLocation({ Id = hero.ObjectId })
	if not here then return end

	local trail = session.SWuVolcanicRiftTrail
	if not trail or trail.Start ~= session.SprintStartTime then
		session.SWuVolcanicRiftTrail = { Start = session.SprintStartTime, X = here.X, Y = here.Y }
		return
	end

	local tuning = mod.tuning.VolcanicRift
	local dx, dy = here.X - trail.X, here.Y - trail.Y
	if dx * dx + dy * dy < tuning.SegmentLength * tuning.SegmentLength then return end
	if not game.CheckCooldown('SWuVolcanicRift', tuning.RiftCooldown) then return end

	local fromId = game.SpawnObstacle({ Name = 'InvisibleTarget', LocationX = trail.X, LocationY = trail.Y })
	local toId = game.SpawnObstacle({ Name = 'InvisibleTarget', LocationX = here.X, LocationY = here.Y })
	local angle = game.GetAngleBetween({ Id = fromId, DestinationId = toId })
	game.Destroy({ Ids = { fromId, toId } })

	volcanic_rift_lay((trail.X + here.X) / 2, (trail.Y + here.Y) / 2, angle)

	trail.X = here.X
	trail.Y = here.Y
end


function volcanic_rift_lay(x, y, angle)
	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero then return end

	local tuning = mod.tuning.VolcanicRift
	local anchorId = game.SpawnObstacle({ Name = 'InvisibleTarget', LocationX = x, LocationY = y })
	local args = {
		Name = RIFT,
		Id = hero.ObjectId,
		DestinationId = anchorId,
		FireFromTarget = true,
		Angle = angle,
		DamageMultiplier = volcanic_rift_damage(RIFT, tuning.RiftDamage),
	}
	game.CreateProjectileFromUnit(args)
	game.thread(game.DestroyOnDelay, { anchorId }, tuning.AnchorLifetime)

	local chance = game.GetTotalHeroTraitValue('DoubleOlympianProjectileChance')
		* game.GetTotalHeroTraitValue('LuckMultiplier', { IsMultiplier = true })
	if chance > 0 and game.RandomChance(chance) then
		game.thread(volcanic_rift_repeat, args)
	end
end


function volcanic_rift_repeat(args)
	game.wait(game.GetTotalHeroTraitValue('DoubleOlympianProjectileInterval'))
	if not volcanic_rift_held() or not hero_live() then return end
	game.CreateProjectileFromUnit(args)
end


---@diagnostic disable-next-line: unused-local
function mod.VolcanicRiftDeath(triggerArgs, _args)
	if not duo_on('VolcanicRift') then return end
	if not triggerArgs or not triggerArgs.LocationX or not triggerArgs.LocationY then return end

	local tuning = mod.tuning.VolcanicRift
	local x, y = triggerArgs.LocationX, triggerArgs.LocationY

	if triggerArgs.name == FIREBALL then
		volcanic_rift_spot(x, y, PUDDLE, tuning.PuddleDamage)
		return
	end

	if not volcanic_rift_erupts(triggerArgs.name) then return end

	local rifts = game.SessionMapState.SWuVolcanicRifts
	local angle = rifts and triggerArgs.ProjectileId and rifts[triggerArgs.ProjectileId]
	if rifts and triggerArgs.ProjectileId then rifts[triggerArgs.ProjectileId] = nil end
	if angle == nil or not hero_live() then return end

	local encounter = game.CurrentRun.CurrentRoom and game.CurrentRun.CurrentRoom.Encounter
	if encounter and encounter.BossKillPresentation then return end

	local count = tuning.Fireballs
	for i = 1, count do
		local along = count > 1 and (-tuning.FireballSpread + (i - 1) * 2 * tuning.FireballSpread / (count - 1)) or 0
		local offset = game.CalcOffset(math.rad(angle), along)
		volcanic_rift_spot(x + offset.X, y + offset.Y, FIREBALL, tuning.FireballDamage)
	end
end


function mod.VolcanicRiftScorch(victim, functionArgs, triggerArgs)
	if not PUDDLES_SCORCH or not duo_on('VolcanicRift') then return end
	if not triggerArgs or triggerArgs.EffectName ~= nil then return end
	if not FIRE_PUDDLES[triggerArgs.SourceProjectile] then return end
	if functionArgs and functionArgs.VictimWillBeAlive == false then return end
	if not victim or not victim.ObjectId or victim.IsDead or duo_ignores(victim) then return end

	local damage = triggerArgs.DamageAmount
	if type(damage) ~= 'number' or damage <= 0 then return end

	game.ApplyBurn(victim, { EffectName = 'BurnEffect', NumStacks = math.floor(damage + 0.5) })
end
