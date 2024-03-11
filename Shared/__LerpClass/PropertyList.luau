export type ArrayOfTags = {}
export type propList = {
	Shape: string,
	Style: string,
	Amount: number,
	Velocity: number,
	MaxDistance: number,
	MaxDistancePity: number,
	DistanceOffset: number,
	StartPointLookOffset: number,
	TotalAngle: number,
	MaxAngle: number,
	RandomizeAngle: boolean,
	RandomDistanceOffset: NumberRange,
	
	MidPointPositionScale: number,
	MidPointOffset: number,
	MidPointScale: number,
	MidPointRandomizer: boolean,
	MidPointRandomOffset: NumberRange,
	MidPointRandomScale: NumberRange,
	
	CanBounce: boolean,
	BounceLimit: number,
	BounceDistanceMultiplier: number,
	ForceAllBounces: boolean,
	ResetHitListAfterBounce: boolean,
	
	TracksTarget: boolean,
	
	TagFilter: ArrayOfTags,
	IgnoreFilter: ArrayOfTags,
	
	VFXName: string,
	
	CompletedHitShape: Enum.PartType,
	CompletedHitRadius: number,
}

local PropertyList = {}

local Properties: propList = {
	Shape = "Circular", --The shape the start points gets put into
	Style = "Bezier", --Determines if there'll be a midpoint or not
	
	LerpDelay = -1, --Determines the delay between each lerp, where -1 has it turned off (NOTE: Anything lower than 0.01666... will always be around 1/60 due to the server running at 60 FPS)
	
	Amount = 3,
	Velocity = 50, --This is used to calculate the total duration of the lerp, based on the distance between the start and end point
	MaxDistance = 80, --The max distance used to determine if you can fire or not
	MaxDistancePity = 1.1, --The pity added on top of the max distance when calculating the new end position, if the End target is a BasePart.
	DistanceOffset = 5, --How far the start position is offset from the start point
	StartPointLookOffset = 5,
	TotalAngle = 180, --The total angle the lerps can spread out in
	MaxAngle = 25, --The max angle between each indiviual lerp (ONLY USED IF AMOUNT > 1)
	RandomDistanceOffset = NumberRange.new(0, 0),
	
	MidPointPositionScale = 0.5, --Determines how far the MidPoint is between the start and end point. (Between 0 and 1)
	
	MidPointOffset = 0, --A flat value multiplied to the MidPoint position
	MidPointScale = 0.2, --How much of the distance between the start and end point is multiplied into the MidPoint position
	MidPointRandomizer = false,
	MidPointRandomOffset = NumberRange.new(0, 0),
	MidPointRandomScale = NumberRange.new(0, 0),
	
	CanBounce = false,
	BounceLimit = 3,
	BounceDistanceMultiplier = 0.5,
	ResetHitListAfterBounce = false,
	BounceMinDuration = 0.2,
	
	TracksTarget = false,
	
	TagFilter = {"EnemyNPC"}, --Used to fire the HitDetected event when the lerp ends or the raycast hits something
	IgnoreFilter = {}, --A filter used to ignore certain tags
	
	VFXName = "LightOrb", --Name of the VFX that'll be used on the client side
	
	CompletedHitShape = Enum.PartType.Ball,
	CompletedHitRadius = 1,
}
Properties.__index = Properties

PropertyList.Properties = Properties

local translateTable = {
	Shape = "1",
	Style = "2",
	LerpType = "3",
	LerpDelay = "4",
	Amount = "5",
	Velocity = "6",
	DistanceOffset = "7",
	TotalAngle = "8",
	MaxAngle = "9",
	MidPointPositionScale = "a",
	MidPointOffset = "b",
	MidPointScale = "c",
	MidPointRandomizer = "d",
	MidPointRandomOffset = "e",
	MidPointRandomScale = "f",
	TracksTarget = "g",
	TagFilter = "h",
	IgnoreFilter = "i",
	ShapecastShape = "j",
	VFXName = "k",
	CompletedHitShape = "l",
	CompletedHitRadius = "m",
	StartPointLookOffset = "n",
	MaxDistance = "o",
	MaxDistancePity = "p",
	CanBounce = "q",
	BounceLimit = "r",
	BounceDistanceMultiplier = "s",
	RandomizeAngle = "t",
	ResetHitListAfterBounce = "u",
	BounceMinDuration = "v",
	RandomDistanceOffset = "w",
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