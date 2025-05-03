-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
-- ========== ReplicatedStorage/Config.lua ==========
-- Central configuration for slot count and item definitions
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
	-- Example additional item:
	-- HealthPotion = { Icon = "rbxassetid://12345678", Title = "Health Potion", Description = "Restores 20 HP." }
}

return Config