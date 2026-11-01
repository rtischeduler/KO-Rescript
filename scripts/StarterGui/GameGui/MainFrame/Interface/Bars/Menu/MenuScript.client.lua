local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local COMBAT_TEXT = "In Combat"
local COMBAT_TEXT_TIME = 1.5

local button = script.Parent
local player = Players.LocalPlayer
local isCountingDown = false
local cancelCountdown = false
local isFlashing = false
local lastActivationAt = 0

button.Active = true
button.Interactable = true
button.ZIndex = math.max(button.ZIndex, 100)

local function inCombat()
    local untilTime = player:GetAttribute("CombatUntil")
    return untilTime ~= nil and Workspace:GetServerTimeNow() < untilTime
end

local function flashCombat()
    if isFlashing or isCountingDown then
        return
    end
    isFlashing = true
    local originalText = button.Text
    button.Text = COMBAT_TEXT
    task.wait(COMBAT_TEXT_TIME)
    button.Text = originalText
    isFlashing = false
end

local function activateMenu()
    local now = os.clock()
    if now - lastActivationAt < 0.25 then
        return
    end
    lastActivationAt = now

    if isCountingDown then
        cancelCountdown = true
        return
    end

    if inCombat() then
        task.spawn(flashCombat)
        return
    end

    isCountingDown = true
    cancelCountdown = false
    local combatAbort = false
    local originalText = button.Text

    for i = 10, 0, -1 do
        button.Text = tostring(i)
        task.wait(1)
        if inCombat() then
            combatAbort = true
            cancelCountdown = true
        end
        if cancelCountdown then
            break
        end
    end

    if not cancelCountdown then
        local playerGui = player:FindFirstChild("PlayerGui")
        local gameGui = playerGui and playerGui:FindFirstChild("GameGui")
        if gameGui then
            gameGui.Enabled = false
        end

        player:SetAttribute("ReturnToMenu", true)
        player:SetAttribute("IsMorphing", false)

        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 then
            humanoid.Health = 0
        end
    end

    button.Text = originalText
    isCountingDown = false
    cancelCountdown = false

    if combatAbort then
        task.spawn(flashCombat)
    end
end

button.Activated:Connect(activateMenu)
