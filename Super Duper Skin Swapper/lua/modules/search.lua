---@class SDSS.Search
SDSS.Search = {}

SDSS.Search.query = ""

function SDSS.Search:is_active()
	return self.query ~= ""
end

function SDSS.Search:reset()
	self.query = ""
end

--Collapses multiple spaces.
--Strips leading/trailing spaces.
function SDSS.Search:_sanitize(text)
	return text:gsub("%s+", " "):match("^%s*(.-)%s*$")
end

--Keep things simple for now.
function SDSS.Search:build_search_table(name)
	--String.lower() doesn't work on Cyrillic.
	--utf8.to_lower() changes representations of some chars internally e.g. á
	--utf8.to_lower() works on most Cyrillic except Ё ё
	local original = name:lower()
	--Strip ASCII punctuation.
	--Accents are preserved. Foreign characters are preserved.
	local alphanumeric = original:gsub("%p", "")
	local words = original:gsub("%p", " ")

	return {
		original = original,
		alphanumeric = alphanumeric,
		words = words,
	}
end

function SDSS.Search:matches(weapon_search, skin_search)
	for term in self.query:lower():gmatch("%S+") do
		local term_match = false
		for _, search_table in ipairs({weapon_search, skin_search}) do
			local table_match = false
			for _, k in ipairs({"original", "alphanumeric", "words"}) do
				for word in search_table[k]:gmatch("%S+") do
					if ncUtils.String:head_match(word, term) then
						table_match = true
						break
					end
				end
				if table_match then
					break
				end
			end

			if table_match then
				term_match = true
				break
			end
		end

		--Every term must match.
		if not term_match then
			return false
		end
	end

	return true
end

--Actual processing here.
function SDSS.Search:_process_search(text)
	if text ~= self.query then
		self.query = text
		SDSS.Filter:refresh_blackmarket_ui()
	end
end

function SDSS.Search:process_search(text)
	text = self:_sanitize(text or "")
	local callback = function()
		self:_process_search(text)
	end

	--Just for fun
	if text == "exit game" then
		self:_dialog_exit_game(callback)
		return
	elseif text == "sudo exit game" then
		MenuCallbackHandler:_dialog_save_progress_backup_no()
		return
	elseif text:lower() == "thanks" then
		self:_dialog_thanks(callback)
		return
	elseif text == "67" then
		self:_dialog_67(callback)
		return
	end

	callback()
end

function SDSS.Search:_dialog_exit_game(callback)
	local menu_title = managers.localization:text("sdss_dialog_title")
	local menu_message = managers.localization:text("sdss_dialog_exit_game")
	local menu_options = {
		{
			text = managers.localization:text("dialog_yes"),
			callback = function()
				MenuCallbackHandler:_dialog_save_progress_backup_no()
			end,
		},
		{
			text = managers.localization:text("dialog_no"),
			is_cancel_button = true,
			is_focused_button = true,
			callback = callback,
		}
	}
	ncDialogs:show(menu_title, menu_message, menu_options)
end

function SDSS.Search:_dialog_thanks(callback)
	local menu_title = managers.localization:text("sdss_dialog_title")
	local menu_message = managers.localization:text("sdss_dialog_thanks")
	local menu_options = {
		{
			text = managers.localization:text("dialog_ok"),
			callback = callback,
		}
	}
	ncDialogs:show(menu_title, menu_message, menu_options)
end

function SDSS.Search:_dialog_67(callback)
	local button_list = {
		{
			text = managers.localization:text("dialog_ok"),
			callback_func = callback,
		}
	}

	local data = {
		id = "sdss_menu_id_67",
		title = managers.localization:text("sdss_dialog_title"),
		text = " \n6 7\n ",
		button_list = button_list,
		focus_button = 1,
		no_buttons = false,
		force = false,
	}

	managers.system_menu:show(data)
end
