-- @ScriptType: ModuleScript
-------------------------------------------------------
-- Modules/Packaging.lua (ModuleScript)
-------------------------------------------------------
local Inventory = require(script.Parent.InventoryManager)
local Packaging = {}

function Packaging:Package(player, crop)
	if not crop then return nil end
	local pkg = {name = crop.name .. "Pack"}
	Inventory:Add(player, "packages", pkg)
	return pkg
end

return Packaging