---====== Load spawner ======---

local Spawner = loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/DOORS-Entity-Spawner-V2/main/init.luau"))()

---====== Create entity ======---

local Ripper = Spawner:Create({
	Entity = {
		Name = "Ripper",
		Asset = "https://raw.githubusercontent.com/Daxfgr/RipperDOORS/refs/heads/main/Assets/Ripper.rbxm",
		HeightOffset = 0
	},
	Lights = {
		Flicker = {
			Enabled = true,
			Duration = 5
		},
		Shatter = false,
		Repair = false
	},
	Earthquake = {
		Enabled = true
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

local function KillPlayerAsEntity(entity)
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local player = Players.LocalPlayer
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if not humanoid or humanoid.Health <= 0 then
        return
    end

    humanoid.Health = 0

    local config = entity.Config
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
            firesignal(
                remotes.DeathHint.OnClientEvent,
                hints,
                colour
            )
        end
    end

    local cause = config.Death.Cause

    if typeof(cause) ~= "string" or cause == "" then
        cause = config.Entity.Name
    end

    local deathCause =
        ReplicatedStorage.GameStats[
            "Player_" .. player.Name
        ].Total.DeathCause

    deathCause.Value = cause
end

---====== Debug entity ======---

Ripper:SetCallback("OnSpawned", function()
	print("Entity has spawned")

	Ripper.Model.RipperSpawn:Play()

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

Ripper:SetCallback("OnEnterRoom", function(room: Model, firstTime: boolean)
    if firstTime == true then
        print("Entity has entered room: ".. room.Name.. " for the first time")
    else
        print("Entity has entered room: ".. room.Name.. " again")
    end
end)

Ripper:SetCallback("OnLookAt", function(lineOfSight: boolean)
	if lineOfSight == true then
		print("Player is looking at entity")
	else
		print("Player view is obstructed by something")
	end
end)

Ripper:SetCallback("OnRebounding", function(startOfRebound: boolean)if startOfRebound == true then
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

Ripper:SetCallback("OnDamagePlayer", function(newHealth: number)
    if newHealth <= 0 then
        print("Entity has killed the player")
    else
        print("Entity has damaged the player")

	local function playNoiseFade()
		local Players = game:GetService("Players")
		local ContentProvider = game:GetService("ContentProvider")

		local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

		local ids = {8482795900, 236542974, 184251462, 236777652}

		local gui = Instance.new("ScreenGui")
		gui.IgnoreGuiInset = true
		gui.ResetOnSpawn = false
		gui.DisplayOrder = 999
		gui.Parent = playerGui

		local images = {}
		local assets = {}

		for i, id in ipairs(ids) do
			local url = "rbxassetid://" .. id
			table.insert(assets, url)

			local img = Instance.new("ImageLabel")
			img.Size = UDim2.new(1, 0, 1, 0)
			img.BackgroundTransparency = 1
			img.BorderSizePixel = 0
			img.ScaleType = Enum.ScaleType.Crop
			img.Image = url
			img.ImageTransparency = 1
			img.Visible = false
			img.ZIndex = i
			img.Parent = gui

			images[i] = img
		end

		ContentProvider:PreloadAsync(assets)

		local function setTransparency(t)
			for _, img in ipairs(images) do
				img.ImageTransparency = t
			end
		end

		local switching = true

		task.spawn(function()
			local index = 1
			while gui.Parent do
				if switching then
					for i = 1, #images do
						images[i].Visible = false
					end
					images[index].Visible = true
					index = index + 1
					if index > #images then
						index = 1
					end
				end
				task.wait(0.03)
			end
		end)

		setTransparency(1)
		task.wait(1)

		local start = os.clock()
		while os.clock() - start < 1 do
			setTransparency(1 - (os.clock() - start))
			task.wait()
		end
		setTransparency(0)

		task.wait(1)

		switching = false

		start = os.clock()
		while os.clock() - start < 1 do
			setTransparency(os.clock() - start)
			task.wait()
		end
		setTransparency(1)

		gui:Destroy()
	end

		task.spawn(playNoiseFade)

        SkipMissing = true
        Ripper:Pause()
        local model = Ripper.Model
        local attachment = model.RipperNew.Attachment
        local RunService = game:GetService("RunService")
        local staticParticle = attachment.Static.ParticleEmitter
        local face = attachment.Ripper.Face
        face.Texture = "rbxassetid://11816152645"
        task.spawn(function()
			staticParticle.Rate = 9999
    		face.Rate = 9999
    		task.wait(0.25)
    		staticParticle.TimeScale = 0
    		face.TimeScale = 0
		end)
        local TARGET_FILE_NAME = "ripperscare.mp3"
        local foundPath
        local function searchFolder(folderPath)
            for _, path in ipairs(listfiles(folderPath)) do
                if isfolder(path) then
                    searchFolder(path)
                    if foundPath then
                        return
                    end
                elseif isfile(path) then
                    local fileName = path:match("[^\\/]+$")
                    if fileName
                        and fileName:lower() == TARGET_FILE_NAME then
                        foundPath = path
                        return
                    end
                end
            end
        end
        searchFolder(".")
        if foundPath then
            local assetId = getcustomasset(foundPath)
            local jumpscareSound = model.Jumpscare
            if assetId
                and jumpscareSound
                and jumpscareSound:IsA("Sound") then
                jumpscareSound.SoundId = assetId
                jumpscareSound:Play()
                task.delay(1, function()
                    if not Ripper:IsAlive() then
                        return
                    end
                    local staticSound = model.Static
                    if not staticSound
                        or not staticSound:IsA("Sound") then
                        return
                    end
                    staticSound.Volume = 0
                    staticSound:Play()
                    local startTime = os.clock()
                    while os.clock() - startTime < 1 do
                        local progress = os.clock() - startTime
                        staticSound.Volume = math.clamp(
                            progress * 10,
                            0,
                            10
                        )
                        task.wait()
                    end
                    staticSound.Volume = 10

                    -- Kill the player immediately.
                    task.spawn(function()
						task.wait(0.53)
                        KillPlayerAsEntity(Ripper)
                    end)

                    task.wait(1)
                    if not Ripper:IsAlive()
                        or model:GetAttribute("Despawning") then
                        return
                    end
                    model:SetAttribute("Despawning", true)
                    task.spawn(
                        Ripper.RunCallback,
                        Ripper,
                        "OnDespawning"
                    )
                    -- Fixed target, exactly 300 studs below.
                    local target =
                        model:GetPivot()
                        - Vector3.new(0, 300, 0)

                    local reached = false
                    local connection

                    -- Start the fade immediately.
                    task.spawn(function()
                        local fadeStart = os.clock()

                        while os.clock() - fadeStart < 1 do
                            local progress =
                                os.clock() - fadeStart

                            staticSound.Volume = math.clamp(
                                10 - progress * 10,
                                0,
                                10
                            )

                            task.wait()
                        end

                        staticSound.Volume = 0
                    end)

                    connection = RunService.Stepped:Connect(
                        function(_, step)
                            local pivot = model:GetPivot()
                            local difference =
                                target.Position - pivot.Position
                            local magnitude = difference.Magnitude

                            if magnitude > 0.1 then
                                local unit = difference.Unit

                                model:PivotTo(
                                    pivot
                                    + unit * math.min(
                                        step * Ripper.Config.Movement.Speed,
                                        magnitude
                                    )
                                )
                            else
                                connection:Disconnect()
                                reached = true
                            end
                        end
                    )

                    repeat
                        task.wait()
                    until reached

                    Ripper:Despawn()
                end)
            end
        end
    end
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
