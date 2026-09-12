--[[
================================================================================
  👑 KING AKBAR - CAR DRIVING INDONESIA
  MODERN DASHBOARD + DELIVERY ASSISTANT + WEBHOOK INTEGRATION
  VERSION: PROFESSIONAL EDITION — NEW ENGINE
  Features: Auto Clear Building (Robust), Instant Arrival, Auto Retry
  PATCH: No Noclip saat masuk truk + Altitude 5000 + Robust Building Clear
  PATCH: Deskripsi metode dikosongkan (stealth)
  PATCH: Potato Mode & 60 FPS Cap on Auto Start
  PATCH: Webhook Report — Anonymized & Professional (No Clickable Links)
================================================================================
--]]

-- ============================================================================
-- // 0. LOAD WINDUI (SAFE)
-- ============================================================================
local WindUI
do
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(
            "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
        ))()
    end)
    if ok and result then
        WindUI = result
    else
        warn("[King Akbar] WindUI failed to load: " .. tostring(result))
        return
    end
end

-- ============================================================================
-- // 0.5 CORE PAUSE BYPASS
-- ============================================================================
pcall(function()
    local CoreGui = game:GetService("CoreGui")
    if CoreGui:FindFirstChild("RobloxGui") then
        local pauseScript = CoreGui.RobloxGui:FindFirstChild("CoreScripts/NetworkPause")
        if pauseScript then pauseScript:Destroy() end
    end
end)

-- ============================================================================
-- // 1. SERVICES
-- ============================================================================
local Services = {
    Players           = game:GetService("Players"),
    RunService        = game:GetService("RunService"),
    UserInput         = game:GetService("UserInputService"),
    Stats             = game:GetService("Stats"),
    TweenSvc          = game:GetService("TweenService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    VirtualInput      = game:GetService("VirtualInputManager"),
    CoreGui           = game:GetService("CoreGui"),
    HttpService       = game:GetService("HttpService"),
    StarterGui        = game:GetService("StarterGui"),
    VirtualUser       = game:GetService("VirtualUser"),
    Workspace         = game:GetService("Workspace"),
}

local LocalPlayer = Services.Players.LocalPlayer

local IsMobile = Services.UserInput.TouchEnabled
    and not Services.UserInput.KeyboardEnabled
    and not Services.UserInput.MouseEnabled

-- ============================================================================
-- // 1.5 GLOBAL STATS
-- ============================================================================
local Stats = {
    moneyBefore = 0,
    moneyNow    = 0,
    deliveries  = 0,
    farmTime    = 0,
    startTime   = os.time(),
}

-- ============================================================================
-- // 2. SPLASH SCREEN
-- ============================================================================
do
    local sg = Instance.new("ScreenGui")
    sg.Name = "KingAkbarSplash"; sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true; sg.DisplayOrder = 999
    sg.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local bg = Instance.new("Frame", sg)
    bg.Size = UDim2.fromScale(1,1); bg.BackgroundColor3 = Color3.fromHex("#0a0a0a")
    bg.BorderSizePixel = 0; bg.ZIndex = 1

    local grad = Instance.new("UIGradient", bg)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromHex("#0a0a0a")),
        ColorSequenceKeypoint.new(1, Color3.fromHex("#1e1e1e")),
    }); grad.Rotation = 135

    local ct = Instance.new("Frame", bg)
    ct.Size = UDim2.fromOffset(500, 300); ct.Position = UDim2.fromScale(0.5, 0.5)
    ct.AnchorPoint = Vector2.new(0.5, 0.5); ct.BackgroundTransparency = 1; ct.ZIndex = 2

    local function mkLabel(txt, yOff, sz)
        local l = Instance.new("TextLabel", ct)
        l.Size = UDim2.fromOffset(500, 70); l.Position = UDim2.fromOffset(0, yOff)
        l.BackgroundTransparency = 1; l.Text = txt; l.TextSize = sz
        l.Font = Enum.Font.GothamBold; l.TextColor3 = Color3.fromHex("#ffffff")
        l.TextTransparency = 1; l.ZIndex = 3; return l
    end

    local icon = Instance.new("ImageLabel", ct)
    icon.Size = UDim2.fromOffset(120, 120); icon.Position = UDim2.fromOffset(190, -40)
    icon.BackgroundTransparency = 1; icon.Image = "rbxassetid://91115084979317"
    icon.ImageTransparency = 1; icon.ZIndex = 3

    local title = mkLabel("King Akbar", 70, IsMobile and 38 or 50)
    local tg = Instance.new("UIGradient", title)
    tg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromHex("#ffffff")),
        ColorSequenceKeypoint.new(0.5, Color3.fromHex("#aaaaaa")),
        ColorSequenceKeypoint.new(1,   Color3.fromHex("#555555")),
    }); tg.Rotation = 45

    local stat = mkLabel("Initializing system...", 200, 12)
    stat.Font = Enum.Font.Gotham; stat.TextColor3 = Color3.fromHex("#555555")
    stat.TextXAlignment = Enum.TextXAlignment.Left; stat.Position = UDim2.fromOffset(50, 200)

    local line = Instance.new("Frame", ct)
    line.Size = UDim2.fromOffset(0, 2); line.Position = UDim2.fromOffset(250, 152)
    line.AnchorPoint = Vector2.new(0.5, 0); line.BackgroundColor3 = Color3.fromHex("#444444")
    line.BorderSizePixel = 0; line.ZIndex = 3

    local barBg = Instance.new("Frame", ct)
    barBg.Size = UDim2.fromOffset(400, 5); barBg.Position = UDim2.fromOffset(50, 190)
    barBg.BackgroundColor3 = Color3.fromHex("#222222"); barBg.BackgroundTransparency = 1
    barBg.BorderSizePixel = 0; barBg.ZIndex = 3
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

    local bar = Instance.new("Frame", barBg)
    bar.Size = UDim2.fromOffset(0, 5); bar.BackgroundColor3 = Color3.fromHex("#ffffff")
    bar.BorderSizePixel = 0; bar.ZIndex = 4
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local function tw(obj, props, t)
        Services.TweenSvc:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
    end

    task.spawn(function()
        tw(icon,  { ImageTransparency = 0 }, 0.5); task.wait(0.15)
        tw(title, { TextTransparency  = 0 }, 0.6); task.wait(0.35)
        tw(line,  { Size = UDim2.fromOffset(400, 2) }, 0.7); task.wait(0.4)
        tw(barBg, { BackgroundTransparency = 0 }, 0.3)
        tw(stat,  { TextTransparency = 0 }, 0.3)
        for _, s in ipairs({
            { "Loading UI Library...",     0.30 },
            { "Verifying License...",      0.60 },
            { "Welcome, King Akbar!",      1.00 },
        }) do
            stat.Text = s[1]
            tw(bar, { Size = UDim2.fromOffset(400 * s[2], 5) }, 0.5)
            task.wait(0.55)
        end
        task.wait(0.3)
        for _, p in ipairs({ bg, icon, title, line, barBg, bar, stat }) do
            local prop = p == stat and "TextTransparency"
                or (p == icon  and "ImageTransparency" or "BackgroundTransparency")
            if p == title then prop = "TextTransparency" end
            tw(p, { [prop] = 1 }, 0.4)
        end
        task.wait(0.8); sg:Destroy()
    end)
    task.wait(3)
end

-- ============================================================================
-- // 3. CREATE WINDOW
-- ============================================================================
local wSz  = IsMobile and UDim2.fromOffset(420, 320) or UDim2.fromOffset(580, 460)
local mnSz = IsMobile and Vector2.new(600, 300) or Vector2.new(600, 350)
local mxSz = IsMobile and Vector2.new(650, 400) or Vector2.new(850, 560)

local Window = WindUI:CreateWindow({
    Title                       = "King Akbar - Car Driving Indonesia",
    Icon                        = "crown",
    Author                      = "King Akbar",
    Folder                      = "KingAkbarHub",
    Size                        = wSz,
    MinSize                     = mnSz,
    MaxSize                     = mxSz,
    Transparent                 = false,
    Background                  = "rbxassetid://127295801178451",
    BackgroundImageTransparency = 0.5,
    Theme                       = "Dark",
    Resizable                   = true,
    SideBarWidth                = 210,
    HideSearchBar               = false,
    ScrollBarEnabled            = true,
})

-- ============================================================================
-- // 4. TABS
-- ============================================================================
local InfoTab    = Window:Tab({ Title = "Info",    Icon = "info",    Border = true })
local FarmTab    = Window:Tab({ Title = "Farm",    Icon = "truck",   Border = true })
local WebhookTab = Window:Tab({ Title = "Webhook", Icon = "webhook", Border = true })

-- ============================================================================
-- // 5. INFO TAB
-- ============================================================================
local memberCount = "N/A"
local onlineCount = "N/A"

local function fetchDiscordInfo()
    local req = request or http_request or (syn and syn.request)
    if not req then return end
    local ok, res = pcall(function()
        return req({
            Url     = "https://discord.com/api/v9/invites/XmWf3YQPpZ?with_counts=true",
            Method  = "GET",
            Headers = { ["User-Agent"] = "Mozilla/5.0" }
        })
    end)
    if ok and res and res.StatusCode == 200 then
        local ok2, data = pcall(function() return Services.HttpService:JSONDecode(res.Body) end)
        if ok2 and data then
            memberCount = tostring(data.approximate_member_count   or "N/A")
            onlineCount = tostring(data.approximate_presence_count or "N/A")
        end
    end
end
fetchDiscordInfo()

local ServerInfo = InfoTab:Paragraph({
    Title         = "King Vypers | Official",
    Desc          = "• Member Count: " .. memberCount .. "\n• Online Count: " .. onlineCount,
    Image         = "rbxassetid://107726435417936",
    Thumbnail     = "rbxassetid://83197533072664",
    ThumbnailSize = 80,
    Buttons = {
        {
            Title    = "Copy Discord Invite",
            Color    = Color3.fromHex("#5707AB"),
            Icon     = "link",
            Callback = function()
                if setclipboard then setclipboard("https://discord.gg/XmWf3YQPpZ") end
            end
        },
        {
            Title    = "Update Info",
            Icon     = "refresh-cw",
            Callback = function()
                fetchDiscordInfo()
                ServerInfo:SetDesc("• Member Count: " .. memberCount .. "\n• Online Count: " .. onlineCount)
            end
        }
    }
})

-- ============================================================================
-- // 6. MONEY TRACKER OVERLAY — MINIMALIST DASHBOARD
-- ============================================================================
local C = {
    BG         = Color3.fromHex("#0A0C10"),
    PANEL      = Color3.fromHex("#12161F"),
    CARD       = Color3.fromHex("#181E29"),
    CARD2      = Color3.fromHex("#1F2633"),
    TEXT_MAIN  = Color3.fromHex("#F3F4F6"),
    TEXT_SUB   = Color3.fromHex("#9CA3AF"),
    TEXT_DIM   = Color3.fromHex("#4B5563"),
    BORDER     = Color3.fromHex("#2A303C"),
    GREEN      = Color3.fromHex("#10B981"),
    BLUE       = Color3.fromHex("#3B82F6"),
    RED        = Color3.fromHex("#EF4444"),
}

local moneyTrackerGui = Instance.new("ScreenGui")
moneyTrackerGui.Name           = "MoneyTrackerUI"
moneyTrackerGui.ResetOnSpawn   = false
moneyTrackerGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
moneyTrackerGui.IgnoreGuiInset = true
moneyTrackerGui.Parent         = Services.CoreGui
moneyTrackerGui.Enabled        = false

local root = Instance.new("Frame", moneyTrackerGui)
root.Size = UDim2.new(1,0,1,0); root.BorderSizePixel = 0
root.BackgroundColor3 = C.BG; root.Active = true

local MT_wrap = Instance.new("Frame", root)
MT_wrap.Size = UDim2.new(0,960,0,540)
MT_wrap.AnchorPoint = Vector2.new(0.5,0.5)
MT_wrap.Position = UDim2.new(0.5,0,0.5,22)
MT_wrap.BackgroundTransparency = 1

local MT_scale = Instance.new("UIScale", MT_wrap)
local MT_cam   = Services.Workspace.CurrentCamera
local function MT_doScale()
    local vp = MT_cam.ViewportSize
    MT_scale.Scale = math.clamp(math.min((vp.X*0.92)/960,(vp.Y*0.90)/540), 0.36, 1.05)
end
MT_doScale()
MT_cam:GetPropertyChangedSignal("ViewportSize"):Connect(MT_doScale)

local function cr(p, r)
    Instance.new("UICorner", p).CornerRadius = UDim.new(0, r or 10)
end
local function mkStroke(p, col, th, tr)
    local s = Instance.new("UIStroke", p)
    s.Color = col; s.Thickness = th or 1; s.Transparency = tr or 0.8
    return s
end
local function mkFr(parent, props)
    local f = Instance.new("Frame", parent); f.BorderSizePixel = 0
    for k,v in pairs(props) do f[k] = v end; return f
end
local function mkLb(parent, props)
    local l = Instance.new("TextLabel", parent); l.BackgroundTransparency = 1
    for k,v in pairs(props) do l[k] = v end; return l
end

-- HEADER
local header = mkFr(MT_wrap, {
    Size=UDim2.new(1,0,0,44), BackgroundColor3=C.PANEL
}); cr(header, 10); mkStroke(header, C.BORDER, 1)

mkFr(header, {
    Size=UDim2.new(1,0,0,2), Position=UDim2.new(0,0,0,0),
    BackgroundColor3=C.BLUE
}); cr(mkFr(header,{}), 2)

mkLb(header, {
    Size=UDim2.new(0,340,1,0), Position=UDim2.new(0,16,0,0),
    Text="KING AKBAR  |  CAR DRIVING INDONESIA",
    TextColor3=C.TEXT_MAIN, Font=Enum.Font.GothamBold, TextSize=13,
    TextXAlignment=Enum.TextXAlignment.Left,
})

local pillFr = mkFr(header, {
    Size=UDim2.new(0,140,0,26), Position=UDim2.new(0.5,-70,0.5,-13),
    BackgroundColor3=C.CARD,
}); cr(pillFr,13); mkStroke(pillFr, C.BORDER, 1)

local pillDot = mkFr(pillFr, {
    Size=UDim2.new(0,7,0,7), Position=UDim2.new(0,13,0.5,-3.5),
    BackgroundColor3=C.GREEN,
}); Instance.new("UICorner",pillDot).CornerRadius=UDim.new(1,0)

mkLb(pillFr, {
    Size=UDim2.new(1,-28,1,0), Position=UDim2.new(0,28,0,0),
    Text="SYSTEM ONLINE", TextColor3=C.GREEN,
    Font=Enum.Font.GothamBold, TextSize=11,
    TextXAlignment=Enum.TextXAlignment.Left,
})

local MT_LiveStats = mkLb(header, {
    Size=UDim2.new(0,210,1,0), Position=UDim2.new(1,-226,0,0),
    Text="PING ??  ·  FPS ??", TextColor3=C.TEXT_SUB,
    Font=Enum.Font.GothamBold, TextSize=12,
    TextXAlignment=Enum.TextXAlignment.Right,
})

-- CONTENT
local LW, RW, CY, CH = 592, 358, 52, 452

local leftPanel  = mkFr(MT_wrap, {Size=UDim2.new(0,LW,0,CH), Position=UDim2.new(0,0,0,CY), BackgroundTransparency=1})
local rightPanel = mkFr(MT_wrap, {Size=UDim2.new(0,RW,0,CH), Position=UDim2.new(0,LW+10,0,CY), BackgroundTransparency=1})

-- HERO BALANCE
local heroCard = mkFr(leftPanel, {
    Size=UDim2.new(1,0,0,180), BackgroundColor3=C.CARD,
}); cr(heroCard,14); mkStroke(heroCard, C.BORDER, 1)

mkLb(heroCard, {
    Size=UDim2.new(1,-30,0,18), Position=UDim2.new(0,22,0,20),
    Text="CURRENT BALANCE",
    TextColor3=C.TEXT_SUB, Font=Enum.Font.GothamMedium, TextSize=11,
    TextXAlignment=Enum.TextXAlignment.Left,
})

local MT_balanceMain = mkLb(heroCard, {
    Size=UDim2.new(1,-30,0,66), Position=UDim2.new(0,20,0,42),
    Text="Rp. 0", TextColor3=C.TEXT_MAIN,
    Font=Enum.Font.GothamBlack, TextSize=52,
    TextXAlignment=Enum.TextXAlignment.Left,
})

local progTrack = mkFr(heroCard, {
    Size=UDim2.new(1,-44,0,4), Position=UDim2.new(0,22,0,130),
    BackgroundColor3=C.TEXT_DIM,
}); cr(progTrack, 2)

local progFill = mkFr(progTrack, {
    Size=UDim2.new(0,0,1,0), BackgroundColor3=C.GREEN,
}); cr(progFill, 2)

local MT_progLabel = mkLb(heroCard, {
    Size=UDim2.new(1,-44,0,20), Position=UDim2.new(0,22,0,145),
    Text="SESSION GAIN: Rp. 0  —  TARGET Rp. 5.000.000",
    TextColor3=C.TEXT_SUB, Font=Enum.Font.GothamMedium, TextSize=11,
    TextXAlignment=Enum.TextXAlignment.Left,
})

-- ROW 2: MAIN CARDS
local R2W = (LW - 10) / 2

local function mkMainCard(xOff, col, title)
    local card = mkFr(leftPanel, {
        Size=UDim2.new(0,R2W,0,110), Position=UDim2.new(0,xOff,0,190),
        BackgroundColor3=C.CARD,
    }); cr(card,12); mkStroke(card, C.BORDER, 1)
    mkLb(card, {
        Size=UDim2.new(1,-22,0,18), Position=UDim2.new(0,20,0,16),
        Text=title, TextColor3=C.TEXT_SUB,
        Font=Enum.Font.GothamMedium, TextSize=10,
        TextXAlignment=Enum.TextXAlignment.Left,
    })
    local val = mkLb(card, {
        Size=UDim2.new(1,-22,0,46), Position=UDim2.new(0,20,0,54),
        Text="Rp. 0", TextColor3=col,
        Font=Enum.Font.GothamBold, TextSize=22,
        TextXAlignment=Enum.TextXAlignment.Left,
    })
    return val
end

local MT_valProfit  = mkMainCard(0,      C.GREEN, "TOTAL PROFIT")
local MT_valPerHour = mkMainCard(R2W+10, C.GREEN, "INCOME / HOUR")

-- ROW 3: MINI CARDS
local R3W = (LW - 20) / 3

local function mkMiniCard(xOff, col, title)
    local card = mkFr(leftPanel, {
        Size=UDim2.new(0,R3W,0,70), Position=UDim2.new(0,xOff,0,310),
        BackgroundColor3=C.CARD2,
    }); cr(card,10); mkStroke(card, C.BORDER, 1)
    mkLb(card, {
        Size=UDim2.new(1,-14,0,18), Position=UDim2.new(0,16,0,8),
        Text=title, TextColor3=C.TEXT_SUB,
        Font=Enum.Font.GothamMedium, TextSize=9,
        TextXAlignment=Enum.TextXAlignment.Left,
    })
    local val = mkLb(card, {
        Size=UDim2.new(1,-14,0,32), Position=UDim2.new(0,16,0,34),
        Text="—", TextColor3=col,
        Font=Enum.Font.GothamBold, TextSize=15,
        TextXAlignment=Enum.TextXAlignment.Left,
    })
    return val
end

local MT_valPerDeliv   = mkMiniCard(0,          C.TEXT_MAIN, "PER DELIVERY")
local MT_valDelPerHour = mkMiniCard(R3W+10,     C.TEXT_MAIN, "DEL / HOUR")
local MT_valInitial    = mkMiniCard((R3W+10)*2, C.TEXT_MAIN, "START BALANCE")

-- ROW 4: INFO STRIP
local infoStrip = mkFr(leftPanel, {
    Size=UDim2.new(1,0,0,62), Position=UDim2.new(0,0,0,390),
    BackgroundColor3=C.PANEL,
}); cr(infoStrip,12); mkStroke(infoStrip, C.BORDER, 1)

mkLb(infoStrip, {
    Size=UDim2.new(0.6,-14,1,0), Position=UDim2.new(0,18,0,0),
    Text="Delivery System  ·  Car Driving Indonesia",
    TextColor3=C.TEXT_SUB, Font=Enum.Font.GothamMedium, TextSize=10,
    TextXAlignment=Enum.TextXAlignment.Left,
})
mkLb(infoStrip, {
    Size=UDim2.new(0.4,-14,1,0), Position=UDim2.new(0.6,0,0,0),
    Text="KING AKBAR HUB",
    TextColor3=C.TEXT_DIM, Font=Enum.Font.GothamMedium, TextSize=9,
    TextXAlignment=Enum.TextXAlignment.Right,
})

-- RIGHT PANEL: DELIVERIES
local delivCard = mkFr(rightPanel, {
    Size=UDim2.new(1,0,0,160), BackgroundColor3=C.CARD,
}); cr(delivCard,14); mkStroke(delivCard, C.BORDER, 1)

mkLb(delivCard, {
    Size=UDim2.new(1,-18,0,18), Position=UDim2.new(0,18,0,16),
    Text="DELIVERIES COMPLETED", TextColor3=C.TEXT_SUB,
    Font=Enum.Font.GothamBold, TextSize=10,
    TextXAlignment=Enum.TextXAlignment.Left,
})

local MT_delivCount = mkLb(delivCard, {
    Size=UDim2.new(0,120,0,60), Position=UDim2.new(0,18,0,40),
    Text="0", TextColor3=C.TEXT_MAIN,
    Font=Enum.Font.GothamBlack, TextSize=56,
    TextXAlignment=Enum.TextXAlignment.Left,
})

local chartFr = mkFr(delivCard, {
    Size=UDim2.new(0,176,0,55), Position=UDim2.new(1,-194,0,48),
    BackgroundTransparency=1, ClipsDescendants=true,
})

local delivBars = {}
for i = 1, 9 do
    local b = mkFr(chartFr, {
        Size=UDim2.new(0,14,0,4),
        Position=UDim2.new(0,(i-1)*20,1,-4),
        BackgroundColor3=C.TEXT_DIM,
    }); cr(b,4)
    table.insert(delivBars, b)
end

mkFr(delivCard, {
    Size=UDim2.new(0,176,0,1), Position=UDim2.new(1,-194,0,104),
    BackgroundColor3=C.BORDER,
})

mkLb(delivCard, {
    Size=UDim2.new(1,-20,0,14), Position=UDim2.new(0,18,1,-22),
    Text="DELIVERY HISTORY",
    TextColor3=C.TEXT_DIM, Font=Enum.Font.Gotham, TextSize=8,
    TextXAlignment=Enum.TextXAlignment.Left,
})

local delivHistory   = {0,0,0,0,0,0,0,0,0}
local lastDelivMoney = 0
local updateDelivBars

updateDelivBars = function()
    local maxVal = 0
    for _, v in ipairs(delivHistory) do if v > maxVal then maxVal = v end end
    if maxVal == 0 then maxVal = 1 end
    for i, bar in ipairs(delivBars) do
        local pct = delivHistory[i] / maxVal
        local h   = math.max(4, math.floor(pct * 50))
        Services.TweenSvc:Create(bar, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
            Size = UDim2.new(0,14,0,h),
            BackgroundColor3 = pct > 0 and C.GREEN or C.TEXT_DIM,
        }):Play()
    end
end

-- SESSION TIME
local uptimeCard = mkFr(rightPanel, {
    Size=UDim2.new(1,0,0,90), Position=UDim2.new(0,0,0,170),
    BackgroundColor3=C.CARD,
}); cr(uptimeCard,12); mkStroke(uptimeCard, C.BORDER, 1)

mkLb(uptimeCard, {
    Size=UDim2.new(0.5,0,0,18), Position=UDim2.new(0,18,0,16),
    Text="SESSION TIME", TextColor3=C.TEXT_SUB,
    Font=Enum.Font.GothamBold, TextSize=10,
    TextXAlignment=Enum.TextXAlignment.Left,
})

local MT_uptimeVal = mkLb(uptimeCard, {
    Size=UDim2.new(0.5,0,0,38), Position=UDim2.new(0,18,0,40),
    Text="00:00", TextColor3=C.TEXT_MAIN,
    Font=Enum.Font.GothamBlack, TextSize=32,
    TextXAlignment=Enum.TextXAlignment.Left,
})

local elapsedTrack = mkFr(uptimeCard, {
    Size=UDim2.new(0.45,-10,0,4), Position=UDim2.new(0.55,0,0.5,8),
    BackgroundColor3=C.TEXT_DIM,
}); cr(elapsedTrack,2)
local elapsedFill = mkFr(elapsedTrack, {
    Size=UDim2.new(0,0,1,0), BackgroundColor3=C.TEXT_MAIN,
}); cr(elapsedFill,2)
mkLb(uptimeCard, {
    Size=UDim2.new(0.45,-10,0,18), Position=UDim2.new(0.55,0,0.5,-22),
    Text="MAX SESSION 2H", TextColor3=C.TEXT_DIM,
    Font=Enum.Font.GothamMedium, TextSize=9,
    TextXAlignment=Enum.TextXAlignment.Left,
})

-- NETWORK
local netCard = mkFr(rightPanel, {
    Size=UDim2.new(1,0,0,90), Position=UDim2.new(0,0,0,270),
    BackgroundColor3=C.CARD,
}); cr(netCard,12); mkStroke(netCard, C.BORDER, 1)

mkLb(netCard, {
    Size=UDim2.new(1,-18,0,18), Position=UDim2.new(0,18,0,12),
    Text="NETWORK STATUS", TextColor3=C.TEXT_SUB,
    Font=Enum.Font.GothamBold, TextSize=10,
    TextXAlignment=Enum.TextXAlignment.Left,
})

mkFr(netCard, {
    Size=UDim2.new(0,1,0.45,0), Position=UDim2.new(0.5,0,0.32,0),
    BackgroundColor3=C.BORDER,
})

local function mkNetStat(xPct, labelTxt)
    mkLb(netCard, {
        Size=UDim2.new(0.5,-20,0,18), Position=UDim2.new(xPct,18,0,36),
        Text=labelTxt, TextColor3=C.TEXT_DIM,
        Font=Enum.Font.GothamMedium, TextSize=9,
        TextXAlignment=Enum.TextXAlignment.Left,
    })
    return mkLb(netCard, {
        Size=UDim2.new(0.5,-20,0,32), Position=UDim2.new(xPct,18,0,54),
        Text="—", TextColor3=C.TEXT_MAIN,
        Font=Enum.Font.GothamBold, TextSize=22,
        TextXAlignment=Enum.TextXAlignment.Left,
    })
end

local MT_pingVal = mkNetStat(0,   "SERVER PING")
local MT_fpsVal  = mkNetStat(0.5, "CLIENT FPS")

-- STATUS BADGE
local statusCard = mkFr(rightPanel, {
    Size=UDim2.new(1,0,0,78), Position=UDim2.new(0,0,0,370),
    BackgroundColor3=C.CARD,
}); cr(statusCard,12); mkStroke(statusCard, C.BORDER, 1)

local MT_statusDot = mkFr(statusCard, {
    Size=UDim2.new(0,10,0,10), Position=UDim2.new(0,18,0.5,-5),
    BackgroundColor3=C.GREEN,
}); Instance.new("UICorner",MT_statusDot).CornerRadius=UDim.new(1,0)

mkLb(statusCard, {
    Size=UDim2.new(1,-50,0,22), Position=UDim2.new(0,36,0,18),
    Text="DELIVERY SYSTEM ACTIVE", TextColor3=C.TEXT_MAIN,
    Font=Enum.Font.GothamBold, TextSize=13,
    TextXAlignment=Enum.TextXAlignment.Left,
})
mkLb(statusCard, {
    Size=UDim2.new(1,-50,0,18), Position=UDim2.new(0,36,0,42),
    Text="CAR DRIVING INDONESIA  ·  SESSION ACTIVE",
    TextColor3=C.TEXT_SUB, Font=Enum.Font.GothamMedium, TextSize=9,
    TextXAlignment=Enum.TextXAlignment.Left,
})

-- SCAN LINE
local scanLine = mkFr(MT_wrap, {
    Size=UDim2.new(1,0,0,1), BackgroundColor3=C.TEXT_DIM,
    BackgroundTransparency=0.95, ZIndex=9,
})

task.spawn(function()
    local y = 0
    while true do
        task.wait(0.018)
        if moneyTrackerGui.Enabled then
            y = (y + 0.003) % 1.02
            scanLine.Position = UDim2.new(0,0,y,0)
        end
    end
end)

-- TICKER
local tickerFr = mkFr(MT_wrap, {
    Size=UDim2.new(1,0,0,28), Position=UDim2.new(0,0,1,-28),
    BackgroundColor3=C.PANEL, ClipsDescendants=true,
}); cr(tickerFr,8); mkStroke(tickerFr, C.BORDER, 1)

local tickerStr = "DELIVERY SYSTEM ACTIVE  ·  KING AKBAR  ·  CAR DRIVING INDONESIA  ·  TRUCK DELIVERY SYSTEM  ·  KING VYPERS  ·  SYSTEM ONLINE  ·  DELIVERY SYSTEM ACTIVE  ·  CAR DRIVING INDONESIA  ·  "

local tickerLb = mkLb(tickerFr, {
    Size=UDim2.new(3,0,1,0), Position=UDim2.new(0,0,0,0),
    Text=tickerStr, TextColor3=C.TEXT_DIM,
    Font=Enum.Font.GothamBold, TextSize=10,
    TextXAlignment=Enum.TextXAlignment.Left,
})

task.spawn(function()
    local p = 0
    while true do
        task.wait(0.018)
        if moneyTrackerGui.Enabled then
            p = p - 0.0003
            if p <= -1 then p = 0 end
            tickerLb.Position = UDim2.new(p,0,0,0)
        end
    end
end)

-- LOGIC & STATE
local bestDelivProfit = 0
local bestPerHour     = 0

local function parseMoney(text)
    if not text then return 0 end
    local clean = text:gsub("[^%d]", "")
    return tonumber(clean) or 0
end

local function getMoney()
    local ok, val = pcall(function()
        return LocalPlayer.PlayerGui.Main.Container.Hub.CashFrame.Frame.TextLabel.Text
    end)
    if ok and val then return parseMoney(val) end
    return 0
end

local function formatMoney(n)
    local s = tostring(math.floor(math.abs(n)))
    local result = ""
    local count  = 0
    for i = #s, 1, -1 do
        count  = count + 1
        result = s:sub(i, i) .. result
        if count % 3 == 0 and i ~= 1 then result = "," .. result end
    end
    return "Rp. " .. result
end

local function formatTime(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)
    if h > 0 then return string.format("%02d:%02d:%02d", h, m, s) end
    return string.format("%02d:%02d", m, s)
end

local function resetMoneyTracker()
    Stats.moneyBefore    = getMoney()
    Stats.moneyNow       = Stats.moneyBefore
    Stats.deliveries     = 0
    Stats.farmTime       = 0
    Stats.startTime      = os.time()
    delivHistory         = {0,0,0,0,0,0,0,0,0}
    lastDelivMoney       = Stats.moneyBefore
    bestDelivProfit      = 0
    bestPerHour          = 0

    MT_balanceMain.Text   = formatMoney(Stats.moneyBefore)
    MT_valProfit.Text     = "Rp. 0"
    MT_valPerHour.Text    = "Rp. 0"
    MT_valInitial.Text    = formatMoney(Stats.moneyBefore)
    MT_valPerDeliv.Text   = "—"
    MT_valDelPerHour.Text = "0 / H"
    MT_delivCount.Text    = "0"
    MT_uptimeVal.Text     = "00:00"
    MT_progLabel.Text     = "SESSION GAIN: Rp. 0  —  TARGET Rp. 5.000.000"
    MT_progLabel.TextColor3 = C.TEXT_SUB
    Services.TweenSvc:Create(progFill,    TweenInfo.new(0.3), {Size=UDim2.new(0,0,1,0)}):Play()
    Services.TweenSvc:Create(elapsedFill, TweenInfo.new(0.3), {Size=UDim2.new(0,0,1,0)}):Play()
    updateDelivBars()
end

local dotPhase = false
task.spawn(function()
    while task.wait(0.5) do
        if moneyTrackerGui.Enabled then
            dotPhase = not dotPhase
            MT_statusDot.BackgroundTransparency = dotPhase and 0 or 0.6
            pillDot.BackgroundTransparency      = dotPhase and 0 or 0.5
        end
    end
end)

local MT_accum = 0
Services.RunService.Heartbeat:Connect(function(dt)
    if not moneyTrackerGui.Enabled then return end

    Stats.farmTime    = os.time() - Stats.startTime
    MT_uptimeVal.Text = formatTime(Stats.farmTime)
    elapsedFill.Size  = UDim2.new(math.clamp(Stats.farmTime/7200,0,1), 0, 1, 0)

    MT_accum = MT_accum + dt
    if MT_accum < 1.5 then return end
    MT_accum = 0

    pcall(function()
        local fps  = math.floor(1 / dt)
        local ping = math.floor(Services.Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        MT_LiveStats.Text = string.format("PING %d ms  ·  FPS %d", ping, fps)
        MT_pingVal.Text   = tostring(ping).." ms"
        MT_fpsVal.Text    = tostring(fps)

        if ping < 80 then        MT_pingVal.TextColor3 = C.BLUE
        elseif ping < 150 then   MT_pingVal.TextColor3 = C.TEXT_MAIN
        else                     MT_pingVal.TextColor3 = C.RED end

        if fps >= 50 then        MT_fpsVal.TextColor3 = C.BLUE
        elseif fps >= 30 then    MT_fpsVal.TextColor3 = C.TEXT_MAIN
        else                     MT_fpsVal.TextColor3 = C.RED end
    end)

    Stats.moneyNow = getMoney()
    MT_balanceMain.Text = formatMoney(Stats.moneyNow)
    MT_valInitial.Text  = formatMoney(Stats.moneyBefore)
    MT_delivCount.Text  = tostring(Stats.deliveries)

    local income = Stats.moneyNow - Stats.moneyBefore
    if income > 0 then
        MT_valProfit.Text       = "+"..formatMoney(income)
        MT_valProfit.TextColor3 = C.GREEN

        local perHour = math.floor((income / math.max(Stats.farmTime,1)) * 3600)
        MT_valPerHour.Text = formatMoney(perHour).." / H"
        if perHour > bestPerHour then bestPerHour = perHour end

        if Stats.deliveries > 0 then
            local perDeliv   = math.floor(income / Stats.deliveries)
            local delPerHour = math.floor((Stats.deliveries / math.max(Stats.farmTime,1)) * 3600)
            MT_valPerDeliv.Text    = formatMoney(perDeliv)
            MT_valDelPerHour.Text  = tostring(delPerHour).." / H"
            if perDeliv > bestDelivProfit then bestDelivProfit = perDeliv end
        end

        local pct = math.clamp(income / 5000000, 0, 1)
        Services.TweenSvc:Create(progFill, TweenInfo.new(0.55), {
            Size = UDim2.new(pct, 0, 1, 0)
        }):Play()

        MT_progLabel.Text = string.format(
            "SESSION GAIN: +%s  (%s%% of 5M target)",
            formatMoney(income):gsub("Rp%. ","Rp. "),
            string.format("%.1f", pct*100)
        )
        MT_progLabel.TextColor3 = C.GREEN
    else
        MT_valProfit.TextColor3 = C.TEXT_DIM
    end
end)

-- ============================================================================
-- // 7. AUTO FARM ENGINE
-- ============================================================================

-- ===== AUTO CLEAR BUILDING (ROBUST) =====
task.spawn(function()
    local function hapusGedungNyangkut()
        pcall(function()
            local map = Services.Workspace:FindFirstChild("Map")
            local prop = map and map:FindFirstChild("Prop")
            
            if prop then
                local targetGedung = prop:GetChildren()[1155]
                if targetGedung and targetGedung.Parent then
                    local nama = targetGedung.Name
                    targetGedung:Destroy()
                    print(("✅ [King Akbar] Gedung penghalang (%s) di index 1155 berhasil di-bypass!"):format(nama))
                end
            end
        end)
    end

    while true do
        hapusGedungNyangkut()
        task.wait(3)
    end
end)

-- ===== FARM CONFIG =====
local farmConfig = {
    MALANG_COORD         = Vector3.new(-7847.49, 386.65, 46865.19),
    STARTER_COORD        = Vector3.new(34938.24, 134.51, -54574.96),
    TRUCK_SEAT_POSITION  = Vector3.new(35173.47, 134.51, -54683.63),
    STARTER_DISTANCE     = 20,
    MALANG_POLL_INTERVAL = 0.02,
    highAltitude         = 5000,
    descendTime          = 44,
}

-- ===== STATE =====
local autoFarmRunning    = false
local collisionOffModel  = nil
local CameraFollowLocked = false
local CameraFollowOffset = Vector3.new(0, 5, 15)

-- ===== PATH REFERENCE =====
local Starter, Spawner
pcall(function()
    Starter = Services.Workspace:WaitForChild("Etc", 10)
        :WaitForChild("Job", 5):WaitForChild("Truck", 5):WaitForChild("Starter", 5)
end)
pcall(function()
    Spawner = Services.Workspace:WaitForChild("Etc", 10)
        :WaitForChild("Job", 5):WaitForChild("Truck", 5):WaitForChild("Spawner", 5)
end)

-- ===== UTIL =====
local function notify(title, text)
    pcall(function()
        Services.StarterGui:SetCore("SendNotification", {
            Title = title, Text = text, Duration = 3,
        })
    end)
end

-- ===== COLLISION & CAMERA =====
local function SetCollisionOff(model)
    if not model then return end
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = false end
    end
    collisionOffModel = model
end

local function SetCollisionOn(model)
    if not model then return end
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = true end
    end
    if collisionOffModel == model then collisionOffModel = nil end
end

local function TurnOnCollisionIfNeeded()
    if collisionOffModel then SetCollisionOn(collisionOffModel) end
end

local function UpdateCameraFollow()
    if not CameraFollowLocked then return end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local targetPos = char.HumanoidRootPart.Position
    local cam = Services.Workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Scriptable
    cam.CFrame = CFrame.lookAt(targetPos + CameraFollowOffset, targetPos)
end

local function EnableCameraFollowLock(offset)
    CameraFollowLocked = true
    if offset then CameraFollowOffset = offset end
    UpdateCameraFollow()
end

local function DisableCameraFollowLock()
    CameraFollowLocked = false
    Services.Workspace.CurrentCamera.CameraType = Enum.CameraType.Follow
end

Services.RunService.RenderStepped:Connect(UpdateCameraFollow)

-- ===== JOB HELPERS =====
local function IsMalang()
    local ok, destPart = pcall(function()
        return Services.Workspace:WaitForChild("Etc", 5)
            :WaitForChild("Waypoint", 5):WaitForChild("Waypoint", 5)
    end)
    if not ok or not destPart then return false end
    if (destPart.Position - farmConfig.MALANG_COORD).Magnitude < 100 then return true end
    local bb = destPart:FindFirstChild("BillboardGui")
    if bb then
        for _, c in ipairs(bb:GetChildren()) do
            if c:IsA("TextLabel") and string.find(string.lower(c.Text), "malang") then
                return true
            end
        end
    end
    return false
end

local function FindTruckButton()
    local jobGui = LocalPlayer:FindFirstChild("PlayerGui"):FindFirstChild("Job")
    if not jobGui then return nil end
    local comp = jobGui:FindFirstChild("Components")
    if not comp then return nil end
    local scroll = comp:FindFirstChild("ScrollingFrame")
    if not scroll then return nil end
    local truck = scroll:FindFirstChild("Truck")
    if not truck then return nil end
    return truck:FindFirstChild("Button")
end

local function FindJobRemote()
    local RS = Services.ReplicatedStorage
    local net = RS:FindFirstChild("NetworkContainer")
    if net then
        local re = net:FindFirstChild("RemoteEvents")
        if re then
            local j = re:FindFirstChild("Job")
            if j then return j end
        end
    end
    for _, obj in ipairs(RS:GetDescendants()) do
        if obj:IsA("RemoteEvent") and obj.Name == "Job" then return obj end
    end
    return nil
end

local function FireJobRemote()
    local remote = FindJobRemote()
    if not remote then return false end
    pcall(function() remote:FireServer("Truck") end)
    pcall(function() remote:FireServer("TruckDriver") end)
    pcall(function() remote:FireServer("SOPIR TRUK") end)
    pcall(function() remote:FireServer("Truck", "Job") end)
    return true
end

-- ===== MOVEMENT =====
local function GetGroundY(targetPos, exclude)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = exclude or { LocalPlayer.Character }
    local result = Services.Workspace:Raycast(
        targetPos + Vector3.new(0, 500, 0), Vector3.new(0, -1, 0), params
    )
    return result and result.Position.Y or targetPos.Y
end

local function TeleportFarmCharacter(targetPos)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not root then return false end
    local wasAnchored = root.Anchored
    root.Anchored = true
    local target = CFrame.new(targetPos + Vector3.new(0, 3, 0))
    char:PivotTo(target)
    root.AssemblyLinearVelocity  = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    root.Velocity                = Vector3.zero
    task.wait(0.05)
    char:PivotTo(target)
    root.Anchored = wasAnchored
    return true
end

local function TeleportToStarterStable()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not root then return false end

    if humanoid and humanoid.SeatPart then
        humanoid.Sit = false
        pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        Services.RunService.Heartbeat:Wait()
    end

    local groundY = GetGroundY(farmConfig.STARTER_COORD, { char })
    local target  = CFrame.new(
        farmConfig.STARTER_COORD.X, groundY + 4, farmConfig.STARTER_COORD.Z
    )

    local states = {}
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            states[part] = part.Anchored
            part.Anchored = true
        end
    end

    char:PivotTo(target)
    root.AssemblyLinearVelocity  = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    root.Velocity                = Vector3.zero
    Services.RunService.Heartbeat:Wait()

    for part, wasA in pairs(states) do
        if part and part.Parent then part.Anchored = wasA end
    end

    root.AssemblyLinearVelocity  = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    root.Velocity                = Vector3.zero
    return true
end

-- ===== PROMPT / SEAT =====
local function GetCurrentTruckModel()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.SeatPart then
        return hum.SeatPart:FindFirstAncestorOfClass("Model")
    end
    return nil
end

local function HoldPrompt(prompt)
    if not prompt or not prompt.Parent then return false end
    return pcall(function()
        prompt:InputHoldBegin()
        local hold = tonumber(prompt.HoldDuration) or 0
        task.wait(math.max(0.12, hold + 0.05))
        prompt:InputHoldEnd()
    end)
end

local function TapPromptDuduk(prompt)
    pcall(function()
        prompt:InputHoldBegin()
        task.wait(1.1)
        prompt:InputHoldEnd()
    end)
end

local function FindSitPrompt()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local pp = root.Position
    local best, bestDist = nil, math.huge
    for _, obj in ipairs(Services.Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local n = obj.Name:lower()
            if n:find("sit") or n:find("driver") or n:find("seat") then
                local parent = obj.Parent
                local pos = parent:IsA("BasePart") and parent.Position
                    or (parent and parent:GetPivot().Position or pp)
                local d = (pos - pp).Magnitude
                if d < bestDist and d < 50 then
                    bestDist = d
                    best = obj
                end
            end
        end
    end
    return best
end

local function TriggerSpawnerSmart()
    local prompt = Spawner and Spawner:FindFirstChildOfClass("ProximityPrompt")
    if not prompt and Spawner then
        for _, d in ipairs(Spawner:GetDescendants()) do
            if d:IsA("ProximityPrompt") then prompt = d; break end
        end
    end
    if prompt then HoldPrompt(prompt); return true end
    return false
end

-- ===== KING AKBAR DROP (Instant Arrival) =====
local function kingAkbarDrop(vehicle, target)
    if not vehicle then return end
    local main = vehicle.PrimaryPart
    if not main then return end

    local parts, anchored = {}, {}
    for _, p in ipairs(vehicle:GetDescendants()) do
        if p:IsA("BasePart") then
            parts[#parts + 1] = p
            anchored[p] = p.Anchored
            p.Anchored = true
        end
        if p:IsA("VehicleSeat") then
            pcall(function()
                p.ThrottleFloat = 0
                p.SteerFloat    = 0
            end)
        end
    end

    local _, yRot = main.CFrame:ToEulerAnglesYXZ()
    local mainCF  = main.CFrame
    local offsets = {}
    for _, p in ipairs(parts) do
        if p ~= main then offsets[p] = mainCF:ToObjectSpace(p.CFrame) end
    end

    local highPos = target + Vector3.new(0, farmConfig.highAltitude, 0)
    main.CFrame = CFrame.new(highPos) * CFrame.fromEulerAnglesYXZ(0, yRot, 0)
    for _, p in ipairs(parts) do
        if p ~= main and offsets[p] then
            p.CFrame = main.CFrame:ToWorldSpace(offsets[p])
        end
    end

    local tween = Services.TweenSvc:Create(
        main,
        TweenInfo.new(farmConfig.descendTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { CFrame = CFrame.new(target) * CFrame.fromEulerAnglesYXZ(0, yRot, 0) }
    )

    local conn = Services.RunService.Heartbeat:Connect(function()
        for _, p in ipairs(parts) do
            if p ~= main and offsets[p] and p.Parent then
                p.CFrame = main.CFrame:ToWorldSpace(offsets[p])
            end
        end
    end)

    tween:Play()
    tween.Completed:Wait()
    conn:Disconnect()

    for _, p in ipairs(parts) do
        if p.Parent then
            p.Anchored = anchored[p]
            pcall(function()
                p.AssemblyLinearVelocity  = Vector3.zero
                p.AssemblyAngularVelocity = Vector3.zero
            end)
        end
    end
end

-- ===== ENSURE SEATED =====
local function EnsureSeated()
    while autoFarmRunning do
        print("🔄 Attempting to seat...")
        if Spawner then
            TeleportFarmCharacter(Spawner:GetPivot().Position)
            task.wait(farmConfig.MALANG_POLL_INTERVAL)
            TriggerSpawnerSmart()
            EnableCameraFollowLock()
        end
        local t0 = tick()
        while (tick() - t0) < 1.5 do
            if not autoFarmRunning then return nil end
            task.wait(0.1)
            if FindSitPrompt() ~= nil then break end
        end
        TeleportFarmCharacter(farmConfig.TRUCK_SEAT_POSITION)
        task.wait(0.6)
        local sitPrompt = FindSitPrompt()
        if sitPrompt then
            TapPromptDuduk(sitPrompt)
            local t1 = tick()
            while tick() - t1 < 1.5 do
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.SeatPart then break end
                task.wait(farmConfig.MALANG_POLL_INTERVAL)
            end
        else
            continue
        end
        local truck = GetCurrentTruckModel()
        if truck then
            print("✅ Successfully seated in truck!")
            return truck
        end
    end
    return nil
end

-- ===== MAIN FARM LOOP =====
local function FarmLoop()
    if not Starter or not Spawner then
        warn("❌ Starter/Spawner not found!")
        autoFarmRunning = false
        return
    end

    moneyTrackerGui.Enabled = true
    resetMoneyTracker()

    while autoFarmRunning do
        -- 1. Select Job
        print("🎯 Selecting job...")
        for _ = 1, 10 do
            local jobGui = LocalPlayer:FindFirstChild("PlayerGui"):FindFirstChild("Job")
            if jobGui then
                local button = FindTruckButton()
                if button then pcall(function() button:Click() end); break end
            end
            task.wait(farmConfig.MALANG_POLL_INTERVAL)
        end
        FireJobRemote()
        task.wait(farmConfig.MALANG_POLL_INTERVAL)

        -- 2. Move to Starter
        print("📌 Moving to Starter...")
        EnableCameraFollowLock(Vector3.new(0, 5, 15))
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local dist = root and (root.Position - farmConfig.STARTER_COORD).Magnitude or math.huge
        if dist > farmConfig.STARTER_DISTANCE then TeleportToStarterStable() end

        local starterPrompt = Starter:FindFirstChild("Prompt")
            or Starter:FindFirstChildOfClass("ProximityPrompt")
        if starterPrompt then
            HoldPrompt(starterPrompt)
        else
            for _, d in ipairs(Starter:GetDescendants()) do
                if d:IsA("ProximityPrompt") then HoldPrompt(d); break end
            end
        end

        -- 3. Verify destination
        print("🔍 Checking destination...")
        local destMalang = false
        for _ = 1, 3 do
            task.wait(farmConfig.MALANG_POLL_INTERVAL)
            if IsMalang() then destMalang = true; break end
        end
        DisableCameraFollowLock()

        if not destMalang then
            print("❌ Not Malang, retrying...")
            TurnOnCollisionIfNeeded()
        else
            print("✅ Malang destination confirmed!")
            local truck = EnsureSeated()
            if not truck then break end

            if not autoFarmRunning then
                TurnOnCollisionIfNeeded()
                DisableCameraFollowLock()
                return
            end

            -- 4. Instant Arrival
            print("🚀 Instant arrival (altitude " .. farmConfig.highAltitude .. ")...")
            local destPart = Services.Workspace
                :WaitForChild("Etc", 5):WaitForChild("Waypoint", 5):WaitForChild("Waypoint", 5)
            local destPos  = destPart.Position

            kingAkbarDrop(truck, destPos)

            if not autoFarmRunning then
                TurnOnCollisionIfNeeded()
                DisableCameraFollowLock()
                return
            end

            -- 5. Update stats on delivery
            Stats.deliveries += 1
            local moneyNow    = getMoney()
            local delivProfit = moneyNow - lastDelivMoney
            lastDelivMoney    = moneyNow
            table.remove(delivHistory, 1)
            table.insert(delivHistory, math.max(0, delivProfit))
            updateDelivBars()

            -- 6. Wait for destination change (next delivery)
            print("⏳ Waiting for destination change...")
            local lastDestPos = destPos
            local startWait   = tick()
            while (tick() - startWait) < 60 do
                if not autoFarmRunning then
                    TurnOnCollisionIfNeeded()
                    DisableCameraFollowLock()
                    return
                end
                task.wait(1)
                local ok, newDest = pcall(function()
                    return Services.Workspace
                        :WaitForChild("Etc", 5):WaitForChild("Waypoint", 5):WaitForChild("Waypoint", 5)
                end)
                if ok and newDest then
                    if (newDest.Position - lastDestPos).Magnitude > 5 then
                        print("✅ Destination changed! Reward received.")
                        break
                    end
                end
            end

            TurnOnCollisionIfNeeded()
            DisableCameraFollowLock()
        end
    end

    moneyTrackerGui.Enabled = false
end

-- ===== START / STOP / POTATO / FPS CAP =====

local potatoModeApplied = false
local function EnableOptimizationAndPotato()
    if potatoModeApplied then return end
    potatoModeApplied = true
    
    -- 1. Apply FPS Cap (60 FPS)
    pcall(function()
        if setfpscap then
            setfpscap(60)
            print("🚀 [King Akbar] FPS Capped to 60.")
        end
    end)
    
    -- 2. Apply Potato Mode
    pcall(function()
        local Lighting = game:GetService("Lighting")
        local Terrain = workspace:FindFirstChildOfClass("Terrain")

        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.ShadowSoftness = 0
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
        Lighting.Brightness = 1
        
        for _, v in ipairs(Lighting:GetDescendants()) do
            if v:IsA("PostEffect") or v:IsA("BlurEffect") or v:IsA("BloomEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect") then
                v.Enabled = false
            end
        end

        if Terrain then
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 0
            Terrain.Decoration = false
        end

        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
                v.CastShadow = false
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            end
        end
    end)
    print("🥔 [King Akbar] Potato Mode Aktif! Grafik telah dipangkas.")
end

local function startFarm()
    if autoFarmRunning then return end
    autoFarmRunning = true
    
    EnableOptimizationAndPotato()
    
    notify("King Akbar", "🚛 Auto Delivery STARTED")
    task.spawn(function()
        while autoFarmRunning do
            local ok, err = pcall(FarmLoop)
            if not ok and autoFarmRunning then
                warn("[King Akbar] FarmLoop recovered: " .. tostring(err))
                task.wait(0.5)
            else
                break
            end
        end
    end)
end

local function stopFarm()
    autoFarmRunning = false
    DisableCameraFollowLock()
    TurnOnCollisionIfNeeded()
    moneyTrackerGui.Enabled = false
    notify("King Akbar", "⏹️ Auto Delivery STOPPED")
end

-- ============================================================================
-- // 8. FARM TAB UI
-- ============================================================================

-- ANTI AFK
local StayActiveEnabled = false
local disabledIdledConns = {}

local function startStayActive()
    if StayActiveEnabled then return end
    StayActiveEnabled = true
    if getconnections and type(getconnections) == "function" then
        pcall(function()
            for _, c in ipairs(getconnections(LocalPlayer.Idled)) do
                if c then
                    if c.Disable then pcall(c.Disable, c) end
                    if c.DisableConnection then pcall(c.DisableConnection, c) end
                    table.insert(disabledIdledConns, c)
                end
            end
        end)
    end
    if #disabledIdledConns == 0 then
        task.spawn(function()
            while StayActiveEnabled do
                task.wait(math.random() * 50 + 40)
                if not StayActiveEnabled then break end
                pcall(function()
                    Services.VirtualUser:CaptureController()
                    Services.VirtualUser:ClickButton2(
                        Vector2.new(),
                        Services.Workspace.CurrentCamera.CFrame
                    )
                end)
            end
        end)
    end
end
startStayActive()

-- AFK Bypass tambahan (VirtualUser setiap 10 menit)
task.spawn(function()
    while true do
        if autoFarmRunning then
            pcall(function()
                Services.VirtualUser:CaptureController()
                Services.VirtualUser:ClickButton2(Vector2.new())
            end)
        end
        task.wait(600)
    end
end)

local AutoFarmSection = FarmTab:Section({ Title = "Delivery System" })

-- ✅ Desc dikosongkan (stealth)
local FarmToggle = AutoFarmSection:Toggle({
    Title    = "Auto Delivery",
    Desc     = "",
    Icon     = "truck",
    State    = true,
    Callback = function(state)
        if state then
            notify("Delivery System", "🚀 Starting.")
            startFarm()
        else
            notify("Delivery System", "⏹️ Stopped.")
            stopFarm()
        end
    end
})

-- Stop via RightShift
Services.UserInput.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if autoFarmRunning then
            stopFarm()
            pcall(function() FarmToggle:Set(false) end)
        end
    end
end)

-- ============================================================================
-- // 9. WEBHOOK TAB
-- ============================================================================
local WebhookEnabled         = false
local WebhookURL             = ""
local WebhookIntervalMinutes = 5
local webhookLoop            = nil

-- ============================================================================
-- // 9.5 NAME MASKER (ANONYMIZED)
-- ============================================================================
local function maskName(name)
    if not name or name == "" then return "Anonymous" end
    local len = #name
    if len == 1 then return "●" end
    if len == 2 then return name:sub(1,1) .. "●" end
    if len <= 4 then
        return name:sub(1,1) .. string.rep("●", len - 2) .. name:sub(len, len)
    end
    -- 5+ karakter: K●●●●a (first + dots + last)
    local dots = math.min(len - 2, 5)
    return name:sub(1,1) .. string.rep("●", dots) .. name:sub(len, len)
end

-- ============================================================================
-- // 9.6 EMBED BUILDER (PROFESSIONAL — NO CLICKABLE LINKS)
-- ============================================================================
local function buildReportEmbed()
    local profit     = Stats.moneyNow - Stats.moneyBefore
    local sessionSec = math.max(Stats.farmTime, 1)

    local perHour    = math.floor((profit / sessionSec) * 3600)
    local perDeliv   = Stats.deliveries > 0 and math.floor(profit / Stats.deliveries) or 0
    local delPerHour = math.floor((Stats.deliveries / sessionSec) * 3600)

    -- Dynamic status color
    local statusIcon, statusText, embedColor
    if profit > 0 then
        statusIcon, statusText, embedColor = "🟢", "PROFITABLE", 0x10B981
    elseif profit < 0 then
        statusIcon, statusText, embedColor = "🔴", "LOSS",       0xEF4444
    else
        statusIcon, statusText, embedColor = "🟡", "IDLE",       0xF59E0B
    end

    local profitSign = profit >= 0 and "+" or "-"
    local maskedName = maskName(LocalPlayer.Name)
    local serverId   = game.JobId ~= "" and (game.JobId:sub(1, 12) .. "...") or "Private Server"
    local placeholder = "━━━━━━━━━━━━━━━━━━━━━━━━━━"

    return {
        -- author tanpa URL → tidak clickable di Discord
        author = {
            name     = "👑  KING AKBAR HUB  •  DELIVERY SYSTEM",
            icon_url = "https://cdn-icons-png.flaticon.com/512/1077/1077012.png",
        },

        title       = "📦   DELIVERY SESSION REPORT",
        description = string.format(
            "**Status :**  %s  `%s`\n**Date   :**  `%s`",
            statusIcon,
            statusText,
            os.date("%d %b %Y  •  %H:%M:%S")
        ),
        color = embedColor,

        fields = {
            -- ─── WALLET BLOCK ───
            {
                name   = placeholder .. "  💰  WALLET  " .. placeholder,
                value  = string.format(
                    "```yaml\n"
                    .. "Starting Balance : %s\n"
                    .. "Current Balance  : %s\n"
                    .. "Session Profit   : %s%s\n"
                    .. "```",
                    formatMoney(Stats.moneyBefore),
                    formatMoney(Stats.moneyNow),
                    profitSign, formatMoney(profit)
                ),
                inline = false,
            },

            -- ─── PERFORMANCE ROW ───
            {
                name   = "⚡  Income / Hour",
                value  = string.format("```yaml\n%s\n```", formatMoney(perHour)),
                inline = true,
            },
            {
                name   = "🚚  Deliveries",
                value  = string.format("```yaml\n%d completed\n```", Stats.deliveries),
                inline = true,
            },
            {
                name   = "⏱️  Session Time",
                value  = string.format("```yaml\n%s\n```", formatTime(sessionSec)),
                inline = true,
            },
            {
                name   = "💵  Per Delivery",
                value  = string.format("```yaml\n%s\n```",
                    Stats.deliveries > 0 and formatMoney(perDeliv) or "—"),
                inline = true,
            },
            {
                name   = "📊  Delivery / Hour",
                value  = string.format("```yaml\n%d / hour\n```", delPerHour),
                inline = true,
            },
            {
                name   = "🎯  System Status",
                value  = string.format("```yaml\n%s\n```",
                    autoFarmRunning and "ACTIVE" or "STANDBY"),
                inline = true,
            },

            -- ─── ACCOUNT BLOCK (ANONYMIZED) ───
            {
                name   = placeholder .. "  👤  ACCOUNT  " .. placeholder,
                value  = string.format(
                    "```yaml\n"
                    .. "Name   : %s\n"
                    .. "Server : %s\n"
                    .. "```",
                    maskedName,
                    serverId
                ),
                inline = false,
            },
        },

        thumbnail = {
            url = "https://cdn-icons-png.flaticon.com/512/9337/9337597.png",
        },

        -- footer tanpa URL → tidak clickable
        footer = {
            text = "🔒  Confidential Report  •  King Akbar Hub  •  Automated Delivery System",
        },

        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    }
end

local function sendWebhook()
    local url = WebhookURL
    if url == "" then
        notify("Webhook", "❌ Webhook URL is empty!")
        return
    end

    local payload = {
        username   = "King Akbar",
        avatar_url = "https://cdn-icons-png.flaticon.com/512/1077/1077012.png",
        embeds     = { buildReportEmbed() },
    }

    local jsonPayload = Services.HttpService:JSONEncode(payload)
    local success     = false
    local req         = request or http_request or (syn and syn.request)

    if req then
        local ok, res = pcall(function()
            return req({
                Url     = url,
                Method  = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body    = jsonPayload,
            })
        end)
        if ok and res and (res.StatusCode == 204 or res.StatusCode == 200) then
            success = true
        end
    else
        local ok = pcall(function()
            Services.HttpService:PostAsync(url, jsonPayload)
        end)
        if ok then success = true end
    end

    if success then
        notify("Webhook", "✅ Report sent to Discord.")
    else
        notify("Webhook", "❌ Delivery failed. Check URL or connection.")
    end
end

local function startWebhookLoop()
    if webhookLoop then task.cancel(webhookLoop) end
    if not WebhookEnabled or WebhookURL == "" then return end
    webhookLoop = task.spawn(function()
        while WebhookEnabled do
            if WebhookURL ~= "" then pcall(sendWebhook) end
            task.wait(WebhookIntervalMinutes * 60)
        end
    end)
end

local function stopWebhookLoop()
    WebhookEnabled = false
    if webhookLoop then task.cancel(webhookLoop); webhookLoop = nil end
end

WebhookTab:Paragraph({
    Title = "Discord Integration",
    Desc  = "Automatically send delivery session reports to your Discord "
         .. "channel. Reports include wallet balance, profit, session time, "
         .. "and performance metrics. Account name is masked for privacy.",
    Image = "rbxassetid://107726435417936",
})

local ConfigSection = WebhookTab:Section({ Title = "Configuration" })

ConfigSection:Toggle({
    Title    = "Auto Send Reports",
    Desc     = "Automatically send report at the configured interval.",
    Icon     = "webhook",
    State    = false,
    Callback = function(state)
        WebhookEnabled = state
        if state then
            startWebhookLoop()
            notify("Webhook", "Auto reports enabled — every " .. WebhookIntervalMinutes .. " min.")
        else
            stopWebhookLoop()
            notify("Webhook", "Auto reports disabled.")
        end
    end
})

ConfigSection:Input({
    Title       = "Webhook URL",
    Desc        = "Discord webhook endpoint for report delivery.",
    Icon        = "link",
    Value       = "",
    Placeholder = "https://discord.com/api/webhooks/...",
    Callback    = function(val)
        WebhookURL = val
        if WebhookEnabled then startWebhookLoop() end
    end
})

ConfigSection:Input({
    Title       = "Interval (minutes)",
    Desc        = "How often reports are sent. Minimum 1 minute.",
    Icon        = "clock",
    Value       = tostring(WebhookIntervalMinutes),
    Placeholder = "5",
    Callback    = function(val)
        local n = tonumber(val)
        if n and n >= 1 then
            WebhookIntervalMinutes = math.floor(n)
            if WebhookEnabled then startWebhookLoop() end
        end
    end
})

local ActionSection = WebhookTab:Section({ Title = "Actions" })

ActionSection:Button({
    Title    = "Send Test Report",
    Desc     = "Send a report immediately to verify your webhook.",
    Icon     = "send",
    Callback = function()
        if WebhookURL == "" then
            notify("Webhook", "❌ Please enter a webhook URL first.")
            return
        end
        sendWebhook()
    end
})

ActionSection:Button({
    Title    = "Reset Session Stats",
    Desc     = "Reset all counters and balance tracking to zero.",
    Icon     = "rotate-ccw",
    Callback = function()
        Stats.moneyBefore = getMoney()
        Stats.moneyNow    = Stats.moneyBefore
        Stats.deliveries  = 0
        Stats.farmTime    = 0
        Stats.startTime   = os.time()
        notify("Session", "✅ Session stats have been reset.")
    end
})

-- ============================================================================
-- // 10. OPEN BUTTON & FPS TAG
-- ============================================================================
Window:EditOpenButton({
    Title           = "Open King Akbar",
    Icon            = "crown",
    CornerRadius    = UDim.new(0,12),
    StrokeThickness = 2,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromHex("#ffffff")),
        ColorSequenceKeypoint.new(1, Color3.fromHex("#0a0a0a")),
    }),
    Enabled   = true,
    Draggable = true,
})

local FpsTag = Window:Tag({
    Title = "Fps: ...",
    Color = WindUI:Gradient({
        [0]   = { Color = Color3.fromHex("#0a0a0a"), Transparency = 0 },
        [100] = { Color = Color3.fromHex("#888888"), Transparency = 0 },
    }, { Rotation = 45 }),
})

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local fps  = math.floor(1 / Services.RunService.RenderStepped:Wait())
            local ping = math.floor(Services.Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
            if FpsTag and FpsTag.SetTitle then
                FpsTag:SetTitle(("Fps: %d | Ping: %d"):format(fps, ping))
            end
        end)
    end
end)

-- ============================================================================
-- // 11. INITIALIZATION + AUTO-START
-- ============================================================================
Window:SetIconSize(47)
WindUI:SetTheme("dark")
InfoTab:Select()

WindUI:Notify({
    Title    = "👑 KING AKBAR — DELIVERY SYSTEM",
    Content  = "System loaded successfully.",
    Duration = 5,
})

task.wait(2)
startFarm()
pcall(function() FarmToggle:Set(true) end)

notify("King Akbar Delivery", "🚛 Ready. (Stop: RightShift)")
