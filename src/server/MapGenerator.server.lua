task.wait(2)
local terrain = workspace.Terrain
terrain:Clear()

local mapFolder = workspace:FindFirstChild("MapParts")
if mapFolder then mapFolder:Destroy() end
mapFolder = Instance.new("Folder")
mapFolder.Name = "MapParts"
mapFolder.Parent = workspace

local decorFolder = Instance.new("Folder")
decorFolder.Name = "Decorations"
decorFolder.Parent = mapFolder

local status = Instance.new("Hint", workspace)
status.Text = "Generowanie stabilnego świata bez jaskiń..."

local MAP_SIZE = 100 
local CELL_SIZE = 4
local SEED = math.random(1, 100000)
local WATER_LEVEL = -4 

local function spawnModel(type, x, y, z)
	if type == "Tree" or type == "FairyTree" or type == "TaigaTree" then
		local trunk = Instance.new("Part")
		trunk.Size = Vector3.new(2, 12, 2)
		trunk.Position = Vector3.new(x, y + 6, z)
		trunk.BrickColor = BrickColor.new("Pine Cone")
		trunk.Material = Enum.Material.SmoothPlastic
		trunk.Anchored = true
		trunk.Parent = decorFolder
		
		local leaves = Instance.new("Part")
		leaves.Shape = Enum.PartType.Ball
		leaves.Size = Vector3.new(14, 14, 14)
		leaves.Position = Vector3.new(x, y + 14, z)
		if type == "FairyTree" then
			leaves.BrickColor = BrickColor.new("Carnation pink")
		elseif type == "TaigaTree" then
			leaves.BrickColor = BrickColor.new("White")
		else
			leaves.BrickColor = BrickColor.new("Shamrock")
		end
		leaves.Material = Enum.Material.SmoothPlastic
		leaves.Anchored = true
		leaves.Parent = decorFolder

	elseif type == "Bamboo" then
		local stalk = Instance.new("Part")
		stalk.Size = Vector3.new(1.5, math.random(12, 24), 1.5)
		stalk.Position = Vector3.new(x, y + (stalk.Size.Y/2), z)
		stalk.BrickColor = BrickColor.new("Lime green")
		stalk.Material = Enum.Material.SmoothPlastic
		stalk.Anchored = true
		stalk.Parent = decorFolder

	elseif type == "Cactus" then
		local cactus = Instance.new("Part")
		cactus.Size = Vector3.new(3, math.random(6, 12), 3)
		cactus.Position = Vector3.new(x, y + (cactus.Size.Y/2), z)
		cactus.BrickColor = BrickColor.new("Bright green")
		cactus.Material = Enum.Material.SmoothPlastic
		cactus.Anchored = true
		cactus.Parent = decorFolder

	elseif type == "Pyramid" then
		local baseSize = 24
		local currentY = y + 2
		while baseSize > 0 do
			local layer = Instance.new("Part")
			layer.Size = Vector3.new(baseSize, 4, baseSize)
			layer.Position = Vector3.new(x, currentY, z)
			layer.BrickColor = BrickColor.new("Deep orange")
			layer.Material = Enum.Material.SmoothPlastic
			layer.Anchored = true
			layer.Parent = decorFolder
			baseSize = baseSize - 4
			currentY = currentY + 4
		end
		
	elseif type == "Flower" then
		local flower = Instance.new("Part")
		flower.Size = Vector3.new(1.2, 1.2, 1.2)
		flower.Position = Vector3.new(x, y + 0.6, z)
		local colors = {"Bright red", "Bright yellow", "Magenta", "Cyan"}
		flower.BrickColor = BrickColor.new(colors[math.random(1, #colors)])
		flower.Material = Enum.Material.SmoothPlastic
		flower.Anchored = true
		flower.Parent = decorFolder
	end
end

local success, err = pcall(function()
	for x = -MAP_SIZE, MAP_SIZE do
		for z = -MAP_SIZE, MAP_SIZE do
			local realX = x * CELL_SIZE
			local realZ = z * CELL_SIZE
			
			local distFromCenter = math.sqrt(x*x + z*z)
			local isEdgeMountain = distFromCenter > MAP_SIZE * 0.85
			
			local baseHeight = math.noise(x * 0.015, SEED, z * 0.015) * 30
			
			if isEdgeMountain then
				local edge = (distFromCenter - (MAP_SIZE * 0.85)) / (MAP_SIZE * 0.15)
				baseHeight = baseHeight + (edge * edge * 150)
			end
			
			-- Zabezpieczenie: dno oceanu jest idealnie płaskie (1 klocek pod wodą)
			if baseHeight < WATER_LEVEL - CELL_SIZE and not isEdgeMountain then
				baseHeight = WATER_LEVEL - CELL_SIZE
			end
			
			local surfaceY = math.floor(baseHeight / CELL_SIZE) * CELL_SIZE
			
			local heatNoise = math.noise(x * 0.018, SEED + 1000, z * 0.018)
			local moistNoise = math.noise(x * 0.018, SEED + 2000, z * 0.018)
			
			-- Skrypt buduje tyko skorupę o grubości 4 klocków, chyba że to góry (wtedy murujemy do ziemi)
			local maxDepth = surfaceY - (CELL_SIZE * 3)
			if isEdgeMountain then maxDepth = -20 end
			
			for y = maxDepth, surfaceY, CELL_SIZE do
				local p = Instance.new("Part")
				p.Size = Vector3.new(CELL_SIZE, CELL_SIZE, CELL_SIZE)
				p.Position = Vector3.new(realX, y, realZ)
				p.Anchored = true
				p.Material = Enum.Material.SmoothPlastic
				
				if y == surfaceY then
					if isEdgeMountain or y > 60 then
						p.BrickColor = BrickColor.new("White") 
					elseif y <= WATER_LEVEL + CELL_SIZE then
						p.BrickColor = BrickColor.new("Pastel yellow") 
					else
						local randomChance = math.random()
						
						if heatNoise > 0.15 and moistNoise < -0.1 then
							p.BrickColor = BrickColor.new("Deep orange") 
							if randomChance < 0.01 then spawnModel("Cactus", realX, y, realZ)
							elseif randomChance < 0.0005 then spawnModel("Pyramid", realX, y, realZ) end
							
						elseif heatNoise > 0.15 and moistNoise >= -0.1 then
							p.BrickColor = BrickColor.new("Lime green") 
							if randomChance < 0.03 then spawnModel("Bamboo", realX, y, realZ) end
							
						elseif heatNoise < -0.15 then
							p.BrickColor = BrickColor.new("Pastel light blue") 
							if randomChance < 0.02 then spawnModel("TaigaTree", realX, y, realZ) end
							
						elseif heatNoise >= -0.15 and heatNoise <= 0.15 and moistNoise > 0.25 then
							p.BrickColor = BrickColor.new("Carnation pink") 
							if randomChance < 0.02 then spawnModel("FairyTree", realX, y, realZ) end
							
						else
							p.BrickColor = BrickColor.new("Bright green") 
							if moistNoise > 0 then
								if randomChance < 0.025 then spawnModel("Tree", realX, y, realZ) end
							else
								if randomChance < 0.04 then spawnModel("Flower", realX, y, realZ) end
							end
						end
					end
				else
					p.BrickColor = BrickColor.new("Dark stone grey") 
				end
				p.Parent = mapFolder
			end
			
			-- Generowanie jednokratkowej wody na płaskim dnie
			if surfaceY < WATER_LEVEL and not isEdgeMountain then
				terrain:FillBlock(CFrame.new(realX, WATER_LEVEL, realZ), Vector3.new(CELL_SIZE, CELL_SIZE, CELL_SIZE), Enum.Material.Water)
			end
		end
		if x % 2 == 0 then task.wait() end
		local percent = math.floor(((x + MAP_SIZE) / (MAP_SIZE * 2)) * 100)
		status.Text = "Budowanie litego terenu: " .. percent .. "%"
	end
end)

if not success then
	status.Text = "BŁĄD: " .. tostring(err)
else
	status.Text = "Generowanie zakończone!"
	task.wait(3)
	status:Destroy()
end