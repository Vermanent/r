-- Script in ServerScriptService
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("PlantClickScript started")

-- Create RemoteEvent for seed collection
local CollectSeedEvent = Instance.new("RemoteEvent")
CollectSeedEvent.Name = "CollectSeedEvent"
CollectSeedEvent.Parent = ReplicatedStorage
print("CollectSeedEvent created")

-- Check Seed tool existence
local seedTool = ServerStorage:FindFirstChild("Seed")
if seedTool then
	print("Seed tool found in ServerStorage")
else
	warn("Seed tool not found in ServerStorage")
end

-- Handle plant clicks
local plantsFolder = workspace:WaitForChild("Plants", 5)
if plantsFolder then
	print("Plants folder found with " .. #plantsFolder:GetChildren() .. " children")
	for _, plant in pairs(plantsFolder:GetChildren()) do
		print("Checking plant: " .. plant.Name)
		local clickDetector = plant:FindFirstChild("ClickDetector")
		if clickDetector then
			print("ClickDetector found on " .. plant.Name)
			clickDetector.MouseClick:Connect(function(player)
				print("ClickDetector triggered on " .. plant.Name .. " by " .. player.Name)
				seedTool = ServerStorage:FindFirstChild("Seed")
				if seedTool then
					CollectSeedEvent:FireClient(player)
					print("Fired CollectSeedEvent for " .. player.Name)
				else
					warn("Seed tool not found in ServerStorage when clicked")
				end
			end)
		else
			warn("No ClickDetector on " .. plant.Name)
		end
	end
else
	warn("Plants folder not found in Workspace")
end