# EditedScripts

A consolidated server framework (`KOFramework`) for the game. `scripts/` is the live mirror written by the sync workflow
and is **never touched**; everything here is additive and only takes effect when you copy it into the place.

## Layout

```
EditedScripts/
  ServerScriptService/KOFramework/     <- one Script (init.server.lua) with child ModuleScripts
    init.server.lua                    bootstrap: safety check, registers services, Init -> Start, prints a status report
    Config.lua                         every constant that used to be hard-coded across scripts (values unchanged)
    Core/  Lifecycle, PlayerHooks, Util, Logger
    Services/  Morph, Health, GCellGuard, Eliminator, Settings, Legacy, Knit
  tests/run.luau                       unit tests:  luau EditedScripts/tests/run.luau
```

## What the framework replaces

| Old script | Now | Notes |
|---|---|---|
| `ServerHandler` (module loader, Knit start, inline morph copy) | `init.server.lua` + `Lifecycle` + `LegacyService` + `KnitService` | |
| `MorphBootstrap` | `MorphService` | the two morph copies are now one |
| `HealthEnforcer` + `framework/modules/Regen` | `HealthService` | same formulas and constants |
| `GCellIntegrityGuard` | `GCellGuardService` | `_G.GCellGuardAllow(value, amount)` unchanged |
| `PlayerEliminator` | `EliminatorService` | `_G.PlayerEliminatorActive` / `_G.HDAdminMain` unchanged |
| `SettingsStore` | `SettingsService` | same DataStore, key and remote contract |

Deliberately **left exactly as they are** (loaded in place by `LegacyService`): `framework/modules/Character`, `Combat`,
`Data`, `World`. They are 120 KB of tightly coupled code sharing `_G` hooks, and `World` reads a `HitSound` child off its
own ModuleScript, so moving or rewriting them blind would risk breaking the game for no gain. They now start under the
same lifecycle (in the same order, each in its own thread) so a failure in one is reported instead of silent.
Also untouched: `SecurityPolicy`, `Levels`, `KnitServices`, `DamageBoost`, `Gcells`, `HealthCommandFix`, everything client-side.

## Install (test in a copy of the place first)

1. Copy `KOFramework` into `ServerScriptService` (Script named `KOFramework`, children as above).
2. **Disable or delete** the replaced scripts: `ServerHandler`, `MorphBootstrap`, `HealthEnforcer`, `GCellIntegrityGuard`,
   `PlayerEliminator`, `SettingsStore`. (`framework/modules/Regen` can stay; nothing loads it any more.)
3. Playtest. The output shows `[KOFramework] Started` followed by one status line per service.

If any replaced script is still enabled, the framework prints which ones and **does nothing**, so the old setup keeps
running untouched instead of double-initialising Data/Combat.

**Rollback:** re-enable the old scripts and delete `KOFramework`.

## Fixes folded in

- `ServerHandler` had an early `return` that stopped *every* legacy module from starting if `SecurityPolicy` failed to
  load; now only the Morph service fails and everything else keeps going.
- `MorphBootstrap` sent failures as `(false, message)` while the client reads `(success, morphName, message)`, so the
  message was lost if that copy won the startup race. One implementation, correct argument order.
- Settings: DataStore retries, save on server shutdown, only writes when FOV changed, and a failed load can no longer
  overwrite a saved FOV with the default. NaN FOV is rejected.
- Eliminator: hooks attach immediately (the old script waited up to 60 s for HD Admin before connecting anything),
  and group ranks are fetched once per group instead of once per rank entry.
- Regen no longer uses deprecated `tick()` and no longer waits forever on a character that is never parented.
- Optional `Morph.AllowedUserIds` in `Config.lua` so restricted-kaiju access survives username changes.

## Not verified

Unit tests cover the pure logic only. The services need a real Roblox server to exercise, which I could not do here, so
playtest in a copy of the place before publishing.
