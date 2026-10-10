-- ===== АВТОПЕРЕЗАПУСК ПОСЛЕ ТЕЛЕПОРТА =====
local SCRIPT_URL = "https://raw.githubusercontent.com/Milk1way-Mr/argoshubbik/refs/heads/main/multiargos.lua"

if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Защита от двойного запуска в одном плейсе
local env = (getgenv and getgenv()) or _G
if env.__ARGOS_RUNNING then
    return
end
env.__ARGOS_RUNNING = true

-- Ставим этот же скрипт в очередь на следующий телепорт
local qot = (syn and syn.queue_on_teleport)
    or queue_on_teleport
    or (fluxus and fluxus.queue_on_teleport)
    or queueonteleport

if qot then
    local ok, err = pcall(function()
        qot('loadstring(game:HttpGet("' .. SCRIPT_URL .. '"))()')
    end)
    if not ok then
        warn("Не удалось поставить очередь телепорта: " .. tostring(err))
    end
else
    warn("Эксплойт не поддерживает queue_on_teleport")
end
-- ===== КОНЕЦ БЛОКА, ДАЛЬШЕ ВАШ ОСНОВНОЙ КОД =====

--                ARGOS ULTIMATE ALL-IN-ONE (RECURSIVE FIXED v28)
-- =================================================================

local rawScript = [==[
repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer

-- Защита от двойного запуска на одном сервере
if _G.ArgosRunning then return end
_G.ArgosRunning = true

-- Авто-перезапуск для последующих телепортаций
local function setupNextTeleport()
    local qOT = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport) or queueonteleport
    if qOT then
        pcall(function()
            local currentCode = getgenv and getgenv().ArgosSource
            if currentCode then
                qOT(currentCode)
            end
        end)
    end
end

-- Регистрируем с небольшой задержкой для стабильности API
task.spawn(function()
    task.wait(1.5)
    setupNextTeleport()
end)

game:GetService("Players").LocalPlayer.OnTeleport:Connect(function()
    setupNextTeleport()
end)

-- Функция гарантированного получения HumanoidRootPart
local function getHRP(maxWait)
    maxWait = maxWait or 10
    local startTime = tick()
    local player = game:GetService("Players").LocalPlayer
    
    while tick() - startTime < maxWait do
        local char = player.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then return char, hrp end
        end
        task.wait(0.2)
    end
    return nil, nil
end

-- Настройки по умолчанию
_G.HeadSize = 25
_G.Disabled = false       -- false = Hitbox Changer включен
_G.EspEnabled = true     -- ВКЛ/ВЫКЛ ESP
_G.ShowEspText = true   -- Показывать имя/HP/расстояние

local autoTpEnabled = false
local tpConnection = nil
local wasAutoTpActiveBeforeEvent = false

local flyNoclipEnabled = false
local flySpeed = 50
local scriptKilled = false

-- Сервисы
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- =================================================================
--                   СИСТЕМА БЕЗОПАСНОСТИ (AUTO-KILL)
-- =================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ArgosUltimateGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Highlight = Instance.new("Highlight")
Highlight.Name = "ArgosEspHighlight"
Highlight.FillColor = Color3.fromRGB(255, 30, 70)
Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
Highlight.FillTransparency = 0.5
Highlight.OutlineTransparency = 0

local BillboardGui = Instance.new("BillboardGui")
BillboardGui.Name = "ArgosEspText"
BillboardGui.AlwaysOnTop = true
BillboardGui.Size = UDim2.new(0, 200, 0, 50)
BillboardGui.StudsOffset = Vector3.new(0, 3.5, 0)

local bodyVelocity = nil
local bodyGyro = nil

local function stopAutoTP()
    autoTpEnabled = false
    if tpConnection then
        tpConnection:Disconnect()
        tpConnection = nil
    end
end

local function stopFlyNoclip()
    flyNoclipEnabled = false
    if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
    if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
end

local function killScript()
    if scriptKilled then return end
    scriptKilled = true
    _G.Disabled = true
    _G.EspEnabled = false
    _G.ArgosRunning = nil
    
    stopAutoTP()
    stopFlyNoclip()
    
    if Highlight then Highlight:Destroy() end
    if BillboardGui then BillboardGui:Destroy() end
    if ScreenGui then ScreenGui:Destroy() end
    
    -- Сброс хитбокса
    local argos = workspace:FindFirstChild("Argos")
    if argos then
        local hrp = argos:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Size = Vector3.new(2, 2, 1)
            hrp.Transparency = 1
            hrp.CanCollide = true
        end
    end
end

-- Проверка при запуске и отслеживание новых игроков
local function checkPlayersAndKill()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            killScript()
            return true
        end
    end
    return false
end

Players.PlayerAdded:Connect(function(plr)
    if plr ~= LocalPlayer then
        killScript()
    end
end)

if checkPlayersAndKill() then
    return
end

-- =================================================================
--                             GUI СОЗДАНИЕ
-- =================================================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 310, 0, 440)
MainFrame.Position = UDim2.new(0, 20, 0.5, -220)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(45, 45, 60)
UIStroke.Thickness = 1.5
UIStroke.Parent = MainFrame

-- Шапка (Header)
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 45)
Header.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 10)
HeaderCorner.Parent = Header

local HeaderFix = Instance.new("Frame")
HeaderFix.Size = UDim2.new(1, 0, 0, 10)
HeaderFix.Position = UDim2.new(0, 0, 1, -10)
HeaderFix.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
HeaderFix.BorderSizePixel = 0
HeaderFix.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 0, 25)
Title.Position = UDim2.new(0, 10, 0, 4)
Title.BackgroundTransparency = 1
Title.Text = "ARGOS HUB"
Title.TextColor3 = Color3.fromRGB(0, 170, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(1, -20, 0, 15)
SubTitle.Position = UDim2.new(0, 10, 0, 25)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "Нажми [B] чтобы скрыть меню"
SubTitle.TextColor3 = Color3.fromRGB(120, 120, 140)
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextSize = 10
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.Parent = Header

-- Разделительная линия
local Line = Instance.new("Frame")
Line.Size = UDim2.new(1, -20, 0, 1)
Line.Position = UDim2.new(0, 10, 0, 45)
Line.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
Line.BorderSizePixel = 0
Line.Parent = MainFrame

-- УВЕЛИЧЕННЫЙ СЧЕТЧИК ИГРОКОВ
local PlayersCounter = Instance.new("TextLabel")
PlayersCounter.Size = UDim2.new(1, -20, 0, 24)
PlayersCounter.Position = UDim2.new(0, 10, 0, 50)
PlayersCounter.BackgroundTransparency = 1
PlayersCounter.TextColor3 = Color3.fromRGB(0, 210, 255)
PlayersCounter.Font = Enum.Font.GothamBold
PlayersCounter.TextSize = 30
PlayersCounter.TextXAlignment = Enum.TextXAlignment.Left
PlayersCounter.Parent = MainFrame

local alertThread = nil

local function updatePlayerCount(newPlayerJoined)
    local current = #Players:GetPlayers()
    local max = Players.MaxPlayers

    if newPlayerJoined then
        PlayersCounter.Text = "👥  Онлайн: " .. current .. " / " .. max .. "  ⚠️ [НОВЫЙ ИГРОК!]"
        PlayersCounter.TextColor3 = Color3.fromRGB(255, 60, 60)
        
        if alertThread then task.cancel(alertThread) end
        alertThread = task.delay(3, function()
            if not scriptKilled then
                PlayersCounter.Text = "👥  Онлайн: " .. #Players:GetPlayers() .. " / " .. Players.MaxPlayers
                PlayersCounter.TextColor3 = Color3.fromRGB(0, 210, 255)
            end
        end)
    else
        PlayersCounter.Text = "👥  Онлайн: " .. current .. " / " .. max
        PlayersCounter.TextColor3 = Color3.fromRGB(0, 210, 255)
    end
end

updatePlayerCount(false)

Players.PlayerRemoving:Connect(function()
    if not scriptKilled then
        updatePlayerCount(false)
    end
end)

-- Статус Hitbox
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 18)
StatusLabel.Position = UDim2.new(0, 10, 0, 76)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "ХИТБОКС: РАБОТАЕТ [N]"
StatusLabel.TextColor3 = Color3.fromRGB(0, 230, 140)
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = MainFrame

-- Вспомогательная функция для стилизации кнопок
local function createStyledButton(name, text, positionY, color)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(1, -20, 0, 36)
    btn.Position = UDim2.new(0, 10, 0, positionY)
    btn.BackgroundColor3 = color
    btn.Font = Enum.Font.GothamBold
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 11
    btn.AutoButtonColor = true
    btn.Parent = MainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    return btn
end

-- Ползунок Hitbox
local SliderContainer = Instance.new("Frame")
SliderContainer.Size = UDim2.new(1, -20, 0, 45)
SliderContainer.Position = UDim2.new(0, 10, 0, 98)
SliderContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 34)
SliderContainer.BorderSizePixel = 0
SliderContainer.Parent = MainFrame

local SliderCorner = Instance.new("UICorner")
SliderCorner.CornerRadius = UDim.new(0, 6)
SliderCorner.Parent = SliderContainer

local SliderTitle = Instance.new("TextLabel")
SliderTitle.Size = UDim2.new(1, -15, 0, 18)
SliderTitle.Position = UDim2.new(0, 10, 0, 4)
SliderTitle.BackgroundTransparency = 1
SliderTitle.Text = "Размер хитбокса:"
SliderTitle.TextColor3 = Color3.fromRGB(160, 160, 180)
SliderTitle.Font = Enum.Font.GothamMedium
SliderTitle.TextSize = 10
SliderTitle.TextXAlignment = Enum.TextXAlignment.Left
SliderTitle.Parent = SliderContainer

local SliderBar = Instance.new("Frame")
SliderBar.Size = UDim2.new(1, -65, 0, 4)
SliderBar.Position = UDim2.new(0, 10, 0, 28)
SliderBar.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
SliderBar.BorderSizePixel = 0
SliderBar.Parent = SliderContainer

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(0.12, 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
SliderFill.BorderSizePixel = 0
SliderFill.Parent = SliderBar

local SliderFillCorner = Instance.new("UICorner")
SliderFillCorner.CornerRadius = UDim.new(1, 0)
SliderFillCorner.Parent = SliderFill

local SliderButton = Instance.new("TextButton")
SliderButton.Size = UDim2.new(0, 12, 0, 12)
SliderButton.Position = UDim2.new(1, -6, 0.5, -6)
SliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SliderButton.Text = ""
SliderButton.Parent = SliderFill

local SliderBtnCorner = Instance.new("UICorner")
SliderBtnCorner.CornerRadius = UDim.new(1, 0)
SliderBtnCorner.Parent = SliderButton

local SliderValueText = Instance.new("TextLabel")
SliderValueText.Size = UDim2.new(0, 40, 0, 20)
SliderValueText.Position = UDim2.new(1, -45, 0, 20)
SliderValueText.BackgroundTransparency = 1
SliderValueText.Text = tostring(_G.HeadSize)
SliderValueText.TextColor3 = Color3.fromRGB(0, 170, 255)
SliderValueText.Font = Enum.Font.GothamBold
SliderValueText.TextSize = 12
SliderValueText.Parent = SliderContainer

-- Кнопки функционала
local EspToggleBtn = createStyledButton("EspBtn", "ESP: ВКЛЮЧЕН", 150, Color3.fromRGB(35, 110, 75))
local EspTextToggleBtn = createStyledButton("EspTextBtn", "ИНФО ESP (HP/Дистанция): ВКЛ", 196, Color3.fromRGB(35, 110, 75))
local TPButton = createStyledButton("TPBtn", "АВТО-ТП ПОД БОССА: ВЫКЛ [T]", 242, Color3.fromRGB(120, 45, 45))
local FlyBtn = createStyledButton("FlyBtn", "FLY + NOCLIP: ВЫКЛ [X]", 288, Color3.fromRGB(120, 45, 45))

-- Дополнительный футер
local Footer = Instance.new("Frame")
Footer.Size = UDim2.new(1, -20, 0, 50)
Footer.Position = UDim2.new(0, 10, 0, 375)
Footer.BackgroundColor3 = Color3.fromRGB(25, 25, 34)
Footer.BorderSizePixel = 0
Footer.Parent = MainFrame

local FooterCorner = Instance.new("UICorner")
FooterCorner.CornerRadius = UDim.new(0, 6)
FooterCorner.Parent = Footer

local FooterText = Instance.new("TextLabel")
FooterText.Size = UDim2.new(1, -10, 1, 0)
FooterText.Position = UDim2.new(0, 10, 0, 0)
FooterText.BackgroundTransparency = 1
FooterText.Text = "Статус: Готов к бою\nЦель: Argos Boss"
FooterText.TextColor3 = Color3.fromRGB(130, 130, 150)
FooterText.Font = Enum.Font.GothamMedium
FooterText.TextSize = 10
FooterText.TextXAlignment = Enum.TextXAlignment.Left
FooterText.Parent = Footer

-- =================================================================
--                     ЛОГИКА ПОЛЗУНКА (SLIDER)
-- =================================================================
local dragging = false
SliderButton.MouseButton1Down:Connect(function() dragging = true end)
UserInputService.InputEnded:Connect(function(input) 
    if input.UserInputType == Enum.UserInputType.MouseButton1 then 
        dragging = false 
    end 
end)

UserInputService.InputChanged:Connect(function(input)
    if scriptKilled then return end
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local mousePos = input.Position.X
        local barPos = SliderBar.AbsolutePosition.X
        local barWidth = SliderBar.AbsoluteSize.X
        local percentage = math.clamp((mousePos - barPos) / barWidth, 0, 1)
        
        SliderFill.Size = UDim2.new(percentage, 0, 1, 0)
        _G.HeadSize = math.round(2 + (percentage * 198))
        SliderValueText.Text = tostring(_G.HeadSize)
    end
end)

-- =================================================================
--                         ESP ОБЪЕКТЫ
-- =================================================================
local EspText = Instance.new("TextLabel")
EspText.Size = UDim2.new(1, 0, 1, 0)
EspText.BackgroundTransparency = 1
EspText.TextColor3 = Color3.fromRGB(255, 60, 60)
EspText.TextStrokeTransparency = 0
EspText.Font = Enum.Font.GothamBold
EspText.TextSize = 13
EspText.Parent = BillboardGui

-- Переключатели ESP
EspToggleBtn.MouseButton1Click:Connect(function()
    if scriptKilled then return end
    _G.EspEnabled = not _G.EspEnabled
    if _G.EspEnabled then
        EspToggleBtn.Text = "ESP: ВКЛЮЧЕН"
        EspToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 110, 75)
    else
        EspToggleBtn.Text = "ESP: ВЫКЛЮЧЕН"
        EspToggleBtn.BackgroundColor3 = Color3.fromRGB(120, 45, 45)
    end
end)

EspTextToggleBtn.MouseButton1Click:Connect(function()
    if scriptKilled then return end
    _G.ShowEspText = not _G.ShowEspText
    if _G.ShowEspText then
        EspTextToggleBtn.Text = "ИНФО ESP (HP/Дистанция): ВКЛ"
        EspTextToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 110, 75)
    else
        EspTextToggleBtn.Text = "ИНФО ESP (HP/Дистанция): ВЫКЛ"
        EspTextToggleBtn.BackgroundColor3 = Color3.fromRGB(120, 45, 45)
    end
end)

-- =================================================================
--                       АВТО-ТЕЛЕПОРТ ПОД БОССА
-- =================================================================
local function findArgos()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:lower():find("argos") then
            local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or obj:FindFirstChild("Head")
            if hrp then
                return obj, hrp
            end
        end
    end
    return nil, nil
end

local function startAutoTP()
    if scriptKilled then return end
    autoTpEnabled = true
    TPButton.Text = "АВТО-ТП ПОД БОССА: ВКЛ [T]"
    TPButton.BackgroundColor3 = Color3.fromRGB(35, 110, 75)
    
    if tpConnection then tpConnection:Disconnect() end
    
    tpConnection = RunService.Heartbeat:Connect(function()
        if scriptKilled or not autoTpEnabled then return end
        
        local char, myHrp = getHRP(1)
        if not myHrp then return end
        
        local argosModel, argosHrp = findArgos()
        if argosModel and argosHrp then
            local downOffset = 13
            local backOffset = 0
            
            local targetPosition = (argosHrp.CFrame * CFrame.new(0, -downOffset, backOffset)).Position
            myHrp.AssemblyLinearVelocity = Vector3.zero
            myHrp.AssemblyAngularVelocity = Vector3.zero
            myHrp.CFrame = CFrame.new(targetPosition) * CFrame.Angles(math.rad(90), 0, 0)
        end
    end)
end

local function toggleAutoTP()
    if scriptKilled then return end
    if autoTpEnabled then
        wasAutoTpActiveBeforeEvent = false
        stopAutoTP()
        TPButton.Text = "АВТО-ТП ПОД БОССА: ВЫКЛ [T]"
        TPButton.BackgroundColor3 = Color3.fromRGB(120, 45, 45)
    else
        wasAutoTpActiveBeforeEvent = true
        startAutoTP()
    end
end

TPButton.MouseButton1Click:Connect(toggleAutoTP)

-- =================================================================
--                     FLY + NOCLIP ЛОГИКА [X]
-- =================================================================
local function toggleFlyNoclip()
    if scriptKilled then return end
    flyNoclipEnabled = not flyNoclipEnabled
    
    if flyNoclipEnabled then
        FlyBtn.Text = "FLY + NOCLIP: ВКЛ [X]"
        FlyBtn.BackgroundColor3 = Color3.fromRGB(35, 110, 75)
        
        local char, hrp = getHRP(2)
        if not hrp then return end
        
        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        bodyVelocity.Parent = hrp

        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        bodyGyro.CFrame = hrp.CFrame
        bodyGyro.Parent = hrp
    else
        FlyBtn.Text = "FLY + NOCLIP: ВЫКЛ [X]"
        FlyBtn.BackgroundColor3 = Color3.fromRGB(120, 45, 45)
        
        stopFlyNoclip()
    end
end

FlyBtn.MouseButton1Click:Connect(toggleFlyNoclip)

RunService.Stepped:Connect(function()
    if scriptKilled then return end
    if flyNoclipEnabled then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
            
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp and bodyVelocity and bodyGyro then
                local moveDir = Vector3.new()
                
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end

                if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end

                bodyVelocity.Velocity = moveDir * flySpeed
                bodyGyro.CFrame = Camera.CFrame
            end
        end
    end
end)

-- =================================================================
--                     СБРОС И ГОРЯЧИЕ КЛАВИШИ
-- =================================================================
local function resetArgosHitbox()
    local argos = workspace:FindFirstChild("Argos")
    if argos then
        local hrp = argos:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Size = Vector3.new(2, 2, 1)
            hrp.Transparency = 1
            hrp.CanCollide = true
        end
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if scriptKilled or gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.B then
        MainFrame.Visible = not MainFrame.Visible
    end
    
    if input.KeyCode == Enum.KeyCode.N then
        _G.Disabled = not _G.Disabled
        if _G.Disabled then
            StatusLabel.Text = "ХИТБОКС: ВЫКЛЮЧЕН [N]"
            StatusLabel.TextColor3 = Color3.fromRGB(235, 70, 70)
            resetArgosHitbox()
        else
            StatusLabel.Text = "ХИТБОКС: РАБОТАЕТ [N]"
            StatusLabel.TextColor3 = Color3.fromRGB(0, 230, 140)
        end
    end

    if input.KeyCode == Enum.KeyCode.T then
        toggleAutoTP()
    end

    if input.KeyCode == Enum.KeyCode.X then
        toggleFlyNoclip()
    end
end)

-- =================================================================
--               ОСНОВНОЙ ЦИКЛ ОБНОВЛЕНИЯ (RENDER STEPPED)
-- =================================================================
RunService.RenderStepped:Connect(function()
    if scriptKilled then return end
    local argos = workspace:FindFirstChild("Argos")
    
    if not _G.Disabled and argos then
        local hrp = argos:FindFirstChild("HumanoidRootPart")
        local humanoid = argos:FindFirstChildOfClass("Humanoid")
        
        if hrp then
            hrp.Size = Vector3.new(_G.HeadSize, _G.HeadSize, _G.HeadSize)
            hrp.Transparency = 0.7
            hrp.BrickColor = BrickColor.new("Really blue")
            hrp.Material = Enum.Material.Neon
            hrp.CanCollide = false
        end
        
        if _G.EspEnabled then
            Highlight.Parent = argos
            Highlight.Enabled = true
        else
            Highlight.Enabled = false
        end
        
        if _G.EspEnabled and _G.ShowEspText and hrp then
            BillboardGui.Parent = hrp
            BillboardGui.Enabled = true
            
            local dist = 0
            local char, myHrp = getHRP(0.1)
            if myHrp then
                dist = math.round((myHrp.Position - hrp.Position).Magnitude)
            end
            
            local hpText = "HP: N/A"
            if humanoid then
                hpText = "HP: " .. math.round(humanoid.Health) .. "/" .. math.round(humanoid.MaxHealth)
            end
            
            EspText.Text = "[ ARGOS BOSS ]\n" .. hpText .. "\nДистанция: " .. dist .. "m"
        else
            BillboardGui.Enabled = false
        end
    else
        Highlight.Enabled = false
        BillboardGui.Enabled = false
    end
end)

-- =================================================================
--         АВТО-ПОДЪЕМ / УКЛОНЕНИЕ ПРИ ИВЕНТАХ (CHARGED SPEAR & EXORCISM)
-- =================================================================
task.spawn(function()
    local isLifted = false
    local liftTimerThread = nil
    local hoverVelocity = nil

    local eventConfigs = {
        ["charged_spear_impact"] = { up = 300, left = 300, duration = 5 },
        ["exorcism"]             = { up = 200, left = 300, duration = 10 }
    }

    local function getSoundEvent()
        local current = ReplicatedStorage
        local path = {"rbxts_include", "node_modules", "@rbxts", "remo", "src", "container", "effects.sound.play"}
        for _, name in ipairs(path) do
            current = current:WaitForChild(name, 5)
            if not current then return nil end
        end
        return current
    end

    local soundEvent = getSoundEvent()
    if soundEvent then
        soundEvent.OnClientEvent:Connect(function(...)
            if scriptKilled then return end
            local args = {...}
            local activeConfig = nil
            local matchedEventName = nil

            for _, arg in ipairs(args) do
                if type(arg) == "string" then
                    for soundName, config in pairs(eventConfigs) do
                        if arg:find(soundName) then
                            activeConfig = config
                            matchedEventName = soundName
                            break
                        end
                    end
                end
                if activeConfig then break end
            end

            if activeConfig then
                if not isLifted then
                    wasAutoTpActiveBeforeEvent = autoTpEnabled
                end

                if autoTpEnabled then
                    stopAutoTP()
                    wasAutoTpActiveBeforeEvent = true
                end

                local char, hrp = getHRP(2)
                if not hrp then return end

                if not isLifted then
                    isLifted = true
                    
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.CFrame = (hrp.CFrame + Vector3.new(0, activeConfig.up, 0)) * CFrame.new(-activeConfig.left, 0, 0)
                    
                    -- Копье: второй аналогичный телепорт через 1 секунду
                    if matchedEventName == "charged_spear_impact" then
                        task.delay(1, function()
                            if scriptKilled or not isLifted then return end
                            local _, currentHrp = getHRP(2)
                            if currentHrp then
                                currentHrp.AssemblyLinearVelocity = Vector3.zero
                                currentHrp.CFrame = (currentHrp.CFrame + Vector3.new(0, activeConfig.up, 0)) * CFrame.new(-activeConfig.left, 0, 0)
                            end
                        end)
                    end

                    hoverVelocity = Instance.new("BodyVelocity")
                    hoverVelocity.Velocity = Vector3.new(0, 0, 0)
                    hoverVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                    hoverVelocity.Parent = hrp
                end

                if liftTimerThread then
                    task.cancel(liftTimerThread)
                    liftTimerThread = nil
                end

                liftTimerThread = task.delay(activeConfig.duration, function()
                    if scriptKilled then return end
                    local currentChar, currentHrp = getHRP(2)

                    if matchedEventName == "exorcism" then
                        -- Экзорцизм: спуск вниз на 100 и вправо на 100 на 1 секунду
                        if currentHrp then
                            currentHrp.AssemblyLinearVelocity = Vector3.zero
                            currentHrp.CFrame = (currentHrp.CFrame - Vector3.new(0, 100, 0)) * CFrame.new(100, 0, 0)
                        end

                        task.wait(1)

                        if hoverVelocity then
                            hoverVelocity:Destroy()
                            hoverVelocity = nil
                        end

                        isLifted = false
                        liftTimerThread = nil

                        -- Включаем функцию клавиши T
                        if not autoTpEnabled then
                            startAutoTP()
                        end
                    else
                        -- Копье (5 секунд)
                        if hoverVelocity then
                            hoverVelocity:Destroy()
                            hoverVelocity = nil
                        end

                        if currentHrp then
                            currentHrp.AssemblyLinearVelocity = Vector3.zero
                        end

                        if wasAutoTpActiveBeforeEvent then
                            startAutoTP()
                        end

                        isLifted = false
                        liftTimerThread = nil
                    end
                end)
            end
        end)
    end
end)

-- =================================================================
--         АВТО-ПРОЖАТИЕ ПРОБЕЛА ПРИ КАТСЦЕНАХ (CUTSCENE SKIP)
-- =================================================================
task.spawn(function()
    local function getCutsceneSkipEvent()
        local current = ReplicatedStorage
        local path = {"rbxts_include", "node_modules", "@rbxts", "remo", "src", "container", "ui.cutscene.setSkip"}
        for _, name in ipairs(path) do
            current = current:WaitForChild(name, 5)
            if not current then return nil end
        end
        return current
    end

    local skipEvent = getCutsceneSkipEvent()
    if skipEvent then
        skipEvent.OnClientEvent:Connect(function(...)
            if scriptKilled then return end
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end)
    end
end)

-- =================================================================
--            АВТО-ПРОХОЖДЕНИЕ QTE ИВЕНТОВ (ARGOS & SPACE MASH)
-- =================================================================
task.spawn(function()
    local function pressKey(keyCode)
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
        task.wait(0.02)
        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
    end

    local function getSequenceEvent()
        local current = ReplicatedStorage
        local path = {"rbxts_include", "node_modules", "@rbxts", "remo", "src", "container", "ui.quickTime.sendSequence"}
        for _, name in ipairs(path) do
            current = current:WaitForChild(name, 5)
            if not current then return nil end
        end
        return current
    end

    local seqEvent = getSequenceEvent()
    if seqEvent then
        seqEvent.OnClientEvent:Connect(function(...)
            if scriptKilled then return end
            task.spawn(function()
                local argosKeys = {
                    Enum.KeyCode.A,
                    Enum.KeyCode.R,
                    Enum.KeyCode.G,
                    Enum.KeyCode.O,
                    Enum.KeyCode.S
                }

                task.wait(0.1)
                for _, key in ipairs(argosKeys) do
                    if scriptKilled then break end
                    pressKey(key)
                    task.wait(0.08)
                end
            end)
        end)
    end

    local function getMashEvent()
        local current = ReplicatedStorage
        local path = {"rbxts_include", "node_modules", "@rbxts", "remo", "src", "container", "ui.quickTime.sendMash"}
        for _, name in ipairs(path) do
            current = current:WaitForChild(name, 5)
            if not current then return nil end
        end
        return current
    end

    local mashEvent = getMashEvent()
    if mashEvent then
        mashEvent.OnClientEvent:Connect(function(...)
            if scriptKilled then return end
            task.spawn(function()
                local startTime = tick()
                while tick() - startTime < 8 and not scriptKilled do
                    pressKey(Enum.KeyCode.Space)
                    task.wait(0.03)
                end
            end)
        end)
    end
end)

-- =================================================================
--      АВТО-ОТВЕТ НА ДИАЛОГ РЕСТАРТА БОЯ (RESTART FIGHT DIALOGUE)
-- =================================================================
task.spawn(function()
    local function getDialogEvent()
        local current = ReplicatedStorage
        local path = {"rbxts_include", "node_modules", "@rbxts", "remo", "src", "container", "ui.dialog.send"}
        for _, name in ipairs(path) do
            current = current:WaitForChild(name, 5)
            if not current then return nil end
        end
        return current
    end

    local dialogEvent = getDialogEvent()
    if dialogEvent then
        dialogEvent.OnClientEvent:Connect(function(data)
            if scriptKilled then return end
            local isRestartDialog = false
            if type(data) == "table" and data.options then
                for _, opt in ipairs(data.options) do
                    if type(opt) == "string" and opt:find("Restart the Fight") then
                        isRestartDialog = true
                        break
                    end
                end
            end

            if isRestartDialog then
                task.spawn(function()
                    task.wait(5)
                    if scriptKilled then return end

                    local respondEvent = ReplicatedStorage:WaitForChild("rbxts_include", 5)
                        :WaitForChild("node_modules", 5)
                        :WaitForChild("@rbxts", 5)
                        :WaitForChild("remo", 5)
                        :WaitForChild("src", 5)
                        :WaitForChild("container", 5)
                        :WaitForChild("player.dialog.respond", 5) or 
                        ReplicatedStorage.rbxts_include.node_modules["@rbxts"].remo.src.container:FindFirstChild("ui.dialog.respond")

                    if respondEvent then
                        respondEvent:FireServer(0)
                    end
                end)
            end
        end)
    end
end)

-- =================================================================
--            АВТО-ЛУТ ДРОПА ПРИ ПОЯВЛЕНИИ (ARGOS DROP)
-- =================================================================
local isDropNearby = false

task.spawn(function()
    local processedDrops = {}

    local function sendKey(keyCode)
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
    end

    local function holdKey(keyCode, holdDuration)
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
        task.wait(holdDuration)
        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
    end

    local function findCrystalAltar()
        for _, obj in ipairs(workspace:GetDescendants()) do
            local name = obj.Name:lower()
            if name == "crystalalter" or name == "crystalaltar" then
                return obj
            end
        end
        return nil
    end

    local function handleDrop(dropObj)
        if scriptKilled or processedDrops[dropObj] then return end
        
        local char, hrp = getHRP(2)
        if not hrp then return end

        local dropPos = dropObj:GetPivot().Position
        local dist = (hrp.Position - dropPos).Magnitude

        if dist <= 30 then
            processedDrops[dropObj] = true
            isDropNearby = true

            task.spawn(function()
                task.wait(2)
                if scriptKilled then return end
                holdKey(Enum.KeyCode.E, 1.0)

                task.wait(2)
                if scriptKilled then return end
                local quickMoveEvent = ReplicatedStorage:WaitForChild("rbxts_include", 5)
                    :WaitForChild("node_modules", 5)
                    :WaitForChild("@rbxts", 5)
                    :WaitForChild("remo", 5)
                    :WaitForChild("src", 5)
                    :WaitForChild("container", 5)
                    :WaitForChild("player.inventory.quickMove", 5)

                if quickMoveEvent then
                    quickMoveEvent:FireServer({
                        index = 5,
                        container = "external"
                    })
                end

                task.wait(2)
                if scriptKilled then return end
                sendKey(Enum.KeyCode.Tab)

                task.wait(1)
                if scriptKilled then return end
                local currentChar, currentHrp = getHRP(2)
                local altar = findCrystalAltar()
                if currentHrp and altar then
                    currentHrp.AssemblyLinearVelocity = Vector3.zero
                    currentHrp.CFrame = altar:GetPivot() * CFrame.new(0, 3, 0)
                end
            end)
        end
    end

    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name == "ArgosDrop" then
            handleDrop(obj)
        end
    end

    workspace.ChildAdded:Connect(function(child)
        if child.Name == "ArgosDrop" then
            handleDrop(child)
        end
    end)
end)

-- =================================================================
--         АВТО-СТАРТ ЦЕПОЧКИ (SPAWN -> TP & FLY -> AUTOCLICK)
-- =================================================================
task.spawn(function()
    local function findArgosSpawnZone()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj.Name == "ArgosSpawnZone" then
                return obj
            end
        end
        return nil
    end

    -- 1. Ждем 20 секунд перед началом цепочки
    task.wait(20)
    if scriptKilled then return end

    -- 2. Надежная телепортация в ArgosSpawnZone
    local char, hrp = getHRP(10)
    local spawnZone = findArgosSpawnZone()

    if hrp and spawnZone then
        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.CFrame = spawnZone:GetPivot() * CFrame.new(0, 3, 0)
        end)
    end

    -- 3. Ждем 2 секунды
    task.wait(2)
    if scriptKilled then return end

    -- 4. Включаем Авто-ТП под босса и Fly+Noclip
    if not autoTpEnabled then
        startAutoTP()
    end
    if not flyNoclipEnabled then
        toggleFlyNoclip()
    end

    -- 5. Авто-клик мыши (LMB)
    while not isDropNearby and not scriptKilled do
        local vp = Camera.ViewportSize
        local centerX, centerY = vp.X / 2, vp.Y / 2
        VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
        task.wait(0.02)
        VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
        task.wait(0.03)
    end
end)
]==]

-- Передаем код в среду без использования формата строк string.format
if getgenv then
    getgenv().ArgosSource = rawScript
end

local qOT = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport) or queueonteleport
if qOT then
    pcall(function()
        qOT(rawScript)
    end)
end

assert(loadstring(rawScript))()
