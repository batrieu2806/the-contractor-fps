local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PlayerUI = ReplicatedStorage.PlayerUI
local PlayerData = ReplicatedStorage.PlayerData

local Slot = PlayerUI.Slot

local GridSlot = require(Slot.GridSlot)

local Inventory = require(script.Parent)

local GridInventory = setmetatable({}, Inventory)
GridInventory.__index = GridInventory

function GridInventory.new(config, InventoryFrame, Grid, TemplateCell, TemplateItem,UpdateEvent)
	local self = Inventory.new(config, InventoryFrame, Grid, TemplateCell, TemplateItem,UpdateEvent)
	setmetatable(self, GridInventory)
	return self
end 

function GridInventory:initializeSlots()
	for row = 1, self.Rows do
		for col = 1, self.Cols do
			local flattenedIndex = (row - 1) * self.Cols + col
			local position = {X = row, Y = col}
			self.Slots[flattenedIndex] = GridSlot.new(self.Grid,self.TemplateCell,position,flattenedIndex)
		end
	end
	Inventory.InventoryManager:addInventory(self.Name,self)
	self:addItem("M1911A1",1,4)
	--self:addItem("MP5",1,1)
	--self:addItem("M4A1",3,1)
	--self:addItem("KAR98K",2,1)
	self:addItem("M4A1",4,1)
	--self:addItem("_45ACP_FMJ",4,6)
	--self:addItem("_9MM_FMJ",4,8)
	--self:addItem("_12GAUGE_BUCKSHOT",5,6)
	--self:addItem("_8MMMAUSER_FMJ",5,8)
	self:addItem("_556x45_FMJ",1,2)
	
	--self:addItem("ENDEAVOR",6,1)
	--self:addItem("PASGT",9,1)
	--self:addItem("STENMK2",9,3)
	--self:addItem("WINCHESTERMODEL21",11,1)
	
	if Players.LocalPlayer.UserId == game.CreatorId then
		print("got the owner!")
		--self:addItem("_9MM_FMJ",1,6)
		--self:addItem("_556x45_FMJ",1,4)
		--self:addItem("M1911",1,8)
		--self:addItem("GLOCK17",2,4)
		--self:addItem("MP5",1,1)
		--self:addItem("KAR98K",5,1)
		--self:addItem("M4A1",3,1)
	end
end


function GridInventory:moveItem(item,startRow,startCol)
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
	item.Inventory = self
	
	return true, "Item moved successfully"
end


return GridInventory