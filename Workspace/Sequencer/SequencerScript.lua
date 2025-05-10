-- LocalScript in Workspace.Sequencer
print("SequencerScript started")

local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local sequencerGui = playerGui:WaitForChild("SequencerGUI", 5)
local clickDetector = script.Parent:WaitForChild("Part"):WaitForChild("ClickDetector", 5)

if not (sequencerGui and clickDetector) then
	warn("SequencerGUI or ClickDetector missing")
	return
end
print("Sequencer ClickDetector found")

clickDetector.MouseClick:Connect(function()
	print("Sequencer ClickDetector triggered")
	sequencerGui.Enabled = not sequencerGui.Enabled
	print("SequencerGUI toggled to " .. tostring(sequencerGui.Enabled))
end)