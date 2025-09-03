local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerUI = ReplicatedStorage.PlayerUI
local PlayerData = ReplicatedStorage.PlayerData

local Slot = PlayerUI.Slot

local WeaponSlot = require(Slot.WeaponSlot)

local Inventory = require(script.Parent)

local WeaponInventory = setmetatable({}, Inventory)
WeaponInventory.__index = WeaponInventory

function WeaponInventory.new(config, InventoryFrame, Grid, TemplateCell,UpdateEvent)
	local self = Inventory.new(config, InventoryFrame, Grid, TemplateCell, nil,UpdateEvent)
	setmetatable(self, WeaponInventory)
	self:initializeSlots()
	return self
end

function WeaponInventory:initializeSlots()
	for row = 1, self.Rows do
		self.Slots[row] = {}
		local position = {X = row, Y = -1}
		self.Slots[row] = WeaponSlot.new(self.Grid,self.TemplateCell,position,row)
	end
	Inventory.InventoryManager:addInventory(self.Name,self)
end

function WeaponInventory:printGrid()
	for row = 1, self.Rows do
		local rowString = ""
		local slot = self.Slots[row]

		-- Check if the slot is initialized and occupied
		if slot and slot.OccupiedItem then
			-- Display the name or identifier of the item in the slot
			local itemName = slot.OccupiedItem.Name or "Item"
			rowString = "[" .. itemName .. "]"
		else
			rowString = "[ ]" -- Empty cell
		end

		print("Row " .. row .. ": " .. rowString) -- Print each row
	end
end

function WeaponInventory:canPlace(item,X,Y)
	--self:printGrid()
	if X < 1 or X > self.Rows then
		return false, "Out of bounds"
	end

	-- Weapon slots typically only allow items of type "Weapon"
	if item.Type ~= "Weapon" then
		return false, "Invalid item type for weapon slot"
	end

	-- Check if the slot at the specified position is occupied
	local slot = self.Slots[X]
	if slot and (slot.OccupiedItem ~= nil and slot.OccupiedItem ~= item) then
		return false, "Slot is already occupied"
	end

	-- If all checks pass, return true
	return true, "Can place"
end

function WeaponInventory:clearSlot(startRow,startCol,sizeX,sizeY)
	if startRow < 1 or startRow > self.Rows then
		return false, "Out of bounds"
	end
	-- Get the slot at the specified position
	local slot = self.Slots[startRow]
	if not slot then
		return false, "Slot does not exist"
	end

	-- Clear the slot by setting its OccupiedItem to nil
	slot.isRoot = false
	slot.OccupiedItem = nil

	return true, "Slot cleared successfully"
end

function WeaponInventory:moveItem(item,startRow,startCol)
	-- Move the item to the new slot
	local slot = self.Slots[startRow]
	slot.OccupiedItem = item
	slot.isRoot = true
	
	item.Position = { X = startRow, Y = -1 }

	-- Resize and reposition the item's visual frame
	slot:resize(item)
	slot:setpos(item)

	-- Update the item's frame parent to match the inventory frame
	item.ItemFrame.Parent = self.Grid:FindFirstChild("Slot_" .. startRow)
	item.Inventory = self

	return true, "Item moved successfully"
end



return WeaponInventory