---------------------------------------------------------
-- ORE FINDER 3000 (FINAL BUILD)
-- Full ESP Suite + Rotating Radar + GUI + Nearest Ore
-- Player-forward-is-up minimap radar
-- Draggable GUI + Draggable Radar
-- Auto-refresh pause logic + Arrow indicator
-- Fully merged and cleaned
---------------------------------------------------------

-- Load ESP
local ESP = loadstring(game:HttpGet("https://kiriot22.com/releases/ESP.lua"))()
ESP:Toggle(true)

---------------------------------------------------------
-- DISABLE BUILT-IN PLAYER ESP FROM LOADSTRING
---------------------------------------------------------
ESP.Players = false
ESP.Player = false
ESP.Character = false

---------------------------------------------------------
-- ORE DEFINITIONS
---------------------------------------------------------

local ORES = {
    {Name="Silicate",   ID=2,   Color=Color3.fromRGB(255,255,255)},
    {Name="Carbon",     ID=4,   Color=Color3.fromRGB(200,200,200)},
    {Name="Iridium",    ID=6,   Color=Color3.fromRGB(0,0,150)},
    {Name="Adamantite", ID=8,   Color=Color3.fromRGB(180,0,255)},
    {Name="Palladium",  ID=10,  Color=Color3.fromRGB(0,170,255)},
    {Name="Titanium",   ID=12,  Color=Color3.fromRGB(255,0,0)},
    {Name="Quantium",   ID=14,  Color=Color3.fromRGB(255,255,0)},
    {Name="Uranium",    ID=20,  Color=Color3.fromRGB(0,255,0)},
    {Name="CrudeOil",   ID=153, Color=Color3.fromRGB(255,140,0)},
}

---------------------------------------------------------
-- SAVED FILTER STATES
---------------------------------------------------------

local SavedOreFilters = {}
for _,ore in ipairs(ORES) do
    SavedOreFilters[ore.Name] = true
end

---------------------------------------------------------
-- FUNCTION: SETUP ORE ESP
---------------------------------------------------------

local function SetupOreESP()
    for _,ore in ipairs(ORES) do
        ESP:AddObjectListener(workspace.Asteroids, {
            Type = "Model",
            Recursive = true,
            CustomName = ore.Name,
            Color = ore.Color,

            Validator = function(obj)
                for _,v in ipairs(obj:GetDescendants()) do
                    if v.Name == "ID" and v.Value == ore.ID then
                        return true
                    end
                end
                return false
            end,

            IsEnabled = ore.Name
        })

        ESP[ore.Name] = SavedOreFilters[ore.Name]
    end
end

-- Initial setup
SetupOreESP()

---------------------------------------------------------
-- INPUT SERVICE
---------------------------------------------------------

local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")

---------------------------------------------------------
-- TOGGLE ALL ORES (K)
---------------------------------------------------------

local oresEnabled = true

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.K then
        oresEnabled = not oresEnabled

        if oresEnabled then
            for _,ore in ipairs(ORES) do
                ESP[ore.Name] = SavedOreFilters[ore.Name]
            end
        else
            for _,ore in ipairs(ORES) do
                ESP[ore.Name] = false
            end
        end

        print("Ore ESP toggled:", oresEnabled)
    end
end)

---------------------------------------------------------
-- CUSTOM PLAYER ESP (L)
---------------------------------------------------------

local playerESPEnabled = true

local function AddPlayerESP()
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            ESP:Add(plr.Character, {
                Name = plr.Name,
                Color = Color3.fromRGB(255,255,255)
            })
        end
    end
end

local function RemovePlayerESP()
    for obj,box in pairs(ESP.Objects) do
        if box and box.Name and Players:FindFirstChild(box.Name) then
            pcall(function()
                box:Remove()
            end)
        end
    end
end

AddPlayerESP()

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.L then
        playerESPEnabled = not playerESPEnabled
        if playerESPEnabled then
            AddPlayerESP()
        else
            RemovePlayerESP()
        end
        print("Player ESP toggled:", playerESPEnabled)
    end
end)

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(char)
        if playerESPEnabled then
            ESP:Add(char, {
                Name = plr.Name,
                Color = Color3.fromRGB(255,255,255)
            })
        end
    end)
end)

---------------------------------------------------------
-- REFRESH ORE ESP (H)
---------------------------------------------------------

local function RefreshOreESP()
    for obj,box in pairs(ESP.Objects) do
        if box and box.Name then
            for _,ore in ipairs(ORES) do
                if box.Name == ore.Name then
                    pcall(function()
                        box:Remove()
                    end)
                end
            end
        end
    end

    SetupOreESP()

    for _,ore in ipairs(ORES) do
        ESP[ore.Name] = SavedOreFilters[ore.Name]
    end

    print("Ore ESP refreshed.")
end

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.H then
        RefreshOreESP()
    end
end)

---------------------------------------------------------
-- AUTO REFRESH EVERY 60 SECONDS (PAUSES WHEN ORES OFF)
---------------------------------------------------------

task.spawn(function()
    while true do
        task.wait(60)
        if oresEnabled then
            RefreshOreESP()
        end
    end
end)

---------------------------------------------------------
-- GUI MENU (MOVABLE) + TOGGLE (J)
---------------------------------------------------------

local parentGui
local success, result = pcall(function() return gethui() end)
parentGui = (success and result) and result or game.CoreGui

local ScreenGui = Instance.new("ScreenGui", parentGui)
ScreenGui.Name = "Ore Finder 3000"

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 200, 0, #ORES * 25 + 40)
Frame.Position = UDim2.new(0, 20, 0, 200)
Frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
Frame.Visible = true
Frame.Active = true
Frame.Selectable = true

---------------------------------------------------------
-- GUI TITLE
---------------------------------------------------------

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundColor3 = Color3.fromRGB(20,20,20)
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.Text = "Ore Finder 3000"
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 20

---------------------------------------------------------
-- DRAGGING SYSTEM
---------------------------------------------------------

local dragging = false
local dragStart
local startPos

Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
    end
end)

Frame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

---------------------------------------------------------
-- GUI BUTTONS (SAVE FILTER STATES)
---------------------------------------------------------

for i,ore in ipairs(ORES) do
    local Button = Instance.new("TextButton", Frame)
    Button.Size = UDim2.new(1, -10, 0, 25)
    Button.Position = UDim2.new(0, 5, 0, 30 + (i-1)*25)
    Button.Text = ore.Name
    Button.BackgroundColor3 = SavedOreFilters[ore.Name]
        and Color3.fromRGB(50,120,50)
        or Color3.fromRGB(120,50,50)
    Button.TextColor3 = Color3.fromRGB(255,255,255)

    Button.MouseButton1Click:Connect(function()
        ESP[ore.Name] = not ESP[ore.Name]
        SavedOreFilters[ore.Name] = ESP[ore.Name]

        Button.BackgroundColor3 = ESP[ore.Name]
            and Color3.fromRGB(50,120,50)
            or Color3.fromRGB(120,50,50)
    end)
end

---------------------------------------------------------
-- NEAREST ORE INDICATOR (TOGGLES WITH GUI)
---------------------------------------------------------

local NearestGui = Instance.new("ScreenGui", parentGui)
NearestGui.Name = "NearestOreIndicator"

local NearestLabel = Instance.new("TextLabel", NearestGui)
NearestLabel.Size = UDim2.new(0, 300, 0, 30)
NearestLabel.Position = UDim2.new(0.5, -150, 0, 10)
NearestLabel.BackgroundTransparency = 0.3
NearestLabel.BackgroundColor3 = Color3.fromRGB(20,20,20)
NearestLabel.TextColor3 = Color3.fromRGB(255,255,255)
NearestLabel.Font = Enum.Font.SourceSansBold
NearestLabel.TextSize = 20
NearestLabel.Text = "Nearest Ore: Scanning..."

---------------------------------------------------------
-- GUI TOGGLE (J) — NOW ALSO TOGGLES NEAREST ORE
---------------------------------------------------------

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.J then
        Frame.Visible = not Frame.Visible
        NearestGui.Enabled = Frame.Visible
        print("GUI toggled:", Frame.Visible)
    end
end)

---------------------------------------------------------
-- NEAREST ORE FUNCTION (FIXED)
---------------------------------------------------------

local function GetNearestOre()
    local closestDist = math.huge
    local closestName = nil
    local closestColor = Color3.new(1,1,1)

    local player = game.Players.LocalPlayer
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return
    end

    local root = player.Character.HumanoidRootPart

    for _,ore in ipairs(ORES) do
        if SavedOreFilters[ore.Name] then
            for _,obj in ipairs(workspace.Asteroids:GetDescendants()) do
                if obj.Name == "ID" and obj.Value == ore.ID then

                    local orePart = obj.Parent:FindFirstChildWhichIsA("BasePart")
                    if orePart then
                        local dist = (orePart.Position - root.Position).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            closestName = ore.Name
                            closestColor = ore.Color
                        end
                    end

                end
            end
        end
    end

    if closestName then
        NearestLabel.Text = string.format("Nearest Ore: %s (%dm)", closestName, math.floor(closestDist))
        NearestLabel.TextColor3 = closestColor
    else
        NearestLabel.Text = "Nearest Ore: None"
        NearestLabel.TextColor3 = Color3.fromRGB(255,255,255)
    end
end

task.spawn(function()
    while true do
        GetNearestOre()
        task.wait(0.5)
    end
end)

---------------------------------------------------------
-- BILLBOARD ARROW (DOWNWARD, WHITE)
---------------------------------------------------------

local arrowEnabled = true

--// BILLBOARD GUI (ARROW + DISTANCE)
local ArrowGui = Instance.new("BillboardGui")
ArrowGui.Name = "OreArrow"
ArrowGui.Size = UDim2.new(0, 50, 0, 50)
ArrowGui.AlwaysOnTop = true
ArrowGui.LightInfluence = 0
ArrowGui.Enabled = true
ArrowGui.Parent = game.CoreGui   -- MUST be CoreGui for loadstring stability

--// ARROW ICON
local ArrowImage = Instance.new("ImageLabel")
ArrowImage.Name = "ArrowImage"
ArrowImage.Size = UDim2.new(0, 50, 0, 50)
ArrowImage.BackgroundTransparency = 1
ArrowImage.ZIndex = 10

-- Force reload (fixes GitHub RAW invisible character corruption)
ArrowImage.Image = ""
ArrowImage.Image = "https://i.imgur.com/BxjmEXo.png"

ArrowImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
ArrowImage.Parent = ArrowGui

--// DISTANCE TEXT
local ArrowText = Instance.new("TextLabel")
ArrowText.Name = "ArrowText"
ArrowText.Size = UDim2.new(0, 100, 0, 20)
ArrowText.Position = UDim2.new(0.5, -50, 1, 0)
ArrowText.BackgroundTransparency = 1
ArrowText.TextColor3 = Color3.fromRGB(255, 255, 255)
ArrowText.TextStrokeTransparency = 0.5
ArrowText.TextScaled = true
ArrowText.ZIndex = 11
ArrowText.Parent = ArrowGui

--// UPDATE FUNCTION
local function UpdateArrowTarget(closestPart, distance)
    if closestPart then
        ArrowGui.Adornee = closestPart
        ArrowText.Text = string.format("%s %dm away", closestPart.Name, math.floor(distance))
    else
        ArrowGui.Adornee = nil
        ArrowText.Text = ""
    end
end

---------------------------------------------------------
-- RADAR (TOGGLE N, DRAGGABLE, ROTATES WITH PLAYER)
---------------------------------------------------------

local RadarGui = Instance.new("ScreenGui", parentGui)
RadarGui.Name = "OreRadar"
RadarGui.Enabled = true

local RadarFrame = Instance.new("Frame", RadarGui)
RadarFrame.Size = UDim2.new(0, 150, 0, 150)
RadarFrame.Position = UDim2.new(0, 20, 0, 20)
RadarFrame.BackgroundColor3 = Color3.fromRGB(10,10,10)
RadarFrame.BorderSizePixel = 0

local RadarBorder = Instance.new("UICorner", RadarFrame)
RadarBorder.CornerRadius = UDim.new(0, 75)

local RadarCenter = Vector2.new(75, 75)
local RadarScale = 0.01
local RadarMaxRadius = 70

---------------------------------------------------------
-- DRAGGING FOR RADAR
---------------------------------------------------------

local radarDragging = false
local radarDragStart
local radarStartPos

RadarFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        radarDragging = true
        radarDragStart = input.Position
        radarStartPos = RadarFrame.Position
    end
end)

RadarFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        radarDragging = false
    end
end)

UIS.InputChanged:Connect(function(input)
    if radarDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - radarDragStart
        RadarFrame.Position = UDim2.new(
            radarStartPos.X.Scale,
            radarStartPos.X.Offset + delta.X,
            radarStartPos.Y.Scale,
            radarStartPos.Y.Offset + delta.Y
        )
    end
end)

---------------------------------------------------------
-- TOGGLE RADAR (N)
---------------------------------------------------------

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.N then
        RadarGui.Enabled = not RadarGui.Enabled
        print("Radar toggled:", RadarGui.Enabled)
    end
end)

---------------------------------------------------------
-- RADAR UPDATE LOOP
---------------------------------------------------------

task.spawn(function()
    while true do
        -- Clear radar dots each frame
        RadarFrame:ClearAllChildren()
        local corner = Instance.new("UICorner", RadarFrame)
        corner.CornerRadius = UDim.new(0, 75)

        local player = game.Players.LocalPlayer
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local root = player.Character.HumanoidRootPart

            -- Player forward direction
            local look = root.CFrame.LookVector
            local angle = math.atan2(look.Z, look.X)

            ---------------------------------------------------------
            -- Plot ore dots
            ---------------------------------------------------------

            for _,ore in ipairs(ORES) do
                if SavedOreFilters[ore.Name] then
                    for _,obj in ipairs(workspace.Asteroids:GetDescendants()) do
                        if obj.Name == "ID" and obj.Value == ore.ID then

                            local orePart = obj.Parent:FindFirstChildWhichIsA("BasePart")
                            if orePart then
                                local offset3 = (orePart.Position - root.Position) * RadarScale
                                local x = offset3.X
                                local z = offset3.Z

                                -- Rotate relative to player direction
                                local rx = x * math.cos(-angle) - z * math.sin(-angle)
                                local rz = x * math.sin(-angle) + z * math.cos(-angle)

                                local vec = Vector2.new(rx, rz)

                                -- Clamp to radar circle
                                if vec.Magnitude > RadarMaxRadius then
                                    vec = vec.Unit * RadarMaxRadius
                                end

                                -- Dot
                                local dot = Instance.new("Frame", RadarFrame)
                                dot.Size = UDim2.new(0, 6, 0, 6)
                                dot.Position = UDim2.new(
                                    0, RadarCenter.X + vec.X - 3,
                                    0, RadarCenter.Y + vec.Y - 3
                                )
                                dot.BackgroundColor3 = ore.Color or Color3.fromRGB(255,255,255)
                                dot.BorderSizePixel = 0
                            end
                        end
                    end
                end
            end

            ---------------------------------------------------------
            -- Player direction indicator (always points up)
            ---------------------------------------------------------

            local dir = Instance.new("Frame", RadarFrame)
            dir.Size = UDim2.new(0, 8, 0, 12)
            dir.Position = UDim2.new(0, RadarCenter.X - 4, 0, RadarCenter.Y - 12)
            dir.BackgroundColor3 = Color3.fromRGB(255,255,255)
            dir.BorderSizePixel = 0

            local dirCorner = Instance.new("UICorner", dir)
            dirCorner.CornerRadius = UDim.new(0, 4)
        end

        task.wait(0.2)
    end
end)

---------------------------------------------------------
-- FINAL SAFETY / CLEANUP LOOP
-- (Keeps ESP stable and prevents stale objects)
---------------------------------------------------------

task.spawn(function()
    while true do
        for obj, box in pairs(ESP.Objects) do
            if not obj or not obj.Parent then
                pcall(function()
                    box:Remove()
                end)
            end
        end
        task.wait(5)
    end
end)

---------------------------------------------------------
-- END OF OREFINDER 3000
-- All systems active:
-- ✔ ESP
-- ✔ GUI
-- ✔ Nearest Ore
-- ✔ Arrow Indicator
-- ✔ Radar (Rotating + Draggable)
-- ✔ Auto Refresh
-- ✔ Player ESP Toggle
-- ✔ Ore Filter Sync
---------------------------------------------------------

print("Ore Finder 3000 fully loaded.")
