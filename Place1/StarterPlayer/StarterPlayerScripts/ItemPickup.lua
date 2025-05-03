-- @ScriptType: LocalScript
-- StarterPlayerScripts/ItemPickup.lua (LocalScript)
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local char   = player.Character or player.CharacterAdded:Wait()
local mouse = player:GetMouse()
local HotbarModule = require(ReplicatedStorage:WaitForChild("HotbarModule"))

-- Tag world items and setup highlight & billboard
local function setupWorldItem(model)
	if not model.PrimaryPart then return end
	local hl = Instance.new("Highlight", model)
	hl.Adornee = model.PrimaryPart; hl.Enabled = false
	local def = HotbarModule.ItemDefinitions[model.Name]
	if def then
		local gui = Instance.new("BillboardGui", model.PrimaryPart)
		gui.Adornee = model.PrimaryPart; gui.AlwaysOnTop=true; gui.Size=UDim2.new(0,150,0,50); gui.StudsOffset=Vector3.new(0,2,0); gui.Enabled=false
		local label = Instance.new("TextLabel", gui)
		label.Size=UDim2.new(1,0,1,0); label.BackgroundTransparency=1; label.Text=def.Title.."\n"..def.Description
		label.TextColor3=Color3.new(1,1,1); label.Font=Enum.Font.SourceSansSemibold; label.TextSize=14
		local click = Instance.new("ClickDetector", model.PrimaryPart)
		click.MouseHoverEnter:Connect(function() hl.Enabled=true; gui.Enabled=true end)
		click.MouseHoverLeave:Connect(function() hl.Enabled=false; gui.Enabled=false end)
	end
end
CollectionService:GetInstanceAddedSignal("WorldItem"):Connect(setupWorldItem)
for _,m in ipairs(workspace:GetChildren()) do
	if m.Name=="Placeholder" then
		CollectionService:AddTag(m,"WorldItem")
	end
end

-- Pickup (F) and drop (G)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.F and input.UserInputState == Enum.UserInputState.Begin then
		local target = mouse.Target
		if target then
			local model = target:FindFirstAncestorOfClass("Model")
			if model and CollectionService:HasTag(model,"WorldItem") then
				if (model.PrimaryPart.Position - char.PrimaryPart.Position).Magnitude <= 10 then
					HotbarModule.addItem(model.Name,1)
					model:Destroy()
				end
			end
		end
	elseif input.KeyCode == Enum.KeyCode.G and input.UserInputState == Enum.UserInputState.Begin then
		local idx = HotbarModule.activeIndex
		if idx and HotbarModule.inventory[idx] then
			local root = char.PrimaryPart
			local template = ReplicatedStorage:FindFirstChild(HotbarModule.inventory[idx].Type)
			if root and template then
				local clone = template:Clone()
				clone:SetPrimaryPartCFrame(root.CFrame * CFrame.new(0,0,-3))
				clone.Parent = workspace
				CollectionService:AddTag(clone,"WorldItem")
				HotbarModule.removeItem()
			end
		end
	end
end)
