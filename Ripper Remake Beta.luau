---====== Load spawner ======---

local Spawner = loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/DOORS-Entity-Spawner-V2/main/init.luau"))()

---====== Create entity ======---

task.spawn(function()
	local RunService = game:GetService("RunService")

	local RED = Color3.fromRGB(255, 0, 0)
	local NEON_RED = Color3.fromRGB(255, 80, 80)

	local FADE_IN_TIME = 2
	local FADE_OUT_TIME = 60

	if getgenv().LightFixtureColorEffectStop then
		getgenv().LightFixtureColorEffectStop()
	end

	local stopped = false
	local objects = {}

	getgenv().LightFixtureColorEffectStop = function()
		stopped = true
	end

	local function TrackObject(object)
		if objects[object] then
			return
		end

		local fixture = object:FindFirstAncestor("LightFixture")
		if not fixture then
			return
		end

		local targetColor

		if object:IsA("PointLight")
			or object:IsA("SpotLight")
			or object:IsA("SurfaceLight") then

			targetColor = RED

		elseif object:IsA("BasePart")
			and object.Name == "Neon" then

			targetColor = NEON_RED
		end

		if not targetColor then
			return
		end

		objects[object] = {
			OriginalColor = object.Color,
			TargetColor = targetColor
		}
	end

	for _, fixture in ipairs(game:GetDescendants()) do
		if fixture.Name == "LightFixture" then
			for _, object in ipairs(fixture:GetDescendants()) do
				TrackObject(object)
			end
		end
	end

	local descendantConnection = game.DescendantAdded:Connect(function(object)
		TrackObject(object)

		if object.Name == "LightFixture" then
			for _, child in ipairs(object:GetDescendants()) do
				TrackObject(child)
			end
		end
	end)

	local startTime = os.clock()

	while true do
		if stopped then
			break
		end

		local elapsed = os.clock() - startTime
		local alpha
		local fadingOut = false

		if elapsed < FADE_IN_TIME then
			alpha = math.clamp(elapsed / FADE_IN_TIME, 0, 1)
		else
			fadingOut = true

			alpha = math.clamp(
				(elapsed - FADE_IN_TIME) / FADE_OUT_TIME,
				0,
				1
			)
		end

		for object, data in pairs(objects) do
			if object.Parent then
				if fadingOut then
					object.Color = data.TargetColor:Lerp(
						data.OriginalColor,
						alpha
					)
				else
					object.Color = data.OriginalColor:Lerp(
						data.TargetColor,
						alpha
					)
				end
			else
				objects[object] = nil
			end
		end

		if fadingOut and alpha >= 1 then
			break
		end

		RunService.Heartbeat:Wait()
	end

	if not stopped then
		for object, data in pairs(objects) do
			if object.Parent then
				object.Color = data.OriginalColor
			end
		end
	end

	descendantConnection:Disconnect()

	if getgenv().LightFixtureColorEffectStop then
		getgenv().LightFixtureColorEffectStop = nil
	end
end)

local Ripper = Spawner:Create({
	Entity = {
		Name = "Ripper",
		Asset = "https://raw.githubusercontent.com/Daxfgr/RipperDOORS/main/Assets/Ripper%20Remake%20Beta.rbxm",
		HeightOffset = 0
	},
	Lights = {
		Flicker = {
			Enabled = false,
			Duration = 0
		},
		Shatter = false,
		Repair = false
	},
	Earthquake = {
		Enabled = false
	},
	CameraShake = {
		Enabled = true,
		Range = 100,
		Values = {3.5, 20, 0.1, 1} -- Magnitude, Roughness, FadeIn, FadeOut
	},
	Movement = {
		Speed = 100,
		Delay = 5,
		Reversed = false
	},
	Rebounding = {
		Enabled = false,
		Type = "Ambush", -- "Blitz"
		Min = 1,
		Max = 1,
		Delay = 2
	},
	Damage = {
		Enabled = true,
		IgnoreHiding = false,
		Range = 50,
		Amount = 0
	},
	Crucifixion = {
		Type = "Guiding",
		Enabled = true,
		Range = 50,
		Resist = false,
		Break = true
	},
	Death = {
		Type = "Guiding", -- "Curious"
		Hints = {"You died to who you call Ripper.", "You can tell its presence by the lights and its scream.", "Hide when he comes by."},
		Cause = "Ripper"
	}
})

local SkipMissing = false

local function KillPlayerAsEntity()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local player = Players.LocalPlayer
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if not humanoid or humanoid.Health <= 0 then
		return
	end

	humanoid.Health = 0

	local config = Ripper.Config
	local playerGui = player:WaitForChild("PlayerGui")

	if #config.Death.Hints > 0 then
		local deathGui = playerGui.MainUI.Death
		deathGui:GetPropertyChangedSignal("Visible"):Wait()

		local colour
		if config.Death.Type:lower() == "guiding" then
			colour = "Blue"
		elseif config.Death.Type:lower() == "curious" then
			colour = "Yellow"
		else
			colour = "Blue"
		end

		local remotes = ReplicatedStorage:WaitForChild("RemotesFolder")
		local hints = {
			config.Death.Hints[1],
			config.Death.Hints[2],
			config.Death.Hints[3]
		}

		if firesignal then
			firesignal(remotes.DeathHint.OnClientEvent, hints, colour)
		end
	end

	local cause = config.Death.Cause
	if typeof(cause) ~= "string" or cause == "" then
		cause = config.Entity.Name
	end

	ReplicatedStorage.GameStats["Player_" .. player.Name].Total.DeathCause.Value = cause
end

---====== Debug entity ======---

Ripper:SetCallback("OnSpawned", function()
	print("Entity has spawned")
	Ripper.Model.RipperSpawn:Play()

	task.delay(1, function()
		if not Ripper:IsAlive() then
			return
		end

		local CollectionService = game:GetService("CollectionService")
		local Players = game:GetService("Players")
		local ReplicatedStorage = game:GetService("ReplicatedStorage")

		local player = Players.LocalPlayer
		local playerGui = player:WaitForChild("PlayerGui")

		local Module_Events = require(
			ReplicatedStorage.ModulesClient.Module_Events
		)

		local Main_Game = require(
			playerGui.MainUI.Initiator.Main_Game
		)

		local currentRoom = workspace.CurrentRooms:FindFirstChild(
			player:GetAttribute("CurrentRoom")
		)

		if currentRoom then
			Module_Events.flicker(
				currentRoom,
				4
			)
		end

		Main_Game.camShaker:ShakeOnce(
			4,
			12,
			1,
			5
		)

		Main_Game.camShaker:ShakeOnce(
			10,
			2,
			3,
			3
		)

		local Earthquake = LoadCustomInstance(
			"https://github.com/RegularVynixu/DOORS-Entity-Spawner-V2/raw/main/Assets/Earthquake.rbxm"
		)

		if not Earthquake then
			return
		end

		local sound = Earthquake:FindFirstChild("SoundEarthquake")

		if sound then
			sound:Play()
		end

		local particles = Earthquake:FindFirstChild("Particles")

		if not particles then
			Earthquake:Destroy()
			return
		end

		local emittedParticles = {}

		for _, ceiling in CollectionService:GetTagged("PartCeiling") do
			local amount = ceiling.Size.Magnitude * 0.7
			amount = math.clamp(amount, 0, 150)

			for _, particle in particles:GetChildren() do
				local clone = particle:Clone()

				clone.Parent = ceiling
				clone:Emit(amount / 10)
				clone.Enabled = true

				table.insert(emittedParticles, clone)
			end
		end

		task.wait(4)

		for _, particle in emittedParticles do
			particle.Enabled = false
		end

		Earthquake:Destroy()
	end)

	Ripper.Model:GetAttributeChangedSignal("BeingBanished"):Connect(function()
		if Ripper.Model:GetAttribute("BeingBanished") then
			print("Entity was crucified")
			Ripper.Model.RipperNew.Attachment.Ripper.Face.Texture = "rbxassetid://11816152645"
			Ripper.Model.RipperNew.Repent:Play()
		end
	end)
end)

Ripper:SetCallback("OnStartMoving", function()
	print("Entity has started moving")
end)

Ripper:SetCallback("OnEnterRoom", function(room, firstTime)
	if firstTime then
		print("Entity has entered room: ".. room.Name.. " for the first time")
	else
		print("Entity has entered room: ".. room.Name.. " again")
	end
end)

Ripper:SetCallback("OnLookAt", function(lineOfSight)
	if lineOfSight then
		print("Player is looking at entity")
	else
		print("Player view is obstructed by something")
	end
end)

Ripper:SetCallback("OnRebounding", function(startOfRebound)
	if startOfRebound then
		print("Entity has started rebounding")
	else
		print("Entity has finished rebounding")
	end
end)

Ripper:SetCallback("OnDespawning", function()
	print("Entity is despawning")

	if SkipMissing then
		SkipMissing = false
		return
	end

	local Players = game:GetService("Players")

	local Player = Players.LocalPlayer
	local PlayerGui = Player:WaitForChild("PlayerGui")

	local MainUI = PlayerGui:WaitForChild("MainUI")
	local Initiator = MainUI:WaitForChild("Initiator")
	local Main_Game = require(Initiator:WaitForChild("Main_Game"))

	local Values = {10, 20, 0.1, 1}

	Main_Game.camShaker:ShakeOnce(Values[1], Values[2], Values[3], Values[4])

	Ripper.Model.Missing:Play()
end)

Ripper:SetCallback("OnDespawned", function()
	print("Entity has despawned")

	local CustomAchievements = loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/DOORS-Custom-Achievements/main/init.luau"))()

	CustomAchievements:Grant({
		Identifier = "Doors Hardcore Mode Ripper Achievement",
		Title = "Torn Apart",
		Desc = "Dont leave too early.",
		Reason = "Encounter Ripper.",
		Image = "rbxassetid://11547914686"
	}, {
		CheckOwned = true,
		Remember = true
	})
end)

Ripper:SetCallback("OnDamagePlayer", function(newHealth)
	if newHealth <= 0 then
		print("Entity has killed the player")
	else
	end
		print("Entity has damaged the player")

		for _, object in ipairs(Ripper.Model.RipperNew:GetDescendants()) do
			if object:IsA("Sound") then
				object.Volume = 0
			end
		end

		local AUDIO_URL = "https://raw.githubusercontent.com/Daxfgr/RipperDOORS/refs/heads/main/Assets/Ripper%20Jumpscare.mp3"
		local AUDIO_PATH = "Ripper Jumpscare.mp3"

		local success, response = pcall(function()
			return game:HttpGet(AUDIO_URL)
		end)

		if not success or not response or #response == 0 then
			warn("[Ripper] Failed to download jumpscare audio.")
			warn(tostring(response))
			return
		end

		writefile(AUDIO_PATH, response)

		print("[Ripper] Jumpscare audio downloaded.")

		task.spawn(function()
			local Players = game:GetService("Players")
			local ContextActionService = game:GetService("ContextActionService")
			local GuiService = game:GetService("GuiService")
			local player = Players.LocalPlayer
			local playerGui = player:WaitForChild("PlayerGui")
			local character = player.Character or player.CharacterAdded:Wait()
			local humanoid = character:WaitForChild("Humanoid")
			local ACTION_NAME = "Ripper_GlobalInputLock"
			local function SinkInput()
				return Enum.ContextActionResult.Sink
			end
			local inputs = {}
			for _, inputType in ipairs(Enum.UserInputType:GetEnumItems()) do
				if inputType ~= Enum.UserInputType.None then
					table.insert(inputs, inputType)
				end
			end
			for _, keyCode in ipairs(Enum.KeyCode:GetEnumItems()) do
				if keyCode ~= Enum.KeyCode.Unknown then
					table.insert(inputs, keyCode)
				end
			end
			ContextActionService:BindActionAtPriority(
				ACTION_NAME,
				SinkInput,
				false,
				Enum.ContextActionPriority.High.Value,
				table.unpack(inputs)
			)
			GuiService.TouchControlsEnabled = false
			local playerModule =
				player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")
			local controls = require(playerModule):GetControls()
			controls:Disable()
			local TouchBlock = Instance.new("ScreenGui")
			TouchBlock.Name = "Ripper Touch Block"
			TouchBlock.IgnoreGuiInset = true
			TouchBlock.ResetOnSpawn = false
			local highestDisplayOrder = 0
			for _, gui in ipairs(playerGui:GetChildren()) do
				if gui:IsA("ScreenGui") then
					highestDisplayOrder = math.max(
						highestDisplayOrder,
						gui.DisplayOrder
					)
				end
			end
			TouchBlock.DisplayOrder = highestDisplayOrder + 1
			TouchBlock.Parent = playerGui
			local Block = Instance.new("TextButton")
			Block.Name = "Block"
			Block.BackgroundTransparency = 1
			Block.BorderSizePixel = 0
			Block.Position = UDim2.new(0, 0, 0, 0)
			Block.Size = UDim2.new(1, 0, 1, 0)
			Block.Text = ""
			Block.AutoButtonColor = false
			Block.Active = true
			Block.Selectable = false
			Block.Modal = true
			Block.Parent = TouchBlock
			local deathConnection
			deathConnection = humanoid.Died:Connect(function()
				ContextActionService:UnbindAction(ACTION_NAME)
				GuiService.TouchControlsEnabled = true
				controls:Enable()
				if TouchBlock then
					TouchBlock:Destroy()
					TouchBlock = nil
				end
				if deathConnection then
					deathConnection:Disconnect()
					deathConnection = nil
				end
			end)
		end)

	task.spawn(function()
		local Camera = workspace.CurrentCamera
		local TweenService = game:GetService("TweenService")
		local RunService = game:GetService("RunService")
		local Players = game:GetService("Players")

		local player = Players.LocalPlayer
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")

		local ripperModel = Ripper.Model

		if not ripperModel then
			warn("[Ripper] Model was not available for camera jumpscare.")
			return
		end

		Camera.CameraType = Enum.CameraType.Scriptable

		local cameraStart = Camera.CFrame
		local targetPosition = ripperModel:GetPivot().Position

		local targetCFrame = CFrame.lookAt(
			cameraStart.Position,
			targetPosition
		)

		local cameraTween = TweenService:Create(
			Camera,
			TweenInfo.new(
				0.3,
				Enum.EasingStyle.Circular,
				Enum.EasingDirection.InOut
			),
			{
				CFrame = targetCFrame
			}
		)

		local cameraLocked = false
		local renderConnection
		local deathConnection

		cameraTween.Completed:Connect(function()
			cameraLocked = true

			renderConnection = RunService.RenderStepped:Connect(function()
				if not cameraLocked then
					return
				end

				if not Ripper:IsAlive() then
					return
				end

				if not Ripper.Model then
					return
				end

				Camera.CFrame = CFrame.lookAt(
					cameraStart.Position,
					Ripper.Model:GetPivot().Position
				)
			end)
		end)

		if humanoid then
			deathConnection = humanoid.Died:Connect(function()
				cameraLocked = false

				if cameraTween.PlaybackState == Enum.PlaybackState.Playing then
					cameraTween:Cancel()
				end

				if renderConnection then
					renderConnection:Disconnect()
					renderConnection = nil
				end

				if deathConnection then
					deathConnection:Disconnect()
					deathConnection = nil
				end
			end)
		end

		cameraTween:Play()
	end)

	task.spawn(function()
		local Players = game:GetService("Players")
		local TweenService = game:GetService("TweenService")
		local RunService = game:GetService("RunService")
		local player = Players.LocalPlayer
		local playerGui = player:WaitForChild("PlayerGui")
		local Noise = Instance.new("ScreenGui")
		Noise.Name = "Ripper Jumpscare Noise"
		Noise.IgnoreGuiInset = true
		Noise.ResetOnSpawn = false
		local highestDisplayOrder = 0
		for _, gui in ipairs(playerGui:GetChildren()) do
			if gui:IsA("ScreenGui") then
				highestDisplayOrder = math.max(
					highestDisplayOrder,
					gui.DisplayOrder
				)
			end
		end
		Noise.DisplayOrder = highestDisplayOrder + 1
		Noise.Parent = playerGui
		local ImageLabel = Instance.new("ImageLabel")
		ImageLabel.Name = "Noise"
		ImageLabel.BackgroundTransparency = 1
		ImageLabel.BorderSizePixel = 0
		ImageLabel.Position = UDim2.new(0, 0, 0, 0)
		ImageLabel.Size = UDim2.new(1, 0, 1, 0)
		ImageLabel.Image = ""
		ImageLabel.ImageTransparency = 1
		ImageLabel.ScaleType = Enum.ScaleType.Stretch
		ImageLabel.Parent = Noise
		local imageIds = {
			"rbxassetid://8482795900",
			"rbxassetid://236542974",
			"rbxassetid://184251462",
			"rbxassetid://236777652"
		}
		task.wait(1)
		local changingImages = true
		local imageConnection = RunService.RenderStepped:Connect(function()
			if not changingImages then
				return
			end
			ImageLabel.Image = imageIds[math.random(1, #imageIds)]
		end)
		local fadeIn = TweenService:Create(
			ImageLabel,
			TweenInfo.new(
				1,
				Enum.EasingStyle.Linear,
				Enum.EasingDirection.Out
			),
			{
				ImageTransparency = 0
			}
		)
		fadeIn:Play()
		task.wait(1)
		task.wait(1)
		changingImages = false
		if imageConnection then
			imageConnection:Disconnect()
			imageConnection = nil
		end
		local fadeOut = TweenService:Create(
			ImageLabel,
			TweenInfo.new(
				1,
				Enum.EasingStyle.Linear,
				Enum.EasingDirection.Out
			),
			{
				ImageTransparency = 1
			}
		)
		fadeOut:Play()
		fadeOut.Completed:Wait()
		Noise:Destroy()
	end)

	SkipMissing = true
	Ripper:Pause()

	local RunService = game:GetService("RunService")
	local model = Ripper.Model
	local attachment = model.RipperNew.Attachment
	local staticParticle = attachment.Static.ParticleEmitter
	local face = attachment.Ripper.Face

	face.Texture = "rbxassetid://107856775585273"

	task.spawn(function()
		staticParticle.Rate = 9999
		face.Rate = 9999
		task.wait(0.25)
		staticParticle.TimeScale = 0
		face.TimeScale = 0
	end)

	local TARGET_FILE_NAME = "Ripper Jumpscare.mp3"
	local foundPath

	local function searchFolder(folderPath)
		for _, path in ipairs(listfiles(folderPath)) do
			if isfolder(path) then
				searchFolder(path)
				if foundPath then return end
			elseif isfile(path) then
				local fileName = path:match("[^\\/]+$")
				if fileName and fileName:lower() == TARGET_FILE_NAME:lower() then
					foundPath = path
					return
				end
			end
		end
	end

	searchFolder(".")

	if not foundPath then
		warn("[Ripper] File '".. TARGET_FILE_NAME.. "' was not found in the executor workspace.")
		return
	end

	local ok, assetId = pcall(getcustomasset, foundPath)
	if not ok or not assetId then
		warn("[Ripper] getcustomasset failed: ".. tostring(assetId))
		return
	end

	local jumpscareSound = model.Jumpscare
	if not jumpscareSound or not jumpscareSound:IsA("Sound") then
		return
	end

	jumpscareSound.SoundId = assetId
	jumpscareSound:Play()

	task.delay(1, function()
		if not Ripper:IsAlive() then return end

		local staticSound = model.Static
		if not staticSound or not staticSound:IsA("Sound") then return end

		staticSound.Volume = 0
		staticSound:Play()

		local startTime = os.clock()
		while os.clock() - startTime < 1 do
			local progress = os.clock() - startTime
			staticSound.Volume = math.clamp(progress * 10, 0, 10)
			task.wait()
		end

		staticSound.Volume = 10
		task.wait(1)

		if not Ripper:IsAlive() or model:GetAttribute("Despawning") then
			return
		end

		model:SetAttribute("Despawning", true)
		task.spawn(Ripper.RunCallback, Ripper, "OnDespawning")

		local target = model:GetPivot() - Vector3.new(0, 300, 0)
		local reached = false

		task.spawn(KillPlayerAsEntity)

		task.spawn(function()
			local fadeStart = os.clock()
			while os.clock() - fadeStart < 1 do
				local progress = os.clock() - fadeStart
				staticSound.Volume = math.clamp(10 - progress * 10, 0, 10)
				task.wait()
			end
			staticSound.Volume = 0
		end)

		local connection
		connection = RunService.Stepped:Connect(function(_, step)
			local pivot = model:GetPivot()
			local difference = target.Position - pivot.Position
			local magnitude = difference.Magnitude

			if magnitude > 0.1 then
				local unit = difference.Unit
				model:PivotTo(pivot + unit * math.min(step * Ripper.Config.Movement.Speed, magnitude))
			else
				connection:Disconnect()
				reached = true
			end
		end)

		repeat task.wait() until reached
		Ripper:Despawn()
	end)
end)

--[[

DEVELOPER NOTE:
By overwriting 'CrucifixionOverwrite' the default crucifixion callback will be replaced with your custom callback.

Ripper.Debug.CrucifixionOverwrite = function()
	print("Custom crucifixion callback")
end

]]--

---====== Run entity ======---

Ripper:Run(true)
