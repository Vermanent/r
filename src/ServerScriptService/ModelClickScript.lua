-- Script in ServerScriptService
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

print("ModelClickScript started")

-- Create RemoteEvents
local ToggleGUIEvent = Instance.new("RemoteEvent")
ToggleGUIEvent.Name = "ToggleGUIEvent"
ToggleGUIEvent.Parent = ReplicatedStorage
print("ToggleGUIEvent created")

local AddSampleEvent = Instance.new("RemoteEvent")
AddSampleEvent.Name = "AddSampleEvent"
AddSampleEvent.Parent = ReplicatedStorage
print("AddSampleEvent created")

-- Server-side debounce
local clickDebounce = {}
local DEBOUNCE_TIME = 0.5

-- Handle Sample addition
AddSampleEvent.OnServerEvent:Connect(function(player)
	print("AddSampleEvent received from " .. player.Name)
	local sampleTool
	local template = ServerStorage:FindFirstChild("Sample")
	if template then
		sampleTool = template:Clone()
		print("Cloned Sample tool from ServerStorage")
	else
		sampleTool = Instance.new("Tool")
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(0.5, 0.5, 0.5)
		handle.Position = Vector3.new(0, 0, 0)
		handle.Parent = sampleTool
		print("Created new Sample tool")
	end
	sampleTool.Name = "Sample"
	sampleTool.Parent = player.Backpack
	if player.Backpack:FindFirstChild("Sample") then
		print("Sample confirmed in " .. player.Name .. "'s Backpack server-side")
	else
		warn("Failed to add Sample to " .. player.Name .. "'s Backpack")
	end
end)

-- Handle Sequencer clicks
local sequencer = workspace:WaitForChild("Sequencer", 5)
if sequencer then
	local sequencerPart = sequencer:WaitForChild("Part", 5)
	local sequencerClickDetector = sequencerPart and sequencerPart:WaitForChild("ClickDetector", 5)
	if sequencerClickDetector then
		print("Sequencer ClickDetector found")
		sequencerClickDetector.MouseClick:Connect(function(player)
			if not clickDebounce[player.UserId] then
				clickDebounce[player.UserId] = true
				print("Sequencer ClickDetector triggered by " .. player.Name)
				ToggleGUIEvent:FireClient(player, "SequencerGUI")
				print("Fired ToggleGUIEvent for SequencerGUI")
				task.wait(DEBOUNCE_TIME)
				clickDebounce[player.UserId] = nil
			end
		end)
	else
		warn("Sequencer Part or ClickDetector not found")
	end
else
	warn("Sequencer model not found in Workspace")
end

-- Handle Nexus clicks
local nexus = workspace:WaitForChild("Nexus", 5)
if nexus then
	local nexusPart = nexus:WaitForChild("Part", 5)
	local nexusClickDetector = nexusPart and nexusPart:WaitForChild("ClickDetector", 5)
	if nexusClickDetector then
		print("Nexus ClickDetector found")
		nexusClickDetector.MouseClick:Connect(function(player)
			if not clickDebounce[player.UserId] then
				clickDebounce[player.UserId] = true
				print("Nexus ClickDetector triggered by " .. player.Name)
				ToggleGUIEvent:FireClient(player, "NexusGUI")
				print("Fired ToggleGUIEvent for NexusGUI")
				task.wait(DEBOUNCE_TIME)
				clickDebounce[player.UserId] = nil
			end
		end)
	else
		warn("Nexus Part or ClickDetector not found")
	end
else
	warn("Nexus model not found in Workspace")
end