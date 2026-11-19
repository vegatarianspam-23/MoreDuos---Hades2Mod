---@meta _


mod.tuning = {
	Systems = {
		ExtraBoonRewards = 2,
		FreshRerolls = false,
		SurfaceShopReroll = true,
		HexReroll = false,

		ExtraGods = {
			DoorRewards = false,
			HideHadesRarity = true,
		},
	},

	Fireballs = {
		Projectiles = {
			'ProjectileCastFireball', 'ProjectileFireball', 'SWuHestiaFireball',
		},
	},

	Pandemonium = {
		RarityBonus = 0.10,
		OfferChance = 0.10,
		DoubleBoonChance = 0.10,

		VoiceLines = 'ChaosHarvestReactionVoiceLines',

		BlessingChance = 0.50,
		AnnounceDelay = 1.0,

		BlessedRewards = { 'WeaponUpgrade', 'StackUpgradeTriple', 'TalentDrop' },

		Blessings = {
			{ Key = 'Aid', Weight = 10 },
			{ Key = 'Fated', Weight = 8 },
			{ Key = 'FreeShop', Weight = 8 },
			{ Key = 'Fountain', Weight = 6 },
			{ Key = 'Respite', Weight = 6 },
			{ Key = 'Trial', Weight = 8 },
			{ Key = 'Heroic', Weight = 12 },
			{ Key = 'Forbidden', Weight = 10 },
			{ Key = 'TakeAll', Weight = 8 },
			{ Key = 'Duplicate', Weight = 12 },
			{ Key = 'Peace', Weight = 8 },
			{ Key = 'Elysium', Weight = 3 },
			{ Key = 'Asphodel', Weight = 3 },
		},

		RoomSets = {
			Elysium = 'C',
			Asphodel = 'Anomaly',
		},

		Rooms = {
			Fountain = '_Reprieve01',
			Respite = '_Reprieve01',
			FreeShop = '_Shop01',
			Fated = '_Story01',
		},

		Spoils = {
			Elysium = { 'Boon', 'Boon', 'Boon' },
			Asphodel = { 'MaxHealthDropBig', 'MaxManaDropBig' },
		},

		SpoilsRadius = 140,

		CapturePointRadiusMin = 600,

		PickTries = 3,

		Fated = {
			'NPC_Arachne_01',
			'NPC_Narcissus_01',
			'NPC_Echo_01',
			'NPC_Medea_01',
			'NPC_Circe_01',
			'NPC_Dionysus_01',
		},

		Allies = {
			{ Record = 'NPC_Artemis_01', Prefix = 'ArtemisCombat', Packages = { 'Artemis' } },
			{ Record = 'NPC_Athena_01', Prefix = 'AthenaCombat', Packages = { 'Athena' } },
			{ Record = 'NPC_Heracles_01', Prefix = 'HeraclesCombat', Packages = { 'Heracles' } },
			{ Record = 'NPC_Icarus_01', Prefix = 'IcarusCombat', Packages = { 'Icarus' } },

			{
				Record = 'NPC_Thanatos_Field_01',
				Prefix = 'Thanatos',
				Packages = { 'Thanatos' },
				Requires = 'NikkelM-Zagreus_Journey',
				GlobalRecord = true,
			},
		},

		DoubleBoonSound = '/SFX/Menu Sounds/ChaosBoonConfirm',

		TakeAllUses = 9,
	},

	PermafrostShield = {
		DamageCap = 35,
	},
	BubblingCauldron = {
		Cooldown = 0.1,
		ChanceMultiplier = 2,
	},
	BitterEnd = {
		InflictMultiplier = 1.50,
	},
	BlindingSmite = {
		BoltProjectile = 'SWuBlindingSmiteBolt',
		DazedMultiplier = 1.30,
		BoltDamage = 100,
		MinBolts = 1,
		MaxBolts = 5,

		BoltInterval = 0.12,
	},
	DifferentLeague = {
		DodgeBonus = 0.10,
		DamagePerDodge = 1.0,
		MissInterval = 0.25,
		MissDuration = 0.5,
		Radius = 430,
		NearbyExclusionBoon = 'AllCloseBoon',
	},
	ColdHearted = {
		Power = 25,
		HoldInterval = 0.2,
	},
	BoilingBlood = {
		HealPerPlasma = 1,

		DamagePerHit = 0.10,
		MaxBonus = 1.00,

		HeinousAffront = true,

		HitVfx = 'AresMelBuff',
		VfxMinScale = 0.35,
	},
	ConvectiveVortex = {
		ScorchPerHit = 25,
		DurationMultiplier = 1.5,

		InsideWindow = 0.4,

		RiftHue = 0.08,
		RiftColor = { Red = 1.0, Green = 0.45, Blue = 0.0 },

		RiftFx = {
			In = 'SWuConvectiveRiftIn',
			Spin = 'SWuConvectiveRiftSpin',
			Out = 'SWuConvectiveRiftOut',
			Particles = 'SWuConvectiveRiftParticles',
			Slice = 'SWuConvectiveRiftSlice',
			Shadow = 'SWuConvectiveRiftShadow',
			GlowRing = 'SWuConvectiveRiftGlowRing',
		},
	},
	BleedingHeart = {
		Blade = 'ProjectileAresSwordCast',
		MeterSource = 'SWuBleedingHeartBlade',

		BladeDamage = 200,
		WeakMultiplier = 1.50,
	},
	ExplosiveSparks = {
		Chance = 0.30,
		Damage = 100,
	},
	GlacialAdvance = {
		SwellChance = 0.25,
		SwellDamage = 60,
		SwellCooldown = 0,

		SwellProjectile = 'SWuGlacialSwell',
		SwellFx = {
			In = 'SWuGlacialSwellFxIn',
			Loop = 'SWuGlacialSwellFx',
			Dissipate = 'SWuGlacialSwellDissipateFx',
		},
		SwellHue = -0.05,
		SwellSaturation = -0.6,
		SwellValue = 0.15,
		SwellColor = { Red = 0.75, Green = 0.9, Blue = 1.0 },

		BonusDamage = 30,
		WaveScale = 1.0,
	},
	KindledSpirit = {
		DamagePerHealth = 20,
		HealOnHit = 3,
		Radius = 430,
		NearbyExclusionBoon = 'AllCloseBoon',
		HealthLossOnly = false,
		HeinousAffront = true,
	},
	VolcanicRift = {
		RiftProjectile = 'SWuVolcanicRift',
		FireballProjectile = 'SWuVolcanicRiftFireball',
		PuddleProjectile = 'SWuVolcanicRiftFire',
		FineLineProjectile = 'ProjectileHeraOmega',

		SprintTrail = false,
		CountsAsHestiaFireball = true,
		PuddlesScorch = false,

		FissureAnim = 'SWuVolcanicRiftFissure',
		FissureDetonateAnim = 'SWuVolcanicRiftFissureDetonate',
		FissureLineAnim = 'SWuVolcanicRiftFissureLine',
		FissureHue = 0.3,

		RiftDamage = 120,
		FireballDamage = 30,
		PuddleDamage = 20,
		PuddleInterval = 0.25,
		PuddleDuration = 3,

		SegmentLength = 400,
		RiftCooldown = 0.75,
		Fireballs = 5,
		FireballSpread = 800,

		AnchorLifetime = 3,

		FirePuddles = { 'HestiaSprintPuddle', 'SWuVolcanicRiftFire' },
	},
	NastyComeback = {
		HeinousAffront = false,
		HeinousAffrontDamage = 50,
		ReflectMultiplier = 100,
		ReflectCap = 9999,
		ShareDelay = 0.05,

		ReflectSource = 'SWuNastyComebackReflect',
	},
	GoldenRule = {
		DamagePerGold = 0.0005,
		MaxBonus = 1.00,
		Interest = 0.05,

		PollInterval = 0.5,
	},
	SpitefulStrength = {
		PrimeMana = 60,
		DamagePerPrimed = 1.00,
		UnscaledMultiplier = 2,
	},
	FamilyTrade = {
		Choices = 3,
		ExchangeLevelBonus = 3,
		AcquireDelay = 0.3,
		MaxPerSlot = 2,
	},
	BloodBorn = {
		Zombies = 5,
		SummonSpread = 150,
		SummonInterval = 0.08,
		ZombieEnemy = 'Zombie',
		ZombiePackages = { 'Zombie', 'BiomeN' },
		Hitch = true,

		MaxAlive = 10,

		DamagePerKill = 0.03,
		MaxBonus = 1.00,
	},
	RazorShoals = {
		RefreshDelay = 0.01,
	},
	StormFront = {
		BlitzDamage = 80,
		ScaleMultiplier = 1.30,
		BlitzInterval = 0.2,
		ApplyInterval = 1.0,
		SparkInterval = 0.2,
		SparkDamage = 20,

		Enlarged = {
			DemeterSprintStorm = 'SWuStormFrontSprintStorm',
			DemeterCastStorm = 'SWuStormFrontCastStorm',
			DemeterMiniStorm = 'SWuStormFrontMiniStorm',
			SWuWinterSolsticeGust = 'SWuStormFrontGust',
		},
	},
	PlasmicCapacitor = {
		BoltRange = 800,
		PlasmaMin = 1,
		PlasmaMax = 3,
		PlasmaMultiplier = 1.2,
		SparkPowerPerPlasma = 0.5,
		SparkPowerThreshold = 0,
		ArcDamage = 20,
		PlasmaSpawnCap = 50,
		PlasmaCeiling = 120,
	},
	SolarEclipse = {
		SpeedPerDazed = 0.05,
		MaxSpeedBonus = nil,
		DamagePerSpeed = 0.5,

		AltSpeedPerDazed = 0.10,
		AltMaxSpeedBonus = 0.50,
		DamageMultiplier = 2.00,
		Duration = 5,
		Recharge = 40,
		DarkSpeedBonus = 0.50,

		PollInterval = 0.15,

		AnnounceText = 'SWuSolarEclipse_CombatText',
		AnnounceDuration = 1.45,
		ReadySound = '/SFX/RevenantBeep',

		WarnCount = 3,
		WarnInterval = 1,
		WarnSound = '/SFX/HexEndingWarning',
		WarnFlash = true,
	},
	WinterSolstice = {
		TimeSlow = 0.70,

		FrostAmplifier = 1.50,

		HoldSeconds = 0.2,
		SlowVariant = 'Long',
		SlowVariants = {
			Long = { HoldSeconds = 0.2, SlowHoldSeconds = 2, SolsticeDuration = 2, SlowMinGap = 2 },
			Quick = { HoldSeconds = 0.5, SlowHoldSeconds = 0.5, SolsticeDuration = 1, SlowMinGap = 0.5 },
		},
		SlowCooldownEnabled = false,
		SlowCooldown = 8,
		SlowEndWarnNum = 3,
		SlowLoopSound = '/SFX/Player Sounds/TimeSlowLoop',
		SlowEndSfx = '/SFX/Player Sounds/TimeSlowEnd',
		SlowEndSound = '/VO/MelinoeEmotes/EmoteGasping',
		PollInterval = 0.05,

		SweepInterval = 0.25,
		ChillRefreshAt = 1.0,

		SquallEffect = 'DemeterTickEffect',
		SquallDamage = 20,
		SquallChillDelay = 0.2,
		SquallRadius = 806,
		SquallScaleY = 0.54,
		NearbyExclusionBoon = 'AllCloseBoon',

		RingFx = 'SWuWinterSolsticeCircle',
		RingRadius = 430,

		GustProjectile = 'SWuWinterSolsticeGust',
		GustRadius = 465,
		GustScale = 1.5,
		GustDamage = 12.5,
		GustLinger = 2,
		ChannelDecal = 'DemeterSprintStormFxGlow',
		ChannelDecalFlash = 'DemeterSprintStormFireFx',
	},
	SolarFlare = {
		Radius = 430,
		CatchScaleY = 0.5,
		LiftCeiling = false,
		Stoke = false,

		ScorchCap = 9999,

		PulseDelay = 0.2,
		PulseInterval = 0.5,

		FirstPulseScorch = 90,
		PulseScorch = 45,
		Expand = 2.00,
		ExpandTime = 2.5,

		RingProjectile = 'SWuSolarFlareRing',
		RingFx = 'SWuSolarFlareRingFx',
		RingFxScale = 1.0,

		ScorchBonus = 0.50,

		PulseFx = 'SWuSolarFlarePyreCircle',
		PulseFxScalesByRadius = true,

		PulseFxNova = 'SWuSolarFlareNova',
		PulseFxCircle = 'SWuSolarFlarePyreCircle',
		PulseFxScale = 1.6,
		PollInterval = 0.05,
		StokeMultiplier = 2,
	},
	TectonicCycle = {
		Interval = 40,
		TextDuration = 1.45,
	},
	BurntOffering = {
		ManaPerGold = 0.20,
		HealthPerGold = 0.20,
		FirstPurgeGold = 500,

		PurgeGoldMultiplier = 1.0,

		PurgesPerBiome = false,

		MinorFindMultiplier = 0.5,

		DemandDelay = 0.6,
	},
	IngeniousInvention = {
		EncountersPerHammer = 6,
		Debug = true,
	},
	RoyalBanquet = {
		PayHeroicPomLevels = false,
		HeroicPomLevels = 3,
	},
	OrbitalRing = {
		Scatter = 70,

		DamagePerCast = 0.30,
	},
	HotIron = {
		GlowMultiplier = 1.25,

		MaxStacks = 5,
		PowerPerStack = 10,
	},
	LandMine = {
		Recharge = 8,
		SeismicHammerReduction = 1,
		MinimumRecharge = 0.1,
		TriggerFuse = 0.6,
		FlashSpeed = 6,
		ReadySound = '/SFX/RevenantBeep',

		UseFixedManaCost = true,
		OmegaCastManaCost = 50,

		BlastProjectile = 'SWuLandMineBlast',
		BlastDamage = 500,
		BlastSize = 1.5,
	}, 
	EnergyOverflow = {
		BonusRestore = 0.30,
		MaxMana = 999,

		DripCeilingPerSecond = 10,
	},
	AirControl = {
		GuardProjectile = 'SWuAirControlGuard',
		BoltProjectile = 'SWuAirControlBolt',
		RingFx = 'SWuAirControlRingFx',
		RingRadius = 430,
		FlameFx = 'SWuAirControlFlames',

		BoltDamage = 120,
		BlockCooldown = 0,
		BlockVfx = 'HestiaFlameParticleDefense',
		BlockSound = '/SFX/BurnDamageSizzle',

		CastStartDelay = 0.1,

		SprintBuffVfx = 'HestiaFlameBuff',
		SprintLinger = 0.5,

		PollInterval = 0.02,
		PruneInterval = 0.1,

		InsideProjectileSpeed = 0.50,
		SlowZoneProjectile = 'SWuAirControlSlowZone',
	},
	TippedScales = {
		BaseFavor = 0.10,
		BoltDamage = 100,
		Range = 380,
		BoltProjectile = 'SWuTippedScalesBolt',
		BoltWindow = 2,
		BoltCooldown = 0.3,
		BoltFrames = 4,
	},
	DiscerningTaste = {
		Rerolls = 5,
		IgnoreArcana = true,
	},
	WishingWell = {
		OfferDelay = 0,

		VoiceLines = true,

		AcquireDelay = 0.5,

		ZagreusAllies = {
			{ Name = 'Sisyphus', Record = 'NPC_Sisyphus_01' },
			{ Name = 'Eurydice', Record = 'NPC_Eurydice_01' },
			{ Name = 'Patroclus', Record = 'NPC_Patroclus_01' },
			{ Name = 'Orpheus', Record = 'NPC_Orpheus_01' },
		},
		ZagreusJourney = 'NikkelM-Zagreus_Journey',

		DoorIcon = 'Keepsake_39',
		DoorIconScale = 0.35,
		DoorGlow = { 255, 194, 224, 255 },
	},
	FamilyReunion = {
		DropInterval = 0.35,
		ScatterRadius = 200,

		DuoBonus = 0.20,

		LegendaryRarityBonus = 0.10,
		DuoRarityBonus = 0.10,
	},
	IntertwinedFate = {
		NearbyOnly = true,

		RevengeSource = 'SWuIntertwinedFateRevenge',

		BindInterval = 0.3,

		NearbyRadius = 430,
		NearbyExclusionBoon = 'AllCloseBoon',
		NearbyDuration = 2,

		Ripple = false,
		ChainDelay = 0.15,
		PulseCooldown = 0.5,

		PulseDecal = false,
		PulseFx = 'SWuIntertwinedFateCircle',
		PulseFxAlpha = 0.5,

		SharePerHitched = 0.10,
		MaxBonus = 2.00,

		BindSummons = true,

		Revenge = false,
		RevengeMultiplier = 10,
		CapRevenge = false,
		RevengeCap = 999,
		RevengeOnLethal = true,

	},
	RoomTemperature = {
		FrozenBonusDamage = 100,

		ClearFreeze = true,
		ThawSeconds = 4,
	},
	GentleCaress = {
		CapArmor = true,
		HeinousAffront = false,

		ArmorCapFloor = 100,
	},
}
