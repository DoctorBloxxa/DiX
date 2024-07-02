--- Kill all bloxxas!!!!!

local HttpService = game:GetService("HttpService")
local IsAPILoaded, APILoaded = false, Instance.new("BindableEvent")
local RunService = game:GetService("RunService")
local IsStudio = RunService:IsStudio()

local function GetApiData()
	local retries = 0
	local sucess, data

	local Method	= (IsStudio and HttpService.GetAsync) or game.HttpGet
	local Root		= (IsStudio and HttpService) or game

	while retries <= math.huge do
		sucess, data = pcall(
			Method, Root,
			"https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/API-Dump.json"
		)

		if sucess then
			return HttpService:JSONDecode(data)
		end

		game:GetService("RunService").Heartbeat:Wait()
	end

	warn("[Properties++]: ", data)
end

local Classes = {}

local function CreatePropertiesForClasses()
	local HttpData = GetApiData()
	for _, Class in pairs(HttpData.Classes) do
		local Things = {
			Property 	=	{},
			Function 	= 	{},
			Event		=	{},
			Callback	=	{},
			Categorized =   {},
		}

		for _, Stuff in pairs(Class.Members) do
			Things[Stuff.MemberType][Stuff.Name] = Stuff
		end
		
		for _, Property in pairs(Things.Property) do
			Things.Categorized[Property.Category] = true
		end
		
		for Category, _ in pairs(Things.Categorized) do
			Things.Categorized[Category] = {}
		end
		
		for _, Property in pairs(Things.Property) do
			Things.Categorized[Property.Category][Property.Name] = Property
		end

		Classes[Class.Name] = {
			Name 		= Class.Name,
			SuperClass 	= Class.Superclass,
			Tags 		= Class.Tags,

			Properties 	= Things.Property,
			Methods		= Things.Function,
			Events		= Things.Event,
			Callbacks	= Things.Callback,
			
			CategorizedProperties = Things.Categorized,
		}
	end

	IsAPILoaded = true
	APILoaded:Fire()
	APILoaded:Remove()
end

task.spawn(CreatePropertiesForClasses)

local Properties = {}

function Properties:GetProperties(instance: Instance | any)
	if not IsAPILoaded then
		APILoaded.Event:Wait()
	end

	return Classes[instance.ClassName]
end

function Properties:ReadEnum(enum: Enum)
	return enum:GetEnumItems()
end

return setmetatable(Properties, { __index = Instance })