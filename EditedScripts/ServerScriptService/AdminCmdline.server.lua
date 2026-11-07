local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local MIN_RANK = 2
local MAX_LINE = 300
local COOLDOWN = 0.15

local STATIC_RANKS = {
	[3882403525] = 4,
	[4603347038] = 3,
	[7797782638] = 3,
	[459870224] = 3,
	[11173548348] = 3,
	[7467585725] = 3,
	[-1] = 3,
}

local function ensure(parent, className, name)
	local existing = parent:FindFirstChild(name)
	if existing and existing.ClassName == className then
		return existing
	end
	if existing then
		existing:Destroy()
	end
	local created = Instance.new(className)
	created.Name = name
	created.Parent = parent
	return created
end

local executeEvent = ensure(ReplicatedStorage, "RemoteEvent", "CmdlineExecute")
local resultEvent = ensure(ReplicatedStorage, "RemoteEvent", "CmdlineResult")
local executedEvent = ensure(ServerScriptService, "BindableEvent", "CmdlineExecuted")

local function getRank(player)
	local rank = STATIC_RANKS[player.UserId] or 0
	local main = _G.HDAdminMain
	if type(main) == "table" and type(main.pdata) == "table" then
		local ok, value = pcall(function()
			local data = main.pdata[player.UserId]
			return data and data.Rank
		end)
		if ok and type(value) == "number" and value > rank then
			rank = value
		end
	end
	return rank
end

local function refreshRank(player)
	local rank = getRank(player)
	if player:GetAttribute("CmdlineRank") ~= rank then
		player:SetAttribute("CmdlineRank", rank)
	end
	return rank
end

local function resolveTargets(speaker, token)
	local result = {}
	local seen = {}
	local function add(plr)
		if plr and not seen[plr] then
			seen[plr] = true
			table.insert(result, plr)
		end
	end
	for part in string.gmatch(token, "[^,]+") do
		local key = string.lower(part)
		if key == "me" then
			add(speaker)
		elseif key == "all" then
			for _, plr in ipairs(Players:GetPlayers()) do
				add(plr)
			end
		elseif key == "others" then
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr ~= speaker then
					add(plr)
				end
			end
		else
			local exact
			local partial
			for _, plr in ipairs(Players:GetPlayers()) do
				local name = string.lower(plr.Name)
				local display = string.lower(plr.DisplayName)
				if name == key or display == key then
					exact = plr
					break
				end
				if not partial and (string.sub(name, 1, #key) == key or string.sub(display, 1, #key) == key) then
					partial = plr
				end
			end
			add(exact or partial)
		end
	end
	return result
end

local function names(list)
	local out = {}
	for _, plr in ipairs(list) do
		table.insert(out, plr.Name)
	end
	return table.concat(out, ", ")
end

local function humanoidOf(plr)
	local character = plr.Character
	if not character then
		return nil, nil
	end
	return character, character:FindFirstChildOfClass("Humanoid")
end

local function setStat(plr, statName, value)
	local character = plr.Character
	if not character then
		return false
	end
	local statsFolder = character:FindFirstChild("Stats")
	if not statsFolder then
		return false
	end
	local lowered = string.lower(statName)
	for _, child in ipairs(statsFolder:GetChildren()) do
		if string.lower(child.Name) == lowered and child:IsA("ValueBase") then
			child.Value = value
			return true
		end
	end
	return false
end

local function applyStat(targets, statName, value)
	local changed = {}
	for _, plr in ipairs(targets) do
		if setStat(plr, statName, value) then
			table.insert(changed, plr)
		end
	end
	if #changed == 0 then
		return false, "No stat named " .. statName .. " found on target"
	end
	return true, "Set " .. string.upper(statName) .. " to " .. tostring(value) .. " for " .. names(changed)
end

local function startBoss(plr)
	local bossEvent = ReplicatedStorage:FindFirstChild("BossEvent")
	if not bossEvent then
		return false, "BossEvent not found"
	end
	local character, humanoid = humanoidOf(plr)
	if not character or not humanoid then
		return false, "Target has no character"
	end

	if _G.BossSystem and _G.BossSystem.cleanup then
		_G.BossSystem.cleanup()
	end

	local originalMaxHealth = humanoid.MaxHealth
	local originalWalkSpeed = humanoid.WalkSpeed
	local oldCustomMaxHealth = character:GetAttribute("CustomMaxHealth")
	character:SetAttribute("CustomMaxHealth", nil)
	character:SetAttribute("BossMode", true)
	humanoid.MaxHealth = 1
	humanoid.Health = 1
	humanoid.WalkSpeed = originalWalkSpeed * 1.5

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BossTitle"
	billboard.Size = UDim2.new(0, 500, 0, 60)
	billboard.StudsOffset = Vector3.new(0, 10, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = math.huge

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 1, 0)
	title.BackgroundTransparency = 1
	title.Text = "BOSS: " .. plr.DisplayName
	title.TextColor3 = Color3.fromRGB(255, 0, 0)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBlack
	title.Parent = billboard

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Parent = title

	billboard.Parent = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart") or character

	bossEvent:FireAllClients("start", plr.Name)

	local bossState = {
		bossPlayer = plr,
		bossCharacter = character,
		active = true,
	}

	local damageSnapshot = nil
	local deathConn
	local ancestryConn
	local healthConn

	healthConn = humanoid.HealthChanged:Connect(function(health)
		if health <= 0 then
			local log = _G.CombatDamageLog
			if log and log[character] then
				damageSnapshot = {}
				for k, v in pairs(log[character]) do
					damageSnapshot[k] = v
				end
			end
		end
	end)

	task.spawn(function()
		while bossState.active and character and character.Parent and humanoid and humanoid.Health > 0 do
			task.wait(0.5)
			if not bossState.active then
				break
			end
			local damageLog = _G.CombatDamageLog
			if damageLog and damageLog[character] then
				local topPlayer = nil
				local topDamage = 0
				local totalDamage = 0
				for attacker, damage in pairs(damageLog[character]) do
					totalDamage = totalDamage + damage
					if damage > topDamage then
						topDamage = damage
						topPlayer = attacker
					end
				end
				if topPlayer and totalDamage > 0 then
					local percentage = math.floor((topDamage / totalDamage) * 100)
					bossEvent:FireAllClients("update", topPlayer.Name, percentage)
				else
					bossEvent:FireAllClients("update", "None", 0)
				end
			else
				bossEvent:FireAllClients("update", "None", 0)
			end
		end
	end)

	deathConn = humanoid.Died:Connect(function()
		bossState.active = false
		local winnerName = "Nobody"
		if damageSnapshot then
			local topPlayer = nil
			local topDamage = 0
			for attacker, damage in pairs(damageSnapshot) do
				if damage > topDamage then
					topDamage = damage
					topPlayer = attacker
				end
			end
			if topPlayer then
				winnerName = topPlayer.Name
			end
		end
		bossEvent:FireAllClients("end", winnerName)
		character:SetAttribute("BossMode", false)
		if billboard and billboard.Parent then
			billboard.Parent = nil
		end
		if healthConn then
			healthConn:Disconnect()
		end
		if deathConn then
			deathConn:Disconnect()
		end
		if ancestryConn then
			ancestryConn:Disconnect()
		end
		_G.BossSystem = nil
	end)

	ancestryConn = character.AncestryChanged:Connect(function(_, parent)
		if not parent and bossState.active then
			bossState.active = false
			bossEvent:FireAllClients("end", "Nobody")
			if healthConn then
				healthConn:Disconnect()
			end
			if deathConn then
				deathConn:Disconnect()
			end
			if ancestryConn then
				ancestryConn:Disconnect()
			end
			if billboard and billboard.Parent then
				billboard.Parent = nil
			end
			_G.BossSystem = nil
		end
	end)

	bossState.cleanup = function()
		bossState.active = false
		if character and character.Parent then
			character:SetAttribute("BossMode", false)
			local hum = character:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.MaxHealth = originalMaxHealth
				hum.WalkSpeed = originalWalkSpeed
				if oldCustomMaxHealth then
					character:SetAttribute("CustomMaxHealth", oldCustomMaxHealth)
				end
			end
		end
		if billboard and billboard.Parent then
			billboard.Parent = nil
		end
		if healthConn then
			healthConn:Disconnect()
		end
		if deathConn then
			deathConn:Disconnect()
		end
		if ancestryConn then
			ancestryConn:Disconnect()
		end
		bossEvent:FireAllClients("end", "Nobody")
	end

	_G.BossSystem = bossState
	return true, plr.Name .. " is now the Boss"
end

local function snapPlayer(plr)
	local character, humanoid = humanoidOf(plr)
	if not character or not humanoid or humanoid.Health <= 0 then
		return false
	end

	local parts = {}
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") or descendant:IsA("Decal") then
			table.insert(parts, { instance = descendant, original = descendant.Transparency })
		end
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	local soundParent = hrp or character:FindFirstChildWhichIsA("BasePart") or character
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://75827577587368"
	sound.Volume = 10
	sound.Parent = soundParent
	sound:Play()

	local steps = 60
	local stepDuration = 5 / steps

	task.spawn(function()
		for i = 1, steps do
			local alpha = i / steps
			for _, info in ipairs(parts) do
				if info.instance and info.instance.Parent then
					info.instance.Transparency = info.original + (1 - info.original) * alpha
				end
			end
			task.wait(stepDuration)
		end
		for _, info in ipairs(parts) do
			if info.instance and info.instance.Parent then
				info.instance.Transparency = 1
			end
		end
		if humanoid and humanoid.Health > 0 then
			humanoid:TakeDamage(100000000)
		end
		task.wait(10)
		if sound and sound.Parent then
			sound:Destroy()
		end
	end)
	return true
end

local commands = {}
local lookup = {}

local function define(def)
	table.insert(commands, def)
	lookup[string.lower(def.Name)] = def
	for _, alias in ipairs(def.Aliases or {}) do
		lookup[string.lower(alias)] = def
	end
end

define({
	Name = "xp",
	Aliases = {},
	Rank = 3,
	Targets = true,
	Run = function(speaker, targets, rest)
		local amount = tonumber(rest[1])
		if not amount then
			return false, "Usage: ;xp <player> <amount>"
		end
		local given = {}
		for _, plr in ipairs(targets) do
			local character = plr.Character
			local addXP = character and character:FindFirstChild("AddXP")
			if addXP and addXP:IsA("BindableEvent") then
				addXP:Fire(amount)
				table.insert(given, plr)
			end
		end
		if #given == 0 then
			return false, "No target had an AddXP event"
		end
		return true, "Gave " .. amount .. " XP to " .. names(given)
	end,
})

define({
	Name = "boss",
	Aliases = {},
	Rank = 3,
	Targets = true,
	Run = function(speaker, targets)
		return startBoss(targets[1])
	end,
})

define({
	Name = "studioinsert",
	Aliases = { "insertmodel", "loadmodel" },
	Rank = 3,
	Targets = false,
	Run = function(speaker, targets, rest)
		local InsertService = game:GetService("InsertService")
		local assetId = tonumber(rest[1])
		if not assetId then
			return false, "Usage: ;studioinsert <assetId>"
		end
		local success, result = pcall(function()
			return InsertService:LoadAsset(assetId)
		end)
		if not success or not result then
			return false, "Failed to load asset " .. tostring(assetId)
		end
		result.Parent = workspace

		local spawnCFrame = nil
		local character = speaker.Character
		if character then
			local hrp = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
			if not hrp then
				for _, descendant in ipairs(character:GetDescendants()) do
					if descendant:IsA("BasePart") then
						hrp = descendant
						break
					end
				end
			end
			if hrp then
				spawnCFrame = hrp.CFrame * CFrame.new(0, 0, -10)
			else
				spawnCFrame = character:GetPivot() * CFrame.new(0, 0, -10)
			end
		end
		if not spawnCFrame then
			local spawnPoints = workspace:FindFirstChild("SpawnPoints")
			if spawnPoints then
				for _, spawn in ipairs(spawnPoints:GetChildren()) do
					if spawn:IsA("BasePart") then
						spawnCFrame = spawn.CFrame * CFrame.new(0, 5, -10)
						break
					end
				end
			end
		end
		if not spawnCFrame then
			spawnCFrame = CFrame.new(0, 10, 0)
		end
		result:PivotTo(spawnCFrame)
		return true, "Inserted asset " .. tostring(assetId)
	end,
})

define({
	Name = "health",
	Aliases = { "sethealth", "kaijuhealth", "maxhealth", "setmaxhealth" },
	Rank = 3,
	Targets = true,
	Run = function(speaker, targets, rest)
		local amount = tonumber(rest[1])
		if not amount then
			return false, "Usage: ;health <player> <amount>"
		end
		amount = math.max(1, math.floor(amount))
		local changed = {}
		for _, plr in ipairs(targets) do
			local character, humanoid = humanoidOf(plr)
			if character and humanoid then
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
				table.insert(changed, plr)
			end
		end
		if #changed == 0 then
			return false, "No target has a character"
		end
		return true, "Set health to " .. amount .. " for " .. names(changed)
	end,
})

define({
	Name = "gcells",
	Aliases = { "givegcells", "addgcells" },
	Rank = 3,
	Targets = true,
	Run = function(speaker, targets, rest)
		local amount = tonumber(rest[1])
		if not amount then
			return false, "Usage: ;gcells <player> <amount>"
		end
		amount = math.floor(amount)
		local changed = {}
		for _, plr in ipairs(targets) do
			local leaderstats = plr:FindFirstChild("leaderstats")
			if leaderstats then
				local gcells = leaderstats:FindFirstChild("GCells") or leaderstats:FindFirstChild("gcells")
				if gcells and gcells:IsA("ValueBase") then
					if type(_G.GCellGuardBypass) == "function" then
						_G.GCellGuardBypass(gcells, 5)
					end
					gcells.Value = gcells.Value + amount
					table.insert(changed, plr)
				end
			end
		end
		if #changed == 0 then
			return false, "No target has GCells"
		end
		return true, "Gave " .. amount .. " GCells to " .. names(changed)
	end,
})

define({
	Name = "candy",
	Aliases = { "givecandy", "addcandy", "removecandy" },
	Rank = 3,
	Targets = true,
	Run = function(speaker, targets, rest)
		local amount = tonumber(rest[1])
		if not amount then
			return false, "Usage: ;candy <player> <amount>"
		end
		amount = math.floor(amount)
		local changed = {}
		for _, plr in ipairs(targets) do
			if type(_G.AdminCandy) == "function" then
				local ok = _G.AdminCandy(plr, amount)
				if ok then
					table.insert(changed, plr)
				end
			else
				local leaderstats = plr:FindFirstChild("leaderstats")
				local candy = leaderstats and leaderstats:FindFirstChild("Candy")
				if candy and candy:IsA("ValueBase") then
					candy.Value = math.max(candy.Value + amount, 0)
					plr:SetAttribute("Candy", candy.Value)
					table.insert(changed, plr)
				end
			end
		end
		if #changed == 0 then
			return false, "Candy could not be changed"
		end
		return true, (amount >= 0 and "Gave " or "Removed ") .. math.abs(amount) .. " Candy " .. (amount >= 0 and "to " or "from ") .. names(changed)
	end,
})

define({
	Name = "givekaiju",
	Aliases = { "addkaiju" },
	Rank = 3,
	Targets = true,
	Run = function(speaker, targets, rest)
		local kaijuName = table.concat(rest, " ")
		if kaijuName == "" then
			return false, "Usage: ;givekaiju <player> <kaiju name>"
		end
		if type(_G.AdminGiveKaiju) ~= "function" then
			return false, "Kaiju data is not loaded yet"
		end
		local given = {}
		local lastResult = kaijuName
		for _, plr in ipairs(targets) do
			local ok, result = _G.AdminGiveKaiju(plr, kaijuName)
			if ok then
				lastResult = tostring(result)
				table.insert(given, plr)
			end
		end
		if #given == 0 then
			return false, "Could not give " .. kaijuName
		end
		return true, "Gave " .. lastResult .. " to " .. names(given)
	end,
})

define({
	Name = "removekaiju",
	Aliases = { "takekaiju", "revokekaiju" },
	Rank = 3,
	Targets = true,
	Run = function(speaker, targets, rest)
		local kaijuName = table.concat(rest, " ")
		if kaijuName == "" then
			return false, "Usage: ;removekaiju <player> <kaiju name>"
		end
		if type(_G.AdminRemoveKaiju) ~= "function" then
			return false, "Kaiju data is not loaded yet"
		end
		local removedFrom = {}
		local lastResult = kaijuName
		for _, plr in ipairs(targets) do
			local removed, result = _G.AdminRemoveKaiju(plr, kaijuName)
			if removed then
				lastResult = tostring(result)
				table.insert(removedFrom, plr)
			end
		end
		if #removedFrom == 0 then
			return false, "No target owned " .. kaijuName
		end
		return true, "Removed " .. lastResult .. " from " .. names(removedFrom)
	end,
})

define({
	Name = "raffle",
	Aliases = {},
	Rank = 3,
	Targets = false,
	Run = function()
		local raffleEvent = ReplicatedStorage:FindFirstChild("RaffleEvent")
		if not raffleEvent then
			return false, "RaffleEvent not found"
		end
		local allPlayers = Players:GetPlayers()
		if #allPlayers < 2 then
			return false, "Need at least 2 players"
		end
		local list = {}
		for _, plr in ipairs(allPlayers) do
			table.insert(list, plr.Name)
		end
		local winner = allPlayers[math.random(1, #allPlayers)]
		raffleEvent:FireAllClients(list, winner.Name)
		return true, "Raffle started"
	end,
})

define({
	Name = "playereliminator",
	Aliases = { "eliminator", "battleroyale" },
	Rank = 3,
	Targets = false,
	Run = function(speaker, targets, rest)
		local arg = string.lower(tostring(rest[1] or ""))
		local popupEvent = ReplicatedStorage:FindFirstChild("EliminatorPopup")
		if arg == "on" then
			_G.PlayerEliminatorActive = true
			if popupEvent then
				popupEvent:FireAllClients("Eliminator activated", "green")
			end
			return true, "PlayerEliminator activated"
		elseif arg == "off" then
			_G.PlayerEliminatorActive = false
			if popupEvent then
				popupEvent:FireAllClients("Eliminator Deactivated", "red")
			end
			return true, "PlayerEliminator deactivated"
		end
		return false, "Usage: ;playereliminator on|off"
	end,
})

define({
	Name = "snap",
	Aliases = { "snapfade", "disintegrate" },
	Rank = 3,
	Targets = true,
	Run = function(speaker, targets)
		local snapped = {}
		for _, plr in ipairs(targets) do
			if snapPlayer(plr) then
				table.insert(snapped, plr)
			end
		end
		if #snapped == 0 then
			return false, "No living target to snap"
		end
		return true, "Snapping " .. names(snapped)
	end,
})

define({
	Name = "kaijusize",
	Aliases = { "kaijuscale", "morphsize", "morphscale" },
	Rank = 2,
	Targets = true,
	Run = function(speaker, targets, rest)
		local scale = tonumber(rest[1])
		if not scale then
			return false, "Usage: ;kaijusize <player> <scale>"
		end
		scale = math.clamp(scale, 0.1, 100)
		local scaled = {}
		for _, plr in ipairs(targets) do
			local character, humanoid = humanoidOf(plr)
			if character and humanoid then
				local previous = character:GetAttribute("KaijuScale") or 1
				character:SetAttribute("KaijuScale", scale)
				character:ScaleTo(scale)
				local ratio = scale / previous
				local stats = character:FindFirstChild("Stats")
				if stats then
					for _, statName in ipairs({ "WS", "SS", "SwimSpeed" }) do
						local stat = stats:FindFirstChild(statName)
						if stat and stat:IsA("ValueBase") and typeof(stat.Value) == "number" then
							stat.Value = stat.Value * ratio
						end
					end
				end
				humanoid.WalkSpeed = humanoid.WalkSpeed * ratio
				table.insert(scaled, plr)
			end
		end
		if #scaled == 0 then
			return false, "No target has a character"
		end
		return true, "Scaled " .. names(scaled) .. " to " .. scale
	end,
})

define({
	Name = "changestat",
	Aliases = { "kaijustat" },
	Rank = 2,
	Targets = true,
	Run = function(speaker, targets, rest)
		local statName = rest[1]
		local value = tonumber(rest[2])
		if not statName or not value then
			return false, "Usage: ;kaijustat <player> <stat> <value>"
		end
		return applyStat(targets, statName, value)
	end,
})

define({
	Name = "dmgstat",
	Aliases = {},
	Rank = 2,
	Targets = true,
	Run = function(speaker, targets, rest)
		local statName = rest[1]
		local value = tonumber(rest[2])
		if not statName or not value then
			return false, "Usage: ;dmgstat <player> <DMG1> <value>"
		end
		if not string.match(string.upper(statName), "^DMG%d*$") then
			return false, "Only DMG stats can be changed with dmgstat"
		end
		return applyStat(targets, statName, value)
	end,
})

define({
	Name = "dmg1stat",
	Aliases = {},
	Rank = 2,
	Targets = true,
	Run = function(speaker, targets, rest)
		local value = tonumber(rest[1])
		if not value then
			return false, "Usage: ;dmg1stat <player> <value>"
		end
		return applyStat(targets, "DMG1", value)
	end,
})

define({
	Name = "dmg2stat",
	Aliases = {},
	Rank = 2,
	Targets = true,
	Run = function(speaker, targets, rest)
		local value = tonumber(rest[1])
		if not value then
			return false, "Usage: ;dmg2stat <player> <value>"
		end
		return applyStat(targets, "DMG2", value)
	end,
})

define({
	Name = "help",
	Aliases = { "cmds", "commands" },
	Rank = 2,
	Targets = false,
	Run = function(speaker)
		local rank = getRank(speaker)
		local available = {}
		for _, def in ipairs(commands) do
			if rank >= def.Rank then
				table.insert(available, def.Name)
			end
		end
		return true, table.concat(available, ", ")
	end,
})

local function commandListFor()
	local list = {}
	for _, def in ipairs(commands) do
		table.insert(list, def.Name)
		for _, alias in ipairs(def.Aliases) do
			table.insert(list, alias)
		end
	end
	return table.concat(list, ",")
end

executeEvent:SetAttribute("CommandList", commandListFor())

local lastRun = {}

local function reply(player, ok, message)
	resultEvent:FireClient(player, ok, message)
end

executeEvent.OnServerEvent:Connect(function(player, line)
	if typeof(line) ~= "string" then
		return
	end
	local now = os.clock()
	if lastRun[player] and now - lastRun[player] < COOLDOWN then
		return
	end
	lastRun[player] = now

	line = string.sub(line, 1, MAX_LINE)
	line = string.gsub(line, "^%s*;?%s*", "")
	if line == "" then
		return
	end

	local rank = refreshRank(player)
	if rank < MIN_RANK then
		return
	end

	local tokens = {}
	for token in string.gmatch(line, "%S+") do
		table.insert(tokens, token)
	end

	local def = lookup[string.lower(tokens[1])]
	if not def then
		reply(player, false, "Unknown command: " .. tokens[1])
		return
	end
	if rank < def.Rank then
		reply(player, false, "You do not have permission to use " .. def.Name)
		return
	end

	local targets = {}
	local rest = {}
	local restStart = 2
	if def.Targets then
		if not tokens[2] then
			reply(player, false, "Usage: ;" .. def.Name .. " <player> ...")
			return
		end
		targets = resolveTargets(player, tokens[2])
		if #targets == 0 then
			reply(player, false, "No matching player for " .. tokens[2])
			return
		end
		restStart = 3
	end
	for i = restStart, #tokens do
		table.insert(rest, tokens[i])
	end

	local ok, success, message = pcall(def.Run, player, targets, rest)
	if not ok then
		warn("[cmdline] " .. def.Name .. " errored: " .. tostring(success))
		reply(player, false, def.Name .. " errored")
		return
	end

	reply(player, success and true or false, message or (success and "Done" or "Failed"))
	if success then
		executedEvent:Fire(player, def.Name, targets, rest)
	end
end)

local function track(player)
	refreshRank(player)
	task.spawn(function()
		while player.Parent == Players do
			task.wait(5)
			if player.Parent == Players then
				refreshRank(player)
			end
		end
	end)
end

Players.PlayerAdded:Connect(track)
for _, player in ipairs(Players:GetPlayers()) do
	track(player)
end

Players.PlayerRemoving:Connect(function(player)
	lastRun[player] = nil
end)
