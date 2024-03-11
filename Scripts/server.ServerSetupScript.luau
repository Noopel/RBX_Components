--THIS SCRIPT SHOULD BE LOCATED IN 'ServerScriptService'
--This script sets up commonly used tags and things

game.Players.PlayerAdded:Connect(function(Player)
	local Character = Player.Character or Player.CharacterAdded:Wait()
	Character:AddTag("Player")
	Player.CharacterAdded:Connect(function(Character) Character:AddTag("Player") end)
end)
