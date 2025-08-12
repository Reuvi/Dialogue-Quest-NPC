# Dialogue-Quest-NPC

A **Roblox (Luau)** template for building **branching NPC dialogue** and **quest-giver** interactions. Drop it into your game to let players talk to NPCs, make choices, start quests, and receive rewards—while keeping quest state authoritative on the server.
(Core game code transfered over, project directory, assets, and exact file structure is not the same)
## Features

- **Branching dialogue trees** with player choices.
- **Quest lifecycle:** `NotStarted → InProgress → Completed → TurnedIn`.
- **Objectives:** collect, kill/count, talk-to, reach-area, or custom callbacks.
- **Rewards:** currency, XP, items, titles—fully customizable.
- **Client/Server split:** lightweight UI client; secure logic server-side.
- **Pluggable persistence:** hook into your DataStore/profile system.

## What’s Included (suggested layout)

```
/client                 # UI + interaction (open/close dialogue, choice selection)
/server                 # Quest service, world event hooks
/shared                 # Dialogue trees, quest configs, utilities
```

> Move modules to `ReplicatedStorage`, `ServerScriptService`, and `StarterPlayerScripts` to match your project.

## Quick Start (Roblox Studio)

1. Import the modules into your place:

   - `shared/` → `ReplicatedStorage/DialogueQuest`
   - `server/` → `ServerScriptService/DialogueQuestServer`
   - `client/` → `StarterPlayerScripts/DialogueQuestClient`

2. Add an NPC with a `ProximityPrompt`.
3. Create one dialogue tree and (optionally) one quest config.
4. Press **Play** and interact with the NPC.

## Usage

### 1) Define a dialogue tree

```lua
-- ReplicatedStorage/DialogueQuest/Dialogue/GuideNPC.lua
return {
  id = "GuideNPC",
  start = "greet",
  nodes = {
    greet = {
      text = "Hey there! Looking for work?",
      choices = {
        { text = "Yes, any quests?", next = "offerQuest" },
        { text = "Not now.", next = "bye" },
      }
    },
    offerQuest = {
      text = "Find 3 crystals in the cave and come back.",
      onEnter = function(ctx)  -- runs when this node is entered
        ctx:StartQuest("FindCrystals")
      end,
      choices = { { text = "I'm on it.", next = "bye" } }
    },
    bye = { text = "See you around!" }
  }
}
```

### 2) Configure a quest

```lua
-- ReplicatedStorage/DialogueQuest/Quests/FindCrystals.lua
return {
  id = "FindCrystals",
  title = "Crystal Hunt",
  description = "Collect 3 crystals from the cave.",
  objectives = {
    { id = "collect_crystal", type = "collect", target = "Crystal", count = 3 },
  },
  rewards = function(player, ctx)
    -- Grant rewards here, e.g.:
    -- ctx:GiveCurrency(player, 100)
    -- ctx:GiveXP(player, 250)
  end
}
```

### 3) Wire the NPC prompt

```lua
-- ServerScriptService/DialogueQuestServer/BindNPC.server.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Dialogue = require(ReplicatedStorage.DialogueQuest.Dialogue) -- adjust path

local npc = workspace.GuideNPC
local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt")

prompt.Triggered:Connect(function(player)
  Dialogue.open("GuideNPC", player)
end)
```

### 4) Advance objectives from world events

```lua
-- ServerScriptService/DialogueQuestServer/Handlers/Collect.server.lua
local QuestService = require(script.Parent.Parent.QuestService)

-- When a crystal is collected:
QuestService:Increment(player, "FindCrystals", "collect_crystal", 1)
```

## Recommended Folder Conventions

```
ReplicatedStorage/
  DialogueQuest/
    Dialogue/        # NPC dialogue trees
    Quests/          # Quest definitions
    Util/            # Helpers/types
ServerScriptService/
  DialogueQuestServer/
    QuestService.server.lua
    Handlers/        # World event hooks (collect, kill, regions)
StarterPlayerScripts/
  DialogueQuestClient/   # UI + open/close + choice selection
```

## Extending

- **Conditions:** lock choices behind quest state, items, or level.
- **Dynamic text:** insert player name, counts, timers.
- **Multi-NPC quests:** continue a quest across different NPCs.
- **UI:** swap in your own dialogue window; keep the same API.
- **Saving:** connect to your DataStore/ProfileService to persist state.

## Troubleshooting

- **Dialogue doesn’t open:** confirm NPC `id` and module path; ensure `Dialogue.open("<id>", player)` matches your tree.
- **Choices do nothing:** every node needs a `next` or a handler that closes.
- **Objectives don’t progress:** check `questId`/`objectiveId` in your world event calls.
- **State desync:** keep quest state authoritative on the server; send minimal UI data to client.

## License

Add your preferred license (e.g., MIT).

## Credits

Built by **Reuvi**. Thanks to the Roblox developer community for patterns on dialogue trees, quest state machines, and clean client/server splits.
