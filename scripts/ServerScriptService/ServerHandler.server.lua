
local ServerScriptService = game:GetService("ServerScriptService")
if not ServerScriptService:GetAttribute("MorphBootstrapActive") then
    ServerScriptService:SetAttribute("MorphBootstrapActive", true)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local function getOrCreate(parent, className, name)
    local object = parent:FindFirstChild(name)
    if object and not object:IsA(className) then
        object:Destroy()
        object = nil
    end
    if not object then
        object = Instance.new(className)
        object.Name = name
        object.Parent = parent
    end
    return object
end

local morphReady = getOrCreate(ReplicatedStorage, "BoolValue", "MorphReady")
morphReady.Value = false
morphReady:SetAttribute("Error", nil)

local morphSupplies = getOrCreate(ReplicatedStorage, "Folder", "MorphSupplies")
local events = getOrCreate(morphSupplies, "Folder", "Events")
local fireEvent = getOrCreate(events, "RemoteEvent", "Fire")
local morphResult = getOrCreate(ReplicatedStorage, "RemoteEvent", "MorphResult")

local securityOk, SecurityPolicy = pcall(function()
    return require(ServerScriptService:WaitForChild("SecurityPolicy", 10))
end)
if not securityOk or type(SecurityPolicy) ~= "table" or type(SecurityPolicy.CanUseMorph) ~= "function" then
    local reason = securityOk and "SecurityPolicy.CanUseMorph is missing" or tostring(SecurityPolicy)
    morphReady:SetAttribute("Error", reason)
    warn("[MorphBootstrap] " .. reason)
    return
end

local tankSpawnMorphs = {
    ["MILITARY TANK [FREE]"] = true,
    ["F16C [FREE]"] = true,
}

local restrictedKaiju = {
    [string.lower("EVOLVED GOJIRA")] = true,
    [string.lower("D.E.M.O.N")] = true,
    [string.lower("Homelander")] = true,
    [string.lower("d")] = true,
    [string.lower("A-train")] = true,
    [string.lower("e")] = true,
    [string.lower("MG21")] = true,
}

local allowedPlayers = {
    [string.lower("AthosGame2023")] = true,
    [string.lower("mr_bolde2")] = true,
    [string.lower("DenisTheCheeseKing")] = true,
    [string.lower("BlueEnderCookie_2")] = true,
}

local function fail(player, message)
    morphResult:FireClient(player, false, nil, message)
end

fireEvent.OnServerEvent:Connect(function(player, selectedCreature)
    local ok, err = pcall(function()
        local morphs = morphSupplies:FindFirstChild("Morphs")
        if type(selectedCreature) == "string" and morphs then
            selectedCreature = morphs:FindFirstChild(selectedCreature)
        end
        if typeof(selectedCreature) ~= "Instance" or not selectedCreature:IsA("Model") then
            fail(player, "Invalid morph")
            return
        end
        if not SecurityPolicy.CanUseMorph(player, selectedCreature) then
            fail(player, "You do not own this kaiju")
            return
        end
        if restrictedKaiju[string.lower(selectedCreature.Name)] and not allowedPlayers[string.lower(player.Name)] then
            player:Kick("You cannot use this kaiju.")
            return
        end

        local controlTemplate = ReplicatedStorage:FindFirstChild("PlayerScripts")
        controlTemplate = controlTemplate and controlTemplate:FindFirstChild("Control")
        if not controlTemplate then
            fail(player, "Control script missing")
            return
        end

        local newModel = selectedCreature:Clone()
        local oldCharacter = player.Character
        for _, descendant in ipairs(newModel:GetDescendants()) do
            if descendant:IsA("BasePart") then
                descendant:SetAttribute("OriginalColor", descendant.Color)
                descendant:SetAttribute("OriginalMaterial", descendant.Material.Name)
            end
        end
        newModel.Name = player.Name
        if not newModel.PrimaryPart then
            local root = newModel:FindFirstChild("HumanoidRootPart")
            if root then newModel.PrimaryPart = root end
        end

        local control = controlTemplate:Clone()
        control.Disabled = true
        control.Parent = newModel

        local kaijuName = Instance.new("StringValue")
        kaijuName.Name = "Kaiju"
        kaijuName.Value = selectedCreature.Name
        kaijuName.Parent = newModel

        local levelsFolder = ServerScriptService:FindFirstChild("Levels")
        local levelsTemplate = levelsFolder and levelsFolder:FindFirstChild("Levels")
        local levelsScript
        if levelsTemplate then
            levelsScript = levelsTemplate:Clone()
            levelsScript.Disabled = true
            levelsScript.Parent = newModel
        end

        local spawnCFrame
        local spawnFolder = tankSpawnMorphs[selectedCreature.Name] and Workspace:FindFirstChild("TankSpawns") or Workspace:FindFirstChild("SpawnPoints")
        if spawnFolder then
            local points = spawnFolder:GetChildren()
            local point = #points > 0 and points[math.random(1, #points)] or nil
            if point and point:IsA("BasePart") then
                spawnCFrame = point.CFrame + Vector3.new(0, tankSpawnMorphs[selectedCreature.Name] and 10 or 50, 0)
            end
        end
        if spawnCFrame then newModel:PivotTo(spawnCFrame) end

        newModel.Parent = Workspace
        player.Character = newModel
        if oldCharacter and oldCharacter.Parent then oldCharacter:Destroy() end
        control.Disabled = false
        if levelsScript then levelsScript.Disabled = false end

        local humanoid = newModel:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
            humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        end
        morphResult:FireClient(player, true, selectedCreature.Name, nil)
        print("[MorphBootstrap] Successfully morphed " .. player.Name .. " into " .. selectedCreature.Name)
    end)
    if not ok then
        warn("[MorphBootstrap] Morph failed: " .. tostring(err))
        fail(player, "Server morph error: " .. tostring(err))
    end
end)

morphReady.Value = true
print("[MorphBootstrap] Morph server ready")
end
local modulesFolder = script.Parent:WaitForChild("framework"):WaitForChild("modules")
local function safeInit(name, func)
	task.spawn(function()
		local ok, err = pcall(func)
		if not ok then
			warn("[ServerHandler] " .. name .. " failed: " .. tostring(err))
		end
	end)
end



local MODULE_LIST = {
	"Character",
	"Combat",
	"Data",
	"Regen",
	"World",
}

for _, moduleName in ipairs(MODULE_LIST) do
	local module = modulesFolder:FindFirstChild(moduleName)
	if module then
		local ok, system = pcall(require, module)
		if ok and type(system) == "table" and type(system.Init) == "function" then
			safeInit(moduleName, function()
				system.Init()
			end)
		else
			warn("[ServerHandler] Failed to load module: " .. moduleName .. " - " .. tostring(system))
		end
	else
		warn("[ServerHandler] Module not found: " .. moduleName)
	end
end


local ReplicatedStorage = game:GetService("ReplicatedStorage")

task.spawn(function()
    local ok, err = pcall(function()
        local Knit = require(ReplicatedStorage:WaitForChild("Knit"):WaitForChild("Knit"))
        Knit.AddServices(ServerScriptService:WaitForChild("KnitServices"))
        Knit.Start():andThen(function()
            print("[Knit] Server started successfully")
        end):catch(function(startErr)
            warn("[Knit] Server failed to start: " .. tostring(startErr))
        end)
    end)
    if not ok then
        warn("[ServerHandler] Knit startup failed: " .. tostring(err))
    end
end)
