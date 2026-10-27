local SoundController = { Name = "Sounds" }

function SoundController:Start()
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local FootstepsSoundGroup = game:GetService("SoundService"):WaitForChild("Footsteps")

	local SOUND_DATA = {
		Climbing = {
			SoundId = "rbxassetid://IDHERE",
			Looped = true,
		},
		Died = {
			SoundId = "rbxassetid://IDHERE",
		},
		FreeFalling = {
			SoundId = "rbxassetid://IDHERE",
			Looped = true,
		},
		GettingUp = {
			SoundId = "rbxassetid://IDHERE",
		},
		Jumping = {
			SoundId = "rbxassetid://IDHERE",
		},
		Landing = {
			SoundId = "rbxassetid://IDHERE",
		},
		Running = {
			SoundId = "",
			Looped = true,
			Playing = true,
			Pitch = 1,
		},
		Splash = {
			SoundId = "rbxassetid://IDHERE",
		},
		Swimming = {
			SoundId = "rbxassetid://IDHERE",
			Looped = true,
			Pitch = 1.6,
		},
	}



	local function waitForFirst(...)
		local shunt = Instance.new("BindableEvent")
		local slots = {...}

		local function fire(...)
			for i = 1, #slots do
				slots[i]:Disconnect()
			end

			return shunt:Fire(...)
		end

		for i = 1, #slots do
			slots[i] = slots[i]:Connect(fire)
		end

		return shunt.Event:Wait()
	end


	local function map(x, inMin, inMax, outMin, outMax)
		return (x - inMin)*(outMax - outMin)/(inMax - inMin) + outMin
	end

	local function playSound(sound)
		sound.TimePosition = 0
		sound.Playing = true
	end

	local function stopSound(sound)
		sound.Playing = false
		sound.TimePosition = 0
	end

	local function initializeSoundSystem(player, humanoid, rootPart)
		local sounds = {}


		for name, props in pairs(SOUND_DATA) do
			local sound = Instance.new("Sound")
			sound.Name = name


			sound.Archivable = false
			sound.EmitterSize = 5
			sound.MaxDistance = 150
			sound.Volume = 0.65

			for propName, propValue in pairs(props) do
				sound[propName] = propValue
			end

			sound.Parent = rootPart
			sounds[name] = sound
		end

		local playingLoopedSounds = {}

		local function stopPlayingLoopedSounds(except)
			for sound in pairs(playingLoopedSounds) do
				if sound ~= except then
					sound.Playing = false
					playingLoopedSounds[sound] = nil
				end
			end
		end


		local stateTransitions = {
			[Enum.HumanoidStateType.FallingDown] = function()
				stopPlayingLoopedSounds()
			end,

			[Enum.HumanoidStateType.GettingUp] = function()
				stopPlayingLoopedSounds()
				playSound(sounds.GettingUp)
			end,

			[Enum.HumanoidStateType.Jumping] = function()
				stopPlayingLoopedSounds()
				playSound(sounds.Jumping)
			end,

			[Enum.HumanoidStateType.Swimming] = function()
				local verticalSpeed = math.abs(rootPart.Velocity.Y)
				if verticalSpeed > 0.1 then
					sounds.Splash.Volume = math.clamp(map(verticalSpeed, 100, 350, 0.28, 1), 0, 1)
					playSound(sounds.Splash)
				end
				stopPlayingLoopedSounds(sounds.Swimming)
				sounds.Swimming.Playing = true
				playingLoopedSounds[sounds.Swimming] = true
			end,

			[Enum.HumanoidStateType.Freefall] = function()
				sounds.FreeFalling.Volume = 0
				stopPlayingLoopedSounds(sounds.FreeFalling)
				playingLoopedSounds[sounds.FreeFalling] = true
			end,

			[Enum.HumanoidStateType.Landed] = function()
				stopPlayingLoopedSounds()
				local verticalSpeed = math.abs(rootPart.Velocity.Y)
				if verticalSpeed > 75 then
					sounds.Landing.Volume = math.clamp(map(verticalSpeed, 50, 100, 0, 1), 0, 1)
					playSound(sounds.Landing)
				end
			end,

			[Enum.HumanoidStateType.Running] = function()
				stopPlayingLoopedSounds(sounds.Running)
				sounds.Running.Playing = true
				playingLoopedSounds[sounds.Running] = true
			end,

			[Enum.HumanoidStateType.Climbing] = function()
				local sound = sounds.Climbing
				if math.abs(rootPart.Velocity.Y) > 0.1 then
					sound.Playing = true
					stopPlayingLoopedSounds(sound)
				else
					stopPlayingLoopedSounds()
				end
				playingLoopedSounds[sound] = true
			end,

			[Enum.HumanoidStateType.Seated] = function()
				stopPlayingLoopedSounds()
			end,

			[Enum.HumanoidStateType.Dead] = function()
				stopPlayingLoopedSounds()
				playSound(sounds.Died)
			end,
		}


		local loopedSoundUpdaters = {
			[sounds.Climbing] = function(dt, sound, vel)
				sound.Playing = vel.Magnitude > 0.1
			end,

			[sounds.FreeFalling] = function(dt, sound, vel)
				if vel.Magnitude > 75 then
					sound.Volume = math.clamp(sound.Volume + 0.9*dt, 0, 1)
				else
					sound.Volume = 0
				end
			end,

			[sounds.Running] = function(dt, sound, vel)


			sound.SoundId = FootstepsSoundGroup:WaitForChild(humanoid.FloorMaterial).SoundId
			sound.PlaybackSpeed = FootstepsSoundGroup:WaitForChild(humanoid.FloorMaterial).PlaybackSpeed
			sound.Volume = FootstepsSoundGroup:WaitForChild(humanoid.FloorMaterial).Volume * (vel.Magnitude/12)
			sound.EmitterSize = FootstepsSoundGroup:WaitForChild(humanoid.FloorMaterial).Volume * (vel.Magnitude/12) * 50

			if FootstepsSoundGroup:FindFirstChild(humanoid.FloorMaterial) == nil then
				sound.SoundId = FootstepsSoundGroup:WaitForChild("nil Sound").SoundId
				sound.PlaybackSpeed = FootstepsSoundGroup:WaitForChild("nil Sound").PlaybackSpeed
				sound.EmitterSize = FootstepsSoundGroup:WaitForChild("nil Sound").Volume
				sound.Volume = FootstepsSoundGroup:WaitForChild("nil Sound").Volume
			end
			end,
		}


		local stateRemap = {
			[Enum.HumanoidStateType.RunningNoPhysics] = Enum.HumanoidStateType.Running,
		}

		local activeState = stateRemap[humanoid:GetState()] or humanoid:GetState()
		local activeConnections = {}

		local stateChangedConn = humanoid.StateChanged:Connect(function(_, state)
			state = stateRemap[state] or state

			if state ~= activeState then
				local transitionFunc = stateTransitions[state]

				if transitionFunc then
					transitionFunc()
				end

				activeState = state
			end
		end)

		local steppedConn = RunService.Stepped:Connect(function(_, worldDt)

			for sound in pairs(playingLoopedSounds) do
				local updater = loopedSoundUpdaters[sound]

				if updater then
					updater(worldDt, sound, rootPart.Velocity)
				end
			end
		end)

		local humanoidAncestryChangedConn
		local rootPartAncestryChangedConn
		local characterAddedConn

		local function terminate()
			stateChangedConn:Disconnect()
			steppedConn:Disconnect()
			humanoidAncestryChangedConn:Disconnect()
			rootPartAncestryChangedConn:Disconnect()
			characterAddedConn:Disconnect()
		end

		humanoidAncestryChangedConn = humanoid.AncestryChanged:Connect(function(_, parent)
			if not parent then
				terminate()
			end
		end)

		rootPartAncestryChangedConn = rootPart.AncestryChanged:Connect(function(_, parent)
			if not parent then
				terminate()
			end
		end)

		characterAddedConn = player.CharacterAdded:Connect(terminate)
	end

	local function playerAdded(player)
		local function characterAdded(character)









			if not character.Parent then
				waitForFirst(character.AncestryChanged, player.CharacterAdded)
			end

			if player.Character ~= character or not character.Parent then
				return
			end

			local humanoid = character:FindFirstChildOfClass("Humanoid")
			while character:IsDescendantOf(game) and not humanoid do
				waitForFirst(character.ChildAdded, character.AncestryChanged, player.CharacterAdded)
				humanoid = character:FindFirstChildOfClass("Humanoid")
			end

			if player.Character ~= character or not character:IsDescendantOf(game) then
				return
			end


			local rootPart = character:FindFirstChild("HumanoidRootPart")
			while character:IsDescendantOf(game) and not rootPart do
				waitForFirst(character.ChildAdded, character.AncestryChanged, humanoid.AncestryChanged, player.CharacterAdded)
				rootPart = character:FindFirstChild("HumanoidRootPart")
			end

			if rootPart and humanoid:IsDescendantOf(game) and character:IsDescendantOf(game) and player.Character == character then
				initializeSoundSystem(player, humanoid, rootPart)
			end
		end

		if player.Character then
			characterAdded(player.Character)
		end
		player.CharacterAdded:Connect(characterAdded)
	end

	Players.PlayerAdded:Connect(playerAdded)
	for _, player in ipairs(Players:GetPlayers()) do
		playerAdded(player)
	end



	local function onCharacterAdded(character)
		local Head = character:WaitForChild("HumanoidRootPart")
		local RunningSound = Head:WaitForChild("Running")
		local Humanoid = character:WaitForChild("Humanoid")
		local vel = 0

		Humanoid.Running:connect(function(a)
				RunningSound.PlaybackSpeed 	= FootstepsSoundGroup:WaitForChild(Humanoid.FloorMaterial).PlaybackSpeed * (a/20) * (math.random(30,50)/40)
				RunningSound.Volume 		= FootstepsSoundGroup:WaitForChild(Humanoid.FloorMaterial).Volume * (vel/12)
				RunningSound.EmitterSize 	= FootstepsSoundGroup:WaitForChild(Humanoid.FloorMaterial).Volume * (vel/12) * 50
				vel 						= a
		end)
	end

	local localPlayer = game.Players.LocalPlayer
	if localPlayer.Character then
		onCharacterAdded(localPlayer.Character)
	end
	localPlayer.CharacterAdded:Connect(onCharacterAdded)
end

return SoundController
