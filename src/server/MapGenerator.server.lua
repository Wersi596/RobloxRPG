local workspace = game:GetService("Workspace")

-- === USTAWIENIA SIATKI (OGROMNA MAPA) ===
local GRID_SIZE = 450 -- Prawie 5x większa powierzchnia
local CELL_SIZE = 6
local SEED = math.random(1, 100000)

-- === PALETA KOLORÓW ===
local MAT = Enum.Material.SmoothPlastic
local C_GRASS = Color3.fromRGB(118, 214, 73)
local C_FAIRY_GRASS = Color3.fromRGB(150, 230, 130) -- Jaśniejsza trawa dla baśniowego
local C_JUNGLE = Color3.fromRGB(60, 200, 40)
local C_SAND = Color3.fromRGB(235, 220, 160)
local C_SNOW = Color3.fromRGB(240, 245, 255)
local C_DIRT = Color3.fromRGB(140, 110, 80)
local C_STONE = Color3.fromRGB(110, 115, 120)
local C_WATER = Color3.fromRGB(60, 150, 220)
local C_ICE = Color3.fromRGB(180, 220, 255)

local C_TRUNK = Color3.fromRGB(90, 60, 30)
local C_PINE = Color3.fromRGB(40, 100, 40)
local C_CACTUS = Color3.fromRGB(50, 160, 50)

-- Kolory liści
local C_LEAVES = {Color3.fromRGB(70, 180, 40), Color3.fromRGB(90, 200, 50)}
local C_FAIRY_LEAVES = {Color3.fromRGB(255, 150, 200), Color3.fromRGB(255, 180, 220), Color3.fromRGB(255, 100, 150)}
local C_FLOWERS = {Color3.fromRGB(255, 50, 50), Color3.fromRGB(50, 50, 255), Color3.fromRGB(255, 255, 50), Color3.fromRGB(255, 100, 200)}

-- === FUNKCJE STRUKTUR ===
local function spawnTree(parent, x, y, z, biome)
	local rand = math.random(1, 100)
	local scale = 3
	if rand > 50 and rand <= 80 then scale = 6 elseif rand > 80 then scale = 12 end
	if biome == "Fairy" then scale = scale * 1.2 end -- Baśniowe drzewa są wyższe

	local trunk = Instance.new("Part")
	trunk.Size = Vector3.new(scale * 0.8, scale * 3, scale * 0.8)
	trunk.Position = Vector3.new(x, y + (trunk.Size.Y/2), z)
	trunk.Color = C_TRUNK trunk.Material = MAT trunk.Anchored = true trunk.Parent = parent

	local leaves = Instance.new("Part")
	leaves.Size = Vector3.new(scale * 3, scale * 3, scale * 3)
	leaves.Position = Vector3.new(x, y + trunk.Size.Y + (scale * 0.5), z)
	
	if biome == "Jungle" then leaves.Color = C_JUNGLE
	elseif biome == "Fairy" then leaves.Color = C_FAIRY_LEAVES[math.random(1, #C_FAIRY_LEAVES)]
	else leaves.Color = C_LEAVES[math.random(1, #C_LEAVES)] end
	
	leaves.Material = MAT leaves.Anchored = true leaves.Parent = parent
end

local function spawnPine(parent, x, y, z)
	local trunk = Instance.new("Part")
	trunk.Size = Vector3.new(2, 12, 2)
	trunk.Position = Vector3.new(x, y + 6, z)
	trunk.Color = C_TRUNK trunk.Material = MAT trunk.Anchored = true trunk.Parent = parent
	for i = 1, 4 do
		local w = 16 - (i * 3.5)
		local leaf = Instance.new("Part")
		leaf.Size = Vector3.new(w, 5, w)
		leaf.Position = Vector3.new(x, y + 4 + (i * 4), z)
		leaf.Color = C_PINE leaf.Material = MAT leaf.Anchored = true leaf.Parent = parent
	end
end

local function spawnCactus(parent, x, y, z)
	local height = math.random(8, 16)
	local main = Instance.new("Part")
	main.Size = Vector3.new(3, height, 3)
	main.Position = Vector3.new(x, y + (height/2), z)
	main.Color = C_CACTUS main.Material = MAT main.Anchored = true main.Parent = parent
	if math.random(1, 2) == 1 then
		local arm = Instance.new("Part")
		arm.Size = Vector3.new(6, 3, 3)
		arm.Position = Vector3.new(x + 2, y + (height*0.6), z)
		arm.Color = C_CACTUS arm.Material = MAT arm.Anchored = true arm.Parent = parent
	end
end

local function spawnBamboo(parent, x, y, z)
	local height = math.random(20, 35)
	local bamboo = Instance.new("Part")
	bamboo.Size = Vector3.new(2, height, 2)
	bamboo.Position = Vector3.new(x, y + (height/2), z)
	bamboo.Color = Color3.fromRGB(120, 220, 80) bamboo.Material = MAT bamboo.Anchored = true bamboo.Parent = parent
end

local function spawnFlower(parent, x, y, z)
	local s = math.random(1, 2) * 1.5
	local flower = Instance.new("Part")
	flower.Size = Vector3.new(s, s, s)
	flower.Position = Vector3.new(x + math.random(-2, 2), y + (s/2), z + math.random(-2, 2))
	flower.Color = C_FLOWERS[math.random(1, #C_FLOWERS)]
	flower.Material = MAT flower.Anchored = true flower.CanCollide = false flower.Parent = parent
end

local function spawnPyramid(parent, cX, y, cZ)
	local steps = 7 -- Wielkość piramidy
	for step = 0, steps - 1 do
		local radius = steps - step
		for px = -radius, radius do
			for pz = -radius, radius do
				-- Budujemy tylko ściany zewnętrzne (pusta w środku)
				local isEdge = (math.abs(px) == radius or math.abs(pz) == radius)
				-- Tworzymy drzwi na najniższych 3 poziomach
				local isDoor = (step < 3 and pz == radius and math.abs(px) <= 1)
				
				if isEdge and not isDoor then
					local p = Instance.new("Part")
					p.Size = Vector3.new(CELL_SIZE, CELL_SIZE, CELL_SIZE)
					p.Position = Vector3.new(cX + px*CELL_SIZE, y + (step*CELL_SIZE) + CELL_SIZE/2, cZ + pz*CELL_SIZE)
					p.Color = C_SAND p.Material = MAT p.Anchored = true p.Parent = parent
				end
			end
		end
	end
end

-- === GŁÓWNY GENERATOR ===
local function generateMap()
	local oldMap = workspace:FindFirstChild("GeneratedMap")
	if oldMap then oldMap:Destroy() end

	local mapFolder = Instance.new("Folder")
	mapFolder.Name = "GeneratedMap"
	mapFolder.Parent = workspace
	
	print("Budowanie gigantycznej mapy... Proszę czekać, to może potrwać do minuty!")

	for x = 1, GRID_SIZE do
		for z = 1, GRID_SIZE do
			local realX = (x * CELL_SIZE) - (GRID_SIZE * CELL_SIZE / 2)
			local realZ = (z * CELL_SIZE) - (GRID_SIZE * CELL_SIZE / 2)
			
			-- 1. GÓRY GRANICZNE (BARDZIEJ STROME)
			local distToEdge = math.min(x, GRID_SIZE - x, z, GRID_SIZE - z)
			local edgeLift = 0
			if distToEdge < 30 then
				edgeLift = math.pow(30 - distToEdge, 2.2) * 0.8 -- Wyższa potęga = stromsze góry
			end
			
			-- 2. SZUM PERLINA (WIĘKSZE BIOMY I STROMSZE GÓRKI)
			-- Zmniejszono mnożnik z 0.04 na 0.015 - to sprawia, że biomy są ogromne!
			local heightNoise = math.noise(x * 0.015, SEED, z * 0.015)
			local tempNoise = math.noise(x * 0.01, SEED + 100, z * 0.01)
			local moistNoise = math.noise(x * 0.01, SEED + 200, z * 0.01)
			local magicNoise = math.noise(x * 0.02, SEED + 300, z * 0.02) -- Decyduje o biomie Fairy
			
			local yOffset = math.floor(heightNoise * 45) + edgeLift -- Zwiększono amplitudę = bardziej strome góry w środku mapy
			local isMountain = edgeLift > 20 or yOffset > 60
			local isWater = yOffset < -15 and not isMountain
			
			-- 3. USTALANIE BIOMÓW
			local biome = "PlainsForest"
			local cellColor = C_GRASS
			
			if magicNoise > 0.4 then
				biome = "Fairy"
				cellColor = C_FAIRY_GRASS
			elseif tempNoise < -0.15 then
				biome = "Taiga"
				cellColor = C_SNOW
			elseif tempNoise > 0.15 then
				if moistNoise < 0 then biome = "Desert" cellColor = C_SAND
				else biome = "Jungle" cellColor = C_JUNGLE end
			else
				if moistNoise < -0.1 then biome = "PurePlains" cellColor = C_GRASS
				else biome = "PlainsForest" cellColor = C_GRASS end
			end

			-- Modyfikacje dla wzniesień i wody
			if isMountain then
				if yOffset > 110 then cellColor = C_SNOW else cellColor = C_STONE end
			elseif isWater then
				cellColor = (biome == "Taiga") and C_ICE or C_WATER
			end

			-- 4. BUDOWA PODŁOŻA
			local blockH = 100 + yOffset -- Grubsze podłoże
			local block = Instance.new("Part")
			block.Size = Vector3.new(CELL_SIZE, blockH, CELL_SIZE)
			block.Position = Vector3.new(realX, blockH/2 - 50, realZ)
			block.Color = cellColor block.Material = MAT block.Anchored = true block.Parent = mapFolder
			
			local topY = (blockH/2 - 50) + (blockH/2)

			-- 5. GENEROWANIE OBIEKTÓW
			if not isMountain and not isWater then
				local rand = math.random(1, 1000)
				
				if biome == "PlainsForest" then
					if rand <= 8 then spawnTree(mapFolder, realX, topY, realZ, biome) end -- Mniej drzew
					if math.random(1,100) <= 3 then spawnFlower(mapFolder, realX, topY, realZ) end
				
				elseif biome == "Fairy" then
					if rand <= 4 then spawnTree(mapFolder, realX, topY, realZ, biome) end -- 50% rzadsze niż Forest
					if math.random(1,100) <= 15 then spawnFlower(mapFolder, realX, topY, realZ) end -- Dużo kwiatów!
					
				elseif biome == "PurePlains" then
					if rand <= 1 then spawnTree(mapFolder, realX, topY, realZ, biome) end
					if math.random(1,100) <= 5 then spawnFlower(mapFolder, realX, topY, realZ) end
				
				elseif biome == "Taiga" then
					if rand <= 15 then spawnPine(mapFolder, realX, topY, realZ) end
				
				elseif biome == "Jungle" then
					if rand <= 20 then spawnBamboo(mapFolder, realX, topY, realZ) 
					elseif rand <= 30 then spawnTree(mapFolder, realX, topY, realZ, biome) end
					if math.random(1,100) <= 8 then spawnFlower(mapFolder, realX, topY, realZ) end
				
				elseif biome == "Desert" then
					if rand <= 6 then spawnCactus(mapFolder, realX, topY, realZ)
					-- Piramida (zabezpieczenie przed krawędziami)
					elseif rand == 1000 and x > 20 and z > 20 and x < GRID_SIZE-20 and z < GRID_SIZE-20 then
						spawnPyramid(mapFolder, realX, topY, realZ)
					end
				end
			end
		end
		-- Zapobieganie crashom przy tak wielkiej mapie (wymagane!)
		if x % 10 == 0 then task.wait() end
	end
	print("Sukces! Gigantyczna mapa została wygenerowana.")
end

generateMap()