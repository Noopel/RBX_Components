local GhostBox = {}

local template = Instance.new("Part")
template.CanCollide = false
template.CanQuery = false
template.CastShadow = false
template.Anchored = true
template.Massless = true
template.Material = Enum.Material.Neon
template.Size = Vector3.new(1,1,1)
template.Position = Vector3.new(0,0,0)
template.Transparency = 0.75
template.Color = Color3.new(0, 0, 1)

local eventDictionary = {
	client = {
		start = Color3.new(0, 0.984314, 1),
		ray = Color3.new(0.101961, 1, 0),
		default = Color3.new(0.117647, 0, 1)
	},
	server = {
		start = Color3.new(1, 0.54902, 0),
		ray = Color3.new(0.101961, 1, 0),
		default = Color3.new(1, 0, 0)
	},
}

function GhostBox.create(cf: CFrame, size: Vector3, partType: Enum.PartType, duration: number, event: string)
	local ghost_box = template:Clone()
	ghost_box.CFrame = cf
	ghost_box.Size = size
	ghost_box.Shape = partType
	
	if game["Run Service"]:IsClient() then
		ghost_box.name = "Client_GhostBox"
		if event and eventDictionary["client"][event] then
			ghost_box.Color = eventDictionary["client"][event]
		end
	else
		ghost_box.name = "Server_GhostBox"
		if event and eventDictionary["server"][event] then
			ghost_box.Color = eventDictionary["server"][event]
		end
	end
	
	if duration then
		task.delay(duration, function()
			ghost_box:Destroy()
		end)
	end
	
	ghost_box.Parent = workspace.DebrisFolder
	return ghost_box
end

return GhostBox
