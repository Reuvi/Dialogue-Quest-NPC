local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")
local Utility = ReplicatedStorage.Utility
local Promise = require(Utility.Promise)
local Component = require(Utility.Component)
local Zone = require(Utility.ZonePlus)
local player = game:GetService("Players").LocalPlayer


local NPCData = require(ReplicatedStorage.NPCData.Interactable)
local ui = player.PlayerGui.BetterNPCBox
local uiFrame = ui:WaitForChild("Frame")
local optionsList = uiFrame:WaitForChild("Frame")
local response = uiFrame:WaitForChild("NPCText")
local cloneOption = ui:WaitForChild("PlayerResponse")
local uiName = uiFrame:WaitForChild("NPCName")

local IntNPC = Component.new({
	Tag = "InteractableNPC"
})



function IntNPC:Construct()
	self.Data = NPCData[self.Instance.Name]

	--Clean Previous Runnting Coroutines
	self.endOptions = false

	--Traversing NPC Data
	self.active = false
	self.options = nil
	self.response = nil
	self.actions = nil
	self.inputSignal = nil
	self.name = self.Instance.Name

	--SoundService
	self.sound = Instance.new("Sound", self.Instance)
	self.sound.EmitterSize = 5
	self.sound.Looped = false
	self.sound.Parent = self.Instance

	self.clickSound = Instance.new("Sound", self.Instance)
	self.clickSound.EmitterSize = 5
	self.clickSound.Looped = false
	self.clickSound.Parent = self.Instance
	self.clickSound.SoundId = "rbxassetid://3779053277"
	self.clickSound.Volume = 0.1

	--Setup Proximity
	task.wait(2)
	self.ProximityPrompt = self.Instance:FindFirstChild("NPC"):FindFirstChild("Torso"):FindFirstChild("ProximityPrompt")
	self.ProximityPrompt.HoldDuration = 0
	self.ProximityPrompt.RequiresLineOfSight = false
	self.ProximityPrompt.UIOffset = Vector2.new(0, 0)

	--UI anims
	self.delay = 0.02
	self.animateTextRunning = false

	--UI Buttons
	self.buttonSignals = {}

	--SetUpZone
	local zoneParent = self.Instance:FindFirstChild("Zones")
	if zoneParent == nil then
		zoneParent = self.Instance
	end
	self.zone = Zone.new(zoneParent)
	self.zoneSignal = nil

end

function IntNPC:animateText(gui, text, delay)
	self.animateTextRunning = true

	coroutine.wrap(function()
		gui.Text = ""
		for i = 1, #text do
			if not self.animateTextRunning then
				gui.Text = text
				break
			end
			if gui then
				gui.Text = string.sub(text, 1, i)
				wait(delay)
			else
				break
			end
			if gui:IsA("TextButton") then
				gui.Size = UDim2.new(0, gui.TextBounds.X + 10, 0, gui.TextBounds.Y + 10)
			end
		end
	end)()
end

function IntNPC:getLastKey(t)
	local lastKey = nil
	for k, _ in pairs(t) do
		if type(k) == "number" and (lastKey == nil or k > lastKey) then
			lastKey = k
		end
	end
	return lastKey
end


function IntNPC:updateGui()

	--First Clean Old Gui Options and Destroy old Events
	for _, gui in next, optionsList:GetChildren() do
		if gui:IsA("TextButton") then
			self.buttonSignals[gui.Name]:Disconnect()
			gui:Destroy()
		end
	end

	--Turn On Animating (All Corutines should have broken)
	self.animateTextRunning = true

	self.buttonSignals = {}

	uiName.Text = self.name
	self:animateText(response, self.response.text, self.delay)

	for key, option in next, self.options do
		local gui = cloneOption:Clone()
		local text = "" .. key .. ": " .. option.text .. "."
		gui.Text = ""
		gui.Parent = optionsList
		gui.Visible = true
		gui.Name = tostring(key)
		self:animateText(gui,text, self.delay)
	end

	--SetupButtonsBeforeQuit
	for _, gui in next, optionsList:GetChildren() do
		if gui:IsA("TextButton") then

			--Click Event
			self.buttonSignals[gui.Name] = gui.MouseButton1Click:Connect(function()
				self:flipActive()
				self:selectOptionAsync(tonumber(gui.Name))
					:andThen(function()
						return self:flipActiveAsync()
					end)
					:catch(function(error)
						warn("Error occurred: " .. tostring(error))
					end)
			end)

			--Hover Enter Event
			self.buttonSignals[gui.Name .. "hovEnt"] = {
				enterConnection = gui.MouseEnter:Connect(function()
					gui.TextStrokeColor3 = Color3.new(0.329412, 0.329412, 0.329412)
				end)
			}

			--Hover Exit Event
			self.buttonSignals[gui.Name .. "hovEx"] = {
				leaveConnection = gui.MouseLeave:Connect(function()
					gui.TextStrokeColor3 = Color3.new(0, 0, 0)
				end)
			}
		end
	end

	--Add the basic Quit Gui Element on Bottom
	local gui = cloneOption:Clone()
	gui.Name = "Quit"
	gui.Text = ""
	gui.Parent = optionsList
	gui.Visible = true
	self:animateText(gui, "X: Leave.", self.delay)

	--Add Quit Event
	self.buttonSignals[gui.Name] = gui.MouseButton1Click:Connect(function()
		self.clickSound.SoundId = "rbxassetid://3779053277"
		self.clickSound:Play()
		local gui = optionsList:WaitForChild("Quit")
		gui.TextStrokeColor3 = Color3.new(255, 170, 0)
		task.wait(0.2)
		self:close()
		return
	end)

	--Hover Quit Enter Event
	self.buttonSignals[gui.Name .. "hovEnt"] = {
		enterConnection = gui.MouseEnter:Connect(function()
			gui.TextStrokeColor3 = Color3.new(0.329412, 0.329412, 0.329412)
		end)
	}

	--Hover Quit Exit Event
	self.buttonSignals[gui.Name .. "hovEx"] = {
		leaveConnection = gui.MouseLeave:Connect(function()
			gui.TextStrokeColor3 = Color3.new(0, 0, 0)
		end)
	}

	--Plays Voice for Player
	self.sound.SoundId = self.response.voice
	self.sound:Play()

end

function IntNPC:setData(option)

	self.options = option["options"]
	self.response = option["response"]
	self.actions = option["actions"] or nil

	self:updateGui()
end

function IntNPC:selectOption(opcode)

	--Turn Off Animating and Stop Voice for next option
	self.animateTextRunning = false
	self.sound:Stop()

	local gui = optionsList:WaitForChild(tostring(opcode))

	gui.TextStrokeColor3 = Color3.new(255, 170, 0)
	task.wait(0.1)
	local option = self.options[opcode]

	--If player Sound Set it others its click
	if option.voice then
		self.clickSound.Volume = 1
		self.clickSound.SoundId = option.voice
		self.clickSound:Play()
		self.clickSound.Ended:Wait()
		if self.endOptions then
			self.endOptions = false
			return
		end
	else
		self.clickSound.Volume = 0.1
		self.clickSound.SoundId = "rbxassetid://3779053277"
		self.clickSound:Play()
	end

	if option["actions"] then

		for _, action in next, option["actions"] do
			action:action()
		end

		self:close()
	else
		self:setData(option) 
	end
end

function IntNPC:reset()

	--First Clean Old Gui Options and Destroy Button Events
	for _, gui in next, optionsList:GetChildren() do
		if gui:IsA("TextButton") then
			self.buttonSignals[gui.Name]:Disconnect()
			gui:Destroy()
		end
	end
	self.buttonSignals = {}

	--Resets
	self.options = nil
	self.response = nil
	self.actions = nil
	if self.inputSignal then
		self.inputSignal:Disconnect()
		self.inputSignal = nil
	end
	if self.zoneSignal then
		self.zoneSignal:Disconnect()
	end
	self.zoneSignal = nil
	task.wait(0.4)
	self.ProximityPrompt.Enabled = true
	self.clickSound.SoundId = "rbxassetid://3779053277"
	self.sound.SoundId = ""
end

--CloseUI+Reset
function IntNPC:close()

	--End All Sounds Previous playing
	if self.sound.IsPlaying then
		self.sound:Stop()
	end

	if self.clickSound.IsPlaying and self.clickSound.soundId ~= "rbxassetid://3779053277" then
		self.clickSound:Stop()
		self.endOptions = true
	end


	--Stop Text
	self.animateTextRunning = false
	ui.Enabled = false

	self:reset()
end

function IntNPC:flipActive()
	self.active = not self.active
end

function IntNPC:selectOptionAsync(numberPressed)
	return Promise.new(function(resolve, reject)
		self:selectOption(numberPressed)
		resolve()
	end)
end

function IntNPC:flipActiveAsync()
	return Promise.new(function(resolve, reject)
		self:flipActive()
		resolve()
	end)
end

function IntNPC:activated()
	self.clickSound:Play()
	self:setData(self.Data)
	ui.Enabled = true

	self.zoneSignal = self.zone.playerExited:Connect(function(_player)
		self:close()
		return
	end)


	self.inputSignal = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if not self.active then
			if input.KeyCode == Enum.KeyCode.X then
				self.clickSound.SoundId = "rbxassetid://3779053277"
				self.clickSound:Play()
				local gui = optionsList:WaitForChild("Quit")
				gui.TextStrokeColor3 = Color3.new(255, 170, 0)
				task.wait(0.2)
				self:close()
				return
			end

			local numberPressed = nil

			--Check if a number pressed
			if input.KeyCode == Enum.KeyCode.Zero then
				numberPressed = 0
			elseif input.KeyCode == Enum.KeyCode.One then
				numberPressed = 1
			elseif input.KeyCode == Enum.KeyCode.Two then
				numberPressed = 2
			elseif input.KeyCode == Enum.KeyCode.Three then
				numberPressed = 3
			elseif input.KeyCode == Enum.KeyCode.Four then
				numberPressed = 4
			elseif input.KeyCode == Enum.KeyCode.Five then
				numberPressed = 5
			elseif input.KeyCode == Enum.KeyCode.Six then
				numberPressed = 6
			elseif input.KeyCode == Enum.KeyCode.Seven then
				numberPressed = 7
			elseif input.KeyCode == Enum.KeyCode.Eight then
				numberPressed = 8
			elseif input.KeyCode == Enum.KeyCode.Nine then
				numberPressed = 9
			end

			if numberPressed ~= nil and self:getLastKey(self.options) >= numberPressed then
				self:flipActive()
				self:selectOptionAsync(numberPressed)
					:andThen(function()
						return self:flipActiveAsync()
					end)
					:catch(function(error)
						warn("Error occurred: " .. tostring(error))
					end)
			end
		end
	end)
end

function IntNPC:Start()

	self.zone.playerEntered:Connect(function(_player)
		--print(tostring(_player) .. " entered near the NPC " .. self.Instance.Name .. ".")
	end)

	self.ProximityPrompt.Triggered:connect(function()
		self.ProximityPrompt.Enabled = false
		self:activated()
	end)

end

return IntNPC