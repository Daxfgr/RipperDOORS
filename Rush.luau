local ServerFunction = _G.server
local QuickFunctions = ServerFunction:Invoke("FastRunModule", "QuickFunctions")
local FlickOrders = ServerFunction:Invoke("FastRunModule", "FlickOrders")
local Collection: CollectionService = ServerFunction:Invoke("Collection")
local HitPlayers = {}

local GameDebugModule = require(script.Parent.Module_GameDebug)
local v4 = require(game.ReplicatedStorage.Modifiers)

local CrucifixLibrary = {
	Crucifix = function(Player: Player, Model)
		if Player and Player.Character and Player.Character.Humanoid and Player.Character.Humanoid.Health > 0 then
			if Player.Character:FindFirstChild("Crucifix") then
				if Collection:HasTag(Model, "InRepent") then
					return
				end
				Collection:AddTag(Model, "InRepent")
				local UseCrucifix = ServerFunction:Invoke("FastRunModule", "UseCrucifix")
				local croxs = QuickFunctions.PluginTools("EssentialTool", Player, "Crucifix")
				local Config = {Resist = false, Player = Player, CustomModel = true}
				task.delay(6, function()
					local PDH = _G.playercore
					PDH.GiveAchievement(Player, "CrucifixRush")
				end)
				
				spawn(function()
					UseCrucifix(Model, croxs, Config)
				end)
			end
		end
	end,
}

local SpawnerLibrary = {
	LerpTo = function(RushCloned, object, offset, speed)
		if RushCloned == nil or RushCloned.PrimaryPart == nil then
			return
		end
		local alpha = 0
		local object = object or error("object must be part.")
		local offset = offset or error("offset Recommended")
		local speed = speed or 60
		local distance = (RushCloned.RushNew.Position - object.Position).Magnitude
		local relativeSpeed = distance / speed
		local startCFrame = RushCloned.PrimaryPart.CFrame
		local loop
		local reachedEvent = Instance.new("BindableEvent")
		loop = game:GetService("RunService").Heartbeat:Connect(function(delta)
			local goalCFrame = startCFrame:Lerp(object.CFrame * offset, alpha)
			if RushCloned == nil or RushCloned.PrimaryPart == nil then
				loop:Disconnect()
				reachedEvent:Fire()
				return
			end
			RushCloned.PrimaryPart:PivotTo(goalCFrame)
			alpha += delta / relativeSpeed
			if RushCloned == nil then
				loop:Disconnect()
				reachedEvent:Fire()
			end
			if alpha >= 1 then
				loop:Disconnect()
				reachedEvent:Fire()
			elseif Collection:HasTag(RushCloned, "InRepent") then
				loop:Disconnect()
				reachedEvent:Fire()
			end
		end)
		reachedEvent.Event:Wait()
	end,
	
	Raycast = function(Player, Part, Distance)
		if Player.Character.Humanoid.Health > 0 then
			local Params = RaycastParams.new()
			Params.FilterDescendantsInstances = {
				Part
			}
			if Part ~= nil then
				local dir = CFrame.lookAt(Part.Position, Player.Character.PrimaryPart.Position).LookVector * Distance
				local Cast = workspace:Raycast(Part.Position, dir)
				if Cast and Cast.Instance then
					local Hit = Cast.Instance
					if Hit:IsDescendantOf(Player.Character) and (Player.Character:GetAttribute("Hiding") == false or Player.Character:GetAttribute("Hiding") == nil) then
						if Part.Parent.Name == "RushMoving" then
							local accesstohit = true
							for i, v in pairs(HitPlayers) do
								if v == Player.Name then
									accesstohit = false
								end
							end
							if accesstohit == true then
								CrucifixLibrary.Crucifix(Player, Part.Parent)
								if Collection:HasTag(Part.Parent, "InRepent") then
									return
								end
								table.insert(HitPlayers, Player.Name)
								local repstorage = game:GetService("ReplicatedStorage")
								local Jumpscare = repstorage.EntityInfo:FindFirstChild("Jumpscare")
								QuickFunctions.DeathCause("DeadCause", Player, "Rush", 1)
								QuickFunctions.DealDamage("PlayerDamage", Player, 125)
								if Player.Character.Humanoid.Health <= 0 then
									Jumpscare:FireClient(Player, "Rush")
								end
								task.wait()
							end
						end
					else
					end
				end
			end
		end
	end,
}

local ServerFunction = _G.server
local UseEventModule = game.ReplicatedStorage.EntityInfo.UseEventModule
local CanRunEntity = true
local gd = game.ReplicatedStorage.GameData

local EntitySpeed = 60

if v4.isOn("RushFaster") then
	EntitySpeed = 85
end

return function(Config)
	pcall(function()
		if v4.isOn("EntitiesLess") then
			if not (math.random(-5, 8) == math.random(-5, 8)) then
				return false
			end
		end
		task.spawn(function()
			local CurrentRooms = workspace:WaitForChild("CurrentRooms")
			local LatestRoom = game:WaitForChild("ReplicatedStorage").GameData.LatestRoom
			
			if _G.ServerSeed.Floor == "Mines" then
				local reqMod = "Earthquake"
				local gRs = game.ReplicatedStorage.FloorReplicated
				if not gRs.ClientRemote:FindFirstChild(reqMod) then
					local sM = game.ServerScriptService.ServerScriptModules.ClientModules
					sM:FindFirstChild(reqMod):Clone().Parent = gRs.ClientRemote
				end
				
				game.ReplicatedStorage.FloorReplicated.ClientRemote.Earthquake.Remote:FireAllClients()
			else
				FlickOrders(math.random(60, 135)/100, 69)
			end
			local NewRush = _G.assets.RushMoving:Clone()
			NewRush.Parent = workspace
			if v4.isOn("RushQuiet") then
				for v23, v24 in pairs(NewRush.PrimaryPart:GetChildren()) do
					if v24:IsA("Sound") then
						v24.Volume = v24.Volume * 0.5
					end
				end
			end
			game.TweenService:Create(NewRush.RushNew.PlaySound, TweenInfo.new(6, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut), {
				RollOffMaxDistance = 325,
			}):Play()
			local function lerpRoom(v1, v2)
				if NewRush == nil then
					return
				end
				local room = CurrentRooms[tostring(LatestRoom.Value - v2)]
				task.delay(v1, function()
					if v2 ~= -1 then
						if not v4.isOn("LightsNeverFlicker") then
							UseEventModule:FireAllClients("shatter", room, 60, 45)
						end
					end
				end)
				if room:FindFirstChild("PathfindNodes") then
					for i, v in pairs(room.PathfindNodes:GetChildren()) do
						SpawnerLibrary.LerpTo(NewRush, room:FindFirstChild("PathfindNodes")[i], CFrame.new(0, 4, 0), EntitySpeed)
					end
				else
					SpawnerLibrary.LerpTo(NewRush, room.RoomExit, CFrame.new(0, 1, 0), EntitySpeed)
				end
			end
			
			local function reverseLerpRoom(v1, v2)
				if NewRush == nil then
					return
				end
				
				local room = CurrentRooms[tostring(LatestRoom.Value - (v2))]
				task.delay(v1, function()
					if v2 ~= -1 then
						if not v4.isOn("LightsNeverFlicker") then
							UseEventModule:FireAllClients("shatter", room, 60, -45)
						end
					end
				end)
				
				local justreturn = false
				local getlastnode = 0
				local reversenodes = {}
				
				--warn('rush at', room)
				local room = CurrentRooms[tostring(LatestRoom.Value - (v2))]
				if room:FindFirstChild("PathfindNodes") then
					for i, v in pairs(room:FindFirstChild("PathfindNodes"):GetChildren()) do
						getlastnode = i
					end
				else
					justreturn = true
				end
				
				if not justreturn then
					for i = 1, getlastnode do
						table.insert(reversenodes, (getlastnode + 1) - i)
					end
					for i, v in pairs(reversenodes) do
						SpawnerLibrary.LerpTo(NewRush, room:FindFirstChild("PathfindNodes")[v], CFrame.new(0, 4, 0), 45)
					end
				else
					SpawnerLibrary.LerpTo(NewRush, room:FindFirstChild("RoomExit"), CFrame.new(0, 4, 0), 45)
				end
			end
			
			local Path = {
				["FromStart"] = 50,
				["FromEnd"] = 50
			}
			local Path = _G.server:Invoke("FastRunModule", "TraceChance")(Path)
			
			if Path == "FromStart" then
				NewRush:PivotTo(CurrentRooms[LatestRoom.Value - 4].RoomEntrance.CFrame)
			else
				NewRush:PivotTo(CurrentRooms[LatestRoom.Value + 1].RoomExit.CFrame * CFrame.new(0, 0, -18))
			end
			task.wait(math.random(550, 750) / 75)
			local rush_domination = game["Run Service"].Heartbeat:Connect(function(delta)
				for i,v in pairs(game.Players:GetPlayers()) do
					SpawnerLibrary.Raycast(v, NewRush.PrimaryPart, 45)
				end
			end)
			
			warn(Path)
			
			if Path == "FromStart" then
				for i = 3, -1, -1 do
					if i == 3 then
						lerpRoom(2, i)
					elseif i == 0 then
						lerpRoom(0.025, i)
						if NewRush ~= nil and NewRush.PrimaryPart ~= nil then
							if CurrentRooms:FindFirstChild(tostring(LatestRoom.Value)) then
								local Door = CurrentRooms[tostring(LatestRoom.Value)]:FindFirstChild("Door")
								local ThatRoom = CurrentRooms[tostring(LatestRoom.Value)]
								if Door and ThatRoom then
									if not ThatRoom:GetAttribute("EntitiesDontOpenDoor") then
										Door.Func_Open:Fire()
									end
								end
							end
						end
					else
						lerpRoom(0.025, i)
					end
				end
			elseif Path == "FromEnd" then
				for i = -1, 3 do
					if i > 0 then
						i = i + 1
					end
					if i == -1 then
						reverseLerpRoom(2, i)
					elseif i == 0 then
						reverseLerpRoom(0.025, i)
						if NewRush ~= nil and NewRush.PrimaryPart ~= nil then
							if CurrentRooms:FindFirstChild(tostring(LatestRoom.Value)) then
								local Door = CurrentRooms[tostring(LatestRoom.Value)]:FindFirstChild("Door")
								local ThatRoom = CurrentRooms[tostring(LatestRoom.Value)]
								if Door and ThatRoom then
									if not ThatRoom:GetAttribute("EntitiesDontOpenDoor") then
										Door.Func_Open:Fire()
									end
								end
							end
						end
					else
						reverseLerpRoom(0.025, i)
					end
				end
			end
			local downobject = {
				Position = NewRush.PrimaryPart.Position + Vector3.new(0, -120, -50),
				CFrame = NewRush.PrimaryPart.CFrame * CFrame.new(0, -120, -50)
			}
			SpawnerLibrary.LerpTo(NewRush, downobject, CFrame.new(0, 0, 0), 110)
			game.TweenService:Create(NewRush.RushNew.PlaySound, TweenInfo.new(3, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut), {
				RollOffMaxDistance = 150,
			}):Play()
			for i, v in pairs(NewRush:GetDescendants()) do
				if v:IsA("Script") then
					v:Destroy()
				end
				if v:IsA("ParticleEmitter") then
					v.Enabled = false
				end
				if v:IsA("Sound") and v.Name == "Footsteps" then
					game.TweenService:Create(v, TweenInfo.new(1.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {
						Volume = 0
					}):Play();
				end
				if v:IsA("Sound") and v.Name == "PlaySound" then
					game.TweenService:Create(v, TweenInfo.new(1.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {
						Volume = 0
					}):Play();
				end
			end 
			task.spawn(function()
				local PDH = _G.playercore
				for i, v in pairs(game.Players:GetPlayers()) do
					if v.Character and v.Character.Humanoid.Health > 0 then
						PDH.GiveAchievement(v, "SurviveRush")
					end
				end
			end)
			if Collection:HasTag(NewRush, "InRepent") then
				HitPlayers = {}
				rush_domination:Disconnect()
				game.Debris:AddItem(NewRush, 5.5)
			else
				HitPlayers = {}
				rush_domination:Disconnect()
				game.Debris:AddItem(NewRush, 1.5)
			end
		end)
	end)
end
