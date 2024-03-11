local TargetQuery = {}

local CollectionService = game:GetService("CollectionService")

export type queryResult = {target: BasePart | Model, distance: number, direction: Vector3}

function TargetQuery.findNearestTarget(position:Vector3, arrayOfTags): queryResult
	local nearestTarget
	local nearestDistance
	local nearestDirection	
	
	for i, tag in pairs(arrayOfTags) do
		for _, target in pairs(CollectionService:GetTagged(tag)) do
			local primaryPart: BasePart = target
			if target:IsA("Model") then primaryPart = target.PrimaryPart end
			local offset = primaryPart.Position - position
			
			if not nearestTarget or offset.Magnitude > nearestDistance then
				nearestTarget = target
				nearestDistance = offset.Magnitude
				nearestDirection = offset.Unit
			end
		end
	end
	return {target = nearestTarget, distance = nearestDistance, direction = nearestDirection}
end

return TargetQuery
