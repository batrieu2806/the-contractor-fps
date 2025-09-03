local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PlayerUI = ReplicatedStorage.PlayerUI
local PlayerData = ReplicatedStorage.PlayerData

local InventoryManager = require(PlayerData.InventoryManager)
local Item = require(PlayerUI.Item)

local ItemPreset = require(PlayerUI.ItemPreset)

local Inventory = {}
Inventory.__index = Inventory

Inventory.InventoryManager = InventoryManager.new()

function Inventory.new(config,InventoryFrame,Grid,TemplateCell,TemplateItem,UpdateEvent)
	local self = setmetatable({}, Inventory) -- Step 1: Create an empty table with Inventory as the metatable 
	self.Name = config.Name
	self.Type = config.Type
	self.Cols = config.Cols
	self.Rows = config.Rows
	self.Slots = {}
	
	self.UpdateEvent = UpdateEvent
	
	self.Grid = Grid
	self.TemplateCell = TemplateCell
	self.TemplateItem = TemplateItem
	self.InventoryFrame = InventoryFrame
	--self:initializeSlots()
	
	return self
end

function Inventory:printGrid()
	for row = 1, self.Rows do
		local rowString = ""
		for col = 1, self.Cols do
			local slotIndex = (row - 1) * self.Cols + col
			local slot = self.Slots[slotIndex]

			if slot and slot.OccupiedItem then
				-- Display the name or identifier of the item in the slot
				local itemName = slot.OccupiedItem.Name or "Item"
				rowString = rowString .. "[" .. itemName .. "]"
			else
				rowString = rowString .. "[ ]" -- Empty cell
			end
		end
		print(rowString) -- Print each row
	end
end

function Inventory:toggle(bool)
	self.InventoryFrame.Visible = bool
end


function Inventory:getPreset(key)
	return ItemPreset[key]
end

function Inventory:canPlaceBySize(sizeX, sizeY, X, Y)
	-- Ensure the placement is within bounds
	if X < 1 or Y < 1 or X + sizeY - 1 > self.Rows or Y + sizeX - 1 > self.Cols then
		return false, "Out of bounds"
	end

	-- Check each slot the item would occupy
	for row = X, X + sizeY - 1 do
		for col = Y, Y + sizeX - 1 do
			local slotIndex = (row - 1) * self.Cols + col
			local slot = self.Slots[slotIndex]
			if slot and slot.OccupiedItem then
				return false, "Slot occupied"
			end
		end
	end

	return true, "Can place"
end

function Inventory:canPlace(item,X,Y)
	--self:printGrid()
	if X < 1 or Y < 1 or X > self.Rows or Y > self.Cols then
		return false, "Out of bounds"
	end
	
	for row = 0, item.Size.Y - 1 do
		for col = 0, item.Size.X - 1 do
			local currentRow = X + row
			local currentCol = Y + col

			-- Ensure the position is within the grid
			if currentRow > self.Rows or currentCol > self.Cols then
				return false, "Does not fit in grid"
			end

			-- Check if the slot is occupied
			local slot = self.Slots[(currentRow - 1) * self.Cols + currentCol]
			if slot and (slot.OccupiedItem ~= nil and slot.OccupiedItem ~= item) then
				return false, "Slot occupied"
			end
		end
	end

	return true, "Can place"
end

function Inventory:clearSlot(startRow,startCol,sizeX,sizeY)
	for row = startRow, startRow + sizeY - 1 do
		for col = startCol, startCol + sizeX - 1 do
			-- Calculate the 1D index for the slot
			local slotIndex = (row - 1) * self.Cols + col
			local slot = self.Slots[slotIndex]
			slot.isRoot = false
			-- Clear the slot if it exists
			if slot then
				slot.OccupiedItem = nil
			end
		end
	end
end

function Inventory:moveItem(item,startRow,startCol)
	for row = startRow, startRow + item.Size.Y - 1 do
		for col = startCol, startCol + item.Size.X - 1 do
			local slotIndex = (row - 1) * self.Cols + col
			local slot = self.Slots[slotIndex]

			if slot then
				slot.OccupiedItem = item
				slot.isRoot = (row == startRow and col == startCol)
			end
		end
	end

	-- Update the item's position
	item.Position = { X = startRow, Y = startCol }

	-- Resize and reposition the item's visual frame
	local slot = self.Slots[(startRow - 1) * self.Cols + startCol]
	if slot then
		slot:resize(item, self.Cols, self.Rows)
		slot:setpos(item, self.Cols, self.Rows, startCol, startRow)
	end
	item.ItemFrame.Parent = self.InventoryFrame
	return true, "Item moved successfully"
end

function Inventory:addItem(preset, startRow, startCol, Count)
	-- Validate the position
	local Position = {X = startRow, Y = startCol}
	local Item = Item.new(ItemPreset[preset],Position,self.InventoryFrame,self.TemplateItem,self)
	
	
	local startIndex = (startRow - 1) * self.Cols + startCol
	
	-- Place the item in the grid
	self:moveItem(Item,startRow,startCol)

	Item:AdjustInventoryModel(ItemPreset[preset].Model:Clone())
	Item:setupInputEvents()
	Item:AddItem()
	Item.Count = Count or Item.Max
	Item:AdjustLable()
	
	-- Track the item in the inventor

	return Item, "Item added successfully"
end

function Inventory:addToAvailableSlot(preset,Count)
	local itemSizeX = ItemPreset[preset].Size.X
	local itemSizeY = ItemPreset[preset].Size.Y

	-- Iterate through all rows and columns to find an available slot
	for startRow = 1, self.Rows do
		for startCol = 1, self.Cols do
			local canPlace, reason = self:canPlaceBySize(itemSizeX, itemSizeY, startRow, startCol)
			if canPlace then
				-- Create and add the item to the available slot
				return self:addItem(preset, startRow, startCol,Count)
			end
		end
	end

	-- If no suitable slot is found, return nil and a message
	return nil, "No available slot to place the item"
end
return Inventory
