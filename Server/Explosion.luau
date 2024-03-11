local Explosion = {}

local CollectionService = game:GetService("CollectionService")
local ReplicatedEvent = game.ReplicatedStorage.RemoteEvents.ReplicationEvent
local SharedComponents = game.ReplicatedStorage.SharedComponents
local ServerComponents = game.ServerStorage.ServerComponents

--Dependencies
local FuncLibrary = require(SharedComponents.FuncLibrary)
local SpacialQuery = require(ServerComponents.AreaDetection)

export type explosiveProps = {
	CanExplosde: boolean,
	Radius: number,
	AllowDamageTwice: boolean,
	VFXName: string,
	OnMiss: boolean,
	OnImpact: boolean,
	TagFilter: any,
}

local DefaultProperties = {
	CanExplode = false,
	Radius = 10,
	AllowDamageTwice = false,
	VFXName = nil,
	OnMiss = false,
	OnImpact = true,
	TagFilter = {"EnemyNPC", "Player"},
}

local function newProperties(providedProperties)
    local properties = {}
    for key, value in pairs(DefaultProperties) do
        if providedProperties[key] then
            properties[key] = providedProperties[key]
        else
            properties[key] = value
        end
    end
    return properties
end

function Explosion.explode(position: Vector3, providedProperties, HitList, collided: boolean, IgnoreList)
	local listOfTargets = {}
	if not providedProperties then providedProperties = {} end
	if not IgnoreList then IgnoreList = {} end
	
    local explosionProperties = newProperties(providedProperties)
	
	if explosionProperties["CanExplode"] and collided and explosionProperties["OnImpact"] or explosionProperties["CanExplode"] and not collided and explosionProperties["OnMiss"] then
		if explosionProperties["VFXName"] then
			ReplicatedEvent:FireAllClients("Explosion", {FuncLibrary.encodeVec3(position), explosionProperties.VFXName, explosionProperties.Radius})
		end
		
		local filter = {}

		if explosionProperties["TagFilter"] then
			for _, tag in pairs(explosionProperties["TagFilter"]) do
				for _, object in pairs(CollectionService:GetTagged(tag)) do
					table.insert(filter, object)
				end
			end
		end

		local listOfObjects = SpacialQuery.getTaggedInRadius(position, explosionProperties.Radius, filter)
		
		for _, object in listOfObjects do
			local actualObject = object:FindFirstAncestorOfClass("Model") or object
			if table.find(listOfTargets, actualObject) then continue end
			if table.find(IgnoreList, actualObject) then continue end
			if table.find(HitList, actualObject) and not explosionProperties["AllowDamageTwice"] then continue end
			table.insert(listOfTargets, actualObject)
		end
	end
	return listOfTargets
end

return Explosion