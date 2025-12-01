local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Universal Waypoints System",
   LoadingTitle = "Waypoints Manager",
   LoadingSubtitle = "By Gemini",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "MyWaypoints",
      FileName = "SavedPositions_" .. game.PlaceId
   },
   KeySystem = false,
})

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

-- 📁 ตัวแปรเก็บข้อมูล (ใช้ระบบ Save ของ Rayfield หรือไฟล์แยกก็ได้)
-- ในที่นี้ใช้ไฟล์แยกเพื่อความชัวร์เหมือนเดิม
local FileName = "SavedPositions_" .. game.PlaceId .. ".json"
local Waypoints = {}

-- 📂 ฟังก์ชันโหลดและบันทึกไฟล์
local function LoadWaypoints()
    if isfile(FileName) then
        local content = readfile(FileName)
        local decoded = HttpService:JSONDecode(content)
        Waypoints = decoded or {}
    else
        Waypoints = {}
    end
end

local function SaveWaypoints()
    writefile(FileName, HttpService:JSONEncode(Waypoints))
end

LoadWaypoints()

-- ✈️ ฟังก์ชันวาร์ป (Safe TP)
local tpConnection
local function SafeTeleport(targetPos)
    if tpConnection then tpConnection:Disconnect() tpConnection = nil end
    
    local Char = Player.Character
    if not Char then return end
    local Root = Char:FindFirstChild("HumanoidRootPart")
    if not Root then return end
    
    local dest = Vector3.new(targetPos.x, targetPos.y, targetPos.z)
    local Speed = 60 
    
    tpConnection = RunService.Heartbeat:Connect(function(dt)
        if not Char or not Root or not Char.Parent then 
            if tpConnection then tpConnection:Disconnect() end
            return 
        end
        
        local currentPos = Root.Position
        local dist = (dest - currentPos).Magnitude
        
        if dist < 3 then
            Root.Velocity = Vector3.zero
            if tpConnection then tpConnection:Disconnect() end
            Rayfield:Notify({Title = "Arrived", Content = "Reached destination!", Duration = 3, Image = 4483345998})
            return
        end
        
        local dir = (dest - currentPos).Unit
        Root.CFrame = CFrame.new(currentPos + (dir * Speed * dt))
        Root.CFrame = CFrame.lookAt(Root.Position, dest)
        Root.Velocity = Vector3.zero
        Root.AssemblyLinearVelocity = Vector3.zero
        
        for _, v in pairs(Char:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end)
end

-- 🖥️ สร้างหน้าจอ UI
local Tab = Window:CreateTab("Locations", 4483345998)
local Section = Tab:CreateSection("Manage Waypoints")

local currentName = ""
local selectedWP = nil
local dropdownList = {}

-- อัปเดตรายชื่อใน Dropdown
local function GetDropdownList()
    local list = {}
    for name, _ in pairs(Waypoints) do
        table.insert(list, name)
    end
    return list
end

local NameInput = Tab:CreateInput({
   Name = "Location Name",
   PlaceholderText = "Enter name here...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      currentName = Text
   end,
})

Tab:CreateButton({
   Name = "Save Current Position 💾",
   Callback = function()
        local Char = Player.Character
        if Char and Char:FindFirstChild("HumanoidRootPart") and currentName ~= "" then
            local pos = Char.HumanoidRootPart.Position
            Waypoints[currentName] = {x = pos.X, y = pos.Y, z = pos.Z}
            SaveWaypoints()
            Rayfield:Notify({Title = "Saved", Content = "Saved: " .. currentName, Duration = 3})
            
            -- แจ้งเตือนให้รีเฟรช (Rayfield อัปเดต Dropdown อัตโนมัติยากนิดนึง ต้องสร้างใหม่หรือใช้ Refresh function)
        else
            Rayfield:Notify({Title = "Error", Content = "Please enter a name first!", Duration = 3})
        end
   end,
})

local SelectDropdown -- ประกาศตัวแปรไว้ก่อน

-- ฟังก์ชันสร้าง/รีเฟรช Dropdown
local function RefreshDropdown()
    -- Rayfield รุ่นใหม่ใช้ :Refresh() ได้
    if SelectDropdown then
        SelectDropdown:Refresh(GetDropdownList())
    end
end

Section = Tab:CreateSection("Teleport Controls")

Tab:CreateButton({
   Name = "🔄 Refresh List (Click after Save/Delete)",
   Callback = function()
        RefreshDropdown()
   end,
})

SelectDropdown = Tab:CreateDropdown({
   Name = "Select Location",
   Options = GetDropdownList(),
   CurrentOption = "",
   MultipleOptions = false,
   Flag = "DropdownWP", 
   Callback = function(Option)
        -- Rayfield ส่งคืนเป็น Table { "Name" }
        selectedWP = Option[1]
   end,
})

Tab:CreateButton({
   Name = "✈️ Teleport (Fly)",
   Callback = function()
        if selectedWP and Waypoints[selectedWP] then
            SafeTeleport(Waypoints[selectedWP])
        else
            Rayfield:Notify({Title = "Error", Content = "Select a location first!", Duration = 3})
        end
   end,
})

Tab:CreateButton({
   Name = "❌ Delete Selected",
   Callback = function()
        if selectedWP and Waypoints[selectedWP] then
            Waypoints[selectedWP] = nil
            SaveWaypoints()
            Rayfield:Notify({Title = "Deleted", Content = "Deleted " .. selectedWP, Duration = 3})
            selectedWP = nil
            RefreshDropdown()
        end
   end,
})

Rayfield:LoadConfiguration()