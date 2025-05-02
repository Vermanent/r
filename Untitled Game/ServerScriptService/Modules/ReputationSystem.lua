-- @ScriptType: ModuleScript
-------------------------------------------------------
-- Modules/ReputationSystem.lua (ModuleScript)
-------------------------------------------------------
local Reputation = {}

function Reputation:Initialize(player)
	player:SetAttribute("Reputation", 0)
end

function Reputation:Add(player, amt)
	local current = player:GetAttribute("Reputation") or 0
	player:SetAttribute("Reputation", current + amt)
end

return Reputation