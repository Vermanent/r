-- LocalScript in ReplicatedStorage
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local player = game.Players.LocalPlayer
local backpack = player:WaitForChild("Backpack")
local character = player.Character or player.CharacterAdded:Wait()

print("SequencerGUIScript running")

local extractButton = script.Parent:WaitForChild("ExtractButton", 5)
local traitsLabel = script.Parent:WaitForChild("TraitsLabel", 5)
local closeButton = script.Parent:WaitForChild("CloseButton", 5)

if not (extractButton and traitsLabel and closeButton) then
	warn("SequencerGUI elements missing")
	return
end

-- Lockout to prevent click-through
local guiLockout = false
local LOCKOUT_TIME = 0.5

-- Detect GUI opening
script.Parent.Parent:GetPropertyChangedSignal("Enabled"):Connect(function()
	if script.Parent.Parent.Enabled then
		guiLockout = true
		print("SequencerGUI opened, lockout enabled")
		task.wait(LOCKOUT_TIME)
		guiLockout = false
		print("SequencerGUI lockout disabled")
	end
end)

extractButton.MouseButton1Click:Connect(function()
	if not guiLockout then
		print("Extract button clicked")
		local seed = backpack:FindFirstChild("Seed") or (character and character:FindFirstChild("Seed"))
		if seed then
			print("Seed found in " .. (seed.Parent == backpack and "Backpack" or "Character"))
			seed:Destroy()
			local colors = {"Red", "Blue", "Green"}
			local sizes = {"Small", "Medium", "Large"}
			local color = colors[math.random(1, #colors)]
			local size = sizes[math.random(1, #sizes)]
			traitsLabel.Text = "Color: " .. color .. ", Size: " .. size
			traitsLabel.Visible = true
			print("Traits displayed: " .. traitsLabel.Text)
			local AddSampleEvent = ReplicatedStorage:WaitForChild("AddSampleEvent")
			AddSampleEvent:FireServer()
			print("Fired AddSampleEvent")
			wait(5)
			traitsLabel.Visible = false
		else
			print("No Seed found in Backpack or Character")
			traitsLabel.Text = "No seeds to extract"
			traitsLabel.Visible = true
			print("No seeds message shown")
			wait(2)
			traitsLabel.Visible = false
		end
	else
		print("Extract button click ignored (GUI lockout)")
	end
end)

closeButton.MouseButton1Click:Connect(function()
	if not guiLockout then
		print("Close button clicked")
		script.Parent.Parent.Enabled = false
	else
		print("Close button click ignored (GUI lockout)")
	end
end)