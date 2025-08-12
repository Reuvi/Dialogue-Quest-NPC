local NonInteractable = {}

--[[

Non Interactable NPC Setup Guide

1) Model NPC and put inside a Model named "NPC"

2) Put that "NPC" model inside another model with "-NPCS Distinguishable Name-" Also put in Folder "NPC"."NonInteract"

3) Tag the Top Model with "NonInteractableNPC"

4) Add a "Zones" folder into the Top Model

5) Within the "Zones" folder put a bunch of Opac 1, No Collide Anchored Parts anywhere, when a player enters their radius the NPC will activate

6) Put NPC Data in ReplicatedStorage.NPCData.NonInteractable in this format

-Make sure to increase [IDX] starting from 0 Ex [0] [1] ...

NonInteractable["-TopModelName-"] = 
    {
        [-IDX-] = {
            text = "-CaptionsOfVoice-",
            voice = "-VoiceAsset-"

        },
    }

note: make sure the models "head" part is a direct first child of the model "NPC"

]]--




--You can Add Voicelines if your game has them

NonInteractable["Example"] = 
	{
		[0] = {
			text = "Black People are not Monkeys!",
			voice = "rbxassetid://8974863112"

		},
		[1] = {
			text = "Buy Stuff in the Shop",
			voice = "rbxassetid://8974863112"

		},
	}


return NonInteractable
