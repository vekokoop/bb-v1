-- Blockspin Master Hub V5.2 (Ghost Mode Underground Farm)
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local GUI_Parent = gethui and gethui() or CoreGui
if GUI_Parent:FindFirstChild("BlockspinMasterHub") then GUI_Parent.BlockspinMasterHub:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BlockspinMasterHub"
ScreenGui.Parent = GUI_Parent
ScreenGui.ResetOnSpawn = false

-- الإعدادات
local Settings = {
    AimbotEnabled = true,
    Smoothness = 5,
    ESPEnabled = true,
    AutoFarmATM = false,
    FOVSize = 100,
    AimKey = Enum.UserInputType.MouseButton2
}

-- إحداثيات الـ ATMs
local AtmPositions = {
    Vector3.new(-132.2, 258.5, 106.9),
    Vector3.new(-156.8, 258.5, 442.9),
    Vector3.new(68.4, 265.1, 44.0),
    Vector3.new(90.7, 258.7, 166.4),
    Vector3.new(109.7, 258.5, 463.5)
}

-- دائرة الـ FOV
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = true
FOVCircle.Transparency = 0.6
FOVCircle.Thickness = 1
FOVCircle.Color = Color3.fromRGB(255, 165, 0)
FOVCircle.Filled = false
FOVCircle.Radius = Settings.FOVSize

local function GetClosestTarget()
    local target = nil
    local shortestDist = Settings.FOVSize
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
            if player.Character.Humanoid.Health > 0 then
                local hrp = player.Character.HumanoidRootPart
                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                
                if onScreen then
                    local dist = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        target = player.Character.Head
                    end
                end
            end
        end
    end
    return target
end

-- أيم بوت سلس
RunService.RenderStepped:Connect(function()
    FOVCircle.Position = UserInputService:GetMouseLocation()
    FOVCircle.Radius = Settings.FOVSize

    if Settings.AimbotEnabled and UserInputService:IsMouseButtonPressed(Settings.AimKey) then
        local targetHead = GetClosestTarget()
        if targetHead then
            local targetCFrame = CFrame.new(Camera.CFrame.Position, targetHead.Position)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 1 / Settings.Smoothness)
        end
    end
end)

-- ESP
local espCache = {}
local function CreateESP(player)
    if player == LocalPlayer then return end
    local box = Drawing.new("Square")
    box.Visible = false; box.Color = Color3.fromRGB(255, 50, 50); box.Thickness = 1; box.Filled = false
    local nameTag = Drawing.new("Text")
    nameTag.Visible = false; nameTag.Color = Color3.fromRGB(255, 255, 255); nameTag.Size = 12; nameTag.Center = true; nameTag.Outline = true
    espCache[player] = {Box = box, Name = nameTag}
    player.CharacterRemoving:Connect(function() box.Visible = false; nameTag.Visible = false end)
end

for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(function(p)
    if espCache[p] then espCache[p].Box:Remove(); espCache[p].Name:Remove(); espCache[p] = nil end
end)

RunService.RenderStepped:Connect(function()
    if not Settings.ESPEnabled then
        for _, data in pairs(espCache) do data.Box.Visible = false; data.Name.Visible = false end
        return
    end
    for player, data in pairs(espCache) do
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
            local hrp = char.HumanoidRootPart
            local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                local headPos = Camera:WorldToViewportPoint(char.Head.Position + Vector3.new(0, 0.5, 0))
                local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                local height = math.abs(headPos.Y - legPos.Y)
                local width = height / 2
                data.Box.Size = Vector2.new(width, height)
                data.Box.Position = Vector2.new(vector.X - width / 2, headPos.Y)
                data.Box.Visible = true
                data.Name.Text = player.Name
                data.Name.Position = Vector2.new(vector.X, headPos.Y - 16)
                data.Name.Visible = true
            else
                data.Box.Visible = false; data.Name.Visible = false
            end
        else
            data.Box.Visible = false; data.Name.Visible = false
        end
    end
end)

-- دالة إخفاء وإظهار الشخصية
local function SetGhostMode(isGhost)
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            if isGhost then
                part.LocalTransparencyModifier = 1 -- يخليك شفاف محلياً (ما تشوف نفسك)
            else
                part.LocalTransparencyModifier = 0 -- يرجعك طبيعي
            end
        end
    end
end

-- أوتو فارم للـ ATMs (مع ميزة الاختفاء تحت الأرض)
task.spawn(function()
    while task.wait(3) do
        if Settings.AutoFarmATM then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
                local hrp = char.HumanoidRootPart

                -- تفعيل وضع الشبح (اختفاء)
                SetGhostMode(true)

                for _, atmPos in ipairs(AtmPositions) do
                    if not Settings.AutoFarmATM then break end
                    
                    -- إطفاء الفيزياء والطيران تحت الأرض
                    hrp.CanCollide = false
                    hrp.CFrame = CFrame.new(atmPos + Vector3.new(0, -4, 0))
                    task.wait(0.5)

                    -- البحث الفيزيائي الذكي عن زر الصراف
                    local params = OverlapParams.new()
                    params.FilterDescendantsInstances = {char}
                    params.FilterType = Enum.RaycastFilterType.Exclude
                    
                    local partsNear = Workspace:GetPartBoundsInRadius(atmPos, 15, params)
                    for _, part in pairs(partsNear) do
                        local prompt = part:FindFirstChildOfClass("ProximityPrompt")
                        if prompt then
                            pcall(function()
                                fireproximityprompt(prompt)
                            end)
                            break
                        end
                    end
                    
                    -- إرجاع الفيزياء
                    hrp.CanCollide = true
                    task.wait(2) -- وقت الانتظار بين كل صراف
                end
                
                -- إيقاف وضع الشبح لما يخلص الفارم أو ينطفي
                if not Settings.AutoFarmATM then
                    SetGhostMode(false)
                end
            end
        else
            -- إذا كان الفارم مطفي، تأكد إنه طبيعي (عشان لو طفيت الزر فجأة)
            SetGhostMode(false)
        end
    end
end)

-- تحديث حالة الشبح عند إعادة التولد (Respawn) أو التفعيل اليدوي
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1) -- ننتظر شوية لين تتحمل الشخصية
    if Settings.AutoFarmATM then
        SetGhostMode(true)
    else
        SetGhostMode(false)
    end
end)

print("Blockspin Master Hub V5.2 (Ghost Mode) Loaded Successfully!")
