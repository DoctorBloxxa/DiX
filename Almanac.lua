local User = game:GetService("Players").LocalPlayer
local Mouse = User:GetMouse()
local Niggasex;
local ContentProvider = game:GetService("ContentProvider")
local Spritesheet = "rbxasset://textures/ClassImages.png"
local UserInputService = game:GetService("UserInputService")
local SelectionInterrupt = Instance.new("BindableEvent")
local RunService = game:GetService("RunService")
local Storage = RunService:IsStudio() and game or game.CoreGui
local HttpService = game:GetService("HttpService")
local LibraryURL = "https://raw.githubusercontent.com/DoctorBloxxa/DiX/main/Almanac.lua" --- This should be the url to the raw code of the library
local Instance = (RunService:IsStudio() and require(script:WaitForChild("Instance"))) or HttpService:JSONDecode(game:HttpGet(LibraryURL, true))
local HoverThing = Instance.new("Highlight", Storage)
local Holobolo6Billion = RaycastParams.new()

local MouseSelector = false

local Colors = {
	Primary 		= Color3.new(0.917647, 0.917647, 0.917647),
	Secondary 		= Color3.new(0.882353, 0, 1),
	SoftSelected 	= Color3.new(0.364706, 0.556863, 1),
	Selected 		= Color3.new(0.52549, 0.729412, 1),
	Text			= Color3.new(0, 0, 0),
}

Colors.SoftSelected = Colors.Primary:Lerp(Colors.SoftSelected, .25)

Holobolo6Billion.FilterType = Enum.RaycastFilterType.Exclude
Holobolo6Billion.IgnoreWater = true

HoverThing.OutlineColor = Color3.fromRGB(178,229,255)
HoverThing.FillTransparency = 1

local ResolveTile = {
	IntValue				=	4,
	NunberValue				=	4,
	Vector3Value			=	4,
	BoolValue				=	4,
	StringValue				=	4,

	Animation				=	60,

	Fire					=	61,
	Smoke					=	59,
	ParticleEmitter			=	80,
	Sparkles				=	42,

	Terrain					=	65,
	Part					=	1,
	BasePart				=	1,

	SpawnLocation			=	25,

	Union					=	73,
	NegateOperation			=	72,
	UnionOperation			=	73,
	MeshPart				=	73,

	Decal					=	7,

	Mesh					=	8,
	SpecialMesh				=	8,
	BlockMesh				=	8,
	CharacterMesh			=	8,
	WrapTarget				=	8,

	Model					= 	2,
	Folder					=	77,

	Camera					=	5,
	Humanoid				=	9,

	Texture					= 	10,
	SurfaceAppearance		= 	10,

	Sound					=	11,
	SoundService			=	31,

	Player					=	12,

	Teams					=	23,

	Lighting				=	13,
	Players					=	79,
	ServerScriptService		=	71,
	ReplicatedStorage		=	70,
	ReplicatedFirst			=	70,
	ServerStorage			=	69,

	PointLight				=	13,
	SpotLight				=	13,
	SurfaceLight			=	13,

	Sky						=	28,
	ColorCorrectionEffect	=	38,
	DepthOfFieldEffect		=	38,
	BlurEffect				=	38,
	SunRaysEffect			=	38,

	Highlight				=	133,

	Workspace				=	19,

	Script					=	6,
	LocalScript				=	18,
	ModuleScript			=	76,

	Tool					=	17,
	HopperBin				=	22,

	Explosion				=	36,

	Hat						=	45,
	Pants					=	44,
	Shirt					=	43,
	ShirtGraphic			=	40,
	Accessory				=	32,

	Weld					=	34,
	Snap					=	34,

	Motor6D					=	106,
	Attachment				=	81,
	WeldConstraint			=	94,

	Seat					=	35,

	ClickDetector			=	41,
	TouchInterest			=	37,
	ForceField				=	37,

	RemoteFunction			=	74,
	RemoteEvent				=	75,

	BindableEvent			=	67,
	BindableFunction		=	66,

	ImageButton				=	52,
	TextButton				=	51,
	TextBox					=	51,
	TextLabel				=	50,
	ImageLabel				=	49,
	Frame					=	48,
	ScreenGui				=	47,
	StarterGui				=	46,
}

local ReadBack = {

};

local Selections = {

};

local Adornments = {

};

local SearchResult = {

};

local function GetAncestry(Part, Break)
	local List = {}
	local Break = Break or game
	local Parent = Part

	repeat 
		List[#List+1] = Parent
		Parent = Parent.Parent
	until Parent == Break or Parent.Parent == nil

	local InvertedList = {}
	for i=0,#List do
		InvertedList[i+1] = List[#List-i]
	end

	return InvertedList
end

local function GetAncestorestModel(Part, Break)
	local Result = Part
	local Break = Break or game
	local Parent = Part

	repeat 
		if Parent.ClassName=="Model" then
			Result = Parent
		end
		Parent = Parent.Parent
	until Parent == Break or Parent.Parent == nil

	return Result
end

local function CreateExplorer(Parent)
	if Niggasex then Niggasex.Parent:Remove() end

	local GUI = Instance.new("ScreenGui", Parent)
	GUI.ResetOnSpawn = false
	local Container = Instance.new("Frame",GUI)
	local SearchBar = Instance.new("TextBox",Container)

	local Explorer = Instance.new("ScrollingFrame", Container)
	local Constraint = Instance.new("UIListLayout", Explorer)

	local ButtonContainer = Instance.new("Frame", Container)
	local ButtonConstraint = Instance.new("UIGridLayout", ButtonContainer)
	ButtonConstraint.CellSize =	UDim2.fromOffset(32,32)

	local Button 	=	Instance.new("ImageButton")
	Button.BorderSizePixel = 0
	Button.BackgroundTransparency = 1

	ButtonContainer.BackgroundTransparency = 0
	ButtonContainer.Size = UDim2.new(.5,0,0,32)
	ButtonContainer.BorderSizePixel = 0

	Container.AnchorPoint = Vector2.new(1,0)
	Container.Position = UDim2.fromScale(1,0)
	Container.Size = UDim2.fromScale(.25,1)
	Container.BackgroundTransparency = 1

	Explorer.AnchorPoint = Vector2.new(0,1)
	Explorer.Size = UDim2.new(1,0,.75,-32)
	Explorer.Position = UDim2.fromScale(0,.75)
	Explorer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Explorer.AutomaticCanvasSize = Enum.AutomaticSize.XY
	Explorer.CanvasSize = UDim2.fromScale(0,0)
	Explorer.ScrollBarImageColor3 = Colors.Secondary

	local DelButton = Button:Clone()
	DelButton.Parent = ButtonContainer
	DelButton.Image = "rbxasset://icons/delete.png"

	local MoveButton = Button:Clone()
	MoveButton.Parent = ButtonContainer
	MoveButton.Image = "rbxasset://icons/delete.png"

	local ResizeButton = Button:Clone()
	ResizeButton.Parent = ButtonContainer
	ResizeButton.Image = "rbxasset://icons/resize.png"

	local RotateButton = Button:Clone()
	RotateButton.Parent = ButtonContainer
	RotateButton.Image = "rbxasset://icons/rotate.png"

	local MoveHandle = Instance.new("Handles")
	local ResizeHandle = Instance.new("Handles")
	local RotateHandle = Instance.new("ArcHandles")

	DelButton.MouseButton1Click:Connect(function()
		for Item, _ in pairs(Selections) do
			pcall(function()
				Item:Remove()
			end)
		end
	end)

	SearchBar.Size = UDim2.new(.5,0,0,32)
	SearchBar.AnchorPoint = Vector2.new(1,0)
	SearchBar.PlaceholderText = "SEARCH"
	SearchBar.ClearTextOnFocus = false
	SearchBar.Position = UDim2.fromScale(1,0)
	SearchBar.Text = ""

	SearchBar.FocusLost:Connect(function(Enter)
		if not Enter then return end

		ClearSelections()
		ReadBack = {}
		SearchResult = {}
		Selections = {}

		Constraint.Parent = nil
		Niggasex:ClearAllChildren()
		Constraint.Parent = Explorer

		local Pattern = SearchBar.Text

		if Pattern=="" then 
			CreateWorld(game)
			return end

		for _, Item in pairs(game:GetDescendants()) do
			if string.find(string.lower(Item.Name),string.lower(Pattern)) then
				SearchResult[#SearchResult+1] = Item

				local Ancestry = GetAncestry(Item, game)

				if not ReadBack[Ancestry[1]] then
					CreateItem(Ancestry[1])
				end

				Ancestry[#Ancestry] = nil

				for _, Item in pairs(Ancestry) do
					if not ReadBack[Item][3] then
						ReadBack[Item][2]()
					end
				end

				SelectionInterrupt:Fire(Item, true, true)	--- avoids wrapper function to bypass search restriction
			end
		end
	end)

	Niggasex = Explorer
end

function CreateItem(Class, Parent)
	if Niggasex then else return end
	local Opened = false
	local Items = {}

	local Frame = Instance.new("Frame")
	Frame.Parent = Parent~=nil and Parent or Niggasex
	Frame.Size = UDim2.new(1,0,0,16)
	Frame.BackgroundColor3 = Selections[Class] and Colors.Selected or Colors.Primary
	Frame.BorderSizePixel = 0
	Frame.AutomaticSize = Enum.AutomaticSize.XY

	local Text = Instance.new("TextButton")
	Text.Parent = Frame
	Text.Text = Class.Name
	Text.Position = UDim2.new(0,16,0,0)
	Text.Size = UDim2.new(1,-16,0,16)
	Text.BorderSizePixel = 0
	Text.BackgroundTransparency = 1
	Text.TextScaled = true
	Text.TextXAlignment = Enum.TextXAlignment.Left	
	Text.TextColor3 = Colors.Text

	local Image = Instance.new("ImageButton")
	Image.Parent = Frame
	Image.Size = UDim2.fromOffset(16,16)
	Image.Image = Spritesheet
	Image.ImageRectSize = Vector2.new(16,16)
	Image.ImageRectOffset = Vector2.new(1,0)*16*(ResolveTile[Class.ClassName] or 0)
	Image.BorderSizePixel = 0
	Image.BackgroundTransparency = 1

	local Container = Instance.new("Frame")
	Container.Parent = Frame
	Container.BackgroundTransparency = 1

	local ContainerSorter = Instance.new("UIListLayout")
	ContainerSorter.Parent = Container

	local Adder;
	local Remover;
	local Updater;
	local StackPusher;
	local Disconnect;
	local Hovered = false;

	local function OpenSequence()
		if Opened then 

			ContainerSorter.Parent = nil
			Container:ClearAllChildren()
			ContainerSorter.Parent = Container
			Container.BackgroundTransparency = 1

			Adder:Disconnect()
			Remover:Disconnect()

		else

			Container.Position = UDim2.new(0,16,0,16)
			Container.Size = UDim2.new(1,0,1,-16)

			Container.BackgroundTransparency = 0
			Container.BackgroundColor3 = Color3.new(1,1,0)
			for _, Item in pairs(Class:GetChildren()) do
				Items[Item] = CreateItem(Item,  Container)
			end

			Adder = Class.ChildAdded:Connect(function(Item)
				Items[Item] = CreateItem(Item, Container)
			end)
			Remover = Class.ChildRemoved:Connect(function(Item)
				Items[Item]:Remove()
			end)

		end
		Opened = not Opened
		ReadBack[Class][3] = Opened
	end

	ReadBack[Class] = {
		Frame, 
		OpenSequence, 
		Opened,
		Text,
		Disconnect,
		Hovered,
	} --- This will allow to open things on demand

	Image.MouseButton1Click:connect(function() if #SearchResult~=0 then return end OpenSequence() end)
	Text.MouseButton1Click:connect(function()
		if #SearchResult~=0 then return end

		SelectItem(Class, UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or false, not Selections[Class])
	end)

	Updater = Class:GetPropertyChangedSignal("Name"):Connect(function()
		Text.Text = Class.Name
	end)

	function Disconnect()
		Updater:Disconnect()
	end

	Frame.MouseEnter:Connect(function()
		ReadBack[Class][6] = true
		Frame.BackgroundColor3 = Selections[Class] and Colors.Selected or Colors.SoftSelected
	end)

	Frame.MouseLeave:Connect(function()
		ReadBack[Class][6] = false
		Frame.BackgroundColor3 = Selections[Class] and Colors.Selected or Colors.Primary
	end)

	Frame.Destroying:connect(Disconnect)

	return Frame
end


function CreateWorld(Start)
	for _, Instance in pairs(Start:GetChildren()) do
		CreateItem(Instance)
	end
end

function SelectItem(Item, Multi, Select)
	if #SearchResult~=0 then return end
	SelectionInterrupt:Fire(Item, Multi, Select)
end

UserInputService.InputBegan:Connect(function(input, Processed)
	if #SearchResult~=0 then return end
	if input.UserInputType == Enum.UserInputType.MouseButton3 then
		
		MouseSelector = not MouseSelector
		if MouseSelector then
			RunService:BindToRenderStep("Selector", 0 , SelectionRoutine) 
		else
			RunService:UnbindFromRenderStep("Selector") 
		end
		
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 and MouseSelector==true then

		Holobolo6Billion.FilterDescendantsInstances = { User.Character }

		local Part = workspace:Raycast(workspace.CurrentCamera.CFrame.Position, Mouse.UnitRay.Direction*15000, Holobolo6Billion)

		if Part then else return end

		Part = Part.Instance
		
		Part = UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) and Part or GetAncestorestModel(Part)

		local Ancestry = GetAncestry(Part)
		Ancestry[#Ancestry] = nil

		for _, Item in pairs(Ancestry) do
			if not ReadBack[Item][3] then
				ReadBack[Item][2]()
			end
		end

		SelectItem(Part, UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or false, not Selections[Part])
	end
end)

function ClearSelections()
	for Item, _ in pairs(Selections) do
		ReadBack[Item][1].BackgroundColor3 = (ReadBack[Item][6] and Colors.SoftSelected) or Colors.Primary
		if Adornments[Item] then
			for _, Thing in pairs(Adornments[Item]) do
				--Thing.Adornee = nil
				Thing:Remove()
			end

			Adornments[Item] = nil
		end
	end
end

function SelectionRoutine()
	local Ancestry = Mouse.Target and GetAncestorestModel(Mouse.Target, workspace) or nil
	local Last = Ancestry

	HoverThing.Adornee = Last
end

SelectionInterrupt.Event:connect(function(Item, Multiple, Select, Highlight)
	ClearSelections()

	if not Multiple then Selections = {} end
	if not Item then return end
	Selections[Item] = Select or nil

	for Item, _ in pairs(Selections) do
		ReadBack[Item][1].BackgroundColor3 = Colors.Selected

		local Selection = Instance.new("Highlight")	
		Selection.Adornee = Item
		Selection.Parent = Storage
		Selection.FillTransparency = 1
		Selection.OutlineColor = Color3.fromRGB(25, 153, 255)

		Adornments[Item] = {
			Selection
		}
	end
end)

CreateExplorer(User.PlayerGui)
CreateWorld(game)

