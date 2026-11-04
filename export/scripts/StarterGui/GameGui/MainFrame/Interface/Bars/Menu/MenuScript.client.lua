local Players = game:GetService("Players")

local button = script.Parent
local player = Players.LocalPlayer
local isCountingDown = false
local cancelCountdown = false
local lastActivationAt = 0

button.Active = true
button.Interactable = true
button.ZIndex = math.max(button.ZIndex, 100)

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

    isCountingDown = true
    cancelCountdown = false
    local originalText = button.Text

    for i = 10, 0, -1 do
        button.Text = tostring(i)
        task.wait(1)
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
end

button.Activated:Connect(activateMenu)