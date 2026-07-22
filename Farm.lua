--[[
  BUILD A BOAT FARMING - DEFINITIVA CON GESTIONE ERRORI
  Non si blocca se leaderstats non esiste
  La partenza è dinamica: posizione attuale del personaggio all'avvio
]]

local player = game.Players.LocalPlayer
local TweenService = game:GetService("TweenService")

-- ===== CREA GUI =====
local function createGUI()
    local old = player.PlayerGui:FindFirstChild("FarmingGUI")
    if old then old:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FarmingGUI"
    screenGui.Parent = player.PlayerGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 210, 0, 130)
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
    title.Text = "Auto farm Reda"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame

    local statusLabel = Instance.new("TextLabel")
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
    startBtn.Size = UDim2.new(0, 85, 0, 30)
    startBtn.Position = UDim2.new(0, 10, 0, 65)
    startBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
    startBtn.Text = "▶ Avvia"
    startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    startBtn.TextSize = 14
    startBtn.Font = Enum.Font.GothamBold
    startBtn.Name = "StartBtn"
    startBtn.Parent = mainFrame

    local btnCorner1 = Instance.new("UICorner")
    btnCorner1.CornerRadius = UDim.new(0, 4)
    btnCorner1.Parent = startBtn

    local stopBtn = Instance.new("TextButton")
    stopBtn.Size = UDim2.new(0, 85, 0, 30)
    stopBtn.Position = UDim2.new(0, 105, 0, 65)
    stopBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    stopBtn.Text = "■ Ferma"
    stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    stopBtn.TextSize = 14
    stopBtn.Font = Enum.Font.GothamBold
    stopBtn.Name = "StopBtn"
    stopBtn.Parent = mainFrame

    local btnCorner2 = Instance.new("UICorner")
    btnCorner2.CornerRadius = UDim.new(0, 4)
    btnCorner2.Parent = stopBtn

    return screenGui, startBtn, stopBtn, statusLabel
end

-- ===== COORDINATE =====
-- Ora startPos sarà dinamico, lo imposteremo all'avvio
local startPos = Vector3.new(-483.83, 9.69, 293.12)  -- fallback se non si riesce a leggere la posizione
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

-- ===== FUNZIONI =====
local function getBoat()
    local char = player.Character
    if not char then return nil end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return nil end
    local seat = humanoid.SeatPart
    if not seat then return nil end
    local current = seat
    while current do
        current = current.Parent
        if current and current:IsA("Model") then
            return current, char, humanoid
        end
    end
    return nil
end

-- ===== VARIABILI GLOBALI =====
local farmingRunning = false

-- ===== THREAD PRINCIPALE (NON MUORE MAI) =====
spawn(function()
    while true do
        -- Ricrea la GUI
        local gui, startBtn, stopBtn, statusLabel = createGUI()
        
        -- Collega i pulsanti
        startBtn.MouseButton1Click:Connect(function()
            -- === LEGGI LA POSIZIONE ATTUALE DEL PERSONAGGIO ===
            local char = player.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    startPos = root.Position
                    print("📍 Nuova partenza impostata a:", startPos)
                else
                    print("⚠️ HumanoidRootPart non trovato, uso posizione fissa")
                end
            else
                print("⚠️ Personaggio non trovato, uso posizione fissa")
            end
            
            farmingRunning = true
            statusLabel.Text = "▶ Avviato!"
            print("▶ Farming avviato")
        end)

        stopBtn.MouseButton1Click:Connect(function()
            farmingRunning = false
            statusLabel.Text = "⏹ Fermato!"
            print("⏹ Farming fermato")
        end)

        -- Loop interno del farming
        while true do
            -- Se il farming è fermo, aspetta
            while not farmingRunning do
                statusLabel.Text = "⏸ In pausa..."
                wait(1)
                if farmingRunning then break end
            end

            -- Se il farming è stato fermato definitivamente, esci
            if not farmingRunning then
                break
            end

            -- ===== FARMING =====
            local success = pcall(function()
                -- 1. Aspetta il personaggio
                local char = player.Character
                while not char and farmingRunning do
                    statusLabel.Text = "⏳ In attesa del personaggio..."
                    wait(0.5)
                    char = player.Character
                end
                if not farmingRunning then return end

                -- 2. Aspetta la barca
                local boat = getBoat()
                while not boat and farmingRunning do
                    statusLabel.Text = "⏳ In attesa della barca..."
                    wait(0.5)
                    boat = getBoat()
                end
                if not farmingRunning then return end

                local primary = boat.PrimaryPart or boat:FindFirstChildOfClass("BasePart")
                if not primary then
                    statusLabel.Text = "❌ Barca senza parti!"
                    wait(2)
                    return
                end

                -- 3. Funzioni helper
                local function teleport(pos)
                    if not farmingRunning then return end
                    primary.CFrame = CFrame.new(pos)
                    local char = player.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        char.HumanoidRootPart.CFrame = CFrame.new(pos)
                    end
                end

                local function advance(dist)
                    if not farmingRunning then return end
                    local target = primary.Position + Vector3.new(0, 0, dist)
                    local tween = TweenService:Create(primary, TweenInfo.new(1.2), {CFrame = CFrame.new(target)})
                    tween:Play()
                    tween.Completed:Wait()
                end

                -- 4. Esegui il ciclo (usa startPos dinamico)
                statusLabel.Text = "📍 Partenza..."
                teleport(startPos)
                wait(1.5)
                if not farmingRunning then return end

                for i, pos in ipairs(stages) do
                    if not farmingRunning then return end
                    statusLabel.Text = "📍 Fase " .. i
                    teleport(pos)
                    wait(1)
                    if not farmingRunning then return end
                    advance(20)
                    wait(1)
                end
                if not farmingRunning then return end

                statusLabel.Text = "💰 Baule..."
                teleport(chestPos)
                wait(2)
                if not farmingRunning then return end

                -- CONTROLLO SICUREZZA PER LEADERSTATS
                local coins = nil
                if player:FindFirstChild("leaderstats") then
                    coins = player.leaderstats:FindFirstChild("Coins") or player.leaderstats:FindFirstChild("Money")
                end
                
                if coins then
                    local startCoins = coins.Value
                    for _ = 1, 20 do
                        if not farmingRunning then return end
                        wait(1)
                        if coins.Value > startCoins then
                            statusLabel.Text = "✅ Ricompensa!"
                            break
                        end
                    end
                else
                    -- Se non trova leaderstats, aspetta comunque 10 secondi
                    statusLabel.Text = "💰 Attendo ricompensa..."
                    wait(10)
                end
                if not farmingRunning then return end

                statusLabel.Text = "🔄 Reclamo..."
                teleport(startPos)   -- torna alla partenza dinamica
                wait(1.5)
                if not farmingRunning then return end

                -- Clicca "Reclama"
                for _, v in pairs(player.PlayerGui:GetDescendants()) do
                    if v:IsA("TextButton") then
                        local txt = string.lower(v.Text or "")
                        if string.find(txt, "reclama") or string.find(txt, "claim") then
                            v:Click()
                            wait(0.3)
                        end
                    end
                end

                statusLabel.Text = "⏳ Ciclo completato!"
                print("✅ Ciclo completato")
                wait(3)
            end)

            if not success then
                statusLabel.Text = "⚠️ Errore, riavvio tra 3 secondi..."
                print("Errore nel farming, riavvio...")
                wait(3)
                -- Il loop ricomincia da capo naturalmente
            end

            -- Piccola pausa prima di ripetere
            wait(1)
        end

        -- Aspetta prima di ricreare la GUI
        wait(1)
    end
end)

print("✅ Farming ULTRA-DEFINITIVO caricato! Usa Avvia/Ferma.")
