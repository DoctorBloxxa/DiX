--- Kill all bloxxas!!!!!

local HttpService = game:GetService("HttpService")
local IsAPILoaded, APILoaded = false, Instance.new("BindableEvent")
local RunService = game:GetService("RunService")
local IsStudio = RunService:IsStudio()

local function GetApiData()
	local retries = 0
	local success, data

	local Method	= (IsStudio and HttpService.GetAsync) or game.HttpGet
	local Root		= (IsStudio and HttpService) or game
	
	local Link = "https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/API-Dump.json"
	
	local Args = IsStudio and {Method, Root, Link} or {Method, Link}

	repeat
	
		success, data = pcall(table.unpack(Args))

		if success then
			return HttpService:JSONDecode(data)
		end

		RunService.Heartbeat:Wait()
		
		if not IsStudio then warn("[Properties++]: ", data) end --- Avoids lagging studio with warns (yes we know you can't do http requests as a localscript now shut the fuck up)
	until false
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
		
		--- All these loops below so I avoid brancing and have properties by category too
		
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