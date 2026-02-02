if _G.SDSS then return end

_G.SDSS = {}
SDSS.meta = {
	mod_path = ModPath,
	save_path = SavePath,
	menu_id = "sdss_options_menu",
	menu_file = ModPath.."menu/options.json",
	save_file = SavePath.."sdss_settings.json",
}

function SDSS:save_json(path, data)
	local file = io.open(path, "w+")
	file:write(json.encode(data))
	file:close()
end

function SDSS:load_json(path)
	local file = io.open(path, "r")
	local data = json.decode(file:read("*all")) or {}
	file:close()
	return data
end

function SDSS:save_settings()
	self:save_json(self.meta.save_file, self.settings)
end

function SDSS:load_settings()
	local file = io.open(self.meta.save_file, "r")
	if file then
		local data = json.decode(file:read("*all")) or {}
		file:close()
		for k, _ in pairs(self.settings) do
			if data[k] ~= nil then
				self.settings[k] = data[k]
			end
		end
	end
end

SDSS.settings = {
	sdss_fast_preview = false,
	sdss_page_buttons_max = 35,
	do_not_warn = false,
}
SDSS.default_filters = {
	sdss_filter_sort = 1,
	sdss_filter_hide_unowned = false,
	sdss_filter_safe = 1,
	sdss_filter_rarity = 1,
	sdss_filter_weapon = 1,
}

function SDSS:set_default_filters()
	for k, v in pairs(self.default_filters) do
		self.settings[k] = v
	end
end

SDSS:set_default_filters()
SDSS:load_settings()
dofile(SDSS.meta.mod_path.."lua/weapon_families.lua")

--Menu hooks
Hooks:Add("LocalizationManagerPostInit", "SDSS-Hooks-LocalizationManagerPostInit", function(loc)
	loc:load_localization_file(SDSS.meta.mod_path.."localizations/english.json")
end)

Hooks:Add("MenuManagerInitialize", "SDSS-Hooks-MenuManagerInitialize", function(menu_manager)
	local Mod = SDSS

	MenuCallbackHandler.sdss_callback_toggle = function(self, item)
		Mod.settings[item:name()] = item:value() == "on"
	end

	MenuCallbackHandler.sdss_callback_slider_discrete = function(self, item)
		Mod.settings[item:name()] = math.floor(item:value()+0.5)
	end

	MenuCallbackHandler.sdss_callback_multi = function(self, item)
		Mod.settings[item:name()] = item:value()
	end

	MenuCallbackHandler.sdss_callback_slider = function(self, item)
		Mod.settings[item:name()] = item:value()
	end

	MenuCallbackHandler.sdss_callback_save = function(self, item)
		Mod:save_settings()
	end

	MenuHelper:LoadFromJsonFile(Mod.meta.menu_file, Mod, Mod.settings)
end)

SDSS.filters_choices = {}
SDSS.filters_choices.sdss_filter_safe = {"off", "base", "custom",
	"wwt", "buck", "surf", "grunt", "flake", "same", "smosh", "cs3", "cs4", "skf",
	"css", "cat", "ait", "nin", "cop", "cf15", "dallas", "dss", "red", "bah",
	"lones", "cola", "wac", "mxs", "sfs", "dinner", "sputnik", "burn", "pack",
}
SDSS.filters_choices.sdss_filter_rarity = {"off", "legendary", "epic", "rare", "uncommon", "common"}
SDSS.filters_choices.sdss_filter_weapon = {"off", "cat", "fam", "cor"}
SDSS.filters_choices.sdss_filter_sort = {"off", "highlow", "lowhigh", "alpha"}

--Get filter setting as a string
function SDSS:get_filter_setting(name)
	local value = self.settings[name]
	if value == nil then
		return ""
	end

	if type(value) == "number" then
		return SDSS.filters_choices[name][value]
	else
		return value and "on" or "off"
	end
end

function SDSS:is_filter_active(filter_id)
	if filter_id then
		return self:get_filter_setting(filter_id) ~= "off"
	else
		for k, _ in pairs(self.default_filters) do
			if self:get_filter_setting(k) ~= "off" then
				return true
			end
		end
	end
	return false
end

function SDSS:filter_button_handler(filter_id)
	if filter_id == "sdss_filter_reset" then
		self:set_default_filters()
		self:apply_filter_settings()
		return
	elseif filter_id == "sdss_filter_hide_unowned" then
		self.settings.sdss_filter_hide_unowned = not self.settings.sdss_filter_hide_unowned
		self:apply_filter_settings()
		return
	else
		local max_items = 8
		self:_mc_filter_handler(filter_id, max_items)
		return
	end
end

--Save filter and refresh UI
function SDSS:apply_filter_settings()
	self:save_settings()

	--Only took 5 years lmao
	local bmg = managers.menu_component and managers.menu_component._blackmarket_gui
	managers.menu_component:post_event("item_buy")
	bmg:reload()
end

function SDSS:_mc_filter_handler(filter_id, max_items, offset)
	local menu_title = managers.localization:text("sdss_dialog_title")
	local menu_message = managers.localization:text(filter_id.."_desc")

	offset = offset or 0
	max_items = max_items or 10
	local choices = self.filters_choices[filter_id]
	local filter_idx = self.settings[filter_id]

	local menu_options = {}
	local count = 0
	for idx, val in ipairs(choices) do
		if idx > offset then
			table.insert(menu_options, {
				text = managers.localization:text(filter_id.."_"..val),
				callback = function()
					if idx ~= filter_idx then
						self.settings[filter_id] = idx
						self:apply_filter_settings()
					end
				end,
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
				text = "Next Page >",
				callback = function()
					self:_mc_filter_handler(filter_id, max_items, offset + max_items)
				end,
				is_focused_button = true,
			})
		else
			table.insert(menu_options, {
				text = "<< First Page",
				callback = function()
					self:_mc_filter_handler(filter_id, max_items, 0)
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

--Get weapon ID from a weapon skin. Also checks weapon IDs list and returns parent ID if applicable.
local function get_skin_weapon_id(weapon_skin_data)
	local skin_weapon_id
	if weapon_skin_data.weapon_id then
		--Has weapon ID, easy.
		skin_weapon_id = weapon_skin_data.weapon_id
	elseif weapon_skin_data.weapon_ids then
		--If multiple weapon IDs, take first one and check if it has a parent ID.
		skin_weapon_id = weapon_skin_data.weapon_ids[1]
		if tweak_data.weapon[skin_weapon_id] and tweak_data.weapon[skin_weapon_id].parent_weapon_id then
			skin_weapon_id = tweak_data.weapon[skin_weapon_id].parent_weapon_id
		end
	end
	return skin_weapon_id
end

--Input is a skin tweak data entry
--Skin data is a reference to skin tweak data entry
function SDSS:filter_ok(weapon_id, skin_data, skin_id)
	--Weapon filter
	if self.settings.sdss_filter_weapon > 1 then
		local weapon_mode = self:get_filter_setting("sdss_filter_weapon")
		if weapon_mode == "cat" then
			--Category
			local weapon_cat = tweak_data.weapon[weapon_id] and tweak_data.weapon[weapon_id]._sdss_cat
			if weapon_cat then
				local skin_weapon_id = get_skin_weapon_id(skin_data)
				local skin_cat = tweak_data.weapon[skin_weapon_id] and tweak_data.weapon[skin_weapon_id]._sdss_cat
				if weapon_cat ~= skin_cat then
					return false
				end
			elseif not self:weapon_cosmetics_type_check_for_real(weapon_id, skin_id) then
				--If category is nil, then only correct weapon is allowed
				return false
			end
		elseif weapon_mode == "fam" then
			--Not every weapon has a family so we have to allow itself
			--Also make sure not to match nils lol
			local weapon_cat = tweak_data.weapon[weapon_id] and tweak_data.weapon[weapon_id]._sdss_fam
			if weapon_cat then
				local skin_weapon_id = get_skin_weapon_id(skin_data)
				local skin_cat = tweak_data.weapon[skin_weapon_id] and tweak_data.weapon[skin_weapon_id]._sdss_fam
				if weapon_cat ~= skin_cat then
					return false
				end
			elseif not self:weapon_cosmetics_type_check_for_real(weapon_id, skin_id) then
				--If category is nil, then only correct weapon is allowed
				return false
			end
		elseif weapon_mode == "cor" and not self:weapon_cosmetics_type_check_for_real(weapon_id, skin_id) then
			return false
		end
	end
	--Safe filter
	if self.settings.sdss_filter_safe > 1 then
		local texture_bundle_folder = self:get_filter_setting("sdss_filter_safe")
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
	if self.settings.sdss_filter_rarity > 1 then
		if skin_data.rarity ~= self:get_filter_setting("sdss_filter_rarity") then
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
