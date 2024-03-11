local SpacialQuery = {}

export type filter = {[any]: any}

local function setupParams(filter)
    local Params = OverlapParams.new()
    Params:AddToFilter(filter or {})
    Params.FilterType = Enum.RaycastFilterType.Include
    return Params
end

function SpacialQuery.getTaggedInPart(part: BasePart, filter, sentParams)
    local Params = sentParams or setupParams(filter)
    return workspace:GetPartsInPart(part, Params)
end

function SpacialQuery.getTaggedInBox(cf: CFrame, size: Vector3, filter: filter, sentParams: OverlapParams)
    local Params = sentParams or setupParams(filter)
    return workspace:GetPartBoundsInBox(cf, size, Params)
end

function SpacialQuery.getTaggedInRadius(position: Vector3, radius: number, filter: filter, sentParams: OverlapParams)
    local Params = sentParams or setupParams(filter)
    return workspace:GetPartBoundsInRadius(position, radius, Params)
end

return SpacialQuery