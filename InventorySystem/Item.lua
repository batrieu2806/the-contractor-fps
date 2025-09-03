local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local PlayerData = ReplicatedStorage.PlayerData
local FrameWork = ReplicatedStorage.FrameWork

local Event = PlayerData.Event

local AddItem = Event.AddItem

local InventoryManager = require(PlayerData.InventoryManager)
local FireArmItem = require(FrameWork.BaseItem.UseableItem.FireArmItem)
local AmmoItem = require(FrameWork.BaseItem.AmmoItem)
local BaseItem = require(FrameWork.BaseItem)

local Item = {}
Item.__index = Item

Item.InventoryManager = InventoryManager.new()

local draggingTemplate = nil

function Item.new(preset,position,inventoryFrame,itemTemplate,Inventory)
	-- Ensure the preset is valid
	if not preset then
		error("Invalid preset provided for Item")
	end
	-- Create the item object
	local self = setmetatable({}, Item)
	
	self.preset = preset
	
	self.ItemFrame = itemTemplate:Clone()
	self.ItemFrame.Parent = inventoryFrame
	self.ItemFrame.Visible = true
	self.ItemFrame.Name = preset.Name
	
	self.Name = preset.Name or "Unnamed Item"
	self.NameShort = preset.NameShort or self.Name
	self.Type = preset.Type or "Generic"
	self.AmmoType = preset.AmmoType or "nil"
	self.Icon = preset.Icon or ""
	self.Max = preset.Max or 1
	self.Discription = preset.Discription
	
	self.Size = {X = preset.Size.X or 1, Y = preset.Size.Y or 1}
	
	self.Cost = preset.Cost or 0
	self.Shop = preset.Shop or false
	
	self.Position = position
	self.Count = self.Max -- Items start at full quantity
	
	self.EventConnector = {}
	
	self.Inventory = Inventory
	
	self.BaseCol = self.Inventory.Cols
	self.BaseRow = self.Inventory.Rows

	return self
end

function Item:copy()
	-- Create a new instance of Item
	local newCopy = setmetatable({}, Item)

	-- Copy simple properties
	newCopy.preset = self.preset -- Preset may be immutable, so direct assignment is fine
	newCopy.Name = self.Name
	newCopy.NameShort = self.NameShort
	newCopy.Type = self.Type
	newCopy.AmmoType = self.AmmoType
	newCopy.Icon = self.Icon
	newCopy.Max = self.Max
	newCopy.Size = {X = self.Size.X, Y = self.Size.Y} -- Deep copy the size table
	newCopy.Cost = self.Cost
	newCopy.Shop = self.Shop
	newCopy.Position = self.Position
	newCopy.Count = self.Count
	newCopy.BaseCol = self.BaseCol
	newCopy.BaseRow = self.BaseRow

	-- Clone the visual representation (ItemFrame)
	if self.ItemFrame then
		newCopy.ItemFrame = self.ItemFrame:Clone()
		newCopy.ItemFrame.Visible = true
		newCopy.ItemFrame.Name = self.ItemFrame.Name
	end

	-- Copy the inventory reference (optional: you might choose to keep it nil)
	newCopy.Inventory = self.Inventory

	-- EventConnector should be a new table (do not share events)
	newCopy.EventConnector = {}

	-- Return the newly created copy
	return newCopy
end


function Item:delete()
	-- Destroy the visual representation (ItemFrame)
	if self.ItemFrame then
		self.ItemFrame:Destroy()
		self.ItemFrame = nil
	end

	-- Remove from the inventory if still present
	if self.Inventory then
		local row, col = self.Position.X, self.Position.Y
		self.Inventory:clearSlot(row, col, self.Size.X, self.Size.Y)
		self.Inventory = nil
	end

	-- Clean up any associated resources (e.g., models)
	if self.Model then
		self.Model:Destroy()
		self.Model = nil
	end

	-- Disconnect events
	if self.EventConnector then
		for _, connection in pairs(self.EventConnector) do
			connection:Disconnect()
		end
		self.EventConnector = nil
	end


	-- Clear references to free memory
	self.preset = nil
	self.Type = nil
	self.AmmoType = nil
end

function Item:Drop()
	self.Item:Drop()
	self:delete()
end


function Item:AddItem()
	if self.Item and self.Item.Parent then
		return
	end
	if self.Type == "Weapon" then
		self.Item = FireArmItem.new(self.preset)
		
	elseif self.Type == "Ammo" then
		self.Item = AmmoItem.new(self.preset)
		--self.Item = AddItem:InvokeServer(self.Name)
	end
	self.Item:initalize()
end

function Item:getKey()
	if self.Type == "Ammo" then
		return "_" .. self.Name
	else
		return self.Name
	end
end

function Item:getFrameCorners()
	local position = self.ItemFrame.AbsolutePosition
	local size = self.ItemFrame.AbsoluteSize
	local anchorOffset = size * self.ItemFrame.AnchorPoint

	-- Calculate corners based on anchor offset
	local topLeft = position - anchorOffset
	local topRight = topLeft + Vector2.new(size.X, 0)
	local bottomLeft = topLeft + Vector2.new(0, size.Y)
	local bottomRight = topLeft + Vector2.new(size.X, size.Y)

	return topLeft, topRight, bottomLeft, bottomRight
end

function Item:toggleLable(bool)
	self.ItemFrame.NameTag.Visible = bool
	self.ItemFrame.AmmoType.Visible = bool
	self.ItemFrame.Price.Visible = bool 
	self.ItemFrame.Count.Visible = bool
end


function Item:UpdateCount()
	self.ItemFrame.Count.Text = self.Count
end

function Item:PriceLable(TextSize)
	self.ItemFrame.Price.Text = self.preset.Cost
	self.ItemFrame.Price.TextSize = TextSize
	self.ItemFrame.Price.Visible = false
end

function Item:AdjustLable()
	local viewportSize = workspace.CurrentCamera.ViewportSize
	local screenWidth = viewportSize.X
	local screenHeight = viewportSize.Y

	-- Detect orientation (Portrait or Landscape)
	local isPortrait = screenHeight > screenWidth

	-- Adjust base size for portrait vs landscape
	local baseTextSize = 22 -- Larger text in portrait mode

	-- Calculate scale factors
	local scaleFactorWidth = screenWidth / 1920
	local scaleFactorHeight = screenHeight / 1080
	local averageScaleFactor = (scaleFactorWidth + scaleFactorHeight) / 2

	-- Adjust text size and clamp
	local TextSize = math.clamp(math.floor(baseTextSize * averageScaleFactor), 5, 50)
	
	self:PriceLable(TextSize)
	
	self.ItemFrame.NameTag.Text = self.preset.Name
	self.ItemFrame.NameTag.TextSize = TextSize
	
	self.ItemFrame.AmmoType.Text = self.preset.AmmoType
	self.ItemFrame.AmmoType.TextSize = TextSize
	
	if self.AmmoType == "nil" then
		self.ItemFrame.AmmoType.Visible = false
	else
		self.ItemFrame.AmmoType.Visible = true
	end
	
	if self.preset.Type == "Ammo" then
		local Type = string.match(self.preset.Name, "_(%w+)$")
		self.ItemFrame.NameTag.Text = Type
	end
	
	if self.preset.Max > 1 then
		self.ItemFrame.Count.Text = self.Count
		self.ItemFrame.Count.TextSize = TextSize
		self.ItemFrame.Count.Visible = true
	else
		self.ItemFrame.Count.Visible = false
	end
end

function Item:SetModelTransparency(Model, transparency)
	-- Validate the Model
	if not Model or not Model:IsA("Model") then
		Model.Transparency = transparency
		return
	end

	-- Iterate through all children of the Model
	for _, child in ipairs(Model:GetDescendants()) do
		if child:IsA("BasePart") then
			child.Transparency = transparency
		end
	end
end

function Item:replaceModel(model)
	if self.Model then
		self.Model:Destroy()
	end

	self:AdjustInventoryModel(model)
end

function Item:AdjustInventoryModel(Model)
	self.Model = Model
	
	if self.Model:FindFirstChild("AimPoint") then
		self.Model.AimPoint:Destroy()
	end
	
	if self.Model:FindFirstChild("MagazinePoint") then
		self.Model.MagazinePoint:Destroy()
	end
	if self.Model:FindFirstChild("MuzzlePoint") then
		self.Model.MuzzlePoint:Destroy()
	end
	
	if self.Model:FindFirstChild("ShellPoint") then
		self.Model.ShellPoint:Destroy()
	end
	
	if not self.Camera then
		self.Camera = Instance.new("Camera")
		self.Camera.FieldOfView = 70
	end
	
	self.ItemFrame.ViewportFrame.CurrentCamera = self.Camera
	
	self.Model.Parent = self.ItemFrame.ViewportFrame 
	self.Camera.Parent = self.ItemFrame.ViewportFrame 
	
	self:reAdjustInventoryModel(self.ItemFrame.ViewportFrame,self.Camera)
	
	if self.Model:FindFirstChild("Clip") then
		self:SetModelTransparency(self.Model.Clip, 1)
	end
	if self.Model:FindFirstChild("Bullet") then
		self:SetModelTransparency(self.Model.Bullet, 1)
	end
end


function Item:AdjustHotbarModel(viewPortFrame,Camera)
	if not self.Model then
		warn("No Model")
		return
	end
	Camera.FieldOfView = 70
	viewPortFrame.CurrentCamera = Camera
	self:reAdjustInventoryModel(viewPortFrame,Camera)
end


function Item:reAdjustInventoryModel(viewPortFrame,Camera)
	local currentCFrame = self.Model:GetPivot() -- Get the current CFrame of the model
	local newPosition = Vector3.new(0, 0, 0) -- Desired position
	self.Model:PivotTo(CFrame.new(newPosition) * CFrame.Angles(currentCFrame:ToOrientation()))

	local modelCF, modelSize = self.Model:GetBoundingBox()
	local modelOrientation = self.Model:GetPivot()
	local pitch, yaw, roll = modelCF:ToOrientation()


	local isFlipped = false
	if yaw and math.abs(math.deg(yaw) % 180) > 85 and math.abs(math.deg(yaw) % 180) < 95 then
		isFlipped = true
	end


	local adjustedX = isFlipped and modelSize.Z or modelSize.X
	local adjustedZ = isFlipped and modelSize.X or modelSize.Z

	local modelCenter = modelCF.Position

	local cameraX = modelCenter.X
	local cameraY = modelCenter.Y
	local cameraZ = modelCenter.Z
	-- Adjust zoom to fit the model in the frame
	local viewportSize = viewPortFrame.AbsoluteSize
	local aspectRatio = viewportSize.X / viewportSize.Y
	local verticalFOV = math.rad(Camera.FieldOfView)
	local horizontalFOV = 2 * math.atan(math.tan(verticalFOV / 2) * aspectRatio)
	local distanceX = adjustedX / 2
	
	if self.Type == "Helmet" then
		distanceX =  distanceX - 0.7
	elseif self.Type == "BodyArmor" then
	elseif self.Type == "Ammo" then
		distanceX =  distanceX + 0.1 
	else 
		distanceX = 0
	end
	-- Calculate the distances needed to fit the model in both dimensions
	local distanceY = ((modelSize.Y ) / 2) / math.tan(verticalFOV / 2)
	local distanceZ = ((adjustedZ ) / 2) / math.tan(horizontalFOV / 2)
	  -- Optional if depth needs adjustment
	
	-- Use the maximum distance to fit the model
	local distance = (math.max(distanceY, distanceZ) + distanceX)
	-- Add minimum and maximum zoom distance limits
	local minZoomDistance = 0.8   -- Minimum camera distance for small models
	local maxZoomDistance = 99  -- Maximum camera distance for large models

	cameraX = distance * 1.1

	Camera.CFrame = CFrame.new(cameraX, cameraY, cameraZ) * CFrame.Angles(0, math.rad(90), 0)
end

function Item:reSizeAnyWhere()
	self.ItemFrame.Size = UDim2.new(
		(self.Size.X / self.BaseCol)* self.Inventory.InventoryFrame.Size.X.Scale, 0, 
		(self.Size.Y / self.BaseRow)* self.Inventory.InventoryFrame.Size.Y.Scale, 0)
end

function Item:startDrag()
	draggingTemplate = self.ItemFrame
	
	self.startPos = draggingTemplate.Position
	self.mousePos = game:GetService("UserInputService"):GetMouseLocation()
	
	self.ItemFrame.Parent = self.Inventory.InventoryFrame.Parent

	-- Convert the mouse position from screen space to local space by subtracting the Inventory's position
	local localMousePositionX = (self.mousePos.X - self.Inventory.InventoryFrame.Parent.AbsolutePosition.X)
	local localMousePositionY = (self.mousePos.Y - self.Inventory.InventoryFrame.Parent.AbsolutePosition.Y) - 36

	-- Set the template's position in Stash's local space
	self.ItemFrame.Position = UDim2.new(0, localMousePositionX, 0, localMousePositionY)
	self:reSizeAnyWhere()
	self.startPos = self.ItemFrame.Position
	
end

function Item:stopDrag()
	draggingTemplate = nil
	Item.InventoryManager:attemptPlaceItem(self)
end

function Item:isDragging()
	local mouseLocation = game:GetService("UserInputService"):GetMouseLocation()
	local delta = mouseLocation -self.mousePos
	--local delta = input.Position - mousePos
	draggingTemplate.Position = UDim2.new(self.startPos.X.Scale, self.startPos.X.Offset + delta.X, self.startPos.Y.Scale, self.startPos.Y.Offset + delta.Y)
end

function Item:setupInputEvents()

	self.EventConnector.Begin = self.ItemFrame.InputBegan:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch)  
			and draggingTemplate == nil then

			self:startDrag()
		end
	end)
	
	self.EventConnector.MobileEnd =  UserInputService.TouchEnded:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) 
			and draggingTemplate == self.ItemFrame then
			self:stopDrag()
		end
	end)
	
	self.EventConnector.PcEnd = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) 
				and draggingTemplate == self.ItemFrame then
				self:stopDrag()
			end
		end
	end)
	
	self.EventConnector.Step =  game:GetService("RunService").RenderStepped:Connect(function()
		if draggingTemplate == self.ItemFrame then
			self:isDragging()
		end
	end)
end

return Item