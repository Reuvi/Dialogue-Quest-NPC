local Actions = game:GetService("ReplicatedStorage").NPCData.Actions

local Interactable = {}

--[[

Interactable NPC Setup Guide

1) Model NPC and put inside a Model named "NPC"

2) Put that "NPC" model inside another model with "-NPCS Distinguishable Name-" Also put in Folder "NPC"."Interact"

3) Tag the Top Model with "InteractableNPC"

4) Add a Non-Initialized ProximityPrompt Object inside NPC model's torso

4.5) Add Zones folder and then add part for radius.

5) Put NPC Data in ReplicatedStorage.NPCData.Interactable the example format below

note: Only add the ["actions"] if it is the last possible input value and you intend convo to close. If you have no intended actions that is okay, just make one will "require(Actions.exampleAction)", so it has something to detect. This exampleAction does nothing.

-exampleAction was changed to "nothing"

-also for those last options dont add options of response in them just a text and [actions]


]]--




--You can Add Voicelines if your game has them

Interactable["Example2"] = 
	{	
		["options"] = 
		{
			[1] = {
				--sound = Voice acted line of the player speaking
				text = "Tell me a joke",
				["options"] = 
				{
					[1] = {
						text = "Haha, that's funny!",
						["actions"] = 
						{
							[0] = require(Actions.nothing),
						}
					},
				},
				['response'] =
				{
					text = "Why don't scientists trust atoms? Because they make up everything!",
					voice = "rbxassetid://8974863112"
				}
			},

			[2] = {
				text = "Share a fun fact",
				["options"] = 
				{
					[1] = {
						text = "Wow, that's interesting!",
						["actions"] = 
						{
							[0] = require(Actions.nothing),
						}
					},
				},
				['response'] =
				{
					text = "Did you know that honey never spoils? Archaeologists have found pots of honey in ancient Egyptian tombs that are over 3,000 years old and still edible!",
					voice = "rbxassetid://8974863112"
				}
			},
		},

		['response'] =
		{
			text = "Hello there! How can I assist you today?",
			voice = "rbxassetid://8974863112"
		}
	}

return Interactable
