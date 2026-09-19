task.wait(2)
local terrain = workspace.Terrain
terrain:Clear()

local mapFolder = workspace:FindFirstChild("MapParts")
if mapFolder then mapFolder:Destroy() end
mapFolder = Instance.new("Folder")
mapFolder.Name = "MapParts"
mapFolder.Parent = workspace

local status = Instance.new("Hint", workspace)
status.Text = "Przywracanie stabilnej mapy..."

local MAP_SIZE = 75 -- Zmniejszona, optymalna wielkość
local CELL_SIZE = 4
local SEED = math.random(1, 100000)
local WATER_LEVEL = -12

local success, err = pcall(function()
    for x = -MAP_SIZE, MAP_SIZE do
        for z = -MAP_SIZE, MAP_SIZE do
            local realX = x * CELL_SIZE
            local realZ = z * CELL_SIZE
            
            local baseHeight = math.noise(x * 0.015, SEED, z * 0.015) * 40
            local distFromCenter = math.sqrt(x*x + z*z)
            local isEdgeMountain = distFromCenter > MAP_SIZE * 0.7
            
            -- Wypiętrzanie litych gór brzegowych
            if isEdgeMountain then
                local edge = (distFromCenter - (MAP_SIZE * 0.7)) / (MAP_SIZE * 0.3)
                baseHeight = baseHeight + (edge * edge * 200)
            end
            
            local surfaceY = math.floor(baseHeight / CELL_SIZE) * CELL_SIZE
            local maxDepth = math.max(-100, surfaceY - 40)
            
            -- Skala biomów ustalona na 0.005 (wielkie, spójne strefy)
            local heatNoise = math.noise(x * 0.005, SEED + 1000, z * 0.005)
            local moistNoise = math.noise(x * 0.005, SEED + 2000, z * 0.005)
            
            for y = maxDepth, surfaceY, CELL_SIZE do
                local caveNoise = math.noise(x * 0.04, y * 0.04 + SEED, z * 0.04)
                
                -- Jaskinie generują się pod ziemią, ale GÓRY BRZEGOWE są zawsze lite
                if caveNoise < 0.25 or isEdgeMountain then
                    local p = Instance.new("Part")
                    p.Size = Vector3.new(CELL_SIZE, CELL_SIZE, CELL_SIZE)
                    p.Position = Vector3.new(realX, y, realZ)
                    p.Anchored = true
                    p.Material = Enum.Material.SmoothPlastic
                    
                    if y == surfaceY then
                        -- Logika wielkich, spójnych biomów
                        if isEdgeMountain or y > 70 then
                            p.BrickColor = BrickColor.new("White") -- Ośnieżone granice
                        elseif y <= WATER_LEVEL + 4 then
                            p.BrickColor = BrickColor.new("Pastel yellow") -- Plaża
                        else
                            if heatNoise > 0.15 and moistNoise < -0.1 then
                                p.BrickColor = BrickColor.new("Deep orange") -- Pustynia
                            elseif heatNoise > 0.15 and moistNoise >= -0.1 then
                                p.BrickColor = BrickColor.new("Lime green") -- Dżungla
                            elseif heatNoise < -0.15 then
                                p.BrickColor = BrickColor.new("Pastel light blue") -- Tajga
                            elseif heatNoise >= -0.15 and heatNoise <= 0.15 and moistNoise > 0.25 then
                                p.BrickColor = BrickColor.new("Carnation pink") -- Baśniowy
                            else
                                p.BrickColor = BrickColor.new("Bright green") -- Równiny/Las
                            end
                        end
                    else
                        p.BrickColor = BrickColor.new("Dark stone grey") -- Skała w jaskiniach
                    end
                    p.Parent = mapFolder
                end
            end
            
            -- Woda Smooth Terrain
            if surfaceY < WATER_LEVEL then
                for wy = surfaceY + CELL_SIZE, WATER_LEVEL, CELL_SIZE do
                    terrain:FillBlock(CFrame.new(realX, wy, realZ), Vector3.new(CELL_SIZE, CELL_SIZE, CELL_SIZE), Enum.Material.Water)
                end
            end
        end
        if x % 3 == 0 then task.wait() end
        local percent = math.floor(((x + MAP_SIZE) / (MAP_SIZE * 2)) * 100)
        status.Text = "Generowanie terenu: " .. percent .. "%"
    end
end)

if not success then
    status.Text = "BŁĄD: " .. tostring(err)
else
    status.Text = "Teren gotowy!"
    task.wait(3)
    status:Destroy()
end