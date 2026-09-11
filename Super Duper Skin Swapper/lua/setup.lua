if _G.SDSS then return end
dofile(ModPath.."lua/ncUtils/init.lua")

_G.SDSS = {}
SDSS.meta = {
	mod_path = ModPath,
	loc_path = ModPath.."loc/",
	language = "en",
	menu_id = "sdss_options_menu",
	menu_callback_prefix = "sdss",
	menu_file = ModPath.."menu/options.json",
	save_file = SavePath.."sdss_settings.json",
}

SDSS.settings = {
	mini_icon_bg = true,
	fast_preview = false,
	page_buttons_max = 35,
	do_not_warn = false,
}
SDSS.save_migration = {
	{
		file = SavePath.."sdss_settings.json",
		key_map = {
			sdss_mini_icon_bg = "mini_icon_bg",
			sdss_fast_preview = "fast_preview",
			sdss_page_buttons_max = "page_buttons_max",
		}
	}
}

SDSS.default_filters = {
	filter_hide_unowned = false,
	filter_sort = 1,
	filter_safe = 1,
	filter_rarity = 1,
	filter_weapon = 1,
	filter_weapon_cat = 1,
	filter_weapon_fam = 1,
}
--Important: write default filters to settings on boot.
--Otherwise ncUtils won't load the filters because the keys are missing.
for k, v in pairs(SDSS.default_filters) do
	SDSS.settings[k] = v
end
ncUtils.Settings:load(SDSS)

dofile(SDSS.meta.mod_path.."data/categories.lua")

--Menu hooks
Hooks:Add("LocalizationManagerPostInit", "SDSS-Hooks-LocalizationManagerPostInit", function(loc)
	ncUtils.Localization:load(loc, SDSS)
end)

Hooks:Add("MenuManagerInitialize", "SDSS-Hooks-MenuManagerInitialize", function(menu_manager)
	ncUtils.Menu:register_default_callbacks(SDSS)
	MenuHelper:LoadFromJsonFile(SDSS.meta.menu_file, SDSS, SDSS.settings)
end)

--Check if OSA / HDS is active. If so, add a shortcut to the options menu.
--Check if OSA / HDS is installed. If not, add a download button.
--Put download buttons at the bottom.
--If mod is installed but not active, do nothing.
Hooks:Add("MenuManagerBuildCustomMenus", "SDSS-Hooks-MenuManagerBuildCustomMenus", function(menu_manager, nodes)
	--Check using global for the shortcuts. The mod may be installed but disabled.
	if _G.OSA or _G.HideDupeSkins then
		MenuHelper:AddDivider({
			id = "options_shortcut_divider",
			size = 16,
			menu_id = "sdss_options_menu",
			priority = -1,
		})
	end

	if _G.OSA then
		MenuHelper:AddButton({
			id = "osa_shortcut_button",
			title = "sdss_osa_shortcut_button_title",
			desc = "sdss_osa_shortcut_button_desc",
			callback = "sdss_callback_button",
			menu_id = "sdss_options_menu",
			priority = -2,
		})
	end

	if _G.HideDupeSkins then
		MenuHelper:AddButton({
			id = "hds_shortcut_button",
			title = "sdss_hds_shortcut_button_title",
			desc = "sdss_hds_shortcut_button_desc",
			callback = "sdss_callback_button",
			menu_id = "sdss_options_menu",
			priority = -3,
		})
	end

	if SDSS:is_osa_installed() and SDSS:is_hds_installed() then
		return
	end

	MenuHelper:AddDivider({
		id = "download_buttons_divider",
		size = 16,
		menu_id = "sdss_options_menu",
		priority = -4,
	})

	if not SDSS:is_osa_installed() then
		MenuHelper:AddButton({
			id = "dl_osa_button",
			title = "sdss_dl_osa_button_title",
			desc = "sdss_dl_osa_button_desc",
			callback = "sdss_callback_button",
			menu_id = "sdss_options_menu",
			priority = -5,
			disabled = true,
		})
	end

	if not SDSS:is_hds_installed() then
		MenuHelper:AddButton({
			id = "dl_hds_button",
			title = "sdss_dl_hds_button_title",
			desc = "sdss_dl_hds_button_desc",
			callback = "sdss_callback_button",
			menu_id = "sdss_options_menu",
			priority = -6,
			disabled = true,
		})
	end
end)

function SDSS:osa_shortcut_button_callback()
	managers.menu:open_node(OSA.meta.menu_id)
end

function SDSS:hds_shortcut_button_callback()
	managers.menu:open_node(HideDupeSkins.meta.menu_id)
end

function SDSS:dl_osa_button_callback()
	local menu_title = managers.localization:text("sdss_dialog_title")
	local menu_message = managers.localization:text("sdss_dialog_install_osa")
	local menu_options = {
		{
			text = managers.localization:text("sdss_dialog_add_to_download_manager"),
			callback = function()
				self:add_osa_to_downloads(function()
					managers.menu:open_node("blt_download_manager")
				end)
			end,
		},
		{
			text = managers.localization:text("dialog_cancel"),
			is_focused_button = true,
			is_cancel_button = true,
		}
	}
	QuickMenu:new(menu_title, menu_message, menu_options):Show()
end

function SDSS:dl_hds_button_callback()
	local menu_title = managers.localization:text("sdss_dialog_title")
	local menu_message = managers.localization:text("sdss_dialog_install_hds")
	local menu_options = {
		{
			text = managers.localization:text("sdss_dialog_add_to_download_manager"),
			callback = function()
				self:add_hds_to_downloads(function()
					managers.menu:open_node("blt_download_manager")
				end)
			end,
		},
		{
			text = managers.localization:text("dialog_cancel"),
			is_focused_button = true,
			is_cancel_button = true,
		}
	}
	QuickMenu:new(menu_title, menu_message, menu_options):Show()
end

function SDSS:is_osa_installed()
	local mod_path = "mods/Optional Skin Attachments/"
	return ncUtils.FileIO:path_exists(mod_path)
end

function SDSS:is_hds_installed()
	local mod_path = "mods/Hide Duplicate Skins/"
	return ncUtils.FileIO:path_exists(mod_path)
end

function SDSS:add_osa_to_downloads(callback)
	local mod_folder = "Optional Skin Attachments"
	local update_file_path = self.meta.mod_path .. "data/OSA.txt"
	self:add_mod_to_updates(mod_folder, update_file_path, callback)
	ncUtils.Menu:disable_item("dl_osa_button", self)
end

function SDSS:add_hds_to_downloads(callback)
	local mod_folder = "Hide Duplicate Skins"
	local update_file_path = self.meta.mod_path .. "data/HDS.txt"
	self:add_mod_to_updates(mod_folder, update_file_path, callback)
	ncUtils.Menu:disable_item("dl_hds_button", self)
end

function SDSS:add_osa_hds_to_updates()
	self:add_osa_to_downloads(function()
		self:add_hds_to_downloads(function()
			managers.menu:open_node("blt_download_manager")
		end)
	end)
end

--Safeguards against adding mods that already exist.
--Callback is always run even if the mod already exists or BLTMod:new() failed.
function SDSS:add_mod_to_updates(mod_folder, update_file_path, callback)
	if not callback then
		callback = function() end
	end

	local mod_path = "mods/" .. mod_folder .. "/"
	if ncUtils.FileIO:path_exists(mod_path) then
		callback()
		return
	end

	if not ncUtils.FileIO:copy_file(update_file_path, mod_path .. "mod.txt") then
		callback()
		return
	end

	local new_mod = BLTMod:new(mod_folder, nil, mod_path)
	if new_mod then
		new_mod:CheckForUpdates(function(cache)
			for update_id, data in pairs(cache) do
				if data.requires_update then
					BLT.Downloads:add_pending_download(data.update)
				end
			end
			callback()
		end)
		return
	end

	log("SDSS:add_mod_to_updates copy succeeded but failed to create mod", mod_path .. "mod.txt")
	callback()
end

SDSS.filter_buttons = {
	"filter_reset",--Reset button, must be first
	"filter_hide_unowned",--Toggle
	"filter_sort",
	"filter_safe",
	"filter_rarity",
	"filter_weapon",
}

--First entry in a main multiple choice filter must be "off".
SDSS.filter_choices = {}
SDSS.filter_choices.filter_sort = {"off", "highlow", "lowhigh", "alpha"}
SDSS.filter_choices.filter_safe = {"off", "base", "custom",
	"wwt", "buck", "surf", "grunt", "flake", "same", "smosh", "cs3", "cs4", "skf",
	"css", "cat", "ait", "nin", "cop", "cf15", "dallas", "dss", "red", "bah",
	"lones", "cola", "wac", "mxs", "sfs", "dinner", "sputnik", "burn", "pack",
}
SDSS.filter_choices.filter_rarity = {"off", "legendary", "epic", "rare", "uncommon", "common"}
SDSS.filter_choices.filter_weapon = {"off", "cat", "fam", "cor"}
SDSS.filter_choices.filter_weapon_cat = {is_submenu=true, "same", "pistol", "shotgun", "smg", "assault_rifle", "lmg", "snp", "special"}
SDSS.filter_choices.filter_weapon_fam = {is_submenu=true, "ak", "car", "mossberg"}

--Reset button must be first button.
function SDSS:filter_is_reset_button(button_name)
	return button_name == self.filter_buttons[1]
end

--Returns false on invalid filter_id
function SDSS:filter_is_toggle(filter_id)
	return type(self.settings[filter_id]) == "boolean"
end

function SDSS:filter_is_multi_choice(filter_id)
	return self.filter_choices[filter_id] ~= nil
end

function SDSS:filter_is_submenu(filter_id)
	local choices = self.filter_choices[filter_id]
	return choices ~= nil and choices.is_submenu == true
end

--Can be the reset button.
function SDSS:filter_button_locstring(button_name)
	return "sdss_" .. button_name
end

--Only for actual filters, not reset button.
function SDSS:filter_state_locstring(filter_id)
	local filter_state = self:get_filter_state(filter_id)
	if not filter_state then
		return "ERROR"
	end
	return "sdss_" .. filter_id .. "_" .. filter_state
end

--Check if filter_id is active. Returns nil on invalid filter_id.
--If no filter_id, checks if any filter is active
--Do not call on subfilters.
function SDSS:filter_is_active(filter_id)
	if filter_id ~= nil and type(filter_id) ~= "string" then
		return
	end

	--Check a specific filter_id
	if filter_id then
		local filter_state = self:get_filter_state(filter_id)
		if filter_state ~= nil then
			return filter_state ~= "off"
		end
		return
	end

	--No filter_id, check all filters
	for k, _ in pairs(self.default_filters) do
		if not self:filter_is_submenu(k) then
			if self:get_filter_state(k) ~= "off" then
				return true
			end
		end
	end

	return false
end

--Resets filter_id if specified.
--Resets all filters otherwise.
--Does not refresh UI. Does not check if filter is on.
function SDSS:reset_filter(filter_id)
	if filter_id then
		if self.default_filters[filter_id] ~= nil then
			self.settings[filter_id] = self.default_filters[filter_id]
		end
		return
	end

	for k, v in pairs(self.default_filters) do
		self.settings[k] = v
	end
end

--Get filter state as a string.
--Returns nil on invalid filter_id or invalid filter choice.
--Boolean filters return "on" or "off"
--Multiple choice filters have submenu choices appended e.g. fam_ak
function SDSS:get_filter_state(filter_id)
	local result = self:_get_filter_state_raw(filter_id)
	if result == nil then
		return
	end

	if type(result) == "boolean" then
		return result and "on" or "off"
	elseif type(result) == "table" then
		local mc_string = result[1]
		for i = 2, #result do
			mc_string = mc_string .. "_" .. result[i]
		end
		return mc_string
	end
end

--Get raw filter state.
--Boolean filters are returned directly.
--Multiple choice filters return a table of the main choice and any submenu choices.
function SDSS:_get_filter_state_raw(filter_id, result)
	local value = self.settings[filter_id]
	if value == nil then
		return
	end

	if type(value) == "boolean" then
		return value
	elseif type(value) == "number" then
		return self:_get_mc_filter_state(filter_id, result)
	end
end

--Returns a table of the main choice and any submenu choices.
function SDSS:_get_mc_filter_state(filter_id, result)
	result = result or {}
	local idx = self.settings[filter_id]
	local val = self.filter_choices[filter_id][idx]
	if val == nil then
		return
	end

	table.insert(result, val)

	local submenu_id = filter_id .. "_" .. val
	if self.filter_choices[submenu_id] then
		return self:_get_mc_filter_state(submenu_id, result)
	end

	return result
end

--Saving filters moved to MenuComponentManager:close_blackmarket_gui
--No need to write the changes to disk every time the user changes a setting.
function SDSS:refresh_blackmarket_ui()
	--Only took 5 years lmao
	local bmg = managers.menu_component and managers.menu_component._blackmarket_gui
	if bmg then
		managers.menu_component:post_event("item_buy")
		bmg:reload()
	end
end

function SDSS:filter_button_handler(filter_id)
	if self:filter_is_reset_button(filter_id) then
		self:reset_filter()
		self:refresh_blackmarket_ui()
		return
	elseif self:filter_is_toggle(filter_id) then
		self.settings[filter_id] = not self.settings[filter_id]
		self:refresh_blackmarket_ui()
		return
	else
		--max_items = 8 means safe filter options fit on exactly 4 pages which is nice.
		--Also we have exactly 8 weapon categories.
		local max_items = 8
		self:_mc_filter_handler(filter_id, max_items)
		return
	end
end

--Only one submenu allowed.
function SDSS:_mc_filter_handler(filter_id, max_items, offset, parent_filter_id, parent_choice_idx)
	local menu_title = managers.localization:text("sdss_dialog_title")
	local menu_message = managers.localization:text("sdss_"..(parent_filter_id or filter_id).."_desc")

	offset = offset or 0
	max_items = max_items or 10

	local choices = self.filter_choices[filter_id]

	local menu_options = {}
	local count = 0
	for idx, val in ipairs(choices) do
		if idx > offset then
			local choice_idx = idx

			local submenu_id = filter_id .. "_" .. val
			local has_submenu = self.filter_choices[submenu_id] ~= nil

			local callback
			if has_submenu then
				callback = function()
					self:_mc_filter_handler(submenu_id, max_items, nil, filter_id, choice_idx)
				end
			else
				callback = function()
					local changed = false
					if parent_filter_id and self.settings[parent_filter_id] ~= parent_choice_idx then
						self.settings[parent_filter_id] = parent_choice_idx
						changed = true
					end
					if self.settings[filter_id] ~= choice_idx then
						self.settings[filter_id] = choice_idx
						changed = true
					end
					if changed then
						self:refresh_blackmarket_ui()
					end
				end
			end
			table.insert(menu_options, {
				text = managers.localization:text("sdss_"..filter_id.."_"..val),
				callback = callback,
			})
			count = count + 1
		end
		if count == max_items then
			break
		end
	end

	--More choices than can fit on a page
	if #choices > max_items then
		if #choices > offset + max_items then
			table.insert(menu_options, {
				text = managers.localization:text("sdss_dialog_next_page") .. " >",
				callback = function()
					self:_mc_filter_handler(filter_id, max_items, offset + max_items, parent_filter_id, parent_choice_idx)
				end,
				is_focused_button = true,
			})
		else
			table.insert(menu_options, {
				text = "<< " .. managers.localization:text("sdss_dialog_first_page"),
				callback = function()
					self:_mc_filter_handler(filter_id, max_items, 0, parent_filter_id, parent_choice_idx)
				end,
				is_focused_button = true,
			})
		end
	end

	table.insert(menu_options, {
		text = managers.localization:text("dialog_cancel"),
		is_cancel_button = true,
		is_focused_button = #choices <= max_items,
	})
	QuickMenu:new(menu_title, menu_message, menu_options):Show()
end

--Get the SDSS category from a list of categories
function SDSS:get_sdss_category(categories)
	for _, category in ipairs(categories) do
		--This table contains the main categories.
		--Does not include akimbo, revolver, and special categories.
		if table.contains(SDSS.categories, category) then
			return category
		end
	end
	--If we didn't return yet, it must be a special weapon
	return "special"
end

--Input is a skin tweak data entry
--Skin data is a reference to skin tweak data entry
function SDSS:passes_filters(weapon_id, skin_data, skin_id)
	--Weapon filter
	if self.settings.filter_weapon > 1 then
		local filter_state_raw = self:_get_filter_state_raw("filter_weapon")
		local weapon_mode = filter_state_raw[1]
		if weapon_mode == "cat" then
			--Category

			if filter_state_raw[2] == "same" then
				--Match same category as current weapon
				local weapon_cat = tweak_data.weapon[weapon_id] and tweak_data.weapon[weapon_id]._sdss_cat
				if weapon_cat then
					if weapon_cat ~= skin_data._sdss_cat then
						return false
					end
				elseif not self:weapon_cosmetics_type_check_for_real(weapon_id, skin_id) then
					--This should never happen.
					--But if category is nil, then only correct weapon is allowed.
					return false
				end
			elseif skin_data._sdss_cat ~= filter_state_raw[2] then
				--Match filter state
				return false
			end
		elseif weapon_mode == "fam" then
			if skin_data._sdss_fam ~= filter_state_raw[2] then
				return false
			end
		elseif weapon_mode == "cor" and not self:weapon_cosmetics_type_check_for_real(weapon_id, skin_id) then
			return false
		end
	end
	--Safe filter
	if self.settings.filter_safe > 1 then
		local texture_bundle_folder = self:get_filter_state("filter_safe")
		if texture_bundle_folder == "base" then
			if skin_data.custom == true then
				return false
			end
		elseif texture_bundle_folder == "custom" then
			if skin_data.custom ~= true then
				return false
			end
		else
			if skin_data.texture_bundle_folder ~= texture_bundle_folder then
				if texture_bundle_folder == "red" and skin_id == "deagle_bling" then
					--Midas Touch is also part of First World Safe
				elseif texture_bundle_folder == "dinner" and skin_id == "ak74_rodina" then
					--Vlad's Rodina is also part of Slaughter Safe
				else
					return false
				end
			end
		end
	end
	--Rarity filter
	if self.settings.filter_rarity > 1 then
		if skin_data.rarity ~= self:get_filter_state("filter_rarity") then
			return false
		end
	end
	return true
end

--Actually check if it's the right skin. Fixed mistake in lua dump.
--Copied from BlackMarketManager:weapon_cosmetics_type_check
function SDSS:weapon_cosmetics_type_check_for_real(weapon_id, skin_id)
	local weapon_skin = tweak_data.blackmarket.weapon_skins[skin_id]
	local found_weapon = false
	if weapon_skin then
		--Fixed
		found_weapon = (weapon_skin.weapon_id == weapon_id) or (weapon_skin.weapon_ids and table.contains(weapon_skin.weapon_ids, weapon_id))
		if weapon_skin.use_blacklist then
			found_weapon = not found_weapon
		end
	end
	return found_weapon
end

--For standalone without OSA
function SDSS:remove_blueprints()
	local skin_tweak = tweak_data.blackmarket.weapon_skins
	for _, k in pairs(self.blueprint_skin_ids or {}) do
		skin_tweak[k].default_blueprint = nil
	end
end
function SDSS:restore_blueprints()
	local skin_tweak = tweak_data.blackmarket.weapon_skins
	for _, k in pairs(self.blueprint_skin_ids or {}) do
		skin_tweak[k].default_blueprint = skin_tweak[k]._sdss_blueprint
	end
end
