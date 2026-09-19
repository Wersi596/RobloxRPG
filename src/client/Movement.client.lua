local uis = game:GetService("UserInputService")
local rs = game:GetService("RunService")
local player = game.Players.LocalPlayer

-- === KONFIGURACJA ===
local NORMAL_SPEED = 16
local SPRINT_SPEED = 32
local CLIMB_SPEED = 20
local CLIMB_RAY_LENGTH = 2.5 

-- === STAN GRACZA ===
local isClimbing = false
local climbVelocityModifier = nil
local climbAttachment = nil

-- === KLAWISZE ===
uis.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.LeftShift then
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = SPRINT_SPEED
        end
    end
    if input.KeyCode == Enum.KeyCode.C then
        isClimbing = true
    end
end)

uis.InputEnded:Connect(function(input, gp)
    if input.KeyCode == Enum.KeyCode.LeftShift then
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = NORMAL_SPEED
        end
    end
    if input.KeyCode == Enum.KeyCode.C then
        isClimbing = false
    end
end)

-- === LOGIKA WSPINACZKI ===
rs.RenderStepped:Connect(function()
    local char = player.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end

    if not climbVelocityModifier then
        climbAttachment = hrp:FindFirstChild("ClimbAttachment") or Instance.new("Attachment", hrp)
        climbAttachment.Name = "ClimbAttachment"
        
        climbVelocityModifier = hrp:FindFirstChild("ClimbVelocity") or Instance.new("LinearVelocity", hrp)
        climbVelocityModifier.Name = "ClimbVelocity"
        climbVelocityModifier.Attachment0 = climbAttachment
        climbVelocityModifier.MaxForce = 100000
        climbVelocityModifier.Enabled = false
    end

    if isClimbing then
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {char}
        rayParams.FilterType = Enum.RaycastFilterType.Exclude

        local rayOrigin = hrp.Position
        local rayDirection = hrp.CFrame.LookVector * CLIMB_RAY_LENGTH
        local hit = workspace:Raycast(rayOrigin, rayDirection, rayParams)

        if hit then
            climbVelocityModifier.Enabled = true
            climbVelocityModifier.VectorVelocity = Vector3.new(0, CLIMB_SPEED, 0) + (hrp.CFrame.LookVector * 5)
        else
            climbVelocityModifier.Enabled = false
        end
    else
        if climbVelocityModifier then
            climbVelocityModifier.Enabled = false
        end
    end
end)

player.CharacterAdded:Connect(function()
    climbVelocityModifier = nil
    climbAttachment = nil
    isClimbing = false
end)