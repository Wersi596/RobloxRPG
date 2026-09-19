task.wait(2)
local terrain = workspace.Terrain
terrain:Clear()

local MAP_SIZE = 40 -- Wracamy do porządnej wielkości mapy
local CELL_SIZE = 4
local SEED = math.random(1, 100000)
local WATER_LEVEL = -12

print("VS Code: Rozpoczynam błyskawiczne generowanie...")

for x = -MAP_SIZE, MAP_SIZE do
	for z = -MAP_SIZE, MAP_SIZE do
		local realX = x * CELL_SIZE
		local realZ = z * CELL_SIZE
		
		local heightNoise = math.noise(x * 0.015, SEED, z * 0.015)
		local surfaceY = math.floor((heightNoise * 80) / CELL_SIZE) * CELL_SIZE
		
		for y = -100, surfaceY, CELL_SIZE do
			local caveNoise = math.noise(x * 0.04, y * 0.04 + SEED, z * 0.04)
			if caveNoise < 0.25 then
				local mat = Enum.Material.Rock
				if y == surfaceY then
					if y <= WATER_LEVEL then mat = Enum.Material.Sand
					elseif y > 40 then mat = Enum.Material.Snow
					else mat = Enum.Material.Grass end
				elseif y > surfaceY - 12 and mat ~= Enum.Material.Sand then
					mat = Enum.Material.Dirt
				end
				terrain:FillBlock(CFrame.new(realX, y, realZ), Vector3.new(CELL_SIZE, CELL_SIZE, CELL_SIZE), mat)
			end
		end
		
		if surfaceY < WATER_LEVEL then
			for wy = surfaceY + CELL_SIZE, WATER_LEVEL, CELL_SIZE do
				terrain:FillBlock(CFrame.new(realX, wy, realZ), Vector3.new(CELL_SIZE, CELL_SIZE, CELL_SIZE), Enum.Material.Water)
			end
		end
	end
	-- Dajemy silnikowi oddech po wygenerowaniu CAŁEGO rzędu (81 kolumn naraz), a nie pojedynczej
	task.wait()
end

print("VS Code: Teren gotowy!")