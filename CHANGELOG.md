# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.1] - 2026-11-24

### Changed

- Nasty Comeback: attacks that bypass retaliation, such as Chronos' nova, are answered with 9999 damage
- Plasmic Capacitor requirement update: Zeus bucket is now Divine Vengeance, Power Surge, and Lightning Lance

### Fixed

- Fixed the game slowing down while the Hell2Modding menu (Insert) was open

## [1.2.0] - 2026-11-22

### Changed

- Plasmic Capacitor: Plasma is 50% more effective (was 20%) and no longer raises the max plasma cap. Excess plasma now converts to chain lightning on pickup.
- Different League: deal 5% more damage for every attack you Dodge this encounter, Daze misses included, up to 100%, shown on its HUD icon. It keeps the +15% chance to Dodge attacks from nearby foes (up from 10%), but the passive dodge-damage scaling effect is removed.
- Blood Born: taking damage or slaying a foe has a 30% chance to raise 1-5 Shamblers (10/30/30/20/10% for 1-5; still capped at 10), instead of 5 per kill. Slain Shamblers count toward the 5% extra damage per foe slain per location.
- Orbital Ring, Energy Overflow and Ingenious Invention requirement updates: Apollo bucket is now Super Nova, Perfect Image, Extra Dose, and Prominence Flare
- Air Control no longer destroys projectiles while channeling
- Volcanic Rift: fireballs deal 60 damage (was 30)
- Added experimental compatiblity with Zerp's MoreDashBoons and Wistiti's HermesDuos (various boon interactions, alternates for redundant boons)

## [1.1.8] - 2026-11-19

### Fixed

- Fixed Air Control not destroying certain projectiles from Zagreus' Journey properly
- Updated damage meter for Air Control, Blinding Smite and Tipped Scales lightning
- Fixed issue with certain boons not showing up properly on boon tray

### Changed

- Discerning Taste: offered during Fates' Whim and without The Enchantress or Champions Arcana, and taking it keeps Fates' Whim. While held you can reroll both location rewards and boons, as with both Arcana equipped (without their extra rerolls).

## [1.1.7] - 2026-11-18

### Fixed

- Nasty Comeback: fixed Prometheus bug where damage taken from his memory games prematurely ends the sequence

### Changed

- Gentle Caress: Heinous Affront no longer triggers it. Restore the old behaviour with `HeinousAffront = true` under `GentleCaress` in `tuning.lua`
- Nasty Comeback: deals 10000% of the damage taken back to your attacker (was 1000%)
- Nasty Comeback: Heinous Affront still inflicts Hitch on all foes, but no longer deals damage back to your attacker.
- Discerning Taste: only offered with The Enchantress or Champions Arcana equipped

## [1.1.6] - 2026-11-16

### Added

- `Options.OneDuoPerPair` (off by default): once you hold a duo, no other duo of the same two gods is offered. Covers vanilla duos too
- Nasty Comeback (Hera × Hephaestus): after you take damage from an attack, inflict Hitch on all foes and deal 1000% of the damage taken back to your attacker (up to 9999).

### Removed

- Experimental duos Glowing Brand, Volcanic Crown Alt and Wrathful Hubris, with their `Experimental.GlowingBrand`, `Experimental.VolcanicCrown` and `Experimental.WrathfulHubris` config entries
- Spiteful Goddess (experimental, `Experimental.GoddessSpite`), replaced by Nasty Comeback
- Distress Call (experimental, `Experimental.DistressCall`): moved to BoonEdits, where it is a Hermes Legendary on by default
- Untouchable Glow (experimental, `Experimental.UntouchableGlow`). BoonEdits' Flawless Execution (Hermes Legendary) carries on its effect

### Changed

- Spiteful Strength is now experimental and off by default (`Experimental.SpitefulStrength`, was `Duos.SpitefulStrength`)

## [1.1.5] - 2026-11-15

### Added

- Hot Iron Alt (experimental, `Experimental.HotIronAlt`): old Hot Iron effect: Hestia's fireballs apply Glow and deal 25% more damage to Glowing foes, and your weapon strikes gain your fireball effects.
- Volcanic Rift (experimental, `Experimental.VolcanicRift`, Hera × Hestia): your Fine Line fissures erupt into 5 fireballs (30 damage, counted as Hestia's fireballs) leaving fire puddles (20 damage every 0.25 sec.).

### Changed

- Hot Iron (new): your Glow can stack up to 5 times, each stack expiring on its own. Each stack adds its own Glow damage taken (+100% at 5 base stacks). Your Attack and Special get +10 power per Glow stack on the foe.
- Glacial Advance: the Ocean Swell it fires deals 60 damage, down from 80, and the tooltip no longer lists its damage
- Different League: +10% chance to Dodge attacks from nearby foes, down from 15%

### Fixed

- Drastic improvements to stuttering mid-combat

## [1.1.4] - 2026-11-13

### Added

- Glacial Advance Alt (experimental, `Experimental.GlacialAdvanceAlt`): old Glacial Advance effect: Poseidon's splash effects inflict Freeze and deal 30 more damage

### Changed

- Glacial Advance (new): Your Ocean Swells inflict Chill, and your splash effects from Poseidon have a 25% chance to fire an 80-damage Ocean Swell.
- Tipped Scales: Favor stays at 10% and no longer builds up. Instead, whenever a chance-based effect fails, a lightning bolt strikes a random nearby foe for 100 damage, (rate limited at 0.3 seconds).
- Cold Hearted: your Attack and Special now get a flat +25 power against Frozen foes, and Weak foes stay Frozen instead of thawing.

### Fixed

- Distress Call, Gentle Caress: now trigger when Night Bloom's Retaliation talent fires off a hit on your summon, the same way they trigger from Heinous Affront. Gentle Caress restores Health equal to the damage your summon took, instead of a flat 50
- Spiteful Goddess (experimental): when Night Bloom's Retaliation talent triggers it, the nearby bonus checks the distance from your summon instead of from you
- Permafrost Shield: no longer shows its damage-cap text over you when one of your summons takes a big hit

## [1.1.3] - 2026-11-09

### Removed

- Intertwined Fate Alt (experimental): removed. It is now Nuptial Vow, a Hera Legendary in BoonEdits. If it was on, regular Intertwined Fate takes its place, including in a run that already holds it

## [1.1.2] - 2026-11-09

### Changed

- Config window: turning a duo on or off now applies from the next room, no restart needed
- Spiteful Goddess (experimental): renamed from Goddess Spite (config key is still `GoddessSpite`) and reworked. After you take damage from an attack, inflict Hitch on all foes and deal 200% of the damage taken back to the attacker, or 1000% if it is nearby, up to 9999. Heinous Affront triggers count as 50 damage taken.
- Spiteful Goddess (experimental), Intertwined Fate: Glamour Gain now counts toward the Aphrodite requirement
- Gentle Caress: when Heinous Affront triggers it, restores a flat 50 Health and shows the Gentle Caress text

### Fixed

- Untouchable Glow: fixed description
- Gentle Caress: Heinous Affront now uses up one first-hit shield instead of removing all of them, including ones bought from Charon
- Spiteful Goddess (experimental): fixed damage meter

## [1.1.1] - 2026-11-01

### Added

- In-game config window: open the Hell2Modding menu and toggle any duo with a Windowed checkbox, grouped by god, with each duo listed under both of its gods. Changes save right away.

### Changed

- Glacial Advance: now works with all of Poseidon's splash effects, including Tidal Ring and Geyser Spout when they count as splash effects (with BoonEdits), not just waves and Beach Ball

## [1.1.0] - 2026-10-30

### Added

- Different League (Apollo × Aphrodite): replaces Untouchable Glow as the Apollo × Aphrodite duo. +15% chance to Dodge attacks from nearby foes, and all your damage to a foe is increased by your chance to avoid its attacks, including its Daze. Replaces Untouchable Glow Alt, so `UntouchableGlowAlt` is removed from the config
- Untouchable Glow: moved to Experimental (`Experimental.UntouchableGlow`, off by default). If your config was made before this version, it still has `Duos.UntouchableGlow = true`, which keeps it on; set that to false to turn it off
- Distress Call (experimental): adds Megaera and Bouldy as possible summons, when Zagreus' Journey is installed + enabled in the config

### Changed

- Solar Eclipse: speed bonus from Dazed foes is no longer capped at 50% (still 5% per Dazed foe)
- Family Trade: Sacrifice boons gain 3 extra Pom levels (was 4)
- Winter Solstice: no longer recharges faster with Post Haste, and no longer counts toward Post Haste's offer requirements
- Tectonic Cycle: cycles faster with Post Haste, and now counts toward Post Haste's offer requirements
- Distress Call (experimental): now summons an ally at the start of each encounter instead of after you take damage. The old trigger can be switched back on with `DistressCall.OnEncounterStart` in tuning. Athena now strikes as the 8 seconds end, instead of right away

### Fixed

- Distress Call (experimental): fixed various entry/exit animations and voicelines, and targeting behavior for Thanatos
- Distress Call (experimental): fixed issue with Artemis preview decal lingering, and summons finish their attack cycle fully before exiting
- Air Control: with Zagreus' Journey, the ring now slows and destroys Hades I projectiles too, including traps and Satyr darts
- Hot Iron: fixed various interactions with Fourth Degree and Burning Meteor, and Omega attacks / specials not getting bonuses

## [1.0.14] - 2026-10-28

### Added

- Untouchable Glow Alt (experimental, `UntouchableGlowAlt`): +10% chance to Dodge, and all your damage to nearby foes is increased by your Dodge + Daze
- Solar Eclipse Alt (experimental, `SolarEclipseAlt`): the previous Solar Eclipse, now swapped to Alt

### Changed

- Solar Eclipse: reworked. You move and strike 5% faster for each Dazed foe (was 10%), up to 50%, and all your damage is increased by half of your bonus move speed, including the extra speed while Sprinting. Now requires an Apollo Daze boon and an Ares Plasma boon
- Cold Hearted: bonus power against Frozen foes starts at +10 (was +50). Freeze now lasts twice as long on Weak foes, instead of a flat +4 seconds
- Untouchable Glow: every 0.3 seconds near foes now gives 1% more Weapon damage, no longer only against nearby foes (was every 1 second) and also 1% less damage taken, both up to 100% after 30 seconds. The bonus resets whenever an attack that deals damage hits you (5 second buffer between resets). At 100% damage reduction, any damage taken is floored to 1, and the bonus is reset.

### Fixed

- Pop-up text over Melinoe and foes (like Perfect Image or Untouchable Glow being lost) now stacks upward instead of overlapping when several show at once
- Bleeding Heart: fixed damage meter
- Solar Eclipse: now also raises sprint speed

## [1.0.13] - 2026-10-27

### Changed

- Razor Shoals: Wounds can be re-inflicted on Frothed foes after 0.01 seconds (was 0.1)

### Fixed

- Air Control: added slowdown fix to Chronos scythe throws when BoonEdits is installed

## [1.0.12] - 2026-10-26

### Changed

- Air Control: no longer slows all foes' ranged shots. Instead, shots that can't be destroyed, like Chronos' scythe throws, travel at 50% speed while inside projectile destruction circles
- Blood Born: 3% more damage per foe slain (was 2%), and the bonus now lasts per location instead of encounter
- Blood Born, Boiling Blood: current damage bonus now shows on the boon's HUD icon

### Fixed

- Air Control: the ring on your Cast now grows with Super Nova
- Air Control: added vfx from Fire Away to destroyed projectiles

## [1.0.11] - 2026-10-24

### Changed

- Hot Iron: Hestia's fireballs now apply Glow; bonus fireball damage against Glow lowered to 25% (was 30%). No longer gates weapon bonuses on glowing foes, and fixed compatibility with various boons (Burning Meteor, Scalding Vapor)


## [1.0.10] - 2026-10-23

### Changed

- Solar Eclipse: recharge raised to 40 seconds (was 30)
- Solar Eclipse: no longer shows a text popup when it recharges
- Land Mine: no longer triggers on a Cast already primed as an Omega Cast

## [1.0.9] - 2026-10-23

### Changed

- Intertwined Fate: Hitch now refreshes on nearby foes every 0.3s during combat, like Glamour Gain, instead of a 1-second pulse; the Hera ring decal is off by default (`PulseDecal`)
- Spiteful Strength: Primes 60 Magick (was 50); bonus is doubled on an Attack or Special that holds no percentage-damage boon

## [1.0.8] - 2026-10-23

### Changed

- Boiling Blood: bonus now lasts the whole location instead of each encounter
- Energy Overflow: raised Magick limit now lasts the whole location instead of each encounter
- Solar Eclipse: speed bonus raised to 10% per Dazed foe (was 5%), still up to 50%

## [1.0.7] - 2026-10-23

### Changed

- Untouchable Glow: bonus now kept across encounters and locations

### Fixed

- Untouchable Glow: now works with Island Getaway
- Winter Solstice: now works with Island Getaway

## [1.0.6] - 2026-10-23

- text updates

## [1.0.5] - 2026-10-23

### Changed

- Bleeding Heart: falling blades now deal 50% more damage to Weak foes (was 30%).

## [1.0.4] - 2026-10-23

### Added

- Dependency on [MultiDressHelper](https://thunderstore.io/c/hades-ii/p/zerp/MultiDressHelper/), so holding more than one Arachne dress through Wishing Well works properly.

## [1.0.3] - 2026-10-23

### Changed

- Intertwined Fate: Hitched foes no longer spread hitch to nearby foes.

### Fixed

- Intertwined Fate: updated description
  
## [1.0.2] - 2026-10-23

- text updates
  
## [1.0.1] - 2026-10-23

- text updates

## [1.0.0] - 2026-10-22

### Added

- Initial release.

[1.2.1]: https://github.com/vegatarianspam-23/MoreDuos---Hades2Mod/compare/1.2.0...1.2.1
[1.2.0]: https://github.com/vegatarianspam-23/MoreDuos---Hades2Mod/compare/1.1.8...1.2.0
[1.1.8]: https://github.com/vegatarianspam-23/MoreDuos---Hades2Mod/compare/1.1.7...1.1.8
[1.1.7]: https://github.com/vegatarianspam-23/MoreDuos---Hades2Mod/compare/1.1.6...1.1.7
[1.1.6]: https://github.com/vegatarianspam-23/MoreDuos---Hades2Mod/compare/1.1.5...1.1.6
[1.1.5]: https://github.com/vegatarianspam-23/MoreDuos---Hades2Mod/compare/1.1.4...1.1.5
[1.1.4]: https://github.com/vegatarianspam-23/MoreDuos---Hades2Mod/compare/1.1.3...1.1.4
[1.1.3]: https://github.com/vegatarianspam-23/MoreDuos---Hades2Mod/compare/1.1.2...1.1.3
[1.1.2]: https://github.com/vegatarianspam-23/MoreDuos---Hades2Mod/compare/1.1.1...1.1.2
[1.1.1]: https://github.com/vegatarianspam-23/MoreDuos---Hades2Mod/compare/1.1.0...1.1.1
[1.1.0]: https://github.com/vegatarianspam-23/MoreDuos---Hades2Mod/compare/1.0.14...1.1.0
[1.0.14]: https://github.com/vegatarianspam-23/MoreDuos---Hades2Mod/compare/1.0.13...1.0.14
[1.0.13]: https://github.com/vegatarianspam-23/MoreDuos---Hades2Mod/compare/1.0.12...1.0.13
[1.0.12]: https://github.com/vegatarianspam-23/MoreDuos---Hades2Mod/compare/1.0.11...1.0.12
[1.0.11]: https://github.com/vegatarianspam-23/MoreDuos---Hades2Mod/compare/1.0.10...1.0.11
[1.0.10]: https://github.com/vegatarianspam-23/MoreDuos---Hades2Mod/compare/1.0.9...1.0.10
[1.0.9]: https://github.com/vegatarianspam-23/MoreDuos---Hades2Mod/compare/1.0.8...1.0.9
[1.0.8]: https://github.com/vegatarianspam-23/MoreDuos---Hades2Mod/compare/1.0.7...1.0.8
[1.0.7]: https://github.com/vegatarianspam-23/MoreDuos---Hades2Mod/compare/1.0.6...1.0.7
[1.0.6]: https://github.com/vegatarianspam-23/MoreDuos---Hades2Mod/compare/1.0.5...1.0.6
[1.0.5]: https://github.com/vegatarianspam-23/MoreDuos---Hades2Mod/compare/1.0.4...1.0.5
[1.0.4]: https://github.com/vegatarianspam-23/MoreDuos---Hades2Mod/compare/1.0.3...1.0.4
[1.0.3]: https://github.com/vegatarianspam-23/MoreDuos---Hades2Mod/compare/1.0.2...1.0.3
[1.0.2]: https://github.com/vegatarianspam-23/MoreDuos---Hades2Mod/compare/1.0.1...1.0.2
[1.0.1]: https://github.com/vegatarianspam-23/MoreDuos---Hades2Mod/compare/1.0.0...1.0.1
[1.0.0]: https://github.com/vegatarianspam-23/MoreDuos---Hades2Mod/compare/50c509808ad6421d2c40353e1c6ed2354f02278f...1.0.0