-- 不进旅馆 脚本 v1.0.3
-- WindUI蓝白版 | 透视物品 | 调速度

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

local VERSION = "v1.0.3"
local espEnabled = false
local espHighlights = {}
local espTags = {}
local espColor = Color3.fromRGB(255, 200, 0)
local speedEnabled = false
local speedValue = 16

local function clearESP()
    for _, h in pairs(espHighlights) do pcall(function() h:Destroy() end) end
    for _, t in pairs(espTags) do pcall(function() t:Destroy() end) end
    table.clear(espHighlights)
    table.clear(espTags)
end

local function scanAndESP()
    if not espEnabled then
        clearESP()
        return
    end
    
    local myPos = nil
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        myPos = LocalPlayer.Character.HumanoidRootPart.Position
    end
    
    local foundKeys = {}
    local foundSafes = {}
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local name = obj.Name
            local nameLower = name:lower()
            
            local isTarget = false
            local displayName = name
            
            if nameLower == "key" then
                if foundKeys["钥匙"] then continue end
                isTarget = true
                foundKeys["钥匙"] = true
                displayName = "🔑 钥匙"
            elseif nameLower:find("safe") or nameLower:find("保险箱") then
                -- 只透视10米内最近的一个保险箱
                local rootPart = nil
                if obj:IsA("Model") then
                    rootPart = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                elseif obj:IsA("BasePart") then
                    rootPart = obj
                end
                if rootPart and myPos then
                    local dist = (myPos - rootPart.Position).Magnitude
                    if dist > 10 then
                        continue
                    end
                end
                if foundSafes["保险箱"] then continue end
                isTarget = true
                foundSafes["保险箱"] = true
                displayName = "🔒 保险箱"
            elseif nameLower:find("box2") then
                isTarget = true
                displayName = "📦 箱子"
            elseif nameLower:find("pea") then
                isTarget = true
                displayName = "🟢 豆子"
            elseif nameLower:find("ghost") or nameLower:find("鬼") then
                isTarget = true
                displayName = "👻 鬼"
            elseif nameLower:find("chest") or nameLower:find("箱子") then
                isTarget = true
                displayName = "📦 箱子"
            end
            
            if isTarget and not espHighlights[obj] then
                local rootPart = nil
                if obj:IsA("Model") then
                    rootPart = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                elseif obj:IsA("BasePart") then
                    rootPart = obj
                end
                
                if rootPart then
                    local h = Instance.new("Highlight")
                    h.FillColor = espColor
                    h.FillTransparency = 0.4
                    h.OutlineColor = espColor
                    h.OutlineTransparency = 0.2
                    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    h.Parent = obj
                    espHighlights[obj] = h
                    
                    local bg = Instance.new("BillboardGui")
                    bg.Size = UDim2.new(0, 150, 0, 30)
                    bg.AlwaysOnTop = true
                    bg.MaxDistance = math.huge
                    bg.Parent = rootPart
                    
                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.Text = displayName
                    label.TextColor3 = espColor
                    label.Font = Enum.Font.GothamBold
                    label.TextSize = 14
                    label.TextStrokeTransparency = 0.5
                    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                    label.Parent = bg
                    espTags[obj] = bg
                end
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

-- 速度修改
task.spawn(function()
    while true do
        if speedEnabled then
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.WalkSpeed = speedValue
                end
            end
        end
        task.wait(0.3)
    end
end)

local Window = WindUI:CreateWindow({
    Title = "旅馆--测试",
    Icon = "solar:moon-bold",
    Size = UDim2.fromOffset(600, 350),
    ToggleKey = Enum.KeyCode.RightShift,
    Theme = "冰白",
    Transparent = true,
    ScrollBarEnabled = true,
})

Window:Tab({Title = "公告", Icon = "solar:info-circle-bold"}):Paragraph({
    Title = "旅馆 v1.0.3",
    Desc = "功能：透视物品 | 调整速度\n\n透视：钥匙(1个) | 保险箱(10米内1个) | 箱子 | 豆子 | 鬼"
})

local MainTab = Window:Tab({Title = "主要功能", Icon = "solar:star-bold"})

MainTab:Toggle({
    Title = "透视物品",
    Value = false,
    Callback = function(v)
        espEnabled = v
        if not v then clearESP() end
    end
})

MainTab:Divider()

MainTab:Colorpicker({
    Title = "透视颜色",
    Default = Color3.fromRGB(255, 200, 0),
    Callback = function(c)
        espColor = c
        clearESP()
        if espEnabled then
            task.wait(0.1)
            scanAndESP()
        end
    end
})

MainTab:Divider()

MainTab:Toggle({
    Title = "调整速度",
    Value = false,
    Callback = function(v)
        speedEnabled = v
    end
})

MainTab:Slider({
    Title = "速度值 (16-200)",
    Value = {Min = 16, Max = 200, Default = 16},
    Step = 1,
    Callback = function(v)
        speedValue = v
    end
})

local SettingsTab = Window:Tab({Title = "设置", Icon = "solar:settings-bold"})
local statusPara = SettingsTab:Paragraph({Title = "功能状态", Desc = "加载中..."})

task.spawn(function()
    while true do
        local status = ""
        status = status .. "透视: " .. (espEnabled and "已开启" or "未开启") .. "\n"
        status = status .. "调整速度: " .. (speedEnabled and "已开启 (" .. speedValue .. ")" or "未开启") .. "\n"
        status = status .. "帧率: " .. math.floor(1 / task.wait()) .. " FPS"
        statusPara:SetDesc(status)
        task.wait(1)
    end
end)

SettingsTab:Button({
    Title = "关闭面板",
    Callback = function()
        Window:Close()
    end
})

Window:OnClose(function()
    clearESP()
end)

WindUI:Notify({
    Title = "不进旅馆",
    Content = "v1.0.3 加载完成",
    Duration = 3
})
