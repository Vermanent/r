-- @ScriptType: Script
-------------------------------------------------------
-- MainServer.lua (Script)
-------------------------------------------------------
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Mods = script.Parent:WaitForChild("Modules")

local Inventory = require(Mods.InventoryManager)
local Sampler = require(Mods.SeedSampling)
local Sequencer = require(Mods.TraitSequencing)
local Cultivator = require(Mods.Cultivation)
local Harvester = require(Mods.Harvest)
local Packager = require(Mods.Packaging)
local Trader = require(Mods.Trade)
local Reputation = require(Mods.ReputationSystem)

local events = RS.RemoteEvents

Players.PlayerAdded:Connect(function(player)
	Inventory:Load(player)
	Reputation:Initialize(player)
end)

Players.PlayerRemoving:Connect(function(player)
	Inventory:Save(player)
end)

-- Event handlers
events.SampleSeedEvent.OnServerEvent:Connect(function(player, point)
	local seed = Sampler:CollectSeed(player, point)
	events.SampleSeedEvent:FireClient(player, seed)
end)

events.SequenceTraitEvent.OnServerEvent:Connect(function(player, index)
	local trait = Sequencer:Sequence(player, index)
	events.SequenceTraitEvent:FireClient(player, trait)
end)

events.CultivateEvent.OnServerEvent:Connect(function(player, index)
	local crop = Cultivator:Plant(player, index)
	events.CultivateEvent:FireClient(player, crop)
end)

events.HarvestEvent.OnServerEvent:Connect(function(player, index)
	local crop = Harvester:Collect(player, index)
	events.HarvestEvent:FireClient(player, crop)
end)

events.PackageEvent.OnServerEvent:Connect(function(player, crop)
	local pkg = Packager:Package(player, crop)
	events.PackageEvent:FireClient(player, pkg)
end)

events.TradeEvent.OnServerEvent:Connect(function(player, index)
	local sale = Trader:Sell(player, index)
	events.TradeEvent:FireClient(player, sale)
	Reputation:Add(player, sale.earned)
	events.UpdateReputationEvent:FireClient(player, player:GetAttribute("Reputation"))
end)