--[[
    Auto Gojek + UI On/Off
    - Toggle ON/OFF lewat UI (draggable)
    - Akselerasi & pengereman bertahap
    - Reset velocity sebelum & sesudah Void TP
    - Putaran BodyGyro dihaluskan (lerp)
    - State FallingDown / Ragdoll / GettingUp dimatikan
    - Auto duduk lagi kalau karakter terlepas dari kursi
    - Noclip permanen + hover holder + Webhook
    - Void TP bertahap (multi-step + arc melayang)
--]]

local Services = {
    Players = game:GetService("Players"),
    Workspace = game:GetService("Workspace"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    RunService = game:GetService("RunService"),
    HttpService = game:GetService("HttpService"),
    UserInputService = game:GetService("UserInputService"),
    TweenService = game:GetService("TweenService"),
}

local LocalPlayer = Services.Players.LocalPlayer
local CharRef = { Character = nil, Humanoid = nil, Root = nil }

local RAGDOLL_STATES = {
    Enum.HumanoidStateType.FallingDown,
    Enum.HumanoidStateType.Ragdoll,
    Enum.HumanoidStateType.GettingUp,
}

local function setRagdollStates(enabled)
    local hum = CharRef.Humanoid
    if not hum then return end
    for _, st in ipairs(RAGDOLL_STATES) do
        pcall(function() hum:SetStateEnabled(st, enabled) end)
    end
end

local function UpdateCharRef()
    CharRef.Character = LocalPlayer.Character
    if CharRef.Character then
        CharRef.Humanoid = CharRef.Character:WaitForChild("Humanoid")
        CharRef.Root = CharRef.Character:WaitForChild("HumanoidRootPart")
    end
end
UpdateCharRef()

local TaxiEvent = Services.ReplicatedStorage:WaitForChild("TaxiAssets"):WaitForChild("Events"):WaitForChild("TaxiEvent")

-- ==================== SETTINGS ====================
local MAX_SPEED_LIMIT = 95
local MIN_SPEED_LIMIT = 70
local HOVER_HEIGHT = 12
local LAND_HEIGHT = 3
local VOID_TP_MIN = 100
local VOID_TP_MAX = 5000
local VOID_TP_STEP = 25

local ACCEL = 45
local TURN_SMOOTH = 0.12
local RESIT_COOLDOWN = 1

local VOID_STEP_SIZE = 45
local VOID_STEP_DELAY = 0.06
local VOID_ARC_RATIO = 0.05
local VOID_ARC_MAX = 30

local WEBHOOK_URL = "https://discord.com/api/webhooks/1529504964265640117/iTtRuFb7M_OXelDNoC81YZ3OalDWorS3NaxT8UnjtaCuc_jkLMy1xb_jJN3uqTvhkUnd"
local DISCORD_ID = "MASUKKAN_ID_DC_KAMU_DISINI"
-- =================================================

local State = {
    IsActive = false,       -- master switch (dikontrol UI + tim)
    ToggleOn = false,       -- state tombol UI
    IsOnline = false,
    Phase = "idle",
    Token = nil,
    TargetPos = nil,
    IsNoclipOn = false,
    TripCount = 0,
    Earnings = 0,
    BV = nil,
    BG = nil,
    LastSeat = nil,
}

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.2)
    UpdateCharRef()
    if State.IsActive then
        setRagdollStates(false)
    end
end)

Services.RunService.Heartbeat:Connect(function()
    local hum = CharRef.Humanoid
    if hum and hum.SeatPart then
        State.LastSeat = hum.SeatPart
    end
end)

local function getBikeModel()
    local hum = CharRef.Humanoid
    if hum and hum.SeatPart then
        return hum.SeatPart.Parent
    end
    if State.IsActive and State.LastSeat and State.LastSeat.Parent then
        return State.LastSeat.Parent
    end
    return nil
end

local function getPrimary(bike)
    if not bike then return nil end
    return bike.PrimaryPart or bike:FindFirstChildOfClass("BasePart") or bike:FindFirstChild("VehicleSeat")
end

local function zeroVelocity(part)
    if not part then return end
    pcall(function()
        part.AssemblyLinearVelocity = Vector3.zero
        part.AssemblyAngularVelocity = Vector3.zero
    end)
end

local function findGroundY(origin)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    local blacklist = {LocalPlayer.Character}
    local bike = getBikeModel()
    if bike then
        table.insert(blacklist, bike)
        for _, seat in ipairs(bike:GetDescendants()) do
            if seat:IsA("VehicleSeat") and seat.Occupant then
                table.insert(blacklist, seat.Occupant.Parent)
            end
        end
    end
    local activeMissions = Services.Workspace:FindFirstChild("ActiveMissions")
    if activeMissions then
        table.insert(blacklist, activeMissions)
    end
    rayParams.FilterDescendantsInstances = blacklist

    local rayResult = workspace:Raycast(origin, Vector3.new(0, -500, 0), rayParams)
    if rayResult then
        return rayResult.Position.Y
    end
    return nil
end

local function setPassengerCollision(enableCollisions)
    local bike = getBikeModel()
    if bike then
        for _, seat in ipairs(bike:GetDescendants()) do
            if seat:IsA("VehicleSeat") and seat.Occupant then
                local passenger = seat.Occupant.Parent
                if passenger then
                    for _, part in ipairs(passenger:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = enableCollisions
                        end
                    end
                end
            end
        end
    end

    local activeMissions = Services.Workspace:FindFirstChild("ActiveMissions")
    if activeMissions then
        for _, mission in ipairs(activeMissions:GetChildren()) do
            if mission.Name:find("RideGO_Passenger") then
                for _, part in ipairs(mission:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = enableCollisions
                    end
                end
            end
        end
    end
end

-- ==================== WEBHOOK SYSTEM ====================
local function sendDiscordWebhook(passengerName, earnedAmount)
    if not WEBHOOK_URL or WEBHOOK_URL == "" then return end

    local pingContent = ""
    if DISCORD_ID and DISCORD_ID ~= "MASUKKAN_ID_DC_KAMU_DISINI" then
        pingContent = string.format("<@%s> ", DISCORD_ID)
    end

    local payload = {
        ["content"] = pingContent .. "🚖 **Auto Gojek - Order Selesai!**",
        ["embeds"] = {
            {
                ["title"] = "✅ Transaksi Berhasil",
                ["color"] = 65280,
                ["fields"] = {
                    { ["name"] = "👤 Nama Penumpang", ["value"] = tostring(passengerName), ["inline"] = true },
                    { ["name"] = "💰 Pendapatan Order", ["value"] = "Rp " .. tostring(earnedAmount), ["inline"] = true },
                    { ["name"] = "📊 Total Trip", ["value"] = tostring(State.TripCount), ["inline"] = true },
                    { ["name"] = "💵 Total Pendapatan Sementara", ["value"] = "Rp " .. tostring(State.Earnings), ["inline"] = false }
                },
                ["footer"] = { ["text"] = "Auto Gojek" }
            }
        }
    }

    local body = Services.HttpService:JSONEncode(payload)
    local requestFunc = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    local success, err

    if requestFunc then
        success, err = pcall(function()
            requestFunc({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = body
            })
        end)
    else
        success, err = pcall(function()
            Services.HttpService:PostAsync(WEBHOOK_URL, body, Enum.HttpContentType.ApplicationJson)
        end)
    end
end
-- =====================================================

-- ==================== HOLDER ====================
local function destroyHolders()
    if State.BV then pcall(function() State.BV:Destroy() end) end
    if State.BG then pcall(function() State.BG:Destroy() end) end
    State.BV = nil
    State.BG = nil
end

local function getHolders(primary)
    if State.BV and State.BV.Parent ~= primary then
        pcall(function() State.BV:Destroy() end)
        State.BV = nil
    end
    if State.BG and State.BG.Parent ~= primary then
        pcall(function() State.BG:Destroy() end)
        State.BG = nil
    end

    if not State.BV then
        local bv = Instance.new("BodyVelocity")
        bv.Name = "Gojek_Hold"
        bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        bv.Velocity = Vector3.zero
        bv.Parent = primary
        State.BV = bv
    end
    if not State.BG then
        local bg = Instance.new("BodyGyro")
        bg.Name = "Gojek_Gyro"
        bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        bg.P = 3000
        bg.D = 500
        bg.CFrame = primary.CFrame
        bg.Parent = primary
        State.BG = bg
    end
    return State.BV, State.BG
end
-- =====================================================

-- ==================== NOCLIP PERMANEN ====================
Services.RunService.Stepped:Connect(function()
    if not State.IsNoclipOn then return end
    local bike = getBikeModel()
    if not bike then return end

    for _, part in ipairs(bike:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
    end

    if CharRef.Character and CharRef.Humanoid and CharRef.Humanoid.SeatPart then
        for _, part in ipairs(CharRef.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
        end
    end

    setPassengerCollision(false)

    local primary = getPrimary(bike)
    if primary then
        pcall(function() getHolders(primary) end)
    end
end)

local function setNoclip(state)
    State.IsNoclipOn = state
    if not state then
        destroyHolders()
        local bike = getBikeModel()
        if bike then
            for _, part in ipairs(bike:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
        if CharRef.Character then
            for _, part in ipairs(CharRef.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
        setPassengerCollision(true)
    end
end
-- =====================================================

-- ==================== AUTO RE-SIT ====================
task.spawn(function()
    while true do
        task.wait(0.5)
        if State.IsActive and State.Phase ~= "idle" then
            local hum = CharRef.Humanoid
            local root = CharRef.Root
            local seat = State.LastSeat
            if hum and hum.Health > 0 and not hum.SeatPart and seat and seat.Parent and root then
                print("[Gojek] Karakter terlepas dari kursi, duduk lagi...")
                zeroVelocity(root)
                root.CFrame = seat.CFrame * CFrame.new(0, 2, 0)
                local ok = pcall(function() seat:Sit(hum) end)
                if not ok then
                    pcall(function() hum.Sit = true end)
                end
                task.wait(RESIT_COOLDOWN)
            end
        end
    end
end)
-- =====================================================

-- ============ VOID TP BERTAHAP ============
local function voidTeleportGradual(bike, primary, endPivot)
    local startPivot = bike:GetPivot()
    local totalDist = (endPivot.Position - startPivot.Position).Magnitude
    local totalSteps = math.max(1, math.ceil(totalDist / VOID_STEP_SIZE))
    local startYaw = startPivot.Rotation.Y

    print(string.format("[Gojek] Void TP bertahap: %.0f stud dalam %d langkah", totalDist, totalSteps))

    for step = 1, totalSteps do
        if not State.IsActive then break end

        local alpha = step / totalSteps
        local arcHeight = math.sin(alpha * math.pi) * math.min(VOID_ARC_MAX, totalDist * VOID_ARC_RATIO)
        local interpPos = startPivot.Position:Lerp(endPivot.Position, alpha) + Vector3.new(0, arcHeight, 0)

        local stepPivot = CFrame.new(interpPos) * CFrame.Angles(0, startYaw, 0)
        pcall(function() bike:PivotTo(stepPivot) end)

        zeroVelocity(primary)
        if CharRef.Root then zeroVelocity(CharRef.Root) end

        task.wait(VOID_STEP_DELAY)
    end

    pcall(function() bike:PivotTo(endPivot) end)

    for _ = 1, 3 do
        zeroVelocity(primary)
        if CharRef.Root then zeroVelocity(CharRef.Root) end
        task.wait(0.05)
    end
end
-- ========================================================

local function flyToTarget(targetPos)
    local bike = getBikeModel()
    if not bike then return false end
    local primary = getPrimary(bike)
    if not primary then return false end

    pcall(function() bike:SetNetworkOwner(LocalPlayer) end)
    setNoclip(true)
    setRagdollStates(false)

    local bv, bg = getHolders(primary)
    bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bv.Velocity = Vector3.zero
    zeroVelocity(primary)
    bg.CFrame = bike:GetPivot()

    local reached = false
    local flatTarget = Vector3.new(targetPos.X, 0, targetPos.Z)
    local baseSpeed = math.random(MIN_SPEED_LIMIT, MAX_SPEED_LIMIT)
    local curHorizVel = Vector3.zero
    local smoothedLook = bike:GetPivot()
    local dt = 0.03

    while State.IsActive and State.TargetPos == targetPos do
        if not bv.Parent or not bg.Parent or getPrimary(getBikeModel()) ~= primary then
            break
        end

        local pos = primary.Position
        local flatPos = Vector3.new(pos.X, 0, pos.Z)
        local flatDist = (flatPos - flatTarget).Magnitude

        if flatDist < 15 then
            reached = true
            break
        end

        local dirToTarget = (flatTarget - flatPos).Unit
        local lookAheadPos = pos + dirToTarget * 60
        local groundAheadY = findGroundY(lookAheadPos)
        local steerTarget = targetPos

        if not groundAheadY then
            local foundTP = nil
            for tpDist = VOID_TP_MIN, VOID_TP_MAX, VOID_TP_STEP do
                local tpCheckPos = pos + dirToTarget * tpDist
                local tpGroundY = findGroundY(tpCheckPos)
                if tpGroundY then
                    foundTP = Vector3.new(tpCheckPos.X, tpGroundY + HOVER_HEIGHT, tpCheckPos.Z)
                    break
                end
            end

            if foundTP then
                local startVel = curHorizVel
                for i = 1, 15 do
                    curHorizVel = startVel * (1 - i/15)
                    bv.Velocity = Vector3.new(curHorizVel.X, 0, curHorizVel.Z)
                    task.wait(0.05)
                end
                curHorizVel = Vector3.zero
                bv.Velocity = Vector3.zero
                zeroVelocity(primary)
                task.wait(0.3)

                local endPivot = CFrame.new(foundTP) * CFrame.Angles(0, bike:GetPivot().Rotation.Y, 0)
                voidTeleportGradual(bike, primary, endPivot)

                smoothedLook = bike:GetPivot()
                bg.CFrame = smoothedLook
                task.wait(0.3)
            else
                local rightDir = Vector3.new(dirToTarget.Z, 0, -dirToTarget.X)
                local leftDir = -rightDir
                local bestDetour = nil
                local bestDetourDist = math.huge
                for _, angleDir in ipairs({leftDir, rightDir}) do
                    for _, dist in ipairs({40, 80, 120, 160, 200}) do
                        local checkPos = lookAheadPos + angleDir * dist
                        local checkGroundY = findGroundY(checkPos)
                        if checkGroundY then
                            local distToTarget = (Vector3.new(checkPos.X, 0, checkPos.Z) - flatTarget).Magnitude
                            if distToTarget < bestDetourDist then
                                bestDetourDist = distToTarget
                                bestDetour = checkPos
                            end
                        end
                    end
                end
                if bestDetour then
                    steerTarget = bestDetour
                else
                    steerTarget = pos
                end
            end
        end

        local currentSpeed = baseSpeed
        if flatDist < 60 then
            currentSpeed = math.clamp(flatDist * 2, 15, baseSpeed)
        end
        currentSpeed = currentSpeed * (1 + (math.random(-5, 5) / 100))

        local flatSteerTarget = Vector3.new(steerTarget.X, 0, steerTarget.Z)
        local moveDir = (flatSteerTarget - flatPos).Unit
        if moveDir.X ~= moveDir.X then moveDir = Vector3.zero end
        local desiredVel = moveDir * currentSpeed

        local delta = desiredVel - curHorizVel
        local maxStep = ACCEL * dt
        if delta.Magnitude > maxStep then
            curHorizVel = curHorizVel + delta.Unit * maxStep
        else
            curHorizVel = desiredVel
        end

        local currentGroundY = findGroundY(pos)
        local targetHoverY = currentGroundY and (currentGroundY + HOVER_HEIGHT) or pos.Y
        local yVel = math.clamp((targetHoverY - pos.Y) * 4, -25, 25)

        bv.Velocity = Vector3.new(curHorizVel.X, yVel, curHorizVel.Z)

        if curHorizVel.Magnitude > 1 then
            local wantLook = CFrame.lookAt(pos, pos + Vector3.new(curHorizVel.X, 0, curHorizVel.Z))
            smoothedLook = smoothedLook:Lerp(wantLook, TURN_SMOOTH)
            bg.CFrame = smoothedLook
        end
        task.wait(dt)
    end

    if not reached then
        if bv.Parent then bv.Velocity = Vector3.zero end
        return false
    end

    local lastVel = curHorizVel
    for i = 1, 20 do
        if not bv.Parent then break end
        local v = lastVel * (1 - i/20)
        bv.Velocity = Vector3.new(v.X, 0, v.Z)
        task.wait(0.03)
    end
    if bv.Parent then bv.Velocity = Vector3.zero end

    local groundY = findGroundY(primary.Position)
    local targetLandY = groundY and (groundY + LAND_HEIGHT) or targetPos.Y

    while bv.Parent and primary.Position.Y > targetLandY + 0.5 do
        if not State.IsActive then break end
        bv.Velocity = Vector3.new(0, -5, 0)
        task.wait(0.1)
    end

    if bv.Parent then bv.Velocity = Vector3.zero end
    zeroVelocity(primary)
    task.wait(1.5)
    task.wait(3)
    return true
end

-- Event handling
TaxiEvent.OnClientEvent:Connect(function(action, data)
    if not State.IsActive then return end
    local d = data or {}
    if action == "DutyStarted" then
        State.IsOnline = true
        State.Phase = "idle"
        print("[Gojek] DutyStarted")

    elseif action == "DutyEnded" then
        State.IsOnline = false
        State.Phase = "idle"
        State.TargetPos = nil
        print("[Gojek] DutyEnded")

    elseif action == "OrderOffer" and State.Phase == "idle" then
        State.Token = d.Token
        State.Phase = "offered"
        print(string.format("[Gojek] OrderOffer: %s (Rp %d)", tostring(d.PassengerName), tonumber(d.Fare) or 0))
        TaxiEvent:FireServer("AcceptOrder", State.Token)

    elseif action == "OrderAccepted" and State.Token == d.Token then
        State.TargetPos = d.PickupPos
        State.Phase = "goingPickup"
        print("[Gojek] OrderAccepted -> Jemput")

    elseif action == "PassengerBoarding" and State.Phase == "goingPickup" then
        State.Phase = "waitingBoard"
        print("[Gojek] Penumpang boarding... (Stabilisasi 3 detik)")
        task.wait(3)

    elseif action == "TripStarted" and State.Phase == "waitingBoard" then
        State.TargetPos = d.DropPos
        State.Phase = "goingDrop"
        print("[Gojek] TripStarted -> Antar")

    elseif action == "OrderCompleted" then
        State.TripCount += 1
        local earned = tonumber(d.Earned or d.FareEarned) or 0
        State.Earnings += earned
        local paxName = d.PassengerName or "Penumpang"

        print(string.format("[Gojek] Selesai! Trip #%d, Total Rp %d", State.TripCount, State.Earnings))

        task.spawn(function()
            sendDiscordWebhook(paxName, earned)
        end)

        task.delay(1, function() TaxiEvent:FireServer("AckTripComplete") end)
        State.Token = nil
        State.TargetPos = nil
        State.Phase = "idle"

    elseif action == "OrderExpired" or action == "OrderDeclined" or action == "OrderCancelled" then
        print("[Gojek] Order gagal: "..action)
        State.Token = nil
        State.TargetPos = nil
        State.Phase = "idle"
    end
end)

task.spawn(function()
    while true do
        task.wait(0.3)
        if State.IsActive and State.TargetPos and (State.Phase == "goingPickup" or State.Phase == "goingDrop") then
            flyToTarget(State.TargetPos)
        end
    end
end)

-- =====================================================
-- ================== START / STOP CORE ================
-- =====================================================
local function applyActiveState(isActive, fromUI)
    if isActive == State.IsActive then return end
    State.IsActive = isActive

    if isActive then
        setNoclip(true)
        setRagdollStates(false)
        print("[Gojek] ✅ ON - Noclip permanen, GoOnline")
        if not State.IsOnline then
            pcall(function() TaxiEvent:FireServer("GoOnline") end)
        end
    else
        State.TargetPos = nil
        State.Phase = "idle"
        State.Token = nil
        setNoclip(false)
        setRagdollStates(true)
        State.LastSeat = nil
        print("[Gojek] ❌ OFF - Noclip off, GoOffline")
        if State.IsOnline then
            pcall(function() TaxiEvent:FireServer("GoOffline") end)
        end
        State.IsOnline = false
    end
end

-- Cek apakah pemain saat ini Driver (auto trigger kalau UI ON)
local function isDriverTeam()
    return LocalPlayer.Team and LocalPlayer.Team.Name == "RideGO Driver"
end

local function refreshActiveState()
    if State.ToggleOn and isDriverTeam() then
        applyActiveState(true)
    else
        applyActiveState(false)
    end
end

LocalPlayer:GetPropertyChangedSignal("Team"):Connect(refreshActiveState)

-- =====================================================
-- ====================== UI ===========================
-- =====================================================
local function createUI()
    local parentGui = (gethui and gethui()) or game:GetService("CoreGui")

    local old = parentGui:FindFirstChild("AutoGojekUI")
    if old then old:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoGojekUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = parentGui

    -- Frame utama
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "Main"
    mainFrame.Size = UDim2.new(0, 200, 0, 92)
    mainFrame.Position = UDim2.new(0, 20, 0, 120)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 65, 90)
    stroke.Thickness = 1.5
    stroke.Parent = mainFrame

    -- Judul
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 28)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🚖 Auto Gojek"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.Parent = mainFrame

    -- Status
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.Size = UDim2.new(1, -20, 0, 18)
    statusLabel.Position = UDim2.new(0, 10, 0, 30)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: OFF"
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 12
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = mainFrame

    -- Tombol ON/OFF
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "ToggleBtn"
    toggleBtn.Size = UDim2.new(1, -20, 0, 32)
    toggleBtn.Position = UDim2.new(0, 10, 1, -42)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Text = "OFF"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 14
    toggleBtn.AutoButtonColor = false
    toggleBtn.Parent = mainFrame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = toggleBtn

    local function updateUI()
        if State.ToggleOn then
            Services.TweenService:Create(toggleBtn, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(60, 200, 100)
            }):Play()
            toggleBtn.Text = "ON"
            statusLabel.Text = State.IsActive and "Status: ON (Aktif)" or "Status: ON (Menunggu tim Driver)"
            statusLabel.TextColor3 = Color3.fromRGB(120, 230, 150)
        else
            Services.TweenService:Create(toggleBtn, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(220, 60, 60)
            }):Play()
            toggleBtn.Text = "OFF"
            statusLabel.Text = "Status: OFF"
            statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end

    toggleBtn.MouseButton1Click:Connect(function()
        State.ToggleOn = not State.ToggleOn
        updateUI()
        refreshActiveState()
    end)

    updateUI()

    -- Minimize
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Size = UDim2.new(0, 22, 0, 22)
    minimizeBtn.Position = UDim2.new(1, -26, 0, 3)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 44, 60)
    minimizeBtn.BorderSizePixel = 0
    minimizeBtn.Text = "–"
    minimizeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.TextSize = 16
    minimizeBtn.Parent = mainFrame

    local mCorner = Instance.new("UICorner")
    mCorner.CornerRadius = UDim.new(0, 6)
    mCorner.Parent = minimizeBtn

    local minimized = false
    local fullSize = UDim2.new(0, 200, 0, 92)
    local miniSize = UDim2.new(0, 90, 0, 28)

    minimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            Services.TweenService:Create(mainFrame, TweenInfo.new(0.15), { Size = miniSize }):Play()
            title.Text = "🚖 Auto"
            statusLabel.Visible = false
            toggleBtn.Visible = false
        else
            Services.TweenService:Create(mainFrame, TweenInfo.new(0.15), { Size = fullSize }):Play()
            title.Text = "🚖 Auto Gojek"
            statusLabel.Visible = true
            toggleBtn.Visible = true
        end
    end)

    -- Update status berkala
    task.spawn(function()
        while screenGui.Parent do
            task.wait(0.5)
            if State.ToggleOn then
                if State.IsActive then
                    local phaseText = State.Phase ~= "idle" and (" | "..State.Phase) or ""
                    statusLabel.Text = string.format("Status: ON%s\nTrip: %d | Rp %d", phaseText, State.TripCount, State.Earnings)
                else
                    statusLabel.Text = "Status: ON (Menunggu tim Driver)"
                end
            end
        end
    end)

    return screenGui
end

createUI()

print("[Gojek] === Auto Gojek Siap ===")
print("[Gojek] UI: klik tombol ON/OFF untuk aktif/nonaktif.")
print("[Gojek] Fitur: Anti Terpental, Ramp Speed, Auto Re-sit, Noclip Permanen, Void TP Bertahap, Webhook.")
