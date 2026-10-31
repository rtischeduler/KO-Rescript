local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local process = require("@lune/process")

local Instance = roblox.Instance
local dir = "test_tmp"
if fs.isDir(dir) then fs.removeDir(dir) end
fs.writeDir(dir .. "/edited/ReplicatedStorage/PlayerScripts/Control")
fs.writeDir(dir .. "/edited/ReplicatedStorage")

local game = Instance.new("DataModel")
local rs = game:GetService("ReplicatedStorage")
local folder = Instance.new("Folder")
folder.Name = "PlayerScripts"
folder.Parent = rs
local control = Instance.new("LocalScript")
control.Name = "Control"
control.Source = "old source"
control.Parent = folder
local sound = Instance.new("Sound")
sound.Name = "Boom"
sound.Volume = 0.5
sound.Parent = control
local other = Instance.new("ModuleScript")
other.Name = "Other"
other.Source = "keep me"
other.Parent = rs
fs.writeFile(dir .. "/in.rbxl", roblox.serializePlace(game))

fs.writeFile(dir .. "/edited/ReplicatedStorage/PlayerScripts/Control/init.client.lua", "new source\n")
fs.writeFile(dir .. "/edited/ReplicatedStorage/Other.lua", "keep me\n")
fs.writeFile(dir .. "/edited/ReplicatedStorage/Nope.lua", "x\n")
fs.writeFile(dir .. "/manifest.txt", "ReplicatedStorage/PlayerScripts/Control/init.client.lua\nReplicatedStorage/Other.lua\nReplicatedStorage/Nope.lua\n")

local res = process.exec("lune", { "run", "tools/apply_edited_scripts", dir .. "/in.rbxl", dir .. "/out.rbxl", dir .. "/report.md", dir .. "/edited", dir .. "/manifest.txt", "0" })
assert(res.ok, res.stderr)

local out = roblox.deserializePlace(fs.readFile(dir .. "/out.rbxl"))
local c = out:GetService("ReplicatedStorage").PlayerScripts.Control
assert(c.Source == "new source", "source not updated: " .. c.Source)
assert(c:FindFirstChild("Boom") and c.Boom.Volume == 0.5, "sound lost")
assert(out:GetService("ReplicatedStorage").Other.Source == "keep me")
assert(out:GetService("ReplicatedStorage"):FindFirstChild("Nope") == nil, "Nope was created")
local result = fs.readFile(dir .. "/report.md.result")
assert(result:find("changed=1", 1, true) and result:find("missing=1", 1, true), result)
fs.removeDir(dir)
print("apply_edited_scripts tests passed")
