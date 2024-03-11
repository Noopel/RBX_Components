local EffectPlayer = {}

function EffectPlayer.runEffects(VFX, size: Vector3, radius: number, event: string)
	local List
	if type(VFX) == "table" then
		List = VFX
	else
		List = VFX:GetDescendants()
	end

	for _, object in pairs(List) do
		if event and not object:GetAttribute("Event") or event and object:GetAttribute("Event") ~= event then continue end
		if object:IsA("ParticleEmitter") then
			
			local DisableDelay = object:GetAttribute("DisableDelay")
			if DisableDelay then
				task.delay(DisableDelay, function()
					object.Enabled = false
				end)
			end
			if object:GetAttribute("EmitCount") then
				local EmitDelay = object:GetAttribute("EmitDelay") or 0

				task.delay(EmitDelay, function()
					object:Emit(object:GetAttribute("EmitCount"))
				end)
			end

			if object:GetAttribute("ScaleOffSize") and not object:GetAttribute("HasBeenScaled") then
				object:SetAttribute("HasBeenScaled", true)
				local OldNumberSequence = object.Size
				local NewNumberSequence = NumberSequence.new(0, (OldNumberSequence.Keypoints[#OldNumberSequence.Keypoints].Value) / size.Z * (radius * 2))
				object.Size = NewNumberSequence
			end

		elseif object:IsA("Sound") then
			local SoundDelay = object:GetAttribute("SoundDelay") or 0
			task.delay(SoundDelay, function()
				object:Play()
			end)
		end
	end
end

return EffectPlayer