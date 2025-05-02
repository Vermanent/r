-- @ScriptType: ModuleScript
-------------------------------------------------------
-- Modules/InventoryManager.lua (ModuleScript)
-------------------------------------------------------
local DataStoreService = game:GetService("DataStoreService")
local store = DataStoreService:GetDataStore("PlayerData")

local Inventory = {}
Inventory.data = {} -- In-memory storage per player.UserId

-- Default structure: seeds, traits, crops, packages, currency
function Inventory:Load(player)
	local userId = player.UserId
	local data = nil
	pcall(function()
		data = store:GetAsync(userId)
	end)
	Inventory.data[userId] = data or {seeds={}, traits={}, crops={}, packages={}, currency=100}
end

function Inventory:Save(player)
	local userId = player.UserId
	local data = Inventory.data[userId]
	pcall(function()
		store:SetAsync(userId, data)
	end)
end

function Inventory:Get(player)
	return Inventory.data[player.UserId]
end

function Inventory:Add(player, category, item)
	local d = Inventory:Get(player)
	table.insert(d[category], item)
end

function Inventory:Remove(player, category, index)
	local d = Inventory:Get(player)
	table.remove(d[category], index)
end

function Inventory:ModifyCurrency(player, amount)
	local d = Inventory:Get(player)
	d.currency = (d.currency or 0) + amount
end

return Inventory