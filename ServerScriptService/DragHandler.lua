-- ========== ServerScriptService/DragHandler.lua ==========

local RS = game:GetService("ReplicatedStorage")
local CS = game:GetService("CollectionService")
local dragEvent = RS:WaitForChild("DragEvent")

-- Store per-player active drags
local activeDrags = {}

dragEvent.OnServerEvent:Connect(function(player, action, part, position, rotation)
	if action == "start" then
		if part then
			local model = part:FindFirstAncestorOfClass("Model")
			if model and CS:HasTag(model, "WorldItem") then
				part:SetNetworkOwner(player)
				local bp = Instance.new("BodyPosition")
				bp.Name = "_DragBP"
				bp.MaxForce = Vector3.new(1e5,1e5,1e5)
				bp.P = 3000; bp.D = 100
				bp.Position = part.Position
				bp.Parent = part

				local bg = Instance.new("BodyGyro")
				bg.Name = "_DragBG"
				bg.MaxTorque = Vector3.new(1e5,1e5,1e5)
				bg.P = 3000; bg.D = 100
				bg.CFrame = part.CFrame
				bg.Parent = part

				activeDrags[player] = {
					bp = bp,
					bg = bg,
					baseRotation = part.CFrame - part.CFrame.Position
				}
			end
		end

	elseif action == "update" then
		local data = activeDrags[player]
		if data then
			if position then
				data.bp.Position = position
			end
			if rotation then
				local rot = CFrame.Angles(math.rad(rotation.x), math.rad(rotation.y), math.rad(rotation.z))
				data.bg.CFrame = CFrame.new(data.bp.Position) * rot
			end
		end
	elseif action == "end" then
		local data = activeDrags[player]
		if data then
			data.bp:Destroy()
			data.bg:Destroy()
			activeDrags[player] = nil
		end
	end
end)