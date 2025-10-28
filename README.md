# 📌 Roblox Game "Mining Game" (not definitive name)
This is a large-scale Roblox project focused on modular, scalable game architecture.  
Currently in early development - the core systems for mining, player stats, and UI foundations are being built.

## 🎮 Gameplay
A mmorpg style mining game with lots of items an ingame economy and lots of grinding.

## 🛡️ Security
Client-side and server-side scripts are separated and communicate through RemoteEvents. The server validates every value provided by the client.

## 🪲 Bugs
The Game catches multiple errors and bugs safely, returning or exiting and loging or warning appropriately. The scope is to eventualy also handle most errors effectively and automatically where possible.

## Current State Of Development

### Mining and Requests
As of right now the player can mine nodes. Tools have stats like mining speed or fortune stored in `src/ReplicatedStorage/Items.lua`. The server always checks with raycasts if the player is actualy looking at the node and in range. Meaning the clients requests only work as "recommendations" to the server. Nodes also have stats like health and regen rate stored in `src/MiningHandler.lua` (script that handles mining logic). Each node is its own object or metatable(lua) with health ect. To prevent lag from many Heartbeat loops per Node the server has a "centralized" mining loop that handles all nodes in serial.

### Player Stats and Inventory (`src/CustomPlayers.lua`)
When a player joins a new metatable gets created that stores player data. When mining the player gets rewarded with loot drops and xp. The server then fires a RemoteEvent to update the players UI on the client.

### UI/Frontend
When the player gains Items/Materials they get displayed by the `src/ReplicatedStorage/PlayerUI` scripts. The Items can be Equiped to the Hotbar this is in early Progress though and has some bugs because of the way Roblox handles tables (dictionary/array) and how RemoteEvents send the data.

### Other
- Loot notifications
- Fortnite like weak spot system.

### Future Implementations
- Fixing hotbar bugs
- I`m not very pleased with some parts of the Module scripts that handle player UI, they are hard to read and are not error proof. I will need to clean up my code
- Finishing UI functionality
- Crafting system
- NPCs
- Auction House

### 🎬 Preview
Here’s a short look at mining in action (loot notifications weren't on screen):

![Mining Demo](https://imgur.com/a/GoSG4VJ)
