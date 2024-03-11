local PropertyList = {}

local Properties = {
	PartCacheAmount = 2,
	HitBoxProperties = {},
	
	TagFilter = {"EnemyNPC"},
	
	Width = 20, --How wide it is
	Height = 20, --How tall it is
	GroundOffset = 0.33, --How much it offsets itself based on size, so 0.5 would be the end of the part at the position, while 1 would make it be offset by it's full size
	
	StartDelay = 0, --Gives it a delay before beginning the main loop
	
	TickOnStart = false, --Determines if it can tick on start
	Duration = 5, --Number in seconds
	TickRate = 1, --How much time between each tick
	
	IgnoreCaster = true,
	
	BeamColor = Color3.new(1, 1, 1),
	
	CanGrow = false,
	WidthGrowthGoal = 1.25, --How much it'll increase based on base Width
	
	VFXName = "",
}
Properties.__index = Properties

PropertyList.Properties = Properties

local translateTable = {
	PartCacheAmount = "1",
	HitBoxProperties = "2",
	TagFilter = "3",
	VFXName = "4",
	Width = "5",
	Height = "6",
	GroundOffset = "7",
	Shape = "8",
	StartDelay = "9",
	TickWaitPosition = "a",
	Duration = "b",
	TickRate = "c",
	CanGrow = "d",
	WidthGrowthGoal = "e",
	IgnoreCaster = "f",
	BeamColor = "g",
}

export type partProperties = {}
export type ArrayOfTags = {}

export type propList = {
	PartCacheAmount: number,
	HitBoxProperties: partProperties,

	TagFilter: ArrayOfTags,

	Width: number,
	Height: number,
	GroundOffset: number, 

	StartDelay: number,

	TickOnStart: boolean,
	Duration: number,
	TickRate: number,
	
	VFXName: string,
	
	CanGrow: boolean,
	WidthGrowthGoal: number,
	
	IgnoreCaster: boolean,
}

function PropertyList.encodeProperties(Properties)
	local encodedProperties = {}
	for key, value in Properties do
		local numberKey = translateTable[key] or key
		encodedProperties[numberKey] = value
	end
	return encodedProperties
end

function PropertyList.decodeProperties(encodedProperties)
	for key, number in translateTable do
		local value = encodedProperties[number] or encodedProperties[tostring(number)]
		if value then
			encodedProperties[key] = value
			encodedProperties[number] = nil
			encodedProperties[tostring(number)] = nil
		end
	end
	return encodedProperties
end

return PropertyList