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

	for i, set in ipairs(offered) do
		if set.Group then set = game.LinkedTraitData[set.Group] or {} end

		sets[i] = {}
		for _, traitName in ipairs(set) do
			local data = game.TraitData[traitName]
			local group = counts[traitName] and game.LinkedTraitData[counts[traitName]]
			if not (data and data.IsDuoBoon and not spec.AllowDuos) and (not counts[traitName] or (group and game.Contains(group, traitName))) then
				table.insert(sets[i], traitName)
			end
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

	UntouchableGlow = {
		Gods = { 'Apollo', 'Aphrodite' },
		OneFromEachSet = {
			{ "AphroditeWeaponBoon", "AphroditeSpecialBoon", "AphroditeManaBoon" },
			{ "ApolloCastAreaBoon", "PerfectDamageBonusBoon", "DoubleStrikeChanceBoon" }
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
			{ "AresExCastBoon" },
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
			{ "AphroditeWeaponBoon", "AphroditeSpecialBoon"},
		},
		Counts = { SpawnCastDamageBoon = 'HeraLinkTraits' },
	},

	IntertwinedFateAlt = {
		Gods = { 'Aphrodite', 'Hera' },
		OneFromEachSet = {
			{ "LinkedDeathDamageBoon", "DamageSharePotencyBoon", "SpawnCastDamageBoon" },
			{ "AphroditeWeaponBoon", "AphroditeSpecialBoon" },
		},
		Counts = { SpawnCastDamageBoon = 'HeraLinkTraits' },
	},

	GoddessSpite = {
		Gods = { 'Aphrodite', 'Hera' },
		OneFromEachSet = {
			{ "LinkedDeathDamageBoon", "DamageSharePotencyBoon", "SpawnCastDamageBoon" },
			{ "AphroditeWeaponBoon", "AphroditeSpecialBoon" },
		},
		Counts = { SpawnCastDamageBoon = 'HeraLinkTraits' },
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

	WrathfulHubris = {
		Gods = { 'Hera', 'Ares' },
		OneFromEachSet = {
			{ "HeraWeaponBoon", "HeraSpecialBoon", "HeraCastBoon", "HeraSprintBoon", "HeraManaBoon" },
			{ "AresWeaponBoon", "AresSpecialBoon", "AresCastBoon", "AresSprintBoon", "AresManaBoon" },
		},
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
			{ "FocusLightningBoon" },
		},
	},

	PlasmicCapacitorAlt = {
		Gods = { 'Ares', 'Zeus' },
		OneFromEachSet = {
			game.LinkedTraitData.AresBloodDropTraits,
			{ "ZeusWeaponBoon", "ZeusSpecialBoon" },
		},
	},

	SolarEclipse = {
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
			{ "ApolloCastAreaBoon", "PerfectDamageBonusBoon", "DoubleStrikeChanceBoon" },
			{ "HeavyArmorBoon", "ArmorBoon", "EncounterStartDefenseBuffBoon", "ManaToHealthBoon" }
		},
	},

	OrbitalRing = {
		Gods = { 'Apollo', 'Hera' },
		OneFromEachSet = {
			{ "DamageSharePotencyBoon", "LinkedDeathDamageBoon", "SpawnCastDamageBoon" },
			{ "ApolloCastAreaBoon", "DoubleStrikeChanceBoon", "ApolloRetaliateBoon" },
		},
		Counts = { SpawnCastDamageBoon = 'HeraLinkTraits' },
	},

	GlowingBrand = {
		Gods = { 'Hephaestus', 'Hestia' },
		OneFromEachSet = {
			Group('SWuGlowTraits'),
			Group('SWuFireballTraits'),
		},
	},

	HotIron = {
		Gods = { 'Hephaestus', 'Hestia' },
		OneFromEachSet = {
			Group('SWuGlowTraits'),
			Group('SWuFireballTraits'),
		},
	},

	VolcanicCrown = {
		Gods = { 'Hephaestus', 'Hestia' },
		OneFromEachSet = {
			{ "HephaestusWeaponBoon", "HephaestusSpecialBoon" },
			Group('SWuFireballTraits'),
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
			{ "ApolloCastAreaBoon", "DoubleStrikeChanceBoon", "ApolloRetaliateBoon" },
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
