-- @ScriptType: ModuleScript
-------------------------------------------------------
-- Modules/Trade.lua (ModuleScript)
-------------------------------------------------------
local Inventory = require(script.Parent.InventoryManager)
local Trade = {}

local SELL_PRICE = 10 -- Flat sell price per package

function Trade:Sell(player, packageIndex)
	local data = Inventory:Get(player)
	local pkg = data.packages[packageIndex]
	if not pkg then return nil end
	Inventory:Remove(player, "packages", packageIndex)
	Inventory:ModifyCurrency(player, SELL_PRICE)
	local newBal = data.currency
	return { earned = SELL_PRICE, balance = newBal }
end

return Trade