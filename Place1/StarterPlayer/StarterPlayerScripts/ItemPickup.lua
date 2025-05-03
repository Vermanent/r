-- @ScriptType: LocalScript
-- ========== StarterPlayerScripts/ItemPickup.lua ==========
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local mouse = player:GetMouse()
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local HotbarModule = require(ReplicatedStorage:WaitForChild("HotbarModule"))

-- Create highlight + label on a world item
local function setupWorldItem(model)
    if not model:IsA("Model") or not model.PrimaryPart then return end
    if model.PrimaryPart:FindFirstChild("Highlight") then return end

    -- Create highlight effect
    local highlight = Instance.new("Highlight")
    highlight.Adornee = model.PrimaryPart
    highlight.Enabled = false
    highlight.Parent = model.PrimaryPart

    -- Create billboard label to show item title and description
    local gui = Instance.new("BillboardGui")
    gui.Adornee = model.PrimaryPart
    gui.Size = UDim2.new(0, 150, 0, 50)
    gui.StudsOffset = Vector3.new(0, 2, 0)
    gui.AlwaysOnTop = true
    gui.Enabled = false
    gui.Parent = model.PrimaryPart

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.SourceSansSemibold
    label.TextSize = 14
    label.Parent = gui

    -- Get the item data from Config.lua based on model name
    local itemData = Config.Items[model.Name]
    if itemData then
        label.Text = itemData.Title .. "\n" .. itemData.Description
    else
        label.Text = model.Name
    end

    -- Show highlight and label when mouse hovers
    local click = Instance.new("ClickDetector", model.PrimaryPart)
    click.MouseHoverEnter:Connect(function()
        highlight.Enabled = true
        gui.Enabled = true
    end)
    click.MouseHoverLeave:Connect(function()
        highlight.Enabled = false
        gui.Enabled = false
    end)
end

-- Tag all existing items in workspace
for _, model in ipairs(workspace:GetChildren()) do
    if model:IsA("Model") and model.PrimaryPart then
        CollectionService:AddTag(model, "WorldItem")
    end
end

-- Listen for future tagged items
CollectionService:GetInstanceAddedSignal("WorldItem"):Connect(setupWorldItem)

-- Setup visuals for already-tagged ones
for _, model in ipairs(CollectionService:GetTagged("WorldItem")) do
    setupWorldItem(model)
end

-- Handle F (pickup) and G (drop)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.F then
        local target = mouse.Target
        if not target then return end

        local model = target:FindFirstAncestorOfClass("Model")
        if model and CollectionService:HasTag(model, "WorldItem") then
            local itemName = model.Name
            local dist = (model.PrimaryPart.Position - char.PrimaryPart.Position).Magnitude
            if dist <= 10 then
                HotbarModule.addItem(itemName, 1)
                model:Destroy()
            end
        end

    elseif input.KeyCode == Enum.KeyCode.G then
        local index = HotbarModule.activeIndex
        if index and HotbarModule.inventory[index] then
            local item = HotbarModule.inventory[index]
            local template = ReplicatedStorage:FindFirstChild(item.Type)
            local root = char.PrimaryPart

            if template and root then
                local clone = template:Clone()
                clone:SetPrimaryPartCFrame(root.CFrame * CFrame.new(0, 0, -3))
                clone.Parent = workspace

                CollectionService:AddTag(clone, "WorldItem")
                HotbarModule.removeItem()
            end
        end
    end
end)


