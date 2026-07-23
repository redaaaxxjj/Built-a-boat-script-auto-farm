--[[
  BUILD A BOAT FARMING - FLY STABILE (come Infinite Yield)
  - Il personaggio rimane sospeso in aria senza cadere
  - Movimento fluido e controllato
  - PAUSA DI 1 SECONDO SU OGNI FASE
  - GUI si ricrea dopo la morte
  - Auto-riavvio dopo il reset
  - Tasto F per avviare/fermare
]]

local player = game.Players.LocalPlayer
local farmingRunning = false
local statusLabel = nil
local screenGui = nil
local flyBodyVelocity = nil
local flyBodyPosition = nil

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

-- ===== FUNZIONE PER ATTIVARE IL VOLO STABILE =====
local function enableFly(char)
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- Rimuovi eventuali fly precedenti
    if flyBodyVelocity then flyBodyVelocity:Destroy() end
    if flyBodyPosition then flyBodyPosition:Destroy() end
    
    -- Crea un BodyVelocity per tenere il personaggio in aria
    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    flyBodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    flyBodyVelocity.Parent = root
    
    -- Crea un BodyPosition per mantenere l'altezza (anti-caduta)
    flyBodyPosition = Instance.new("BodyPosition")
    flyBodyPosition.MaxForce = Vector3.new(4000, 4000, 4000)
    flyBodyPosition.D = 500
    flyBodyPosition.P = 5000
    flyBodyPosition.Position = root.Position
    flyBodyPosition.Parent = root
    
    -- Disabilita la gravità per il personaggio
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.PlatformStand = true
        humanoid.Sit = true  -- lo mette in posizione "seduto" ma in aria
    end
    
    print("🕊️ Volo stabile attivato!")
end

-- ===== FUNZIONE PER DISATTIVARE IL VOLO =====
local function disableFly()
    if flyBodyVelocity then
        flyBodyVelocity:Destroy()
        flyBodyVelocity = nil
    end
    if flyBodyPosition then
        flyBodyPosition:Destroy()
        flyBodyPosition = nil
    end
    local char = player.Character
    if char then
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
            humanoid.Sit = false
        end
    end
    print("🛑 Volo disattivato")
end

-- ===== FUNZIONE DI VOLO FLUIDO (con fly attivo) =====
local function flyTo(targetPos, speed)
    speed = speed or 35
    local char = player.Character
    if not char then return false end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    
    -- Assicura che il volo sia attivo
    if not flyBodyVelocity or not flyBodyPosition then
        enableFly(char)
    end
    
    local startPos = root.Position
    local distance = (targetPos - startPos).Magnitude
    if distance < 1 then return true end
    
    local steps = math.max(10, distance / speed)
    steps = math.min(steps, 50)
    
    for i = 1, steps do
        if not farmingRunning then return false end
        local alpha = i / steps
        local eased = alpha * alpha * (3 - 2 * alpha)
        local newPos = startPos:lerp(targetPos, eased)
        
        -- Aggiorna la posizione del BodyPosition per mantenere l'altezza
        if flyBodyPosition then
            flyBodyPosition.Position = newPos
        end
        root.CFrame = CFrame.new(newPos)
        wait(0.02)
    end
    
    root.CFrame = CFrame.new(targetPos)
    if flyBodyPosition then
        flyBodyPosition.Position = targetPos
    end
    return true
end

-- ===== FUNZIONE PER ASPETTARE IL PERSONAGGIO =====
local function waitForCharacter()
    local char = player.Character
    while not char do
        wait(0.5)
        char = player.Character
    end
    while not char:FindFirstChild("HumanoidRootPart") do
        wait(0.2)
    end
    return char
end

-- ===== CREA GUI =====
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

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "Auto farm Reda"  -- <--- TITOLO CAMBIATO
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame

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

    startBtn.MouseButton1Click:Connect(function()
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            startPos = char.HumanoidRootPart.Position
            -- Attiva il volo stabile
            enableFly(char)
        end
        farmingRunning = true
        if statusLabel then statusLabel.Text = "▶ Avviato!" end
        print("▶ Farming avviato (fly stabile)")
    end)

    stopBtn.MouseButton1Click:Connect(function()
        farmingRunning = false
        disableFly()
        if statusLabel then statusLabel.Text = "⏹ Fermato!" end
        print("⏹ Farming fermato")
    end)
end

-- ===== KEYBIND (Tasto F) =====
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then
        farmingRunning = not farmingRunning
        if farmingRunning then
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                startPos = char.HumanoidRootPart.Position
                enableFly(char)
            end
            if statusLabel then statusLabel.Text = "▶ Avviato!" end
        else
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
        -- Se la GUI è stata distrutta, la ricrea
        if not screenGui or not screenGui.Parent then
            createGUI()
            if statusLabel then
                statusLabel.Text = farmingRunning and "▶ Avviato!" or "⏹ Fermato!"
            end
        end

        -- Aspetta che il farming sia attivo
        while not farmingRunning do
            wait(1)
            if not screenGui or not screenGui.Parent then
                createGUI()
                if statusLabel then
                    statusLabel.Text = farmingRunning and "▶ Avviato!" or "⏹ Fermato!"
                end
            end
        end

        -- ===== CICLO DI FARMING (FLY STABILE + PAUSA 1 SEC) =====
        local success = pcall(function()
            -- 1. Aspetta il personaggio
            if statusLabel then statusLabel.Text = "📍 Aspetto personaggio..." end
            local char = waitForCharacter()
            if not farmingRunning then return end
            
            -- 2. Attiva il volo se non è già attivo
            if not flyBodyVelocity or not flyBodyPosition then
                enableFly(char)
            end
            
            -- 3. Vola alla partenza
            if statusLabel then statusLabel.Text = "🕊️ Volo alla partenza..." end
            flyTo(startPos, 40)
            if not farmingRunning then return end
            wait(0.5)

            -- 4. Percorri gli stage con PAUSA di 1 secondo su ogni fase
            for i, pos in ipairs(stages) do
                if not farmingRunning then return end
                if statusLabel then statusLabel.Text = "🕊️ Fase " .. i .. " (attesa 1 sec)" end
                flyTo(pos, 45)
                if not farmingRunning then return end
                wait(0.3)   -- breve pausa dopo l'arrivo
                if not farmingRunning then return end
                wait(1)     -- <--- PAUSA DI 1 SECONDO SU OGNI FASE
                if not farmingRunning then return end
            end
            if not farmingRunning then return end

            -- 5. Vola al baule
            if statusLabel then statusLabel.Text = "🕊️ Volo al baule..." end
            flyTo(chestPos, 50)
            if not farmingRunning then return end
            wait(1.5)

            -- 6. Aspetta la ricompensa
            if player:FindFirstChild("leaderstats") then
                local coins = player.leaderstats:FindFirstChild("Coins") or 
                              player.leaderstats:FindFirstChild("Money")
                if coins then
                    local startCoins = coins.Value
                    for _ = 1, 15 do
                        if not farmingRunning then return end
                        wait(1)
                        if coins.Value > startCoins then
                            if statusLabel then statusLabel.Text = "✅ Ricompensa!" end
                            break
                        end
                    end
                end
            else
                wait(10)
            end
            if not farmingRunning then return end

            -- 7. Vola alla partenza
            if statusLabel then statusLabel.Text = "🕊️ Rientro..." end
            flyTo(startPos, 40)
            if not farmingRunning then return end
            wait(0.5)

            -- 8. Clicca "Reclama"
            for _, v in pairs(player.PlayerGui:GetDescendants()) do
                if v:IsA("TextButton") then
                    local txt = string.lower(v.Text or "")
                    if string.find(txt, "reclama") or string.find(txt, "claim") then
                        v:Click()
                        wait(0.3)
                        break
                    end
                end
            end

            if statusLabel then statusLabel.Text = "⏳ Ciclo completato!" end
            print("✅ Ciclo completato (fly stabile + pausa 1s)")
            wait(2)
        end)

        -- ===== GESTIONE DEL RESET (morte) =====
        if not success then
            if statusLabel then statusLabel.Text = "⚠️ Attendo respawn..." end
            print("Errore o reset, attendo il respawn...")
            disableFly()  -- pulisce il fly vecchio
            local char = player.Character
            while not char and farmingRunning do
                wait(0.5)
                char = player.Character
            end
            if farmingRunning and char then
                if statusLabel then statusLabel.Text = "🔄 Riavvio..." end
                print("🔄 Personaggio respawnato, riavvio...")
                wait(1)
            end
        end

        if not farmingRunning then
            wait(1)
        end
    end
end)

print("✅ Farming FLY STABILE + PAUSA 1 SECONDO caricato!")
print("   - Il personaggio rimane sospeso in aria (come Infinite Yield)")
print("   - Su ogni fase aspetta 1 secondo")
print("   - Premi F per avviare/fermare")
