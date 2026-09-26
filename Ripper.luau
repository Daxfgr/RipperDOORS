---====== Load spawner ======---

local Spawner = loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/DOORS-Entity-Spawner-V2/main/init.luau"))()

---====== Create entity ======---

local Ripper = Spawner:Create({
	Entity = {
		Name = "Ripper",
		Asset = "https://github.com/Daxfgr/RipperDOORS/blob/main/Assets/Ripper.rbxm?raw=true",
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
		Delay = 8,
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
		Range = 40,
		Resist = false,
		Break = true
	},
	Death = {
		Type = "Guiding", -- "Curious"
		Hints = {"You died to who you call Ripper.", "You can tell its presence by the lights and its scream.", "Hide when he comes by.", ""},
		Cause = "Ripper"
	}
})

---====== Debug entity ======---

Ripper:SetCallback("OnSpawned", function()
    print("Entity has spawned")
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

Ripper:SetCallback("OnDespawned", function()
    print("Entity has despawned")
end)

Ripper:SetCallback("OnDamagePlayer", function(newHealth: number)
	if newHealth <= 0 then
		print("Entity has killed the player")
	else
		print("Entity has damaged the player")
	end
end)

Ripper:SetCallback("CrucifixionOverwrite", function()
    print("Custom crucifixion callback")
end)

---====== Run entity ======---

Ripper:Run(true)
