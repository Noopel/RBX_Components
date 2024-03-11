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
local EffectOverTime = require(SharedComponents.EffectOverTime)

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
			newProps[key] = FuncLibrary.deepCopyTable(value)
		else
			newProps[key] = value
		end
	end
	return newProps
end

function ZoneModule:CreateZone(position: Vector3, properties: PropertyList.propList, currentCaster: Model)
	if self.Destroying or self.Destroying == nil then return end

	local ActiveZone = EffectOverTime.new(properties.OverTimeProperties)

	self.ActiveZones += 1
	ActiveZone.Completed:Connect(function() self.ActiveZones -= 1 end)

	if RunService:IsClient() then --> Client
		position = FuncLibrary.decodeVec3(position)
		properties = ZoneModule.newProperties(PropertyList.decodeProperties(properties))

		local partList = {}
		
		local VFX

		local ActualVFX = VFXStorage:FindFirstChild(tostring(properties.VFXName))
		if ActualVFX then
			VFX = ActualVFX:Clone()
			for _, object in pairs(VFX:GetDescendants()) do
				if object:IsA("Part") then
					partList[object] = {Part = object, Offset = object.Position - VFX.Position}
				end
			end
			
			VFX.Position = position
			for _, partTable in pairs(partList) do
				partTable.Part.Position = partTable.Offset + VFX.Position
			end
			VFX.Parent = workspace.DebrisFolder

			if VFX.Shape == Enum.PartType.Cylinder then
				VFX.Size = Vector3.new(0, properties.Width, properties.Width)
			else
				VFX.Size = Vector3.new(properties.Width, 0, properties.Width)
			end
		end

		local ZoneCircle
		
		if not properties.IgnoreDynamicCircle then
			ZoneCircle = DynamicCircle:Create(position, properties.Width / 2)
		end
		
		if properties.BeamColor and ZoneCircle then
			ZoneCircle:ChangeBeamColor(properties.BeamColor)
		end

		local currentWidth = properties.Width

		ActiveZone:BindToHeartbeat(function()
			if properties.CanGrow and properties.GrowthEndGoal then
				local progression = math.clamp(self.TimePassed / properties.GrowthDuration, 0, 1)
				
				local newWidth = ((properties.Width * properties.GrowthEndGoal - properties.Width) * progression) + properties.Width
				currentWidth = newWidth

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
			end
		end)

		ActiveZone.Ticked:Connect(function() EffectPlayer.runEffects(VFX, "Tick", VFX.Size, currentWidth) end)

		ActiveZone.Completed:Connect(function()
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

			partList = nil
			properties = nil
		end)

	else --> Server
		properties = ZoneModule.newProperties(properties)

		local ZonePart: Part = self.PCache:GetPart()
		local Params = OverlapParams.new()

		local GroundOffset
		
		if ZonePart.Shape == Enum.PartType.Cylinder then
			ZonePart.PivotOffset = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)) 
			ZonePart.Size = Vector3.new(properties.Height, properties.Width, properties.Width)
			GroundOffset = Vector3.new(0, ZonePart.Size.X * position.GroundOffset, 0)
		else
			ZonePart.Size = Vector3.new(properties.Width, properties.Height, properties.Width)
			GroundOffset = Vector3.new(0, ZonePart.Size.Y * properties.GroundOffset, 0)
		end
		
		ZonePart:PivotTo(CFrame.new(position + Vector3.new(0, GroundOffset, 0)))
		
		Params.FilterType = Enum.RaycastFilterType.Include
		if properties.IgnoreCaster then
			Params.FilterDescendantsInstances = {currentCaster}
		end
		for _, Tag in pairs(properties.TagFilter) do
			Params:AddToFilter(game.CollectionService:GetTagged(Tag))
		end
		
		if Settings.ClientReplicationEvent and properties.VFXName then 
			Settings.ClientReplicationEvent:FireAllClients("Zone", {FuncLibrary.encodeVec3(position), PropertyList.encodeProperties(properties)}) 
		end

		ActiveZone:BindToHeartbeat(function()
			if properties.CanGrow and properties.GrowthEndGoal then
				local progression = math.clamp(self.TimePassed / properties.GrowthDuration, 0, 1)
				
				local newWidth = ((properties.Width * properties.GrowthEndGoal - properties.Width) * progression) + properties.Width
				
				if ZonePart then
					if ZonePart.Shape == Enum.PartType.Cylinder then
						ZonePart.PivotOffset = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)) 
						ZonePart.Size = Vector3.new(properties.Height, newWidth, newWidth)
					else
						ZonePart.Size = Vector3.new(newWidth, properties.Height, newWidth)
					end
				end
			end
		end)

		ActiveZone.Ticked:Connect(function()
			local HitList = {}

			if ZonePart then --For server
				for _, part in pairs(workspace:GetPartsInPart(ZonePart, Params)) do
					for _, Tag in pairs(properties.TagFilter) do
						local partHasTag = part:HasTag(Tag)
						if partHasTag and not HitList[part] then
							HitList[part] = true
							self.HitDetected:Fire(part, currentCaster)
						elseif part.Parent and part.Parent:HasTag(Tag) and not HitList[part.Parent] then
							HitList[part.Parent] = true
							self.HitDetected:Fire(part.Parent, currentCaster)
						end
					end
				end
			end
		end)

		ActiveZone.Completed:Connect(function()
			if ZonePart then
				self.PCache:ReturnPart(ZonePart)
			end
		end)
	end

	return ActiveZone
end

function ZoneModule.sendVFXToClient(position: Vector3, properties: PropertyList.propList)
	if Settings.ClientReplicationEvent then
		Settings.ClientReplicationEvent:FireAllClients("Zone", {FuncLibrary.encodeVec3(position), PropertyList.encodeProperties(ZoneModule.newProperties(properties))})
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