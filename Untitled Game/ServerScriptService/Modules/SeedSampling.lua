-- @ScriptType: ModuleScript
-------------------------------------------------------
-- Modules/SeedSampling.lua (ModuleScript)
-------------------------------------------------------
local Inventory = require(script.Parent.InventoryManager)
local SeedSampling = {}

function SeedSampling:CollectSeed(player, point)
	if not point or not point:IsA("BasePart") then return false end
	local seed = {name = point.Name, time = os.time()}
	Inventory:Add(player, "seeds", seed)
	return seed
end

return SeedSampling