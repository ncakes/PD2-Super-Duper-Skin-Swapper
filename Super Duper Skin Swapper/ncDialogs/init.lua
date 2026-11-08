if RequiredScript ~= "core/lib/system/coresystem" then
	log("[ncDialogs] ERROR: invalid initialization hook, skipping: " .. ModPath)
	return
end

if _G.ncDialogs and ncDialogs._freeze_version then
	if not ncDialogs.devmode then
		log("[ncDialogs] ERROR: version frozen, skipping: " .. ModPath)
	end
	return
end

local version = 1

if _G.ncDialogs and ncDialogs.version and ncDialogs.version >= version then
	return
end

_G.ncDialogs = {
	version = version,
	path = ModPath .. "ncDialogs/",
}

dofile(ncDialogs.path .. "core.lua")
dofile(ncDialogs.path .. "menu.lua")
dofile(ncDialogs.path .. "menu_paginated.lua")
dofile(ncDialogs.path .. "menu_paginated_classic.lua")
dofile(ncDialogs.path .. "menu_input.lua")
