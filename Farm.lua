--[[
  BUILD A BOAT FARMING - FLY STABILE (come Infinite Yield)
  - GUI DRAGGABILE (trascina con il mouse)
  - Il personaggio rimane sospeso in aria senza cadere
  - Movimento fluido e controllato
  - PAUSA DI 1 SECONDO SU OGNI FASE
  - AL BAULE: rimane lì, aspetta ricompensa e reset
  - GUI si ricrea AUTOMATICAMENTE al respawn
  - AUTO-AVVIO dopo il reset (NON devi premere Ferma/Avvia)
  - Tasto F per avviare/fermare
]]

local player = game.Players.LocalPlayer
local farmingRunning = false
local statusLabel = nil
local screenGui = nil
local flyBodyVelocity = nil
local flyBodyPosition = nil
local restartFarming = false

-- ===== VARIABILI PER DRAG =====
local dragging = false
local dragStart = nil
local framePos = nil

-- ===== COORDINATE =====
local startPos = Vector3.new(-483.83, 9.69, 293.12)
local stages = {
    Vector3.new(-48.13, 31.66, 1291.60),
    Vector3.new(-48.85, 36.10, 2080.88),
    Vector3.new(-32.44, 45.92, 2842.22),
    Vector3.new(-49.12, 26.22, 3614.95),
    Vector3.new(-32.55, 64.45, 4376.00),
    Vector3.new(-33.04, 53.18, 5155.53),
    Vector3.new(-25.44, 39.20, 5932.89),
    Vector3.new(-39.52, 43.96, 6722.31),
    Vector3.new(-25.68, 47.16, 7485.08),
    Vector3.new(-42.82, 22.90, 8269.01)
}
local chestPos = Vector3.new(-55.66, -360.05, 9488.53)

-- ===== FUNZIONE PER PULIRE IL VOLO VECCHIO =====
local function cleanFly()
    if flyBodyVelocity then
        flyBodyVelocity:Destroy()
        flyBodyVelocity = nil
    end
    if flyBodyPosition then
        flyBodyPosition:Destroy()
        flyBodyPosition = nil
    end
end

-- ===== FUNZIONE PER ATTIVARE IL VOLO STABILE =====
local function enableFly(char)
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    cleanFly()
    
    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    flyBodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    flyBodyVelocity.Parent = root
    
    flyBodyPosition = Instance.new("BodyPosition")
    flyBodyPosition.MaxForce = Vector3.new(4000, 4000, 4000)
    flyBodyPosition.D = 500
    flyBodyPosition.P = 5000
    flyBodyPosition.Position = root.Position
    flyBodyPosition.Parent = root
    
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.PlatformStand = true
        humanoid.Sit = true
    end
end

-- ===== FUNZIONE PER DISATTIVARE IL VOLO =====
local function disableFly()
    cleanFly()
    local char = player.Character
    if char then
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
            humanoid.Sit = false
        end
    end
end

-- ===== FUNZIONE DI VOLO FLUIDO =====
local function flyTo(targetPos, speed)
    speed = speed or 35
    local char = player.Character
    if not char then return false end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    
    if not flyBodyVelocity or not flyBodyVelocity.Parent or not flyBodyPosition or not flyBodyPosition.Parent then
        enableFly(char)
    end
    
    local startPos = root.Position
    local distance = (targetPos - startPos).Magnitude
    if distance < 1 then return true end
    
    local steps = math.max(10, distance / speed)
    steps = math.min(steps, 50)
    
    for i = 1, steps do
        if not farmingRunning then return false end
        if restartFarming then return false end
        local alpha = i / steps
        local eased = alpha * alpha * (3 - 2 * alpha)
        local newPos = startPos:lerp(targetPos, eased)
        
        if flyBodyPosition and flyBodyPosition.Parent then
            flyBodyPosition.Position = newPos
        end
        root.CFrame = CFrame.new(newPos)
        wait(0.02)
    end
    
    root.CFrame = CFrame.new(targetPos)
    if flyBodyPosition and flyBodyPosition.Parent then
        flyBodyPosition.Position = targetPos
    end
    return true
end

-- ===== FUNZIONE PER ASPETTARE IL PERSONAGGIO =====
local function waitForCharacter()
    local char = player.Character
    while not char do
        if restartFarming then return nil end
        wait(0.5)
        char = player.Character
    end
    while not char:FindFirstChild("HumanoidRootPart") do
        if restartFarming then return nil end
        wait(0.2)
    end
    return char
end

-- ===== FUNZIONE PER ASPETTARE IL RESET (MORTE) =====
local function waitForReset()
    if statusLabel then statusLabel.Text = "💀 Attendo reset..." end
    print("💀 In attesa del reset del personaggio...")
    
    local char = player.Character
    while char and farmingRunning do
        if restartFarming then return end
        wait(0.5)
        char = player.Character
    end
    
    if not farmingRunning then return end
    
    if statusLabel then statusLabel.Text = "⏳ Respawn in corso..." end
    print("⏳ Personaggio morto, attendo respawn...")
    
    cleanFly()
    
    while not player.Character and farmingRunning do
        if restartFarming then return end
        wait(0.5)
    end
    
    if not farmingRunning then return end
    
    local newChar = player.Character
    while newChar and not newChar:FindFirstChild("HumanoidRootPart") and farmingRunning do
        if restartFarming then return end
        wait(0.2)
        newChar = player.Character
    end
    
    if farmingRunning then
        if statusLabel then statusLabel.Text = "🔄 Respawn completato!" end
        print("🔄 Personaggio respawnato, riavvio del farming")
        restartFarming = true
        wait(1)
    end
end

-- ===== CREA GUI (DRAGGABILE) =====
local function createGUI()
    if screenGui then screenGui:Destroy() end

    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FarmingGUI"
    screenGui.Parent = player.PlayerGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 220, 0, 120)
    mainFrame.Position = UDim2.new(0, 10, 0, 10)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame

    -- ===== SISTEMA DRAG =====
    local function startDrag()
        dragging = true
        dragStart = game:GetService("UserInputService"):GetMouseLocation()
        framePos = mainFrame.Position
    end

    local function stopDrag()
        dragging = false
    end

    local function updateDrag()
        if not dragging then return end
        local mousePos = game:GetService("UserInputService"):GetMouseLocation()
        local delta = mousePos - dragStart
        local newPos = UDim2.new(
            framePos.X.Scale,
            framePos.X.Offset + delta.X,
            framePos.Y.Scale,
            framePos.Y.Offset + delta.Y
        )
        mainFrame.Position = newPos
    end

    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            startDrag()
        end
    end)

    mainFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            stopDrag()
        end
    end)

    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            updateDrag()
        end
    end)

    -- ===== TITOLO =====
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "Auto farm Reda"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame

    -- ===== STATUS =====
    statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 0, 20)
    statusLabel.Position = UDim2.new(0, 0, 0, 35)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Stato: Fermo"
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusLabel.TextSize = 14
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.Name = "StatusLabel"
    statusLabel.Parent = mainFrame

    -- ===== AVVIA =====
    local startBtn = Instance.new("TextButton")
    startBtn.Size = UDim2.new(0, 90, 0, 30)
    startBtn.Position = UDim2.new(0, 10, 0, 65)
    startBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
    startBtn.Text = "▶ Avvia"
    startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    startBtn.TextSize = 14
    startBtn.Font = Enum.Font.GothamBold
    startBtn.Parent = mainFrame
    local btnCorner1 = Instance.new("UICorner")
    btnCorner1.CornerRadius = UDim.new(0, 4)
    btnCorner1.Parent = startBtn

    -- ===== FERMA =====
    local stopBtn = Instance.new("TextButton")
    stopBtn.Size = UDim2.new(0, 90, 0, 30)
    stopBtn.Position = UDim2.new(0, 110, 0, 65)
    stopBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    stopBtn.Text = "■ Ferma"
    stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    stopBtn.TextSize = 14
    stopBtn.Font = Enum.Font.GothamBold
    stopBtn.Parent = mainFrame
    local btnCorner2 = Instance.new("UICorner")
    btnCorner2.CornerRadius = UDim.new(0, 4)
    btnCorner2.Parent = stopBtn

    -- ===== PULSANTI =====
    startBtn.MouseButton1Click:Connect(function()
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            startPos = char.HumanoidRootPart.Position
            enableFly(char)
        end
        restartFarming = false
        farmingRunning = true
        if statusLabel then statusLabel.Text = "▶ Avviato!" end
        print("▶ Farming avviato")
    end)

    stopBtn.MouseButton1Click:Connect(function()
        farmingRunning = false
        restartFarming = false
        disableFly()
        if statusLabel then statusLabel.Text = "⏹ Fermato!" end
        print("⏹ Farming fermato")
    end)
end

-- ===== EVENTO: RICREA LA GUI AL RESPAWN =====
player.CharacterAdded:Connect(function(char)
    cleanFly()
    createGUI()
    if statusLabel then
        statusLabel.Text = farmingRunning and "▶ Avviato!" or "⏹ Fermato!"
    end
    print("🔄 GUI ricreata automaticamente al respawn")
    
    if farmingRunning then
        enableFly(char)
        restartFarming = true
        print("🔄 Volo riattivato, farming in esecuzione...")
    end
end)

-- ===== KEYBIND (Tasto F) =====
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then
        farmingRunning = not farmingRunning
        if farmingRunning then
            restartFarming = false
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                startPos = char.HumanoidRootPart.Position
                enableFly(char)
            end
            if statusLabel then statusLabel.Text = "▶ Avviato!" end
        else
            restartFarming = false
            disableFly()
            if statusLabel then statusLabel.Text = "⏹ Fermato!" end
        end
        print(farmingRunning and "▶ Farming attivato (F)" or "⏹ Farming fermato (F)")
    end
end)

-- ===== THREAD PRINCIPALE =====
createGUI()

spawn(function()
    while true do
        -- Ricrea la GUI se distrutta
        if not screenGui or not screenGui.Parent then
            createGUI()
            if statusLabel then
                statusLabel.Text = farmingRunning and "▶ Avviato!" or "⏹ Fermato!"
            end
        end

        -- Aspetta che il farming sia attivo
        while not farmingRunning do
            wait(1)
            if restartFarming then restartFarming = false end
            if not screenGui or not screenGui.Parent then
                createGUI()
                if statusLabel then
                    statusLabel.Text = farmingRunning and "▶ Avviato!" or "⏹ Fermato!"
                end
            end
        end

        -- Se c'è un restart da fare, esce e ricomincia
        if restartFarming then
            restartFarming = false
            wait(0.5)
        end

        -- ===== CICLO DI FARMING =====
        local success = pcall(function()
            -- 1. Aspetta il personaggio
            if statusLabel then statusLabel.Text = "📍 Aspetto personaggio..." end
            local char = waitForCharacter()
            if not char or not farmingRunning then return end
            
            -- 2. Attiva il volo
            if not flyBodyVelocity or not flyBodyVelocity.Parent or not flyBodyPosition or not flyBodyPosition.Parent then
                enableFly(char)
            end
            
            -- 3. Vola alla partenza
            if statusLabel then statusLabel.Text = "🕊️ Volo alla partenza..." end
            flyTo(startPos, 40)
            if not farmingRunning or restartFarming then return end
            wait(0.5)

            -- 4. Percorri gli stage (pausa 1 secondo)
            for i, pos in ipairs(stages) do
                if not farmingRunning or restartFarming then return end
                if statusLabel then statusLabel.Text = "🕊️ Fase " .. i .. " (attesa 1 sec)" end
                flyTo(pos, 45)
                if not farmingRunning or restartFarming then return end
                wait(0.3)
                if not farmingRunning or restartFarming then return end
                wait(1)
                if not farmingRunning or restartFarming then return end
            end
            if not farmingRunning or restartFarming then return end

            -- 5. Vola al baule
            if statusLabel then statusLabel.Text = "🕊️ Volo al baule..." end
            flyTo(chestPos, 50)
            if not farmingRunning or restartFarming then return end
            wait(1.5)

            -- 6. Aspetta la ricompensa
            if statusLabel then statusLabel.Text = "💰 In attesa ricompensa..." end
            if player:FindFirstChild("leaderstats") then
                local coins = player.leaderstats:FindFirstChild("Coins") or 
                              player.leaderstats:FindFirstChild("Money")
                if coins then
                    local startCoins = coins.Value
                    for _ = 1, 15 do
                        if not farmingRunning or restartFarming then return end
                        wait(1)
                        if coins.Value > startCoins then
                            if statusLabel then statusLabel.Text = "✅ Ricompensa ottenuta!" end
                            break
                        end
                    end
                end
            else
                wait(10)
            end
            if not farmingRunning or restartFarming then return end

            -- 7. Resta al baule e aspetta il reset
            if statusLabel then statusLabel.Text = "💀 Attendo reset..." end
            print("💀 Attendo che il personaggio muoia per resettarsi...")
            waitForReset()
            if not farmingRunning then return end
            
            -- 8. Personaggio respawnato, il ciclo ricomincia
            if statusLabel then statusLabel.Text = "🔄 Reset completato, riavvio..." end
            print("🔄 Personaggio resettato, ricomincio il farming")
            wait(1)
        end)

        -- Gestione errori
        if not success then
            if statusLabel then statusLabel.Text = "⚠️ Errore, attendo..." end
            print("Errore nel farming, attendo 3 secondi...")
            wait(3)
        end

        if not farmingRunning then
            wait(1)
        end
    end
end)

print("✅ Farming FLY STABILE + DRAGGABILE + AUTO-AVVIO caricato!")
print("   - GUI draggabile (trascina con il mouse)")
print("   - GUI si ricrea automaticamente al respawn")
print("   - Farming riparte automaticamente se era attivo")
print("   - Premi F per avviare/fermare")
