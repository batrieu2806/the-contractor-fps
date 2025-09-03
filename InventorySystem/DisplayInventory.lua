local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerUI = ReplicatedStorage.PlayerUI
local PlayerData = ReplicatedStorage.PlayerData

local Slot = PlayerUI.Slot

local Item = PlayerUI.Item

local ItemShop = require(Item.ItemShop)
local GridSlot = require(Slot.GridSlot)
local GridInventory = require(script.Parent)
local Inventory = require(script.Parent.Parent)
local ItemPreset = require(PlayerUI.ItemPreset)


local DisplayInventory = setmetatable({}, GridInventory)
DisplayInventory.__index = DisplayInventory

function DisplayInventory.new(config, InventoryFrame, Grid, TemplateCell, TemplateItem,UpdateEvent)
	local self = GridInventory.new(config, InventoryFrame, Grid, TemplateCell, TemplateItem,UpdateEvent)
	setmetatable(self, DisplayInventory)
	
	self.CurrentItem = nil
	return self
end

function DisplayInventory:initializeSlots()
	for row = 1, self.Rows do
		for col = 1, self.Cols do
			local flattenedIndex = (row - 1) * self.Cols + col
			local position = {X = row, Y = col}
			self.Slots[flattenedIndex] = GridSlot.new(self.Grid,self.TemplateCell,position,flattenedIndex)
		end
	end
end

function DisplayInventory:addItem(preset, startRow, startCol)
	local Position = {X = startRow, Y = startCol}
	local ItemShop = ItemShop.new(ItemPreset[preset],Position,self.InventoryFrame,self.TemplateItem,self)


	local startIndex = (startRow - 1) * self.Cols + startCol

	-- Place the item in the grid
	self:moveItem(ItemShop,startRow,startCol)

	ItemShop:AdjustInventoryModel(ItemPreset[preset].Model:Clone())
	ItemShop:toggleLable(false)
	-- Track the item in the inventor

	return ItemShop, "Item added successfully"
end

function DisplayInventory:addItemToDisplay(Item)
	if self.CurrentItem == nil then
		self.CurrentItem = ItemShop.new(Item.preset,Item.Position,self.InventoryFrame,self.TemplateItem,self,true)
		self.CurrentItem:toggleLable(false)
	end
	self.CurrentItem.Type = Item.Type
	self.CurrentItem.Size = Item.Size
	self.Slots[1]:resize(self.CurrentItem, self.Cols, self.Rows)
	self.CurrentItem:replaceModel(Item.Model:Clone(),Item.Size)
	self.CurrentItem.ItemFrame.ViewportFrame.BackgroundTransparency = 0.5
end

function DisplayInventory:clearItem()
	if self.CurrentItem then
		self.CurrentItem.Model:Destroy()
		self.CurrentItem.ItemFrame.ViewportFrame.BackgroundTransparency = 1
	end
	
end

return DisplayInventory