local Crafting = {}

local Utils = require(game.ReplicatedStorage:WaitForChild("Utils"))
local Items = require(game.ReplicatedStorage:WaitForChild("Items"))
local SlotsHandler = require(
	game.ReplicatedStorage
		:WaitForChild("PlayerUIHandler")
		:WaitForChild("InventoryUIHandler")
		:WaitForChild("SlotsHandler")
)

local craftRequest = game.ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("craftRequest")

Crafting.__index = Crafting
function Crafting.new(InventoryUI: table, PlayerUI: table)
	local self = {}
	setmetatable(self, Crafting)

	self.PlayerUI = PlayerUI
	self.InventoryUI = InventoryUI
	self.Instance = InventoryUI.InventoryFrame:WaitForChild("Crafting")
	self.RecipeFrame = self.Instance:WaitForChild("Recipes")
	self.InfoFrame = self.Instance:WaitForChild("Info")
	self.PreviewSlot = SlotsHandler.newSlot(InventoryUI, self.InfoFrame, 0, "locked", 2)
	self.IngredientsFrame = self.InfoFrame:WaitForChild("Ingredients")
	self.CraftBtn = self.InfoFrame:WaitForChild("CraftBtn")

	self.CraftBtn.MouseButton1Click:Connect(function()
		if not self.activeRecipe then
			return
		end

		craftRequest:FireServer(self.activeRecipe)
	end)

	self:updateRecipes()

	return self
end

function Crafting:updateRecipes()
	--clear last recepes
	local children = self.RecipeFrame:GetChildren()
	for _, child in pairs(children) do
		if child.ClassName ~= "UIListLayout" then
			child:Destroy()
		end
	end

	local recipes = self.PlayerUI.stats.unlockedRecipes

	for k, recipe in pairs(recipes) do
		local recipeBtn = {}
		recipeBtn.Instance = self:initRecipeUI(recipe.result.id, recipe.result.amount)
		recipeBtn.Instance.Parent = self.RecipeFrame
		recipeBtn.recipe = recipe

		recipeBtn.Instance.MouseButton1Click:Connect(function()
			self:setActiveRecipe(recipe)
			self.InventoryUI.cursorItem:cancel()
		end)
	end
end

function Crafting:setActiveRecipe(recipe: table)
	if not recipe then
		self.InfoFrame.Visible = false
		return
	end

	local resultItem = Items.getItemById(recipe.result.id)
	resultItem.amount = recipe.result.amount

	self.PreviewSlot:setItem(resultItem)

	--clear last ingredients
	local children = self.IngredientsFrame:GetChildren()
	for _, child in pairs(children) do
		if child.ClassName ~= "UIListLayout" then
			child:Destroy()
		end
	end

	for k, ingredient in pairs(recipe.ingredients) do
		local button = self:initRecipeUI(ingredient.id, ingredient.amount)
		button.Parent = self.IngredientsFrame
		button.Name = ingredient.id --name serves as layout order
	end

	self.InfoFrame.Visible = true

	self.activeRecipe = recipe
end

function Crafting:initRecipeUI(id: string, amount: number)
	local item = Items.getItemById(id)

	if not item then
		warn(
			"[InventoryHandler] Error: No item data for player: "
				.. tostring(self.InventoryUI.player.UserId)
				.. ". While trying to load recipe."
		)
		return
	end

	item.amount = amount

	local button = Instance.new("TextButton")
	button.Text = ""
	button.Size = UDim2.new(1, 0, 0, 20)
	button.BackgroundColor = BrickColor.Black()
	button.BackgroundTransparency = 1

	local UiListLayout = Instance.new("UIListLayout")
	UiListLayout.FillDirection = Enum.FillDirection.Horizontal
	UiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UiListLayout.Wraps = false
	UiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	UiListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	UiListLayout.Parent = button

	local img = Instance.new("ImageLabel")
	img.Image = item.img
	img.Size = UDim2.new(0, 0, 1, 0)
	img.BackgroundTransparency = 1
	img.LayoutOrder = 1
	img.Parent = button

	local aspectRatio = Instance.new("UIAspectRatioConstraint")
	aspectRatio.AspectType = Enum.AspectType.ScaleWithParentSize
	aspectRatio.DominantAxis = Enum.DominantAxis.Height
	aspectRatio.AspectRatio = 1
	aspectRatio.Parent = img

	local textLabel = Instance.new("TextLabel")
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextColor3 = item.rarity
	textLabel.FontFace.Weight = Enum.FontWeight.Bold
	textLabel.BackgroundTransparency = 1
	textLabel.Name = item.displayName
	textLabel.Text = tostring(item.amount) .. "x " .. id
	textLabel.Position = UDim2.new(0.3, 0, 0, 0)
	textLabel.Size = UDim2.new(0.7, 0, 1, 0)
	textLabel.LayoutOrder = 2
	textLabel.Parent = button

	local textStroke = Instance.new("UIStroke")
	textStroke.Color = Color3.new(0, 0, 0)
	textStroke.Parent = textLabel

	button.Parent = self.ItemContainer

	return button
end

return Crafting
