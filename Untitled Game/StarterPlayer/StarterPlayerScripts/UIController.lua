-- @ScriptType: LocalScript
-------------------------------------------------------
-- StarterPlayerScripts/UIController.lua (LocalScript)
-------------------------------------------------------
local RS = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer
local events = RS.RemoteEvents

local screen = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
local buttons = {"Sample","Sequence","Cultivate","Harvest","Package","Trade"}
for idx, name in ipairs(buttons) do
	local btn = Instance.new("TextButton", screen)
	btn.Name = name .. "Btn"
	btn.Size = UDim2.new(0, 120, 0, 40)
	btn.Position = UDim2.new(0, 10, 0, (idx - 1) * 50 + 10)
	btn.Text = name
	btn.MouseButton1Click:Connect(function()
		if name == "Sample" then events.SampleSeedEvent:FireServer() end
		if name == "Sequence" then events.SequenceTraitEvent:FireServer(1) end
		if name == "Cultivate" then events.CultivateEvent:FireServer(1) end
		if name == "Harvest" then events.HarvestEvent:FireServer(1) end
		if name == "Package" then events.PackageEvent:FireServer({name = "ExampleCrop"}) end
		if name == "Trade" then events.TradeEvent:FireServer(1) end
	end)
end

-- Listen and print
for _, evt in ipairs({"SampleSeed","SequenceTrait","Cultivate","Harvest","Package","Trade","UpdateReputation"}) do
	events[evt .. "Event"].OnClientEvent:Connect(print)
end