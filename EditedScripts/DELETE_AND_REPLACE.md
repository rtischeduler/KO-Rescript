# Delete and replace

Counts come from the git tree of `scripts/` (1056 script files). Identical files were matched by blob hash, so nothing was downloaded. `scripts/` stays a read-only mirror; every delete below happens in the place, not in this repo.

709 of the 1056 scripts are 3 bytes or smaller (empty stubs). Most of the duplication is stubs inside duplicated models, not duplicated logic.

## Overall checklist

Do these in order in Studio. Everything under `EditedScripts/` is the replacement; `scripts/` is only a mirror.

| # | Delete | Replaced by |
|---|---|---|
| 1 | Loose scripts in `StarterPlayerScripts` (15) and `ServerHandler`, `MorphBootstrap`, `HealthEnforcer`, `GCellIntegrityGuard`, `PlayerEliminator`, `SettingsStore` | `Server` and `Client` frameworks, steps in `SETUP.md` |
| 2 | `Server/Core` and `Client/Core` Lifecycle, Logger, Util | `ReplicatedStorage/Shared` |
| 3 | `ReplicatedStorage/Recolors` Folder (29 folders, 231 values) | `ReplicatedStorage/Recolors` ModuleScript from `EditedScripts/ReplicatedStorage/Recolors.lua` |
| 4 | Old `RecolorPopulator` and old `framework/modules/Data` | the two edited copies listed in section 5 (both now `require` the module, so step 3 must be done first) |
| 5 | `Interface/Colors/Colors/*` and `Interface/Recolor/LocalScript` | nothing, they are empty |
| 6 | `Roar1Script`, `Roar2Script`, every `DPS` script | `initRoar` and `initDPS` in `Combat.lua`, then run `Migration/MigrateDPSAndRoar.lua` |
| 7 | Duplicate models, retired kaijus, empty stubs | sections 1, 2 and 6 below |
| 8 | Old `framework/modules/World` | edited copy, section 9 |
| 9 | Old `Combat`, `World`, `BeamSystem`, `DPSTemplate` and `Control`, plus the `Server` and `Client` init scripts | edited copies, section 17, and add `IndicatorService` and `Indicators` |

After step 3, anything else that read `ReplicatedStorage.Recolors.<name>.Primary.Value` must use `require(Recolors).Data[name].Primary`. Only `Data` and `RecolorPopulator` did in this repo's scripts.

## 1. Delete, copy already exists elsewhere

| Delete in the place | Scripts | Kept copy |
|---|---|---|
| `Lighting/mappiece (2)` | 103 | `Workspace/Map` |
| `Lighting/mappiece` | 103 | `Workspace/Map` (all 103 match by path and content) |
| `ReplicatedStorage/MINILLA` | 1 | `ReplicatedStorage/MorphSupplies/Morphs/MINILLA` (identical) |
| `Lighting/GUIs/oldMenu` | 14 | `StarterGui/NEWMenu` |
| `ReplicatedStorage/oldMenu` | 24 | `StarterGui/NEWMenu` |
| `Lighting/GUIs/GameGui` | 25 | `StarterGui/GameGui` (only 4 match, so open it first and confirm it is only an old version) |
| `ServerStorage/TITANUS GHIDORAH` | 5 | `MorphSupplies/Morphs/TITANUS GHIDORAH` (2 of 5 match; compare the other 3) |
| `ReplicatedStorage/FINAL WARS GODZILLA` | 7 | `MorphSupplies/Morphs/FINAL WARS GODZILLA` (none match; compare before deleting) |

## 2. Retired kaijus

`Lighting/KaijusUnused` holds 160 scripts across 21 retired kaijus. Six have a live morph with the same name: Biollante, HEISEI GODZILLA, MALE MUTO, Mothra, Space Godzilla, TITANUS GHIDORAH. Delete those six copies. The other 15 (Anguirus, Behemoth, FinalWars, FireGodzilla, Human, KamataKun, KingGhidorah, Mosura, OldFire, Rodan, Shin, ShinagawaKun, Tank, VolcanicBio, oldFrozen) have no same-named morph, so decide per kaiju. If a kaiju is coming back, move it into `MorphSupplies/Morphs` instead of deleting it.

## 3. Many copies of one script, replace with one module

| Old | Copies | Replaced by |
|---|---|---|
| `Roar1Script` and `Roar2Script` in each morph's `CharacterScripts` | 77 files in 39 places | `initRoar` in `BeamCombat/ServerScriptService/framework/modules/Combat.lua`; it hooks every `Roar#` RemoteEvent under a `CharacterScripts` folder and keeps the `Debounce` value behaviour |
| `DPS.server.lua` in each `HitParts` model | 19 files | `initDPS` in `Combat.lua`, driven by the `DPSPart` tag and per-part attributes |
| `GCellCounterLS` | 3 | `Client/Controllers/Hud` |
| `LocalScript` inside `BuyGCellWindow/GCells/<amount>` | 7 | one script that reads the button name as the amount |

Copies of the Roar and DPS scripts are not all byte-identical: some differ slightly, so their differences have to be listed before the modules are written. Do this after the exports in section 5 exist.

## 4. Already replaced by the framework

See `README.md` in this folder for the full table. Old `ServerHandler`, `MorphBootstrap`, `HealthEnforcer`, `GCellIntegrityGuard`, `PlayerEliminator`, `SettingsStore` and the 15 loose `StarterPlayerScripts` scripts are replaced by `Server` and `Client`.

## 5. Recolors

Recolors are many separate values today. They become one module.

| Old | Replaced by |
|---|---|
| `ReplicatedStorage/Recolors` Folder: 29 child Folders, 231 Color3Value/StringValue (Primary, Secondary, Tertiary, EyeColor and their Material values) plus `RandomGreen`/`KeepColor` attributes | `ReplicatedStorage/Recolors` ModuleScript (`EditedScripts/ReplicatedStorage/Recolors.lua`), `Data[name]` holds every color, material and flag; `Order` lists names; `Unlock` holds the Diamond and Gold rules. Delete the Folder, then add the ModuleScript under the same name |
| `Lighting/GUIs/GameGui/MainFrame/Interface/Colors/Colors/*` (`LocalRecolor`, `RecolorScript` x6, all empty) | deleted, no replacement needed |
| `Interface/Recolor/LocalScript` (empty) | deleted |
| `StarterGui/NEWMenu/Kaijus/Stats/Recolors/RecolorPopulator` (loops the Folder, hard-codes Diamond and Gold level) | `EditedScripts/StarterGui/NEWMenu/Kaijus/Stats/Recolors/RecolorPopulator.client.lua`: builds buttons from `Recolors.Order` and `Recolors.Get`, level 50 comes from `Recolors.Unlock.Gold.level` |
| `ServerScriptService/framework/modules/Data` (`getRecolorData` read the Folder value by value) | `EditedScripts/BeamCombat/ServerScriptService/framework/modules/Data.lua`: `getRecolorData` returns `Recolors.Get(name)`; same keys, so the apply code is unchanged |

The module was generated from `exports/recolors.json`. Readers that did `Recolors:FindFirstChild(name).Primary.Value` now do `require(Recolors).Data[name].Primary`. `exports/value-overview.json` lists every value-type instance grouped by parent, so anything else that should become a module can be picked from it.

## 6. Empty stubs

Delete all scripts of 3 bytes or smaller once their parent copy is gone. 296 of them are `DestroyBuilding` stubs inside `Workspace/Map`. Before deleting those, search the place for the name `DestroyBuilding`: code search of this repo returned no hits for it, but that search can miss files, so confirm in Studio.

## Do not touch

`ReplicatedStorage/Knit/_Index` (package shims such as `Signal`, `Promise`, `Trove` repeat on purpose), `HD Admin`, `Chat`, `GuiAnimatorPlugin`.

## 7. Framework duplicates

| Old | Replaced by |
|---|---|
| `Server/Core/Lifecycle`, `Logger`, `Util` | `ReplicatedStorage/Shared/Lifecycle`, `Logger`, `Util` |
| `Client/Core` (Lifecycle, Logger, Util) | `ReplicatedStorage/Shared`, folder deleted |

Client `Util.spawn` was merged into the shared `Util`.

## 8. Roar and DPS handler

Both handlers live in `Combat.lua` and start from `Combat.Init`. Run `Migration/MigrateDPSAndRoar.lua` in the Studio command bar (it prints only while `DRY_RUN = true`), check the list, set `DRY_RUN = false`, run it again, then publish. It reads each old script, writes its values onto the part as attributes, adds the `DPSPart` tag, then deletes the script. Roar scripts are deleted with no attributes.

DPS attributes on the tagged part (defaults in brackets):

| Attribute | Replaces |
|---|---|
| `Damage` (0.9) | the number in `h.Health - N`; seen values 0.9, 1, 2 |
| `GCellRate` (0.2) | GCell gain per hit; seen values 0.2, 0.9 |
| `Cooldown` (0.5) | the per-target debounce; 0 for the variants that had none |
| `DamageMultiplier` (1) | `VOLCANIC_DAMAGE_MULTIPLIER = 1.5` in ZILLA `Firebomb` |
| `LevelScaled` | the variants that read `ReplicatedStorage/DamageMultiplierPerLevel` (HEISEI, Space Godzilla, TITANUS beams) |
| `RequireBlastActive` | the `BlastActive` gate in the HeiseiBlast variants |

Behaviour changes to know about:
- The attacker is the first player found walking up the part's ancestors, then the `PlayerName` StringValue. Hitting your own character is always ignored; the old `BlastHitbox` and `BurningHeiseiBlast` scripts never found an attacker from the part itself, so they now pay GCells.
- Roar animation always plays at Action priority with fade 0.1 and weight 10, and the wait uses `TimeLength / PlaybackSpeed`. The old plain copies used default priority.
- ZILLA's `Roar1Script` keeps a `roarTrack` variable the others lack. The handler does not stop the animation early, so check ZILLA's roar once in game.
- `ROAR1` and `ROAR2` LocalScripts in `KaijusUnused/FireGodzilla` are a different, client-side script. They are not covered, and that kaiju is retired anyway.

## 9. Building collapse

`framework/modules/World` is replaced by `EditedScripts/BeamCombat/ServerScriptService/framework/modules/World.lua`. Only `initBuilding` changed.

| Old | Now |
|---|---|
| `COLLAPSE_TIME = 3.8`, ease `p ^ 2.4` | `2.6`, ease `p ^ 1.7`, so the fall starts sooner and finishes quicker |
| 10 chunks thrown in one burst after the collapse ended | 12 chunks thrown one at a time across the collapse (`DEBRIS_CHUNKS`), slower launch speed 18 to 45 |
| Chunks vanished after 5 s | each chunk fades out over its last second, then is removed (lives 2.4 to 3.4 s) |
| Building parts kept their collision | `CanCollide` is off on every building part when it starts to collapse, restored from the saved value on respawn |

## Update: building lights, beam end effect, fly animation

| Delete | Replace with |
| --- | --- |
| ServerScriptService/framework/modules/World (whole ModuleScript source) | EditedScripts/BeamCombat/ServerScriptService/framework/modules/World.lua |
| ReplicatedStorage/BeamSystem (whole ModuleScript source) | EditedScripts/BeamCombat/ReplicatedStorage/BeamSystem.lua |
| ReplicatedStorage/PlayerScripts/Control (LocalScript source) | EditedScripts/ReplicatedStorage/PlayerScripts/Control/init.client.lua |

Inside World.lua, initWindowLights: the old ensureLight, removeLight, turnOn, turnOff and the Brightness 0.8 / Range 40 light are replaced by a queued builder (3 lights per frame), a 6 second staggered turn on, a 5 second staggered turn off, and Brightness 1.6 / Range 30. Tune LIGHT_BRIGHTNESS and LIGHT_RANGE at the top of initWindowLights.

Inside BeamSystem.lua: PlayerRemoving now runs ForceCleanup before clearing state, the character AncestryChanged hook cleans up when the character leaves mid beam, and the impact anchor now follows the beam end every frame instead of using a stale raycast hit.

Inside Control: endFlight now stops the Fly and Swim tracks explicitly and re-checks one frame later, and the per frame airTrack replay is skipped once the mode is Land.

## Update: single model in build/

| Delete | Replace with |
| --- | --- |
| build/BeamCombat.rbxmx, Client.rbxmx, Server.rbxmx, Shared.rbxmx, Recolors.rbxmx, RecolorPopulator.rbxmx | build/KO-Rescript.rbxmx |
| tools/build_rbxmx.py (six targets) | tools/build_rbxmx.py (one merged model) |

KO-Rescript.rbxmx holds one folder per place location. Drag the children of each folder into the matching service and merge or overwrite by name:

| Model folder | Goes into |
| --- | --- |
| ReplicatedStorage | ReplicatedStorage |
| ServerScriptService | ServerScriptService |
| StarterGui | StarterGui |
| StarterPlayer/StarterPlayerScripts | StarterPlayer/StarterPlayerScripts |
| Migration | run once, then delete |

## Model pack

build/ was cleared of Client, RecolorPopulator, Recolors, Server, Shared and BeamCombat models. build/KO-Rescript.rbxmx now holds only the edited scripts, laid out by their real paths:

| Model path | Class | Goes to |
| --- | --- | --- |
| KO-Rescript/ReplicatedStorage/BeamSystem | ModuleScript | ReplicatedStorage.BeamSystem |
| KO-Rescript/StarterPlayer/StarterPlayerScripts/Client/Controllers/Effects | ModuleScript | StarterPlayer.StarterPlayerScripts.Client.Controllers.Effects (the Client folder in the model is only a container, drop Effects into your existing Client.Controllers) |
| KO-Rescript/StarterPlayer/StarterPlayerScripts/Client/Controllers/Ocean | ModuleScript | StarterPlayer.StarterPlayerScripts.Client.Controllers.Ocean (drop into your existing Client.Controllers) |
| KO-Rescript/StarterGui/GameGui/MainFrame/Interface/Backpack/BackpackScript | LocalScript | StarterGui.GameGui.MainFrame.Interface.Backpack.BackpackScript (replace the existing LocalScript, the folders in the model are only containers) |
| KO-Rescript/ReplicatedStorage/HolidayConfigs | ModuleScript | ReplicatedStorage.HolidayConfigs (new, nothing to delete) |
| KO-Rescript/ServerScriptService/framework/modules/World | ModuleScript | ServerScriptService.framework.modules.World |
| KO-Rescript/ReplicatedStorage/PlayerScripts/Control | LocalScript | ReplicatedStorage.PlayerScripts.Control |
| KO-Rescript/StarterGui/ClientHandler | LocalScript | StarterGui.ClientHandler |

Drag each service folder's contents onto the matching service, replacing the old script of the same name.

## Optimization pass

Behavior and visuals are unchanged. ClientHandler: the per frame underwater blur check now caches the Ocean part and only writes Enabled when the value changes. BeamSystem: the impact raycast reuses one RaycastParams instead of allocating a new one every other frame.

## Holiday configs

HolidayConfigs is a new ModuleScript in ReplicatedStorage. World now reads it, so World and HolidayConfigs must go in together.

| Holiday | Months | Lighting and weather | Building lights | Ground |
| --- | --- | --- | --- | --- |
| Halloween | October, November | purple and orange day and night, green accents, purple rain fog | one color per building from orange, purple, magenta, green | Grass parts and Grass terrain turn purple |
| Christmas (placeholder) | December, January | cool white and blue, snow weather | one color per building from red, green, warm white | unchanged |

Set the ReplicatedStorage attribute HolidayOverride to Halloween, Christmas or None to test a holiday outside its months. Snow fires a ToggleSnow RemoteEvent in ReplicatedStorage if one exists; nothing client side listens to it yet.

## Weather and timing smoothing

World: the day is now 30 minutes long (DAY_LENGTH_MIN at the top of initDayNight), dawn and dusk use an eased curve, and rain or snow blends the fog, atmosphere and cloud values in and out over 10 seconds (WEATHER_FADE) instead of snapping. Halloween rain fog is now a grayer purple. Effects: rain particles are tinted by HolidayConfigs RainColor (purple for Halloween) and fade in and out over 6 seconds along with the rain sound. The rain sky swap still switches instantly because a Sky cannot be faded.

## Performance pass

| Change | File | Effect |
| --- | --- | --- |
| Building glow lights get a BuildingGlowLight tag | World | lets clients cull them |
| Client turns off glow lights beyond 300 studs and keeps only the nearest 60 on (160 studs and 20 on touch devices or quality 1 to 4) | ClientHandler | far fewer dynamic lights on low end devices, nothing replicates |
| Ocean mesh update rate drops toward 12 per second when the frame rate falls under 30 and recovers above 45 | Ocean | the biggest per frame client cost scales down on weak devices |
| Beam aim is only sent when the aim or shift lock changed | BackpackScript | fewer remote calls while a beam is held |
| Rain particle rate is halved on touch devices or quality 1 to 4 | Effects | fewer particles on low end |

Not changed on purpose: the 0.1 second damage loop in DPSTemplate and the hit scans in Combat are already cheap, and caching building windows in World would need invalidation logic that risks visual changes.

## 10. Ocean depth, water FX and workflow

| Delete | Replaced by |
| --- | --- |
| `place/place.rbxlx.gz` and any `.part-*` files (the workflow removes them on its next run) | `place/place.rbxlx`, committed by `sync-roblox-scripts.yml`; stored with Git LFS only when the file is over 95 MB |
| Any manual sand floor or shore edits you made to deepen the ocean | `Services/OceanDepthService`, driven by `Config.OceanDepth` |
| Any old splash or wake scripts inside kaiju models | `Controllers/WaterFX`, driven by `Config.WaterFX` |

OceanDepthService: moves every part named `FloorName` (default `Bottom`) under Workspace down by `DepthDrop`, then grows every upright WedgePart anywhere in the game tree that matches the material and color of a Bottom part (within `ColorTolerance`) by `WedgeGrow` studs downward with its top edge kept in place. It runs once per server (workspace attribute `OceanDeepened`). Set `Enabled = false` to turn it off.

WaterFX: foam wake while moving in the water, spray at high speed, and a splash burst on entry, for every player, scaled by root part size and culled past `MaxDistance`. The existing Ocean ripples are untouched.

## 11. Duplicate scan of scripts/ (by blob hash, nothing downloaded)

Non-stub scripts only (over 3 bytes): 11 groups, 19 redundant files, 15.1 KB redundant.

| Biggest duplicated script | Copies | Bytes each |
| --- | --- | --- |
| `scripts/ReplicatedStorage/Knit/_Index/sleitnick_signal@2.0.1/signal/init.spec.lua` | 2 | 4272 |
| `scripts/Lighting/KaijusUnused/TITANUS GHIDORAH/HitParts/Beam3/DPS.server.lua` | 3 | 1415 |
| `scripts/StarterGui/NEWMenu/Kaijus/GCells/GCellCounterLS.client.lua` | 3 | 1012 |
| `scripts/ReplicatedStorage/MorphSupplies/Morphs/MINILLA/CharacterScripts/Minilla.server.lua` | 3 | 985 |
| `scripts/StarterGui/GameGui/MainFrame/Interface/BuyGCellWindow/GCells/5000/LocalScript.client.lua` | 6 | 273 |
| `scripts/Lighting/KaijusUnused/Space Godzilla/CharacterScripts/Roar2/Roar2Script.server.lua` | 2 | 1300 |
| `scripts/Lighting/KaijusUnused/Space Godzilla/CharacterScripts/Roar1/Roar1Script.server.lua` | 2 | 1300 |
| `scripts/ReplicatedStorage/Knit/_Index/sleitnick_input@2.3.0/Signal.lua` | 3 | 74 |
| `scripts/ReplicatedStorage/Knit/_Index/sleitnick_timer@1.1.2/Signal.lua` | 2 | 74 |
| `scripts/ReplicatedStorage/Knit/_Index/sleitnick_component@2.4.8/Promise.lua` | 2 | 73 |

EditedScripts files that match a mirrored script byte for byte. These are already installed in the place (the mirror is synced from it), so they are not duplicates to delete; they only show which edits are already live. Files missing from this list still need to be copied in.

| EditedScripts file | Same as |
| --- | --- |
| `EditedScripts/BeamCombat/ReplicatedStorage/DPSTemplate.server.lua` | `scripts/ReplicatedStorage/DPSTemplate.server.lua` |
| `EditedScripts/BeamCombat/ServerScriptService/framework/modules/Combat.lua` | `scripts/ServerScriptService/framework/modules/Combat.lua` |
| `EditedScripts/BeamCombat/ServerScriptService/framework/modules/Data.lua` | `scripts/ServerScriptService/framework/modules/Data.lua` |
| `EditedScripts/ReplicatedStorage/Recolors.lua` | `scripts/ReplicatedStorage/Recolors.lua` |
| `EditedScripts/ReplicatedStorage/Shared/Lifecycle.lua` | `scripts/ReplicatedStorage/Shared/Lifecycle.lua` |
| `EditedScripts/ReplicatedStorage/Shared/Logger.lua` | `scripts/ReplicatedStorage/Shared/Logger.lua` |
| `EditedScripts/ReplicatedStorage/Shared/Util.lua` | `scripts/ReplicatedStorage/Shared/Util.lua` |
| `EditedScripts/ServerScriptService/Server/Config.lua` | `scripts/ServerScriptService/Server/Config.lua` |
| `EditedScripts/ServerScriptService/Server/Core/PlayerHooks.lua` | `scripts/ServerScriptService/Server/Core/PlayerHooks.lua` |
| `EditedScripts/ServerScriptService/Server/Core/Util.lua` | `scripts/ServerScriptService/Server/Core/Util.lua` |
| `EditedScripts/ServerScriptService/Server/Services/EliminatorService.lua` | `scripts/ServerScriptService/Server/Services/EliminatorService.lua` |
| `EditedScripts/ServerScriptService/Server/Services/GCellGuardService.lua` | `scripts/ServerScriptService/Server/Services/GCellGuardService.lua` |
| `EditedScripts/ServerScriptService/Server/Services/HealthService.lua` | `scripts/ServerScriptService/Server/Services/HealthService.lua` |
| `EditedScripts/ServerScriptService/Server/Services/KnitService.lua` | `scripts/ServerScriptService/Server/Services/KnitService.lua` |
| `EditedScripts/ServerScriptService/Server/Services/LegacyService.lua` | `scripts/ServerScriptService/Server/Services/LegacyService.lua` |
| `EditedScripts/ServerScriptService/Server/Services/MorphService.lua` | `scripts/ServerScriptService/Server/Services/MorphService.lua` |
| `EditedScripts/ServerScriptService/Server/Services/SettingsService.lua` | `scripts/ServerScriptService/Server/Services/SettingsService.lua` |
| `EditedScripts/ServerScriptService/Server/init.server.lua` | `scripts/ServerScriptService/Server/init.server.lua` |
| `EditedScripts/StarterPlayer/StarterPlayerScripts/Client/Config.lua` | `scripts/StarterPlayer/StarterPlayerScripts/Client/Config.lua` |
| `EditedScripts/StarterPlayer/StarterPlayerScripts/Client/Controllers/Chat.lua` | `scripts/StarterPlayer/StarterPlayerScripts/Client/Controllers/Chat.lua` |
| `EditedScripts/StarterPlayer/StarterPlayerScripts/Client/Controllers/Hud.lua` | `scripts/StarterPlayer/StarterPlayerScripts/Client/Controllers/Hud.lua` |
| `EditedScripts/StarterPlayer/StarterPlayerScripts/Client/Controllers/Knit.lua` | `scripts/StarterPlayer/StarterPlayerScripts/Client/Controllers/Knit.lua` |
| `EditedScripts/StarterPlayer/StarterPlayerScripts/Client/Controllers/Menu.lua` | `scripts/StarterPlayer/StarterPlayerScripts/Client/Controllers/Menu.lua` |
| `EditedScripts/StarterPlayer/StarterPlayerScripts/Client/Controllers/Settings.lua` | `scripts/StarterPlayer/StarterPlayerScripts/Client/Controllers/Settings.lua` |
| `EditedScripts/StarterPlayer/StarterPlayerScripts/Client/Controllers/Sounds.lua` | `scripts/StarterPlayer/StarterPlayerScripts/Client/Controllers/Sounds.lua` |
| `EditedScripts/StarterPlayer/StarterPlayerScripts/Client/Controllers/Touch.lua` | `scripts/StarterPlayer/StarterPlayerScripts/Client/Controllers/Touch.lua` |
| `EditedScripts/StarterPlayer/StarterPlayerScripts/Client/Core/Util.lua` | `scripts/StarterPlayer/StarterPlayerScripts/Client/Core/Util.lua` |
| `EditedScripts/StarterPlayer/StarterPlayerScripts/Client/init.client.lua` | `scripts/StarterPlayer/StarterPlayerScripts/Client/init.client.lua` |

`build/KO-Rescript.rbxmx` holds only the newest edits, because the earlier ones are already applied in the place: `ReplicatedStorage/HolidayConfigs` and `ServerScriptService/framework/modules/World`. Drop each into the matching existing location and replace the old copy. `build-rbxm.yml` rebuilds it whenever `EditedScripts/` or `tools/build_rbxmx.py` changes.

## 12. Halloween update

Halloween is now October only (`Months = { 10 }`). The day and night sky, fog, cloud and rain colors in `HolidayConfigs` are saturated orange and purple with much lower haze, so the old grey wash is gone. In `World`, the building palette is refreshed every second and on every night start, so window flicker (including daytime and collapse flicker) and the building glow lights use the Halloween colors.

## 13. Depth, swimming and sky retune

`OceanDepth` now drops by 25 studs (`DepthDrop`, `WedgeGrow`) and finds floors through the `FloorNames` list, so any other part that acts as a wall at the old depth can be added by name. In `Control`, swimming near a surface no longer shoves you upward; it only stops you sinking into it. Halloween day is darker, with a purple atmosphere, orange horizon, purple clouds and a little green in the bounce light.

## 14. White sky and collapse debris

The place Lighting held Atmosphere Offset 0.25, Haze 2, Bloom Intensity 1 with Threshold 2, and SunRays Intensity 0.25. During Halloween, `World` now applies the `Effects` block in `HolidayConfigs.Halloween` on top of those (Atmosphere Offset and Glare 0, Bloom 0.2 at threshold 3, SunRays 0.02, ExposureCompensation -0.4) and restores the saved originals when no holiday is active. The Halloween atmosphere and horizon colors are also dimmer so they no longer clip to white.

Collapse chunks use the CollapseDebris collision group, which does not collide with the Characters group. `World` puts every player character into Characters, so debris still hits the map and other debris but passes through players.

## 15. Halloween day dimming and daytime lights

Halloween day brightness is now 0.85 with darker ambient light. During the Halloween day, `HolidayConfigs.Halloween.DayLights` lights a random 35 percent of buildings, and about half the windows in each, spread over 25 seconds with the usual flicker. They are cleared at night start, when every building lights as before, and a fresh random set is chosen each morning. The building point lights are dimmer (brightness 1.6 to 1.25).

## 16. Skys folder

| Delete in the place | Replaced by |
| --- | --- |
| Any Sky object sitting directly in `Lighting` (World destroys them on start anyway) | `Lighting/Skys` folder holding three Sky objects named `Dark`, `Rainy` and `Sunny` |
| `ReplicatedFirst/Rainy` | `Lighting/Skys/Rainy` |

`World` now keeps one active Sky in `Lighting`, cloned from `Skys`. During Halloween it is always `Dark` (set by `HolidayConfigs.Halloween.Sky`) and never changes, rain included. Otherwise it is `Sunny`, switching to `Rainy` while it rains. The swap checks once a second. If `Lighting/Skys` is missing, World leaves the sky alone after 30 seconds.

## 17. Kaiju Universe style indicators, sprint FOV and lighter rubble

| Delete in the place | Replaced by |
| --- | --- |
| `ServerScriptService/framework/modules/Combat` | `EditedScripts/BeamCombat/ServerScriptService/framework/modules/Combat.lua` |
| `ServerScriptService/framework/modules/World` | `EditedScripts/BeamCombat/ServerScriptService/framework/modules/World.lua` |
| `ReplicatedStorage/BeamSystem` | `EditedScripts/BeamCombat/ReplicatedStorage/BeamSystem.lua` |
| `ReplicatedStorage/DPSTemplate` | `EditedScripts/BeamCombat/ReplicatedStorage/DPSTemplate.server.lua` |
| `ReplicatedStorage/PlayerScripts/Control` | `EditedScripts/ReplicatedStorage/PlayerScripts/Control/init.client.lua` |
| `ServerScriptService/Server/init` and `StarterPlayerScripts/Client/init` | the edited copies, which register the two new scripts below |
| nothing, these are new | `ServerScriptService/Server/Services/IndicatorService` and `StarterPlayerScripts/Client/Controllers/Indicators` |

Every earning hit now reports to `_G.ShowIndicator(player, damage, gcells, xp, target)`. `IndicatorService` merges what one target gave you within 0.25 seconds and sends one `RewardIndicator` RemoteEvent call per target, so a beam sweeping three players or a building makes three separate indicators and a single target never spams. The sources are building damage and its G-Cell and XP reward in `World`, pulse, melee and beam hits and kill and assist rewards in `Combat` (anchored on the victim), the `DPSTemplate` and `BeamSystem` beam hits, and the DPS part hook in `Combat`. The `Indicators` controller draws each one as a small BillboardGui at the target, floating up and fading in about 1.5 seconds, with a red `Damage: N` line on top, a green `Gcells: N` line in the middle and a yellow `Exp: N` line at the bottom (only the lines that hit earned). The billboard is a fixed pixel size at 70 studs or closer and shrinks with camera distance down to 30 percent, so it is never huge, and up to 24 can show at once. The DPS part hook only reports G-Cells of 1 or more, because its default rate of 0.2 is rounded away by the IntValue.

`Control` raises the camera FOV by 12 over 0.3 seconds while sprinting and returns to whatever FOV the player had when they started sprinting. Change `SPRINT_FOV_BOOST` to tune it.

Building rubble is lighter: `DEBRIS_CHUNKS` 12 to 9, chunk sides 1 to 3.5 studs down to 0.8 to 2.8, and chunk life 2.4 to 3.4 seconds down to 2 to 2.8.

Duplicates: this update adds no copies and nothing new to delete. The 11 duplicate groups in section 11 still stand, and all of them are in the `scripts/` mirror.

Workflow: `sync-roblox-scripts.yml` now always commits the place. It writes `place/place.rbxlx`, or `place/place.rbxlx.gz` when the XML is over 95 MB, and the old Git LFS path is removed. Each run rebuilds the `place` folder, so the existing `place/place.rbxlx.gz` is replaced by itself or by the plain file automatically and needs no manual delete.
