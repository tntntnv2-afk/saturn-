local REPO = "https://raw.githubusercontent.com/tntntnv2-afk/saturn-/main/"
local CACHE = "Saturn/library_cache.lua"
local ok, source = pcall(function()
	return game:HttpGet(REPO .. "Saturn.lua")
end)
if ok and type(source) == "string" and #source > 1000 then
	local fn = loadstring(source, "=Saturn")
	if fn then
		pcall(function()
			if not isfolder("Saturn") then
				makefolder("Saturn")
			end
			writefile(CACHE, source)
		end)
		return fn()
	end
end
local cached = nil
pcall(function()
	cached = isfile(CACHE) and readfile(CACHE) or nil
end)
assert(type(cached) == "string" and #cached > 1000, "Saturn couldn't be downloaded")
return loadstring(cached, "=Saturn")()
