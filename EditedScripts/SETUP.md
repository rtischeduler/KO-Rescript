# Setup: installing KOFramework (server) and KOClient (client)

Everything you need to copy into Roblox Studio, and exactly what to delete afterwards.

## The one rule

`scripts/` in this repo is a **read-only mirror**. The sync workflow wipes and rewrites it from the published place every 6 hours, so anything edited there is lost. All hand-written code lives in `EditedScripts/`. Nothing in `EditedScripts/` takes effect until you copy it into the place in Studio.

## 0. Back up first

In Studio: **File > Save to File As...** and keep the `.rbxl`. Do the whole setup, playtest, and only then **Publish**. Nothing is live until you publish.

## 1. Server: install KOFramework

Create this tree in **ServerScriptService**. Class names matter: the top item is a `Script`, everything under it is a `ModuleScript` or `Folder`.

```
ServerScriptService
└── KOFramework              Script          <- EditedScripts/ServerScriptService/KOFramework/init.server.lua
    ├── Config               ModuleScript    <- Config.lua
    ├── Core                 Folder
    │   ├── Lifecycle        ModuleScript    <- Core/Lifecycle.lua
    │   ├── Logger           ModuleScript    <- Core/Logger.lua
    │   ├── PlayerHooks      ModuleScript    <- Core/PlayerHooks.lua
    │   └── Util             ModuleScript    <- Core/Util.lua
    └── Services             Folder
        ├── EliminatorService  ModuleScript  <- Services/EliminatorService.lua
        ├── GCellGuardService  ModuleScript  <- Services/GCellGuardService.lua
        ├── HealthService      ModuleScript  <- Services/HealthService.lua
        ├── KnitService        ModuleScript  <- Services/KnitService.lua
        ├── LegacyService      ModuleScript  <- Services/LegacyService.lua
        ├── MorphService       ModuleScript  <- Services/MorphService.lua
        └── SettingsService    ModuleScript  <- Services/SettingsService.lua
```

How to fill each one: open the file on GitHub, click **Raw**, copy everything, and paste it over the script's default contents in Studio. Instance names must match the file name exactly (case-sensitive). The `init.server.lua` code goes into the `KOFramework` Script itself.

### Delete these 6 server scripts (ServerScriptService)

| Delete | Replaced by |
|---|---|
| `ServerHandler` | `init.server.lua` + `LegacyService` + `KnitService` |
| `MorphBootstrap` | `MorphService` |
| `HealthEnforcer` | `HealthService` |
| `GCellIntegrityGuard` | `GCellGuardService` |
| `PlayerEliminator` | `EliminatorService` |
| `SettingsStore` | `SettingsService` |

If you would rather not delete yet, set `Disabled = true` on each instead. The framework accepts either.

### Do NOT delete these (the framework loads them)

| Keep | Why |
|---|---|
| `framework` folder, with `modules/Character`, `Combat`, `Data`, `World` | `LegacyService` starts them in order |
| `framework/modules/Regen` | harmless; nothing loads it any more |
| `SecurityPolicy` | `MorphService` requires it |
| `Levels` | `MorphService` clones `Levels.Levels` into each morph |
| `KnitServices` | `KnitService` registers it |
| `DamageBoost`, `Gcells`, `HealthCommandFix` | untouched by the framework |

## 2. Client: install KOClient

Create this tree in **StarterPlayer > StarterPlayerScripts**. The top item is a `LocalScript`.

```
StarterPlayer
└── StarterPlayerScripts
    ├── KOClient             LocalScript     <- EditedScripts/StarterPlayer/StarterPlayerScripts/KOClient/init.client.lua
    │   ├── Config           ModuleScript    <- Config.lua
    │   ├── Core             Folder
    │   │   ├── Lifecycle    ModuleScript    <- Core/Lifecycle.lua
    │   │   ├── Logger       ModuleScript    <- Core/Logger.lua
    │   │   └── Util         ModuleScript    <- Core/Util.lua
    │   └── Controllers      Folder
    │       ├── Chat         ModuleScript    <- Controllers/Chat.lua
    │       ├── Effects      ModuleScript    <- Controllers/Effects.lua
    │       ├── Hud          ModuleScript    <- Controllers/Hud.lua
    │       ├── Knit         ModuleScript    <- Controllers/Knit.lua
    │       ├── Menu         ModuleScript    <- Controllers/Menu.lua
    │       ├── Ocean        ModuleScript    <- Controllers/Ocean.lua
    │       ├── Settings     ModuleScript    <- Controllers/Settings.lua
    │       ├── Sounds       ModuleScript    <- Controllers/Sounds.lua
    │       └── Touch        ModuleScript    <- Controllers/Touch.lua
    └── RbxCharacterSounds   LocalScript     <- leave EMPTY (see below)
```

### Delete these 14 client scripts (StarterPlayerScripts)

| Delete | Now lives in |
|---|---|
| `KnitClientBootstrap` | `Controllers/Knit` |
| `MenuCameraController`, `Daiju` | `Controllers/Menu` |
| `SettingsSaver` | `Controllers/Settings` |
| `TouchControlHider` | `Controllers/Touch` |
| `KillMessageDisplay`, `EliminatorPopupDisplay` | `Controllers/Chat` |
| `BossHUD`, `RaffleHUD`, `BlindEffect`, `HideOwnTag` | `Controllers/Hud` |
| `Ocean` | `Controllers/Ocean` |
| `RainClient`, `PulseRenderer` | `Controllers/Effects` |

### RbxCharacterSounds: keep the script, delete its code

Its logic now lives in `Controllers/Sounds`. **Do not delete the script itself.** Roblox only skips inserting its own default character sounds when a script with this exact name exists in StarterPlayerScripts. So:

1. Open `RbxCharacterSounds`.
2. Select all, delete everything, leave it empty.

Deleting the script gives you Roblox's default footsteps on top of yours. Leaving the old code in gives you doubled sounds.

## 3. Playtest

Press Play. Output should show:

```
[KOFramework] Started. Service status:
  Morph ... Knit      (one line per service)
[KOClient] Started. Controller status:
  Knit ... Sounds     (one line per controller)
[Knit] Client started successfully
```

Then check, in a local server with 2 players if you can: menu camera on join, picking a morph, death returning to the menu, FOV slider saving, boss/raffle/kill messages, ocean, rain, pulses, and the touch controls on a mobile emulator.

## 4. Troubleshooting

| You see | Fix |
|---|---|
| `[KOFramework] Not starting: disable or delete these replaced scripts first: ...` | Delete or disable the scripts it names in ServerScriptService. Nothing was started, so the old setup keeps running. |
| `[KOClient] Not starting: delete or disable these replaced scripts first: ...` | Same, in StarterPlayerScripts. |
| No `[KOFramework]` / `[KOClient]` lines at all | Wrong class or location. `KOFramework` must be a `Script` in ServerScriptService, `KOClient` a `LocalScript` in StarterPlayerScripts. |
| `module not found: ServerScriptService.framework.modules.X` | The `framework/modules` folder or that module was deleted. Restore it. |
| `[Hud] BossHud failed: ...` (or any `[Controller] Feature failed`) | That one feature errored. The rest keep running. The message names the cause. |
| Doubled or default footsteps | `RbxCharacterSounds` is missing (default injected) or still contains the old code (doubled). It must exist and be empty. |

## 5. Rollback

Delete `KOFramework` and `KOClient`, then restore the deleted scripts from your `.rbxl` backup. The old versions are also in this repo's git history: every sync commit keeps the previous `scripts/` contents.

## 6. After you publish

The sync workflow will mirror the new setup into `scripts/` within 6 hours, so `KOFramework` and `KOClient` will appear there too. That is expected. Keep editing in `EditedScripts/`, not in the mirror, and copy any change you make in Studio back here.

## Notes

- Both frameworks were syntax-checked with a Luau parser, and the server unit tests cover the pure logic. Neither could be run inside Roblox from here, so playtest in a copy of the place before publishing.
- The client merge keeps every original behaviour. Each feature runs in its own protected thread, so one failing feature no longer takes others down with it.
- Left as in the original: the ENTITY menu entry unlock is tied to the username in `Config.Menu.EntityUnlockUser`; `Sounds` still uses the `rbxassetid://IDHERE` placeholders; chat messages are silently skipped when the `RBXSystem` channel is missing (the legacy-chat fallback only runs if TextChatService errors).
