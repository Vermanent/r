-- @ScriptType: ModuleScript
-------------------------------------------------------
-- Modules/Cultivation.lua (ModuleScript)
-------------------------------------------------------
local Inventory = require(script.Parent.InventoryManager)
local Cultivation = {}

function Cultivation:Plant(player, traitIndex)
	local data = Inventory:Get(player)
	local trait = data.traits[traitIndex]
	if not trait then return nil end
	local crop = {name = trait.source .. "Crop", start = os.time()}
	Inventory:Add(player, "crops", crop)
	return crop
end

return Cultivation