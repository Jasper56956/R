-- ==========================================================
-- ⚙️ WAYPOINT SYSTEM MODULE (NO UI)
-- ==========================================================
local WaypointModule = {}

-- Services
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

-- Config
local FileName = "SavedPositions_" .. game.PlaceId .. ".json"
local DefaultWaypoints = {
    ["Spawn"] = {x = 0, y = 50, z = 0},
    ["Shop Zone"] = {x = -158.2, y = 27.3, z = 114},
    ["Safe Zone"] = {x = -192, y = 29.6, z = 162.1},
}

-- Variables
WaypointModule.Waypoints = {}
local tpConnection, noclipConnection

-- 💾 Internal: Save Function
local function SaveFile()
    writefile(FileName, HttpService:JSONEncode(WaypointModule.Waypoints))
end

-- 📂 Public: Load Data (Merge Default + Saved)
function WaypointModule.LoadData()
    -- 1. Load Defaults
    WaypointModule.Waypoints = table.clone(DefaultWaypoints)
    
    -- 2. Load File if exists
    if isfile(FileName) then
        local success, result = pcall(function()
            return HttpService:JSONDecode(readfile(FileName))
        end)
        if success and result then
            for name, pos in pairs(result) do
                WaypointModule.Waypoints[name] = pos
            end
        end
    end
    SaveFile() -- Update file structure
end

-- ➕ Public: Add Current Location
function WaypointModule.AddLocation(name)
    local Char = Player.Character
    if Char and Char:FindFirstChild("HumanoidRootPart") and name ~= "" then
        local pos = Char.HumanoidRootPart.Position
        WaypointModule.Waypoints[name] = {x = pos.X, y = pos.Y, z = pos.Z}
        SaveFile()
        return true -- Success
    end
    return false -- Failed
end

-- ❌ Public: Remove Location
function WaypointModule.RemoveLocation(name)
    if WaypointModule.Waypoints[name] then
        WaypointModule.Waypoints[name] = nil
        SaveFile()
        return true
    end
    return false
end

-- 📜 Public: Get Name List (Sorted)
function WaypointModule.GetList()
    local list = {}
    for name, _ in pairs(WaypointModule.Waypoints) do
        table.insert(list, name)
    end
    table.sort(list)
    return list
end

-- 🛑 Public: Stop Teleport
function WaypointModule.StopTeleport()
    if tpConnection then tpConnection:Disconnect() tpConnection = nil end
    if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
    
    local Char = Player.Character
    if Char then
        local Root = Char:FindFirstChild("HumanoidRootPart")
        local Hum = Char:FindFirstChild("Humanoid")
        
        if Root then
            Root.Velocity = Vector3.zero
            Root.AssemblyLinearVelocity = Vector3.zero
        end
        
        if Hum then
            Hum.PlatformStand = false 
            Hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
        
        task.wait()
        for _, v in pairs(Char:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = true end
        end
    end
end

-- ✈️ Public: Teleport Logic
function WaypointModule.TeleportTo(name)
    local targetData = WaypointModule.Waypoints[name]
    if not targetData then return false end
    
    WaypointModule.StopTeleport() -- Reset before start
    
    local Char = Player.Character
    if not Char then return end
    local Root = Char:FindFirstChild("HumanoidRootPart")
    local Hum = Char:FindFirstChild("Humanoid")
    if not Root or not Hum then return end
    
    local dest = Vector3.new(targetData.x, targetData.y, targetData.z)
    local Speed = 60 
    
    Hum.PlatformStand = true 
    
    noclipConnection = RunService.Stepped:Connect(function()
        if Char then
            for _, v in pairs(Char:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end
    end)
    
    tpConnection = RunService.Heartbeat:Connect(function(dt)
        if not Char or not Root or not Char.Parent then 
            WaypointModule.StopTeleport()
            return 
        end
        
        local currentPos = Root.Position
        local dist = (dest - currentPos).Magnitude
        
        if dist < 3 then
            WaypointModule.StopTeleport()
            -- You can add a callback or notification event here if needed
            return
        end
        
        local dir = (dest - currentPos).Unit
        Root.CFrame = CFrame.new(currentPos + (dir * Speed * dt))
        Root.CFrame = CFrame.lookAt(Root.Position, dest)
        Root.Velocity = Vector3.zero
        Root.AssemblyLinearVelocity = Vector3.zero
    end)
    
    return true
end

-- Init Load
WaypointModule.LoadData()

return WaypointModule
