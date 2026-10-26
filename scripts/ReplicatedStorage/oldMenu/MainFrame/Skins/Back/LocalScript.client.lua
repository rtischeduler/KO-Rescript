local button = script.Parent
local skinsFrame = button.Parent
local scrollWindow = skinsFrame:WaitForChild("ScrollWindow")
local statsWindow = skinsFrame:WaitForChild("StatsWindow")

button.MouseButton1Click:Connect(function()

    if statsWindow.Visible then
        statsWindow.Visible = false
        scrollWindow.Visible = true
    end
end)
