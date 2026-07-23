--[[
  BUILD A BOAT FARMING - VERSIONE XENO (DRAGGABILE)
  - GUI si ricrea dopo la morte
  - Tasto F per avviare/fermare
  - La GUI si può trascinare ovunque con il mouse
]]

local player = game.Players.LocalPlayer
local farmingRunning = false
local statusLabel = nil
local screenGui = nil
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

-- ===== FUNZIONI BASE =====
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

local function teleportBoatAndPlayer(pos)
    local boat = getBoat()
    if boat then
        local primary = boat.PrimaryPart or boat:FindFirstChildOfClass("BasePart")
        if primary then
            primary.CFrame = CFrame.new(pos)
        end
    end
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(pos)
    end
end

local function moveForward(dist, steps)
    steps = steps or 8
    local boat = getBoat()
    if not boat then return end
    local primary = boat.PrimaryPart or boat:FindFirstChildOfClass("BasePart")
    if not primary then return end
    local startPos = primary.Position
    local targetPos = startPos + Vector3.new(0, 0, dist)
    local stepVec = (targetPos - startPos) / steps
    for i = 1, steps do
        if not farmingRunning then break end
        local newPos = startPos + stepVec * i
        primary.CFrame = CFrame.new(newPos)
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = CFrame.new(newPos)
        end
        wait(0.05)
    end
    primary.CFrame = CFrame.new(targetPos)
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

    -- Eventi mouse per il drag
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

    -- Titolo
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "Auto farm Reda"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame

    -- Status
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

    -- Avvia
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

    -- Ferma
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

    -- Pulsanti
    startBtn.MouseButton1Click:Connect(function()
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            startPos = char.HumanoidRootPart.Position
        end
        farmingRunning = true
        if statusLabel then statusLabel.Text = "▶ Avviato!" end
        print("▶ Farming avviato")
    end)

    stopBtn.MouseButton1Click:Connect(function()
        farmingRunning = false
        if statusLabel then statusLabel.Text = "⏹ Fermato!" end
        print("⏹ Farming fermato")
    end)
end

-- ===== KEYBIND (Tasto F) =====
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then
        farmingRunning = not farmingRunning
        if statusLabel then
            statusLabel.Text = farmingRunning and "▶ Avviato!" or "⏹ Fermato!"
        end
        print(farmingRunning and "▶ Farming attivato (F)" or "⏹ Farming fermato (F)")
        if farmingRunning then
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                startPos = char.HumanoidRootPart.Position
            end
        end
    end
end)

-- ===== THREAD PRINCIPALE =====
createGUI()

spawn(function()
    while true do
        if not screenGui or not screenGui.Parent then
            createGUI()
            if statusLabel then
                statusLabel.Text = farmingRunning and "▶ Avviato!" or "⏹ Fermato!"
            end
        end

        while not farmingRunning do
            wait(1)
            if not screenGui or not screenGui.Parent then
                createGUI()
                if statusLabel then
                    statusLabel.Text = farmingRunning and "▶ Avviato!" or "⏹ Fermato!"
                end
            end
        end

        local success = pcall(function()
            local char = player.Character
            while not char and farmingRunning do
                if statusLabel then statusLabel.Text = "⏳ Personaggio..." end
                wait(0.5)
                char = player.Character
            end
            if not farmingRunning then return end

            local boat = getBoat()
            while not boat and farmingRunning do
                if statusLabel then statusLabel.Text = "⏳ Barca..." end
                wait(0.5)
                boat = getBoat()
            end
            if not farmingRunning then return end

            local primary = boat.PrimaryPart or boat:FindFirstChildOfClass("BasePart")
            if not primary then
                if statusLabel then statusLabel.Text = "❌ Errore!" end
                wait(2)
                return
            end

            if statusLabel then statusLabel.Text = "📍 Partenza..." end
            teleportBoatAndPlayer(startPos)
            wait(1.5)
            if not farmingRunning then return end

            for i, pos in ipairs(stages) do
                if not farmingRunning then return end
                if statusLabel then statusLabel.Text = "📍 Fase " .. i end
                teleportBoatAndPlayer(pos)
                wait(0.8)
                if not farmingRunning then return end
                moveForward(20, 6)
                wait(0.8)
            end
            if not farmingRunning then return end

            if statusLabel then statusLabel.Text = "💰 Baule..." end
            teleportBoatAndPlayer(chestPos)
            wait(2)
            if not farmingRunning then return end

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

            if statusLabel then statusLabel.Text = "🔄 Rientro..." end
            teleportBoatAndPlayer(startPos)
            wait(1.5)
            if not farmingRunning then return end

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

            if statusLabel then statusLabel.Text = "⏳ Completato!" end
            print("✅ Ciclo completato")
            wait(2)
        end)

        if not success then
            if statusLabel then statusLabel.Text = "⚠️ Riavvio..." end
            print("Errore, riavvio tra 3 secondi")
            wait(3)
        end
    end
end)

print("✅ Farming caricato! Premi F per avviare/fermare.")
print("   La GUI si può trascinare tenendo premuto il mouse.")
