# Halloween and Candy: what to delete and what replaces it

Candy and the Halloween kaijus are only obtainable October through November (UTC). Everything below lives in `EditedScripts/`. Duplicate scripts across the whole place are still tracked in `DELETE_AND_REPLACE.md`.

## How it works

- Kill reward: when a player gets the top kill, they earn 5 Candy per full 1000 max HP of the victim (1500 HP = 5, 2000 HP = 10, 999 HP = 0). Outside October and November nothing is awarded.
- Candy is stored as the `Candy` attribute on the player and saved in the `Candy_v1` DataStore. It is not in leaderstats.
- The Candy row only appears in the reward indicator when Candy was earned on that kill.
- Halloween kaijus live in `ReplicatedStorage.MorphSupplies.Morphs.<folder starting with "Halloween">`. Same setup as other morphs; `Stats.Price` is a Candy price for these.
- Menu list: names of Halloween kaijus are orange. The button reads `BUY (500 Candy)` during the season, and `Offsale until halloween` when the season is over and the kaiju is not owned. Owned ones stay selectable all year.
- Testing: set the `HolidayOverride` attribute on ReplicatedStorage to `Halloween` (force on) or `None` (force off). Clear it for real dates.

## Add (new in the game)

| Put in game | From |
| --- | --- |
| `ReplicatedStorage.CandyConfig` (ModuleScript) | `EditedScripts/ReplicatedStorage/CandyConfig.lua` |
| `ServerScriptService.Server.Services.CandyService` (ModuleScript) | `EditedScripts/ServerScriptService/Server/Services/CandyService.lua` |

## Replace (delete the old script, put the new one in its place)

| Old script in game | Replaced by | What changed |
| --- | --- | --- |
| `ServerScriptService.framework.modules.Combat` | `EditedScripts/BeamCombat/ServerScriptService/framework/modules/Combat.lua` | Calls `_G.AwardCandy` on a kill |
| `ServerScriptService.framework.modules.Data` | `EditedScripts/BeamCombat/ServerScriptService/framework/modules/Data.lua` | Finds morphs inside the Halloween folder, buys Halloween kaijus with Candy, refuses off season |
| `ServerScriptService.framework.modules.Character` | `EditedScripts/BeamCombat/ServerScriptService/framework/modules/Character.lua` | Morph lookup searches inside the Halloween folder |
| `ServerScriptService.SecurityPolicy` | `EditedScripts/ServerScriptService/SecurityPolicy.lua` | Accepts morphs nested in the Halloween folder |
| `ServerScriptService.Server.Services.MorphService` | `EditedScripts/ServerScriptService/Server/Services/MorphService.lua` | Morph lookup searches inside the Halloween folder |
| `ServerScriptService.Server.Services.IndicatorService` | `EditedScripts/ServerScriptService/Server/Services/IndicatorService.lua` | `_G.ShowIndicator` takes a sixth `candy` argument |
| `ServerScriptService.Server` (init) | `EditedScripts/ServerScriptService/Server/init.server.lua` | Registers CandyService |
| `StarterPlayerScripts.Client.Controllers.Indicators` | `EditedScripts/StarterPlayer/StarterPlayerScripts/Client/Controllers/Indicators.lua` | Orange Candy row, only drawn when Candy is above 0 |
| `StarterGui.NEWMenu.Kaijus.List.PopulateList` | `EditedScripts/StarterGui/NEWMenu/Kaijus/List/PopulateList.client.lua` | Pulls from Halloween folder, orange names, Candy price, offsale text |
| `StarterGui.NEWMenu.UIScript` | `EditedScripts/StarterGui/NEWMenu/UIScript.client.lua` | Play check finds Halloween morphs |
| `StarterGui.NEWMenu.Kaijus.Stats.SkillPoints.Modifiers.ModifierUIHandler` | `EditedScripts/StarterGui/NEWMenu/Kaijus/Stats/SkillPoints/Modifiers/ModifierUIHandler.client.lua` | Base stats lookup finds Halloween morphs |

## Check before deleting

- `Character` and `MorphService` both handle the morph request. Both are patched. If only one is live in the game, the other can go.
- The Halloween folder currently has a long name ending in "THEY ARE CANDY". Any name starting with "Halloween" works. Renaming it to just `Halloween` is cleaner.
- Anything in the old menus (`oldMenu`) still indexes `Morphs` directly and does not see Halloween kaijus. It is unused, so it can be deleted.
