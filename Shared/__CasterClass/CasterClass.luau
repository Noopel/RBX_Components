local CasterModule = {}

--[[
	CasterModule - Version 1.1
	Made by Noopel_V
	Builds upon the FastCastRedux module with Shapecasting and explosion registration
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Settings = require(script.Settings)
local PropertyList = require(script.PropertyList)

--Dependencies
local FastCast = require(script.FastCastRedux)
FastCast.VisualizeCasts = Settings.VisualizeCasts

local SharedComponents = ReplicatedStorage.SharedComponents
local FuncLibrary = require(SharedComponents.FuncLibrary)
local GhostBoxModule = require(SharedComponents.GhostBox)
local SignalClass = require(SharedComponents.Signal)


function CasterModule.new(ProvidedProperties: table)
	if not ProvidedProperties then ProvidedProperties = {} end
	local ProjectileCaster = {}

	local Properties = setmetatable(ProvidedProperties, PropertyList.Properties)
	
	local Cosmetic = Settings.ProjectileFolder:FindFirstChild(Properties.CosmeticProjectile or Settings.ProjectileFolder:FindFirstChild("PlaceholderCosmetic"))
	
	if Properties.HitBoxType == "Shape" then
		ProjectileCaster.BoundingBoxSize = Properties.ShapeSize
	elseif Properties.HitBoxType == "Cosmetic" then
		if Cosmetic:IsA("Model") then
			local _, size = Cosmetic:GetBoundingBox()
			ProjectileCaster.BoundingBoxSize = size
		else
			ProjectileCaster.BoundingBoxSize = Cosmetic.Size
		end
		
	end
	
	if not table.find(Settings.ValidHitBoxTypes, Properties.HitBoxType) then
		warn("HitBoxType is not valid! HitBoxType: "..tostring(Properties.HitBoxType))
		Properties.HitBoxType = "Raycast"
	end
	
	local HitDetectedEvent = SignalClass.new()
	local Collided = SignalClass.new()
	ProjectileCaster.EventList = {HitDetectedEvent}
	ProjectileCaster.HitDetected = HitDetectedEvent
	ProjectileCaster.Collided = Collided
	
	local Caster = FastCast.new()
	
	local ProjectileList = {}
	local CurrentIndex = 0
	
	local function CheckForValidTarget(ActiveCast, TouchingPart)
		if not TouchingPart and typeof(TouchingPart) == "boolean" then return false end
		local ParentModel = TouchingPart.Parent
		
		local Properties = ActiveCast.Properties
		
		local IsTargetValid = false
		local WasIgnored = false
		local Target = nil
		
		if ActiveCast.CurrentCaster and TouchingPart:IsDescendantOf(ActiveCast.CurrentCaster) or TouchingPart:IsDescendantOf(Settings.DebrisFolder) then
			--warn("Hit caster!")
			return IsTargetValid 
		end
		
		local IsTagged, Ignored = FuncLibrary.hasTagFromList(TouchingPart, Properties)
		
		if Ignored then
			WasIgnored = true
		end
		
		if IsTagged then
			if ActiveCast.TargetHitList and not table.find(ActiveCast.TargetHitList, TouchingPart) then
				table.insert(ActiveCast.TargetHitList, TouchingPart)
				IsTargetValid = true
			end
			Target = TouchingPart
		elseif ParentModel and ParentModel:IsA("Model") then
			IsTagged, Ignored = FuncLibrary.hasTagFromList(ParentModel, Properties)
			
			if Ignored then
				WasIgnored = true
			end
			if IsTagged then
				if ActiveCast.TargetHitList and not table.find(ActiveCast.TargetHitList, ParentModel) then
					table.insert(ActiveCast.TargetHitList, ParentModel)
					IsTargetValid = true
				end
				
				Target = ParentModel
			end
		end
		
		return IsTargetValid, Target, WasIgnored, IsTagged
	end
	
	local function CreateShape(Properties)
		local Shape = Settings.Template:Clone()
		Shape.Name = "ShapeProjectile"
		
		Shape.Size = Properties.ShapeSize
		Shape.Shape = Properties.ShapeType
		Shape.Transparency = Properties.ShapeTransparency
		
		return Shape
	end
	
	local function CheckForTarget(ActiveCast, TouchingPart)
		local Properties = ActiveCast.UserData.Properties
		local IsValid, Target, WasIgnored = CheckForValidTarget(ActiveCast, TouchingPart)
	
		if IsValid and not WasIgnored then
			if not ProjectileList[ActiveCast.CurrentIndex] then
				ProjectileList[ActiveCast.CurrentIndex] = {TimesPierced = 0}
			end
			ProjectileList[ActiveCast.CurrentIndex][Target] = true
			HitDetectedEvent:Fire(Target, ActiveCast.CurrentCaster)
			ActiveCast.HitTarget = true
			
			if Properties.CanPierce and Properties.PierceLimit ~= 0 then
				if ProjectileList[ActiveCast.CurrentIndex]["TimesPierced"] >= Properties.PierceLimit and Properties.PierceLimit ~= -1 then
					ActiveCast:Terminate()
				else
					ProjectileList[ActiveCast.CurrentIndex]["TimesPierced"] += 1
					Collided:Fire(ActiveCast.LastPoint, ActiveCast.CurrentCaster, ActiveCast.TargetHitList, ActiveCast.HitTarget, ActiveCast.UserData)
				end
			else
				if Settings.PrintProjectileTermination then
					print("Launching terminate")
				end
				local success, err = pcall(function()
					ActiveCast:Terminate()
				end)
			end
		elseif not Properties.CanPierce and ActiveCast.CurrentCaster and not TouchingPart:IsDescendantOf(ActiveCast.CurrentCaster) and not TouchingPart:IsDescendantOf(Settings.DebrisFolder) and not WasIgnored then
			ActiveCast.HitTarget = true
			--FINE
			if ActiveCast.Shape and TouchingPart ~= ActiveCast.Shape and TouchingPart ~= ActiveCast.RayInfo.CosmeticBulletObject and not TouchingPart:IsDescendantOf(ActiveCast.RayInfo.CosmeticBulletObject) then
				if ActiveCast then
					if Settings.PrintProjectileTermination then
						print("Launching terminate")
					end
					local success, err = pcall(function()
						ActiveCast:Terminate()
					end)
				end
			elseif not ActiveCast.Shape and TouchingPart ~= ActiveCast.RayInfo.CosmeticBulletObject and not TouchingPart:IsDescendantOf(ActiveCast.RayInfo.CosmeticBulletObject) and not TouchingPart:IsDescendantOf(Settings.DebrisFolder) then
				if ActiveCast then
					if Settings.PrintProjectileTermination then
						print("Launching terminate")
					end
					local success, err = pcall(function()
						ActiveCast:Terminate()
					end)
				end
			elseif not RunService:IsClient() then
				if Settings.PrintProjectileTermination then
					print("Launching terminate")
				end
				local success, err = pcall(function()
					ActiveCast:Terminate()
				end)
			end
		elseif WasIgnored then
			return true
		end
	end
	
	Caster.LengthChanged:Connect(function(ActiveCast, CurrentPoint, Direction, Length, Vel, Projectile)
		if not ActiveCast.TargetHitList then
			ActiveCast.TargetHitList = {}
		end
		
		if not ActiveCast.UserData.Properties then
			warn("Properties were not passed along!")
		end
		
		if not ActiveCast.Properties then
			ActiveCast.Properties = FuncLibrary.deepCopyTable(ActiveCast.UserData.Properties)
		end
		
		local Properties = ActiveCast.UserData.Properties
		
		if not ActiveCast.CurrentIndex then
			ActiveCast.CurrentIndex = CurrentIndex
			CurrentIndex += 1
		end
		
		--First time setup for projectile
		if Projectile and not ProjectileList[ActiveCast.CurrentIndex] then 
			ProjectileList[ActiveCast.CurrentIndex] = {TimesPierced = 0}
			if Settings.PrintProjectileInitialization then
				print("Projectile initialized")
			end

			if Properties.UseShape and Properties.UseCosmetic then
				local Shape = CreateShape(Properties)

				ActiveCast.Shape = Shape
			end
		end
		
		if Properties.HitBoxType ~= "Raycast" and ActiveCast.LastPoint then
			local ShapeType = Properties.HitBoxShape
			local CurrentPointCFrame = CFrame.lookAt(CurrentPoint, CurrentPoint + Direction)
			local LastPointCFrame = CFrame.lookAt(ActiveCast.LastPoint, CurrentPoint)
			
			local Size = nil
			
			if ShapeType == "Box" then
				Size = ProjectileCaster.BoundingBoxSize
				
				if Settings.GhostBoxClient and RunService:IsClient() or Settings.GhostBoxServer and not RunService:IsClient() then
					GhostBoxModule.create(LastPointCFrame, Size, Enum.PartType.Block, 8, "End")
				end
				
				local ShouldStop = false

				repeat
					local Rayresult = workspace:Blockcast(LastPointCFrame, Size, CurrentPoint - ActiveCast.LastPoint, ActiveCast.RayInfo.Parameters)

					if Settings.GhostRayClient and RunService:IsClient() or Settings.GhostRayServer and not RunService:IsClient() then
						GhostBoxModule.create(LastPointCFrame, Size, Enum.PartType.Ball, 8, "Ray")
					end

					if Rayresult and Rayresult.Instance then
						local WasIgnored = CheckForTarget(ActiveCast, Rayresult.Instance)
						if not WasIgnored and ActiveCast.RayInfo and ActiveCast.RayInfo.Parameters then
							ActiveCast.RayInfo.Parameters:AddToFilter(Rayresult.Instance)
						else
							ShouldStop = true
						end
					else 
						ShouldStop = true
					end
				until ShouldStop == true
			else
				Size = Vector3.new(ProjectileCaster.BoundingBoxSize.Z, ProjectileCaster.BoundingBoxSize.Z, ProjectileCaster.BoundingBoxSize.Z)
				
				if Settings.GhostBoxClient and RunService:IsClient() or Settings.GhostBoxServer and not RunService:IsClient() then
					GhostBoxModule.create(LastPointCFrame, Size, Enum.PartType.Ball, 8, "End")
				end

				local ShouldStop = false

				repeat
					local Rayresult = workspace:Spherecast(LastPointCFrame, Size.Z, CurrentPoint - ActiveCast.LastPoint, ActiveCast.RayInfo.Parameters)

					GhostBoxModule.create(LastPointCFrame, Size, Enum.PartType.Block, 8, "Ray")

					if Rayresult and Rayresult.Instance then
						--print("Ray hit something!")
						local WasIgnored = CheckForTarget(ActiveCast, Rayresult.Instance)
						if not WasIgnored and ActiveCast.RayInfo and ActiveCast.RayInfo.Parameters then
							ActiveCast.RayInfo.Parameters:AddToFilter(Rayresult.Instance)
						else
							ShouldStop = true
						end
					else 
						ShouldStop = true
					end
				until ShouldStop == true
			end
		end
		
		local NewCFrame
		
		local function setProjectilePos(part: BasePart)
			local ProjectileLength = part.Size.Z/2
			local Offset = CFrame.new(0,0,-(Length - ProjectileLength))

			if Properties.UseCosmetic then
				part.PivotOffset = part.PivotOffset * CFrame.Angles(math.rad(Properties.CosmeticAngularVelocity.X), math.rad(Properties.CosmeticAngularVelocity.Y), math.rad(Properties.CosmeticAngularVelocity.Z))
			end

			NewCFrame = CFrame.lookAt(CurrentPoint, CurrentPoint + Direction):ToWorldSpace(Offset)
			part.CFrame = NewCFrame * part.PivotOffset
		end
		
		if Projectile and Projectile:IsA("Model") then
			local ProjectileLength = Projectile.PrimaryPart.Size.Z/2
			local Offset = CFrame.new(0,0,-(Length - ProjectileLength))

			if Properties.UseCosmetic then
				Projectile.PrimaryPart.PivotOffset = Projectile.PrimaryPart.PivotOffset * CFrame.Angles(math.rad(Properties.CosmeticAngularVelocity.X), math.rad(Properties.CosmeticAngularVelocity.Y), math.rad(Properties.CosmeticAngularVelocity.Z))
			end

			NewCFrame = CFrame.lookAt(CurrentPoint, CurrentPoint + Direction):ToWorldSpace(Offset)
			Projectile:SetPrimaryPartCFrame(NewCFrame)
		elseif Projectile then
			setProjectilePos(Projectile)
		end
		
		if ActiveCast.Shape and NewCFrame then
			ActiveCast.Shape.PivotOffset = ActiveCast.Shape.PivotOffset * CFrame.Angles(math.rad(Properties.ShapeAngularVelocity.X), math.rad(Properties.ShapeAngularVelocity.Y), math.rad(Properties.ShapeAngularVelocity.Z))

			ActiveCast.Shape.CFrame = NewCFrame * ActiveCast.Shape.PivotOffset

			if ActiveCast.Shape.Parent ~= Settings.DebrisFolder then
				ActiveCast.Shape.Parent = Settings.DebrisFolder
			end
		end
		
		ActiveCast.LastPoint = CurrentPoint
	end)

	Caster.CastTerminating:Connect(function(ActiveCast)
		if Settings.PrintProjectileTermination then
			if not RunService:IsClient() then warn("Projectile is terminating!") else warn("Projectile is terminating on the client!") end
		end
		local function cleanupPart(part)
			part.Transparency = 1
			part.Anchored = true
			part.CanTouch = false
			part.CanQuery = false

			for _, ParticleEmitter in pairs(part:GetDescendants()) do
				if ParticleEmitter:IsA("ParticleEmitter") then ParticleEmitter.Enabled = false end
			end

			game.Debris:AddItem(part, 1.5)
		end
		
		Collided:Fire(ActiveCast.LastPoint, ActiveCast.CurrentCaster, ActiveCast.TargetHitList, ActiveCast.HitTarget, ActiveCast.UserData)
		
		local RayInfo = ActiveCast.RayInfo
		if RayInfo then
			local Projectile = RayInfo.CosmeticBulletObject
			if Projectile and Projectile:IsA("Model") then
				for _, part in pairs(Projectile:GetChildren()) do
					if not part:IsA("BasePart") then continue end
					cleanupPart(part)

					if ActiveCast.Shape then
						cleanupPart(ActiveCast.Shape)
					end
				end
			elseif Projectile then
				cleanupPart(Projectile)

				if ActiveCast.Shape then
					cleanupPart(ActiveCast.Shape)
				end
			end
		end
		
		task.wait(0.001)
		
		--Attempted cleanup
		ActiveCast.TargetHitList = nil
		ActiveCast.CurrentIndex = nil
		ActiveCast.LastPoint = nil
		ActiveCast.CurrentCaster = nil
		ActiveCast.Properties = nil
		ActiveCast.HitTarget = nil
	end)
	
	Caster.RayHit:Connect(function(ActiveCast, RaycastResult, SegmentVelocity, Cosmetic)
		local TargetInstance = RaycastResult.Instance
		local Properties = ActiveCast.UserData.Properties
		if Properties.HitBoxType == "Raycast" then
			local IsValid, Target = CheckForValidTarget(ActiveCast, TargetInstance)
			
			if Target and IsValid then
				HitDetectedEvent:Fire(Target, ActiveCast.CurrentCaster)
			end
		end
	end)
	
	function ProjectileCaster:Fire(Origin, Direction, CasterModel, SentProperties)
		local NewProperties = Properties
		if RunService:IsClient() then
			Origin = FuncLibrary.decodeVec3(Origin)
			local decodedProperties = PropertyList.decodeProperties(SentProperties)
			NewProperties = setmetatable(decodedProperties, PropertyList.Properties)
		end
		
		local Params = RaycastParams.new()
		Params.FilterType = Enum.RaycastFilterType.Exclude
		Params.FilterDescendantsInstances = {CasterModel, Settings.DebrisFolder}

		local Behaviour = Caster.newBehavior()
		Behaviour.MaxDistance = NewProperties.MaxDistance
		Behaviour.AutoIgnoreContainer = true
		Behaviour.RaycastParams = Params
		Behaviour.Acceleration = Vector3.new(0, NewProperties.Gravity, 0)

		if NewProperties.HitBoxType ~= "Raycast" then
			function Behaviour.CanPierceFunction(ActiveCast, Result, SegmentVelocity)
				--if Result.Instance:IsA("Terrain") or not Properties.CanPierce and ActiveCast.CurrentCaster and not Result.Instance:IsDescendantOf(ActiveCast.CurrentCaster) and not Result.Instance:IsDescendantOf(Settings.DebrisFolder) and not Result.Instance:IsDescendantOf(workspace.InvisWalls) then
				--	local hasTag, ignored = CheckForTags(Result.Instance, Properties)
				--	local hasTag2, ignored2 = CheckForTags(Result.Instance.Parent, Properties)
				--	if not ignored and not ignored2 then
				--		print("Hit something!")
				--		print(Result.Instance)
				--		ActiveCast.HitTarget = true
				--		return false
				--	else
				--		return true
				--	end
				--else
				if Result.Instance:IsA("Terrain") then
					return false
				else
					return true
				end
			end
		end
		
		if RunService:IsClient() then
			if NewProperties.UseCosmetic then
				Behaviour.CosmeticBulletTemplate = Settings.ProjectileFolder:FindFirstChild(NewProperties.CosmeticProjectile or Settings.ProjectileFolder:FindFirstChild("PlaceholderCosmetic"))
				Behaviour.CosmeticBulletContainer = Settings.DebrisFolder

				if Behaviour.CosmeticBulletTemplate then
					if Behaviour.CosmeticBulletTemplate:IsA("Model") then
						local _, size = Behaviour.CosmeticBulletTemplate:GetBoundingBox()
						ProjectileCaster.ProjectileSize = size
					else
						ProjectileCaster.ProjectileSize = Behaviour.CosmeticBulletTemplate.Size
					end
					
				end

				if NewProperties.UseShape and NewProperties.HitBoxType ~= "Cosmetic" then
					Behaviour.CosmeticBulletTemplate.CanTouch = false
					ProjectileCaster.ProjectileSize = NewProperties["ShapeSize"]
				end
			elseif NewProperties.UseShape and not NewProperties.UseCosmetic then	
				local Shape = CreateShape(NewProperties)

				Behaviour.CosmeticBulletTemplate = Shape
				Behaviour.CosmeticBulletContainer = Settings.DebrisFolder

				ProjectileCaster.ProjectileSize = NewProperties["ShapeSize"]
			end

			if NewProperties.HitBoxType == "Shape" then
				ProjectileCaster.BoundingBoxSize = NewProperties.ShapeSize
			elseif NewProperties.HitBoxType == "Cosmetic" and Behaviour.CosmeticBulletTemplate then
				if Behaviour.CosmeticBulletTemplate:IsA("Model") then
					local _, size = Behaviour.CosmeticBulletTemplate:GetBoundingBox()
					ProjectileCaster.BoundingBoxSize = size
				else
					ProjectileCaster.BoundingBoxSize = Behaviour.CosmeticBulletTemplate.Size
				end
			end
		end
		
		if Settings.ClientReplicationEvent and not RunService:IsClient() then
			Settings.ClientReplicationEvent:FireAllClients("Projectile", {FuncLibrary.encodeVec3(Origin), Direction, CasterModel, PropertyList.encodeProperties(Properties)})
		end
		
		local ActiveCast = Caster:Fire(Origin, Direction, NewProperties.Velocity, Behaviour)
		ActiveCast.UserData.Properties = NewProperties
		ActiveCast.CurrentCaster = CasterModel
		ActiveCast.UserData.Origin = Origin
		ActiveCast.HitTarget = false
	end

	function ProjectileCaster:Destroy(ToolDestroying)
		FuncLibrary.clearTable(self, ToolDestroying)
		self = nil
	end
	
	return ProjectileCaster
end



return CasterModule