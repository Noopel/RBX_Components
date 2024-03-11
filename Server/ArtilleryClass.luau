local Artillery = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local ReplicationEvent = ReplicatedStorage.RemoteEvents.ReplicationEvent

--Dependencies
local SharedComponents = ReplicatedStorage.SharedComponents
local RandomPosition = require(SharedComponents.RandomPosition)
local Signal = require(SharedComponents.Signal)
local FuncLibrary = require(SharedComponents.FuncLibrary)

local ServerComponents = ServerStorage.ServerComponents
local Explosion = require(ServerComponents.Explosion)
--

export type propType = {
	RadiusRange: NumberRange,
	RadiusRangeDistanceScale: number,
	Amount: number,
	RandomizeGoalPosition: boolean,
	LaunchDelay: number,
	ExplosionDelay: number,
	UseVisualizer: boolean,
	VFXName: string,
	CenterPointScale: number,
	CenterPointOffset: number,
	CenterPointDistance: number,
	ExplosionProperties: Explosion.explosiveProps,
}

local _artilleryProperties: propType = {
	RadiusRange = NumberRange.new(5, 40),
	RadiusRangeDistanceScale = 0,
	Amount = 20,
	RandomizeGoalPosition = true,
	LaunchDelay = 0.2,
	ExplosionDelay = 1,
	UseVisualizer = true,
	VFXName = "",
	CenterPointScale = 0.5,
	CenterPointOffset = 80,
	CenterPointDistance = 0.95,
	ExplosionProperties = {},
}
_artilleryProperties.__index = _artilleryProperties

function Artillery.newProperties(providedProperties): propType
	if not providedProperties then providedProperties = {} end
	local newProperties = {}
	for key, value in pairs(_artilleryProperties) do
		if key == "__index" then continue end
		if providedProperties[key] then
			newProperties[key] = providedProperties[key]
		else
			newProperties[key] = value
		end
	end
	return newProperties
end

export type callback = (randPos: Vector3) -> nil

function Artillery.new()
	local self = {}
	
	self.Exploded = Signal.new()
	self.Fired = Signal.new()
	
	self.launch = function(center: Vector3, artilleryProperties: propType, IgnoreList, launchCallback: callback, launchPosition: Vector3 | BasePart | Attachment)
		setmetatable(artilleryProperties, _artilleryProperties)

		for count = 1, artilleryProperties.Amount, 1 do
			if not self then return end
			local launchPos = launchPosition or center
			if typeof(launchPosition) == "Instance" then
				if launchPosition:IsA("BasePart") then
					launchPos = center.Position
				elseif launchPosition:IsA("Attachment") then
					launchPos = launchPosition.WorldPosition
				end
			end
			
			local goal_position
			
			if artilleryProperties.RandomizeGoalPosition then
				goal_position = RandomPosition.getPositionFromRadius(center, NumberRange.new(artilleryProperties.RadiusRange.Min, artilleryProperties.RadiusRange.Max + (artilleryProperties.RadiusRangeDistanceScale * (center - launchPos).Magnitude)), true, NumberRange.new(-150, 150), {})
			else
				goal_position = RandomPosition.getPositionFromRadius(center, NumberRange.new(artilleryProperties.RadiusRange.Min, artilleryProperties.RadiusRange.Max + (artilleryProperties.RadiusRangeDistanceScale * (center - launchPos).Magnitude)), true, NumberRange.new(-150, 150), {}, (count - 1) * (360 / artilleryProperties.Amount))
			end
			
			if launchCallback then task.spawn(function() launchCallback(goal_position) end) end
			if artilleryProperties["VFXName"] and artilleryProperties["VFXName"] ~= "" and launchPos then 
				ReplicationEvent:FireAllClients("Artillery", {FuncLibrary.encodeVec3(launchPos), FuncLibrary.encodeVec3(goal_position), artilleryProperties["VFXName"], {artilleryProperties["CenterPointScale"], artilleryProperties["CenterPointOffset"], artilleryProperties["CenterPointDistance"], artilleryProperties.ExplosionDelay}})
			end
			self.Fired:Fire()
			task.spawn(function()
				if artilleryProperties.ExplosionDelay > 0 then
					if artilleryProperties.UseVisualizer then
						ReplicationEvent:FireAllClients("Visualizer", {FuncLibrary.encodeVec3(goal_position), artilleryProperties.ExplosionProperties.Radius, artilleryProperties.ExplosionDelay})
					end
					task.wait(artilleryProperties.ExplosionDelay)
				end
				local listOfTargets = Explosion.explode(goal_position, artilleryProperties.ExplosionProperties, {}, true, IgnoreList)
				if self and self.Exploded then
					self.Exploded:Fire(listOfTargets)
				end
			end)
			if artilleryProperties.LaunchDelay and artilleryProperties.LaunchDelay > 0 then task.wait(artilleryProperties.LaunchDelay) end
		end
	end
	
	self.Destroy = function()
		self.Exploded:Destroy()
		self.launch = nil
		self.Destroy = nil
		self = nil
	end
	
	return self
end



return Artillery
