local SoundPlayer = {}

local SoundService = game:GetService("SoundService")
local debrisFolder = workspace.DebrisFolder

local template = Instance.new("Part")
template.Size = Vector3.new(1,1,1)
template.CanCollide = false
template.CanQuery = false
template.CanTouch = false
template.CastShadow = false
template.Anchored = true
template.Transparency = 1

function SoundPlayer.findSound(soundName: string)
	return SoundService:FindFirstChild(soundName, true)
end

function SoundPlayer.playAtPosition(position: Vector3, soundObject: Sound | string)
	if typeof(soundObject) == "string" then soundObject = SoundPlayer.findSound(soundObject) end --Will attempt it's own search if the provided value is a string
	if not soundObject then warn("No Sound instance was found!") return end --Checks if it exists
	if soundObject ~= "Instance" then warn("Object provided was not an Instance!") return end --Checks if it's an instance
	if not soundObject:IsA("Sound") then warn("Instance is not a Sound!") return end --Checks if it is a Sound instance
	
	local part = template:Clone()
	part.Position = position
	
	local sound = soundObject:Clone()
	sound.Parent = part
	
	sound.Ended:Once(function()
		part:Destroy()
	end)
	
	part.Parent = debrisFolder
	sound:Play()
end

function SoundPlayer.playOnTarget(target: BasePart, soundObject: Sound | string)
	if typeof(soundObject) == "string" then soundObject = SoundPlayer.findSound(soundObject) end
	if not soundObject then warn("No sound was found or provided!") return end
	
	local sound = soundObject:Clone()
	sound.Parent = target

	sound.Ended:Once(function()
		sound:Destroy()
	end)

	sound.Parent = target
	sound:Play()
end

return SoundPlayer
