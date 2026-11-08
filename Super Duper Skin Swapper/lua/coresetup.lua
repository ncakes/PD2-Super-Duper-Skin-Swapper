if _G.SDSS then return end

---@class SDSS
_G.SDSS = {}
SDSS.meta = {
	mod_path = ModPath,
	loc_path = ModPath .. "loc/",
	language = "en",
	menu_id = "sdss_options_menu",
	menu_callback_prefix = "sdss",
	save_file = SavePath .. "sdss_settings.json",
}

---@type table<string, boolean|number|string>
SDSS.settings = {
	mini_icon_bg = true,
	fast_preview = false,
	page_buttons_max = 35,
	do_not_warn = false,
	filter_tooltip_shown = false,
}
SDSS.save_migration = {
	{
		file = SavePath .. "sdss_settings.json",
		key_map = {
			sdss_mini_icon_bg = "mini_icon_bg",
			sdss_fast_preview = "fast_preview",
			sdss_page_buttons_max = "page_buttons_max",
		}
	}
}

dofile(SDSS.meta.mod_path .. "data/categories.lua")
dofile(SDSS.meta.mod_path .. "data/weapon_part_families.lua")

dofile(SDSS.meta.mod_path .. "lua/modules/attachments.lua")
--Important: write default filters to settings by calling Filter:reset()
--Otherwise ncUtils won't load the filters because the keys are missing.
dofile(SDSS.meta.mod_path .. "lua/modules/search.lua")
dofile(SDSS.meta.mod_path .. "lua/modules/filter.lua")
SDSS.Filter:reset()
ncUtils.Settings:load(SDSS)
SDSS.Filter:validate()

SDSS.flags = {
	real_icon = false,
	lazy_cosmetics = false,
	lazy_instances = false,
	reload_filters = false,
	--focus_slot_name
}

--Menu hooks
Hooks:Add("LocalizationManagerPostInit", "SDSS-Hooks-LocalizationManagerPostInit", function(loc)
	ncUtils.Localization:load(loc, SDSS)
end)

Hooks:Add("MenuManagerInitialize", "SDSS-Hooks-MenuManagerInitialize", function(menu_manager)
	ncUtils.Menu:register_default_callbacks(SDSS)
	MenuHelper:LoadFromJsonFile(
		SDSS.meta.mod_path .. "menu/options.json",
		SDSS,
		SDSS.settings
	)
end)

--Check if OSA / HDS is active. If so, add a shortcut to the options menu.
--Check if OSA / HDS is installed. If not, add a download button.
--Put download buttons at the bottom.
--If mod is installed but not active, do nothing.
Hooks:Add("MenuManagerBuildCustomMenus", "SDSS-Hooks-MenuManagerBuildCustomMenus", function(menu_manager, nodes)
	--Check using global for the shortcuts. The mod may be installed but disabled.
	--Also make sure menu_id is defined.
	local osa_active = _G.OSA and OSA.meta and OSA.meta.menu_id
	local hds_active = _G.HideDupeSkins and HideDupeSkins.meta and HideDupeSkins.meta.menu_id
	if osa_active or hds_active then
		MenuHelper:AddDivider({
			id = "options_shortcut_divider",
			size = 16,
			menu_id = "sdss_options_menu",
			priority = -1,
		})
	end

	if osa_active then
		MenuHelper:AddButton({
			id = "osa_shortcut_button",
			title = "sdss_osa_shortcut_button_title",
			desc = "sdss_osa_shortcut_button_desc",
			callback = "sdss_callback_button",
			menu_id = "sdss_options_menu",
			priority = -2,
		})
	end

	if hds_active then
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
	ncDialogs:show(menu_title, menu_message, menu_options)
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
	ncDialogs:show(menu_title, menu_message, menu_options)
end

function SDSS:is_osa_installed()
	local mod_path = "mods/Optional Skin Attachments/"
	return _G.OSA ~= nil or ncUtils.FileIO:path_exists(mod_path)
end

function SDSS:is_hds_installed()
	local mod_path = "mods/Hide Duplicate Skins/"
	return _G.HideDupeSkins ~= nil or ncUtils.FileIO:path_exists(mod_path)
end

function SDSS:add_osa_to_downloads(callback)
	if not self:is_osa_installed() then
		local mod_folder = "Optional Skin Attachments"
		local manifest_path = self.meta.mod_path .. "data/OSA.txt"
		ncUtils.Bootstrap:blt_mod(mod_folder, manifest_path, callback)
		ncUtils.Menu:disable_item("dl_osa_button", self)
	elseif callback then
		callback()
	end
end

function SDSS:add_hds_to_downloads(callback)
	if not self:is_hds_installed() then
		local mod_folder = "Hide Duplicate Skins"
		local manifest_path = self.meta.mod_path .. "data/HDS.txt"
		ncUtils.Bootstrap:blt_mod(mod_folder, manifest_path, callback)
		ncUtils.Menu:disable_item("dl_hds_button", self)
	elseif callback then
		callback()
	end
end

function SDSS:add_osa_hds_to_updates()
	self:add_osa_to_downloads(function()
		self:add_hds_to_downloads(function()
			managers.menu:open_node("blt_download_manager")
		end)
	end)
end

--Centralize the cache.
SDSS.cache = {
	weapons = {},
	skins = {},
	instances = {},
}

--Definitions from economytweakdata
SDSS.rarity_indexes = {
	common = 1,
	uncommon = 2,
	rare = 3,
	epic = 4,
	legendary = 5,
}
SDSS.quality_indexes = {
	poor = 1,
	fair = 2,
	good = 3,
	fine = 4,
	mint = 5,
}

--Must initialize in order: add all weapons, then skins, then instances.
function SDSS:db_add_weapon(weapon_id)
	local weapon_data = tweak_data.weapon[weapon_id]
	if not weapon_data then
		return
	end

	if not weapon_data.categories then
		return
	end

	if not weapon_data.name_id then
		return
	end

	--Defaults to special
	local category = "special"
	for _, check_category in ipairs(weapon_data.categories) do
		--This table contains the main categories. Does not include akimbo, revolver, or special categories.
		if table.contains(self.categories, check_category) then
			category = check_category
			break
		end
	end

	--Family can be nil
	local family = nil
	for check_family, weapons in pairs(self.families) do
		if table.contains(weapons, weapon_id) then
			family = check_family
			break
		end
	end

	self.cache.weapons[weapon_id] = {
		category = category,
		family = family,
		weapon_search = SDSS.Search:build_search_table(
			managers.localization:text(weapon_data.name_id)
		),
	}
end

function SDSS:db_get_weapon(weapon_id)
	return self.cache.weapons[weapon_id]
end

function SDSS:db_add_skin(skin_id)
	local skin_data = tweak_data.blackmarket.weapon_skins[skin_id]
	if not skin_data then
		return
	end

	--Stolen from BlackMarketManager:is_weapon_skin_tam(skin_id)
	local is_tam = skin_data.global_value == "tam" and not skin_data.is_a_color_skin and string.match(skin_id, "tam")
	--Ignore Immortal Python (tam) and color skins.
	if is_tam or skin_data.is_a_color_skin then
		return
	end

	--This should never happen.
	--Only color skins have no weapon_id, they use weapon_ids with a blacklist instead.
	local weapon_id = skin_data.weapon_id
	if not weapon_id then
		log("[SDSS] ERROR: db_add_skin no weapon_id", skin_id)
		return
	end

	local weapon_cache = self:db_get_weapon(weapon_id)
	if not weapon_cache then
		log("[SDSS] ERROR: db_add_skin weapon_id not in cache", skin_id, weapon_id)
		return
	end

	self.cache.skins[skin_id] = {
		weapon_id = weapon_id,
		rarity = skin_data.rarity,
		rarity_index = self.rarity_indexes[skin_data.rarity],
		custom = skin_data.custom and true or false,
		texture_bundle_folder = skin_data.texture_bundle_folder,
		skin_search = SDSS.Search:build_search_table(
			managers.localization:text(skin_data.name_id)
		),
	}

	for k, v in pairs(weapon_cache) do
		self.cache.skins[skin_id][k] = v
	end
end

function SDSS:db_get_skin(skin_id)
	return self.cache.skins[skin_id]
end

function SDSS:_db_add_instance(instance_id)
	--{"bonus":false,"category":"weapon_skins","amount":1,"entry":"p226_wolf","quality":"mint"}
	local instance_data = managers.blackmarket:get_inventory_tradable()[instance_id]
	if not instance_data then
		return
	end

	if instance_data.category ~= "weapon_skins" then
		return
	end

	local skin_id = instance_data.entry
	if not skin_id then
		return
	end

	local skin_cache = self:db_get_skin(skin_id)
	if not skin_cache then
		log("[SDSS] ERROR: db_add_instance skin_id not in cache", skin_id)
		return
	end

	self.cache.instances[instance_id] = {
		skin_id = skin_id,
		quality = instance_data.quality,
		quality_index = self.quality_indexes[instance_data.quality],
		bonus = instance_data.bonus,--Boolean
		bonus_index = instance_data.bonus and 1 or 0,
	}
	for k, v in pairs(skin_cache) do
		self.cache.instances[instance_id][k] = v
	end
end

function SDSS:db_get_instance(instance_id)
	if not self.cache.instances[instance_id] then
		self:_db_add_instance(instance_id)
	end
	return self.cache.instances[instance_id]
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
