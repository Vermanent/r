-- @ScriptType: LocalScript
-- StarterPlayerScripts/HotbarUI.lua (LocalScript)
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local HotbarModule = require(ReplicatedStorage:WaitForChild("HotbarModule"))

-- GUI config pulled from module values
local BASE_SIZE    = 48
local SPACING      = 8
local SLOT_COUNT   = HotbarModule.SLOT_COUNT
local SLOT_COLOR   = Color3.fromRGB(20,20,20)
local SLOT_ALPHA   = 0.6
local BORDER_CLR   = Color3.fromRGB(180,180,180)
local BORDER_ALPHA = 0.4
local ACTIVE_TINT  = Color3.fromRGB(40,40,40)
local ACTIVE_ALPHA = 0.3
local EXPAND_SCALE = 1.15
local TWEEN_TIME   = 0.2

-- Build ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FloatingHotbar"
screenGui.Parent = playerGui

-- Container
local container = Instance.new("Frame")
container.AnchorPoint = Vector2.new(0.5, 1)
container.Position    = UDim2.new(0.5, 0, 1, -8)
container.Size        = UDim2.new(0, SLOT_COUNT*BASE_SIZE + (SLOT_COUNT-1)*SPACING, 0, BASE_SIZE)
container.BackgroundTransparency = 1
container.Parent = screenGui

local layout = Instance.new("UIListLayout", container)
layout.FillDirection       = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Padding             = UDim.new(0, SPACING)

-- Create slots dynamically
local slots = {}
for i = 1, SLOT_COUNT do
	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(0, BASE_SIZE, 0, BASE_SIZE)
	holder.BackgroundTransparency = 1
	holder.Parent = container

	local btn = Instance.new("ImageButton")
	btn.Size = UDim2.new(0, BASE_SIZE, 0, BASE_SIZE)
	btn.AnchorPoint = Vector2.new(0.5, 0.5)
	btn.Position    = UDim2.new(0.5, 0, 0.5, 0)
	btn.BackgroundColor3 = SLOT_COLOR
	btn.BackgroundTransparency = 1 - SLOT_ALPHA
	btn.AutoButtonColor = false
	btn.ImageTransparency = 1
	btn.Parent = holder

	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	local stroke = Instance.new("UIStroke", btn)
	stroke.Color = BORDER_CLR
	stroke.Transparency = 1 - BORDER_ALPHA

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0.8, 0, 0.8, 0)
	icon.Position = UDim2.new(0.1, 0, 0.1, 0)
	icon.BackgroundTransparency = 1
	icon.ImageTransparency = 1
	icon.Parent = btn

	local count = Instance.new("TextLabel")
	count.Name = "Count"
	count.Size = UDim2.new(0, 24, 0, 14)
	count.Position = UDim2.new(1, -2, 1, -2)
	count.AnchorPoint = Vector2.new(1, 1)
	count.BackgroundTransparency = 1
	count.Font = Enum.Font.SourceSansSemibold
	count.TextSize = 12
	count.TextColor3 = Color3.new(1, 1, 1)
	count.TextStrokeColor3 = Color3.new(0,0,0)
	count.TextStrokeTransparency = 0.7
	count.TextXAlignment = Enum.TextXAlignment.Right
	count.Parent = btn

	-- Tooltip
	local tooltip = Instance.new("TextLabel")
	tooltip.Name = "Tooltip"
	tooltip.AnchorPoint = Vector2.new(0.5, 0)
	tooltip.Position = UDim2.new(0.5, 0, 0, -20)
	tooltip.Size = UDim2.new(0, BASE_SIZE+20, 0, 20)
	tooltip.BackgroundTransparency = 1
	tooltip.TextColor3 = Color3.new(1,1,1)
	tooltip.Font = Enum.Font.SourceSansSemibold
	tooltip.TextSize = 14
	tooltip.Text = ""
	tooltip.Visible = false
	tooltip.Parent = holder

	btn.MouseEnter:Connect(function()
		local data = HotbarModule.inventory[i]
		if data then
			local def = HotbarModule.ItemDefinitions[data.Type]
			tooltip.Text = def.Title .. ": " .. def.Description
			tooltip.Visible = true
			tooltip.TextTransparency = 1
			TweenService:Create(tooltip, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
		end
	end)
	btn.MouseLeave:Connect(function()
		local hideTween = TweenService:Create(tooltip, TweenInfo.new(0.2), {TextTransparency = 1})
		hideTween.Completed:Connect(function() tooltip.Visible = false end)
		hideTween:Play()
	end)

	btn.MouseButton1Click:Connect(function()
		HotbarModule.setActive(i)
	end)

	local expandTween = TweenService:Create(btn, TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Sine), {Size = UDim2.new(0, BASE_SIZE*EXPAND_SCALE, 0, BASE_SIZE*EXPAND_SCALE)})
	local contractTween = TweenService:Create(btn, TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Sine), {Size = UDim2.new(0, BASE_SIZE, 0, BASE_SIZE)})
	slots[i] = {btn=btn, icon=icon, count=count, expand=expandTween, contract=contractTween}
end

-- Keyboard selection
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.Keyboard and input.UserInputState == Enum.UserInputState.Begin then
		local kc = input.KeyCode
		if kc.Value >= Enum.KeyCode.One.Value and kc.Value <= Enum.KeyCode.Nine.Value then
			HotbarModule.setActive(kc.Value - Enum.KeyCode.One.Value + 1)
		end
	end
end)

HotbarModule.refreshUI()
