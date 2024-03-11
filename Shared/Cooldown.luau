local CooldownComponent = {}

local Cooldowns = {}

local CooldownAdded = Instance.new("BindableEvent")
local CooldownRemoved = Instance.new("BindableEvent")

CooldownComponent.CooldownAdded = CooldownAdded.Event
CooldownComponent.CooldownRemoved = CooldownRemoved.Event

function CooldownComponent.setCooldown(owner: Model | BasePart, id: string, duration: number, sendSignal: boolean)
    sendSignal = sendSignal or false
	if not Cooldowns[owner] then Cooldowns[owner] = {} end
	local PlayerCooldowns = Cooldowns[owner]

	local Ver = 1

	if Cooldowns[owner][id] then
		Ver = Cooldowns[owner][id]["Ver"] + 1
	else
		Cooldowns[owner][id] = {Ver = Ver}
	end

    CooldownAdded:Fire(owner, id, duration)

	task.delay(duration, function()
		if Ver == Cooldowns[owner][id]["Ver"] then
			Cooldowns[owner][id] = nil
		end
	end)
end

function CooldownComponent.getCooldown(owner: Model | BasePart, id: string)
	if not Cooldowns[owner] then Cooldowns[owner] = {} end
	if Cooldowns[owner][id] then
		return true
	end
	return false
end

return CooldownComponent