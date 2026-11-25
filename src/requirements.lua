---@meta _


DUO_ROLES = {
	SWuFireballTraits = { 'CastProjectileBoon', 'FireballManaSpecialBoon' },
	SWuGlowTraits = { 'MassiveKnockupBoon' },
	SWuHammerTraits = { 'HephaestusCastBoon' },
	SWuSplashBonusTraits = { 'PoseidonWeaponBoon', 'PoseidonSpecialBoon' },
}

local function Group(name) return { Group = name } end


function duo_roles_ensure()
	for name, base in pairs(DUO_ROLES) do
		if game.LinkedTraitData[name] == nil then
			game.LinkedTraitData[name] = game.ShallowCopyTable(base)
		end
	end
end


function duo_offer_sets(key)
	local spec = duo_requirements[key]
	if not spec or not spec.OneFromEachSet then return nil end

	local counts = spec.Counts or {}
	local sets = {}

	local offered = spec.OneFromEachSet

	for _, set in ipairs(offered) do
		if not (set.SkipIf and set.SkipIf()) then
			if set.Group then set = game.LinkedTraitData[set.Group] or {} end

			local picks = {}
			for _, traitName in ipairs(set) do
				local data = game.TraitData[traitName]
				local group = counts[traitName] and game.LinkedTraitData[counts[traitName]]
				if not (data and data.IsDuoBoon and not spec.AllowDuos) and (not counts[traitName] or (group and game.Contains(group, traitName))) then
					table.insert(picks, traitName)
				end
			end
			table.insert(sets, picks)
		end
	end

	return sets
end


duo_roles_ensure()


duo_requirements = {
	PermafrostShield = {
		Gods = { 'Demeter', 'Hephaestus' },
		OneFromEachSet = {
			{ "ReserveManaHitShieldBoon", "PlantHealthBoon", "BoonGrowthBoon" },
			{ "ArmorBoon", "HeavyArmorBoon", "EncounterStartDefenseBuffBoon", "ManaToHealthBoon" },
		}
	},

	BubblingCauldron = {
		Gods = { 'Hestia', 'Poseidon' },
		OneFromEachSet = {
			{ 'HestiaWeaponBoon', 'HestiaSpecialBoon', 'HestiaCastBoon' },
			{ 'PoseidonStatusBoon', 'PoseidonCastBoon' },
		}
	},

	BitterEnd = {
		Gods = { 'Ares', 'Demeter' },
		OneFromEachSet = {
			{ "AresStatusDoubleDamageBoon", "MissingHealthCritBoon", "LowHealthLifestealBoon" },
			{ "SlowExAttackBoon", "CastAttachBoon", "RootDurationBoon" },
			{ "AresWeaponBoon", "AresSpecialBoon", "DemeterWeaponBoon", "DemeterSpecialBoon" },
		}
	},

	BlindingSmite = {
		Gods = { 'Apollo', 'Zeus' },
		OneFromEachSet = {
			{ "ApolloCastBoon", "ApolloSprintBoon", "ApolloRetaliateBoon", "BlindChanceBoon" },
			{ "BoltRetaliateBoon", "ZeusManaBoltBoon", "CastAnywhereBoon" },
		},
	},

	DifferentLeague = {
		Gods = { 'Apollo', 'Aphrodite' },
		OneFromEachSet = {
			{ "AphroditeWeaponBoon", "AphroditeSpecialBoon", "AphroditeManaBoon" },
			game.LinkedTraitData.ApolloBlindTraits,
		}
	},

	ColdHearted = {
		Gods = { 'Aphrodite', 'Demeter' },
		OneFromEachSet = {
			{ "AphroditeCastBoon", "AphroditeSprintBoon", "AphroditeManaBoon", },
			{ "DemeterWeaponBoon", "DemeterSpecialBoon", "DemeterCastBoon" }
		},
	},

	GoldenRule = {
		Gods = { 'Hera', 'Poseidon' },
		OneFromEachSet = {
			{ "DoubleRewardBoon", "RoomRewardBonusBoon" },
			{ "BoonDecayBoon", "CommonGlobalDamageBoon", "DamageShareRetaliateBoon" }
		}
	},

	BoilingBlood = {
		Gods = { 'Ares', 'Hestia' },
		OneFromEachSet = {
			game.LinkedTraitData.AresBloodDropTraits,
			{ "BurnExplodeBoon", "BurnArmorBoon", "AloneDamageBoon" },
		},
	},

	ConvectiveVortex = {
		Gods = { 'Ares', 'Hestia' },
		OneFromEachSet = {
			{ "AresExCastBoon", "zerp-More_Dash_Boons-AresBlinkTrailBoon", "SWuBloodyBlinkBoon" },
			{ "HestiaWeaponBoon", "HestiaSpecialBoon", "HestiaCastBoon" },
		},
	},

	BleedingHeart = {
		Gods = { 'Ares', 'Aphrodite' },
		OneFromEachSet = {
			{ "AresWeaponBoon", "AresSpecialBoon", "RendBloodDropBoon" },
			{ "AphroditeCastBoon", "AphroditeSprintBoon", "AphroditeManaBoon", }
		},
		Counts = { RendBloodDropBoon = 'AresSwordTraits' },
	},

	ExplosiveSparks = {
		Gods = { 'Hephaestus', 'Zeus' },
		OneFromEachSet = {
			{ "ZeusWeaponBoon", "ZeusSpecialBoon", "ZeusCastBoon", "ZeusSprintBoon", "ZeusManaBoon" },
			Group('SWuHammerTraits'),
		},
	},

	GlacialAdvance = {
		Gods = { 'Poseidon', 'Demeter' },
		OneFromEachSet = {
			{ "PoseidonWeaponBoon", "PoseidonSpecialBoon", "PoseidonSprintBoon" },
			{ "OmegaPoseidonProjectileBoon" },
			{ "DemeterWeaponBoon", "DemeterSpecialBoon", "DemeterCastBoon", "DemeterSprintBoon", "DemeterManaBoon" },
		},
	},

	GlacialAdvanceAlt = {
		Gods = { 'Poseidon', 'Demeter' },
		OneFromEachSet = {
			{ "DemeterWeaponBoon", "DemeterSpecialBoon", "DemeterCastBoon" },
			Group('PoseidonSplashTraits'),
		},
	},

	KindledSpirit = {
		Gods = { 'Aphrodite', 'Hestia' },
		OneFromEachSet = {
			{ "HealthRewardBonusBoon", "FocusRawDamageBoon", "HighHealthOffenseBoon" },
			{ "BurnExplodeBoon", "BurnArmorBoon", "AloneDamageBoon" },
		}
	},

	RoomTemperature = {
		Gods = { 'Hestia', 'Demeter' },
		OneFromEachSet = {
			{ "DemeterWeaponBoon", "DemeterSpecialBoon", "DemeterCastBoon" },
			Group('SWuFireballTraits'),
		},
	},

	IntertwinedFate = {
		Gods = { 'Aphrodite', 'Hera' },
		OneFromEachSet = {
			{ "LinkedDeathDamageBoon", "DamageSharePotencyBoon", "SpawnCastDamageBoon" },
			{ "AphroditeWeaponBoon", "AphroditeSpecialBoon", "AphroditeManaBoon" },
		},
		Counts = { SpawnCastDamageBoon = 'HeraLinkTraits' },
	},

	NastyComeback = {
		Gods = { 'Hera', 'Hephaestus' },
		OneFromEachSet = {
			{ "HeraWeaponBoon", "HeraSpecialBoon", "HeraCastBoon", "HeraSprintBoon", "HeraManaBoon" },
			{ "HephaestusWeaponBoon", "HephaestusSpecialBoon", "HephaestusCastBoon", "HephaestusSprintBoon", "HephaestusManaBoon" },
		},
	},

	SpitefulStrength = {
		Gods = { 'Hera', 'Hephaestus' },
		OneFromEachSet = {
			{ "HeraWeaponBoon", "HeraSpecialBoon", "HeraCastBoon", "HeraSprintBoon", "HeraManaBoon" },
			{ "HephaestusWeaponBoon", "HephaestusSpecialBoon", "HephaestusCastBoon", "HephaestusSprintBoon", "HephaestusManaBoon" },
			{ "FocusDamageShaveBoon", "FocusLightningBoon", "FocusRawDamageBoon",
				"FocusCritBoon", "FocusSpecialDamageTrait", "FocusAttackDamageTrait", "FocusLastStandBoon", "ArmorBoon" },
		}
	},

	BloodBorn = {
		Gods = { 'Hera', 'Ares' },
		OneFromEachSet = {
			{ "AresStatusDoubleDamageBoon", "MissingHealthCritBoon", "LowHealthLifestealBoon" },
			{ "DamageSharePotencyBoon", "LinkedDeathDamageBoon", "SpawnCastDamageBoon" },
		},
		Counts = { SpawnCastDamageBoon = 'HeraLinkTraits' },
	},

	RazorShoals = {
		Gods = { 'Ares', 'Poseidon' },
		OneFromEachSet = {
			{ "PoseidonCastBoon", "PoseidonStatusBoon" },
			{ "AresWeaponBoon", "AresSpecialBoon", }
		}
	},

	StormFront = {
		Gods = { 'Zeus', 'Demeter' },
		OneFromEachSet = {
			{ "CastNovaBoon", "DemeterSprintBoon" },
			{ "BoltRetaliateBoon", "ZeusManaBoltBoon", "CastAnywhereBoon" },
		},
	},

	StormFrontAlt = {
		Gods = { 'Zeus', 'Demeter' },
		OneFromEachSet = {
			{ "CastNovaBoon", "DemeterSprintBoon" },
			{ "ZeusWeaponBoon", "ZeusSpecialBoon" },
		},
	},

	PlasmicCapacitor = {
		Gods = { 'Ares', 'Zeus' },
		OneFromEachSet = {
			game.LinkedTraitData.AresBloodDropTraits,
			{ "BoltRetaliateBoon", "ZeusManaBoltBoon", "CastAnywhereBoon" },
		},
	},

	PlasmicCapacitorAlt = {
		Gods = { 'Ares', 'Zeus' },
		OneFromEachSet = {
			game.LinkedTraitData.AresBloodDropTraits,
			{ "ZeusWeaponBoon", "ZeusSpecialBoon" },
		},
	},

	PlasmicCapacitorAlt2 = {
		Gods = { 'Ares', 'Zeus' },
		OneFromEachSet = {
			game.LinkedTraitData.AresBloodDropTraits,
			{ "FocusLightningBoon" },
		},
	},

	SolarEclipse = {
		Gods = { 'Apollo', 'Ares' },
		OneFromEachSet = {
			game.LinkedTraitData.ApolloBlindTraits,
			game.LinkedTraitData.AresBloodDropTraits,
		},
	},

	SolarEclipseAlt = {
		Gods = { 'Apollo', 'Ares' },
		OneFromEachSet = {
			{ "ApolloCastBoon", "ApolloSprintBoon", "BlindChanceBoon", "ApolloRetaliateBoon" },
			{ "AresStatusDoubleDamageBoon", "MissingHealthCritBoon", "LowHealthLifestealBoon" },
		},
	},

	WinterSolstice = {
		Gods = { 'Apollo', 'Demeter' },
		OneFromEachSet = {
			{ "DemeterWeaponBoon", "DemeterSpecialBoon", "DemeterCastBoon", "DemeterSprintBoon", "DemeterManaBoon" },
			{ "ApolloWeaponBoon", "ApolloSpecialBoon", "ApolloCastBoon", "ApolloSprintBoon", "ApolloManaBoon" },
		}
	},

	WinterSolsticeAlt = {
		Gods = { 'Apollo', 'Demeter' },
		OneFromEachSet = {
			{ "DemeterWeaponBoon", "DemeterSpecialBoon", "DemeterCastBoon", "DemeterSprintBoon", "DemeterManaBoon" },
			{ "ApolloWeaponBoon", "ApolloSpecialBoon", "ApolloCastBoon", "ApolloSprintBoon", "ApolloManaBoon" },
		}
	},

	SolarFlare = {
		Gods = { 'Apollo', 'Hestia' },
		OneFromEachSet = {
			{ "HestiaWeaponBoon", "HestiaSpecialBoon", "HestiaCastBoon" },
			{ "ApolloWeaponBoon", "ApolloSpecialBoon", "ApolloCastBoon", "ApolloSprintBoon", "ApolloManaBoon" },
		},
	},

	TectonicCycle = {
		Gods = { 'Hephaestus', 'Poseidon' },
		OneFromEachSet = {
			{ "PoseidonWeaponBoon", "PoseidonSpecialBoon", "PoseidonCastBoon", "PoseidonSprintBoon", "PoseidonManaBoon" },
			{ "HephaestusCastBoon", "HephaestusSprintBoon", "HephaestusManaBoon" },
			{ "EncounterStartDefenseBuffBoon", "EncounterStartOffenseBuffBoon" },
		},
	},

	BurntOffering = {
		Gods = { 'Hera', 'Hestia' },
		OneFromEachSet = {
			{ "BoonDecayBoon", "CommonGlobalDamageBoon", "DamageShareRetaliateBoon" },
			{ "BurnExplodeBoon", "BurnArmorBoon", "AloneDamageBoon" },
		},
	},

	SacrosanctAlms = {
		Gods = { 'Hermes', 'Hera' },
		OneFromEachSet = {
			{ "BoonDecayBoon", "CommonGlobalDamageBoon", "DamageShareRetaliateBoon" },
			{ "MoneyMultiplierBoon", "RestockBoon" },
		},
	},

	GildedHook = {
		Gods = { 'Hermes', 'Poseidon' },
		OneFromEachSet = {
			{ "MoneyMultiplierBoon", "RestockBoon" },
		},
	},

	RoyalBanquet = {
		Gods = { 'Hera', 'Demeter' },
		OneFromEachSet = {
			{ "BoonDecayBoon", "CommonGlobalDamageBoon", "DamageShareRetaliateBoon" },
			game.LinkedTraitData.DemeterCoreTraits,
		}
	},

	IngeniousInvention = {
		Gods = { 'Apollo', 'Hephaestus' },
		OneFromEachSet = {
			{ "ApolloCastAreaBoon", "PerfectDamageBonusBoon", "DoubleStrikeChanceBoon", "ApolloExCastBoon" },
			{ "HeavyArmorBoon", "ArmorBoon", "EncounterStartDefenseBuffBoon", "ManaToHealthBoon" }
		},
	},

	OrbitalRing = {
		Gods = { 'Apollo', 'Hera' },
		OneFromEachSet = {
			{ "DamageSharePotencyBoon", "LinkedDeathDamageBoon", "SpawnCastDamageBoon" },
			{ "ApolloCastAreaBoon", "PerfectDamageBonusBoon", "DoubleStrikeChanceBoon", "ApolloExCastBoon" },
		},
		Counts = { SpawnCastDamageBoon = 'HeraLinkTraits' },
	},

	HotIron = {
		Gods = { 'Hephaestus', 'Hestia' },
		OneFromEachSet = {
			Group('SWuGlowTraits'),
			game.LinkedTraitData.HestiaCoreTraits,
		},
	},
	HotIronAlt = {
		Gods = { 'Hephaestus', 'Hestia' },
		OneFromEachSet = {
			Group('SWuGlowTraits'),
			Group('SWuFireballTraits'),
		},
	},

	VolcanicRift = {
		Gods = { 'Hera', 'Hestia' },
		OneFromEachSet = {
			{ "OmegaHeraProjectileBoon", "zerp-More_Dash_Boons-HeraBlinkTrailBoon", "SWuSwornBlinkBoon" },
			{ "HestiaSprintBoon", "AloneDamageBoon" },
		},
	},

	LandMine = {
		Gods = { 'Hephaestus', 'Ares' },
		OneFromEachSet = {
			{ "HephaestusWeaponBoon", "HephaestusSpecialBoon" },
			{ "AresStatusDoubleDamageBoon", "MissingHealthCritBoon", "LowHealthLifestealBoon" }
		}
	},

	EnergyOverflow = {
		Gods = { 'Apollo', 'Poseidon' },
		OneFromEachSet = {
			{ "ApolloCastAreaBoon", "PerfectDamageBonusBoon", "DoubleStrikeChanceBoon", "ApolloExCastBoon" },
			{ "RoomRewardBonusBoon", "DoubleRewardBoon" },
		},
	},

	GentleCaress = {
		Gods = { 'Hephaestus', 'Aphrodite' },
		OneFromEachSet = {
			{ "FocusRawDamageBoon", "HealthRewardBonusBoon", "HighHealthOffenseBoon" },
			{ "HeavyArmorBoon", "ArmorBoon", "EncounterStartDefenseBuffBoon", "ManaToHealthBoon" }
		}
	},

	FamilyTrade = {
		Gods = { 'Hera', 'Zeus' },
		AllowDuos = true,
		OneFromEachSet = {
			{ "SuperSacrificeBoonZeus", "SuperSacrificeBoonHera" },
		},
	},

	FamilyReunion = {
		Gods = { 'Hera', 'Zeus' },
		OneFromEachSet = {
			{ "DamageShareRetaliateBoon", "BoonDecayBoon", "CommonGlobalDamageBoon" },
			{ "CastAnywhereBoon", "BoltRetaliateBoon", "ZeusManaBoltBoon" },
		},
	},

	AirControl = {
		Gods = { 'Hestia', 'Zeus' },
		OneFromEachSet = {
			{ "BoltRetaliateBoon", "ZeusManaBoltBoon", "CastAnywhereBoon" },
			{ "HestiaCastBoon", "HestiaSprintBoon" }
		}
	},

	WishingWell = {
		Gods = { 'Aphrodite', 'Poseidon' },
		OneFromEachSet = {
			{ "RoomRewardBonusBoon", "DoubleRewardBoon" },
			{ "HighHealthOffenseBoon", "FocusRawDamageBoon", "HealthRewardBonusBoon" }
		}
	},

	DiscerningTaste = {
		Gods = { 'Aphrodite', 'Zeus' },
		OneFromEachSet = {
			{ "HighHealthOffenseBoon", "FocusRawDamageBoon", "HealthRewardBonusBoon" },
			{ "BoltRetaliateBoon", "ZeusManaBoltBoon", "CastAnywhereBoon" },
			{ "DoorRerollMetaUpgrade", "PanelRerollMetaUpgrade", SkipIf = function() return mod.tuning.DiscerningTaste.IgnoreArcana == true end },
		}
	},

	TippedScales = {
		Gods = { 'Poseidon', 'Zeus' },
		OneFromEachSet = {
			{ "DoubleRewardBoon", "RoomRewardBonusBoon" },
			{ "BoltRetaliateBoon", "ZeusManaBoltBoon", "CastAnywhereBoon" }
		}
	},
}


canon_requirements = {
	StormSpawnBoon = {
		Set = { OneFromEachSet = {
			{ "ApolloCastAreaBoon", "PerfectDamageBonusBoon", "DoubleStrikeChanceBoon" },
			{ "DemeterSprintBoon", "CastNovaBoon" },
		} },
	},

	GoodStuffBoon = {
		Set = { OneFromEachSet = {
			{ "RoomRewardBonusBoon", "DoubleRewardBoon" },
			{ "PlantHealthBoon", "BoonGrowthBoon", "ReserveManaHitShieldBoon" },
		} },
	},

	MaxHealthDamageBoon = {
		Set = { OneFromEachSet = {
			{ "HealthRewardBonusBoon", "FocusRawDamageBoon", "HighHealthOffenseBoon" },
			{ "PlantHealthBoon", "ReserveManaHitShieldBoon", "BoonGrowthBoon" },
		} },
	},

	BurnArmorBoon = {
		Set = false,
	},

	KeepsakeLevelBoon = {
		Set = { OneFromEachSet = {
			{ "ReserveManaHitShieldBoon", "PlantHealthBoon", "BoonGrowthBoon" },
			{ "HeraWeaponBoon", "HeraSpecialBoon", "HeraCastBoon", "HeraSprintBoon", "HeraManaBoon" },
		} },
	},
}


function canon_sync_requirements()
	mod.CanonRequirementBase = mod.CanonRequirementBase or {}
	local base = mod.CanonRequirementBase

	for traitName, rework in pairs(canon_requirements) do
		if base[traitName] == nil then
			base[traitName] = game.TraitRequirements[traitName] or false
		end

		if config.enabled ~= false then
			game.TraitRequirements[traitName] = rework.Set and game.DeepCopyTable(rework.Set) or nil
		else
			game.TraitRequirements[traitName] = base[traitName] or nil
		end
	end
end
