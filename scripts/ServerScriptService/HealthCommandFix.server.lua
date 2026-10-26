



local Players = game:GetService("Players")

local function replaceHealthCommand()
    local main = _G.HDAdminMain
    if not main then return false end

    
    
    local commands = main.commands or main.Commands or main.commandList
    if not commands then return false end

    local found = false

    
    for _, cmd in pairs(commands) do
        if type(cmd) == "table" then
            local cmdName = cmd.Name or cmd.name
            if cmdName and string.lower(cmdName) == "health" then
                
                cmd.Function = function(speaker, args)
                    local targetPlayers = {}
                    local players = args[1]
                    if type(players) == "table" then
                        for _, v in ipairs(players) do
                            table.insert(targetPlayers, v)
                        end
                    elseif typeof(players) == "Instance" and players:IsA("Player") then
                        table.insert(targetPlayers, players)
                    end

                    local amount = tonumber(args[2])
                    if not amount then return end
                    amount = math.max(1, math.floor(amount))

                    for _, plr in ipairs(targetPlayers) do
                        if plr.Character then
                            local character = plr.Character
                            local humanoid = character:FindFirstChildOfClass("Humanoid")
                            if humanoid then 
                                character:SetAttribute("CustomMaxHealth", amount)
                                humanoid.MaxHealth = amount
                                humanoid.Health = amount

                                
                                local stats = character:FindFirstChild("Stats")
                                if stats then
                                    local maxHP = stats:FindFirstChild("MaxHP")
                                    if maxHP and maxHP:IsA("ValueBase") then
                                        maxHP.Value = amount
                                    end
                                end

                                
                                character:SetAttribute("BaseMaxHP", amount)
                            end
                        end
                    end
                end
                found = true
                break
            end
        end
    end

    return found
end



task.spawn(function()
    local attempts = 0
    while attempts < 100 do
        task.wait(1)
        attempts = attempts + 1
        local success = replaceHealthCommand()
        if success then
            print("[HealthFix] Successfully replaced built-in health command with no-cap version")
            break
        end
    end
    if attempts >= 100 then
        warn("[HealthFix] Could not find built-in health command to replace after 100 attempts")
    end
end)