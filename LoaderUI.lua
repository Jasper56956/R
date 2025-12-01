-- โหลด UI Library (Rayfield)
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

--WaypointModule
local System = loadstring(game:HttpGet(""))() -- เปลี่ยนเป็น Link จริงของคุณ

-- สร้างหน้าต่าง UI
local Window = Rayfield:CreateWindow({
   Name = "Universal Waypoints (Modular Version)",
   LoadingTitle = "Waypoint Manager",
   LoadingSubtitle = "Powered by Module",
   ConfigurationSaving = { Enabled = false }, -- เราจัดการเซฟเองใน Module แล้ว
   KeySystem = false,
})

local Tab = Window:CreateTab("Locations", 4483345998)

-- Variables สำหรับ UI
local currentInputName = ""
local selectedLocation = nil
local DropdownElement -- เก็บตัวแปร Dropdown เพื่อไว้รีเฟรช

-- ฟังก์ชันช่วยรีเฟรช Dropdown
local function UpdateDropdown()
    if DropdownElement then
        DropdownElement:Refresh(System.GetList()) -- ดึงรายการจาก Module
    end
end

-- ส่วน: เพิ่มจุด
Tab:CreateSection("Manage Waypoints")

Tab:CreateInput({
   Name = "Location Name",
   PlaceholderText = "Enter name...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      currentInputName = Text
   end,
})

Tab:CreateButton({
   Name = "Save Current Position 💾",
   Callback = function()
       -- เรียกใช้ Module: AddLocation
       local success = System.AddLocation(currentInputName)
       
       if success then
           Rayfield:Notify({Title = "Success", Content = "Saved: " .. currentInputName, Duration = 3})
           UpdateDropdown() -- อัปเดตลิสต์ทันที
       else
           Rayfield:Notify({Title = "Error", Content = "Invalid name or character missing", Duration = 3})
       end
   end,
})

-- ส่วน: ควบคุมการวาร์ป
Tab:CreateSection("Teleport Controls")

DropdownElement = Tab:CreateDropdown({
   Name = "Select Location",
   Options = System.GetList(), -- ดึงรายการครั้งแรก
   CurrentOption = "",
   MultipleOptions = false,
   Callback = function(Option)
       selectedLocation = Option[1]
   end,
})

Tab:CreateButton({
   Name = "🔄 Refresh List",
   Callback = function()
       UpdateDropdown()
       Rayfield:Notify({Title = "Refreshed", Content = "List updated", Duration = 2})
   end,
})

Tab:CreateButton({
   Name = "✈️ Teleport",
   Callback = function()
       -- เรียกใช้ Module: TeleportTo
       if selectedLocation then
           System.TeleportTo(selectedLocation)
           Rayfield:Notify({Title = "Traveling", Content = "Going to " .. selectedLocation, Duration = 3})
       else
           Rayfield:Notify({Title = "Error", Content = "Please select a location", Duration = 3})
       end
   end,
})

Tab:CreateButton({
   Name = "❌ Delete Selected",
   Callback = function()
       -- เรียกใช้ Module: RemoveLocation
       if selectedLocation then
           local success = System.RemoveLocation(selectedLocation)
           if success then
               Rayfield:Notify({Title = "Deleted", Content = "Removed " .. selectedLocation, Duration = 3})
               selectedLocation = nil
               UpdateDropdown()
           end
       end
   end,
})


