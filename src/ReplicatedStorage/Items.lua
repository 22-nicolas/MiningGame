local Rarities = require(game.ReplicatedStorage:WaitForChild("Rarities"))
local Utils = require(game.ReplicatedStorage:WaitForChild("Utils"))

local Items = {
	
	miningTools = {
		admin_pick = {
			displayName = "Admin Pick",
			rarity = Rarities.mithic,
			description = "The strongest pickaxe in the game.",
			img = "http://www.roblox.com/asset/?id=258161647",
			npcSell = 0,
			breakingPower = 100,
			miningFortune = 2000,
			miningSpeed = 2000,
			swingRange = 14,
			type = "Pickaxe",
			displayedStats = {
				"miningSpeed",
				"miningFortune",
				"swingRange",
				"breakingPower"
			}
		},
		rookie_pickaxe = {
			displayName = "Rookie Pickaxe",
			rarity = Rarities.common,
			description = "A great beginner pickaxe",
			img = "http://www.roblox.com/asset/?id=258161647",
			npcSell = 20,
			breakingPower = 1,
			miningFortune = 20,
			miningSpeed = 20,
			swingRange = 14,
			type = "Pickaxe",
			displayedStats = {
				"miningSpeed",
				"miningFortune",
				"swingRange",
				"breakingPower",
				"npcSell"
			}
		},
	},
	
	materials = {
		coal = {
			displayName = "Coal",
			rarity = Rarities.uncommon,
			description = "Can be used as a primitive fuel.",
			npcSell = 2,
			amount = 1,
			img = "http://www.roblox.com/asset/?id=71161594365669"
		},
		
		stone = {
			displayName = "Stone",
			rarity = Rarities.common,
			description = "Bowling.",
			npcSell = 0.1,
			amount = 1,
			img = "http://www.roblox.com/asset/?id=856547720"
		}
	}
}

function Items.getItemById(id: string)
	if not Utils.checkValue(id, "string", "[Items]") then return end
	for _, categories in pairs(Items) do
		if typeof(categories) ~= "function" then 
			for itemId, itemData in pairs(categories) do
				if itemId == id then
					return itemData
				end
			end
		end
	end
end

return Items
