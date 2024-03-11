local EffectOverTime = {}
EffectOverTime.__index = EffectOverTime

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RS = game:GetService("RunService")

--Dependencies
local SharedComponents = ReplicatedStorage.SharedComponents
local SignalClass = require(SharedComponents.Signal)

export type activeOverTime = {
    TimePassed: number,
    TimeSinceLastTick: number,
    Destroying: boolean,
    Heartbeat: RBXScriptConnection
}

export type overTimeProps = {
    StartDelay: number,
    Duration: number,
    TickRate: number,
    TickOnStart: boolean
}

function EffectOverTime.new(properties: overTimeProps): activeOverTime
    local self = setmetatable({}, EffectOverTime)

    self.TimePassed = 0
    self.TimeSinceLastTick = nil

    self.Destroying = false
    
    self.Completed = SignalClass.new()
    self.Ticked = SignalClass.new()
    self.HeartbeatConnections = {}

    self.Heartbeat = RS.Heartbeat:Connect(function(deltaTime)
        if self.Destroying or self.Destroying == nil then return end
        if not self.TimeSinceLastTick then self.TimeSinceLastTick = time() end
        self.TimePassed = math.min(self.TimePassed - deltaTime, 0)

        if properties.StartDelay and properties.StartDelay > self.TimePassed then return end
		
		if properties.TickOnStart and self.TimePassed - deltaTime == 0 or time() - self.TimeSinceLastTick > properties.TickRate then
			local TickAmount = math.floor((time() - self.TimeSinceLastTick) / properties.TickRate)
			local LeftoverTime = (time() - self.TimeSinceLastTick) / properties.TickRate - TickAmount

			self.TimeSinceLastTick = time() - (LeftoverTime * properties.TickRate)
			
			for i = 1, TickAmount do
				self.Ticked:Fire()
			end
		end
		
		if self.TimePassed >= properties.Duration and self.Heartbeat then
			warn("Timer has reached it's duration!")
			self:Destroy()
			return
		end
    end)

    return self
end

function EffectOverTime:BindToHeartbeat(callbackFn)
   table.insert(self.HeartbeatConnections, callbackFn) 
end

function EffectOverTime:Destroy()
    if self.Destroying or self.Destroying == nil then return end
    self.Destroying = true
    task.wait()
    self.Heartbeat:Disconnect()

end

return EffectOverTime