local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local hasMorphed = false

local function hideTouchControls()

    local touchGui = playerGui:FindFirstChild("TouchGui")
    if touchGui then
        touchGui.Enabled = false
    end

    local gameGui = playerGui:FindFirstChild("GameGui")
    if gameGui then
        local mainFrame = gameGui:FindFirstChild("MainFrame")
        if mainFrame then
            local interface = mainFrame:FindFirstChild("Interface")
            if interface then
                local mobile = interface:FindFirstChild("Mobile")
                if mobile then
                    mobile.Visible = false
                end
            end
        end
    end
end

local function showTouchControls()

    local touchGui = playerGui:FindFirstChild("TouchGui")
    if touchGui then
        touchGui.Enabled = true
    end

    local uis = game:GetService("UserInputService")
    if uis.TouchEnabled then
        local gameGui = playerGui:FindFirstChild("GameGui")
        if gameGui then
            local mainFrame = gameGui:FindFirstChild("MainFrame")
            if mainFrame then
                local interface = mainFrame:FindFirstChild("Interface")
                if interface then
                    local mobile = interface:FindFirstChild("Mobile")
                    if mobile then
                        mobile.Visible = true
                    end
                end
            end
        end
    end
end

hideTouchControls()

playerGui.ChildAdded:Connect(function(child)
    if child.Name == "TouchGui" and not hasMorphed then

        task.defer(function()
            child.Enabled = false
        end)
    end
end)

local function monitorTouchGui(touchGui)
    touchGui.Changed:Connect(function(prop)
        if prop == "Enabled" and not hasMorphed then
            if touchGui.Enabled then
                task.defer(function()
                    if not hasMorphed then
                        touchGui.Enabled = false
                    end
                end)
            end
        end
    end)
end

local existingTouchGui = playerGui:FindFirstChild("TouchGui")
if existingTouchGui then
    monitorTouchGui(existingTouchGui)
end

local replicatedStorage = game:GetService("ReplicatedStorage")
local morphSupplies = replicatedStorage:FindFirstChild("MorphSupplies")
if morphSupplies then
    local events = morphSupplies:FindFirstChild("Events")
    if events then
        local fireEvent = events:FindFirstChild("Fire")
        if fireEvent then
            fireEvent.OnClientEvent:Connect(function()
                hasMorphed = true

                task.wait(1)
                showTouchControls()
            end)
        end
    end
end

player.CharacterAdded:Connect(function(character)

    task.wait(1)

    local kaijuValue = character:FindFirstChild("Kaiju")
    if kaijuValue then
        hasMorphed = true
        showTouchControls()
    end
end)
