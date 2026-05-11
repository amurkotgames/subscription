local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Настройки
local flySpeed = 50
local fastWalkSpeed = 100
local normalWalkSpeed = humanoid.WalkSpeed

-- Состояния
local isNoclipping = false
local isFlying = false
local isFast = false

local camera = workspace.CurrentCamera

---------------------------------------
-- 1. СКОРОСТЬ
---------------------------------------
local function toggleSpeed()
    isFast = not isFast
    humanoid.WalkSpeed = isFast and fastWalkSpeed or normalWalkSpeed
    print("Быстрый бег:", isFast)
end

---------------------------------------
-- 2. ПРОХОЖДЕНИЕ СКВОЗЬ СТЕНЫ (NOCLIP)
---------------------------------------
local function toggleNoclip()
    isNoclipping = not isNoclipping
    print("Noclip:", isNoclipping)
end

-- Обновляем коллизию каждый кадр физики
RunService.Stepped:Connect(function()
    if isNoclipping then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

---------------------------------------
-- 3. ПОЛЕТ (FLY)
---------------------------------------
local flyVelocity = nil
local flyGyro = nil

local function toggleFly()
    isFlying = not isFlying
    print("Полет:", isFlying)
    
    if isFlying then
        -- Отключаем стандартное падение и анимации
        humanoid.PlatformStand = true 
        
        -- Создаем векторы тяги и поворота
        flyVelocity = Instance.new("BodyVelocity")
        flyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flyVelocity.Velocity = Vector3.new(0, 0, 0)
        flyVelocity.Parent = rootPart

        flyGyro = Instance.new("BodyGyro")
        flyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        flyGyro.P = 10000
        flyGyro.CFrame = camera.CFrame
        flyGyro.Parent = rootPart

        -- Привязываем движение к камере
        RunService:BindToRenderStep("FlyLoop", Enum.RenderPriority.Camera.Value + 1, function()
            local moveDir = humanoid.MoveDirection
            -- Движемся туда, куда смотрит камера
            flyVelocity.Velocity = camera.CFrame:VectorToWorldSpace(moveDir) * flySpeed
            flyGyro.CFrame = camera.CFrame
        end)
    else
        -- Возвращаем все в норму
        humanoid.PlatformStand = false
        if flyVelocity then flyVelocity:Destroy() end
        if flyGyro then flyGyro:Destroy() end
        RunService:UnbindFromRenderStep("FlyLoop")
    end
end

---------------------------------------
-- 4. ТЕЛЕПОРТАЦИЯ
---------------------------------------
player.Chatted:Connect(function(message)
    local prefix = "/tp "
    if string.sub(message, 1, string.len(prefix)) == prefix then
        local targetName = string.sub(message, string.len(prefix) + 1)
        
        -- Ищем игрока (частичное совпадение имени не делаю для простоты, нужно вводить точно)
        local targetPlayer = Players:FindFirstChild(targetName)
        
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            -- Переносим нашего персонажа чуть выше головы цели
            rootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 4, 0)
            print("Телепортирован к", targetName)
        else
            warn("Игрок не найден или еще не заспавнился!")
        end
    end
end)

---------------------------------------
-- ПРИВЯЗКА КЛАВИШ
---------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    -- Игнорируем нажатия, если игрок пишет в чат
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Z then
        toggleSpeed()
    elseif input.KeyCode == Enum.KeyCode.X then
        toggleNoclip()
    elseif input.KeyCode == Enum.KeyCode.C then
        toggleFly()
    end
end)