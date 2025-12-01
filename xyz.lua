local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local plr = Players.LocalPlayer

-- สร้าง UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = CoreGui -- ใส่ใน CoreGui เพื่อไม่ให้เกมลบออกง่ายๆ

local Label = Instance.new("TextLabel")
Label.Parent = ScreenGui
Label.Size = UDim2.new(0, 300, 0, 50)
Label.Position = UDim2.new(0.5, -150, 0, 50) -- อยู่ตรงกลางบน
Label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Label.BackgroundTransparency = 0.5
Label.TextColor3 = Color3.fromRGB(255, 255, 255)
Label.TextSize = 20

-- อัปเดตทุกเฟรม
RunService.RenderStepped:Connect(function()
    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
        local pos = plr.Character.HumanoidRootPart.Position
        -- ปัดเศษให้ดูง่าย
        Label.Text = string.format("X: %.1f | Y: %.1f | Z: %.1f", pos.X, pos.Y, pos.Z)
    else
        Label.Text = "Waiting for Character..."
    end
end)