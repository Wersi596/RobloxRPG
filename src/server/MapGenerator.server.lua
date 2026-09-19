task.wait(2)
local terrain = workspace.Terrain
terrain:Clear()

-- Czyszczenie i tworzenie folderu na klocki
local mapFolder = workspace:FindFirstChild("MapParts")
if mapFolder then mapFolder:Destroy() end
mapFolder = Instance.new("Folder")
mapFolder.Name = "MapParts"
mapFolder.Parent = workspace

local status = Instance.new("Hint", workspace)
status.Text = "Przygotowanie hybrydowego generatora..."

local MAP_SIZE = 100 -- Testowy rozmiar (800x800 studów)
local CELL_SIZE = 4
local SEED = math.random(1, 100000)
local WATER_LEVEL = -12

local success, err = pcall(function()
    for x = -MAP_SIZE, MAP_SIZE do
        for z = -MAP_SIZE, MAP_SIZE do
            local realX = x * CELL_SIZE
            local realZ = z * CELL_SIZE
            
            -- Maska Krawędzi: Wypiętrzanie gór na brzegach mapy
            local distFromCenter = math.sqrt(x*x + z*z)
            local maxDist = MAP_SIZE
            local edgeMultiplier = 1
            
            if distFromCenter > maxDist * 0.6 then
                -- Im bliżej krawędzi, tym potężniejszy mnożnik wysokości
                local edgeFactor = (distFromCenter - (maxDist * 0.6)) / (maxDist * 0.4)
                edgeMultiplier = 1 + (edgeFactor ^ 3) * 6
            end
            
            local heightNoise = math.noise(x * 0.015, SEED, z * 0.015)
            -- Aplikujemy mnożnik krawędzi, aby stworzyć naturalny pierścień gór
            local surfaceY = math.floor(((heightNoise * 50) * edgeMultiplier) / CELL_SIZE) * CELL_SIZE
            
            -- Optymalizacja klocków: Generujemy jaskinie tylko do 60 klocków w dół,
            -- aby nie zabić pamięci komputera milionami niewidocznych elementów.
            local maxDepth = math.max(-120, surfaceY - 60)
            
            for y = maxDepth, surfaceY, CELL_SIZE do
                local caveNoise = math.noise(x * 0.04, y * 0.04 + SEED, z * 0.04)
                if caveNoise < 0.25 then
                    local p = Instance.new("Part")
                    p.Size = Vector3.new(CELL_SIZE, CELL_SIZE, CELL_SIZE)
                    p.Position = Vector3.new(realX, y, realZ)
                    p.Anchored = true
                    p.TopSurface = Enum.SurfaceType.Smooth
                    p.BottomSurface = Enum.SurfaceType.Smooth
                    
                    -- Pokolorowanie klocków w stylu bajkowym
                    if y == surfaceY then
                        if y <= WATER_LEVEL + 4 then
                            p.BrickColor = BrickColor.new("Sand yellow")
                            p.Material = Enum.Material.Sand
                        elseif y > 60 then
                            p.BrickColor = BrickColor.new("White")
                            p.Material = Enum.Material.Snow
                        elseif y > 30 then
                            p.BrickColor = BrickColor.new("Dark stone grey")
                            p.Material = Enum.Material.Slate
                        else
                            p.BrickColor = BrickColor.new("Bright green")
                            p.Material = Enum.Material.Grass
                        end
                    else
                        p.BrickColor = BrickColor.new("Dark stone grey")
                        p.Material = Enum.Material.Slate
                    end
                    p.Parent = mapFolder
                end
            end
            
            -- Wlewanie fizycznej wody Smooth Terrain pomiędzy klocki piasku
            if surfaceY < WATER_LEVEL then
                for wy = surfaceY + CELL_SIZE, WATER_LEVEL, CELL_SIZE do
                    terrain:FillBlock(CFrame.new(realX, wy, realZ), Vector3.new(CELL_SIZE, CELL_SIZE, CELL_SIZE), Enum.Material.Water)
                end
            end
        end
        
        -- Wymuszony oddech dla silnika zapobiegający crashom (co 2 rzędy)
        if x % 2 == 0 then task.wait() end
        
        local percent = math.floor(((x + MAP_SIZE) / (MAP_SIZE * 2)) * 100)
        status.Text = "Budowanie klockowego świata: " .. percent .. "%"
    end
end)

if not success then
    status.Text = "BŁĄD KODU: " .. tostring(err)
else
    status.Text = "Generowanie w 100% zakończone!"
    task.wait(3)
    status:Destroy()
end