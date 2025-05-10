-- LocalScript in StarterPlayerScripts
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("GUIManager started")

-- Debounce for GUI toggling
local guiDebounce = false
local DEBOUNCE_TIME = 0.5

-- Create SequencerGUI
local SequencerGUI = Instance.new("ScreenGui")
SequencerGUI.Name = "SequencerGUI"
SequencerGUI.Enabled = false
SequencerGUI.Parent = playerGui
print("SequencerGUI created")

local SequencerFrame = Instance.new("Frame")
SequencerFrame.Size = UDim2.new(0, 300, 0, 200)
SequencerFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
SequencerFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
SequencerFrame.Parent = SequencerGUI

local ExtractButton = Instance.new("TextButton")
ExtractButton.Name = "ExtractButton"
ExtractButton.Size = UDim2.new(0, 100, 0, 50)
ExtractButton.Position = UDim2.new(0, 100, 0, 50)
ExtractButton.Text = "Extract"
ExtractButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
ExtractButton.Parent = SequencerFrame

local TraitsLabel = Instance.new("TextLabel")
TraitsLabel.Name = "TraitsLabel"
TraitsLabel.Size = UDim2.new(0, 200, 0, 50)
TraitsLabel.Position = UDim2.new(0, 50, 0, 100)
TraitsLabel.Text = ""
TraitsLabel.BackgroundTransparency = 1
TraitsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TraitsLabel.Visible = false
TraitsLabel.Parent = SequencerFrame

local SequencerCloseButton = Instance.new("TextButton")
SequencerCloseButton.Name = "CloseButton"
SequencerCloseButton.Size = UDim2.new(0, 100, 0, 50)
SequencerCloseButton.Position = UDim2.new(0, 100, 0, 150)
SequencerCloseButton.Text = "Close"
SequencerCloseButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
SequencerCloseButton.Parent = SequencerFrame

-- Create NexusGUI
local NexusGUI = Instance.new("ScreenGui")
NexusGUI.Name = "NexusGUI"
NexusGUI.Enabled = false
NexusGUI.Parent = playerGui
print("NexusGUI created")

local NexusFrame = Instance.new("Frame")
NexusFrame.Size = UDim2.new(0, 300, 0, 300)
NexusFrame.Position = UDim2.new(0.5, -150, 0.5, -150)
NexusFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
NexusFrame.Parent = NexusGUI

local bayNames = {"Bay1", "Bay2", "Bay3"}
for i, bayName in ipairs(bayNames) do
	local bay = Instance.new("Frame")
	bay.Name = bayName
	bay.Size = UDim2.new(0, 80, 0, 100)
	bay.Position = UDim2.new(0, 10 + (i-1)*100, 0, 50)
	bay.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	bay.Parent = NexusFrame

	local plantButton = Instance.new("TextButton")
	plantButton.Name = "PlantSeedButton"
	plantButton.Size = UDim2.new(0, 60, 0, 30)
	plantButton.Position = UDim2.new(0, 10, 0, 10)
	plantButton.Text = "Plant Sample"
	plantButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	plantButton.Parent = bay

	local progressBar = Instance.new("Frame")
	progressBar.Name = "ProgressBar"
	progressBar.Size = UDim2.new(0, 0, 1, 0)
	progressBar.Position = UDim2.new(0, 0, 0, 0)
	progressBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	progressBar.Visible = false
	progressBar.Parent = bay
end

local NexusCloseButton = Instance.new("TextButton")
NexusCloseButton.Name = "CloseButton"
NexusCloseButton.Size = UDim2.new(0, 100, 0, 50)
NexusCloseButton.Position = UDim2.new(0, 100, 0, 240)
NexusCloseButton.Text = "Close"
NexusCloseButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
NexusCloseButton.Parent = NexusFrame

-- Clone GUI scripts
local SequencerGUIScript = ReplicatedStorage:WaitForChild("SequencerGUIScript", 5)
if SequencerGUIScript then
	local clonedScript = SequencerGUIScript:Clone()
	clonedScript.Parent = SequencerFrame
	print("SequencerGUIScript cloned and parented")
else
	warn("SequencerGUIScript not found in ReplicatedStorage")
end

local NexusGUIScript = ReplicatedStorage:WaitForChild("NexusGUIScript", 5)
if NexusGUIScript then
	local clonedScript = NexusGUIScript:Clone()
	clonedScript.Parent = NexusFrame
	print("NexusGUIScript cloned and parented")
else
	warn("NexusGUIScript not found in ReplicatedStorage")
end

-- Handle seed collection
local CollectSeedEvent = ReplicatedStorage:WaitForChild("CollectSeedEvent")
CollectSeedEvent.OnClientEvent:Connect(function()
	local seedTool = Instance.new("Tool")
	seedTool.Name = "Seed"
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.5, 0.5, 0.5)
	handle.Position = Vector3.new(0, 0, 0)
	handle.Parent = seedTool
	seedTool.Parent = player.Backpack
	print("Seed added to Backpack via CollectSeedEvent")
	print("Backpack contents: ")
	for _, item in pairs(player.Backpack:GetChildren()) do
		print(" - " .. item.Name)
	end
end)

-- Handle GUI toggling
local ToggleGUIEvent = ReplicatedStorage:WaitForChild("ToggleGUIEvent")
ToggleGUIEvent.OnClientEvent:Connect(function(guiName)
	if not guiDebounce then
		guiDebounce = true
		print("ToggleGUIEvent received for " .. guiName)
		local gui = playerGui:FindFirstChild(guiName)
		if gui then
			gui.Enabled = not gui.Enabled
			print(guiName .. " toggled to " .. tostring(gui.Enabled))
		else
			warn(guiName .. " not found in PlayerGui")
		end
		task.wait(DEBOUNCE_TIME)
		guiDebounce = false
	else
		print("GUI toggle debounced for " .. guiName)
	end
end)