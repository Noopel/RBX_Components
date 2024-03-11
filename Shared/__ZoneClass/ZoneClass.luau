local ZoneModule = {}
ZoneModule.__index = ZoneModule

local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Settings = require(script.Settings)
local PropertyList = require(script.PropertyList)

local VFXStorage = ReplicatedStorage.ClientAssets.VFX.ZoneVFX

--> Dependencies
local SharedComponents = ReplicatedStorage.SharedComponents
local FuncLibrary = require(SharedComponents.FuncLibrary)
local PartCache = require(SharedComponents.PartCache)
local SignalClass = require(SharedComponents.Signal)
local EffectPlayer = require(SharedComponents.EffectPlayer)
local DeepCopy = require(SharedComponents.DeepCopy)

local ClientComponents = ReplicatedStorage.ClientComponents
local DynamicCircle = require(ClientComponents.DynamicCircle)
-->

function ZoneModule.new()
	local self = setmetatable({}, ZoneModule)
	
	self.HitDetected = SignalClass.new()
	
	self.ActiveZones = 0
	self.Destroying = false
	
	if not RunService:IsClient() then
		self.PCache = PartCache.new(Settings.Template, 2, workspace.Camera.ServerDebrisFolder)
		self.ZoneTouched = nil
	end
	
	return self
end

function ZoneModule.newProperties(providedProperties): PropertyList.propList
	local newProps = {}
	if not providedProperties then providedProperties = {} end
	for key, value in pairs(PropertyList.Properties) do
		if providedProperties[key] then newProps[key] = providedProperties[key] continue end
		if typeof(value) == "table" then
			newProps[key] = DeepCopy.copy(value)
		else
			newProps[key] = value
		end
	end
	return newProps
end

function ZoneModule:CreateZone(Position: Vector3, Properties: PropertyList.propList, CurrentCaster: Model)
	if self.Destroying or self.Destroying == nil then return end
	self.ActiveZones += 1
	
	local VFX
	local ZoneCircle
	
	local ZonePart: Part

	local TimePassed = 0

	local TimeSinceLastTick = nil
	
	local HeartConnection
	
	local Params = OverlapParams.new()
	
	local ParticleEmitters = {}
	local PartList = {}
	local Sounds = {}
	
	local TargetConstraintList = {}
	
	if RunService:IsClient() then
		Position = FuncLibrary.decodeVec3(Position)
		Properties = PropertyList.decodeProperties(Properties)
		setmetatable(Properties, PropertyList.Properties)
		
		local ActualVFX = VFXStorage:FindFirstChild(tostring(Properties.VFXName))
		if ActualVFX then
			VFX = ActualVFX:Clone()
			for _, object in pairs(VFX:GetDescendants()) do
				if object:IsA("ParticleEmitter") then
					ParticleEmitters[object] = object
				elseif object:IsA("Part") then
					PartList[object] = {Part = object, Offset = object.Position - VFX.Position}
				elseif object:IsA("Sound") then
					Sounds[object] = object
				end
			end
			
			VFX.Position = Position
			for _, partTable in pairs(PartList) do
				partTable.Part.Position = partTable.Offset + VFX.Position
			end
			VFX.Parent = workspace.DebrisFolder

			if VFX.Shape == Enum.PartType.Cylinder then
				VFX.Size = Vector3.new(0, Properties.Width, Properties.Width)
			else
				VFX.Size = Vector3.new(Properties.Width, 0, Properties.Width)
			end
		end
		
		if not Properties.IgnoreDynamicCircle then
			ZoneCircle = DynamicCircle:Create(Position, Properties.Width / 2)
		end
		print(Properties)
		if Properties.BeamColor and ZoneCircle then
			ZoneCircle:ChangeBeamColor(Properties.BeamColor)
		end
	else
		setmetatable(Properties, PropertyList.Properties)
		ZonePart = self.PCache:GetPart()
		
		local GroundOffset
		
		if ZonePart.Shape == Enum.PartType.Cylinder then
			ZonePart.PivotOffset = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)) 
			ZonePart.Size = Vector3.new(Properties.Height, Properties.Width, Properties.Width)
			GroundOffset = Vector3.new(0, ZonePart.Size.X * Properties.GroundOffset, 0)
		else
			ZonePart.Size = Vector3.new(Properties.Width, Properties.Height, Properties.Width)
			GroundOffset = Vector3.new(0, ZonePart.Size.Y * Properties.GroundOffset, 0)
		end
		
		ZonePart:PivotTo(CFrame.new(Position + Vector3.new(0, GroundOffset, 0)))
		
		Params.FilterType = Enum.RaycastFilterType.Include
		if Properties.IgnoreCaster then
			Params.FilterDescendantsInstances = {CurrentCaster}
		end
		for _, Tag in pairs(Properties.TagFilter) do
			print(Properties.TagFilter)
			Params:AddToFilter(game.CollectionService:GetTagged(Tag))
		end
		
		if Settings.ClientReplicationEvent and Properties.VFXName then 
			Settings.ClientReplicationEvent:FireAllClients("Zone", {FuncLibrary.encodeVec3(Position), PropertyList.encodeProperties(Properties)}) 
		end
	end
	
	local Duration = Properties.Duration
	local TickRate = Properties.TickRate
	
	local CanGrow = Properties.CanGrow
	local WidthGrowthGoal = Properties.WidthGrowthGoal
	
	local TargetConstraintList = {}
	
	local function ClearHeartConnection()
		if HeartConnection then HeartConnection:Disconnect() HeartConnection = nil end
		if VFX then 
			for _, object in pairs(VFX:GetDescendants()) do
				if object:IsA("ParticleEmitter") then
					object.Enabled = false
				elseif object:IsA("Sound") then
					object:Stop()
				end
			end

			game.Debris:AddItem(VFX, 3)
		end
		if ZoneCircle then ZoneCircle:Destroy() end
		if ZonePart then
			self.PCache:ReturnPart(ZonePart)
		end
		local ParticleEmitters = nil
		local PartList = nil	
		local Sounds = nil	
		for object, ActiveConstraint in pairs(TargetConstraintList) do
			ActiveConstraint:Destroy()
		end
		TargetConstraintList = nil
		self.ActiveZones -= 1
	end
	
	HeartConnection = RunService.Heartbeat:Connect(function(deltaTime)
		if self.Destroying or self.Destroying == nil then ClearHeartConnection() return end
		if not TimeSinceLastTick then TimeSinceLastTick = time() end
		TimePassed += deltaTime
		
		local newWidth = Properties.Width
		
		if CanGrow and WidthGrowthGoal then
			local progression = math.clamp(TimePassed / Duration, 0, 1)
			
			newWidth = ((Properties.Width * WidthGrowthGoal - Properties.Width) * progression) + Properties.Width
			
			if VFX then
				if VFX.Shape == Enum.PartType.Cylinder then
					VFX.Size = Vector3.new(0, newWidth, newWidth)
				else
					VFX.Size = Vector3.new(newWidth, 0, newWidth)
				end
			end
			if ZoneCircle then
				ZoneCircle:ChangeWidth(newWidth)
			end
			if ZonePart then
				if ZonePart.Shape == Enum.PartType.Cylinder then
					ZonePart.PivotOffset = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)) 
					ZonePart.Size = Vector3.new(Properties.Height, newWidth, newWidth)
				else
					ZonePart.Size = Vector3.new(newWidth, Properties.Height, newWidth)
				end
			end
		end
		
		if Properties.StartDelay and Properties.StartDelay > TimePassed then return end
		
		if Properties.TickOnStart and TimePassed - deltaTime == 0 or time() - TimeSinceLastTick > TickRate then
			local TickAmount = math.floor((time() - TimeSinceLastTick) / Properties.TickRate)
			local LeftoverTime = (time() - TimeSinceLastTick) / Properties.TickRate - TickAmount

			TimeSinceLastTick = time() - (LeftoverTime * Properties.TickRate)
			
			local HitList = {}
			
			for Count = 1, TickAmount do
				if VFX then --For client
					EffectPlayer.runEffects(VFX, VFX.Size, newWidth)
				end
				if ZonePart then --For server
					for _, part in pairs(workspace:GetPartsInPart(ZonePart, Params)) do
						for _, Tag in pairs(Properties.TagFilter) do
							local partHasTag = part:HasTag(Tag)
							if partHasTag and not HitList[part] then
								HitList[part] = true
								self.HitDetected:Fire(part, CurrentCaster)
							elseif part.Parent and part.Parent:HasTag(Tag) and not HitList[part.Parent] then
								HitList[part.Parent] = true
								self.HitDetected:Fire(part.Parent, CurrentCaster)
							end
						end
					end
				end
			end
		end
		
		if TimePassed >= Duration and HeartConnection then
			warn("Zone has reached it's duration!")
			ClearHeartConnection()
			return
		end
	end)
end

function ZoneModule:SendVFXToClient(Position, BaseProperties, OverwritingProperties)
	if self.Destroying or self.Destroying == nil then return end
	if Settings.ClientReplicationEvent then
		local NewProperties = {}
		for key, value in pairs(BaseProperties) do
			if key == "__index" then continue end
			if not OverwritingProperties or not OverwritingProperties[key] then
				NewProperties[key] = value
			else
				NewProperties[key] = OverwritingProperties[key]
			end
		end
		for key, value in pairs(OverwritingProperties) do
			if not NewProperties[key] then
				NewProperties[key] = value
			end
		end
		Settings.ClientReplicationEvent:FireAllClients("Zone", {FuncLibrary.encodeVec3(Position), PropertyList.encodeProperties(NewProperties)}) 
	end
end

function ZoneModule:Destroy()
	self.Destroying = true
	task.wait()
	if self.PCache then self.PCache:Dispose() end
	self.HitDetected:Destroy()
	self.ActiveZones = nil
	FuncLibrary.clearTable(self)
	setmetatable(self, nil)
	self = nil
end

return ZoneModule