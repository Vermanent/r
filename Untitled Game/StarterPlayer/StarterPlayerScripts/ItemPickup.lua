-- @ScriptType: LocalScript
-- ===== StarterPlayerScripts/ItemPickup.lua =====
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS               = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local char   = player.Character or player.CharacterAdded:Wait()
local mouse  = player:GetMouse()
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Hotbar = require(ReplicatedStorage:WaitForChild("HotbarModule"))

-- reference the world-items container
local worldFolder = workspace:WaitForChild("WorldItems")

-- Debug function to help identify issues
local function debugPrint(msg, ...)
	print("📦 PICKUP: " .. msg:format(...))
end

-- ensure a model has a PrimaryPart (picks first BasePart if none set)
local function ensurePrimaryPart(model)
	if model.PrimaryPart then return true end
	local part = model:FindFirstChild("Part")
	if not part then
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				part = d
				break
			end
		end
	end
	if part then
		model.PrimaryPart = part
		debugPrint("Set PrimaryPart for %s to %s", model.Name, part.Name)
		return true
	else
		warn("No BasePart in model:", model:GetFullName())
		return false
	end
end

-- wire up visuals & click-hover on any new world item
local function setupWorldItem(model)
	if not ensurePrimaryPart(model) then return end
	local part = model.PrimaryPart

	debugPrint("Setting up world item: %s", model:GetFullName())

	-- highlight
	if not part:FindFirstChildOfClass("Highlight") then
		local hl = Instance.new("Highlight", part)
		hl.Adornee = part
		hl.Enabled = false
	end

	-- billboard GUI
	if not part:FindFirstChildOfClass("BillboardGui") then
		local gui = Instance.new("BillboardGui", part)
		gui.Adornee     = part
		gui.Size        = UDim2.new(0,150,0,50)
		gui.StudsOffset = Vector3.new(0,2,0)
		gui.AlwaysOnTop = true

		local lbl = Instance.new("TextLabel", gui)
		lbl.Size               = UDim2.new(1,0,1,0)
		lbl.BackgroundTransparency = 1
		lbl.TextColor3         = Color3.new(1,1,1)
		lbl.Font               = Enum.Font.SourceSansSemibold
		lbl.TextSize           = 14

		local data = Config.Items[model.Name]
		lbl.Text = (data and data.Title.."\n"..data.Description) or model.Name
	end

	-- hover detector
	local cd = part:FindFirstChildOfClass("ClickDetector")
		or Instance.new("ClickDetector", part)
	cd.MouseHoverEnter:Connect(function()
		part.Highlight.Enabled = true
		part:FindFirstChildOfClass("BillboardGui").Enabled = true
	end)
	cd.MouseHoverLeave:Connect(function()
		part.Highlight.Enabled = false
		part:FindFirstChildOfClass("BillboardGui").Enabled = false
	end)

	-- Make sure the model has the WorldItem tag
	if not CollectionService:HasTag(model, "WorldItem") then
		debugPrint("Adding WorldItem tag to %s", model.Name)
		CollectionService:AddTag(model, "WorldItem")
	else
		debugPrint("Model already has WorldItem tag")
	end

	-- Make the object not anchored for physics interactions
	for _, child in pairs(model:GetDescendants()) do
		if child:IsA("BasePart") then
			child.Anchored = false
		end
	end

	-- Add CanCollide and Cancel collisions with character to prevent physics issues
	model.PrimaryPart.CanCollide = true
	model.PrimaryPart.CanTouch = true
	model.PrimaryPart.CanQuery = true
end

-- initial setup for any existing items
for _, mdl in ipairs(worldFolder:GetChildren()) do
	setupWorldItem(mdl)
end

-- whenever you drop new clones into the folder
worldFolder.ChildAdded:Connect(function(model)
	debugPrint("New model added to WorldItems: %s", model.Name)
	setupWorldItem(model)
end)

-- handle F = pickup, G = drop
-- Handle F = pickup, G = drop
UIS.InputBegan:Connect(function(input, gp)
	if gp then return end

	-- —— PICKUP (F) ——
	if input.KeyCode == Enum.KeyCode.F then
		local tgt = mouse.Target
		if not tgt then return end

		local model = tgt:FindFirstAncestorOfClass("Model")
		if model and model.Parent == worldFolder and model.PrimaryPart then
			local dist = (model.PrimaryPart.Position - char.PrimaryPart.Position).Magnitude
			local range = Config.PickupRange or Config.MaxDragDistance or 10
			if dist <= range then
				debugPrint("Picking up %s", model.Name)
				Hotbar.addItem(model.Name, 1)
				model:Destroy()
			end
		end

		-- —— DROP (G) ——
	elseif input.KeyCode == Enum.KeyCode.G then
		local idx = Hotbar.activeIndex
		if idx and Hotbar.inventory[idx] then
			local item = Hotbar.inventory[idx]
			-- Tell the server to drop the item
			ReplicatedStorage:WaitForChild("DropItemEvent"):FireServer(item.Type)
			Hotbar.removeItem()
		end
	end
end)