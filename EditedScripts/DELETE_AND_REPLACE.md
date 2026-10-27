# Delete and replace

Counts come from the git tree of `scripts/` (1056 script files). Identical files were matched by blob hash, so nothing was downloaded. `scripts/` stays a read-only mirror; every delete below happens in the place, not in this repo.

709 of the 1056 scripts are 3 bytes or smaller (empty stubs). Most of the duplication is stubs inside duplicated models, not duplicated logic.

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
| `Roar1` and `Roar2` scripts in each morph's `CharacterScripts` | 77 files in 39 places | one `RoarService` in `KOFramework/Services`; it reads `Sounds/RoarN` and `Animations/RoarN` from the morph and keeps the `Debounce` value behaviour |
| `DPS.server.lua` in each `HitParts` model | 19 files | one `HitService` driven by a per-hitpart attribute for damage and GCell rate |
| `GCellCounterLS` | 3 | `KOClient/Controllers/Hud` |
| `LocalScript` inside `BuyGCellWindow/GCells/<amount>` | 7 | one script that reads the button name as the amount |

Copies of the Roar and DPS scripts are not all byte-identical: some differ slightly, so their differences have to be listed before the modules are written. Do this after the exports in section 5 exist.

## 4. Already replaced by the framework

See `README.md` in this folder for the full table. Old `ServerHandler`, `MorphBootstrap`, `HealthEnforcer`, `GCellIntegrityGuard`, `PlayerEliminator`, `SettingsStore` and the 15 loose `StarterPlayerScripts` scripts are replaced by `KOFramework` and `KOClient`.

## 5. Recolors

Recolors are many separate values today. They become one module.

| Old | Replaced by |
|---|---|
| Per-kaiju recolor values (names, primary, secondary, tertiary and eye colors) | `ReplicatedStorage/Recolors` ModuleScript returning one table keyed by kaiju, then recolor name |
| `Lighting/GUIs/GameGui/MainFrame/Interface/Colors/Colors/*` (`LocalRecolor`, `RecolorScript` x6, all empty) | deleted, no replacement needed |
| `Interface/Recolor/LocalScript` (empty) | deleted |
| `StarterGui/NEWMenu/Kaijus/Stats/Recolors/RecolorPopulator` (hard-codes Diamond and Gold) | same script, but reads the Recolors module and the unlock rules from it |

The module is generated from `exports/recolors.json`, which the sync workflow now writes. Run the workflow, tell me when it is done, and I will build the module from the real values. `exports/value-overview.json` lists every value-type instance grouped by parent, so anything else that should become a module can be picked from it.

## 6. Empty stubs

Delete all scripts of 3 bytes or smaller once their parent copy is gone. 296 of them are `DestroyBuilding` stubs inside `Workspace/Map`. Before deleting those, search the place for the name `DestroyBuilding`: code search of this repo returned no hits for it, but that search can miss files, so confirm in Studio.

## Do not touch

`ReplicatedStorage/Knit/_Index` (package shims such as `Signal`, `Promise`, `Trove` repeat on purpose), `HD Admin`, `Chat`, `GuiAnimatorPlugin`.
