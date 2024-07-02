local Colors = {
	Primary = Color3.new(0.917647, 0.917647, 0.917647),
	Secondary = Color3.new(0.596078, 0.596078, 0.596078),
	Hover = Color3.new(0.364706, 0.556863, 1),
	Selected = Color3.new(0.52549, 0.729412, 1),
	Text = Color3.new(0, 0, 0),
}

local function downloadstring(URL: string)
	return loadstring(game:HttpGet(URL, true))()
end

local User = game:GetService("Players").LocalPlayer
local Mouse = User:GetMouse()
local RunService = game:GetService("RunService")
local StudioMode = RunService:IsStudio()

local NewV2 = Vector2.new
local NewV3 = Vector3.new

local Spritesheet = "rbxasset://textures/ClassImages.png"
local Repo = "https://raw.githubusercontent.com/DoctorBloxxa/DiX/canary/"

local InstanceIcons = StudioMode and require(script:WaitForChild("Spritesheet")) or downloadstring(Repo + "Modules/Spritesheet.luau")
local Utils = StudioMode and require(script:WaitForChild("Utils")) or downloadstring(Repo + "Modules/Utils.luau")
local Almanac = StudioMode and require(script:WaitForChild("Almanac")) or downloadstring(Repo + "Modules/Almanac.luau")
local Quartermaster = Utils:watchdog(1/240, RunService.RenderStepped.Wait)

local function GetInstanceIcon(ClassName: string)
	return Vector2.new(16, 0) * (InstanceIcons[ClassName] or 0)
end
