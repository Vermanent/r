-- @ScriptType: Script
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local worldFolder = workspace:WaitForChild("WorldItems")

RS:WaitForChild("DropItemEvent").OnServerEvent:Connect(function(player, itemType)
	local template = RS:FindFirstChild(itemType)
	if template and template:IsA("Model") then
		local clone = template:Clone()
		-- Ensure PrimaryPart
		if not clone.PrimaryPart then
			for _, d in ipairs(clone:GetDescendants()) do
				if d:IsA("BasePart") then
					clone.PrimaryPart = d
					break
				end
			end
		end
		if clone.PrimaryPart then
			-- Position in front of player
			local char = player.Character
			if char and char.PrimaryPart then
				clone:SetPrimaryPartCFrame(char.PrimaryPart.CFrame * CFrame.new(0, 0, -3))
			end
			-- Make unanchored
			for _, child in pairs(clone:GetDescendants()) do
				if child:IsA("BasePart") then
					child.Anchored = false
				end
			end
			-- Add tag on the server
			CollectionService:AddTag(clone, "WorldItem")
			-- Parent to WorldItems
			clone.Parent = worldFolder
		end
	end
end)