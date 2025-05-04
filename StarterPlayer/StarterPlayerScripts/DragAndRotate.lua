-- ===== StarterPlayerScripts/DragAndRotate.lua =====
local RS         = game:GetService("ReplicatedStorage")
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local player    = Players.LocalPlayer
local camera    = workspace.CurrentCamera
local mouse     = player:GetMouse()
local dragEvent = RS:WaitForChild("DragEvent")

-- reference your folder
local worldFolder = workspace:WaitForChild("WorldItems")

-- dragging state
local dragging, dragPart, dragDistance = false, nil, 0
local rotating, rotation                = false, Vector3.new()
local keyState = { W=false, A=false, S=false, D=false, Q=false, E=false }

-- helper to disable/enable walk during rotation
local function setMovementEnabled(on)
	local controls = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")).controls
	if on then controls:Enable() else controls:Disable() end
end

-- left-click to start drag
mouse.Button1Down:Connect(function()
	local target = mouse.Target
	if not target then return end

	-- climb up to the model
	local model = target:FindFirstAncestorOfClass("Model")
	if model 
		and model.Parent == worldFolder 
		and model.PrimaryPart then

		dragging     = true
		dragPart     = model.PrimaryPart
		dragDistance = (mouse.Hit.Position - camera.CFrame.Position).Magnitude
		rotation     = dragPart.Orientation
		rotating     = false
		setMovementEnabled(true)

		-- notify server you started dragging
		dragEvent:FireServer("start", dragPart, nil)
	end
end)

-- capture Shift + rotation keys
UIS.InputBegan:Connect(function(input, gp)
	if gp or not dragging then return end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		rotating = true
		setMovementEnabled(false)
	end
	if rotating then
		if     input.KeyCode == Enum.KeyCode.W then keyState.W = true
		elseif input.KeyCode == Enum.KeyCode.S then keyState.S = true
		elseif input.KeyCode == Enum.KeyCode.A then keyState.A = true
		elseif input.KeyCode == Enum.KeyCode.D then keyState.D = true
		elseif input.KeyCode == Enum.KeyCode.Q then keyState.Q = true
		elseif input.KeyCode == Enum.KeyCode.E then keyState.E = true end
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
		dragging = false
		dragEvent:FireServer("end")
		dragPart = nil
		setMovementEnabled(true)
	end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		rotating = false
		setMovementEnabled(true)
		for k in pairs(keyState) do keyState[k] = false end
	end
	-- reset any rotation key
	if     input.KeyCode == Enum.KeyCode.W then keyState.W = false
	elseif input.KeyCode == Enum.KeyCode.S then keyState.S = false
	elseif input.KeyCode == Enum.KeyCode.A then keyState.A = false
	elseif input.KeyCode == Enum.KeyCode.D then keyState.D = false
	elseif input.KeyCode == Enum.KeyCode.Q then keyState.Q = false
	elseif input.KeyCode == Enum.KeyCode.E then keyState.E = false end
end)

-- every frame update position + rotation
RunService.RenderStepped:Connect(function()
	if not dragging or not dragPart then return end

	-- raycast from camera through mouse
	local ray    = camera:ScreenPointToRay(mouse.X, mouse.Y)
	local newPos = ray.Origin + ray.Direction * dragDistance

	-- enforce max distance from player
	local maxDist = require(RS.Config).MaxDragDistance or 20
	local hrpPos  = player.Character.HumanoidRootPart.Position
	if (hrpPos - dragPart.Position).Magnitude > maxDist then
		dragging = false
		dragPart = nil
		dragEvent:FireServer("end")
		setMovementEnabled(true)
		return
	end

	-- apply any rotation keys
	if rotating then
		if keyState.W then rotation += Vector3.new(-1,0,0) end
		if keyState.S then rotation += Vector3.new( 1,0,0) end
		if keyState.A then rotation += Vector3.new(0,-1,0) end
		if keyState.D then rotation += Vector3.new(0, 1,0) end
		if keyState.Q then rotation += Vector3.new(0,0,-1) end
		if keyState.E then rotation += Vector3.new(0,0, 1) end
	end

	-- send updated transform to server
	dragEvent:FireServer("update", dragPart, newPos, rotation)
end)
