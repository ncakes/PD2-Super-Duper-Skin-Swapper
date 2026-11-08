if not _G.ncDialogs or ncDialogs.path ~= ModPath .. "ncDialogs/" then
	return
end

ncDialogs._freeze_version = true
ncDialogs._hooks = ncDialogs._hooks or {}

local function init_class(CLASS_NAME)
	if not ncDialogs[CLASS_NAME] then
		local ok, err = pcall(dofile, ncDialogs.path .. "classes/" .. CLASS_NAME .. ".lua")
		if not ok then
			ncDialogs[CLASS_NAME] = nil
			log(string.format("[ncDialogs] ERROR: class %s initialization failed: %s", CLASS_NAME, tostring(err)))
		elseif not ncDialogs[CLASS_NAME] then
			log(string.format("[ncDialogs] ERROR: class %s not registered after initialization", CLASS_NAME))
		end
	else
		log(string.format("[ncDialogs] ERROR: class %s already registered", CLASS_NAME))
	end
end

if RequiredScript == "lib/setups/setup" and not ncDialogs._hooks[RequiredScript] then
	ncDialogs._hooks[RequiredScript] = true
	init_class("TextInputDialog")
	init_class("PaginatedDialog")
end
