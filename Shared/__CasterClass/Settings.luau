--CURRENT VERSION: 0.9
--Scripter: Noopel_V
--Built on the FastCastRedux module with newer features specifically made for my own use

local Settings = {
	PrintProjectileTermination = false,
	PrintProjectileInitialization = false,
	
	ClientReplicationEvent = game.ReplicatedStorage.RemoteEvents.ReplicationEvent,
	SetupPlayerTag = true,
	ProjectileFolder = game.ReplicatedStorage.ClientAssets.VFX.ProjectileVFX,
	DebrisFolder = workspace.DebrisFolder, --Path to the folder where projectiles are temporarily stored
	ValidHitBoxTypes = {"Raycast", "Cosmetic", "Shape"},
	VisualizeCasts = false,
	
	GhostBoxClient = false,
	GhostRayClient = false,
	GhostExplosionClient = false,
	
	GhostBoxServer = false,
	GhostRayServer = false,
	GhostExplosionServer = false,
}

local template = Instance.new("Part")
template.Size = Vector3.new(2,0.5,0.5)
template.Transparency = 1
template.BrickColor = BrickColor.new("Smoky grey")
template.Anchored = true
template.CanCollide = false
template.CanQuery = false
template.CanTouch = false

Settings.Template = template

function Settings.getCasterType()
	
end


return Settings
