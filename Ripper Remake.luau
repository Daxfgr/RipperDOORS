---====== Load spawner ======---

local Spawner = loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/DOORS-Entity-Spawner-V2/main/init.luau"))()

---====== Create ripper ======---

---====== Red Light Fixture Effect ======---
task.spawn(function()
    local RunService = game:GetService("RunService")
    local RED = Color3.fromRGB(255, 0, 0)
    local NEON_RED = Color3.fromRGB(255, 80, 80)
    local FADE_IN_TIME = 2
    local FADE_OUT_TIME = 60
    -- Stop the previous effect if it exists.
    local previousStop = getgenv().LightFixtureColorEffectStop
    if previousStop then
        previousStop()
    end
    local stopped = false
    local objects = {}
    local function StopEffect()
        stopped = true
    end
    getgenv().LightFixtureColorEffectStop = StopEffect
    -- Track supported objects inside LightFixture models.
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
    -- Find existing fixtures.
    for _, object in ipairs(game:GetDescendants()) do
        TrackObject(object)
    end
    -- Detect new fixtures and objects added later.
    local descendantConnection = game.DescendantAdded:Connect(function(object)
        TrackObject(object)
        if object.Name == "LightFixture" then
            for _, child in ipairs(object:GetDescendants()) do
                TrackObject(child)
            end
        end
    end)
    local startTime = os.clock()
    while not stopped do
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
    descendantConnection:Disconnect()
    -- Only clear the stop function if this is still the active effect.
    if getgenv().LightFixtureColorEffectStop == StopEffect then
        getgenv().LightFixtureColorEffectStop = nil
    end
    -- Restore original colors if the effect ended naturally.
    if not stopped then
        for object, data in pairs(objects) do
            if object.Parent then
                object.Color = data.OriginalColor
            end
        end
    end
end)

local ripper = Spawner:Create({
	Entity = {
		Name = "Ripper",
		Asset = "https://raw.githubusercontent.com/Daxfgr/RipperDOORS/main/Assets/Ripper%20Remake.rbxm",
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

local Jumpscaring = false

---====== Debug ripper ======---

ripper:SetCallback("OnSpawned", function()
    print("Ripper has spawned")

    ripper.Model.RipperSpawn:Play()

    ripper.Model:GetAttributeChangedSignal("BeingBanished"):Connect(function()
        if ripper.Model:GetAttribute("BeingBanished") then
            print("Ripper was crucified")

            ripper.Model.RipperNew.Attachment.Ripper.Face.Texture = "rbxassetid://11816152645"
            ripper.Model.RipperNew.Repent:Play()
        end
    end)

    task.wait(1)

    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local CollectionService = game:GetService("CollectionService")

    local Player = Players.LocalPlayer
    local PlayerGui = Player:WaitForChild("PlayerGui")

    local Modules = {
        Module_Events = require(ReplicatedStorage.ModulesClient.Module_Events),
        Main_Game = require(PlayerGui.MainUI.Initiator.Main_Game)
    }

    local ROOT = "https://github.com/RegularVynixu/DOORS-Entity-Spawner-V2/raw/main"

    local Assets = {
        Earthquake = LoadCustomInstance(ROOT .. "/Assets/Earthquake.rbxm")
    }

    local Room = workspace.CurrentRooms:FindFirstChild(
        tostring(Player:GetAttribute("CurrentRoom"))
    )

    if not Room then
        Assets.Earthquake:Destroy()
        return
    end

    -- Original Vynixu flicker function
    task.spawn(function()
        Modules.Module_Events.flicker(Room, 3)
    end)

    -- Original Vynixu Earthquake function
    task.spawn(function()
        Modules.Main_Game.camShaker:ShakeOnce(4, 12, 1, 5)
        Modules.Main_Game.camShaker:ShakeOnce(10, 2, 3, 3)

        Assets.Earthquake.SoundEarthquake:Play()

        local v5 = CollectionService:GetTagged("PartCeiling")
        local v6 = {}

        for _, v7 in v5 do
            local v8 = v7.Size.Magnitude * 0.7
            local v9 = math.clamp(v8, 0, 150)

            for _, v10 in Assets.Earthquake.Particles:GetChildren() do
                local v11 = v10:Clone()
                v11.Parent = v7
                v11:Emit(v9 / 10)
                v11.Enabled = true
                table.insert(v6, v11)
            end
        end

        task.wait(3)

        for _, v12 in v6 do
            v12.Enabled = false
        end

        Assets.Earthquake.SoundEarthquake:Stop()
        Assets.Earthquake:Destroy()
    end)
end)

ripper:SetCallback("OnStartMoving", function()
    print("Ripper has started moving")
end)

ripper:SetCallback("OnEnterRoom", function(room: Model, firstTime: boolean)
    if firstTime == true then
        print("Ripper has entered room: ".. room.Name.. " for the first time")
    else
        print("Ripper has entered room: ".. room.Name.. " again")
    end
end)

ripper:SetCallback("OnLookAt", function(lineOfSight: boolean)
	if lineOfSight == true then
		print("Player is looking at ripper")
	else
		print("Player view is obstructed by something")
	end
end)

ripper:SetCallback("OnRebounding", function(startOfRebound: boolean)
    if startOfRebound == true then
        print("Ripper has started rebounding")
	else
        print("Ripper has finished rebounding")
	end
end)

ripper:SetCallback("OnDespawning", function()
    print("Ripper is despawning")

	if Jumpscaring == true then
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

	ripper.Model.Missing:Play()
end)

ripper:SetCallback("OnDespawned", function()
    print("Ripper has despawned")

	local CustomAchievements = loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/DOORS-Custom-Achievements/main/init.luau"))()

	if CustomAchievements:CheckOwned("TestAchievement") then
    	CustomAchievements:Revoke("TestAchievement")
	end

	CustomAchievements:Grant({
    	Identifier = "Doors Hardcore Ripper Achievement",
    	Title = "Torn Apart",
    	Desc = "Dont leave too early.",
    	Reason = "Encounter Ripper.",
    	Image = "rbxassetid://11547914686"
	}, {
    	CheckOwned = true,
    	Remember = true
	})
end)

ripper:SetCallback("OnDamagePlayer", function(newHealth: number)
	if newHealth <= 0 then
		print("Ripper has killed the player")
	else
		print("Ripper has damaged the player")
		Jumpscaring = true	
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

ripper:Run(true)
