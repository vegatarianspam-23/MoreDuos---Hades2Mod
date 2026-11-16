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
    DifferentLeague = true;
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
    NastyComeback = true;
    OrbitalRing = true;
    PermafrostShield = true;
    PlasmicCapacitor = true;
    RazorShoals = true;
    RoomTemperature = true;
    RoyalBanquet = true;
    SolarEclipse = true;
    SolarFlare = true;
    StormFront = true;
    TectonicCycle = true;
    TippedScales = true;
    WinterSolstice = true;
    WishingWell = true;
  };

  Experimental = {
    ConvectiveVortex = false;

    SpitefulStrength = false;

    VolcanicRift = false;

    GlacialAdvanceAlt = false;

    HotIronAlt = false;

    PlasmicCapacitorAlt = false;

    SolarEclipseAlt = false;

    StormFrontAlt = false;

    WinterSolsticeAlt = false;

    Pandemonium = false;

    WrathOfOlympus = false;

    ZagreusJourney = false;
  };

  Options = {
    OneDuoPerPair = false;

    -- resets all timed cooldowns (like Volcanic Strike, Unseen Ire, etc.) at the start of each encounter
    -- cd resets are picked up by tectonic cycle
    TectonicCycleResetsCooldowns = false;
  };
}

return config
