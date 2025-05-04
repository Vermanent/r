-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
-- ========== ReplicatedStorage/HotbarModule.lua ==========
local Config = require(script.Parent:WaitForChild("Config"))

local HotbarModule = {}

-- Load from config
HotbarModule.SLOT_COUNT       = Config.SlotCount
HotbarModule.ItemDefinitions  = Config.Items

-- State: inventory slots 1..SLOT_COUNT, each entry = { Type, Count }
HotbarModule.inventory   = {}
HotbarModule.activeIndex = nil

-- Select/deselect slot (restored toggling functionality)
function HotbarModule.setActive(idx)
	-- Toggle behavior restored
	if idx == HotbarModule.activeIndex then
		HotbarModule.activeIndex = nil
	else
		HotbarModule.activeIndex = idx
	end
	HotbarModule.refreshUI()
end

-- Add count of given itemType to active or first empty slot
function HotbarModule.addItem(itemType, count)
	local def = HotbarModule.ItemDefinitions[itemType]
	if not def then
		warn("Unknown itemType:", itemType)
		return
	end
	local idx = HotbarModule.activeIndex
	if idx then
		local slot = HotbarModule.inventory[idx]
		if slot and slot.Type == itemType then
			slot.Count = slot.Count + count
		else
			HotbarModule.inventory[idx] = { Type = itemType, Count = count }
		end
		HotbarModule.refreshUI()
		return
	end
	for i = 1, HotbarModule.SLOT_COUNT do
		if not HotbarModule.inventory[i] then
			HotbarModule.inventory[i] = { Type = itemType, Count = count }
			HotbarModule.refreshUI()
			return
		end
	end
end

-- Remove one from selected slot
function HotbarModule.removeItem()
	local idx = HotbarModule.activeIndex
	if not idx then return end
	local slot = HotbarModule.inventory[idx]
	if not slot then return end

	slot.Count = slot.Count - 1
	if slot.Count <= 0 then
		HotbarModule.inventory[idx] = nil
		-- We keep the selection on the same slot even when empty
	end
	HotbarModule.refreshUI()
	return idx, slot
end

-- Stub replaced by UI
function HotbarModule.refreshUI() end

return HotbarModule