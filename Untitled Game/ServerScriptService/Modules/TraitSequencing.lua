-- @ScriptType: ModuleScript
-------------------------------------------------------
-- Modules/TraitSequencing.lua (ModuleScript)
-------------------------------------------------------
local Inventory = require(script.Parent.InventoryManager)
local TraitSequencing = {}

function TraitSequencing:Sequence(player, seedIndex)
	local data = Inventory:Get(player)
	local seed = data.seeds[seedIndex]
	if not seed then return nil end
	local trait = {source = seed.name, trait = "Trait_" .. seed.name}
	Inventory:Add(player, "traits", trait)
	return trait
end

return TraitSequencing