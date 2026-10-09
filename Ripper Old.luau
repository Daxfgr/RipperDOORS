---====== Load spawner ======---

local Spawner = loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/DOORS-Entity-Spawner-V2/main/init.luau"))()

---====== Create entity ======---

local ripper = Spawner:Create({
	Ripper = {
		Name = "Ripper",
		Asset = "https://github.com/RegularVynixu/DOORS-Entity-Spawner-V2/raw/main/Assets/Entities/Rush.rbxm",
		HeightOffset = 0
	},
	Lights = {
		Flicker = {
			Enabled = false,
			Duration = 1
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

---====== Debug entity ======---

ripper:SetCallback("OnSpawned", function()
    print("Entity has spawned")

    ripper.Model.RipperSpawn:Play()

    local CollectionService = game:GetService("CollectionService")
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local player = Players.LocalPlayer
    local playerGui = player.PlayerGui

    local Module_Events = require(ReplicatedStorage.ModulesClient.Module_Events)
    local Main_Game = require(playerGui.MainUI.Initiator.Main_Game)

    local currentRoom = workspace.CurrentRooms[ReplicatedStorage.GameData.LatestRoom.Value]

    Module_Events.flicker(currentRoom, 4)

    Main_Game.camShaker:ShakeOnce(4, 12, 1, 5)
    Main_Game.camShaker:ShakeOnce(10, 2, 3, 3)

    local Earthquake = LoadCustomInstance("https://github.com/RegularVynixu/DOORS-Entity-Spawner-V2/raw/main/Assets/Earthquake.rbxm")
    Earthquake.Parent = workspace

    local SoundEarthquake = Earthquake:FindFirstChild("SoundEarthquake", true)
    if SoundEarthquake then
        SoundEarthquake:Play()
    end

    local Particles = Earthquake:FindFirstChild("Particles", true)

    for _, Particle in ipairs(Particles:GetDescendants()) do
        if Particle:IsA("ParticleEmitter") then
            for _, Ceiling in ipairs(CollectionService:GetTagged("PartCeiling")) do
                if Ceiling:IsA("BasePart") then
                    local Clone = Particle:Clone()
                    Clone.Parent = Ceiling

                    local Amount = math.clamp(Ceiling.Size.Magnitude * 0.7, 0, 150)
                    Clone:Emit(Amount / 10)
                end
            end
        end
    end

    task.wait(4)

    for _, Ceiling in ipairs(CollectionService:GetTagged("PartCeiling")) do
        for _, Particle in ipairs(Ceiling:GetChildren()) do
            if Particle:IsA("ParticleEmitter") then
                Particle.Enabled = false
                Particle:Destroy()
            end
        end
    end

    Earthquake:Destroy()

    ripper.Model:GetAttributeChangedSignal("BeingBanished"):Connect(function()
        if ripper.Model:GetAttribute("BeingBanished") then
            print("Entity was crucified")

            ripper.Model.RipperNew.Attachment.Ripper.Face.Texture = "rbxassetid://11816152645"
            ripper.Model.RipperNew.Repent:Play()
        end
    end)
end)

ripper:SetCallback("OnStartMoving", function()
    print("Entity has started moving")
end)

ripper:SetCallback("OnEnterRoom", function(room: Model, firstTime: boolean)
    if firstTime == true then
        print("Entity has entered room: ".. room.Name.. " for the first time")
    else
        print("Entity has entered room: ".. room.Name.. " again")
    end
end)

ripper:SetCallback("OnLookAt", function(lineOfSight: boolean)
	if lineOfSight == true then
		print("Player is looking at entity")
	else
		print("Player view is obstructed by something")
	end
end)

ripper:SetCallback("OnRebounding", function(startOfRebound: boolean)
    if startOfRebound == true then
        print("Entity has started rebounding")
	else
        print("Entity has finished rebounding")
	end
end)

ripper:SetCallback("OnDespawning", function()
    print("Entity is despawning")
end)

ripper:SetCallback("OnDespawned", function()
    print("Entity has despawned")
end)

ripper:SetCallback("OnDamagePlayer", function(newHealth: number)
	if newHealth <= 0 then
		print("Entity has killed the player")
	else
		print("Entity has damaged the player")
	end
end)

--[[

DEVELOPER NOTE:
By overwriting 'CrucifixionOverwrite' the default crucifixion callback will be replaced with your custom callback.

ripper:SetCallback("CrucifixionOverwrite", function()
    print("Custom crucifixion callback")
end)

]]--

---====== Run entity ======---

entity:Run(true)
