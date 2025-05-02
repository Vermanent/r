-- @ScriptType: ModuleScript
-------------------------------------------------------
-- Modules/Harvest.lua (ModuleScript)
-------------------------------------------------------
local Inventory = require(script.Parent.InventoryManager)
local Harvest = {}

function Harvest:Collect(player, cropIndex)
	local data = Inventory:Get(player)
	local crop = data.crops[cropIndex]
	if not crop then return nil end
	Inventory:Remove(player, "crops", cropIndex)
	return crop
end

return Harvest