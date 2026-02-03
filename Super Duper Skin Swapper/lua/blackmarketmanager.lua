--Functions which call BlackMarketManager:weapon_cosmetics_type_check(...)
--BlackMarketManager:get_cosmetics_by_weapon_id(weapon_id)
	--Returns the tweak_data of compatible skins, tries to use parent_weapon_id if present
	--Used to populate all possible weapon skins/colors, including unowned, for crafting
	--Hides the weapon skin tab if empty.
	--Also used by the game to check if a skin mod-icon should be made in your inventory lmfao.
--BlackMarketManager:get_cosmetics_instances_by_weapon_id(weapon_id)
	--Returns list of all Steam item instance_id matching the weapon
	--Hide Duplicate Skins hijacks this to only show one copy per skin
--BlackMarketManager:get_weapon_skins(weapon_id)
	--Returns the tweak_data of compatible skins
	--Used in InventoryIconCreator, not relevant
--BlackMarketManager:_set_weapon_cosmetics(...)
	--Sanity check before applying a skin. Skips on fail.
function BlackMarketManager:weapon_cosmetics_type_check(weapon_id, weapon_skin_id)
	--yolo
	return true
end

--Filtering here is very inefficient because it gets called way too much.
--The game uses this to check if a skin mod-icon should be made in your inventory lmfao.
--Also we need the whole list for real-time filters.
function BlackMarketManager:get_cosmetics_by_weapon_id(weapon_id)
	--This flag means the game is calling this function for the sole purpose of creating mini-icons
	--We just need to return anything so the icon gets created.
	if SDSS._lazy then
		SDSS._lazy = false
		return {color_tan_khaki = tweak_data.blackmarket.weapon_skins["color_tan_khaki"]}
	end

	return clone(tweak_data.blackmarket.weapon_skins)
end

--When using a swapped skin, put the default weapon icon over the rarity background
--Use the real type check in SDSS. OSA will disable it's own get_weapon_icon_path if it detects SDSS.
--Actually OSA uses the native type check which always passes and does nothing so it would be fine either way.
local orig_BlackMarketManager_get_weapon_icon_path = BlackMarketManager.get_weapon_icon_path
function BlackMarketManager:get_weapon_icon_path(weapon_id, cosmetics)
	local skin_id = cosmetics and cosmetics.id
	local skin_data = skin_id and tweak_data.blackmarket.weapon_skins[skin_id]
	if not skin_data or skin_data.is_a_color_skin then
		return orig_BlackMarketManager_get_weapon_icon_path(self, weapon_id, cosmetics)
	end

	local texture_path, rarity_path = nil
	if SDSS._force_real then
		--Don't return yet, might have to fix custom weapon icons
		texture_path, rarity_path = orig_BlackMarketManager_get_weapon_icon_path(self, skin_data.weapon_id, cosmetics)
	elseif not SDSS:weapon_cosmetics_type_check_for_real(weapon_id, skin_id) then
		--Default icon, can return immediately
		local rarity = skin_data.rarity or "common"
		local rarity_path = tweak_data.economy.rarities[rarity] and tweak_data.economy.rarities[rarity].bg_texture
		local texture_path, _ = orig_BlackMarketManager_get_weapon_icon_path(self, weapon_id, nil)
		return texture_path, rarity_path
	else
		texture_path, rarity_path = orig_BlackMarketManager_get_weapon_icon_path(self, weapon_id, cosmetics)
	end

	-- U242+ uses suffix "<skin>_<weapon_id>" when the cosmetic isn't the skin's base weapon.
	-- The path has also moved from dlcs/<bundle_folder> to dlcs/cash/safes/<bundle_folder>
	-- Leaving this for custom weapon skins that are using the old path.
	if texture_path and not DB:has(Idstring("texture"), Idstring(texture_path)) then
		local guis_catalog = "guis/"
		local bundle_folder = skin_data.texture_bundle_folder
		if bundle_folder then
			guis_catalog = guis_catalog .. "dlcs/" .. tostring(bundle_folder) .. "/"
		end
		local fallback_path = guis_catalog .. "weapon_skins/" .. tostring(skin_id)
		if DB:has(Idstring("texture"), Idstring(fallback_path)) then
			texture_path = fallback_path
		end
	end
	return texture_path, rarity_path
end

function BlackMarketManager:get_weapon_icon_path_old(weapon_id, cosmetics)
	--Restoration
	if SDSS.force_real then
		local skin_id = cosmetics and cosmetics.id
		local skin_data = skin_id and tweak_data.blackmarket.weapon_skins[skin_id]
		if skin_data and not skin_data.is_a_color_skin then
			return orig_BlackMarketManager_get_weapon_icon_path(self, skin_data.weapon_id, cosmetics)
		end
	end

	local skin_id = cosmetics and cosmetics.id
	local skin_data = skin_id and tweak_data.blackmarket.weapon_skins[skin_id]
	if skin_data and not skin_data.is_a_color_skin and not SDSS:weapon_cosmetics_type_check_for_real(weapon_id, skin_id) then
		local rarity = skin_data.rarity or "common"
		local rarity_path = tweak_data.economy.rarities[rarity] and tweak_data.economy.rarities[rarity].bg_texture
		local texture_path, _ = orig_BlackMarketManager_get_weapon_icon_path(self, weapon_id, nil)
		return texture_path, rarity_path
	end
	-- U242+ uses suffix "<skin>_<weapon_id>" when the cosmetic isn't the skin's base weapon.
	-- The path has also moved from dlcs/<bundle_folder> to dlcs/cash/safes/<bundle_folder>
	-- Leaving this for custom weapon skins that are using the old path.
	local texture_path, rarity_path = orig_BlackMarketManager_get_weapon_icon_path(self, weapon_id, cosmetics)
	if texture_path and not DB:has(Idstring("texture"), Idstring(texture_path)) then
		if skin_data and not skin_data.is_a_color_skin then
			local guis_catalog = "guis/"
			local bundle_folder = skin_data.texture_bundle_folder
			if bundle_folder then
				guis_catalog = guis_catalog .. "dlcs/" .. tostring(bundle_folder) .. "/"
			end
			local fallback_path = guis_catalog .. "weapon_skins/" .. tostring(skin_id)
			if DB:has(Idstring("texture"), Idstring(fallback_path)) then
				texture_path = fallback_path
			end
		end
	end
	return texture_path, rarity_path
end

if _G.OSA then
	return
end

--SDSS needs to update global values if you run it without OSA.
--Blueprints are removed when modifying weapons, BlackMarketManager:modify_weapon will assign wrong global value to removed parts if we don't do this.
local function set_global_values(crafted)
	local vanilla_parts = managers.weapon_factory:get_default_blueprint_by_factory_id(crafted.factory_id)
	local parts_tweak = tweak_data.weapon.factory.parts
	crafted.global_values = {}
	for _, part_id in pairs(crafted.blueprint) do
		if not table.contains(vanilla_parts, part_id) then
			local dlc = parts_tweak[part_id] and parts_tweak[part_id].dlc
			local global_value = dlc and managers.dlc:dlc_to_global_value(dlc) or "normal"
			crafted.global_values[part_id] = global_value
		end
	end
end

Hooks:PostHook(BlackMarketManager, "load", "SDSS-PostHook-BlackMarketManager:load", function(self, ...)
	for _, category in ipairs({"primaries", "secondaries"}) do
		if self._global.crafted_items[category] then
			for slot, crafted in pairs(self._global.crafted_items[category]) do
				set_global_values(crafted)
			end
		end
	end
end)

Hooks:PostHook(BlackMarketManager, "init_finalize", "SDSS-PostHook-BlackMarketManager:init_finalize", function(self, ...)
	for _, category in ipairs({"primaries", "secondaries"}) do
		if self._global.crafted_items[category] then
			for slot, crafted in pairs(self._global.crafted_items[category]) do
				set_global_values(crafted)
			end
		end
	end
end)

--Check for legendary parts in a blueprint. Needed in case people didn't install / uninstalled OSA.
--U242.1 has added the unatainable tag to the Plush Phoenix Upper/Lower Body
local function has_legendary(blueprint)
	local tweak_parts = tweak_data.weapon.factory.parts
	for _, part_id in pairs(blueprint) do
		if tweak_parts[part_id] and tweak_parts[part_id].unatainable then
			return true
		end
	end
	return false
end

local function warn_legend()
	local menu_title = managers.localization:text("sdss_dialog_title")
	local menu_message = "Your weapon was reset to the default configuration due to using legendary attachments without the corresponding skin.\n\nDownload Optional Skin Attachments from ModWorkshop if you want to customize legendary skins safely."

	local menu_options = {
		{
			text = managers.localization:text("dialog_ok"),
			is_cancel_button = true,
			is_focused_button = true,
		}
	}
	QuickMenu:new(menu_title, menu_message, menu_options):Show()
end

Hooks:PreHook(BlackMarketManager, "_set_weapon_cosmetics", "SDSS-PreHook-BlackMarketManager:_set_weapon_cosmetics", function(self, category, slot, cosmetics, update_weapon_unit)
	local crafted = self._global.crafted_items[category] and self._global.crafted_items[category][slot]
	if not crafted then
		return
	end

	--Revert to default blueprint if legendary parts and no OSA
	local old_cosmetic_id = crafted.cosmetics and crafted.cosmetics.id
	local old_cosmetic_data = old_cosmetic_id and tweak_data.blackmarket.weapon_skins[old_cosmetic_id]
	if old_cosmetic_data and old_cosmetic_data._sdss_is_legendary then
		if old_cosmetic_id ~= cosmetics.id and has_legendary(crafted.blueprint) then
			local skin_blueprint = deep_clone(old_cosmetic_data._sdss_blueprint)
			if old_cosmetic_data.special_blueprint and old_cosmetic_data.special_blueprint[crafted.weapon_id] then
				table.list_append(skin_blueprint, old_cosmetic_data.special_blueprint[crafted.weapon_id])
			end
			self:add_crafted_weapon_blueprint_to_inventory(category, slot, skin_blueprint)
			crafted.blueprint = deep_clone(managers.weapon_factory:get_default_blueprint_by_factory_id(crafted.factory_id))
			crafted.global_values = {}
			if update_weapon_unit then
				warn_legend()
			end
		end
	end
end)

Hooks:PreHook(BlackMarketManager, "on_remove_weapon_cosmetics", "SDSS-PostHook-BlackMarketManager:on_remove_weapon_cosmetics", function(self, category, slot, skip_update)
	local crafted = self._global.crafted_items[category] and self._global.crafted_items[category][slot]
	if not crafted then
		return
	end

	local old_cosmetic_id = crafted.cosmetics and crafted.cosmetics.id
	local old_cosmetic_data = old_cosmetic_id and tweak_data.blackmarket.weapon_skins[old_cosmetic_id]
	if old_cosmetic_data and old_cosmetic_data._sdss_is_legendary then
		if has_legendary(crafted.blueprint) then
			local skin_blueprint = deep_clone(old_cosmetic_data._sdss_blueprint)
			if old_cosmetic_data.special_blueprint and old_cosmetic_data.special_blueprint[crafted.weapon_id] then
				table.list_append(skin_blueprint, old_cosmetic_data.special_blueprint[crafted.weapon_id])
			end
			self:add_crafted_weapon_blueprint_to_inventory(category, slot, skin_blueprint)
			crafted.blueprint = deep_clone(managers.weapon_factory:get_default_blueprint_by_factory_id(crafted.factory_id))
			crafted.global_values = {}
			if not skip_update then
				warn_legend()
			end
		end
	end
end)

--Remove locked name after applying legendary skin
Hooks:PostHook(BlackMarketManager, "_set_weapon_cosmetics", "SDSS-PostHook-BlackMarketManager:_set_weapon_cosmetics", function(self, category, slot, cosmetics, update_weapon_unit)
	local crafted = self._global.crafted_items[category] and self._global.crafted_items[category][slot]
	if crafted then
		crafted.locked_name = nil
	end
end)

--Remove locked name after removing legendary skin
Hooks:PostHook(BlackMarketManager, "on_remove_weapon_cosmetics", "SDSS-PostHook-BlackMarketManager:on_remove_weapon_cosmetics", function(self, category, slot, skip_update)
	local crafted = self._global.crafted_items[category] and self._global.crafted_items[category][slot]
	if crafted then
		crafted.locked_name = nil
	end
end)
