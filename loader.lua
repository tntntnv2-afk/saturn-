local REPO = "https://raw.githubusercontent.com/tntntnv2-afk/saturn-/main/"
local CACHE = "Saturn/library_cache.lua"
local function fromGitHub()
	local source = game:HttpGet(REPO .. "Saturn.lua")
	pcall(function()
		if not isfolder("Saturn") then
			makefolder("Saturn")
		end
		writefile(CACHE, source)
	end)
	return source
end
local cached = nil
pcall(function()
	cached = isfile(CACHE) and readfile(CACHE) or nil
end)
if type(cached) == "string" and #cached > 1000 then
	local fn = loadstring(cached, "=Saturn")
	if fn then
		local ok, lib = pcall(fn)
		if ok and type(lib) == "table" then
			task.spawn(pcall, fromGitHub)
			return lib
		end
	end
end
return loadstring(fromGitHub(), "=Saturn")()
