local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local process = require("@lune/process")
local Instance = roblox.Instance

local dir = "test_tmp_export"
if fs.isDir(dir) then fs.removeDir(dir) end
fs.writeDir(dir)

local game = Instance.new("DataModel")
local ws = game:GetService("Workspace")
local part = Instance.new("Part")
part.Name = "Thing"
part.Anchored = true
part.CFrame = roblox.CFrame.new(1, 2, 3)
part:AddTag("PlayerOnly")
part:SetAttribute("playerSlot", 4)
part.Parent = ws
local sv = Instance.new("StringValue")
sv.Name = "Holder"
sv.Value = "the Player ref"
sv.Parent = ws
local rs = game:GetService("ReplicatedStorage")
local mod = Instance.new("ModuleScript")
mod.Name = "Util"
mod.Source = "return 1"
mod.Parent = rs
fs.writeFile(dir .. "/in.rbxl", roblox.serializePlace(game))

local res = process.exec("lune", { "run", "tools/export_tree", dir .. "/in.rbxl", dir .. "/out", "player", "0" })
assert(res.ok, res.stderr .. res.stdout)

local tags = serde.decode("json", fs.readFile(dir .. "/out/tags.json"))
assert(tags[1].name == "PlayerOnly", "tag missing")
local attrs = serde.decode("json", fs.readFile(dir .. "/out/attributes.json"))
assert(attrs[1].name == "playerSlot", "attribute missing")
local search = serde.decode("json", fs.readFile(dir .. "/out/search.json"))
assert(#search.hits >= 3, "search hits: " .. #search.hits)
assert(fs.readFile(dir .. "/out/scripts/ReplicatedStorage/Util.lua") == "return 1", "script file")
local node = serde.decode("json", fs.readFile(dir .. "/out/tree/Workspace/Thing.json"))
assert(node.ClassName == "Part" and node.Properties.CFrame.Position[1] == 1, "part props")
assert(node.Tags[1] == "PlayerOnly")
fs.removeDir(dir)
print("export tests passed")
