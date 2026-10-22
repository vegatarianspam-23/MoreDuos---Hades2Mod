# Credits

MoreDuos is MIT licensed.

## Required dependencies

These are declared in `thunderstore.toml` and installed by the mod manager. They are called at
runtime, and none of their code is copied into this repository.

| Mod | Author | Licence |
| --- | --- | --- |
| [Hell2Modding](https://thunderstore.io/c/hades-ii/p/Hell2Modding/Hell2Modding/) | Hell2Modding | see mod |
| [ENVY](https://thunderstore.io/c/hades-ii/p/LuaENVY/ENVY/) | LuaENVY | see mod |
| [Chalk](https://thunderstore.io/c/hades-ii/p/SGG_Modding/Chalk/), [ReLoad](https://thunderstore.io/c/hades-ii/p/SGG_Modding/ReLoad/), [SJSON](https://thunderstore.io/c/hades-ii/p/SGG_Modding/SJSON/), [ModUtil](https://thunderstore.io/c/hades-ii/p/SGG_Modding/ModUtil/) | SGG_Modding | see mod |
| [GodsAPI](https://thunderstore.io/c/hades-ii/p/zannc/GodsAPI/) | zannc | GPL-3.0 |
| [Droppable Gods](https://thunderstore.io/c/hades-ii/p/zannc/Droppable_Gods/) | zannc | GPL-3.0 |
| [HexReroll](https://thunderstore.io/c/hades-ii/p/zerp/HexReroll/) | Aditya Gupta | MIT |

**Droppable Gods** supplies Artemis, Athena, Dionysus and Hades, who have no loot tables in vanilla,
along with their icons and sounds. Family Reunion, Wishing Well and Pandemonium draw on these gods by
name. `src/extra_gods.lua` keeps them out of the ordinary door pool; that is a runtime change to
shared game data, not a change to their mod.

**Reroll_Hammers** — mozzarellathicc — MIT — <https://github.com/mozzarellathicc/reroll-hammers> for
enabling rerolls on hammer upgrades for Discerning Taste

**HexReroll** supplies the reroll interface for the Hex screen, which vanilla leaves without one. It
shows for holders of the Panel Reroll arcana, and Discerning Taste reports that arcana as held, so
the screen works for this boon without either mod knowing about the other.

GodsAPI and Droppable Gods are GPL-3.0. This mod only depends on them and reads their public data.

HexReroll's MIT licence asks that its notice travel with it:

```
MIT License

Copyright (c) 2026 Aditya Gupta

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial
portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```

## AI disclosure

AI tools were used to help write and review the mod's code. No AI-generated art, audio or other
assets are used; everything shown or heard in game is Supergiant's own.
