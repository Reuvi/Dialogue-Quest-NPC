local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local Utility = ReplicatedStorage.Utility
local Component = require(Utility.Component)
local Zone = require(Utility.ZonePlus)

local NPCData = require(ReplicatedStorage.NPCData.NonInteractable)

local NonIntNPC = Component.new({
	Tag = "NonInteractableNPC"
})


function NonIntNPC:Construct()
	self.Data = NPCData[self.Instance.Name]
	self.idx = 0
	self.TotalLines = #self.Data + 1 --I dont know why roblox length starts at 0
	self.head = self.Instance:FindFirstChild("NPC"):FindFirstChild("Head")
	
	--SetUpZone
	local zoneParent = self.Instance:FindFirstChild("Zones")
	if zoneParent == nil then
		zoneParent = self.Instance
	end
	self.zone = Zone.new(zoneParent)
	
	--SoundService
	self.sound = Instance.new("Sound", self.Instance)
	self.sound.EmitterSize = 5
	self.sound.Looped = false
	self.sound.Parent = self.Instance
end

function NonIntNPC:activated()
	--Bubble Text
	TextChatService:DisplayBubble(self.head, self.Data[self.idx].text)
	
	--Play Sound
	self.sound.SoundId = self.Data[self.idx].voice
	self.sound:Play()

	--Iterate Lines
	self.idx += 1
	self.idx %= self.TotalLines
end

function NonIntNPC:Start()
	self.zone.playerEntered:Connect(function(_player)
		--print(tostring(_player) .. " entered near the NPC " .. self.Instance.Name .. ".")
		self:activated()
	end)

end

return NonIntNPC
