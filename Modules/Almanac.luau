local HttpService = game:GetService("HttpService")
local IsAPILoaded, APILoaded = false, Instance.new("BindableEvent")
local RunService = game:GetService("RunService")
local IsStudio = RunService:IsStudio()

if IsStudio then
	warn("Unable to fetch Roblox API. Almanac unusable.")
	return {}
end

local function GetApiData()
	--return HttpService:JSONDecode(HttpService:GetAsync("https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/API-Dump.json", true))
	return HttpService:JSONDecode(game:HttpGet("https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/API-Dump.json", true))
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
			Data.Categorized[Property.Category] = true
		end

		for Category, _ in pairs(Data.Categorized) do
			Data.Categorized[Category] = {}
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

if not IsAPILoaded then
	APILoaded.Event:Wait()
end

for Class, ClassData in Classes do
	local Super = ClassData.SuperClass
	local MergedProperties = ClassData.CategorizedProperties
	
	--print(Class, MergedProperties)

	if Super ~= "<<<ROOT>>>" then
		repeat
			local SuperTree = Classes[Super]
			Super = SuperTree.SuperClass
			
			if Super == "<<<ROOT>>>" or Super == Classes[Super].SuperClass then break end
			
			--warn(Super, Classes[Super].SuperClass)

			for Category, Properties in pairs(SuperTree.CategorizedProperties) do
				if MergedProperties[Category]==nil then MergedProperties[Category] = {} end

				--warn(Category, Properties)

				for Property, Data in Properties do
					MergedProperties[Category][Property] = Data
				end
			end
			--game:GetService("RunService").Heartbeat:Wait()
		until false
	end

	ClassData.AllProperties = MergedProperties
end

warn(Classes["Part"].AllProperties)

return {Classes, APILoaded}
