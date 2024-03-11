local PropertyList = {}

local Properties = {
	Velocity = 80,
	MaxDistance = 120,
	Gravity = 0,
	TagFilter = {"EnemyNPC"},
	IgnoreFilter = {},
	TagFilterType = "Include",
	HitBoxType = "Raycast", --Will ALWAYS default to Raycast if Cosmetic or Shape is provided and their UseCosmetic and UseShape properties are turned off
	
	HitBoxShape = "Box", --Used for server Shape and Cosmetic hitbox registration, can be either Box or Sphere
	OverrideHitBoxSize = nil, --Can be set in case of overriding the actual sizes of said hitboxes
	
	--Piercing properties W.I.P. AVOID USING THIS FOR NOW
	CanPierce = false,
	PierceLimit = 0,
	
	--CosmeticProjectile properties
	UseCosmetic = false,
	CosmeticProjectile = "PlaceholderCosmetic",
	CosmeticAngularVelocity = Vector3.new(0, 0, 0),
	
	--ShapedProjectile properties
	UseShape = false,
	ShapeType = Enum.PartType.Block,
	ShapeSize = Vector3.new(1,1,3),
	ShapeTransparency = 1,
	ShapeAngularVelocity = Vector3.new(0, 0, 0),
}
Properties.__index = Properties

PropertyList.Properties = Properties

local translateTable = {
	Velocity = "1",
	MaxDistance = "2",
	Gravity = "3",
	TagFilter = "4",
	IgnoreFilter = "5",
	TagFilterType = "6",
	HitBoxType = "7",
	HitBoxShape = "8",
	OverrideHitBoxSize = "9",
	CanPierce = "a",
	PierceLimit = "b",
	ExplodesOnImpact = "c",
	ExplodesOnMiss = "d",
	ExplosionIgnoreHitLimit = "e",
	IgnoreExplosionMultiHitLimit = "f",
	UseCosmetic = "g",
	CosmeticProjectile = "h",
	CosmeticAngularVelocity = "i",
	UseShape = "j",
	ShapeType = "k",
	ShapeSize = "l",
	ShapeTransparency = "m",
	ShapeAngularVelocity = "n",
	ExplosionVFXName = "r",
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

export type properties = {
	Velocity: number,
	MaxDistance: number,
	Gravity: number,
	TagFilter: tagFilter,
	IgnoreFilter: ignoreFilter,
	TagFilterType: string,
	HitBoxType: string,

	HitBoxShape: string,
	OverrideHitBoxSize: boolean,

	CanPierce: boolean,
	PierceLimit: number,

	UseCosmetic: boolean,
	CosmeticProjectile: string,
	CosmeticAngularVelocity: Vector3,

	UseShape: boolean,
	ShapeType: Enum.PartType,
	ShapeSize: Vector3,
	ShapeTransparency: number,
	ShapeAngularVelocity: Vector3,

	ExplosionVFXName: string,
}

return PropertyList