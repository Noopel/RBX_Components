local Settings = {
	DebrisFolder = workspace.DebrisFolder,
	ClientReplicationEvent = game.ReplicatedStorage.RemoteEvents.ReplicationEvent,
}

local Template = Instance.new("Part")
Template.Anchored = true
Template.Transparency = 1
Template.Color = Color3.new(1, 0.533333, 0)
Template.Material = Enum.Material.SmoothPlastic
Template.CanCollide = false
Template.CanQuery = false
Template.CanTouch = false
Template.Shape = Enum.PartType.Cylinder
Template.Name = "ZoneHurtBox"

Settings.Template = Template

return Settings
