local LerpModule = {}
LerpModule.__index = LerpModule

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local ReplicatedEvent = ReplicatedStorage.ReplicatedEvents.RemoteEvents.ReplicationEvent

local VFXFolder = ReplicatedStorage.ClientAssets.VFX.LerpVFX

local PropertyList = require(script.PropertyList)
local SignalClass = require(script.Signal)

--Dependencies
local SharedComponents = ReplicatedStorage.SharedComponents
local FuncLibrary = require(SharedComponents.FuncLibrary)
local EffectPlayer = require(SharedComponents.EffectPlayer)

type ActiveLerp = {CurrentCaster: Model, Properties: PropertyList.propList}

local function getNearestTarget(ArrayOfTags, StartPosition: Vector3, MaxDistance: number, HitList)
	if not HitList then HitList = {} end
	if not MaxDistance then MaxDistance = -1 end
	
	local nearestTarget
	local Distance
	local Direction
	local Position
	
	for _, tag in pairs(ArrayOfTags) do
		for _, object in pairs(game.CollectionService:GetTagged(tag)) do
			if HitList[object] then continue end
			
			local ActualObject
			local EndPosition
			
			if object:FindFirstChild("Humanoid") and object.Humanoid.Health <= 0 then continue end
			
			if object:IsA("Model") and object.PrimaryPart then
				ActualObject = object.PrimaryPart
				EndPosition = object.PrimaryPart.Position
			elseif object:IsA("BasePart") then
				ActualObject = object
				EndPosition = object.Position
			else 
				continue
			end
			
			local Difference = (EndPosition - StartPosition)

			if MaxDistance ~= -1 and Difference.Magnitude > MaxDistance then continue end
			if nearestTarget and Difference.Magnitude > Distance then continue end

			nearestTarget = ActualObject
			Distance = Difference.Magnitude
			Direction = Difference.Unit
			Position = EndPosition
		end
	end
	
	return nearestTarget, Distance, Direction, Position
end

function LerpModule.new()
	local self = setmetatable({}, LerpModule)
	
	self.EventList = {HitDetectedEvent = SignalClass.new(), CompletedEvent = SignalClass.new()}	
	self.HitDetected = self.EventList.HitDetectedEvent
	self.CompletedEvent = self.EventList.CompletedEvent

	return self
end

local function calc_b(a, c, DirectionalVector, Properties)
	local RandomMidPointOffset = 0
	local RandomMidPointScale = 0
	if Properties.MidPointRandomizer then
		RandomMidPointOffset = math.random(Properties.MidPointRandomOffset.Min, Properties.MidPointRandomOffset.Max)
		RandomMidPointScale = math.random(Properties.MidPointRandomScale.Min * 100, Properties.MidPointRandomScale.Max * 100) / 100
	end
	local MidPointOffsetPosition = DirectionalVector * (Properties.MidPointOffset + RandomMidPointOffset + (c - a).Magnitude * (Properties.MidPointScale + RandomMidPointScale))
	local b = a + ((c - a).Unit * ((c - a).Magnitude * Properties.MidPointPositionScale)) + MidPointOffsetPosition
	return b
end


function LerpModule.newProperties(ProvidedProperties)
	local newProperty: PropertyList.propList = setmetatable(ProvidedProperties, PropertyList.Properties)
	return newProperty
end

local function ClearActiveLerp(ActiveLerp)
	ActiveLerp.CurrentCaster = nil
	ActiveLerp.Properties = nil
	ActiveLerp.HasHit = false
	ActiveLerp.HitList = nil
	ActiveLerp.BounceCount = nil
	ActiveLerp = nil
end

function LerpModule:LerpToPosition(ActiveLerp: ActiveLerp, a: Vector3, b: Vector3, End: Vector3 | BasePart, Duration: number)
	local Timepassed = 0
	local CurrentPosition = a
	local c
	local VFX
	
	local PreviousEndPosition
	
	local reachedTarget = false
	
	local TempConnection
	
	local Properties = ActiveLerp.Properties
	local CurrentCaster = ActiveLerp.CurrentCaster
	local BounceCount = ActiveLerp.BounceCount
	
	local PartsToMove = {}
	
	local function ClearLerp(Position)
		TempConnection:Disconnect() 
		
		if VFX then
			game.Debris:AddItem(VFX, 2)
			VFX.Transparency = 1 
			EffectPlayer.runEffects(VFX, "End")
			for _, info in pairs(PartsToMove) do
				if info[1] then
					info[1].Transparency = 1
				end
			end
		end
		
		if typeof(End) == "Instance" and End:IsA("BasePart") and End.Position == c or reachedTarget then
			local TaggedInstance = FuncLibrary.hasTagFromList(End, Properties.TagFilter) or FuncLibrary.hasTagFromList(End.Parent, Properties.TagFilter)
			if TaggedInstance and not ActiveLerp.HitList[TaggedInstance] then ActiveLerp.HitList[TaggedInstance] = true ActiveLerp.HasHit = true self.EventList.HitDetectedEvent:Fire(TaggedInstance, ActiveLerp.CurrentCaster) end
		end
		
		local Params = OverlapParams.new()
		Params.FilterType = Enum.RaycastFilterType.Include
		Params.FilterDescendantsInstances = {}

		for _, tag in pairs(ActiveLerp.Properties.TagFilter) do
			Params:AddToFilter(CollectionService:GetTagged(tag))
		end
		
		for _, object in pairs(workspace:GetPartBoundsInRadius(c, ActiveLerp.Properties.CompletedHitRadius, Params)) do
			local TaggedInstance = FuncLibrary.hasTagFromList(object, Properties.TagFilter) or FuncLibrary.hasTagFromList(object.Parent, Properties.TagFilter)
			if TaggedInstance and not ActiveLerp.HitList[TaggedInstance] then ActiveLerp.HitList[TaggedInstance] = true ActiveLerp.HasHit = true self.EventList.HitDetectedEvent:Fire(TaggedInstance, ActiveLerp.CurrentCaster) end
		end
		
		if Properties.CanBounce and Properties.BounceLimit > ActiveLerp.BounceCount and ActiveLerp.HasHit then
			ActiveLerp.BounceCount += 1
			
			local nearestTarget: BasePart, Distance, Direction = getNearestTarget(ActiveLerp.Properties.TagFilter, Position, ActiveLerp.Properties.MaxDistance * ActiveLerp.Properties.BounceDistanceMultiplier, ActiveLerp.HitList)
			if not nearestTarget and not ActiveLerp.Properties.ForceAllBounces then 
				self.EventList.CompletedEvent:Fire(ActiveLerp, Position, ActiveLerp.HasHit, ActiveLerp.HitList)
				task.wait()
				ClearActiveLerp(ActiveLerp)
				return 
			end	
			
			local newA = Position
			local newEnd
			
			if typeof(End) == "Instance" then
				newEnd = nearestTarget
			else
				newEnd = nearestTarget.Position
			end
			
			local newB = calc_b(newA, nearestTarget.Position, Vector3.new(0,1,0), ActiveLerp.Properties)
			
			local newDuration = math.clamp(Distance / ActiveLerp.Properties.Velocity, ActiveLerp.Properties.BounceMinDuration, ActiveLerp.Properties.Velocity * ActiveLerp.Properties.MaxDistance * 2)
			
			if ActiveLerp.Properties.ResetHitListAfterBounce then
				ActiveLerp.HitList = {nearestTarget}
			end
			
			self:LerpToPosition(ActiveLerp, newA, newB, newEnd, newDuration)
			
		else
			self.EventList.CompletedEvent:Fire(ActiveLerp, Position, ActiveLerp.HasHit, ActiveLerp.HitList)
			task.wait()
			ClearActiveLerp(ActiveLerp)
		end
	end
	
	if typeof(End) == "Instance" and End:IsA("BasePart") then
		c = End.Position
		PreviousEndPosition = End.Position
	else
		c = End
		PreviousEndPosition = End
	end
	
	if RunService:IsClient() and VFXFolder:FindFirstChild(Properties.VFXName) then
		VFX = VFXFolder:FindFirstChild(Properties.VFXName):Clone()
		VFX.Parent = workspace.DebrisFolder
		for _, object in pairs(VFX:GetDescendants()) do
			if object:IsA("BasePart") then
				table.insert(PartsToMove, {object, (object.Position - VFX.Position)})
			end
		end
	end
	
	TempConnection = game["Run Service"].Heartbeat:Connect(function(delta)
		Timepassed = math.clamp(Timepassed + delta, 0, Duration)
		
		if ActiveLerp.Properties.TracksTarget and typeof(End) == "Instance" and c ~= End.Position and Timepassed / Duration < 1 then
			local CurrentEndPosition = End.Position
			local DistancePassed = (ActiveLerp.Properties.Velocity * Timepassed)
			if DistancePassed < 0 then DistancePassed *= -1 end
			local NewMaxDistance = math.clamp((ActiveLerp.Properties.MaxDistance * ActiveLerp.Properties.MaxDistancePity) - DistancePassed, -math.huge, ActiveLerp.Properties.MaxDistance * ActiveLerp.Properties.MaxDistancePity)

			local CurrentLinearPosition = (c - a).Unit * DistancePassed + a

			local Difference = (CurrentEndPosition - CurrentLinearPosition)
			local Direction = Difference.Unit
			local Distance = Difference.Magnitude

			if Distance < 0 then
				Distance *= -1
			end

			if Distance <= NewMaxDistance then
				Duration = (DistancePassed + Distance) / ActiveLerp.Properties.Velocity
				c = (Direction * Distance) + CurrentLinearPosition
				PreviousEndPosition = CurrentEndPosition
			end
		elseif ActiveLerp.Properties.TracksTarget and typeof(End) == "Instance" and Timepassed / Duration >= 1 and c == PreviousEndPosition then
			reachedTarget = true
		end
		
		local t = math.clamp(Timepassed / Duration, 0, 1)
		
		CurrentPosition = FuncLibrary.bezierQuad(a, b, c, t)
		local NextPosition = FuncLibrary.bezierQuad(a, b, c, Timepassed + 1/60)
		
		if Timepassed >= Duration then ClearLerp(CurrentPosition) end
		if not self then warn("Self doesn't exist!") ClearLerp(CurrentPosition) return end

		if not VFX then return end

		if Timepassed - delta == 0 then
			VFX.CFrame = CFrame.new(a, (c - a).Unit * 1 + a)
			
			if ActiveLerp.BounceCount == 0 then
				EffectPlayer.runEffects(VFX, "Start", Vector3.new(), 1)
			end
		else
			VFX.CFrame = CFrame.new(CurrentPosition, NextPosition)
			if #PartsToMove > 0 then
				for _, Info in pairs(PartsToMove) do
					Info[1].CFrame = CFrame.new(CurrentPosition, NextPosition)
				end
			end
		end
	end)
end

function LerpModule:StartLerping(Start: Vector3, End: Vector3 | BasePart | Model, CurrentCaster: Model, Properties: PropertyList.propList, CountStart: number, CountEnd: number)
	if RunService:IsClient() then
		--Run through decoding
		Start = FuncLibrary.decodeVec3(Start)
		if typeof(End) ~= "Instance" then End = FuncLibrary.decodeVec3(End) end
		Properties = PropertyList.decodeProperties(Properties)
	else
		--Encode data for client
		local EndData

		if typeof(End) == "Instance" then EndData = End
		else EndData = FuncLibrary.encodeVec3(End) end

		ReplicatedEvent:FireAllClients("Lerp", {FuncLibrary.encodeVec3(Start), EndData, CurrentCaster, PropertyList.encodeProperties(Properties), CountStart, CountEnd})
	end
	
	Properties = setmetatable(Properties, PropertyList.Properties)
	
	local EndPosition
	local IsInstance = false

	if typeof(End) == "Instance" then
		EndPosition = End.Position
		IsInstance = true
	else
		EndPosition = End
	end
	
	if not CountStart then CountStart = 1 end
	if not CountEnd then CountEnd = math.clamp(Properties.Amount, CountStart, 10000) end
	
	local Distance = (EndPosition - Start).Magnitude
	local Duration = Distance / Properties.Velocity

	local Angle = math.clamp(Properties.TotalAngle/Properties.Amount, 0, Properties.MaxAngle)
	local StartAngle = (Angle / 2) * (Properties.Amount - 1)

	local UsedAngles = {}

	for Count = CountStart, CountEnd, 1 do
		local CurrentAngle = StartAngle + Angle * (1 - Count)
		if Properties.RandomizeAngle then
			local SAngle = (Properties.MaxAngle / 2)
			CurrentAngle = math.random(0, Properties.MaxAngle * 2) - Properties.MaxAngle
			repeat
				CurrentAngle = math.random(0, Properties.MaxAngle * 2) - Properties.MaxAngle
			until UsedAngles[CurrentAngle] ~= true
			UsedAngles[CurrentAngle] = true
		end
		
		local CF = CFrame.new(Start, Vector3.new(EndPosition.X, Start.Y, EndPosition.Z)) * CFrame.Angles(0,0, math.rad(CurrentAngle))

		local a = CF.UpVector * (Properties.DistanceOffset + math.random(Properties.RandomDistanceOffset.Min, Properties.RandomDistanceOffset.Max)) + CF.Position + CF.LookVector * Properties.StartPointLookOffset

		local b = calc_b(a, EndPosition, CF.UpVector, Properties)

		task.spawn(function()
			local ActiveLerp = {CurrentCaster = CurrentCaster, Properties = Properties, HitList = {}, HasHit = false, BounceCount = 0}
			self:LerpToPosition(ActiveLerp, a, b, End, Duration)
		end)

		if Properties.LerpDelay ~= -1 then
			task.wait(Properties.LerpDelay)
		end
	end
	
	local TotalDuration = ((Properties.MaxDistance + Properties.MaxDistancePity) / Properties.Velocity) * 1.5
end

function LerpModule:Destroy()
	FuncLibrary.clearTable(self)
	self = nil
end

return LerpModule