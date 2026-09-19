local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local uis = game:GetService("UserInputService")
local rs = game:GetService("RunService")
local tweenService = game:GetService("TweenService")

local gold = 0
local klasy = {
	lumberjack = {exp = 0, level = 1, baseTime = 3, color = Color3.fromRGB(50, 200, 50), emoji = "🌳", displayName = "Lumberjack"},
	miner = {exp = 0, level = 1, baseTime = 4, color = Color3.fromRGB(200, 50, 50), emoji = "⛏️", displayName = "Miner"},
	sand = {exp = 0, level = 1, baseTime = 2, color = Color3.fromRGB(220, 220, 100), emoji = "⏳", displayName = "Sand Miner"}
}
local function wymaganyExp(lvl) return 10 + (lvl - 1) * 5 end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RpgGui"
screenGui.ResetOnSpawn = false
local frameContainer = Instance.new("Frame", screenGui)
frameContainer.Size = UDim2.new(0, 260, 0, 180)
frameContainer.Position = UDim2.new(0, 20, 1, -200)
frameContainer.BackgroundTransparency = 1
local listLayout = Instance.new("UIListLayout", frameContainer)
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

local paski = {}
local function stworzPasekStatow(nazwaId, info, order)
	local pFrame = Instance.new("Frame", frameContainer)
	pFrame.Name = nazwaId .. "Frame"
	pFrame.Size = UDim2.new(1, 0, 0, 35)
	pFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	pFrame.BorderSizePixel = 2
	pFrame.BorderColor3 = info.color or Color3.fromRGB(150, 150, 150)
	pFrame.LayoutOrder = order
	local label = Instance.new("TextLabel", pFrame)
	label.Name = nazwaId .. "Label"
	label.Size = UDim2.new(1, -10, 1, -6)
	label.Position = UDim2.new(0, 10, 0, 3)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextXAlignment = Enum.TextXAlignment.Left
	local expFill = Instance.new("Frame", pFrame)
	expFill.Name = "ExpFill"
	expFill.Size = UDim2.new(0, 0, 0, 3)
	expFill.Position = UDim2.new(0, 0, 1, -3)
	expFill.BackgroundColor3 = info.color or Color3.fromRGB(150, 150, 150)
	expFill.BorderSizePixel = 0
	paski[nazwaId] = {frame = pFrame, label = label, expFill = expFill}
end
stworzPasekStatow("gold", {color = Color3.fromRGB(255, 215, 0)}, 0)
stworzPasekStatow("lumberjack", klasy.lumberjack, 1)
stworzPasekStatow("miner", klasy.miner, 2)
stworzPasekStatow("sand", klasy.sand, 3)

local function aktualizujUI()
	paski.gold.label.Text = "💰 Gold: " .. gold
	paski.gold.expFill.Size = UDim2.new(1,0,0,3)
	for nazwaId, info in pairs(klasy) do
		local reqExp = wymaganyExp(info.level)
		paski[nazwaId].label.Text = info.emoji .. " " .. info.displayName .. " Lv." .. info.level .. " (" .. info.exp .. "/" .. reqExp .. ")"
		paski[nazwaId].expFill.Size = UDim2.new(math.clamp(info.exp / reqExp, 0, 1), 0, 0, 3)
	end
end
aktualizujUI()
screenGui.Parent = player:WaitForChild("PlayerGui")

local isMining = false
local currentTarget = nil
local mineType = ""
local mineTime = 0
local originalSize = nil

local function getResourceType(targetModel)
	if not targetModel then return nil end
	local modelName = targetModel.Name
	local tool = (player.Character and player.Character:FindFirstChildOfClass("Tool"))
	local toolName = tool and tool.Name or ""
	if modelName == "ChoppableTree" and toolName == "BajkowaSiekiera" then return "lumberjack"
	elseif modelName == "MinableStone" and toolName == "Kilof" then return "miner"
	elseif modelName == "DiggableSand" and toolName == "Lopata" then return "sand"
	end
	return nil
end

uis.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local char = player.Character
		if not char then return end
		local tool = char:FindFirstChildOfClass("Tool")
		if not tool then return end
		local target = mouse.Target
		if target and target.Parent then
			local targetModel = target.Parent
			local tType = getResourceType(targetModel)
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if tType and hrp and (hrp.Position - target.Position).Magnitude <= 18 then
				if targetModel:FindFirstChild("TimerGui") and not targetModel.TimerGui.Enabled then
					isMining = true
					currentTarget = targetModel
					mineType = tType
					mineTime = 0
					currentTarget.ProgressGui.Enabled = true
					if mineType == "miner" then originalSize = currentTarget.PrimaryPart.Size
					elseif mineType == "sand" then originalSize = currentTarget.PilePart.Size end
				end
			end
		end
	end
end)

uis.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isMining = false
		if currentTarget then currentTarget.ProgressGui.Enabled = false end
		if mineType == "miner" and originalSize and currentTarget then currentTarget.PrimaryPart.Size = originalSize
		elseif mineType == "sand" and originalSize and currentTarget then currentTarget.PilePart.Size = originalSize end
		currentTarget = nil
		mineType = ""
	end
end)

rs.RenderStepped:Connect(function(dt)
	local char = player.Character
	if not char then return end
	local tool = char:FindFirstChildOfClass("Tool")
	if not tool then
		if isMining and currentTarget then currentTarget.ProgressGui.Enabled = false isMining = false currentTarget = nil end
		return
	end

	if isMining and currentTarget then
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp or (hrp.Position - currentTarget.PrimaryPart.Position).Magnitude > 20 then isMining = false currentTarget.ProgressGui.Enabled = false currentTarget = nil tool.Grip = CFrame.new(0, 0, 0) return end
		
		if mineType == "lumberjack" then tool.Grip = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(math.sin(os.clock() * 15) * 45), 0, 0)
		elseif mineType == "miner" then tool.Grip = CFrame.new(0, 0, math.sin(os.clock() * 20) * 0.3) * CFrame.Angles(0, 0, math.rad(-90))
		elseif mineType == "sand" then tool.Grip = CFrame.new(0, 0, math.sin(os.clock() * 10) * 0.5) end
		
		mineTime = mineTime + dt
		local infoKL = klasy[mineType]
		local hasteModifier = math.max(0.1, infoKL.baseTime * (1 - ((infoKL.level - 1) * 0.05)))
		
		local progProg = math.clamp(mineTime / hasteModifier, 0, 1)
		currentTarget.ProgressGui.Frame.Fill.Size = UDim2.new(progProg, 0, 1, 0)
		
		if mineType == "miner" and originalSize then currentTarget.PrimaryPart.Size = originalSize * (1 - (progProg * 0.8))
		elseif mineType == "sand" and originalSize then currentTarget.PilePart.Size = originalSize * (1 - (progProg * 0.9)) end
		
		if mineTime >= hasteModifier then
			isMining = false
			local target = currentTarget
			local mTypeCompletion = mineType
			currentTarget = nil
			tool.Grip = CFrame.new(0, 0, 0)
			target.ProgressGui.Enabled = false
			
			gold = gold + 1
			local infoKLCompletion = klasy[mTypeCompletion]
			infoKLCompletion.exp = infoKLCompletion.exp + 1
			
			if infoKLCompletion.exp >= wymaganyExp(infoKLCompletion.level) then
				infoKLCompletion.exp = infoKLCompletion.exp - wymaganyExp(infoKLCompletion.level)
				infoKLCompletion.level = infoKLCompletion.level + 1
				local frameUI = paski[mTypeCompletion].frame
				frameUI.BackgroundColor3 = Color3.new(1,1,1)
				tweenService:Create(frameUI, TweenInfo.new(0.5), {BackgroundColor3 = Color3.fromRGB(30,30,30)}):Play()
			end
			aktualizujUI()
			
			for _, czesc in ipairs(target:GetChildren()) do if czesc:IsA("BasePart") then czesc.Transparency = 1 czesc.CanCollide = false end end
			target.TimerGui.Enabled = true
			coroutine.wrap(function()
				local textL = target.TimerGui.TextLabel
				for i = 10, 1, -1 do textL.Text = "Respawn: " .. i .. "s" task.wait(1) end
				target.TimerGui.Enabled = false
				if target.Name == "MinableStone" and originalSize then target.PrimaryPart.Size = originalSize
				elseif target.Name == "DiggableSand" and originalSize then target.PilePart.Size = originalSize end
				for _, czesc in ipairs(target:GetChildren()) do if czesc:IsA("BasePart") then czesc.Transparency = 0 czesc.CanCollide = (czesc.Name ~= "PilePart") end end
			end)()
		end
	else
		if tool then tool.Grip = CFrame.new(0, 0, 0) end
	end
end)