local player = game.Players.LocalPlayer
local character = workspace:WaitForChild(player.Name)
local humanoid = character:WaitForChild("Humanoid")
humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming,false)
