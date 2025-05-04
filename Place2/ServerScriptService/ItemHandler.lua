-- @ScriptType: Script
-- @ScriptType: Script
-- ========== ServerScriptService/ItemHandler.lua ==========
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Create necessary RemoteEvents if they don't exist
local useItemEvent = ReplicatedStorage:FindFirstChild("UseItemEvent")
if not useItemEvent then
	useItemEvent = Instance.new("RemoteEvent")
	useItemEvent.Name = "UseItemEvent"
	useItemEvent.Parent = ReplicatedStorage
end

local dropItemEvent = ReplicatedStorage:FindFirstChild("DropItemEvent")
if not dropItemEvent then
	dropItemEvent = Instance.new("RemoteEvent")
	dropItemEvent.Name = "DropItemEvent"
	dropItemEvent.Parent = ReplicatedStorage
end

-- Debug function
local function debugPrint(msg, ...)
	print("📦 ITEM HANDLER: " .. msg:format(...))
end

-- Handle item drop requests
dropItemEvent.OnServerEvent:Connect(function(player, itemType)
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then 
		debugPrint("Character or HumanoidRootPart not found")
		return 
	end

	-- Create the item in the world
	local config = require(ReplicatedStorage:WaitForChild("Config"))
	local itemDef = config.Items[itemType]

	if not itemDef then 
		warn("Unknown item type:", itemType)
		return 
	end

	debugPrint("Creating dropped item: %s", itemType)

	-- Create new item model
	local model = Instance.new("Model")
	model.Name = itemType

	-- Create the item part
	local part = Instance.new("Part")
	part.Name = "Part" -- Standard name for PrimaryPart detection
	part.Size = Vector3.new(1, 1, 1)
	part.Anchored = true
	part.CanCollide = true

	-- Position slightly in front of the player
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local forwardVector = rootPart.CFrame.LookVector
	local dropPosition = rootPart.Position + forwardVector * 5
	part.Position = dropPosition

	-- Add visuals based on item type
	if itemType:find("Sword") or itemType:find("Tool") then
		part.Size = Vector3.new(0.2, 0.2, 2)
	elseif itemType:find("Shield") then
		part.Size = Vector3.new(2, 2, 0.3)
	elseif itemType:find("Food") or itemType:find("Potion") then
		part.Size = Vector3.new(0.5, 0.5, 0.5)
		part.Shape = Enum.PartType.Ball
	end

	-- Set the part color to something visible
	part.Color = Color3.fromRGB(200, 200, 200)

	-- Add a texture to show what the item is
	local decal = Instance.new("Decal", part)
	decal.Texture = itemDef.Icon
	decal.Face = Enum.NormalId.Front

	-- Add necessary components for pickup system
	local clickDetector = Instance.new("ClickDetector", part)
	clickDetector.MaxActivationDistance = 10

	-- Setup the model
	part.Parent = model
	model.PrimaryPart = part

	-- Set non-anchored after a brief delay to prevent physics issues
	task.spawn(function()
		task.wait(0.2)
		if model and model.Parent and part and part.Parent then
			part.Anchored = false
		end
	end)

	-- Add to world items
	local worldItems = workspace:FindFirstChild("WorldItems")
	if not worldItems then
		worldItems = Instance.new("Folder")
		worldItems.Name = "WorldItems"
		worldItems.Parent = workspace
	end
	model.Parent = worldItems

	debugPrint("Item %s dropped at %s", itemType, tostring(dropPosition))
end)

-- Handle item use requests
useItemEvent.OnServerEvent:Connect(function(player, itemType, useType)
	local character = player.Character
	if not character or not character:FindFirstChild("Humanoid") then return end

	debugPrint("Item use request: %s, type: %s", itemType, useType)

	-- Handle different use types
	if useType == "swing" then
		-- Create damage area or hitbox
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			local hitbox = Instance.new("Part")
			hitbox.Size = Vector3.new(5, 5, 5)
			hitbox.CFrame = rootPart.CFrame * CFrame.new(0, 0, -3)
			hitbox.Anchored = true
			hitbox.CanCollide = false
			hitbox.Transparency = 1
			hitbox.Parent = workspace

			-- Check for damage to NPCs/players
			local hits = workspace:GetPartsInPart(hitbox)
			for _, part in pairs(hits) do
				local hitChar = part:FindFirstAncestorOfClass("Model")
				if hitChar and hitChar ~= character and hitChar:FindFirstChildOfClass("Humanoid") then
					-- Apply damage
					local humanoid = hitChar:FindFirstChildOfClass("Humanoid")
					humanoid:TakeDamage(10) -- Adjust damage based on item
					debugPrint("Damaged character: %s", hitChar.Name)
				end
			end

			-- Remove hitbox after a short time
			game:GetService("Debris"):AddItem(hitbox, 0.1)
		end

	elseif useType == "consume" then
		-- Heal the player or apply effect
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = math.min(humanoid.Health + 25, humanoid.MaxHealth)
			debugPrint("Healed player: %s", player.Name)
			-- Could add other effects like speed boost, etc.
		end
	end
end)