-- @ScriptType: LocalScript
-- @ScriptType: LocalScript
-- ===== StarterPlayerScripts/EquipmentHandler.lua =====
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local HotbarModule = require(ReplicatedStorage:WaitForChild("HotbarModule"))

-- Keep track of player character
player.CharacterAdded:Connect(function(char)
	character = char
end)

-- Keep track of currently equipped item
local equippedItem = nil
local equippedItemType = nil

-- Create item models for each item type
local itemModels = {}

-- Debug function
local function debugPrint(msg, ...)
	print("🔧 EQUIP: " .. msg:format(...))
end

-- Function to equip item visually
local function equipItem(itemType)
	debugPrint("Equipping item: %s", itemType or "NONE")

	-- Unequip previous item if exists
	if equippedItem then
		equippedItem:Destroy()
		equippedItem = nil
		equippedItemType = nil
	end

	if not itemType then return end

	local def = HotbarModule.ItemDefinitions[itemType]
	if not def then return end

	-- Create or clone the item model
	local itemModel
	if itemModels[itemType] then
		-- Clone existing model
		itemModel = itemModels[itemType]:Clone()
	else
		-- Create new model based on item type
		itemModel = Instance.new("Model")
		itemModel.Name = itemType .. "Model"

		-- Create a basic part for now - could be replaced with custom models per item
		local part = Instance.new("Part")
		part.Name = "Handle"
		part.Size = Vector3.new(1, 0.5, 2) -- Adjust size based on item type
		part.Anchored = false
		part.CanCollide = false
		part.Material = Enum.Material.SmoothPlastic

		-- Customize based on item type
		if itemType:find("Sword") or itemType:find("Tool") then
			part.Size = Vector3.new(0.2, 0.2, 2)
		elseif itemType:find("Shield") then
			part.Size = Vector3.new(2, 2, 0.3)
		elseif itemType:find("Food") or itemType:find("Potion") then
			part.Size = Vector3.new(0.5, 0.5, 0.5)
			part.Shape = Enum.PartType.Ball
		end

		-- Color based on icon color or use a default
		local color = Color3.fromRGB(200, 200, 200)
		part.Color = color

		-- Create a texture label to show item icon
		local decal = Instance.new("Decal")
		decal.Texture = def.Icon
		decal.Face = Enum.NormalId.Front
		decal.Parent = part

		part.Parent = itemModel
		itemModel.PrimaryPart = part

		-- Cache for future use
		itemModels[itemType] = itemModel:Clone()
	end

	-- Weld to right hand
	local rightHand = character:FindFirstChild("RightHand") or 
		character:FindFirstChild("Right Hand") or
		character:FindFirstChild("RightLowerArm")

	if not rightHand then
		-- Try to find in humanoid description if R15
		if character:FindFirstChildOfClass("Humanoid").RigType == Enum.HumanoidRigType.R15 then
			rightHand = character:FindFirstChild("RightHand") or character:FindFirstChild("RightLowerArm")
		else
			-- R6 fallback
			rightHand = character:FindFirstChild("Right Arm")
		end
	end

	if rightHand then
		-- Position the item in the character's hand
		itemModel.PrimaryPart.CFrame = rightHand.CFrame * CFrame.new(0, 0, -1) * CFrame.Angles(0, math.rad(90), 0)

		-- Create a weld to attach the item to the hand
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = rightHand
		weld.Part1 = itemModel.PrimaryPart
		weld.Parent = itemModel.PrimaryPart

		itemModel.Parent = character
		equippedItem = itemModel
		equippedItemType = itemType
	else
		warn("Could not find right hand to equip item")
		itemModel:Destroy()
	end
end

-- Function to use the equipped item (customize based on item type)
local function useItem()
	if not equippedItemType then return end

	local def = HotbarModule.ItemDefinitions[equippedItemType]
	if not def then return end

	-- Create a basic use animation
	local char = character
	local humanoid = char:FindFirstChildOfClass("Humanoid")

	if humanoid then
		-- Different use types based on item
		if equippedItemType:find("Sword") or equippedItemType:find("Tool") then
			-- Sword swing animation
			ReplicatedStorage:WaitForChild("UseItemEvent"):FireServer(equippedItemType, "swing")

			-- Local animation for feedback
			local animTrack = humanoid:LoadAnimation(ReplicatedStorage:WaitForChild("Animations"):WaitForChild("SwordSwing"))
			if animTrack then
				animTrack:Play()
			end

		elseif equippedItemType:find("Food") or equippedItemType:find("Potion") then
			-- Consume animation
			ReplicatedStorage:WaitForChild("UseItemEvent"):FireServer(equippedItemType, "consume")

			-- Remove one of the item
			HotbarModule.consumeItem()
		else
			-- Generic use
			ReplicatedStorage:WaitForChild("UseItemEvent"):FireServer(equippedItemType, "use")
		end
	end
end

-- Monitor hotbar selection changes
local function updateEquipmentBasedOnHotbar()
	-- Get current item type
	local currentItem = nil
	if HotbarModule.activeIndex then
		local slot = HotbarModule.inventory[HotbarModule.activeIndex]
		if slot then
			currentItem = slot.Type
		end
	end

	-- Equip or unequip based on selection
	equipItem(currentItem)
end

-- Override the HotbarModule's setActive method to handle equipment
local originalSetActive = HotbarModule.setActive
HotbarModule.setActive = function(idx)
	originalSetActive(idx)
	updateEquipmentBasedOnHotbar()
end

-- Override the removeItem to handle unequipping when dropping
local originalRemoveItem = HotbarModule.removeItem
HotbarModule.removeItem = function()
	local idx, slot = originalRemoveItem()
	updateEquipmentBasedOnHotbar()
	return idx, slot
end

-- Add a function to consume the active item (for consumables)
function HotbarModule.consumeItem()
	local idx = HotbarModule.activeIndex
	if not idx then return end

	local slot = HotbarModule.inventory[idx]
	if not slot then return end

	-- Remove one from count
	slot.Count = slot.Count - 1
	if slot.Count <= 0 then
		HotbarModule.inventory[idx] = nil
	end

	HotbarModule.refreshUI()
	updateEquipmentBasedOnHotbar()
end

-- Listen for item use input (mouse click)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 and equippedItemType then
		useItem()
	end
end)

-- Re-equip item when character respawns
player.CharacterAdded:Connect(function(char)
	character = char
	wait(1) -- Wait for character to be fully loaded

	-- Re-equip the active item if exists
	updateEquipmentBasedOnHotbar()
end)

-- Initial equip if something is selected
updateEquipmentBasedOnHotbar()