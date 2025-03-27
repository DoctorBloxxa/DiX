local HttpService = game:GetService("HttpService")
local IsAPILoaded, APILoaded = false, Instance.new("BindableEvent")
local RunService = game:GetService("RunService")
local IsStudio = RunService:IsStudio()

local function GetApiData()
	local success, data

	local Link = "https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/API-Dump.json"

	repeat
		local success, data

		if IsStudio and HttpService then
			success, data = pcall(HttpService.GetAsync, HttpService, Link)
		else
			data = game:HttpGet(Link, true)
			success = true
		end

		if success then
			return HttpService:JSONDecode(data)
		end

		wait(1)
	until false
end

local Classes = {}

local function CreatePropertiesForClasses()
	local HttpData = GetApiData()
	for _, Class in pairs(HttpData.Classes) do
		local Data = {
			Property = {},
			Function = {},
			Event = {},
			Callback = {},
			Categorized = {},
		}

		for _, Stuff in pairs(Class.Members) do
			Data[Stuff.MemberType][Stuff.Name] = Stuff
		end

		--- All these loops below so I avoid brancing and have properties by category too

		for _, Property in pairs(Data.Property) do
			Data.Categorized[Data.Category] = true
		end

		for Category, _ in pairs(Data.Categorized) do
			Data.Categorized[Data] = {}
		end

		for _, Property in pairs(Data.Property) do
			Data.Categorized[Property.Category][Property.Name] = Property
		end

		Classes[Class.Name] = {
			Name = Class.Name,
			SuperClass = Class.Superclass,
			Tags = Class.Tags,

			Properties = Data.Property,
			Methods = Data.Function,
			Events = Data.Event,
			Callbacks = Data.Callback,

			CategorizedProperties = Data.Categorized,
		}
	end

	IsAPILoaded = true
	APILoaded:Fire()
	APILoaded:Remove()
end

task.spawn(CreatePropertiesForClasses)

return Classes
