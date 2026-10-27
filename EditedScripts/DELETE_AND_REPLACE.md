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
| KO-Rescript/ServerScriptService/framework/modules/World | ModuleScript | ServerScriptService.framework.modules.World |
| KO-Rescript/ReplicatedStorage/PlayerScripts/Control | LocalScript | ReplicatedStorage.PlayerScripts.Control |
| KO-Rescript/StarterGui/ClientHandler | LocalScript | StarterGui.ClientHandler |

Drag each service folder's contents onto the matching service, replacing the old script of the same name.

## Optimization pass

Behavior and visuals are unchanged. ClientHandler: the per frame underwater blur check now caches the Ocean part and only writes Enabled when the value changes. BeamSystem: the impact raycast reuses one RaycastParams instead of allocating a new one every other frame.
