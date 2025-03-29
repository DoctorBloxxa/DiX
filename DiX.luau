local Colors = {
	Primary = Color3.new(1, 1, 1),
	Secondary = Color3.new(0.596078, 0.596078, 0.596078),
	Hover = Color3.new(0.364706, 0.556863, 1),
	Hover3D = Color3.fromRGB(178, 229, 255),
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
local AlmanacData = StudioMode and require(script:WaitForChild("Almanac")) or downloadstring(Repo .. "Modules/Almanac.luau")
local Quartermaster = Utils:watchdog(1/24, wait)

local function GetInstanceIcon(ClassName: string)
	return Vector2.new(16, 0) * (InstanceIcons[ClassName] or 0)
end

local ExplorerInstance, ExplorerBody, SearchBox, FilterBox, InstanceFrame, PropertyFrame
local GestureHandle, EnableHandle, DisableHandle
local Hover3DHandle, Click3DHandle, Hover3DBox
local BrowserProportion = 0.65
local Selections = {}
local SelectionCount = 0
local LoadedPropertyCategories = {}
local RegisteredInstances = {}
local RegisteredInstancesEvents = {
	ChildAdded = {},
	ChildRemoved = {},
	NameChanged = {},
}
local CannotSelect = false
local Interrupt = NewInstance("BindableEvent")
InterruptOut = nil
local SelectingProperty = false

local function CreateBox(IsSelection: boolean)
	local Box = NewInstance("SelectionBox")
	Box.Parent = Recipient
	Box.Color3 = IsSelection and Colors.Selected or Colors.Hover3D
	Box.LineThickness = 0.025
	return Box
end

local function Hover3D() -- I can't use interrupts for when Mouse.Target changes so instead we use this bullcrap
	Hover3DBox.Adornee = not CannotSelect and Mouse.Target and (BindTracker.DirectInteract and Mouse.Target or Utils:GetRootClass(Mouse.Target, "Model", false)) or nil
end

local function Click3D()
	if Hover3DBox.Adornee and not CannotSelect then
		if not BindTracker.MultiSelect then
			Unselect()
		end
		Select(Hover3DBox.Adornee, true)
	end
end

Interrupt.Event:Connect(function(Type, ...)
	local Data = { ... }
	if Type == "Selection" then
		InterruptOut = Data[1]
	end
end)

function Unselect(Instance: Instance)
	if Instance ~= nil then
		if not Selections[Instance] then
			return
		end

		Selections[Instance]:Remove()
		Selections[Instance] = nil

		if RegisteredInstances[Instance] then
			RegisteredInstances[Instance].Parent.BackgroundColor3 = Colors.Primary
		end

		SelectionCount -= 1
	else
		for Selection, _ in pairs(Selections) do
			Unselect(Selection)
		end
	end

	if SelectionCount == 0 then
		ClearProperties()
	end
end

function Select(Instance: Instance, Scroll: boolean, Basic: boolean)
	if Selections[Instance] then
		return
	end

	if SelectingProperty then
		Interrupt:Fire("Selection", Instance)
	end

	SelectionCount += 1

	if not Basic then
		local Ancestry = Utils:GetAncestry(Instance)
		table.remove(Ancestry, #Ancestry)

		for _, Branch in pairs(Ancestry) do
			OpenInstance(Branch)
		end
	end

	local Frame = RegisteredInstances[Instance].Parent

	Frame.BackgroundColor3 = Colors.Selected

	if Scroll then
		local Offset = NewV2(0, Frame.AbsolutePosition.Y - InstanceFrame.AbsolutePosition.Y)
		InstanceFrame.CanvasPosition += NewV2(0, Frame.AbsolutePosition.Y - InstanceFrame.AbsolutePosition.Y)
	end

	local Box = CreateBox()
	Box.Adornee = Instance
	Selections[Instance] = Box

	if SelectionCount == 1 then
		ClearProperties()
		LoadProperties(Instance)
	end

	Instance.Destroying:Connect(function()
		Unselect(Instance)
	end)
end

local function AdjustExplorer()
	BrowserProportion = Mouse.Y / ExplorerBody.AbsoluteSize.Y
	BrowserProportion = math.clamp(BrowserProportion, 0.045, 1)

	InstanceFrame.Size = UDim2.new(1, 0, BrowserProportion, -32)
	PropertyFrame.Size = UDim2.new(1, 0, 1 - BrowserProportion, -16)
	FilterBox.Position = UDim2.new(1, 0, BrowserProportion, 0)
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

			if BindTracker.Interact3D then
				Hover3DHandle = RunService.PreRender:Connect(Hover3D)
				Click3DHandle = Mouse.Button1Down:Connect(Click3D)
				Hover3DBox = CreateBox()
			else
				Hover3DHandle:Disconnect()
				Click3DHandle:Disconnect()
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

local function RegisterInstance(Object: Instance, Container: Instance, Basic: boolean)
	if RegisteredInstances[Object] then
		return
	end

	local Children = {}
	local Opened = Basic

	local Frame = NewInstance("Frame")
	Frame.Size = UDim2.new(1, 0, 0, 16)
	Frame.AutomaticSize = Enum.AutomaticSize.XY
	Frame.BackgroundColor3 = Selections[Object] and Colors.Selected or Colors.Primary
	Frame.Parent = Container or InstanceFrame

	local DropdownIcon = NewInstance("ImageLabel")
	DropdownIcon.Size = UDim2.fromOffset(8, 8)
	DropdownIcon.AnchorPoint = NewV2(0.5, 0.5)
	DropdownIcon.Position = UDim2.fromOffset(8, 8)
	DropdownIcon.Image = "rbxasset://textures/ui/dropdown_arrow@2x.png"
	DropdownIcon.BorderSizePixel = 0
	DropdownIcon.BackgroundTransparency = 1
	DropdownIcon.ScaleType = Enum.ScaleType.Fit
	DropdownIcon.ImageColor3 = Colors.Text
	DropdownIcon.Rotation = Opened and 0 or -90
	DropdownIcon.Parent = Frame

	local Dropdown = NewInstance("TextButton")
	Dropdown.Size = UDim2.fromOffset(16, 16)
	Dropdown.BorderSizePixel = 0
	Dropdown.BackgroundTransparency = 1
	Dropdown.Text = ""
	Dropdown.Parent = Frame

	local Icon = NewInstance("ImageLabel")
	Icon.Size = UDim2.fromOffset(16, 16)
	Icon.Position = UDim2.fromOffset(16, 0)
	Icon.ImageRectSize = NewV2(16, 16)
	Icon.ImageRectOffset = GetInstanceIcon(Object.ClassName)
	Icon.Image = Spritesheet
	Icon.ResampleMode = Enum.ResamplerMode.Pixelated
	Icon.BorderSizePixel = 0
	Icon.BackgroundTransparency = 1
	Icon.Parent = Frame

	local Name = NewInstance("TextLabel")
	Name.Size = UDim2.new(1, -40, 0, 16)
	Name.Position = UDim2.fromOffset(40, 0)
	Name.Text = Object.Name
	Name.TextSize = 8
	Name.AutomaticSize = Enum.AutomaticSize.X
	Name.BorderSizePixel = 0
	Name.BackgroundTransparency = 1
	Name.TextColor3 = Colors.Text
	Name.TextXAlignment = Enum.TextXAlignment.Left
	Name.Parent = Frame

	local Box = NewInstance("Frame")
	Box.Size = UDim2.new(1, -16, 0, 0)
	Box.Position = UDim2.fromOffset(16, 16)
	Box.AutomaticSize = Enum.AutomaticSize.XY
	Box.BorderSizePixel = 0
	Box.BackgroundTransparency = 1
	Box.Parent = Frame

	local BodyClicker = NewInstance("TextButton")
	BodyClicker.Size = UDim2.new(1, -16, 0, 16)
	BodyClicker.Position = UDim2.fromOffset(16, 0)
	BodyClicker.BackgroundTransparency = 1
	BodyClicker.Text = ""
	BodyClicker.Parent = Frame

	RegisteredInstances[Object] = Box
	NewInstance("UIListLayout").Parent = Box
	if not Basic then
		Dropdown.MouseButton1Click:Connect(function()
			if RegisteredInstancesEvents.ChildAdded[Object] then
				CloseInstance(Object)
				DropdownIcon.Rotation = -90
			else
				OpenInstance(Object)
				DropdownIcon.Rotation = 0
			end
		end)
	else
		Dropdown.MouseButton1Click:Connect(function()
			if Opened then
				Box.Visible = false
				DropdownIcon.Rotation = -90
				Opened = false
			else
				Box.Visible = true
				DropdownIcon.Rotation = 0
				Opened = true
			end
		end)

		Object.Parent.ChildRemoved:Connect(function(Thing)
			if Thing == Object then
				UnregisterInstance(Object)
			end
		end)
	end
	Frame.MouseEnter:Connect(function()
		Frame.BackgroundColor3 = Colors.Hover:Lerp(Frame.BackgroundColor3, 0.75)
	end)

	Frame.MouseLeave:Connect(function()
		Frame.BackgroundColor3 = Selections[Object] and Colors.Selected or Colors.Primary
	end)

	BodyClicker.MouseButton1Down:Connect(function()
		if not Selections[Object] then
			if not BindTracker.MultiSelect then
				Unselect()
			end
			Select(Object, false, true)
		else
			Unselect(Object)
			Frame.BackgroundColor3 = Colors.Hover:Lerp(Frame.BackgroundColor3, 0.75)
		end
	end)

	RegisteredInstancesEvents.NameChanged[Object] = Object:GetPropertyChangedSignal("Name"):Connect(function()
		Name.Text = Object.Name
	end)
end

function UnregisterInstance(Object: Instance, IsDeleted: boolean)
	if RegisteredInstances[Object] then
	else
		return
	end

	if IsDeleted then
		Unselect(Object)
	end

	CloseInstance(Object)

	RegisteredInstancesEvents.NameChanged[Object]:Disconnect()
	RegisteredInstancesEvents.NameChanged[Object] = nil

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

	if RegisteredInstancesEvents.ChildAdded[Object] then
		return
	end

	local Handle = RegisteredInstances[Object]

	RegisteredInstancesEvents.ChildAdded[Object] = Object.ChildAdded:Connect(function(Child)
		RegisterInstance(Child, Handle)
	end)

	RegisteredInstancesEvents.ChildRemoved[Object] = Object.ChildRemoved:Connect(function(Child)
		UnregisterInstance(Child)
	end)

	for _, Child in pairs(Object:GetChildren()) do
		RegisterInstance(Child, Handle)
	end
end

local function LoadProperty(PropertyData: table, Parent: Instance, InstancePassthrough: Instance)
	local Hook
	local ReadOnly = (PropertyData.Tags and table.find(PropertyData.Tags, "ReadOnly")) or PropertyData.Security.Write=="RobloxSecurity"
	local CanRead = (PropertyData.Security.Read and PropertyData.Security.Read~="RobloxSecurity")

	local Frame = NewInstance("Frame")
	Frame.Size = UDim2.new(1, 0, 0, 16)
	Frame.AutomaticSize = Enum.AutomaticSize.Y
	Frame.BackgroundColor3 = Colors.Primary
	Frame.Parent = Parent

	local Name = NewInstance("TextLabel")
	Name.Size = UDim2.new(0.5, -8, 0, 16)
	Name.Position = UDim2.fromOffset(8, 0)
	Name.Text = PropertyData.Name
	Name.TextSize = 8
	--Name.AutomaticSize = Enum.AutomaticSize.X
	Name.BorderSizePixel = 0
	Name.BackgroundTransparency = 1
	Name.TextColor3 = Colors.Text
	Name.TextXAlignment = Enum.TextXAlignment.Left
	Name.Parent = Frame

	local ValueBox

	local function CreateValueBox(Class)
		local Box = NewInstance(Class)
		Box.Size = UDim2.new(1, -8, 0, 16)
		Box.AnchorPoint = NewV2(0, 0)
		Box.Position = UDim2.fromScale(1, 0)
		Box.BorderSizePixel = 0
		Box.BackgroundTransparency = 0
		Box.BackgroundColor3 = Colors.Secondary
		Box.Parent = Name

		return Box
	end
	
	if not CanRead then 
		local Box = CreateValueBox("Frame")
		Box.BackgroundColor3 = Color3.fromRGB(219, 0, 164)
		
		Frame.Visible = false

		return Frame, Hook
	end

	if PropertyData.ValueType.Category == "Primitive" then
		local ValueType = PropertyData.ValueType.Name

		if ValueType == "float" or ValueType == "int" or ValueType == "int64" then
			local Box = CreateValueBox(not ReadOnly and "TextBox" or "TextLabel")
			Box.Text = InstancePassthrough[PropertyData.Name]

			if not ReadOnly then
				Box.FocusLost:connect(function(PressedEnter)
					if PressedEnter and Utils:matchnumber(Box.Text) then
						InstancePassthrough[PropertyData.Name] = ValueType == "float" and Utils:matchnumber(Box.Text) or math.floor(Utils:matchnumber(Box.Text))
					end

					Box.Text = InstancePassthrough[PropertyData.Name]
				end)
			end

			Hook = InstancePassthrough:GetPropertyChangedSignal(PropertyData.Name):Connect(function()
				if not ReadOnly and Box:IsFocused() then
					Box.FocusLost:Wait()
				end
				Box.Text = InstancePassthrough[PropertyData.Name]
			end)
		elseif ValueType == "string" then
			local Box = CreateValueBox(not ReadOnly and "TextBox" or "TextLabel")
			Box.Text = InstancePassthrough[PropertyData.Name]

			if not ReadOnly then
				Box.FocusLost:connect(function(PressedEnter)
					if PressedEnter then
						InstancePassthrough[PropertyData.Name] = Box.Text
					end

					Box.Text = InstancePassthrough[PropertyData.Name]
				end)
			end

			Hook = InstancePassthrough:GetPropertyChangedSignal(PropertyData.Name):Connect(function()
				if not ReadOnly and Box:IsFocused() then
					Box.FocusLost:Wait()
				end
				Box.Text = InstancePassthrough[PropertyData.Name]
			end)
		elseif ValueType == "bool" then
			local Box = CreateValueBox(not ReadOnly and "TextButton" or "TextLabel")
			Box.TextColor3 = Color3.new(1, 1, 1)

			local OnColor = Color3.fromRGB(0, 139, 219)
			local OffColor = Color3.fromRGB(219, 0, 82)

			local function ReflectValue()
				Box.BackgroundColor3 = InstancePassthrough[PropertyData.Name] and OnColor or OffColor
				Box.Text = InstancePassthrough[PropertyData.Name] and "true" or "false"
			end

			if not ReadOnly then
				Box.MouseButton1Down:connect(function()
					InstancePassthrough[PropertyData.Name] = not InstancePassthrough[PropertyData.Name]
					ReflectValue()
				end)
			end

			Hook = InstancePassthrough:GetPropertyChangedSignal(PropertyData.Name):Connect(function()
				ReflectValue()
			end)

			ReflectValue()
		end
	elseif PropertyData.ValueType.Category == "DataType" then
		local ValueType = PropertyData.ValueType.Name

		local function SetupCSVBox(Class: any, Method: any, stringf: string, ...)
			local Box = CreateValueBox(not ReadOnly and "TextBox" or "TextLabel")
			local Params = { ... }

			local function ReflectValue()
				local Object = InstancePassthrough[PropertyData.Name]

				local Components = {}
				for IDX, Parameter in Params do
					if typeof(Parameter) == "table" then
						local Setting = Object

						for _, Subparameter in Parameter do
							Setting = Setting[Subparameter]
						end

						Components[IDX] = Setting
					else
						Components[IDX] = Object[Parameter]
						if ValueType == "Color3" then
							Components[IDX] *= 255
						end
					end
				end

				Box.Text = string.format(stringf, table.unpack(Components))
			end

			if not ReadOnly then
				Box.ClearTextOnFocus = false

				Box.FocusLost:connect(function(PressedEnter)
					if PressedEnter then
						local Components = string.split(Box.Text, ",")
						for IDX, Component in Components do
							Components[IDX] = tonumber(Utils:matchnumber(Component:gsub(" ", "")))
						end

						InstancePassthrough[PropertyData.Name] = Class[Method](table.unpack(Components))
					end

					ReflectValue()
				end)
			end

			Hook = InstancePassthrough:GetPropertyChangedSignal(PropertyData.Name):Connect(function()
				if not ReadOnly and Box:IsFocused() then
					Box.FocusLost:Wait()
				end
				ReflectValue()
			end)

			ReflectValue()
		end

		if ValueType == "Vector3" then
			SetupCSVBox(Vector3, "new", "%d, %d, %d", "X", "Y", "Z")
		elseif ValueType == "Vector2" then
			SetupCSVBox(Vector2, "new", "%d, %d", "X", "Y")
		elseif ValueType == "UDim2" then
			SetupCSVBox(UDim2, "new", "%d, %d, %d, %d", { "X", "Scale" }, { "X", "Offset" }, { "Y", "Scale" }, { "Y", "Offset" })
		elseif ValueType == "Color3" then
			SetupCSVBox(Color3, "fromRGB", "%d, %d, %d", "R", "G", "B")
		end
	elseif PropertyData.ValueType.Category == "Enum" then
		local Box = CreateValueBox(not ReadOnly and "TextButton" or "TextLabel")

		local Opened = false
		local ValidEnums = Enum[PropertyData.ValueType.Name]:GetEnumItems()
		local Buttons = {}

		local function ReflectValue()
			Box.Text = InstancePassthrough[PropertyData.Name].Name
		end

		if not ReadOnly then
			Box.MouseButton1Down:connect(function()
				if not Opened then
					for IDX, Enum in pairs(ValidEnums) do
						local Button = CreateValueBox("TextButton")
						Button.BackgroundColor3 = Button.BackgroundColor3:Lerp(Color3.new(1, 1, 1), 0.5)
						Button.Parent = Box
						Button.Position = UDim2.new(0, 0, 0, 16 * IDX)
						Button.Size = UDim2.new(1, 0, 0, 16)
						Button.Text = ValidEnums[IDX].Name

						Buttons[Button] = Enum

						Button.MouseButton1Down:connect(function()
							InstancePassthrough[PropertyData.Name] = Enum.Value
							ReflectValue()
						end)
					end
				else
					for Button, _ in pairs(Buttons) do
						Button:Remove()
						Buttons[Button] = nil
					end
				end
				Opened = not Opened
			end)
		end

		Hook = InstancePassthrough:GetPropertyChangedSignal(PropertyData.Name):Connect(function()
			ReflectValue()
		end)

		ReflectValue()
	elseif PropertyData.ValueType.Category == "Class" then
		local Box = CreateValueBox(not ReadOnly and "TextButton" or "TextLabel")
		local Selecting = false

		local function ReflectValue()
			Box.Text = InstancePassthrough[PropertyData.Name] and InstancePassthrough[PropertyData.Name].Name or "nil"
		end

		if not ReadOnly then
			Box.MouseButton1Down:connect(function()
				if Selecting == false and SelectingProperty == true then
					return
				end

				if not Selecting then
					SelectingProperty = true
					Interrupt.Event:Wait()
					task.wait()
					InstancePassthrough[PropertyData.Name] = InterruptOut
					InterruptOut = nil
					SelectingProperty = false
				else
					SelectingProperty = false
				end

				Selecting = not Selecting
				ReflectValue()
			end)
		end

		Hook = InstancePassthrough:GetPropertyChangedSignal(PropertyData.Name):Connect(function()
			ReflectValue()
		end)

		ReflectValue()
	end

	Frame.MouseEnter:Connect(function()
		Frame.BackgroundColor3 = Colors.Hover:Lerp(Frame.BackgroundColor3, 0.75)
	end)

	Frame.MouseLeave:Connect(function()
		Frame.BackgroundColor3 = Colors.Primary
	end)

	return Frame, Hook
end

local function LoadCategory(CategoryData: table, CategoryName: string, InstancePassthrough: Instance)
	local IsOpened = false
	local LoadedProperties = {}

	local Frame = NewInstance("Frame")
	Frame.Size = UDim2.new(1, 0, 0, 24)
	Frame.AutomaticSize = Enum.AutomaticSize.XY
	Frame.BackgroundColor3 = Colors.Secondary
	Frame.Parent = PropertyFrame

	local DropdownIcon = NewInstance("ImageLabel")
	DropdownIcon.Size = UDim2.fromOffset(8, 8)
	DropdownIcon.AnchorPoint = NewV2(0.5, 0.5)
	DropdownIcon.Position = UDim2.fromOffset(12, 12)
	DropdownIcon.Image = "rbxasset://textures/ui/dropdown_arrow@2x.png"
	DropdownIcon.BorderSizePixel = 0
	DropdownIcon.BackgroundTransparency = 1
	DropdownIcon.ScaleType = Enum.ScaleType.Fit
	DropdownIcon.ImageColor3 = Colors.Text
	DropdownIcon.Rotation = -90
	DropdownIcon.Parent = Frame

	local Dropdown = NewInstance("TextButton")
	Dropdown.Size = UDim2.fromOffset(24, 24)
	Dropdown.BorderSizePixel = 0
	Dropdown.BackgroundTransparency = 1
	Dropdown.Text = ""
	Dropdown.Parent = Frame

	local Name = NewInstance("TextLabel")
	Name.Size = UDim2.new(1, -40, 0, 16)
	Name.Position = UDim2.fromOffset(24, 4)
	Name.Text = CategoryName
	Name.TextSize = 8
	Name.AutomaticSize = Enum.AutomaticSize.X
	Name.BorderSizePixel = 0
	Name.BackgroundTransparency = 1
	Name.TextColor3 = Colors.Text
	Name.TextXAlignment = Enum.TextXAlignment.Left
	Name.Parent = Frame

	local Box = NewInstance("Frame")
	Box.Size = UDim2.new(1, -16, 0, 0)
	Box.Position = UDim2.fromOffset(24, 24)
	Box.AutomaticSize = Enum.AutomaticSize.XY
	Box.BorderSizePixel = 0
	Box.BackgroundTransparency = 1
	Box.Parent = Frame

	NewInstance("UIListLayout").Parent = Box

	Frame.MouseEnter:Connect(function()
		Frame.BackgroundColor3 = Colors.Hover:Lerp(Frame.BackgroundColor3, 0.75)
	end)

	Frame.MouseLeave:Connect(function()
		Frame.BackgroundColor3 = Colors.Secondary
	end)

	Dropdown.MouseButton1Down:Connect(function()
		if not IsOpened then
			local Properties = CategoryData
			for Name, Data in Properties do
				if Data.Tags and table.find(Data.Tags, "NotScriptable") then
					continue
				end
				local Tab = LoadProperty(Data, Box, InstancePassthrough)
				LoadedProperties[Tab] = true
			end
		else
			for Item, _ in LoadedProperties do
				Item:Remove()
				LoadedProperties[Item] = nil
			end
		end
		IsOpened = not IsOpened
		DropdownIcon.Rotation = IsOpened and 0 or -90
	end)

	LoadedPropertyCategories[CategoryName] = Frame
end

function ClearProperties()
	for IDX, Box in LoadedPropertyCategories do
		Box:Remove()
		LoadedPropertyCategories[IDX] = nil
	end
end

function LoadProperties(Object: Instance)
	if not AlmanacData[2] then
		return
	end

	local Almanac = AlmanacData[1]

	local Tree = Almanac[Object.ClassName]
	local Categories = Tree.AllProperties

	for CategoryName, CategoryData in Categories do
		LoadCategory(CategoryData, CategoryName, Object)
	end
end

local function CreateRoot(Root)
	for _, Instance in pairs(Root:GetChildren()) do
		RegisterInstance(Instance)
	end
end

local function ClearRoot(Root)
	for _, Instance in pairs(Root:GetChildren()) do
		UnregisterInstance(Instance)
	end
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
	SearchBox.Text = ""
	SearchBox.PlaceholderText = "Search: "
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
	PropertyFrame.Size = UDim2.new(1, 0, 1 - BrowserProportion, -16)
	PropertyFrame.Position = UDim2.new(1, 0, 1, 0)
	PropertyFrame.Parent = ExplorerBody
	PropertyFrame.AutomaticCanvasSize = Enum.AutomaticSize.XY
	PropertyFrame.CanvasSize = UDim2.new()

	FilterBox = NewInstance("TextBox")
	FilterBox.AnchorPoint = NewV2(1, 0)
	FilterBox.Size = UDim2.new(1, 0, 0, 16)
	FilterBox.Position = UDim2.new(1, 0, BrowserProportion, 0)
	FilterBox.Text = ""
	FilterBox.PlaceholderText = "Filter: "
	FilterBox.BackgroundColor3 = Colors.Primary
	FilterBox.Parent = ExplorerBody

	NewInstance("UIListLayout").Parent = InstanceFrame
	NewInstance("UIListLayout").Parent = PropertyFrame

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
	end)

	SearchBox.FocusLost:Connect(function(IsEnter)
		if not IsEnter then
			return
		end
		local Pattern = SearchBox.Text
		ClearRoot(Root)
		CannotSelect = true
		if Pattern == "" then
			CannotSelect = false
			CreateRoot(Root)
			return
		end

		Quartermaster:Reset()
		for _, Instance in pairs(game:GetDescendants()) do
			if Utils:matchpattern(Pattern, Instance.Name) then
				local Ancestry = Utils:GetAncestry(Instance, Root)

				for IDX, Item in Ancestry do
					RegisterInstance(Item, RegisteredInstances[Item.Parent] or InstanceFrame, true)
				end
			end

			Quartermaster:Tick()
		end
	end)

	CreateRoot(Root)
end

CreateExplorer(game)
