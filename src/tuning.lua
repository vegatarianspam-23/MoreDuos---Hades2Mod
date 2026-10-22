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
			'SWuVolcanicCrownFireball', 'SWuVolcanicFireball',
		},
	},

	MovementSpeed = {
		Cap = 1.00,
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

	DistressCall = {
		Duration = 8,
		Cooldown = 40,

		NominalHealth = 1,

		AllowInBoss = true,
		FocusBoss = true,

		TargetReach = 9999,

		BossProjectile = {
			ImpactLineOfSight = false,
			CheckObstacleImpact = false,
			MaxVictimZ = 9999,
		},

		Allies = {
			{
				Key = 'Heracles',
				Unit = 'NPC_Heracles_01',
				BlockedBy = 'Heracles',
				WakeDelay = 0,
				Haste = 1.25,
				Packages = { 'Heracles' },
				Voice = { Bank = 'Heracles' },
				Greet = true,
				Exit = {
					Animation = 'Heracles_Combat_LeapExit',
					Voice = true,
					Wind = 0.62,
					Rise = 2000,
					RiseTime = 0.2,
					Fade = 0.1,
					Shake = true,
				},
			},
			{
				Key = 'Nemesis',
				Unit = 'NPC_Nemesis_01',
				Variant = 'NemesisCombat',
				WakeDelay = 0,
				Packages = { 'Nemesis' },
				Voice = { Bank = 'Nemesis' },
				Greet = true,
				Exit = {
					Animation = 'Nemesis_Hub_Exit',
					Voice = true,
					Wind = 0.92,
					Rise = 1000,
					RiseTime = 0.2,
					Fade = 0.1,
				},
			},
			{
				Key = 'Icarus',
				Unit = 'NPC_Icarus_01',
				Variant = 'IcarusCombat',
				Packages = { 'Icarus', 'NPC_Icarus_01' },
				Voice = { Bank = 'Icarus' },
				Greet = true,
				Invisible = true,
				WakeDelay = 0,
				SpawnAt = { 'CameraClamp' },

				Weapons = {
					IcarusBombardmentLine = {
						TargetSpawnPoints = false,
						TargetRequiredKillEnemy = true,
						TargetClosestToPlayer = true,

						PostAttackCooldownMin = 1.5,
						PostAttackCooldownMax = 1.5,
						Requirements = { MinAttacksBetweenUse = 0 },
					},
					IcarusBombardmentSingle = {
						TargetClosestToPlayer = true,

						PostAttackCooldownMin = 0.8,
						PostAttackCooldownMax = 1.2,
					},
				},

				Exit = {
					Cycles = 3,
					Grace = 1.0,
					Settle = 0.5,
					Animation = 'Icarus_FlyExit_TakeOff',
					Voice = true,
					Wind = 0.36,
					Rise = 800,
					RiseTime = 0.22,
					Fade = 0.11,
				},
			},
			{
				Key = 'Hades',
				Unit = 'NPC_Hades_Field_01',
				Packages = { 'NPC_Hades_Field_01', 'Hades' },
				Voice = { Bank = 'Hades' },
				BossOnly = true,
				Weight = 0.5,

				Grudge = {
					Fraction = 0.20,
					Delay = 1.0,

					Effect = 'HadesInvisible',
					Multiplier = 1.5,

					DamageSourceName = 'HadesPreDamageBoon',
					Presentation = 'HadesPreDamagePresentation',
					Text = 'PreDamageHit_Hades',
					VoiceLines = 'HadesCurseVoiceLines',
				},
			},
			{
				Key = 'Dionysus',
				Unit = 'NPC_Dionysus_01',
				Packages = { 'NPC_Dionysus_01', 'Dionysus' },
				Voice = { Bank = 'Dionysus' },

				Revel = {
					Ball = '3DDiscoBall_SkipEncounter',
					Chain = 'OlympusCeilingChain01',
					Reflections = 'DiscoBallReflections_SkipEncounter',
					ChainScale = 0.51,
					ChainOffset = -97,
					Height = 1200,
					Drop = -650,
					DropAlt = -525,

					Sound = '/SFX/DionysusBoonWineLaugh',
					Music = '/Music/MusicPlayer/Iris/DionysusMusicMusicPlayer',
					EndSound = '/SFX/Menu Sounds/RecordScratch',

					Fog = 'DionysusField',
					Clouds = 18,
					MinGap = 750,
					Spread = 2800,
					SpreadY = 0.6,
					Refresh = 4.0,
					Drift = 137.5,

					Hangover = 'DamageOverTime',
					Damage = 50,
					Radius = 400,
					Sweep = 0.5,

					Drink = 'PowerDrinkDrop',
					Drinks = 2,
					DrinkMin = 700,
					DrinkVfx = 'BoonDropFrontFlare',
					DrinkSound = '/SFX/Menu Sounds/KeepsakeEurydiceAcorn',
				},
			},
			{
				Key = 'Athena',
				Unit = 'NPC_Athena_01',
				Packages = { 'NPC_Athena_01', 'Athena' },
				Voice = { Bank = 'Athena' },
				NoBoss = true,
				Weight = 0.5,

				Smite = {
					Nova = 'AthenaLandingNova',
					Sound = '/SFX/AthenaWrathHolyShield',
					Damage = 9999,

					Descend = 1.2,
					Interval = 0.01,
					Linger = 0.7,

					Entrance = 'Athena_Leap_Entrance',
					Departure = 'Athena_Leap_Exit',
					Height = 2000,
				},
			},
			{
				Key = 'Artemis',
				Unit = 'NPC_Artemis_Field_01',
				Packages = { 'Artemis', 'NPC_Artemis_Field_01' },
				Voice = { Bank = 'Artemis', From = 'NPC_Artemis_01' },
				Greet = true,
				Invisible = 'Artemis_Invisible',
				WakeDelay = 0,
				SpawnAt = { 'ArtemisSpawnPoints', 'HeroStart', 'CameraClamp' },
				SpawnAtEntrance = 'ArtemisUseHeroStart',

				Weapons = {
					ArtemisSniper = {
						PreAttackDuration = 0.6,
						FireDuration = 0.15,
						PostAttackDurationMin = 0.7,
						PostAttackDurationMax = 0.85,
					},
					ArtemisHuntersMark = {
						PreAttackDuration = 0.3,
						PostAttackDurationMin = 0.7,
						PostAttackDurationMax = 0.9,
					},
				},

				Exit = {
					Cycles = 4,
					Grace = 1.0,
					Settle = 0.5,
					Voice = true,
					Wind = 0.4,
					Fade = 0.1,
				},
			},
			{
				Key = 'Thanatos',
				Unit = 'NPC_Thanatos_Field_01',
				Requires = 'NikkelM-Zagreus_Journey',
				Packages = { 'Thanatos' },
				NoBoss = true,
				WakeDelay = 0,
				Greet = true,
				Exit = {
					Animation = 'NPCThanatosExit',
					Fx = 'ThanatosTeleport',
					Wind = 0.1,
					Fade = 0.35,
				},
			},
		},
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
		DazedMultiplier = 1.30,
		BoltDamage = 100,
		MinBolts = 1,
		MaxBolts = 5,

		BoltInterval = 0.12,
	},
	UntouchableGlow = {
		PercentPerSecond = 0.01,
		MaxPercent = 1.00,
		Radius = 430,
	},
	ColdHearted = {
		Power = 50,
		PowerPerSecond = 10,
		FreezeExtension = 4,
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

		BladeDamage = 200,
		WeakMultiplier = 1.30,
	},
	ExplosiveSparks = {
		Chance = 0.30,
		Damage = 100,
	},
	GlacialAdvance = {
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
	VolcanicCrown = {
		EmberProjectile = 'SWuVolcanicEmber',
		BlastProjectile = 'SWuVolcanicBlast',
		FireballProjectile = 'SWuVolcanicFireball',

		Fireballs = 6,
		FireballDamage = 120,
		CentreDamage = 500,
		CentreScale = 1.0,
		BlastDelay = 0.3,
		CoalDamage = 100,
		EmberDuration = 6,
		EmberRefresh = 2,

		BlastSize = 1.5,
		EmberSize = 1.5,

		FireballSize = 1.5,

		CastRadius = 430,

		BlastRadius = 330,
		EmberRadius = 200,
	},
	WrathfulHubris = {
		DamageDealt = 0.50,
		DamageTaken = 0.50,
	},
	GoddessSpite = {
		ReflectMultiplier = 100,
		ReflectCap = 9999,

		ReflectSource = 'SWuGoddessSpiteReflect',
	},
	GoldenRule = {
		DamagePerGold = 0.0005,
		MaxBonus = 1.00,
		Interest = 0.05,

		PollInterval = 0.5,
	},
	SpitefulStrength = {
		PrimeMana = 50,
		DamagePerPrimed = 1.00,
	},
	FamilyTrade = {
		Choices = 3,
		ExchangeLevelBonus = 4,
		AcquireDelay = 0.3,
	},
	BloodBorn = {
		Zombies = 5,
		SummonSpread = 150,
		SummonInterval = 0.08,
		ZombieEnemy = 'Zombie',
		ZombiePackages = { 'Zombie', 'BiomeN' },
		Hitch = true,

		MaxAlive = 10,

		DamagePerKill = 0.02,
		MaxBonus = 1.00,
	},
	RazorShoals = {
		RefreshDelay = 0.1,
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
		DamageMultiplier = 2.00,
		Duration = 5,
		Recharge = 30,

		SpeedPerDazed = 0.05,
		MaxSpeedBonus = 0.50,
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
		GlowMultiplier = 1.30,
		GlowOnly = true,
	},
	GlowingBrand = {
		GlowPotency = 2.0,
		GlowDuration = 2.0,

		BrandFx = 'SWuBrandDecal',
		BrandFxPulse = 'SWuBrandDecalPulse',
		BrandFxOut = 'SWuBrandDecalOut',
		BrandFxSize = 1.2,
		BrandFxGroup = 'FX_Terrain',
		BrandColor = { Red = 1.0, Green = 0.85, Blue = 0.0 },
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

		BoltDamage = 120,
		BlockCooldown = 0,

		CastStartDelay = 0.1,

		SprintBuffVfx = 'HestiaFlameBuff',
		SprintLinger = 0.5,

		PollInterval = 0.02,

		ProjectileSpeed = 0.25,
	},
	TippedScales = {
		FavorPerMiss = 0.03,
		BaseFavor = 0.10,
		MaxFavor = 1.00,
	},
	DiscerningTaste = {
		Rerolls = 5,
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

		BindInterval = 1,

		NearbyRadius = 430,
		NearbyExclusionBoon = 'AllCloseBoon',
		NearbyDuration = 2,

		ChainDelay = 0.15,
		PulseCooldown = 0.5,

		PulseFx = 'SWuIntertwinedFateCircle',
		PulseFxAlpha = 0.5,

		SharePerHitched = 0.10,
		AltDamagePerHitched = 0.05,
		AltMaxBonus = 1.00,
		MaxBonus = 2.00,

		BindSummons = true,

		Revenge = false,
		RevengeMultiplier = 10,
		CapRevenge = false,
		RevengeCap = 999,
		RevengeOnLethal = true,

	},
	RoomTemperature = {
		FrozenBonusDamage = 200,

		ClearFreeze = true,
		ThawSeconds = 4,
	},
	GentleCaress = {
		CapArmor = true,

		ArmorCapFloor = 100,
	},
}
