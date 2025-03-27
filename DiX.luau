local Colors = {
	Primary = Color3.new(1, 1, 1),
	Secondary = Color3.new(0.596078, 0.596078, 0.596078),
	Hover = Color3.new(0.364706, 0.556863, 1),
	Selected = Color3.new(0.52549, 0.729412, 1),
	Text = Color3.new(0, 0, 0),
}

local BindTracker = {
	AdjustProportions = false,
	MultiSelect = false,
	Interact3D = false,
	DirectInteract = false,
}

local function downloadstring(URL: string)
	return loadstring(game:HttpGet(URL, true))()
end

local User = game:GetService("Players").LocalPlayer
local UIS = game:GetService("UserInputService")
local Mouse = User:GetMouse()
local RunService = game:GetService("RunService")
local StudioMode = RunService:IsStudio()
local Recipient = StudioMode and User:WaitForChild("PlayerGui") or game.CoreGui

local NewV2 = Vector2.new
local NewV3 = Vector3.new
local NewInstance = Instance.new

local Spritesheet = "rbxasset://textures/ClassImages.png"
local Repo = "https://raw.githubusercontent.com/DoctorBloxxa/DiX/canary/"

local InstanceIcons = StudioMode and require(script:WaitForChild("Spritesheet")) or downloadstring(Repo .. "Modules/Spritesheet.luau")
local Utils = StudioMode and require(script:WaitForChild("Utils")) or downloadstring(Repo .. "Modules/Utils.luau")
local Almanac = StudioMode and require(script:WaitForChild("Almanac")) or downloadstring(Repo .. "Modules/Almanac.luau")
local Quartermaster = Utils:watchdog(1 / 60, wait)

local function GetInstanceIcon(ClassName: string)
	return Vector2.new(16, 0) * (InstanceIcons[ClassName] or 0)
end

local ExplorerInstance, ExplorerBody, SearchBox, InstanceFrame, PropertyFrame
local GestureHandle, EnableHandle, DisableHandle
local Hover3DHandle, Hover3DBox
local BrowserProportion = 0.65
local Selections3D = {}
local RegisteredInstances = {}
local RegisteredInstancesEvents = {
	ChildAdded = {},
	ChildRemoved = {},
}

local function CreateBox()
	local Box = Instance.new("SelectionBox")
	Box.Parent = Recipient
	Box.Color3 = Color3.fromRGB(178, 229, 255)
	Box.LineThickness = 0.025
	return Box
end

local function Hover3D() -- I can't use interrupts for when Mouse.Target changes so instead we use this bullcrap
	Hover3DBox.Adornee = Mouse.Target and (BindTracker.DirectInteract and Mouse.Target or Utils:GetRootClass(Mouse.Target, "Model", false)) or nil
end

local function Select() end

local function AdjustExplorer()
	BrowserProportion = Mouse.Y / ExplorerBody.AbsoluteSize.Y
	BrowserProportion = math.clamp(BrowserProportion, 0.045, 1)

	InstanceFrame.Size = UDim2.new(1, 0, BrowserProportion, -32)
	PropertyFrame.Size = UDim2.new(1, 0, 1 - BrowserProportion, 0)
end

local function ExplorerGestures(Input: InputObject, GUIHook: boolean)
	if Input.UserInputType == Enum.UserInputType.MouseMovement and BindTracker.AdjustProportions then
		AdjustExplorer()
	end
end

local function ExplorerEnable(Input: InputObject, GUIHook: boolean)
	if Input.UserInputType == Enum.UserInputType.MouseButton3 then
		if BindTracker.MultiSelect and Input.UserInputState == Enum.UserInputState.Begin then
			BindTracker.Interact3D = not BindTracker.Interact3D

			warn(BindTracker.Interact3D)

			if BindTracker.Interact3D then
				Hover3DHandle = RunService.PreRender:Connect(Hover3D)
				Hover3DBox = CreateBox()
			else
				Hover3DHandle:Disconnect()
				Hover3DBox:Remove()
			end
		else
			BindTracker.AdjustProportions = Input.UserInputState == Enum.UserInputState.Begin

			if BindTracker.AdjustProportions then
				AdjustExplorer()
			end
		end
	elseif Input.UserInputType == Enum.UserInputType.Keyboard then
		if Input.KeyCode == Enum.KeyCode.LeftControl then
			BindTracker.MultiSelect = Input.UserInputState == Enum.UserInputState.Begin
		elseif Input.KeyCode == Enum.KeyCode.LeftAlt and Input.UserInputState == Enum.UserInputState.Begin then
			BindTracker.DirectInteract = not BindTracker.DirectInteract
		end
	end
end

local function ExplorerDisable(Input: InputObject, GUIHook: boolean) end

local function RegisterInstance(Object: Instance, Container: Instance)
	local Opened = false
	local Children = {}

	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.new(1, 0, 0, 16)
	Frame.AutomaticSize = Enum.AutomaticSize.XY
	Frame.BackgroundColor3 = Colors.Primary
	Frame.Parent = Container or InstanceFrame

	local Dropdown = Instance.new("ImageButton")
	Dropdown.Size = UDim2.fromOffset(8, 8)
	Dropdown.AnchorPoint = NewV2(0.5, 0.5)
	Dropdown.Position = UDim2.fromOffset(8, 8)
	Dropdown.Image = "rbxasset://textures/ui/dropdown_arrow@2x.png"
	Dropdown.BorderSizePixel = 0
	Dropdown.BackgroundTransparency = 1
	Dropdown.ScaleType = Enum.ScaleType.Fit
	Dropdown.ImageColor3 = Colors.Text
	Dropdown.Rotation = -90
	Dropdown.Parent = Frame

	local Icon = Instance.new("ImageLabel")
	Icon.Size = UDim2.fromOffset(16, 16)
	Icon.Position = UDim2.fromOffset(16, 0)
	Icon.ImageRectSize = NewV2(16, 16)
	Icon.ImageRectOffset = GetInstanceIcon(Object.ClassName)
	Icon.Image = Spritesheet
	Icon.BorderSizePixel = 0
	Icon.BackgroundTransparency = 1
	Icon.Parent = Frame

	local Name = Instance.new("TextLabel")
	Name.Size = UDim2.new(1, -32, 0, 16)
	Name.Position = UDim2.fromOffset(16, 0)
	Name.Text = Object.Name
	Name.TextSize = 8
	Name.AutomaticSize = Enum.AutomaticSize.X
	Name.BorderSizePixel = 0
	Name.BackgroundTransparency = 1
	Name.TextColor3 = Colors.Text
	Name.Parent = Frame

	local Box = Instance.new("Frame")
	Box.Size = UDim2.new(1, -16, 0, 0)
	Box.Position = UDim2.fromOffset(16, 16)
	Box.AutomaticSize = Enum.AutomaticSize.XY
	Box.BorderSizePixel = 0
	Box.BackgroundTransparency = 1
	Box.Parent = Frame

	RegisteredInstances[Object] = Box
	Instance.new("UIListLayout").Parent = Box

	Dropdown.MouseButton1Click:Connect(function()
		if RegisteredInstancesEvents.ChildAdded[Object] then
			CloseInstance(Object)
			Dropdown.Rotation = -90
		else
			OpenInstance(Object)
			Dropdown.Rotation = 0
		end
	end)

	Frame.MouseEnter:Connect(function()
		Frame.BackgroundColor3 = Frame.BackgroundColor3:Lerp(Colors.Hover, 0.5)
	end)

	Frame.MouseLeave:Connect(function()
		Frame.BackgroundColor3 = Colors.Primary
	end)
end

local function UnregisterInstance(Object: Instance, Container: Instance)
	if RegisteredInstances[Object] then
	else
		return
	end

	CloseInstance(Object)

	RegisteredInstances[Object].Parent:Remove()
	RegisteredInstances[Object] = nil
end

function CloseInstance(Object: Instance)
	if RegisteredInstances[Object] then
	else
		return
	end

	if RegisteredInstancesEvents.ChildAdded[Object] then
		RegisteredInstancesEvents.ChildAdded[Object]:Disconnect()
		RegisteredInstancesEvents.ChildRemoved[Object]:Disconnect()

		RegisteredInstancesEvents.ChildAdded[Object] = nil
		RegisteredInstancesEvents.ChildRemoved[Object] = nil
	end

	for _, Child in pairs(Object:GetChildren()) do
		UnregisterInstance(Child)
	end
end

function OpenInstance(Object: Instance)
	if RegisteredInstances[Object] then
	else
		return
	end

	local Handle = RegisteredInstances[Object]

	Quartermaster:Reset()
	for _, Child in pairs(Object:GetChildren()) do
		RegisterInstance(Child, Handle)
		Quartermaster:Tick()
	end

	RegisteredInstancesEvents.ChildAdded[Object] = Object.ChildAdded:Connect(function(Child)
		RegisterInstance(Child, Handle)
	end)
	RegisteredInstancesEvents.ChildRemoved[Object] = Object.ChildRemoved:Connect(function(Child)
		UnregisterInstance(Child)
	end)
end

local function CreateExplorer(Root: Instance)
	ExplorerInstance = NewInstance("ScreenGui")
	ExplorerInstance.Name = "FoundationOverlay"
	ExplorerInstance.Parent = Recipient

	ExplorerBody = NewInstance("Frame")
	ExplorerBody.AnchorPoint = NewV2(1, 0)
	ExplorerBody.Size = UDim2.fromScale(0.5, 1)
	ExplorerBody.Position = UDim2.fromScale(1, 0)
	ExplorerBody.SizeConstraint = Enum.SizeConstraint.RelativeYY
	ExplorerBody.Parent = ExplorerInstance
	ExplorerBody.BackgroundColor3 = Colors.Primary

	SearchBox = NewInstance("TextBox")
	SearchBox.AnchorPoint = NewV2(1, 0)
	SearchBox.Size = UDim2.new(0.5, 0, 0, 32)
	SearchBox.Position = UDim2.fromScale(1, 0)
	SearchBox.Parent = ExplorerBody
	SearchBox.BackgroundColor3 = Colors.Primary

	InstanceFrame = NewInstance("ScrollingFrame")
	InstanceFrame.AnchorPoint = NewV2(1, 0)
	InstanceFrame.Size = UDim2.new(1, 0, BrowserProportion, -32)
	InstanceFrame.Position = UDim2.new(1, 0, 0, 32)
	InstanceFrame.Parent = ExplorerBody
	InstanceFrame.AutomaticCanvasSize = Enum.AutomaticSize.XY
	InstanceFrame.CanvasSize = UDim2.new()

	PropertyFrame = NewInstance("ScrollingFrame")
	PropertyFrame.AnchorPoint = NewV2(1, 1)
	PropertyFrame.Size = UDim2.new(1, 0, 1 - BrowserProportion, 0)
	PropertyFrame.Position = UDim2.new(1, 0, 1, 0)
	PropertyFrame.Parent = ExplorerBody
	PropertyFrame.AutomaticCanvasSize = Enum.AutomaticSize.XY
	PropertyFrame.CanvasSize = UDim2.new()

	Instance.new("UIListLayout").Parent = InstanceFrame
	Instance.new("UIListLayout").Parent = PropertyFrame

	ExplorerBody.MouseEnter:Connect(function()
		GestureHandle = UIS.InputChanged:Connect(ExplorerGestures)
		EnableHandle = UIS.InputBegan:Connect(ExplorerEnable)
		DisableHandle = UIS.InputEnded:Connect(ExplorerEnable)
	end)

	ExplorerBody.MouseLeave:Connect(function()
		GestureHandle:Disconnect()
		EnableHandle:Disconnect()
		DisableHandle:Disconnect()

		BindTracker.AdjustProportions = false
		BindTracker.MultiSelect = false
	end)

	for _, Instance in pairs(Root:GetChildren()) do
		RegisterInstance(Instance)
	end
end

CreateExplorer(game)
