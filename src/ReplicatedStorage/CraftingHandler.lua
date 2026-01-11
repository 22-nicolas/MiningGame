local Items = require(game.ReplicatedStorage:WaitForChild("Items"))

local CraftingHandler = {}

local CraftingRecipes = {
	TestRecipe = {
		result = { id = Items.other.stackableTestItem.id, amount = 1 },
		ingredients = {
			{ id = Items.materials.coal.id, amount = 20 },
			{ id = Items.materials.stone.id, amount = 20 },
		},
	},
}
CraftingHandler.CraftingRecipes = CraftingRecipes

CraftingHandler.DefaultRecipes = { CraftingRecipes.TestRecipe }

return CraftingHandler
