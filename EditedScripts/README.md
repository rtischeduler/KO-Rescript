# EditedScripts

Consolidated server (`Server`) and client (`Client`) frameworks for the game. `scripts/` is the live mirror written
by the sync workflow and is **never touched**; everything here is additive and only takes effect when you copy it into the
place.

**To install, and to see exactly what to delete, follow [SETUP.md](SETUP.md).**

## Layout

```
EditedScripts/
  SETUP.md                             step-by-step install, delete lists, troubleshooting, rollback
  ServerScriptService/Server/     <- one Script (init.server.lua) with child ModuleScripts
    init.server.lua                    bootstrap: safety check, registers services, Init -> Start, prints a status report
    Config.lua                         every constant that used to be hard-coded across scripts (values unchanged)
    Core/  PlayerHooks
    Services/  Morph, Health, GCellGuard, Eliminator, Settings, Legacy, Knit
  StarterPlayer/StarterPlayerScripts/
    Client/                          <- one LocalScript (init.client.lua) with child ModuleScripts
      init.client.lua                  bootstrap: safety check, registers controllers, prints a status report
      Config.lua                       menu, FOV, HUD, rain, pulse and ocean tunables (values unchanged)
      (shared modules live in ReplicatedStorage/Shared)
      Controllers/  Knit, Menu, Settings, Touch, Chat, Hud, Ocean, Effects, Sounds
    RbxCharacterSounds.client.lua      intentionally empty: keeps Roblox from injecting its default sounds
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
Also untouched: `SecurityPolicy`, `Levels`, `KnitServices`, `DamageBoost`, `Gcells`, `HealthCommandFix`.

## What Client replaces

All 15 scripts that used to sit loose in `StarterPlayerScripts`:

| Old script | Now |
|---|---|
| `KnitClientBootstrap` | `Controllers/Knit` |
| `MenuCameraController`, `Daiju` | `Controllers/Menu` |
| `SettingsSaver` | `Controllers/Settings` |
| `TouchControlHider` | `Controllers/Touch` |
| `KillMessageDisplay`, `EliminatorPopupDisplay` | `Controllers/Chat` |
| `BossHUD`, `RaffleHUD`, `BlindEffect`, `HideOwnTag` | `Controllers/Hud` |
| `Ocean` | `Controllers/Ocean` |
| `RainClient`, `PulseRenderer` | `Controllers/Effects` |
| `RbxCharacterSounds` | `Controllers/Sounds` (the original script stays, emptied) |

Behaviour is unchanged. Each feature now runs in its own protected thread, so one failing feature is reported by name
instead of taking the others down, and every tunable number sits in `Config.lua`.

## Install

See [SETUP.md](SETUP.md). If any replaced script is still enabled, each framework prints which ones and **does nothing**,
so the old setup keeps running untouched instead of double-initialising.

**Rollback:** delete `Server` / `Client` and restore the old scripts (details in SETUP.md).

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

Unit tests cover the pure logic of the server framework only. Every file was syntax-checked with a Luau parser, but the
services and controllers need a real Roblox server and client to exercise, which I could not do here, so playtest in a
copy of the place before publishing.
