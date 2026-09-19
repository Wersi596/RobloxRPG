task.wait(2)
local terrain = workspace.Terrain
terrain:Clear()

local mapFolder = workspace:FindFirstChild("MapParts")
if mapFolder then mapFolder:Destroy() end
mapFolder = Instance.new("Folder")
mapFolder.Name = "MapParts"
mapFolder.Parent = workspace

local status = Instance.new("Hint", workspace)
status.Text = "Generowanie plastelinowego RPG..."

local MAP_SIZE = 150 -- Powiększamy mapę do 300x300 bloków
local CELL_SIZE = 4
local SEED = math.random(1, 100000)
local WATER_LEVEL = -12

local success, err = pcall(function()
    for x = -MAP_SIZE, MAP_SIZE do
        for z = -MAP_SIZE, MAP_SIZE do
            local realX = x * CELL_SIZE
            local realZ = z * CELL_SIZE
            
            -- Podstawowa wysokość terenu
            local baseHeight = math.noise(x * 0.015, SEED, z * 0.015) * 40
            
            -- AGRESYWNA MASKA KRAWĘDZI (Potężne góry na granicach)
            local distFromCenter = math.sqrt(x*x + z*z)
            if distFromCenter > MAP_SIZE * 0.7 then
                local edge = (distFromCenter - (MAP_SIZE * 0.7)) / (MAP_SIZE * 0.3)
                baseHeight = baseHeight + (edge * edge * 200) -- Wypiętrza teren o 200 studów do góry!
            end
            
            local surfaceY = math.floor(baseHeight / CELL_SIZE) * CELL_SIZE
            local maxDepth = math.max(-100, surfaceY - 40)
            
            -- SZUMY BIOMÓW (Temperatura i Wilgotność)
            local heatNoise = math.noise(x * 0.02, SEED + 1000, z * 0.02)
            local moistNoise = math.noise(x * 0.02, SEED + 2000, z * 0.02)
            
            for y = maxDepth, surfaceY, CELL_SIZE do
                local caveNoise = math.noise(x * 0.04, y * 0.04 + SEED, z * 0.04)
                if caveNoise < 0.25 then
                    local p = Instance.new("Part")
                    p.Size = Vector3.new(CELL_SIZE, CELL_SIZE, CELL_SIZE)
                    p.Position = Vector3.new(realX, y, realZ)
                    p.Anchored = true
                    
                    -- KLUCZ DO BAJKOWEGO STYLU: Tylko gładki plastik!
                    p.Material = Enum.Material.SmoothPlastic
                    
                    if y == surfaceY then
                        -- LOGIKA 5 BIOMÓW NA POWIERZCHNI
                        if distFromCenter > MAP_SIZE * 0.85 or y > 70 then
                            p.BrickColor = BrickColor.new("White") -- Ośnieżone góry brzegowe i szczyty
                        elseif y <= WATER_LEVEL + 4 then
                            p.BrickColor = BrickColor.new("Pastel yellow") -- Plaża
                        else
                            if heatNoise > 0.2 and moistNoise < -0.1 then
                                p.BrickColor = BrickColor.new("Deep orange") -- Pustynia
                            elseif heatNoise > 0.2 and moistNoise >= -0.1 then
                                p.BrickColor = BrickColor.new("Lime green") -- Dżungla
                            elseif heatNoise < -0.2 then
                                p.BrickColor = BrickColor.new("Pastel light blue") -- Zimowa Tajga
                            elseif heatNoise >= -0.2 and heatNoise <= 0.2 and moistNoise > 0.3 then
                                p.BrickColor = BrickColor.new("Carnation pink") -- Bajkowy (Fairy)
                            else
                                p.BrickColor = BrickColor.new("Bright green") -- Klasyczne Równiny/Las
                            end
                        end
                    else
                        -- Podziemia (Jaskinie)
                        p.BrickColor = BrickColor.new("Dark stone grey")
                    end
                    p.Parent = mapFolder
                end
            end
            
            -- WODA HYBRYDOWA (Tylko Smooth Terrain w dziurach)
            if surfaceY < WATER_LEVEL then
                for wy = surfaceY + CELL_SIZE, WATER_LEVEL, CELL_SIZE do
                    terrain:FillBlock(CFrame.new(realX, wy, realZ), Vector3.new(CELL_SIZE, CELL_SIZE, CELL_SIZE), Enum.Material.Water)
                end
            end
        end
        -- Oddech dla silnika
        if x % 3 == 0 then task.wait() end
        local percent = math.floor(((x + MAP_SIZE) / (MAP_SIZE * 2)) * 100)
        status.Text = "Generowanie świata: " .. percent .. "%"
    end
end)

if not success then
    status.Text = "BŁĄD: " .. tostring(err)
else
    status.Text = "Mapa gotowa!"
    task.wait(3)
    status:Destroy()
end