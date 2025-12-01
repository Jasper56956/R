-- ================= AUTO FARM MINING (LOCK & FULL CLEANUP) =================
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local Char = Player.Character or Player.CharacterAdded:Wait()

-- ⚙️ ตั้งค่า
local cfg = {
    key = Enum.KeyCode.V,
    
    -- 🎯 การตั้งค่าแร่
    orePath = "Rocks",
    oreName = "Pebble",
    
    -- 🔧 ระบบหาเครื่องมืออัตโนมัติ
    toolKeywords = {"Pickaxe"},
    autoFindTool = true,
    
    -- ⚡ การตั้งค่าความเร็ว
    hitDelay = 0.1,
    flySpeed = 60,
    mineDistance = 5,
    nextOreDelay = 0.1,
}

getgenv().running = false
local flyConnection, noclipConnection, inputConnection, charConnection
local bodyVelocity, bodyGyro
local currentTool = nil

-- Remote
local remote = RS.Shared.Packages.Knit.Services.ToolService.RF.ToolActivated

-- ฟังก์ชันสั้น
local function notify(txt)
    game.StarterGui:SetCore("SendNotification", {Title = "AutoFarm", Text = txt, Duration = 3})
end

local function mine()
    if currentTool then
        task.spawn(function() pcall(function() remote:InvokeServer(currentTool.Name) end) end)
    end
end

-- ฟังก์ชันหาเครื่องมืออัตโนมัติ
local function findTool()
    local backpack = Player.Backpack
    local character = Player.Character
    
    if character then
        for _, item in pairs(character:GetChildren()) do
            if item:IsA("Tool") then
                return item
            end
        end
    end
    
    if cfg.autoFindTool then
        for _, keyword in pairs(cfg.toolKeywords) do
            for _, tool in pairs(backpack:GetChildren()) do
                if tool:IsA("Tool") and string.find(string.lower(tool.Name), string.lower(keyword)) then
                    return tool
                end
            end
        end
        
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                return tool
            end
        end
    end
    
    return nil
end

local function equip()
    if not currentTool or currentTool.Parent ~= Char then
        currentTool = findTool()
        
        if currentTool then
            if currentTool.Parent == Player.Backpack then
                Char.Humanoid:EquipTool(currentTool)
                notify("Equipped: " .. currentTool.Name)
            end
        else
            notify("No tool found!")
        end
    end
end

local function getOreHP(ore)
    if ore:FindFirstChild("Health") then
        return ore.Health.Value or 0
    elseif ore:FindFirstChild("HP") then
        return ore.HP.Value or 0
    elseif ore:FindFirstChild("Health") and ore.Health:IsA("NumberValue") then
        return ore.Health.Value or 0
    elseif ore:FindFirstChild("Hitpoints") then
        return ore.Hitpoints.Value or 0
    end
    
    return 1
end

local function enableNoclip()
    if noclipConnection then return end
    
    noclipConnection = RunService.Stepped:Connect(function()
        if not Char then return end
        
        for _, part in pairs(Char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end

local function disableNoclip()
    if noclipConnection then 
        noclipConnection:Disconnect() 
        noclipConnection = nil
    end
    
    if Char then
        for _, part in pairs(Char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

local function stopFly()
    if flyConnection then 
        flyConnection:Disconnect() 
        flyConnection = nil
    end
    
    if bodyVelocity then 
        bodyVelocity:Destroy() 
        bodyVelocity = nil
    end
    
    if bodyGyro then 
        bodyGyro:Destroy() 
        bodyGyro = nil
    end
    
    disableNoclip()
    
    if Char and Char:FindFirstChild("HumanoidRootPart") then
        local root = Char.HumanoidRootPart
        local hum = Char:FindFirstChild("Humanoid")
        
        root.Anchored = false
        root.Velocity = Vector3.new(0, 0, 0)
        
        if hum then
            hum.PlatformStand = false
        end
    end
end

-- 🔥 ฟังก์ชัน CLEANUP ทั้งหมด
local function fullCleanup()
    getgenv().running = false
    
    -- ลบ connections ทั้งหมด
    if flyConnection then 
        flyConnection:Disconnect() 
        flyConnection = nil
    end
    
    if noclipConnection then 
        noclipConnection:Disconnect() 
        noclipConnection = nil
    end
    
    if inputConnection then
        inputConnection:Disconnect()
        inputConnection = nil
    end
    
    if charConnection then
        charConnection:Disconnect()
        charConnection = nil
    end
    
    -- ลบ body objects
    if bodyVelocity then 
        bodyVelocity:Destroy() 
        bodyVelocity = nil
    end
    
    if bodyGyro then 
        bodyGyro:Destroy() 
        bodyGyro = nil
    end
    
    -- รีเซ็ตตัวละคร
    if Char and Char:FindFirstChild("HumanoidRootPart") then
        local root = Char.HumanoidRootPart
        local hum = Char:FindFirstChild("Humanoid")
        
        root.Anchored = false
        root.Velocity = Vector3.new(0, 0, 0)
        root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        
        -- เปิด collision กลับ
        for _, part in pairs(Char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
        
        if hum then 
            hum.PlatformStand = false
            hum:MoveTo(root.Position)
        end
    end
    
    currentTool = nil
    
    notify("Script Stopped & Cleaned!")
end

local function flyTo(target)
    if not Char or not Char:FindFirstChild("HumanoidRootPart") then return false end
    
    local root = Char.HumanoidRootPart
    local hum = Char:FindFirstChild("Humanoid")
    local targetPos = target.Position
    
    if hum then
        hum.PlatformStand = true
    end
    
    enableNoclip()
    
    if not bodyVelocity then
        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bodyVelocity.Parent = root
    end
    
    if not bodyGyro then
        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bodyGyro.P = 9e4
        bodyGyro.Parent = root
    end
    
    local reached = false
    local startTime = tick()
    
    flyConnection = RunService.Heartbeat:Connect(function()
        if not getgenv().running or not Char or not root then
            stopFly()
            return
        end
        
        local direction = (targetPos - root.Position).Unit
        local distance = (targetPos - root.Position).Magnitude
        
        if distance < cfg.mineDistance then
            reached = true
            stopFly()
            return
        end
        
        if tick() - startTime > 15 then
            stopFly()
            return
        end
        
        bodyVelocity.Velocity = direction * cfg.flySpeed
        bodyGyro.CFrame = CFrame.lookAt(root.Position, targetPos)
        root.Velocity = direction * cfg.flySpeed
    end)
    
    while getgenv().running and not reached and flyConnection do
        task.wait(0.1)
    end
    
    stopFly()
    return reached
end

local function findOre()
    local closest, minDist = nil, math.huge
    local myPos = Char.HumanoidRootPart.Position
    
    for _, ore in pairs(workspace[cfg.orePath]:GetDescendants()) do
        if ore:IsA("Model") and ore.Name == cfg.oreName then
            local part = ore.PrimaryPart or ore:FindFirstChildWhichIsA("BasePart")
            if part then
                local dist = (part.Position - myPos).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = ore
                end
            end
        end
    end
    
    return closest
end

-- 🔒 ฟังก์ชันล็อคและหันหน้าไปหากองแร่
local function lockAndFaceOre(orePart)
    if not Char or not Char:FindFirstChild("HumanoidRootPart") then return end
    
    local root = Char.HumanoidRootPart
    local hum = Char:FindFirstChild("Humanoid")
    
    -- ปิด PlatformStand และล็อคตัวละคร
    if hum then
        hum.PlatformStand = false
    end
    
    -- ล็อคตำแหน่งและหันหน้า
    root.Anchored = true
    root.CFrame = CFrame.new(root.Position, orePart.Position)
    
    task.wait(0.05)
    root.Anchored = false
end

local function start()
    currentTool = findTool()
    
    if currentTool then
        notify("Auto Tool: " .. currentTool.Name)
    else
        notify("No tool found! Add keywords in config")
        fullCleanup()
        return
    end
    
    notify("Farming " .. cfg.oreName .. "...")
    
    while getgenv().running do
        pcall(function()
            Char = Player.Character
            if not Char or not Char:FindFirstChild("HumanoidRootPart") then return end
            
            local ore = findOre()
            
            if ore then
                local part = ore.PrimaryPart or ore:FindFirstChildWhichIsA("BasePart")
                
                flyTo(part)
                
                if getgenv().running then
                    stopFly()
                    
                    -- 🔒 ล็อคและหันหน้าไปหากองแร่
                    lockAndFaceOre(part)
                    
                    -- ใส่เครื่องมืออัตโนมัติ
                    equip()
                    task.wait(0.1)
                    
                    while getgenv().running do
                        if not ore.Parent then
                            break
                        end
                        
                        local hp = getOreHP(ore)
                        if hp <= 0 then
                            break
                        end
                        
                        if not currentTool or currentTool.Parent ~= Char then
                            equip()
                            task.wait(0.2)
                        end
                        
                        mine()
                        task.wait(cfg.hitDelay)
                    end
                    
                    task.wait(cfg.nextOreDelay)
                end
            else
                task.wait(2)
            end
        end)
        task.wait(0.1)
    end
    
    fullCleanup()
end

-- ควบคุม
inputConnection = UIS.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == cfg.key then
        getgenv().running = not getgenv().running
        if getgenv().running then
            task.spawn(start)
        else
            fullCleanup()  -- 🔥 ลบทุกอย่างเมื่อกดหยุด
        end
    end
end)

charConnection = Player.CharacterAdded:Connect(function(newChar)
    Char = newChar
    currentTool = nil
    if getgenv().running then fullCleanup() end
end)

-- แสดงเครื่องมือที่หาเจอ
task.spawn(function()
    task.wait(1)
    local tool = findTool()
    if tool then
        notify("Tool Found: " .. tool.Name .. " | Press V")
    else
        notify("No tool found! Check backpack")
    end
end)