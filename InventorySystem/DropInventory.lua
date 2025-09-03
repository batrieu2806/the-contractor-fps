local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PlayerUI = ReplicatedStorage.PlayerUI
local PlayerData = ReplicatedStorage.PlayerData

local Slot = require(PlayerUI.Slot)

local Inventory = require(script.Parent)

local DropInventory = setmetatable({}, Inventory)
DropInventory.__index = DropInventory

function DropInventory.new(config, InventoryFrame, Grid)
	local self = Inventory.new(config, InventoryFrame, Grid,nil,nil,nil)
	setmetatable(self, DropInventory)
	self:initializeSlots()
	return self
end 


function DropInventory:initializeSlots()
	self.Slots[1] = Slot.new({X = 1,Y = 1},self.Grid.ItemDrop)
	Inventory.InventoryManager:addInventory(self.Name,self)
end

function DropInventory:canPlace()
	--self:printGrid()
	return true, "Can place"
end


function DropInventory:moveItem(Item)
	Item:Drop()
	return true
end



return DropInventory