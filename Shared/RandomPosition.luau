local RandomPosition = {}

local CollectionService = game:GetService("CollectionService")

function RandomPosition.getPositionFromRadius(center: Vector3, radius_range: NumberRange, seekGround: boolean, seek_range: NumberRange, arrayOfTags, specificAngle: number): Vector3
	local random_angle = specificAngle or math.random(0, 3600) / 10
	local cf = CFrame.new(center) * CFrame.Angles(0, math.rad(random_angle), 0)
	local position = (cf.LookVector * math.random(radius_range.Min, radius_range.Max)) + cf.Position
	if seekGround and seek_range then
		local Params = RaycastParams.new()
		Params.FilterType = Enum.RaycastFilterType.Exclude
		Params:AddToFilter(workspace.DebrisFolder)
		for i, tag in pairs(arrayOfTags) do
			Params:AddToFilter(CollectionService:GetTagged(tag))
		end
		for _, player in game.Players:GetPlayers() do
			if player.Character then
				Params:AddToFilter(player.Character)
			end
		end
		
		local rayresult = workspace:Raycast(position + Vector3.new(0, seek_range.Max, 0), Vector3.new(0, seek_range.Min - seek_range.Max, 0), Params)
		
		if rayresult then
			position = rayresult.Position
		end
	end
	return position
end

function RandomPosition.getPositionFromShape(center: Vector3, size: Vector3, shape: Enum.PartType, seekGround: boolean, seek_range: NumberRange, arrayOfTags): Vector3
	local position = center
	
	if shape == Enum.PartType.Block then
		position = Vector3.new(math.random(((size.X / 2) * 10) * -1, (size.X / 2) * 10) / 10, 0, math.random(((size.Z / 2) * 10) * -1, (size.Z / 2) * 10) / 10) + center
		if seekGround and seek_range then
			local Params = RaycastParams.new()
			Params.FilterType = Enum.RaycastFilterType.Exclude
			for i, tag in pairs(arrayOfTags) do
				Params:AddToFilter(CollectionService:GetTagged(tag))
			end

			local rayresult = workspace:Raycast(position + Vector3.new(0, seek_range.Max), Vector3.new(0, seek_range.Min, 0), Params)

			if rayresult then
				rayresult.Position = position
			end
		end
	end
	return position
end

return RandomPosition