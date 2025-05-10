-- LocalScript in Workspace.Nexus
print("NexusScript started")

local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local part = script.Parent:WaitForChild("Part", 5)
local clickDetector = part and part:WaitForChild("ClickDetector", 5)

if not (part and clickDetector) then
	warn("Nexus Part or ClickDetector missing")
	return
end
print("Nexus ClickDetector found")

-- Create NexusGUI programmatically
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

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 100, 0, 50)
CloseButton.Position = UDim2.new(0, 100, 0, 240)
CloseButton.Text = "Close"
CloseButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
CloseButton.Parent = NexusFrame

-- Clone NexusGUIScript from ReplicatedStorage
local NexusGUIScript = ReplicatedStorage:WaitForChild("NexusGUIScript", 5)
if NexusGUIScript then
	local clonedScript = NexusGUIScript:Clone()
	clonedScript.Parent = NexusFrame
	print("NexusGUIScript cloned and parented")
else
	warn("NexusGUIScript not found in ReplicatedStorage")
end

clickDetector.MouseClick:Connect(function()
	print("Nexus ClickDetector triggered")
	NexusGUI.Enabled = not NexusGUI.Enabled
	print("NexusGUI toggled to " .. tostring(NexusGUI.Enabled))
end)