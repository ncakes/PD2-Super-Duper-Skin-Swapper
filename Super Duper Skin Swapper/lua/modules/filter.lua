---@class SDSS.Filter
SDSS.Filter = {}

SDSS.Filter.defaults = {
	filter_hide_unowned = false,
	filter_sort = "off",
	filter_safe = "off",
	filter_rarity = "off",
	filter_weapon = "off",
	filter_weapon_cat = "same",
	filter_weapon_fam = "ak",
}

local RESET_BUTTON_NAME = "filter_reset"
local SEARCH_BUTTON_NAME = "filter_search"
SDSS.Filter.buttons = {
	RESET_BUTTON_NAME,
	SEARCH_BUTTON_NAME,
	"filter_hide_unowned",--Toggle
	"filter_sort",
	"filter_safe",
	"filter_rarity",
	"filter_weapon",
}

--First entry in a main multiple choice filter must be "off".
SDSS.Filter.choices = {}
SDSS.Filter.choices.filter_sort = {"off", "highlow", "lowhigh", "alpha"}
SDSS.Filter.choices.filter_safe = {"off", "base", "custom",
	"wwt", "buck", "surf", "grunt", "flake", "same", "smosh", "cs3", "cs4", "skf",
	"css", "cat", "ait", "nin", "cop", "cf15", "dallas", "dss", "red", "bah",
	"lones", "cola", "wac", "mxs", "sfs", "dinner", "sputnik", "burn", "pack",
}
SDSS.Filter.choices.filter_rarity = {"off", "legendary", "epic", "rare", "uncommon", "common"}
SDSS.Filter.choices.filter_weapon = {"off", "cat", "fam", "cor"}
SDSS.Filter.choices.filter_weapon_cat = {parent = {filter_weapon = "cat"}, "same", "pistol", "shotgun", "smg", "assault_rifle", "lmg", "snp", "special"}
SDSS.Filter.choices.filter_weapon_fam = {parent = {filter_weapon = "fam"}, "ak", "car", "mossberg"}

--Sets filter_id to default value if specified, otherwise sets all filters to default.
function SDSS.Filter:reset(filter_id)
	if filter_id then
		if self:is_search(filter_id) then
			SDSS.Search:reset()
			return
		end

		if self.defaults[filter_id] ~= nil then
			SDSS.settings[filter_id] = self.defaults[filter_id]
		end
		return
	end

	SDSS.Search:reset()
	for k, v in pairs(self.defaults) do
		SDSS.settings[k] = v
	end
end

--THIS READS SETTINGS.
--Get child of a MC filter if one exists.
--Returns nil if no child. Non-MC filters never have children.
function SDSS.Filter:_get_child_id(filter_id)
	if not self.choices[filter_id] then
		return nil
	end
	local child_id = filter_id .. "_" .. SDSS.settings[filter_id]
	if not self.choices[child_id] then
		return nil
	end
	return child_id
end

--Validate filter settings.
function SDSS.Filter:validate()
	for filter_id, value in pairs(self.defaults) do
		local invalid = false
		if type(value) ~= type(SDSS.settings[filter_id]) then
			invalid = true
		elseif self.choices[filter_id] and not table.contains(self.choices[filter_id], SDSS.settings[filter_id]) then
			invalid = true
		end
		if invalid then
			SDSS.settings[filter_id] = value
		end
	end
end

--Get filter state as a string.
--Returns nil on invalid filter_id.
--Boolean filters return "on" or "off"
--Can be called for submenus.
function SDSS.Filter:get_state(filter_id)
	if self:is_search(filter_id) then
		return SDSS.Search.query
	end

	local value = SDSS.settings[filter_id]
	if value == nil then
		return nil
	end

	if type(value) == "boolean" then
		return value and "on" or "off"
	elseif self.choices[filter_id] then
		return value
	end
end

--Also appends each child state, e.g. fam_ak.
--Only affects MC filters with submenus. Otherwise behaves as get_state().
function SDSS.Filter:get_full_state(filter_id)
	if self:is_search(filter_id) then
		return SDSS.Search.query
	end

	local state = self:get_state(filter_id)
	if state == nil then
		return nil
	end

	if self.choices[filter_id] then
		local child_id = self:_get_child_id(filter_id)
		if child_id then
			state = state .. "_" .. self:get_full_state(child_id)
		end
	end
	return state
end

--Can be reset button.
function SDSS.Filter:locstring_button(button_name)
	return "sdss_" .. button_name
end

--Should only call this on top-filters.
function SDSS.Filter:locstring_state(filter_id)
	local filter_state = self:get_full_state(filter_id)
	if not filter_state then
		log("[SDSS] ERROR: locstring_state on bad filter.")
		return "ERROR"
	end
	return "sdss_" .. filter_id .. "_" .. filter_state
end

--Check if a filter is a submenu. Non-MC filters are never submenus.
function SDSS.Filter:_is_submenu(filter_id)
	if not self.choices[filter_id] then
		return false
	end
	return self.choices[filter_id].parent ~= nil
end

function SDSS.Filter:is_reset(button_name)
	return button_name == RESET_BUTTON_NAME
end

function SDSS.Filter:is_search(button_name)
	return button_name == SEARCH_BUTTON_NAME
end

--Returns false on invalid filter_id
function SDSS.Filter:is_toggle(filter_id)
	return type(self.defaults[filter_id]) == "boolean"
end

--Check if filter_id is active. Returns nil on invalid filter_id.
--If no filter_id, checks if any filter is active
--Do not call on subfilters.
function SDSS.Filter:is_active(filter_id)
	if filter_id ~= nil and type(filter_id) ~= "string" then
		return
	end

	if filter_id then
		if self:is_search(filter_id) then
			return SDSS.Search:is_active()
		end

		local filter_state = self:get_state(filter_id)
		if filter_state ~= nil then
			return filter_state ~= "off"
		end
		return
	end

	for k, _ in pairs(self.defaults) do
		if not self:_is_submenu(k) then
			if self:get_state(k) ~= "off" then
				return true
			end
		end
	end

	return SDSS.Search:is_active()
end

--Recursively set an MC setting.
--Changes needs to be propagated for a UI refresh.
function SDSS.Filter:_apply_mc(filter_id, value)
	local changed = false
	if SDSS.settings[filter_id] ~= value then
		SDSS.settings[filter_id] = value
		changed = true
	end

	if self:_is_submenu(filter_id) then
		local parent = self.choices[filter_id].parent
		for k, v in pairs(parent) do
			changed = self:_apply_mc(k, v) or changed
		end
	end

	--Only the top-level filter should check this.
	if changed and not self:_is_submenu(filter_id) then
		self:_check_reset_tooltip(filter_id)
	end

	return changed
end

--Show a one-time tooltip for resetting filters with right click.
function SDSS.Filter:_check_reset_tooltip(filter_id)
	if self:_is_submenu(filter_id) then
		return
	end

	if SDSS.settings.filter_tooltip_shown then
		return
	end

	if SDSS.settings[filter_id] ~= "off" then
		return
	end

	SDSS.settings.filter_tooltip_shown = true
	ncUtils.Settings:save(SDSS)

	local menu_title = managers.localization:text("sdss_dialog_title")
	local menu_message = managers.localization:text("sdss_dialog_reset_filter_tooltip")
	ncDialogs:show(menu_title, menu_message)
end

function SDSS.Filter:_build_mc_options(filter_id)
	local menu_options = {}
	local choices = self.choices[filter_id]
	for _, v in ipairs(choices) do
		local value = v
		local child_id = filter_id .. "_" .. value
		child_id = self.choices[child_id] ~= nil and child_id or nil

		local text = managers.localization:text("sdss_" .. filter_id .. "_" .. value)
		local callback
		if not child_id then
			callback = function()
				local changed = self:_apply_mc(filter_id, value)
				if changed then
					self:refresh_blackmarket_ui()
				end
			end
		else
			callback = function()
				self:_mc_handler(child_id)
			end
			text = text .. " "
		end
		table.insert(menu_options, {
			text = text,
			callback = callback,
		})
	end
	table.insert(menu_options, {
		text = managers.localization:text("dialog_cancel"),
		is_cancel_button = true,
	})
	return menu_options
end

function SDSS.Filter:_search_dialog()
	local menu_title = managers.localization:text("sdss_dialog_title")
	local menu_message = managers.localization:text("sdss_dialog_search")
	local menu_options = {
		{
			text = managers.localization:text("sdss_dialog_button_search"),
			callback = function(data)
				local text = data and data.text or ""
				SDSS.Search:process_search(text)
			end,
			is_focused_button = true,
		},
		{
			text = managers.localization:text("dialog_cancel"),
			is_cancel_button = true,
		}
	}
	local settings = {
		initial_text = SDSS.Search.query
	}
	ncDialogs:show_input(menu_title, menu_message, menu_options, settings)
end

function SDSS.Filter:_mc_handler(filter_id)
	local menu_title = managers.localization:text("sdss_dialog_title")
	local menu_message = managers.localization:text("sdss_" .. filter_id .. "_desc")
	local options = self:_build_mc_options(filter_id)

	--max_items = 8 means safe filter options fit on exactly 4 pages which is nice.
	--Also we have exactly 8 weapon categories.
	local settings = {
		page_size = 8,
		next_page_text = managers.localization:text("sdss_dialog_button_next_page"),
		first_page_text = managers.localization:text("sdss_dialog_button_first_page"),
	}
	--ncDialogs:show_paginated_classic(menu_title, menu_message, options, settings)
	ncDialogs:show_paginated(menu_title, menu_message, options, settings)
end

function SDSS.Filter:refresh_blackmarket_ui()
	SDSS.flags.reload_filters = true
	--Only took 5 years lmao
	local bmg = managers.menu_component and managers.menu_component._blackmarket_gui
	if bmg then
		managers.menu_component:post_event("item_buy")
		bmg:reload()
	end
end

function SDSS.Filter:left_click(filter_id)
	if self:is_reset(filter_id) then
		self:reset()
		self:refresh_blackmarket_ui()
		return
	elseif self:is_search(filter_id) then
		self:_search_dialog()
		return
	elseif self:is_toggle(filter_id) then
		SDSS.settings[filter_id] = not SDSS.settings[filter_id]
		self:refresh_blackmarket_ui()
		return
	else
		self:_mc_handler(filter_id)
		return
	end
end

function SDSS.Filter:right_click(filter_id)
	if self:is_reset(filter_id) then
		self:reset()
		self:refresh_blackmarket_ui()
		return
	else
		self:reset(filter_id)
		self:refresh_blackmarket_ui()
		return
	end
end

function SDSS.Filter:pass(weapon_id, skin_id, unlocked)
	--Unlocked defaults to true.
	if unlocked == nil then
		unlocked = true
	end

	--Anything not in the cache is not filtered.
	local skin_cache = SDSS:db_get_skin(skin_id)
	if not skin_cache then
		log("[SDSS] ERROR: passes_filters skin_id not found", skin_id)
		return false
	end

	--Hide unowned
	if SDSS.settings.filter_hide_unowned and not unlocked then
		return false
	end

	--Weapon filter
	do
		local state = self:get_state("filter_weapon")
		if state == "off" then
			--Nothing
		elseif state == "cat" then
			--Category
			local category = self:get_state("filter_weapon_cat")
			if category == "same" then
				--Match same category as current weapon
				if skin_cache.category ~= SDSS:db_get_weapon(weapon_id).category then
					return false
				end
			elseif skin_cache.category ~= category then
				return false
			end
		elseif state == "fam" then
			--Family
			local family = self:get_state("filter_weapon_fam")
			if skin_cache.family ~= family then
				return false
			end
		elseif state == "cor" then
			--Correct weapon
			if not SDSS:weapon_cosmetics_type_check_for_real(weapon_id, skin_id) then
				return false
			end
		end
	end

	--Safe Filter
	do
		local state = self:get_state("filter_safe")
		if state == "off" then
			--Nothing
		elseif state == "base" then
			if skin_cache.custom then
				return false
			end
		elseif state == "custom" then
			if not skin_cache.custom then
				return false
			end
		elseif skin_cache.texture_bundle_folder ~= state then
			if state == "red" and skin_id == "deagle_bling" then
				--Midas Touch is also part of First World Safe
			elseif state == "dinner" and skin_id == "ak74_rodina" then
				--Vlad's Rodina is also part of Slaughter Safe
			else
				return false
			end
		end
	end

	--Rarity filter
	do
		local state = self:get_state("filter_rarity")
		if state == "off" then
			--Nothing
		elseif skin_cache.rarity ~= state then
			return false
		end
	end

	--Search filter
	if SDSS.Search:is_active() then
		if skin_cache.search_query ~= SDSS.Search.query then
			skin_cache.search_query = SDSS.Search.query
			skin_cache.search_match = SDSS.Search:matches(
				skin_cache.weapon_search,
				skin_cache.skin_search
			)
		end

		if not skin_cache.search_match then
			return false
		end
	end

	return true
end
