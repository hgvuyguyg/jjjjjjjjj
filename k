-- 无尽旅馆 脚本 v1.0.15
-- WindUI蓝白版 | 透视物品 | 刷新房间

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
if not WindUI then return end

WindUI:AddTheme({
    Name = "冰白",
    Accent = "#80C0FF",
    Outline = "#6090C0",
    Text = "#FFFFFF",
    Placeholder = "#D0E0FF",
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

local VERSION = "v1.0.15"
local espEnabled = false
local espGhost = false
local espHighlights = {}
local espTags = {}
local showDist = false
local speedEnabled = false
local speedValue = 16
local isFlying = false

local refreshPoints = {
    Vector3.new(-187.1, 44.2, 333.7),
    Vector3.new(-190.1, 44.0, 259.5),
    Vector3.new(-71.7, 41.2, 217.1),
    Vector3.new(-24.3, 42.9, 344.7),
    Vector3.new(-151.6, 45.3, 379.5),
}

local itemColors = {
    key = Color3.fromRGB(255, 215, 0),
    safe = Color3.fromRGB(0, 255, 200),
    box2 = Color3.fromRGB(100, 200, 255),
    pea = Color3.fromRGB(50, 255, 50),
    coin = Color3.fromRGB(255, 200, 50),
    hintpaper = Color3.fromRGB(200, 150, 255),
    chest = Color3.fromRGB(150, 100, 50),
}
local ghostColor = Color3.fromRGB(255, 0, 0)

local function clearESP()
    for _, h in pairs(espHighlights) do pcall(function() h:Destroy() end) end
    for _, t in pairs(espTags) do pcall(function() t:Destroy() end) end
    table.clear(espHighlights)
    table.clear(espTags)
end

local function flyTo(pos)
    if isFlying then return end
    isFlying = true
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local hrp = char.HumanoidRootPart
        local start = hrp.Position
        local dist = (pos - start).Magnitude
        local steps = math.max(10, math.floor(dist / 300 * 60))
        for i = 0, steps do
            if not isFlying then break end
            hrp.CFrame = CFrame.new(start + (pos - start) * (i / steps))
            task.wait()
        end
        hrp.CFrame = CFrame.new(pos)
    end
    isFlying = false
end

local function refreshRooms()
    local char = LocalPlayer.Character
    if not char then return
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return
    local startPos = hrp.Position
    WindUI:Notify({Title = "刷新", Content = "开始...", Duration = 2})
    for _, p in pairs(refreshPoints) do
        flyTo(p)
        task.wait(0.3)
    end
    flyTo(startPos)
    WindUI:Notify({Title = "刷新完成", Content = "已回起点", Duration = 2})
end

local function scanAndESP()
    if not espEnabled and not espGhost then
        clearESP()
        return
    end
    
    local myPos, myY = nil, nil
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        myPos = char.HumanoidRootPart.Position
        myY = myPos.Y
    end
    
    local blockPos = Vector3.new(291.6, 8.4, 645.0)
    local foundKeys, foundSafes, foundCoins = {}, {}, {}
    local closestGhost, ghostDist = nil, math.huge
    
    if espGhost and myPos and myY then
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") or obj:IsA("BasePart") then
                local name = obj.Name:lower()
                if name:find("monster_") then
                    local root = obj:IsA("Model") and (obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or obj
                    if root then
                        local d = (myPos - root.Position).Magnitude
                        if d <= 1000 then
                            local dy = math.abs(myY - root.Position.Y)
                            if dy < ghostDist then
                                ghostDist = dy
                                closestGhost = {obj = obj, root = root, dist = d}
                            end
                        end
                    end
                end
            end
        end
    end
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local name = obj.Name:lower()
            local root = obj:IsA("Model") and (obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or obj
            if not root then continue end
            
            if (root.Position - blockPos).Magnitude < 30 then continue end
            
            local isTarget, display, color, dist = false, obj.Name, Color3.fromRGB(255,255,255), nil
            if myPos then dist = math.floor((myPos - root.Position).Magnitude) end
            
            if espEnabled then
                if name == "key" and not foundKeys["钥匙"] then
                    isTarget, foundKeys["钥匙"], display, color = true, true, "🔑 钥匙", itemColors.key
                elseif (name:find("safe") or name:find("保险箱")) and not foundSafes["保险箱"] then
                    isTarget, foundSafes["保险箱"], display, color = true, true, "🔒 保险箱", itemColors.safe
                elseif name:find("box2") then
                    isTarget, display, color = true, "📦 箱子", itemColors.box2
                elseif name:find("pea") then
                    isTarget, display, color = true, "🟢 豆子", itemColors.pea
                elseif name:find("coin") and not foundCoins["硬币"] then
                    isTarget, foundCoins["硬币"], display, color = true, true, "🪙 硬币", itemColors.coin
                elseif name:find("hintpaper") then
                    isTarget, display, color = true, "📄 提示纸", itemColors.hintpaper
                elseif name:find("chest") or name:find("箱子") then
                    isTarget, display, color = true, "📦 箱子", itemColors.chest
                end
            end
            
            if espGhost and closestGhost and obj == closestGhost.obj then
                isTarget, display, color, dist = true, "👻 鬼", ghostColor, math.floor(closestGhost.dist)
            end
            
            if isTarget and not espHighlights[obj] then
                local h = Instance.new("Highlight")
                h.FillColor, h.FillTransparency, h.OutlineColor, h.OutlineTransparency, h.DepthMode = color, 0.4, color, 0.2, Enum.HighlightDepthMode.AlwaysOnTop
                h.Parent = obj
                espHighlights[obj] = h
                
                local bg = Instance.new("BillboardGui")
                bg.Size, bg.AlwaysOnTop, bg.MaxDistance, bg.Parent = UDim2.new(0,180,0,40), true, math.huge, root
                
                local label = Instance.new("TextLabel")
                label.Size, label.BackgroundTransparency, label.Text, label.TextColor3, label.Font, label.TextSize = UDim2.new(1,0,1,0), 1, display, color, Enum.Font.GothamBold, 14
                label.TextStrokeTransparency, label.TextStrokeColor3 = 0.5, Color3.fromRGB(0,0,0)
                label.Parent = bg
                
                if showDist and dist then
                    local dl = Instance.new("TextLabel")
                    dl.Size, dl.Position, dl.BackgroundTransparency, dl.Text, dl.TextColor3, dl.Font, dl.TextSize = UDim2.new(1,0,0,16), UDim2.new(0,0,0.6,0), 1, dist.."m", Color3.fromRGB(200,200,200), Enum.Font.Gotham, 12
                    dl.TextStrokeTransparency, dl.TextStrokeColor3 = 0.5, Color3.fromRGB(0,0,0)
                    dl.Parent = bg
                end
                espTags[obj] = bg
            end
        end
    end
end

task.spawn(function()
    while true do
        pcall(scanAndESP)
        task.wait(2)
    end
end)

task.spawn(function()
    while true do
        if speedEnabled then
            local char = LocalPlayer.Character
            if char and char:FindFirstChildOfClass("Humanoid") then
                char:FindFirstChildOfClass("Humanoid").WalkSpeed = speedValue
            end
        end
        task.wait(0.3)
    end
end)

local Window = WindUI:CreateWindow({
    Title = "黑脚本--无尽旅馆",
    Icon = "solar:moon-bold",
    Size = UDim2.fromOffset(600, 350),
    ToggleKey = Enum.KeyCode.RightShift,
    Theme = "冰白",
    Transparent = true,
    ScrollBarEnabled = true,
    Background = "https://i.ibb.co/5xB47QLN/IMG-5677.jpg",
    BackgroundImageTransparency = 0.42,
})

Window:Tab({Title = "公告", Icon = "solar:info-circle-bold"}):Paragraph({
    Title = "黑脚本--无尽旅馆 v1.0.15",
    Desc = "功能：透视物品 | 透视鬼 | 刷新房间(飞行) | 显示距离 | 调整速度"
})

local MainTab = Window:Tab({Title = "主要功能", Icon = "solar:star-bold"})

MainTab:Toggle({Title = "透视物品", Value = false, Callback = function(v) espEnabled = v if not v and not espGhost then clearESP() end end})
MainTab:Divider()
MainTab:Toggle({Title = "透视鬼", Value = false, Callback = function(v) espGhost = v if not v and not espEnabled then clearESP() end end})
MainTab:Divider()
MainTab:Toggle({Title = "显示距离", Value = false, Callback = function(v) showDist = v end})
MainTab:Divider()
MainTab:Toggle({Title = "调整速度", Value = false, Callback = function(v) speedEnabled = v end})
MainTab:Slider({Title = "速度值", Value = {Min = 16, Max = 200, Default = 16}, Step = 1, Callback = function(v) speedValue = v end})
MainTab:Divider()
MainTab:Button({Title = "刷新所有房间", Callback = refreshRooms})

local SettingsTab = Window:Tab({Title = "设置", Icon = "solar:settings-bold"})
local statusPara = SettingsTab:Paragraph({Title = "状态", Desc = "加载中..."})

task.spawn(function()
    while true do
        statusPara:SetDesc(string.format(
            "透视物品: %s\n透视鬼: %s\n显示距离: %s\n调整速度: %s\n帧率: %d FPS",
            espEnabled and "✅" or "❌",
            espGhost and "✅" or "❌",
            showDist and "✅" or "❌",
            speedEnabled and ("✅ "..speedValue) or "❌",
            math.floor(1 / task.wait())
        ))
        task.wait(1)
    end
end)

SettingsTab:Button({Title = "关闭面板", Callback = function() Window:Close() end})
Window:OnClose(clearESP)

WindUI:Notify({Title = "无尽旅馆", Content = "v1.0.15 加载完成", Duration = 3})
