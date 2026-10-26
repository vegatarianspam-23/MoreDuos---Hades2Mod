---@meta _


blessing_text = {
	SWuPandemoniumBlessing = {
		DisplayName = 'Pandemonium',
		Description = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor ' ..
			'incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis ' ..
			'nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. ' ..
			'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu ' ..
			'fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in ' ..
			'culpa qui officia deserunt mollit anim id est laborum.',
		CombatText = {
			SWuPandemoniumDoubleBoon = '{#CombatTextHighlightFormat}Pandemonium{#Prev}!',
		},
	},

	SWuPandemoniumBlessing_Complete = {
		Description = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor ' ..
			'incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis ' ..
			'nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. ' ..
			'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu ' ..
			'fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in ' ..
			'culpa qui officia deserunt mollit anim id est laborum.',
	},

	SWuPandemoniumBlessing_FlavorText = {
		DisplayName = 'All of them at once, then. Why not?',
	},
}


duo_text = {
	PermafrostShield = {
		Name = 'Permafrost Shield',
		Description = 'You cannot take more than a limited amount of damage from any single hit.',
		CombatText = {
			SWuPermafrostShield_CombatText = '{#CombatTextHighlightFormat}Permafrost Shield',
		},
		StatLines = {
			SWuPermafrostShieldStatDisplay = { Name = 'Damage Limit per Hit:', Index = 1 },
		},
	},

	BubblingCauldron = {
		Name = 'Bubbling Cauldron',
		Description = 'Your {$Keywords.KnockbackAmplify} effects are more likely to occur, and can occur ' ..
			'more often against {$Keywords.Burn}-afflicted foes.',
		StatLines = {
			SWuBubblingCauldronChanceStatDisplay = { Name = 'Bonus {$Keywords.KnockbackAmplify} Chance:', Index = 1 },
			SWuBubblingCauldronStatDisplay = { Name = 'Recharge Time vs. {$Keywords.Burn}:', Index = 2, Suffix = ' Sec.' },
		},
	},

	BitterEnd = {
		Name = 'Bitter End',
		Description = 'Your {$Keywords.WeaponSet} strikes deal more damage whenever they inflict ' ..
			'{$Keywords.Rend} or {$Keywords.Root}.',
		StatLines = {
			SWuBitterEndStatDisplay = { Name = 'Bonus Damage:', Index = 1 },
		},
	},

	BlindingSmite = {
		Name = 'Blinding Smite',
		Description = 'Whenever a {$Keywords.Blind}-afflicted foe misses you, it is struck by ' ..
			'{#BoldFormatGraft}{$TooltipData.ExtractData.TooltipMinBolts}-' ..
			'{$TooltipData.ExtractData.TooltipMaxBolts} {#Prev}lightning bolts.',
		StatLines = {
			SWuBlindingSmiteBoltStatDisplay = { Name = 'Bolt Damage:', Index = 1 },
			SWuBlindingSmiteStatDisplay = { Name = 'Lightning Damage vs. {$Keywords.Blind}:', Index = 2 },
		},
	},

	UntouchableGlow = {
		Name = 'Untouchable Glow',
		Description = 'Your {$Keywords.AttackSet} and {$Keywords.SpecialSet} deal more damage to nearby foes ' ..
			'for every {#BoldFormatGraft}1 Sec. {#Prev}you go without losing {!Icons.Health}.',
		StatLines = {
			SWuUntouchableGlowMaxStatDisplay = { Name = 'Max Bonus Damage:', Index = 2 },
		},
	},

	ColdHearted = {
		Name = 'Cold Hearted',
		Description = 'Your {$Keywords.WeaponSet} strikes grow in {$Keywords.BaseDamage} against ' ..
			'{$Keywords.Root}-afflicted foes, and your {$Keywords.Root} effects last ' ..
			'{#BoldFormatGraft}{$TooltipData.ExtractData.TooltipFreezeExtension} Sec. {#Prev}longer on ' ..
			'{$Keywords.Weak}-afflicted foes.',
		StatLines = {
			SWuColdHeartedStatDisplay = { Name = 'Bonus Power vs. {$Keywords.Root}:', Index = 1 },
			SWuColdHeartedPerSecondStatDisplay = { Name = 'Bonus Power per Second:', Index = 2 },
		},
	},

	GoldenRule = {
		Name = 'Golden Rule',
		Description = 'You deal more damage for every {!Icons.Currency} you have. After you exit a ' ..
			'{$Keywords.RoomAlt}, earn interest on it.',
		StatLines = {
			SWuGoldenRuleStatDisplay = { Name = 'Bonus Damage per Gold:', Index = 1 },
			SWuGoldenRuleMaxStatDisplay = { Name = 'Max Bonus Damage:', Index = 2 },
		},
	},

	BoilingBlood = {
		Name = 'Boiling Blood',
		Description = 'Whenever you collect {!Icons.BloodDropIcon}, restore {!Icons.Health}. You deal more ' ..
			'damage for every hit you take this {$Keywords.RoomAlt}, up to {#BoldFormatGraft}' ..
			'{$TooltipData.ExtractData.TooltipMaxBonus}%{#Prev}.',
		StatLines = {
			SWuBoilingBloodHealStatDisplay = { Name = 'Life Restored per Plasma:', Index = 1 },
			SWuBoilingBloodHitStatDisplay = { Name = 'Bonus Damage per Hit Taken:', Index = 2 },
		},
	},

	ConvectiveVortex = {
		Name = 'Convective Vortex',
		Description = 'Your {$Keywords.BladeRift} lasts longer and rapidly inflicts {$Keywords.Burn}.',
		StatLines = {
			SWuConvectiveVortexStatDisplay = { Name = '{$Keywords.Burn} per Rift Hit:', Index = 1 },
			SWuConvectiveVortexDurationStatDisplay = { Name = 'Bonus Rift Duration:', Index = 2 },
		},
	},

	BleedingHeart = {
		Name = 'Bleeding Heart',
		Description = 'Whenever you inflict {$Keywords.Rend} on a {$Keywords.Weak}-afflicted foe, create a ' ..
			'falling blade over it. Your falling blades from {#BoldFormatGraft}Ares {#Prev}deal more damage ' ..
			'to {$Keywords.Weak}-afflicted foes.',
		StatLines = {
			SWuBleedingHeartStatDisplay = { Name = 'Blade Damage:', Index = 1 },
			SWuBleedingHeartWeakStatDisplay = { Name = 'Blade Damage vs. {$Keywords.Weak}:', Index = 2 },
		},
	},

	ExplosiveSparks = {
		Name = 'Explosive Sparks',
		Description = 'Your hammer strikes from {#BoldFormatGraft}Hephaestus {#Prev}may cause a blast ' ..
			'where they land.',
		StatLines = {
			SWuExplosiveSparksStatDisplay = { Name = 'Blast Chance:', Index = 1 },
			SWuExplosiveSparksDamageStatDisplay = { Name = 'Blast Damage:', Index = 2 },
		},
	},

	GlacialAdvance = {
		Name = 'Glacial Advance',
		Description = 'Your splash effects from {#BoldFormatGraft}Poseidon {#Prev}inflict ' ..
			'{$Keywords.Root} and deal more damage.',
		StatLines = {
			SWuGlacialAdvanceStatDisplay = { Name = 'Bonus Wave Damage:', Index = 1 },
		},
	},

	KindledSpirit = {
		Name = 'Kindled Spirit',
		Description = 'Whenever you restore {!Icons.Health}, inflict {$Keywords.Burn} on nearby foes for ' ..
			'each point restored. After you take damage, restore some {!Icons.Health}.',
		StatLines = {
			SWuKindledSpiritStatDisplay = { Name = '{$Keywords.Burn} per Life Restored:', Index = 1 },
			SWuKindledSpiritHealStatDisplay = { Name = 'Life Restored per Hit:', Index = 2 },
		},
	},

	RoomTemperature = {
		Name = 'Room Temperature',
		Description = 'Your fireball effects from {#BoldFormatGraft}Hestia {#Prev}deal more damage to ' ..
			'{$Keywords.Root}-afflicted foes, and ' ..
			(mod.tuning.RoomTemperature.ClearFreeze and 'clear' or 'shorten') ..
			' their {$Keywords.Root} so you can inflict it again.',
		StatLines = {
			SWuRoomTemperatureDamageStatDisplay = { Name = 'Bonus Damage vs. {$Keywords.Root}:', Index = 1 },
		},
	},

	IntertwinedFate = {
		Name = 'Intertwined Fate',
		Description = (not mod.tuning.IntertwinedFate.NearbyOnly and
				'All foes are afflicted with {$Keywords.Link}. ' or
				mod.tuning.IntertwinedFate.Ripple and
				'Foes nearby to you and other {$Keywords.Link} afflicted foes are also afflicted with {$Keywords.Link}.' or
				'Nearby foes are afflicted with {$Keywords.Link}. ') ..
			'{$Keywords.Link} shares more damage for each {$Keywords.Link}-afflicted foe.',
		StatLines = {
			SWuIntertwinedFateStatDisplay = { Name = 'Bonus {$Keywords.Link} Damage per Hitched Foe:', Index = 1 },
		},
	},
	IntertwinedFateAlt = {
		Name = 'Intertwined Fate Alt',
		Description = 'All foes are {$Keywords.Link}-afflicted and share their {$Keywords.StatusPlural} with each ' ..
			'other. You deal more damage for each {$Keywords.Link}-afflicted foe.',
		StatLines = {
			SWuIntertwinedFateAltStatDisplay = { Name = 'Extra Damage per Hitched Foe:', Index = 1 },
		},
	},

	SpitefulStrength = {
		Name = 'Spiteful Strength',
		Description = 'Your {$Keywords.AttackSet} and ' ..
			'{$Keywords.SpecialSet} deal more damage the more of your {!Icons.Mana} is Primed.' ..
			'The bonus is doubled if no {$Keywords.GodBoonNoTooltip} already boosts its damage.',
		StatLines = {
			SWuSpitefulStrengthManaStatDisplay = { Name = 'Magick Primed:', Index = 1 },
			SWuSpitefulStrengthDamageStatDisplay = { Name = 'Bonus Damage at Full Prime:', Index = 2 },
		},
	},

	FamilyTrade = {
		Name = 'Family Trade',
		Description = '{$Keywords.TraitExchangeAlt} are offered whenever possible, and choosing one keeps ' ..
			'the {$Keywords.GodBoonNoTooltip} it would replace. Choose from ' ..
			'{#BoldFormatGraft}{$TooltipData.ExtractData.TooltipChoices} {#Prev}{$Keywords.GodBoonPlural} now, ' ..
			'{$Keywords.TraitExchangeAlt} first.',
		StatLines = {
			SWuFamilyTradeLevelsStatDisplay = { Name = 'Bonus {$Keywords.PomLevel} on Sacrifice:', Index = 1 },
		},
	},

	BloodBorn = {
		Name = 'Blood Born',
		Description = 'You deal more damage for every foe you slay this {$Keywords.RoomAlt}. ' ..
			'Whenever a foe is slain, {#BoldFormatGraft}' ..
			'{$TooltipData.ExtractData.TooltipZombies} {#Prev}' ..
			(mod.tuning.BloodBorn.Hitch and '{$Keywords.Link}-afflicted ' or '') ..
			'Shamblers rise to take its place.',
		StatLines = {
			SWuBloodBornStatDisplay = { Name = 'Bonus Damage per Slain Foe:', Index = 1 },
			SWuBloodBornMaxStatDisplay = { Name = 'Max Bonus Damage:', Index = 2 },
		},
	},

	RazorShoals = {
		Name = 'Razor Shoals',
		Description = 'You can inflict {$Keywords.Rend} again sooner on {$Keywords.KnockbackAmplify}-afflicted foes.',
		StatLines = {
			SWuRazorShoalsStatDisplay = { Name = '{$Keywords.Rend} Ready After:', Index = 1, Suffix = ' Sec.' },
		},
	},

	StormFront = {
		Name = 'Storm Front',
		Description = 'Your {$Keywords.SlowField} effects from {#BoldFormatGraft}Demeter {#Prev}are larger ' ..
			'and emit chain-lightning whenever they deal damage.',
		StatLines = {
			SWuStormFrontSizeStatDisplay = { Name = 'Bonus {$Keywords.SlowField} Size:', Index = 1 },
		},
	},
	StormFrontAlt = {
		Name = 'Storm Front Alt',
		Description = 'Your {$Keywords.SlowField} effects from {#BoldFormatGraft}Demeter {#Prev}are larger ' ..
			'and rapidly inflict {$Keywords.Echo}.',
		StatLines = {
			SWuStormFrontAltStatDisplay = { Name = '{$Keywords.Echo} Damage:', Index = 1 },
			SWuStormFrontAltSizeStatDisplay = { Name = 'Bonus {$Keywords.SlowField} Size:', Index = 2 },
		},
	},

	PlasmicCapacitor = {
		Name = 'Plasmic Capacitor',
		Description = 'Your {!Icons.BloodDropIcon} is more effective, and your chain-lightning deals more ' ..
			'damage for each {!Icons.BloodDropIcon} you have.',
		StatLines = {
			SWuPlasmicCapacitorCeilingStatDisplay = { Name = 'Max Plasma:', Index = 2 },
		},
	},
	PlasmicCapacitorAlt = {
		Name = 'Plasmic Capacitor Alt',
		Description = 'Your {$Keywords.Echo} effects leave behind {#BoldFormatGraft}' ..
			'{$TooltipData.ExtractData.TooltipPlasmaMin}-{$TooltipData.ExtractData.TooltipPlasmaMax}' ..
			'{#Prev}{!Icons.BloodDropIcon}, which emits chain-lightning when collected.',
		StatLines = {
			SWuPlasmicCapacitorAltCeilingStatDisplay = { Name = 'Max Plasma:', Index = 2 },
		},
	},

	SolarEclipse = {
		Name = 'Solar Eclipse',
		Description = 'You move and strike faster for each {$Keywords.Blind}-afflicted foe. While they all ' ..
			'are, go {$Keywords.Invisible} and deal more damage for a few seconds.',
		StatLines = {
			SWuSolarEclipseStatDisplay = { Name = 'Damage While {$Keywords.Invisible}:', Index = 1 },
			SWuSolarEclipseSpeedStatDisplay = { Name = 'Bonus Speed per Foe:', Index = 2 },
		},
		CombatText = {
			SWuSolarEclipse_CombatText = '{#CombatTextHighlightFormat}Solar Eclipse',
		},
	},

	WinterSolstice = {
		Name = 'Winter Solstice',
		Description = mod.tuning.WinterSolstice.SlowVariant == 'Quick'
			and 'While you {$Keywords.HoldNoTooltip} your {$Keywords.Omega}, slow down time. Surrounding foes are rapidly ' ..
				'damaged and afflicted by {$Keywords.SlowField}.'
			or 'While you {$Keywords.HoldNoTooltip} your {$Keywords.Omega}, surrounding foes are rapidly ' ..
				'damaged and afflicted by {$Keywords.SlowField}. Hold your channel for longer to slow down time.',
		StatLines = {
			SWuWinterSolsticeStatDisplay = {
				Name = mod.tuning.WinterSolstice.SlowVariant == 'Quick' and 'Slowdown Duration:'
					or 'Extra Hold Time and Slowdown Duration:',
				Index = 1,
				Suffix = ' Sec.',
			},
		},
	},
	VolcanicCrown = {
		Name = 'Volcanic Crown Alt',
		Description = 'Your {$Keywords.CastEX} erupts in a large blast, throwing out a crown of fireballs ' ..
			'and leaving behind burning embers.',
		StatLines = {
			SWuVolcanicCrownBlastStatDisplay = { Name = 'Blast Damage:', Index = 1 },
			SWuVolcanicCrownStatDisplay = { Name = 'Fireball Damage:', Index = 2 },
		},
	},
	WrathfulHubris = {
		Name = 'Wrathful Hubris',
		Description = 'You deal more total damage, but also take more total damage.',
		StatLines = {
			SWuWrathfulHubrisDealtStatDisplay = { Name = 'Bonus Total Damage:', Index = 1 },
			SWuWrathfulHubrisTakenStatDisplay = { Name = 'Bonus Total Damage Taken:', Index = 2 },
		},
	},
	GoddessSpite = {
		Name = 'Goddess Spite',
		Description = 'After you take damage from an attack, inflict {$Keywords.Link} on the attacker and ' ..
			'deal more damage back to all {$Keywords.Link}-afflicted foes.',
		StatLines = {
			SWuGoddessSpiteStatDisplay = { Name = 'Damage Returned:', Index = 1, Suffix = 'x' },
		},
	},
	WinterSolsticeAlt = {
		Name = 'Winter Solstice Alt',
		Description = 'While you {$Keywords.HoldNoTooltip} your {$Keywords.Omega}, ' ..
			'a large {$Keywords.SlowField} forms where you stand.' ..
			' Your {$Keywords.Root} and other slowing effects are more potent.',
		StatLines = {
			SWuWinterSolsticeAltFrostStatDisplay = { Name = '{$Keywords.Root} & Slow Potency:', Index = 1 },
		},
	},

	SolarFlare = {
		Name = 'Solar Flare',
		Description = 'While you {$Keywords.HoldNoTooltip} your {$Keywords.Omega}, a ring of fire expands ' ..
			'around you, rapidly inflicting {$Keywords.Burn}. All {$Keywords.Burn} you inflict is stronger.',
		StatLines = {
			SWuSolarFlareStatDisplay = { Name = '{$Keywords.Burn} per Sec.:', Index = 1 },
			SWuSolarFlareScorchStatDisplay = { Name = 'Bonus {$Keywords.Burn} Inflicted:', Index = 2 },
		},
	},

	TectonicCycle = {
		Name = 'Tectonic Cycle',
		Description = 'Your effects that occur at the start of each {$Keywords.EncounterAlt} periodically ' ..
			'occur again, and any {$Keywords.GodBoon} effects that recharge over time are ready again.',
		StatLines = {
			SWuTectonicCycleStatDisplay = { Name = 'Cycle Interval:', Index = 1, Suffix = ' Sec.' },
		},
		CombatText = {
			SWuTectonicCycle_CombatText = '{#CombatTextHighlightFormat}Tectonic Cycle',
		},
	},

	BurntOffering = {
		Name = 'Burnt Offering',
		Description = 'For the rest of this night, you may purge rewards for {!Icons.Currency}, ' ..
			'{!Icons.ManaUp} and {!Icons.HealthUp}. Give up a ' ..
			'{$Keywords.GodBoonNoTooltip} now for bonus {!Icons.Currency}.',
		StatLines = {
			SWuBurntOfferingGoldStatDisplay = { Name = 'First-Offering Bonus Gold:', Index = 1 },
			SWuBurntOfferingPurgesStatDisplay = { Name = 'Purges per {$Keywords.Biome}:', Index = 2 },
		},
	},

	RoyalBanquet = {
		Name = 'Royal Banquet',
		Description = 'Your {$Keywords.GodBoonPlural} gain rarity this night, and again whenever they gain ' ..
			'{$Keywords.PomLevel}.',
		StatLines = {
			SWuRoyalBanquetStatDisplay = { Name = 'Rarity Gained:', Index = 1 },
			SWuRoyalBanquetPomStatDisplay = mod.tuning.RoyalBanquet.PayHeroicPomLevels
				and { Name = 'Bonus Lv. for {#BoldFormatGraft}Heroic {#Prev}Boons:', Index = 2 } or nil,
		},
	},

	IngeniousInvention = {
		Name = 'Ingenious Invention',
		Description = 'Gain a random {!Icons.RandomHammer} upgrade now, and another every few ' ..
			'{$Keywords.EncounterPlural}.',
		StatLines = {
			SWuIngeniousInventionStatDisplay = { Name = '{$Keywords.EncounterPlural} per Upgrade:', Index = 1 },
		},
	},

	OrbitalRing = {
		Name = 'Orbital Ring',
		Description = 'When you {$Keywords.Cast}, move every {$Keywords.Link}-afflicted foe ' ..
			'into the binding circle. Foes caught in your {$Keywords.CastSet} take more damage.',
		StatLines = {
			SWuOrbitalRingStatDisplay = { Name = 'Damage to Foes in Cast:', Index = 1 },
		},
	},

	GlowingBrand = {
		Name = 'Glowing Brand',
		Description = 'Your fireball effects from {#BoldFormatGraft}Hestia {#Prev}inflict ' ..
			'{$Keywords.DelayedKnockback}, and your {$Keywords.DelayedKnockback} is more potent and lasts longer.',
		StatLines = {
			SWuGlowingBrandPotencyStatDisplay = { Name = '{$Keywords.DelayedKnockback} Potency:', Index = 1 },
			SWuGlowingBrandDurationStatDisplay = { Name = '{$Keywords.DelayedKnockback} Duration:', Index = 2 },
		},
	},

	DistressCall = {
		Name = 'Distress Call',
		Description = 'After you take damage, summon an ally to the fight for a few seconds.',
		Flavour = '',
		StatLines = {
			SWuDistressCallCooldownStatDisplay = { Name = 'Distress Call Cooldown:', Index = 1, Suffix = ' Sec.' },
		},
	},

	HotIron = {
		Name = 'Hot Iron',
		Description = 'Your fireballs from {#BoldFormatGraft}Hestia{#Prev} apply {$Keywords.DelayedKnockback}, and your weapon strikes gain bonuses from your fireball effects from {#BoldFormatGraft}Hestia{#Prev}.',
		StatLines = {
			SWuHotIronStatDisplay = { Name = 'Bonus Fireball Damage vs. {$Keywords.DelayedKnockback}:', Index = 1 },
		},
	},

	LandMine = {
		Name = 'Land Mine',
		Description = 'When a foe enters your {$Keywords.CastSet}, use {!Icons.Mana} to turn it into your ' ..
			'{$Keywords.CastEX}, then cause a blast that deals ' ..
			'{#BoldFormatGraft}{$TooltipData.ExtractData.TooltipBlastDamage} {#Prev}damage in the area.',
		StatLines = {
			SWuLandMineManaStatDisplay = mod.tuning.LandMine.UseFixedManaCost
				and { Name = 'Magick Cost:', Index = 1 } or nil,
			SWuLandMineFuseStatDisplay = not mod.tuning.LandMine.UseFixedManaCost
				and { Name = 'Blast After:', Index = 1, Suffix = ' Sec.' } or nil,
			SWuLandMineRechargeStatDisplay = { Name = 'Recharge Time:', Index = 2, Suffix = ' Sec.' },
		},
		CombatText = {
			SWuLandMine_CombatText = '{#CombatTextHighlightFormat}Land Mine',
		},
	},

	EnergyOverflow = {
		Name = 'Energy Overflow',
		Description = 'You restore more {!Icons.Mana}. Any you restore past your limit raises it for the ' ..
			'rest of the {$Keywords.RoomAlt}.',
		StatLines = {
			SWuEnergyOverflowStatDisplay = { Name = 'Bonus Magick Restoration:', Index = 1 },
			SWuEnergyOverflowCapStatDisplay = { Name = 'Max Magick:', Index = 2 },
		},
	},

	GentleCaress = {
		Name = 'Gentle Caress',
		Description = 'Any {!Icons.Health} you restore past your limit becomes {!Icons.ArmorTotal}' ..
			(mod.tuning.GentleCaress.CapArmor and ', up to a cap' or '') .. '. ' ..
			'The first time you take damage each {$Keywords.EncounterAlt}, restore that much {!Icons.Health} instead.',
		CombatText = {
			SWuGentleCaress_CombatText = '{#CombatTextHighlightFormat}Gentle Caress{#Prev}!',
		},
		StatLines = mod.tuning.GentleCaress.CapArmor and {
			SWuGentleCaressStatDisplay = { Name = 'Minimum Armor Cap:', Index = 1 },
		} or nil,
	},

	FamilyReunion = {
		Name = 'Family Reunion',
		Description = 'Gain a {$Keywords.GodBoonNoTooltip} from each Olympian you have not chosen any from ' ..
			'this night. Any {$Keywords.GodBoonPlural} you find are more likely to include ' ..
			'{$Keywords.Legendary} or {$Keywords.Duo} blessings.',
		StatLines = {
			SWuFamilyReunionLegendaryStatDisplay = { Name = 'Bonus Legendary & Duo Chance:', Index = 1 },
		},
	},

	AirControl = {
		Name = 'Air Control',
		Description = 'Foes\' ranged shots are slowed and  destroyed by your {$Keywords.CastSet}, ' ..
			'your {$Keywords.Sprint}, and your {$Keywords.Omega} as you {$Keywords.HoldNoTooltip} them. ' ..
			'Foes whose shots are destroyed are struck by lightning.',
		StatLines = {
			SWuAirControlStatDisplay = { Name = 'Bolt Damage:', Index = 1 },
		},
	},

	WishingWell = {
		Name = 'Wishing Well',
		Description = 'Whenever you use a {$Keywords.Fountain}, choose a {$Keywords.GodBoonNoTooltip} from ' ..
			'{#BoldFormatGraft}Artemis{#Prev}, {#BoldFormatGraft}Athena{#Prev}, {#BoldFormatGraft}Dionysus ' ..
			'{#Prev}or {#BoldFormatGraft}Hades{#Prev}. {$Keywords.FountainPlural} appear in each ' ..
			'{$Keywords.Biome} if possible. Choose one now.',
		StatLines = {
			SWuWishingWellStatDisplay = { Name = '{$Keywords.Fountain} Chance per {$Keywords.Biome}:', Index = 1 },
		},
	},

	DiscerningTaste = {
		Name = 'Discerning Taste',
		Description = 'You can alter most choices, and the first time you alter each is free. ' ..
			'Gain some {!Icons.ReRollAlt} now.',
		StatLines = {
			SWuDiscerningTasteStatDisplay = { Name = 'Rerolls Granted:', Index = 1 },
		},
	},

	TippedScales = {
		Name = 'Tipped Scales',
		Description = 'Gain some {$Keywords.SWuFavor}. Whenever a chance-based effect fails to occur, gain more.',
		Keywords = {
			SWuFavor = {
				DisplayName = 'Favor',
				Description = 'Added to the chance of each of your chance-based effects, and spent whenever ' ..
					'one occurs.',
			},
		},
		StatLines = {
			SWuTippedScalesBaseStatDisplay = { Name = 'Base Favor:', Index = 1 },
			SWuTippedScalesStatDisplay = { Name = 'Favor per Failure:', Index = 2 },
		},
	},
}
