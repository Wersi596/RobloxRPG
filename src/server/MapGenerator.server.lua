task.wait(2)
local terrain = workspace.Terrain
terrain:Clear()

-- Pasek postępu na górze ekranu
local status = Instance.new("Hint", workspace)
status.Text = "Przygotowanie generatora..."

local MAP_SIZE = 40
local CELL_SIZE = 4
local SEED = math.random(1, 100000)
local WATER_LEVEL = -12

-- pcall zabezpiecza przed crashem i pokaże błąd na ekranie
local success, err = pcall(function()
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
            
            -- Ulepszony oddech: wymusza ułamek sekundy przerwy co 2 wygenerowane kolumny (likwiduje crashe)
            if z % 2 == 0 then task.wait() end
        end
        
        -- Wyświetla procent ukończenia na żywo!
        local percent = math.floor(((x + MAP_SIZE) / (MAP_SIZE * 2)) * 100)
        status.Text = "Generowanie mapy: " .. percent .. "%"
    end
end)

if not success then
    status.Text = "BŁĄD KODU: " .. tostring(err)
else
    status.Text = "Generowanie w 100% zakończone!"
    task.wait(3)
    status:Destroy()
end