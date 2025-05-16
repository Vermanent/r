-- @ScriptType: ModuleScript
-- ========== ReplicatedStorage/Config.lua ==========
local Config = {}

-- Number of hotbar slots; change this to add or remove slots
Config.SlotCount = 9

-- Define each item type here; new items can be added by extending this table
-- Fields: Icon (image asset), Title (string), Description (string)
Config.Items = {
	Placeholder = {
		Icon        = "rbxassetid://6023426915",
		Title       = "Mysterious Cube",
		Description = "A plain cube used for testing. Can be picked up and dropped."
	},
	bro = {
		Icon        = "rbxassetid://6023426915",
		Title       = "Mysterious Ball",
		Description = "A plain ball used for testing. Can be picked up and dropped."
	},
	-- Example additional item:
	-- HealthPotion = { Icon = "rbxassetid://12345678", Title = "Health Potion", Description = "Restores 20 HP." }
}

-- Add the maximum drag distance in studs
Config.MaxDragDistance = 10  -- Set this to any value you prefer
Config.PickupRange    = 10    

return Config
