local FuncLibrary = {}

export type ArrayOfTags = {}

function FuncLibrary.encodeVec3(Vec3: Vector3, decMult: number): Vector3
	if not decMult then decMult = 10 end
	return Vector3.new(math.floor(Vec3.X * decMult), math.floor(Vec3.Y * decMult), math.floor(Vec3.Z * decMult)) 
end

function FuncLibrary.decodeVec3(Vec3: Vector3, decMult: number): Vector3
	if not decMult then decMult = 10 end
	return Vec3 / decMult
end

function FuncLibrary.hasTagFromList(instance: Instance, tagList, tagFilter, objectFilter): boolean --Returns 2 booleans, HasTag and WasIgnored
	if not tagList then warn("No tag list was provided!") tagList = {} end
	if not tagFilter then tagFilter = {} end
	if not objectFilter then objectFilter = {} end
	
	for _, tag in tagFilter do
		if instance:HasTag(tag) then return false, true end
	end
	
	for _, tag in tagList do
		if instance:HasTag(tag) and not table.find(objectFilter, instance) then
			return true, false
		end
	end
	
	return false, false
end

function FuncLibrary.deepCopyTable(baseTable)
	local newTable = {}
	for key, value in pairs(baseTable) do
		if key == "__index" then continue end
		if type(value) == "table" then
			value = FuncLibrary.deepCopyTable(value)
		end
		newTable[key] = value
	end
	local metatable = getmetatable(baseTable)
	if metatable then --CAUSES STACK OVERFLOW
		setmetatable(newTable, metatable)
	end
	
	return newTable
end

function FuncLibrary.clearTable(Table: table)
	for key, value in pairs(Table) do
		if typeof(value) == "table" then
			if value.ClassName == "Signal" then
				value:Destroy()
			else
				FuncLibrary.clearTable(value)
			end
		elseif typeof(value) == "Instance" and value and not value:IsA("Player") and not value:IsA("Animation") then
			if not value.Parent or value.Parent:IsA("Player") then
				value:Destroy()
			end
		elseif typeof(value) == "RBXScriptConnection" then
			value:Disconnect()
		else	
			value = nil
		end
		Table[key] = nil
	end
end

function FuncLibrary.lerp(a, b, t)
	return a + (b - a) * t
end

function FuncLibrary.bezierQuad(p0: Vector3, p1: Vector3, p2: Vector3, t: number): Vector3
	return (1 - t)^2 * p0 + 2 * (1 - t) * t * p1 + t^2 * p2
end

function FuncLibrary.bezierCubic(p0, p1, p2, p3, t)
	return (1 - t)^3*p0 + 3*(1 - t)^2*t*p1 + 3*(1 - t)*t^2*p2 + t^3*p3
end

return FuncLibrary