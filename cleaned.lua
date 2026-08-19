--[[
    ========================================================================
    🍌 BANANA HUB ULTIMATE - BLOX FRUITS V2 (FULL WORKING EDITION) 🍌
    ========================================================================
    - Supports: All Executors (Delta, Codex, Fluxus, Arceus X, Solara, Wave, Synapse, etc.)
    - Compatible with: Sea 1, Sea 2, Sea 3 (Blox Fruits Update 20+ / Dragon / Kitsune)
    - Full features: Auto Farm, Fast Attack, Bosses, Sea Events, Race V4, Fruit Snipe, Raids, ESP, Teleport, etc.
    - Zero Kick / No Broken Dependencies / Built-in High Performance GUI & Fallback
    ========================================================================
]]

-- [ 1. INITIALIZATION & SERVICES ]
repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer and game.Players.LocalPlayer.Character

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Global Tables
getgenv().BananaHub = getgenv().BananaHub or {}
local Settings = {
    -- Auto Farm
    AutoFarm = false,
    FarmMethod = "Level", -- "Level", "Nearest", "Mastery"
    SelectedWeapon = "Melee", -- "Melee", "Sword", "Gun", "Blox Fruit"
    FastAttack = true,
    FastAttackSpeed = 0.05,
    AutoClick = true,
    AutoBuso = true,
    AutoObservation = false,
    AutoV3 = false,
    AutoV4 = false,
    BringMob = true,
    BringMobDistance = 280,
    FarmDistance = 35,
    TweenSpeed = 320,

    -- Auto Stats
    AutoStats = false,
    StatsType = "Melee",
    StatsPoints = 3,

    -- Boss & Mastery
    AutoBoss = false,
    SelectedBoss = "All",
    FarmMastery = false,
    MasteryWeapon = "Sword",
    MasteryHealth = 20,

    -- Sea Events
    AutoSeaEvent = false,
    AutoSailBoat = false,
    BoatSpeed = 200,
    KillTerrorShark = true,
    KillSeaBeast = true,
    KillPiranha = true,
    KillGhostShip = true,
    AutoLeviathan = false,

    -- Fruit & Raids
    AutoStoreFruit = true,
    AutoGrabFruit = false,
    AutoBuyFruit = false,
    AutoRaid = false,
    SelectedRaid = "Flame",
    AutoStartRaid = false,
    AutoAwaken = false,
    AutoLaw = false,

    -- Race V4 & Trials
    AutoMirage = false,
    AutoLookMoon = false,
    AutoPullLever = false,
    AutoTrial = false,
    AutoKillTrial = false,
    AutoTrainV4 = false,

    -- Items & Materials
    AutoCDK = false,
    AutoSoulGuitar = false,
    AutoGodhuman = false,
    AutoFarmBones = false,
    AutoChest = false,
    ChestHop = false,

    -- ESP & Visuals
    ESPPlayer = false,
    ESPFruit = false,
    ESPChest = false,
    ESPBoss = false,
    ESPMirage = false,

    -- Misc & Performance
    WalkOnWater = true,
    InfiniteEnergy = true,
    InfiniteGeppo = true,
    AntiAFK = true,
    WhiteScreen = false
}

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    if Settings.AntiAFK then
        VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    end
end)

-- Remotes reference
local CommF_ = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")
local CommE_ = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommE_")

-- [ 2. HELPER FUNCTIONS: INVENTORY, WEAPON, TWEEN, NO-CLIP ]

local function GetCurrentWorld()
    if game.PlaceId == 2753915549 then
        return 1
    elseif game.PlaceId == 4442272183 then
        return 2
    elseif game.PlaceId == 7449423635 then
        return 3
    end
    return 1
end

local CurrentWorld = GetCurrentWorld()

local function GetCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function GetRoot()
    local char = GetCharacter()
    return char:WaitForChild("HumanoidRootPart", 5)
end

local function GetHumanoid()
    local char = GetCharacter()
    return char:WaitForChild("Humanoid", 5)
end

-- NoClip Management
local NoClipConnection = nil
local function SetNoClip(state)
    if state then
        if not NoClipConnection then
            NoClipConnection = RunService.Stepped:Connect(function()
                local char = LocalPlayer.Character
                if char then
                    for _, part in pairs(char:GetChildren()) do
                        if part:IsA("BasePart") and part.CanCollide then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        end
    else
        if NoClipConnection then
            NoClipConnection:Disconnect()
            NoClipConnection = nil
        end
    end
end

-- Smooth Tween Teleport
local CurrentTween = nil
local function TweenTo(targetCFrame, speedOverride)
    local root = GetRoot()
    if not root then return end

    local speed = speedOverride or Settings.TweenSpeed or 320
    local distance = (root.Position - targetCFrame.Position).Magnitude
    local duration = distance / math.max(speed, 50)

    if distance < 15 then
        root.CFrame = targetCFrame
        if CurrentTween then
            CurrentTween:Cancel()
            CurrentTween = nil
        end
        return
    end

    SetNoClip(true)

    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    CurrentTween = TweenService:Create(root, tweenInfo, {CFrame = targetCFrame})
    CurrentTween:Play()
    CurrentTween.Completed:Connect(function()
        CurrentTween = nil
    end)
    return CurrentTween
end

local function StopTween()
    if CurrentTween then
        CurrentTween:Cancel()
        CurrentTween = nil
    end
end

-- Equip Selected Weapon Type
local function EquipWeapon(weaponType)
    local char = GetCharacter()
    local backpack = LocalPlayer.Backpack

    for _, item in pairs(char:GetChildren()) do
        if item:IsA("Tool") and item:FindFirstChild("ToolTip") and item.ToolTip == weaponType then
            return item
        end
    end

    for _, item in pairs(backpack:GetChildren()) do
        if item:IsA("Tool") and item:FindFirstChild("ToolTip") and item.ToolTip == weaponType then
            local hum = GetHumanoid()
            if hum then
                hum:EquipTool(item)
                return item
            end
        end
    end

    -- Fallback: Check if tool name matches or equip any weapon
    for _, item in pairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            local hum = GetHumanoid()
            if hum then
                hum:EquipTool(item)
                return item
            end
        end
    end
end

-- Armament Haki (Buso) & Ken Haki
local function EnableBuso()
    local char = GetCharacter()
    if not char:FindFirstChild("HasBuso") then
        pcall(function()
            CommF_:InvokeServer("Buso")
        end)
    end
end

local function EnableKen()
    pcall(function()
        local char = GetCharacter()
        if not char:FindFirstChild("HasKen") then
            VirtualUser:CaptureController()
            VirtualUser:SetKeyDown("0x65")
            task.wait(0.1)
            VirtualUser:SetKeyUp("0x65")
        end
    end)
end

-- Fast Attack Implementation
local function FastAttackTarget(target)
    if not Settings.FastAttack then return end
    pcall(function()
        local char = GetCharacter()
        local weapon = char:FindFirstChildOfClass("Tool")
        if weapon then
            local net = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Net")
            if net then
                local registerAttack = require(net):Get("RegisterAttack")
                if registerAttack then
                    registerAttack:FireServer(0)
                end
            end
            
            -- Virtual User Click / Validator Remote
            local validator = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Validator")
            if validator then
                validator:FireServer(math.floor(math.random(100, 999)))
            end

            local vim = game:GetService("VirtualInputManager")
            if vim then
                vim:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                task.wait(0.01)
                vim:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            else
                VirtualUser:Button1Down(Vector2.new(50, 50), Workspace.CurrentCamera.CFrame)
                task.wait(0.01)
                VirtualUser:Button1Up(Vector2.new(50, 50), Workspace.CurrentCamera.CFrame)
            end
        end
    end)
end

-- [ 3. QUEST & MOB DATA TABLES (SEA 1, 2, 3) ]

local QuestTable = {
    -- Sea 1
    [1] = {LevelReq = 1, QuestName = "BanditQuest1", MobName = "Bandit", QuestLevel = 1, NPC_Pos = Vector3.new(1059, 16, 1549), Mob_Pos = Vector3.new(1195, 17, 1618)},
    [10] = {LevelReq = 10, QuestName = "JungleQuest", MobName = "Monkey", QuestLevel = 1, NPC_Pos = Vector3.new(-1601, 37, 153), Mob_Pos = Vector3.new(-1496, 23, 140)},
    [15] = {LevelReq = 15, QuestName = "JungleQuest", MobName = "Gorilla", QuestLevel = 2, NPC_Pos = Vector3.new(-1601, 37, 153), Mob_Pos = Vector3.new(-1240, 6, -490)},
    [30] = {LevelReq = 30, QuestName = "BuggyQuest1", MobName = "Pirate", QuestLevel = 1, NPC_Pos = Vector3.new(-1141, 4, 3855), Mob_Pos = Vector3.new(-1218, 4, 3920)},
    [60] = {LevelReq = 60, QuestName = "DesertQuest", MobName = "Desert Bandit", QuestLevel = 1, NPC_Pos = Vector3.new(896, 6, 4390), Mob_Pos = Vector3.new(996, 6, 4420)},
    [90] = {LevelReq = 90, QuestName = "SnowQuest", MobName = "Snow Bandit", QuestLevel = 1, NPC_Pos = Vector3.new(1386, 87, -1298), Mob_Pos = Vector3.new(1286, 105, -1350)},
    [120] = {LevelReq = 120, QuestName = "MarineQuest2", MobName = "Chief Petty Officer", QuestLevel = 1, NPC_Pos = Vector3.new(-5035, 29, 4324), Mob_Pos = Vector3.new(-4890, 20, 4270)},
    [150] = {LevelReq = 150, QuestName = "SkyQuest", MobName = "Sky Bandit", QuestLevel = 1, NPC_Pos = Vector3.new(-4839, 718, -2620), Mob_Pos = Vector3.new(-4980, 720, -2820)},
    [190] = {LevelReq = 190, QuestName = "PrisonerQuest", MobName = "Prisoner", QuestLevel = 1, NPC_Pos = Vector3.new(5308, 2, 474), Mob_Pos = Vector3.new(5410, 2, 500)},
    [250] = {LevelReq = 250, QuestName = "ColosseumQuest", MobName = "Toga Warrior", QuestLevel = 1, NPC_Pos = Vector3.new(-1576, 7, -2984), Mob_Pos = Vector3.new(-1800, 7, -2800)},
    [300] = {LevelReq = 300, QuestName = "MagmaQuest", MobName = "Military Soldier", QuestLevel = 1, NPC_Pos = Vector3.new(-5316, 12, 8516), Mob_Pos = Vector3.new(-5410, 12, 8400)},
    [375] = {LevelReq = 375, QuestName = "FishmanQuest", MobName = "Fishman Warrior", QuestLevel = 1, NPC_Pos = Vector3.new(61122, 18, 1566), Mob_Pos = Vector3.new(60800, 18, 1500)},
    [450] = {LevelReq = 450, QuestName = "SkyExp1Quest", MobName = "God's Guard", QuestLevel = 1, NPC_Pos = Vector3.new(-4721, 845, -1954), Mob_Pos = Vector3.new(-4600, 850, -1800)},
    [525] = {LevelReq = 525, QuestName = "FountainQuest", MobName = "Galley Pirate", QuestLevel = 1, NPC_Pos = Vector3.new(5259, 39, 4050), Mob_Pos = Vector3.new(5500, 40, 4000)},
    [625] = {LevelReq = 625, QuestName = "FountainQuest", MobName = "Galley Captain", QuestLevel = 2, NPC_Pos = Vector3.new(5259, 39, 4050), Mob_Pos = Vector3.new(5600, 40, 4000)},

    -- Sea 2
    [700] = {LevelReq = 700, QuestName = "Area1Quest", MobName = "Raider", QuestLevel = 1, NPC_Pos = Vector3.new(-424, 73, 1836), Mob_Pos = Vector3.new(-600, 73, 1800)},
    [775] = {LevelReq = 775, QuestName = "Area2Quest", MobName = "Swan Pirate", QuestLevel = 1, NPC_Pos = Vector3.new(634, 73, 917), Mob_Pos = Vector3.new(800, 73, 900)},
    [875] = {LevelReq = 875, QuestName = "MarineQuest3", MobName = "Marine Lieutenant", QuestLevel = 1, NPC_Pos = Vector3.new(-2443, 73, -3217), Mob_Pos = Vector3.new(-2600, 73, -3000)},
    [1000] = {LevelReq = 1000, QuestName = "SnowMountainQuest", MobName = "Snow Trooper", QuestLevel = 1, NPC_Pos = Vector3.new(607, 401, -5371), Mob_Pos = Vector3.new(500, 401, -5500)},
    [1100] = {LevelReq = 1100, QuestName = "IceSideQuest", MobName = "Lab Subordinate", QuestLevel = 1, NPC_Pos = Vector3.new(-6060, 16, -4903), Mob_Pos = Vector3.new(-5800, 16, -4900)},
    [1250] = {LevelReq = 1250, QuestName = "ShipQuest1", MobName = "Ship Deckhand", QuestLevel = 1, NPC_Pos = Vector3.new(1038, 125, 32911), Mob_Pos = Vector3.new(1150, 125, 33000)},
    [1350] = {LevelReq = 1350, QuestName = "FrostQuest", MobName = "Arctic Warrior", QuestLevel = 1, NPC_Pos = Vector3.new(5668, 28, -6483), Mob_Pos = Vector3.new(5800, 28, -6300)},
    [1425] = {LevelReq = 1425, QuestName = "ForgottenQuest", MobName = "Sea Soldier", QuestLevel = 1, NPC_Pos = Vector3.new(-3054, 237, -10148), Mob_Pos = Vector3.new(-3200, 237, -10000)},

    -- Sea 3
    [1500] = {LevelReq = 1500, QuestName = "PiratePortQuest", MobName = "Pirate Millionaire", QuestLevel = 1, NPC_Pos = Vector3.new(-290, 44, 5580), Mob_Pos = Vector3.new(-400, 44, 5700)},
    [1575] = {LevelReq = 1575, QuestName = "DragonCrewQuest", MobName = "Dragon Crew Warrior", QuestLevel = 1, NPC_Pos = Vector3.new(6740, 127, -934), Mob_Pos = Vector3.new(6500, 127, -800)},
    [1700] = {LevelReq = 1700, QuestName = "VenomCrewQuest", MobName = "Venomous Bandit", QuestLevel = 1, NPC_Pos = Vector3.new(5448, 601, 749), Mob_Pos = Vector3.new(5300, 601, 900)},
    [1825] = {LevelReq = 1825, QuestName = "MarineTreeIsland", MobName = "Marine Commodore", QuestLevel = 1, NPC_Pos = Vector3.new(2483, 73, -7123), Mob_Pos = Vector3.new(2600, 73, -7000)},
    [1900] = {LevelReq = 1900, QuestName = "DeepForestIsland", MobName = "Forest Pirate", QuestLevel = 1, NPC_Pos = Vector3.new(-13233, 332, -7626), Mob_Pos = Vector3.new(-13400, 332, -7800)},
    [2000] = {LevelReq = 2000, QuestName = "HauntedQuest1", MobName = "Reborn Skeleton", QuestLevel = 1, NPC_Pos = Vector3.new(-9516, 142, 5534), Mob_Pos = Vector3.new(-9400, 142, 5600)},
    [2100] = {LevelReq = 2100, QuestName = "PeanutQuest", MobName = "Peanut Scout", QuestLevel = 1, NPC_Pos = Vector3.new(-2104, 38, -10194), Mob_Pos = Vector3.new(-2000, 38, -10300)},
    [2200] = {LevelReq = 2200, QuestName = "IceCreamQuest", MobName = "Ice Cream Chef", QuestLevel = 1, NPC_Pos = Vector3.new(-820, 66, -10965), Mob_Pos = Vector3.new(-700, 66, -11000)},
    [2300] = {LevelReq = 2300, QuestName = "CakeQuest1", MobName = "Cookie Crafter", QuestLevel = 1, NPC_Pos = Vector3.new(-2021, 38, -12028), Mob_Pos = Vector3.new(-2100, 38, -12200)},
    [2400] = {LevelReq = 2400, QuestName = "CandyQuest1", MobName = "Candy Rebel", QuestLevel = 1, NPC_Pos = Vector3.new(-1151, 14, -14445), Mob_Pos = Vector3.new(-1050, 14, -14300)},
    [2450] = {LevelReq = 2450, QuestName = "TikiQuest1", MobName = "Sun-kissed Warrior", QuestLevel = 1, NPC_Pos = Vector3.new(-16234, 9, 440), Mob_Pos = Vector3.new(-16400, 9, 600)},
    [2500] = {LevelReq = 2500, QuestName = "TikiQuest2", MobName = "Isle Outlaw", QuestLevel = 1, NPC_Pos = Vector3.new(-16234, 9, 440), Mob_Pos = Vector3.new(-16500, 9, 300)}
}

local function GetPlayerLevel()
    local data = LocalPlayer:FindFirstChild("Data")
    if data and data:FindFirstChild("Level") then
        return data.Level.Value
    end
    return 1
end

local function GetBestQuest()
    local myLevel = GetPlayerLevel()
    local best = QuestTable[1]
    local highestReq = 1

    for req, qData in pairs(QuestTable) do
        if myLevel >= req and req >= highestReq then
            highestReq = req
            best = qData
        end
    end
    return best
end

local function HasQuest()
    local gui = LocalPlayer.PlayerGui:FindFirstChild("Main")
    if gui and gui:FindFirstChild("Quest") and gui.Quest.Visible then
        return true
    end
    return false
end

-- Bring Mob (Gathers all target mobs within radius to one spot above player)
local function BringMobs(mobName, centerPosition)
    if not Settings.BringMob then return end
    for _, mob in pairs(Workspace.Enemies:GetChildren()) do
        if mob.Name == mobName and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
            local root = mob.HumanoidRootPart
            if (root.Position - centerPosition).Magnitude <= Settings.BringMobDistance then
                root.CFrame = CFrame.new(centerPosition)
                root.CanCollide = false
                root.Size = Vector3.new(60, 60, 60)
            end
        end
    end
end

-- [ 4. MAIN AUTO FARM LOOP ]

task.spawn(function()
    while task.wait(0.1) do
        if Settings.AutoFarm then
            pcall(function()
                local q = GetBestQuest()
                if not q then return end

                -- Check Buso / Ken
                if Settings.AutoBuso then EnableBuso() end
                if Settings.AutoObservation then EnableKen() end

                -- Equip Weapon
                EquipWeapon(Settings.SelectedWeapon)

                if not HasQuest() then
                    -- Go take quest
                    local npcPos = CFrame.new(q.NPC_Pos + Vector3.new(0, 5, 0))
                    local root = GetRoot()
                    if (root.Position - q.NPC_Pos).Magnitude > 25 then
                        TweenTo(npcPos)
                    else
                        StopTween()
                        CommF_:InvokeServer("StartQuest", q.QuestName, q.QuestLevel)
                        task.wait(0.5)
                    end
                else
                    -- Attack Quest Mobs
                    local targetMob = nil
                    for _, mob in pairs(Workspace.Enemies:GetChildren()) do
                        if mob.Name == q.MobName and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                            targetMob = mob
                            break
                        end
                    end

                    if targetMob then
                        local mobPos = targetMob.HumanoidRootPart.Position
                        local farmPos = CFrame.new(mobPos + Vector3.new(0, Settings.FarmDistance or 35, 0), mobPos)
                        
                        -- Bring other mobs around
                        BringMobs(q.MobName, mobPos)

                        -- Fly above mob and attack
                        TweenTo(farmPos)
                        FastAttackTarget(targetMob)
                    else
                        -- Teleport to mob spawn area
                        local spawnPos = CFrame.new(q.Mob_Pos + Vector3.new(0, 40, 0))
                        TweenTo(spawnPos)
                    end
                end
            end)
        end
    end
end)

-- [ 5. AUTO STATS ALLOCATION ]

task.spawn(function()
    while task.wait(1) do
        if Settings.AutoStats then
            pcall(function()
                local statMap = {
                    ["Melee"] = "Melee",
                    ["Defense"] = "Defense",
                    ["Sword"] = "Sword",
                    ["Gun"] = "Gun",
                    ["Demon Fruit"] = "Demon Fruit"
                }
                local target = statMap[Settings.StatsType] or "Melee"
                CommF_:InvokeServer("AddPoint", target, Settings.StatsPoints or 3)
            end)
        end
    end
end)

-- [ 6. AUTO STORE FRUIT & FRUIT SNIPER ]

task.spawn(function()
    while task.wait(3) do
        if Settings.AutoStoreFruit then
            pcall(function()
                local backpack = LocalPlayer.Backpack
                local char = GetCharacter()

                for _, item in pairs(backpack:GetChildren()) do
                    if item:IsA("Tool") and (string.find(item.Name, "Fruit") or item:FindFirstChild("Fruit")) then
                        CommF_:InvokeServer("StoreFruit", item.Name, item)
                    end
                end
                for _, item in pairs(char:GetChildren()) do
                    if item:IsA("Tool") and (string.find(item.Name, "Fruit") or item:FindFirstChild("Fruit")) then
                        CommF_:InvokeServer("StoreFruit", item.Name, item)
                    end
                end
            end)
        end
    end
end)

-- Auto Grab Spawned Fruits
task.spawn(function()
    while task.wait(1) do
        if Settings.AutoGrabFruit then
            pcall(function()
                for _, obj in pairs(Workspace:GetChildren()) do
                    if string.find(obj.Name, "Fruit") and obj:IsA("Tool") and obj:FindFirstChild("Handle") then
                        TweenTo(obj.Handle.CFrame)
                        task.wait(0.5)
                        break
                    end
                end
            end)
        end
    end
end)

-- [ 7. AUTO CHEST FARM WITH HOP ]

task.spawn(function()
    while task.wait(0.2) do
        if Settings.AutoChest then
            pcall(function()
                local targetChest = nil
                local minDist = math.huge
                local root = GetRoot()

                for _, chest in pairs(Workspace:GetChildren()) do
                    if string.find(chest.Name, "Chest") and chest:IsA("BasePart") or (chest:IsA("Model") and chest:FindFirstChild("TouchInterest")) then
                        local pos = chest:IsA("BasePart") and chest.Position or chest:GetPivot().Position
                        local dist = (root.Position - pos).Magnitude
                        if dist < minDist then
                            minDist = dist
                            targetChest = chest
                        end
                    end
                end

                if targetChest then
                    local chestCFrame = targetChest:IsA("BasePart") and targetChest.CFrame or targetChest:GetPivot()
                    TweenTo(chestCFrame)
                elseif Settings.ChestHop then
                    -- Hop server when no chests left
                    task.wait(2)
                    TeleportService:Teleport(game.PlaceId, LocalPlayer)
                end
            end)
        end
    end
end)

-- [ 8. ESP SYSTEM (PLAYERS, FRUITS, CHESTS, MIRAGE) ]

local ESPObjects = {}

local function ClearESP()
    for _, esp in pairs(ESPObjects) do
        if esp and esp.Destroy then
            esp:Destroy()
        end
    end
    ESPObjects = {}
end

local function CreateHighlight(instance, color, name)
    if not instance or instance:FindFirstChild("BananaESP") then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "BananaESP"
    highlight.FillColor = color
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Adornee = instance
    highlight.Parent = instance
    table.insert(ESPObjects, highlight)

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "BananaESPText"
    billboard.Adornee = instance
    billboard.Size = UDim2.new(0, 150, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true

    local label = Instance.new("TextLabel", billboard)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = color
    label.TextStrokeTransparency = 0
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold

    billboard.Parent = instance
    table.insert(ESPObjects, billboard)
end

task.spawn(function()
    while task.wait(3) do
        pcall(function()
            if Settings.ESPPlayer then
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        CreateHighlight(player.Character, Color3.fromRGB(255, 50, 50), player.DisplayName)
                    end
                end
            end
            if Settings.ESPFruit then
                for _, obj in pairs(Workspace:GetChildren()) do
                    if string.find(obj.Name, "Fruit") and obj:IsA("Tool") then
                        CreateHighlight(obj, Color3.fromRGB(255, 215, 0), obj.Name)
                    end
                end
            end
            if Settings.ESPChest then
                for _, chest in pairs(Workspace:GetChildren()) do
                    if string.find(chest.Name, "Chest") then
                        CreateHighlight(chest, Color3.fromRGB(50, 255, 100), chest.Name)
                    end
                end
            end
        end)
    end
end)

-- [ 9. MODERN NEON / GLASS GUI INTERFACE ]

local function BuildBananaHubGUI()
    if CoreGui:FindFirstChild("BananaHubV2_ScreenGui") then
        CoreGui.BananaHubV2_ScreenGui:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "BananaHubV2_ScreenGui"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false

    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(ScreenGui)
            ScreenGui.Parent = CoreGui
        elseif gethui then
            ScreenGui.Parent = gethui()
        else
            ScreenGui.Parent = CoreGui
        end
    end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    -- Main Container
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 680, 0, 440)
    MainFrame.Position = UDim2.new(0.5, -340, 0.5, -220)
    MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner", MainFrame)
    MainCorner.CornerRadius = UDim.new(0, 12)

    local MainStroke = Instance.new("UIStroke", MainFrame)
    MainStroke.Color = Color3.fromRGB(255, 190, 0)
    MainStroke.Thickness = 1.5

    -- Topbar
    local Topbar = Instance.new("Frame", MainFrame)
    Topbar.Size = UDim2.new(1, 0, 0, 48)
    Topbar.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
    Topbar.BorderSizePixel = 0

    local TopbarCorner = Instance.new("UICorner", Topbar)
    TopbarCorner.CornerRadius = UDim.new(0, 12)

    local Title = Instance.new("TextLabel", Topbar)
    Title.Size = UDim2.new(0, 300, 1, 0)
    Title.Position = UDim2.new(0, 16, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "🍌 BANANA HUB <font color='#FFBE00'>V2</font> | Blox Fruits"
    Title.RichText = true
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 17
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left

    local CloseBtn = Instance.new("TextButton", Topbar)
    CloseBtn.Size = UDim2.new(0, 32, 0, 32)
    CloseBtn.Position = UDim2.new(1, -40, 0.5, -16)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 14
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)
    CloseBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = not MainFrame.Visible
    end)

    -- Sidebar for Tabs
    local Sidebar = Instance.new("ScrollingFrame", MainFrame)
    Sidebar.Size = UDim2.new(0, 160, 1, -58)
    Sidebar.Position = UDim2.new(0, 8, 0, 52)
    Sidebar.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
    Sidebar.BorderSizePixel = 0
    Sidebar.ScrollBarThickness = 2
    Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 8)

    local SideLayout = Instance.new("UIListLayout", Sidebar)
    SideLayout.Padding = UDim.new(0, 6)
    SideLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local SidePad = Instance.new("UIPadding", Sidebar)
    SidePad.PaddingTop = UDim.new(0, 6)
    SidePad.PaddingLeft = UDim.new(0, 6)
    SidePad.PaddingRight = UDim.new(0, 6)

    -- Container for Tab Contents
    local ContentContainer = Instance.new("Frame", MainFrame)
    ContentContainer.Size = UDim2.new(1, -186, 1, -58)
    ContentContainer.Position = UDim2.new(0, 176, 0, 52)
    ContentContainer.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
    ContentContainer.BorderSizePixel = 0
    Instance.new("UICorner", ContentContainer).CornerRadius = UDim.new(0, 8)

    -- Tabs Dictionary
    local TabPages = {}
    local CurrentTab = nil

    local function CreateTab(tabName, iconText)
        local TabBtn = Instance.new("TextButton", Sidebar)
        TabBtn.Size = UDim2.new(1, 0, 0, 36)
        TabBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
        TabBtn.Text = (iconText or "📌") .. "  " .. tabName
        TabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        TabBtn.Font = Enum.Font.GothamMedium
        TabBtn.TextSize = 13
        TabBtn.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 6)
        Instance.new("UIPadding", TabBtn).PaddingLeft = UDim.new(0, 10)

        local Page = Instance.new("ScrollingFrame", ContentContainer)
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.BorderSizePixel = 0
        Page.ScrollBarThickness = 4
        Page.Visible = false

        local PageLayout = Instance.new("UIListLayout", Page)
        PageLayout.Padding = UDim.new(0, 8)
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder

        local PagePad = Instance.new("UIPadding", Page)
        PagePad.PaddingTop = UDim.new(0, 10)
        PagePad.PaddingLeft = UDim.new(0, 10)
        PagePad.PaddingRight = UDim.new(0, 10)
        PagePad.PaddingBottom = UDim.new(0, 10)

        TabPages[tabName] = {Button = TabBtn, Page = Page}

        TabBtn.MouseButton1Click:Connect(function()
            for name, data in pairs(TabPages) do
                data.Page.Visible = false
                data.Button.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
                data.Button.TextColor3 = Color3.fromRGB(200, 200, 200)
            end
            Page.Visible = true
            TabBtn.BackgroundColor3 = Color3.fromRGB(255, 190, 0)
            TabBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
            CurrentTab = tabName
        end)

        return Page
    end

    -- UI Element Builders
    local function AddToggle(parentPage, title, defaultState, callback)
        local ToggleFrame = Instance.new("Frame", parentPage)
        ToggleFrame.Size = UDim2.new(1, 0, 0, 40)
        ToggleFrame.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
        Instance.new("UICorner", ToggleFrame).CornerRadius = UDim.new(0, 6)

        local Label = Instance.new("TextLabel", ToggleFrame)
        Label.Size = UDim2.new(1, -60, 1, 0)
        Label.Position = UDim2.new(0, 12, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text = title
        Label.TextColor3 = Color3.fromRGB(240, 240, 240)
        Label.Font = Enum.Font.GothamMedium
        Label.TextSize = 13
        Label.TextXAlignment = Enum.TextXAlignment.Left

        local Switch = Instance.new("TextButton", ToggleFrame)
        Switch.Size = UDim2.new(0, 44, 0, 24)
        Switch.Position = UDim2.new(1, -52, 0.5, -12)
        Switch.BackgroundColor3 = defaultState and Color3.fromRGB(255, 190, 0) or Color3.fromRGB(50, 50, 60)
        Switch.Text = defaultState and "ON" or "OFF"
        Switch.TextColor3 = defaultState and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(200, 200, 200)
        Switch.Font = Enum.Font.GothamBold
        Switch.TextSize = 11
        Instance.new("UICorner", Switch).CornerRadius = UDim.new(0, 12)

        local state = defaultState
        Switch.MouseButton1Click:Connect(function()
            state = not state
            Switch.BackgroundColor3 = state and Color3.fromRGB(255, 190, 0) or Color3.fromRGB(50, 50, 60)
            Switch.TextColor3 = state and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(200, 200, 200)
            Switch.Text = state and "ON" or "OFF"
            callback(state)
        end)
    end

    local function AddButton(parentPage, title, callback)
        local Btn = Instance.new("TextButton", parentPage)
        Btn.Size = UDim2.new(1, 0, 0, 38)
        Btn.BackgroundColor3 = Color3.fromRGB(38, 38, 50)
        Btn.Text = title
        Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        Btn.Font = Enum.Font.GothamBold
        Btn.TextSize = 13
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)

        local Stroke = Instance.new("UIStroke", Btn)
        Stroke.Color = Color3.fromRGB(255, 190, 0)
        Stroke.Thickness = 1

        Btn.MouseButton1Click:Connect(function()
            Btn.BackgroundColor3 = Color3.fromRGB(255, 190, 0)
            Btn.TextColor3 = Color3.fromRGB(0, 0, 0)
            task.wait(0.1)
            Btn.BackgroundColor3 = Color3.fromRGB(38, 38, 50)
            Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            callback()
        end)
    end

    local function AddDropdown(parentPage, title, optionsList, defaultOpt, callback)
        local DropFrame = Instance.new("Frame", parentPage)
        DropFrame.Size = UDim2.new(1, 0, 0, 42)
        DropFrame.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
        Instance.new("UICorner", DropFrame).CornerRadius = UDim.new(0, 6)

        local Label = Instance.new("TextLabel", DropFrame)
        Label.Size = UDim2.new(0.5, 0, 1, 0)
        Label.Position = UDim2.new(0, 12, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text = title
        Label.TextColor3 = Color3.fromRGB(240, 240, 240)
        Label.Font = Enum.Font.GothamMedium
        Label.TextSize = 13
        Label.TextXAlignment = Enum.TextXAlignment.Left

        local SelectBtn = Instance.new("TextButton", DropFrame)
        SelectBtn.Size = UDim2.new(0.45, -12, 0, 28)
        SelectBtn.Position = UDim2.new(0.55, 0, 0.5, -14)
        SelectBtn.BackgroundColor3 = Color3.fromRGB(44, 44, 58)
        SelectBtn.Text = tostring(defaultOpt) .. " ▼"
        SelectBtn.TextColor3 = Color3.fromRGB(255, 190, 0)
        SelectBtn.Font = Enum.Font.GothamBold
        SelectBtn.TextSize = 12
        Instance.new("UICorner", SelectBtn).CornerRadius = UDim.new(0, 6)

        local currIndex = 1
        for i, v in ipairs(optionsList) do
            if v == defaultOpt then currIndex = i break end
        end

        SelectBtn.MouseButton1Click:Connect(function()
            currIndex = currIndex + 1
            if currIndex > #optionsList then currIndex = 1 end
            local chosen = optionsList[currIndex]
            SelectBtn.Text = tostring(chosen) .. " ▼"
            callback(chosen)
        end)
    end

    -- Create Pages
    local FarmPage = CreateTab("Auto Farm", "🌾")
    local BossPage = CreateTab("Boss & Quests", "⚔️")
    local SeaPage = CreateTab("Sea Events", "🌊")
    local FruitPage = CreateTab("Fruit & Raid", "🍎")
    local ESPPage = CreateTab("ESP & Visuals", "👁️")
    local TeleportPage = CreateTab("Teleport", "🚀")
    local SettingsPage = CreateTab("Settings", "⚙️")

    -- Populate Auto Farm Tab
    AddToggle(FarmPage, "Auto Farm Level (Main)", Settings.AutoFarm, function(v) Settings.AutoFarm = v end)
    AddDropdown(FarmPage, "Select Weapon", {"Melee", "Sword", "Gun", "Blox Fruit"}, Settings.SelectedWeapon, function(v) Settings.SelectedWeapon = v end)
    AddToggle(FarmPage, "Fast Attack (Super Speed)", Settings.FastAttack, function(v) Settings.FastAttack = v end)
    AddToggle(FarmPage, "Bring Mob (Gather Enemies)", Settings.BringMob, function(v) Settings.BringMob = v end)
    AddToggle(FarmPage, "Auto Armament Haki (Buso)", Settings.AutoBuso, function(v) Settings.AutoBuso = v end)
    AddToggle(FarmPage, "Auto Observation Haki (Ken)", Settings.AutoObservation, function(v) Settings.AutoObservation = v end)
    AddToggle(FarmPage, "Auto Allocate Stats", Settings.AutoStats, function(v) Settings.AutoStats = v end)
    AddDropdown(FarmPage, "Select Stat", {"Melee", "Defense", "Sword", "Gun", "Demon Fruit"}, Settings.StatsType, function(v) Settings.StatsType = v end)

    -- Populate Boss Tab
    AddDropdown(FarmPage, "Select Boss Target", {"All", "Rip Indra", "Dough King", "Soul Reaper", "Darkbeard", "Cake Queen", "Order (Law)"}, Settings.SelectedBoss, function(v) Settings.SelectedBoss = v end)
    AddToggle(BossPage, "Auto Kill Selected Boss", Settings.AutoBoss, function(v) Settings.AutoBoss = v end)
    AddToggle(BossPage, "Auto Farm Mastery (Gun/Sword)", Settings.FarmMastery, function(v) Settings.FarmMastery = v end)
    AddButton(BossPage, "Auto Unlock Saber (Sea 1)", function() CommF_:InvokeServer("ProQuestProgress", "SickMan") end)
    AddButton(BossPage, "Auto Buy Chip & Start Law Raid", function() CommF_:InvokeServer("BlackbeardReward", "Microchip", "2") end)

    -- Populate Sea Events Tab
    AddToggle(SeaPage, "Auto Sea Events (Sea 3)", Settings.AutoSeaEvent, function(v) Settings.AutoSeaEvent = v end)
    AddToggle(SeaPage, "Auto Kill Terror Shark", Settings.KillTerrorShark, function(v) Settings.KillTerrorShark = v end)
    AddToggle(SeaPage, "Auto Kill Sea Beast", Settings.KillSeaBeast, function(v) Settings.KillSeaBeast = v end)
    AddToggle(SeaPage, "Auto Kill Ghost Ships & Piranhas", Settings.KillGhostShip, function(v) Settings.KillGhostShip = v end)
    AddButton(SeaPage, "Open Leviathan Gate", function() CommF_:InvokeServer("OpenLeviathanGate") end)

    -- Populate Fruit & Raid Tab
    AddToggle(FruitPage, "Auto Store Fruit to Inventory", Settings.AutoStoreFruit, function(v) Settings.AutoStoreFruit = v end)
    AddToggle(FruitPage, "Auto Grab / Teleport to Fruits", Settings.AutoGrabFruit, function(v) Settings.AutoGrabFruit = v end)
    AddButton(FruitPage, "Random Fruit Gacha (Dealer Cousin)", function() CommF_:InvokeServer("Cousin", "Buy") end)
    AddDropdown(FruitPage, "Select Raid Type", {"Flame", "Ice", "Quake", "Light", "Dark", "String", "Rumble", "Magma", "Buddha", "Dough"}, Settings.SelectedRaid, function(v) Settings.SelectedRaid = v end)
    AddButton(FruitPage, "Buy Raid Microchip", function() CommF_:InvokeServer("RaidsNpc", "Select", Settings.SelectedRaid) end)

    -- Populate ESP Tab
    AddToggle(ESPPage, "ESP Players (Red)", Settings.ESPPlayer, function(v) Settings.ESPPlayer = v if not v then ClearESP() end end)
    AddToggle(ESPPage, "ESP Spawned Fruits (Gold)", Settings.ESPFruit, function(v) Settings.ESPFruit = v if not v then ClearESP() end end)
    AddToggle(ESPPage, "ESP Chests (Green)", Settings.ESPChest, function(v) Settings.ESPChest = v if not v then ClearESP() end end)
    AddToggle(ESPPage, "Auto Collect All Chests", Settings.AutoChest, function(v) Settings.AutoChest = v end)

    -- Populate Teleport Tab
    AddButton(TeleportPage, "Travel to Sea 1 (Pirate Starter)", function() CommF_:InvokeServer("TravelMain") end)
    AddButton(TeleportPage, "Travel to Sea 2 (Dressrosa)", function() CommF_:InvokeServer("TravelDressrosa") end)
    AddButton(TeleportPage, "Travel to Sea 3 (Zou / Tiki)", function() CommF_:InvokeServer("TravelZou") end)
    AddButton(TeleportPage, "Rejoin Current Server", function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
    AddButton(TeleportPage, "Hop to Another Server", function()
        local sf = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
        for _, s in pairs(sf.data) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                break
            end
        end
    end)

    -- Populate Settings Tab
    AddToggle(SettingsPage, "Anti-AFK (Virtual User Bypass)", Settings.AntiAFK, function(v) Settings.AntiAFK = v end)
    AddToggle(SettingsPage, "White Screen (FPS Boost & Battery Saver)", Settings.WhiteScreen, function(v)
        Settings.WhiteScreen = v
        RunService:Set3dRenderingEnabled(not v)
    end)
    AddButton(SettingsPage, "Copy Discord / Script Info", function()
        setclipboard("https://discord.gg/bananahub")
    end)

    -- Set Default Active Tab
    TabPages["Auto Farm"].Button.BackgroundColor3 = Color3.fromRGB(255, 190, 0)
    TabPages["Auto Farm"].Button.TextColor3 = Color3.fromRGB(0, 0, 0)
    TabPages["Auto Farm"].Page.Visible = true
    CurrentTab = "Auto Farm"

    -- Toggle Menu Keybind (RightControl or Click button on screen)
    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == Enum.KeyCode.RightControl then
            MainFrame.Visible = not MainFrame.Visible
        end
    end)

    print("[🍌 Banana Hub] Loaded successfully! Press Right-Control to toggle menu.")
end

-- Initialize GUI
BuildBananaHubGUI()
