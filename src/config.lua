local config = {
  version = 1;
  enabled = true;

  Duos = {
    AirControl = true;
    BitterEnd = true;
    BleedingHeart = true;
    BlindingSmite = true;
    BloodBorn = true;
    BoilingBlood = true;
    BubblingCauldron = true;
    BurntOffering = true;
    ColdHearted = true;
    DiscerningTaste = true;
    EnergyOverflow = true;
    ExplosiveSparks = true;
    FamilyReunion = true;
    FamilyTrade = true;
    GentleCaress = true;
    GlacialAdvance = true;
    GoldenRule = true;
    HotIron = true;
    IngeniousInvention = true;
    IntertwinedFate = true;
    KindledSpirit = true;
    LandMine = true;
    OrbitalRing = true;
    PermafrostShield = true;
    PlasmicCapacitor = true;
    RazorShoals = true;
    RoomTemperature = true;
    RoyalBanquet = true;
    SolarEclipse = true;
    SolarFlare = true;
    SpitefulStrength = true;
    StormFront = true;
    TectonicCycle = true;
    TippedScales = true;
    UntouchableGlow = true;
    WinterSolstice = true;
    WishingWell = true;
  };

  Experimental = {
    ConvectiveVortex = false;

    GlowingBrand = false;

    GoddessSpite = false;

    VolcanicCrown = false;

    WrathfulHubris = false;

    IntertwinedFateAlt = false;

    PlasmicCapacitorAlt = false;

    SolarEclipseAlt = false;

    StormFrontAlt = false;

    UntouchableGlowAlt = false;

    WinterSolsticeAlt = false;

    DistressCall = false;

    Pandemonium = false;

    WrathOfOlympus = false;

    ZagreusJourney = false;
  };

  Options = {
    -- resets all timed cooldowns (like Volcanic Strike, Unseen Ire, etc.) at the start of each encounter
    -- cd resets are picked up by tectonic cycle
    TectonicCycleResetsCooldowns = false;
  };
}

return config
