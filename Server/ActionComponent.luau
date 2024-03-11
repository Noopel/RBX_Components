local ActionComponent = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedComponents = ReplicatedStorage.SharedComponents

--Dependencies
local Cooldown = require(SharedComponents.Cooldown)

export type animations = {Action: Animation, Setup: Animation}
export type animTracks = {Action: AnimationTrack, Setup: AnimationTrack}
export type callback = (actionName: string, animTracks, actionCooldown: number, userData: any) -> nil
export type callbackConditional = (distance: number, maxDistance: number, UserData: any) -> boolean

export type actionData = {Priority: number, Cooldown: number, MaxDistance: number, StartOnCooldown: boolean, Animations: animations}
export type action = {Name: string, Cooldown: number, MaxCooldown: number, Callback: callback, ConditionCallback: callbackConditional, AnimTracks: animTracks}

local function CreateActionData(owner, action: string, actionData: actionData, animator: Animator)
	local newActionData = {
		Name = action,
		Cooldown = actionData["Cooldown"] or 999,
		MaxDistance = actionData["MaxDistance"] or math.huge,
		Callback = actionData["Callback"],
		ConditionCallback = nil,
		AnimTracks = {},
	}
	if actionData["StartOnCooldown"] then
		Cooldown.setCooldown(owner, newActionData["Name"])
	end
	if actionData["Animations"] then
		for key, animation in pairs(actionData["Animations"]) do
			newActionData["AnimTracks"][key] = animator:LoadAnimation(animation)
		end
	end
	return newActionData
end

function ActionComponent.new(actionList, Animator: Animator)
	local self = {}
	local ActionArray = {}
	self.ActionArray = ActionArray
	
	self.owner = Instance.new("Part")
	
	for key, infoTable in pairs(actionList) do
		table.insert(ActionArray, infoTable["Priority"], CreateActionData(self.owner, key, infoTable, Animator))
	end
	
	self.setCallbackOfAction = function(Action: string, Callback: callback): boolean
		for i, infoTable in ActionArray do
			if infoTable["Name"] == Action and typeof(Callback) == "function" then
				infoTable["Callback"] = Callback
				return true
			end
		end
		print("Warning: Didn't find an action with name: " .. tostring(Action))
		return false
	end
	
	self.setConditionalCallbackOfAction = function(Action: string, Callback: callbackConditional): boolean
		for i, infoTable in ActionArray do
			if infoTable["Name"] == Action and typeof(Callback) == "function" then
				infoTable["ConditionCallback"] = Callback
				return true
			end
		end
		return false
	end
	
	self.run = function(distance: number, UserData)
		for i, infoTable in ipairs(ActionArray) do
			local overruleValue = 0
			if infoTable["ConditionCallback"] then
				local cleared: boolean, priorityValue: number = infoTable["ConditionCallback"](distance, infoTable.MaxDistance, UserData)
				if not cleared then continue end
				overruleValue = priorityValue or 0
				if overruleValue > 0 then
					print("Some conditions are overruled! OverruleValue: " .. tostring(overruleValue))
				end
			end
			if overruleValue < 2 and Cooldown.getCooldown(self.owner, infoTable["Name"]) then continue end
			if overruleValue < 1 and distance and infoTable["MaxDistance"] < distance then continue end
			
			Cooldown.setCooldown(self.owner, infoTable["Name"], infoTable["Cooldown"])
			
			if infoTable["Callback"] and typeof(infoTable.Callback) == "function" then
				infoTable.Callback(infoTable.Name, infoTable.AnimTracks, infoTable.Cooldown, UserData)
			end
		end
	end
	
	self.Destroy = function()
		self.Destroy = nil
		self.run = nil
		self.setCallbackOfAction = nil
		for i, infoTable in ipairs(self.ActionArray) do
			if infoTable.Track then infoTable.Track:Destroy() end
			infoTable = nil
		end
		self.ActionArray = nil
		self = nil
	end
	
	return self
end

return ActionComponent