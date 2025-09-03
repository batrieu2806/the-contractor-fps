local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerUI = ReplicatedStorage.PlayerUI
local PlayerData = ReplicatedStorage.PlayerData

local Event = PlayerData.Event

local ArmorEvent = Event.ArmorEvent

local Slot = PlayerUI.Slot

local EquipmentSlot = require(Slot.EquipmentSlot)

local Inventory = require(script.Parent)

local EquipmentInventory = setmetatable({}, Inventory)
EquipmentInventory.__index = EquipmentInventory

function EquipmentInventory.new(config, InventoryFrame, Grid,UpdateEvent)
	local self = Inventory.new(config, InventoryFrame, Grid, nil, nil,UpdateEvent)
	setmetatable(self, EquipmentInventory)
	self:initializeSlots()
	return self
end

function EquipmentInventory:initializeSlots()
	for row = 1, self.Rows do
		self.Slots[row] = {}
		local position = {X = row, Y = -1}
		self.Slots[row] = EquipmentSlot.new(self.Grid,nil,position,row)
	end
	Inventory.InventoryManager:addInventory(self.Name,self)
end


function EquipmentInventory:canPlace(item,X,Y)
	--self:printGrid()
	if X < 1 or X > self.Rows then
		return false, "Out of bounds"
	end
	if X == 1 and item.Type ~= "BodyArmor" then
		return false, "Only BodyArmor items can be placed in this slot"
	elseif X == 2 and item.Type ~= "Helmet" then
		return false, "Only Helmet items can be placed in this slot"
	end
	
	-- Check if the slot at the specified position is occupied
	local slot = self.Slots[X]
	if slot and (slot.OccupiedItem ~= nil and slot.OccupiedItem ~= item) then
		return false, "Slot is already occupied"
	end

	-- If all checks pass, return true
	return true, "Can place"
end


function EquipmentInventory:equipArmor(index)

	if self.Slots[index].OccupiedItem.Item then
		ArmorEvent:FireServer(self.Slots[index].OccupiedItem.Item,index)
	else
		warn("No Armor item at that index to equip")
	end
end

function EquipmentInventory:unequipArmor(index)
	ArmorEvent:FireServer(nil,index)
end


function EquipmentInventory:clearSlot(startRow,startCol,sizeX,sizeY)
	if startRow < 1 or startRow > self.Rows then
		return false, "Out of bounds"
	end
	-- Get the slot at the specified position
	local slot = self.Slots[startRow]
	if not slot then
		return false, "Slot does not exist"
	end

	-- Clear the slot by setting its OccupiedItem to nil
	slot.OccupiedItem = nil
	slot.isRoot = false
	
	self:unequipArmor(startRow)
	return true, "Slot cleared successfully"
end


function EquipmentInventory:moveItem(item,startRow,startCol)
	-- Move the item to the new slot
	local slot = self.Slots[startRow]
	slot.OccupiedItem = item
	item.Position = { X = startRow, Y = -1 }

	-- Resize and reposition the item's visual frame
	slot:resize(item)
	slot:setpos(item)
	
	slot.isRoot = true

	-- Update the item's frame parent to match the inventory frame
	item.ItemFrame.Parent = self.Grid:FindFirstChild("Equip_" .. startRow)
	item.Inventory = self
	
	self:equipArmor(startRow)
	return true, "Item moved successfully"
end





return EquipmentInventory