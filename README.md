Here’s a **drop-in replacement** for your README with the **Usage** updated to match your actual Interactable NPC system (the `ReplicatedStorage.NPCData.Interactable` table + `Actions` modules, ProximityPrompt, Zones, and the “actions only on terminal options” rule).

---

# Dialogue-Quest-NPC

A **Roblox (Luau)** template for building **branching NPC dialogue** and **quest-giver** interactions using a simple **Interactable data table**. NPCs are configured by name under `ReplicatedStorage.NPCData.Interactable`, with optional **voice lines** and **terminal actions**.
(Core game code transferred over — project directory, assets, and exact file structure may differ.)

## Features

* **Branching dialogue** defined as data (no custom UI code required to start).
* **Terminal actions** (e.g., grant item, start quest, nothing) triggered only at leaf options.
* **Voice support**: optional `voice = "rbxassetid://..."` per response.
* **Zones & prompt**: proximity prompt + configurable zones folder for interaction radius.
* **Tag-based discovery**: tag the top NPC model `"InteractableNPC"` to auto-register.
* **Server-authoritative hooks**: put side-effects in `ReplicatedStorage.NPCData.Actions`.

## Suggested Layout

```
ReplicatedStorage/
  NPCData/
    Interactable/   -- Dialogue data tables keyed by NPC name
    Actions/        -- Action modules (e.g., nothing.lua, giveItem.lua)
Workspace/
  <YourNPCParentModel>   -- top model tagged "InteractableNPC"
    NPC/                 -- child model containing the rig
      Zones/             -- (optional) parts used to define custom radii
      HumanoidRootPart   -- holds a ProximityPrompt (uninitialized by default)
ServerScriptService/
  Interactables.server.lua  -- binder that reads NPCData and wires prompts
```

## Quick Start (Roblox Studio)

1. **Create the NPC hierarchy**

* Top model: any name (e.g., `GuideNPC`), **tag it** `"InteractableNPC"`.
* Inside it, add a child model named **`NPC`** containing the rig.
* Add an **uninitialized `ProximityPrompt`** under `NPC.HumanoidRootPart` (or torso).
* *(Optional)* Add a folder **`Zones`** inside `NPC` with one or more Parts to define a custom interact radius.

2. **Add NPC data**

* In **`ReplicatedStorage.NPCData.Interactable`**, create a ModuleScript returning a table keyed by **top model name**.
  The key must match the NPC’s top model `Name` (e.g., `"GuideNPC"`).

3. **Add actions**

* Create Modules under **`ReplicatedStorage.NPCData.Actions`**.
  Include at least **`nothing.lua`** (a no-op) so terminal options have a detectable action.

4. **Bind on server**

* In a server script (e.g., `Interactables.server.lua`), read/tag and wire prompts to your Interactable system (your binder).
  The binder should look up `NPCData.Interactable[topModel.Name]`.

---

## Usage

### 1) Define NPC data (Interactable table)

Create `ReplicatedStorage/NPCData/Interactable/init.lua` (or similar) that returns a table.
**Only leaf options** should include an `actions` array. Non-terminal options should **not** include `actions`.

```lua
-- ReplicatedStorage/NPCData/Interactable/init.lua
local Actions = game:GetService("ReplicatedStorage").NPCData.Actions

local Interactable = {}

-- NPC key MUST equal the top model's Name in Workspace
Interactable["Example2"] = {
  -- Root NPC response when interaction starts
  response = {
    text = "Hello there! How can I assist you today?",
    voice = "rbxassetid://8974863112",
  },

  -- Player choices at this level
  options = {
    [1] = {
      text = "Tell me a joke",
      response = {
        text = "Why don't scientists trust atoms? Because they make up everything!",
        voice = "rbxassetid://8974863112",
      },
      -- Next set of player choices (no actions here; conversation continues)
      options = {
        [1] = {
          text = "Haha, that's funny!",
          -- TERMINAL: add actions ONLY at leaves
          actions = {
            [0] = require(Actions.nothing), -- must exist; does nothing
          },
        },
      },
    },

    [2] = {
      text = "Share a fun fact",
      response = {
        text = "Honey never spoils — jars from ancient Egypt are still edible!",
        voice = "rbxassetid://8974863112",
      },
      options = {
        [1] = {
          text = "Wow, that's interesting!",
          actions = {
            [0] = require(Actions.nothing),
          },
        },
      },
    },
  },
}

return Interactable
```

**Rules to remember**

* Put `actions` **only on the last possible input value** (leaf nodes).
* If you don’t have real actions yet, include `require(Actions.nothing)` so the system detects a terminal node.
* **Do not** add `options` under a node that already has `actions` (that would defeat the “terminal” rule).
* Each node can have an NPC **`response`** (`text`, optional `voice`) and an array of **`options`** (`text`, optional nested `options` or terminal `actions`).

### 2) Create Actions modules

Add `ReplicatedStorage/NPCData/Actions/nothing.lua` and any real action modules you need.

```lua
-- ReplicatedStorage/NPCData/Actions/nothing.lua
return function(ctx)
  -- no-op terminal action
  -- ctx can include: player, npcModel, metadata, etc.
end
```

Example real action:

```lua
-- ReplicatedStorage/NPCData/Actions/grantCoins.lua
return function(ctx)
  local player = ctx.player
  local amount = 100
  -- Your server-side currency grant goes here
  -- CurrencyService:Add(player, amount)
end
```

Use them in a terminal node:

```lua
actions = {
  [0] = require(Actions.grantCoins),
}
```

### 3) NPC setup in Workspace

Follow your original setup guide (adjusted for clarity):

1. **Model the NPC** inside a model named `NPC` (rig + Humanoid).
2. Put that `NPC` model **inside a top model** (your distinguishable NPC name).
3. **Tag the top model** with `"InteractableNPC"` (e.g., via CollectionService).
4. Add a **ProximityPrompt** in the NPC’s torso/`HumanoidRootPart` (left uninitialized).
5. *(Optional)* Add a **`Zones`** folder under `NPC` and place a Part that defines custom radius.
6. Put NPC data in **`ReplicatedStorage.NPCData.Interactable`** using a key equal to the **top model’s Name**.

### 4) Server binder (example)

Here’s a minimal idea of how your server binder might associate tagged NPCs with data:

```lua
-- ServerScriptService/Interactables.server.lua (example scaffold)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local InteractableData = require(ReplicatedStorage.NPCData.Interactable)

for _, npcTop in ipairs(CollectionService:GetTagged("InteractableNPC")) do
  local npcModel = npcTop:FindFirstChild("NPC")
  local prompt = npcModel and npcModel:FindFirstChildWhichIsA("ProximityPrompt", true)
  local data = InteractableData[npcTop.Name]
  if prompt and data then
    prompt.Triggered:Connect(function(player)
      -- Your conversation driver:
      -- 1) Show data.response text/voice
      -- 2) Present data.options
      -- 3) Traverse until a terminal node (node.actions), then run each action with ctx
      --    for _, action in pairs(node.actions) do action({ player = player, npc = npcTop }) end
    end)
  end
end
```

> Your real binder will use your UI and traversal logic; this is only to illustrate how the mapping by `npcTop.Name` works.

---

## Extending

* **Conditions**: gate options based on inventory, quest state, or attributes.
* **Dynamic text**: interpolate player name, counts, timers, etc.
* **Multi-stage conversations**: compose trees with shared sub-nodes.
* **Audio**: extend `voice` to include SFX, lip-sync metadata, or subtitles.
* **Analytics**: log chosen options to tweak writing & reward pacing.

## Troubleshooting

* **No dialogue on prompt**: check the top model has the `"InteractableNPC"` tag and that the key exists in `NPCData.Interactable`.
* **Silent terminal**: ensure leaf nodes include `actions` (at least `require(Actions.nothing)`).
* **Wrong NPC data**: confirm the **top model’s `Name` matches** the key under `Interactable[...]`.
* **Radius not respected**: verify you placed Parts under `NPC/Zones` and your binder reads them.

## License

Add your preferred license (e.g., MIT).

## Credits

Built by **Reuvi**. Thanks to the Roblox dev community for patterns on data-driven dialogue and clean server hooks.
