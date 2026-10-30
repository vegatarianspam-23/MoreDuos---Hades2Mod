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

		OnEncounterStart = true,
		EncounterStartDelay = 0.5,
		EncounterFoeWait = 15,
		SwingLimit = 2.5,

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
				Entrance = {
					Animation = 'Heracles_Combat_Taunt',
					Height = 2500,
					Delay = 0.3,
					Force = 3500,
					Land = 0.5,
					Sound = '/SFX/Enemy Sounds/Heracles/EmotePowerCharging',
					LandFx = 'HydraTouchdownFx',
					LandSounds = {
						'/SFX/Enemy Sounds/Heracles/EmotePowerAttacking',
						'/SFX/Enemy Sounds/Polyphemus/PolyphemusGroundSlam',
					},
					LandShake = true,
				},
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
				Entrance = {
					Animation = 'Nemesis_Combat_Entrance',
					Height = 1500,
					Delay = 0.3,
					Force = 2000,
					Land = 0.6,
					Sound = '/SFX/Player Sounds/MelWhooshDropIn',
					Shake = true,
				},
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
				Packages = { 'Thanatos', 'ModsNikkelMHadesBiomesFxOriginal', 'NikkelM-HadesBiomesFxModded' },
				Voice = { Bank = { 'Thanatos', 'ThanatosField' } },
				NoBoss = true,
				WakeDelay = 0,
				Greet = true,
				GreetLines = 'EntranceVoiceLines',
				TargetReach = 1000,
				Weapons = {
					ThanatosDeathCurseAoE = {
						ForceFirst = true,
						MinAttacksBetweenUse = 0,
						Requirements = { MinAttacksBetweenUse = 0 },
					},
				},
				Entrance = {
					Fx = 'ThanatosTeleport',
					Delay = 0.2,
					FadeIn = 0.3,
					Sound = '/SFX/ThanatosEntranceSound',
					Land = 0.5,
				},
				Exit = {
					Animation = 'NPCThanatosExit',
					Fx = 'ThanatosTeleport',
					Wind = 0.1,
					Fade = 0.35,
				},
			},
			{
				Key = 'Megaera',
				Unit = 'Harpy',
				Requires = 'NikkelM-Zagreus_Journey',
				Traitor = true,
				DamageMultiplier = 30,
				Packages = { 'TartarusModsNikkelMHadesBiomes', 'ModsNikkelMHadesBiomesFxOriginal', 'NikkelM-HadesBiomesFxModded' },
				Voice = { Bank = 'MegaeraField' },
				BlockedIn = { 'BossHarpy1' },
				WakeDelay = 0,
				Greet = true,
				Clear = {
					'IsBoss', 'UseBossHealthBar', 'AIStages', 'AdditionalEnemySetupFunctionName',
					'OnDeathFunctionName', 'OnDeathFunctionArgs', 'KillEnemyEvents', 'FightStartGlobalVoiceLines',
					'BossPresentationUltraSuperPriorityIntroTextLineSets', 'BossPresentationIntroTextLineSets',
					'BossPresentationTextLineSets', 'ShrineMetaUpgradeName', 'ShrineDataOverwrites', 'DreamBiomeData',
					'SpawnOptions', 'SupportAIWeaponSetOptions', 'SupportUnitName',
				},
				Data = {
					AIOptions = { 'AttackerAI' },
					WeaponOptions = { 'HarpyLunge', 'HarpyWhipWhirl', 'HarpyLightning' },
					HideHealthBar = true,
					EncounterStartVoiceLines = {
						RandomRemaining = true,
						PreLineWait = 0.6,
						{ Cue = '/VO/MegaeraField_0401' },
						{ Cue = '/VO/MegaeraField_0085' },
						{ Cue = '/VO/MegaeraField_0086' },
						{ Cue = '/VO/MegaeraField_0114' },
						{ Cue = '/VO/MegaeraField_0116' },
					},
					ExitVoiceLines = {
						RandomRemaining = true,
						{ Cue = '/VO/MegaeraField_0662' },
						{ Cue = '/VO/MegaeraField_0133' },
						{ Cue = '/VO/MegaeraField_0296' },
					},
				},
				Entrance = {
					Animation = 'MegaeraMultiFurySkyDive',
					Height = 1500,
					Delay = 0.3,
					Force = 2500,
					Land = 0.5,
					LandShake = true,
				},
				Exit = {
					Animation = 'MegaeraMultiFuryTakeOff',
					Voice = true,
					Wind = 0.4,
					Rise = 1500,
					RiseTime = 0.2,
					Fade = 0.1,
				},
			},
			{
				Key = 'Bouldy',
				Unit = 'NPC_Bouldy_01',
				Requires = 'NikkelM-Zagreus_Journey',
				Packages = { 'Bouldy', 'BiomeI' },
				Voice = { Bank = 'Sisyphus' },
				Weight = 0.5,

				Callout = {
					Speaker = 'NPC_Sisyphus_01',
					SubtitleColor = { 109, 185, 116, 255 },
					Sets = {
						{
							Rooms = { 'A_Boss01', 'A_Boss02', 'A_Boss03' },
							Cues = { 'Sisyphus_0290', 'Sisyphus_0291', 'Sisyphus_0292', 'Sisyphus_0293', 'Sisyphus_0294', 'Sisyphus_0295' },
						},
						{
							Units = { 'Hecate', 'Eris' },
							Cues = { 'Sisyphus_0290', 'Sisyphus_0291', 'Sisyphus_0293', 'Sisyphus_0294', 'Sisyphus_0295' },
						},
						{
							Units = { 'NPC_Thanatos_Field_01' },
							Cues = { 'Sisyphus_0296', 'Sisyphus_0297', 'Sisyphus_0298', 'Sisyphus_0299', 'Sisyphus_0300' },
						},
						{
							Rooms = { 'D_Boss01' },
							Cues = { 'Sisyphus_0302', 'Sisyphus_0303', 'Sisyphus_0304', 'Sisyphus_0305', 'Sisyphus_0306', 'Sisyphus_0307' },
						},
						{
							Rooms = { 'CharonFight01' },
							Cues = { 'Sisyphus_0447', 'Sisyphus_0448', 'Sisyphus_0449', 'Sisyphus_0450', 'Sisyphus_0451', 'Sisyphus_0452' },
						},
						{
							Cues = {
								'Sisyphus_0268', 'Sisyphus_0269', 'Sisyphus_0272', 'Sisyphus_0273', 'Sisyphus_0274',
								'Sisyphus_0275', 'Sisyphus_0276', 'Sisyphus_0277', 'Sisyphus_0279', 'Sisyphus_0280',
								'Sisyphus_0282', 'Sisyphus_0283', 'Sisyphus_0284', 'Sisyphus_0285', 'Sisyphus_0310',
								'Sisyphus_0313', 'Sisyphus_0314', 'Sisyphus_0315',
							},
						},
					},
				},

				Drop = {
					Damage = 4000,
					Radius = 700,
					Reach = 900,

					Scale = 0.5,
					Height = 1000,
					Fall = 0.45,
					FallSound = '/Leftovers/SFX/MeteorStrikeQuiet',
					LandFx = 'UnitUnfrozen',
					LandSound = '/SFX/Explosion1',

					Delay = 2.5,

					LootDelay = 0,
					LootRange = 150,
					LootForceMin = 200,
					LootForceMax = 350,
					LootScale = 0.6,
					Loot = {
						{ Name = 'RoomMoneyTinyDrop', Count = 5, Overrides = { DropMoney = 10 } },
						{ Name = 'MetaCurrencyDrop', Count = 5, Overrides = { AddResources = { MetaCurrency = 20 } } },
						{ Name = 'HealDropMinor', Count = 5, Overrides = { HealFixed = 10 } },
					},

					Linger = 0,
					Fade = 0.15,
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
		StepInterval = 0.3,
		PercentPerStep = 0.01,
		MaxPercent = 1.00,
		DefensePerStep = 0.01,
		MaxDefense = 1.00,
		IncludeTraps = true,
		Radius = 430,
		NearbyExclusionBoon = 'AllCloseBoon',
		ExpireSound = '/SFX/WrathOver',
		ResetGrace = 5,
	},
	DifferentLeague = {
		DodgeBonus = 0.15,
		DamagePerDodge = 1.0,
		MissInterval = 0.25,
		MissDuration = 0.5,
		Radius = 430,
		NearbyExclusionBoon = 'AllCloseBoon',
	},
	ColdHearted = {
		Power = 10,
		PowerPerSecond = 10,
		FreezeMultiplier = 2,
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
		PrimeMana = 60,
		DamagePerPrimed = 1.00,
		UnscaledMultiplier = 2,
	},
	FamilyTrade = {
		Choices = 3,
		ExchangeLevelBonus = 3,
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

		InsideProjectileSpeed = 0.50,
		SlowZoneProjectile = 'SWuAirControlSlowZone',
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
		FrozenBonusDamage = 100,

		ClearFreeze = true,
		ThawSeconds = 4,
	},
	GentleCaress = {
		CapArmor = true,

		ArmorCapFloor = 100,
	},
}
