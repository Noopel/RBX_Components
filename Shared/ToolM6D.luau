local M6D = {}
M6D.__index = M6D

function M6D.new(Tool: Tool)
	if not Tool then return end
	local self = setmetatable({}, M6D)
	
	self.Tool = Tool
	self.Handle = Tool:WaitForChild("Handle", 1)
	self.Handle2 = Tool:WaitForChild("Model2", 1) or nil
	self.M6D = nil
	self.GripC1 = Tool.Grip
	self.GripC0 = CFrame.new(0, -0.158, 0) * CFrame.fromOrientation(math.rad(-90), 0, 0)
	
	return self
end

function M6D:Create(Character: Model)
	if not self.Tool then return end
	local RightHand = Character:FindFirstChild("RightHand")
	local RightGrip = RightHand:WaitForChild("RightGrip", 1)
	
	if not RightGrip then return end
	
	self.M6D = Instance.new("Motor6D")
	self.M6D.C0 = self.GripC0
	self.M6D.C1 = self.GripC1
	self.M6D.Part0 = RightHand
	self.M6D.Part1 = self.Handle
	self.M6D.Parent = RightHand
	
	RightGrip:Destroy()
end

function M6D:CreateLeftHand(Character: Model)
	
	if not self.Tool then return end
	local LeftHand = Character:FindFirstChild("LeftHand")
	
	if not LeftHand or not self.Handle2 then return end
	
	self.M6D2 = Instance.new("Motor6D")
	self.M6D2.C0 = self.GripC0
	self.M6D2.C1 = self.GripC1
	self.M6D2.Part0 = LeftHand
	self.M6D2.Part1 = self.Handle2.PrimaryPart
	self.M6D2.Parent = LeftHand
	
	
end

function M6D:Destroy()
	if self.M6D then
		self.M6D:Destroy()
	end
	if self.M6D2 then
		self.M6D2:Destroy()
	end
end

return M6D
