-- LocalScript in ReplicatedStorage
local player = game.Players.LocalPlayer
local backpack = player:WaitForChild("Backpack")
local character = player.Character or player.CharacterAdded:Wait()
local TweenService = game:GetService("TweenService")

print("NexusGUIScript running")

local bays = {
	script.Parent:WaitForChild("Bay1", 5),
	script.Parent:WaitForChild("Bay2", 5),
	script.Parent:WaitForChild("Bay3", 5),
}

-- Lockout to prevent click-through
local guiLockout = false
local LOCKOUT_TIME = 0.5

-- Detect GUI opening
script.Parent.Parent:GetPropertyChangedSignal("Enabled"):Connect(function()
	if script.Parent.Parent.Enabled then
		guiLockout = true
		print("NexusGUI opened, lockout enabled")
		task.wait(LOCKOUT_TIME)
		guiLockout = false
		print("NexusGUI lockout disabled")
	end
end)

for i, bay in ipairs(bays) do
	if not bay then
		warn("Bay" .. i .. " not found")
		return
	end
	local plantButton = bay:WaitForChild("PlantSeedButton", 5)
	local progressBar = bay:WaitForChild("ProgressBar", 5)
	if not (plantButton and progressBar) then
		warn("PlantSeedButton or ProgressBar missing in Bay" .. i)
		return
	end

	plantButton.MouseButton1Click:Connect(function()
		if not guiLockout then
			print("PlantSeedButton clicked in Bay" .. i)
			local sample = backpack:FindFirstChild("Sample") or (character and character:FindFirstChild("Sample"))
			if sample then
				print("Sample found in " .. (sample.Parent == backpack and "Backpack" or "Character"))
				sample:Destroy()
				plantButton.Visible = false
				progressBar.Size = UDim2.new(0, 0, 1, 0)
				progressBar.Visible = true
				local tween = TweenService:Create(progressBar, TweenInfo.new(5, Enum.EasingStyle.Linear), {Size = UDim2.new(1, 0, 1, 0)})
				tween:Play()
				tween.Completed:Connect(function()
					progressBar.Visible = false
					plantButton.Visible = true
					print("Growth complete in Bay" .. i)
				end)
			else
				print("No sample found for planting")
			end
		else
			print("PlantSeedButton click ignored (GUI lockout)")
		end
	end)
end

local closeButton = script.Parent:WaitForChild("CloseButton", 5)
if closeButton then
	closeButton.MouseButton1Click:Connect(function()
		if not guiLockout then
			print("Nexus Close button clicked")
			script.Parent.Parent.Enabled = false
		else
			print("Nexus Close button click ignored (GUI lockout)")
		end
	end)
else
	warn("Nexus CloseButton not found")
end