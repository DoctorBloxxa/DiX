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

	while retries <= 3 do
		sucess, data = pcall(
			Method, Root,
			"https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/API-Dump.json"
		)

		if sucess then
			return HttpService:JSONDecode(data)
		end

		RunService.Heartbeat:Wait()
	end

	warn("[Properties+ Http Error]: ", data)
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
		}

		for _, Stuff in pairs(Class.Members) do
			Things[Stuff.MemberType][Stuff.Name] = Stuff
		end

		Classes[Class.Name] = {
			Name 		= Class.Name,
			SuperClass 	= Class.Superclass,
			Tags 		= Class.Tags,

			Properties 	= Things.Property,
			Methods		= Things.Function,
			Events		= Things.Event,
			Callbacks	= Things.Callback,
		}
	end
	
	IsAPILoaded = true
	APILoaded:Fire()
end

task.spawn(CreatePropertiesForClasses)

local Properties = {}

function Properties:GetProperties(instance: string | any)
	if not IsAPILoaded then
		APILoaded.Event:Wait()
		APILoaded:Remove()
	end

	return Classes[tostring(instance)]
end

function Properties:ReadEnum(enum: Enum)
	return enum:GetEnumItems()
end

return setmetatable(Properties, { __index = Instance })