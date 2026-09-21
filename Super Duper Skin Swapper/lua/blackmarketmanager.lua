_G[ModPath] = _G[ModPath] or {}
if _G[ModPath][RequiredScript] then return end
_G[ModPath][RequiredScript] = true

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
	--Set lazy just before BlackMarketGui:choose_weapon_mods_callback.
	--All skins will fail the type check. Revert before BlackMarketGuiTabItem:init.
	--This way the vanilla choose_weapon_mods_callback gets no instances to process.
	return not SDSS.flags.lazy_instances
end

--Filtering here is very inefficient because it gets called way too much.
--The game uses this to check if a skin mod-icon should be made in your inventory lmfao.
--Also we need the whole list for real-time filters.
function BlackMarketManager:get_cosmetics_by_weapon_id(weapon_id)
	--This flag means the game is calling this function for the sole purpose of creating mini-icons
	--We just need to return anything so the icon gets created.
	if SDSS.flags.lazy_cosmetics then
		SDSS.flags.lazy_cosmetics = false
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

	if skin_data and not skin_data.is_a_color_skin then
		--For forcing real skin icons in weapon customization
		if SDSS.flags.real_icon then
			return orig_BlackMarketManager_get_weapon_icon_path(self, skin_data.weapon_id, cosmetics)
		end

		--Default weapon with rarity background for swapped skins.
		if not SDSS:weapon_cosmetics_type_check_for_real(weapon_id, skin_id) then
			local rarity = skin_data.rarity or "common"
			local rarity_path = tweak_data.economy.rarities[rarity] and tweak_data.economy.rarities[rarity].bg_texture
			local texture_path, _ = orig_BlackMarketManager_get_weapon_icon_path(self, weapon_id, nil)
			return texture_path, rarity_path
		end
	end

	return orig_BlackMarketManager_get_weapon_icon_path(self, weapon_id, cosmetics)
end

if _G.OSA then
	return
end

local function safe_get_part_data(part_id)
	return tweak_data and tweak_data.weapon and tweak_data.weapon.factory and tweak_data.weapon.factory.parts and tweak_data.weapon.factory.parts[part_id]
end

local function can_use_part(part_id)
	local part_data = safe_get_part_data(part_id)
	if not part_data then
		--We tried.
		return true
	end

	--BeardLib parts, do nothing.
	if part_data.custom then
		return true
	end

	--Legendary part.
	--U242.1 has added the unatainable tag to the Plush Phoenix Upper/Lower Body.
	if part_data.unatainable then
		return false
	end

	--Unowned DLC
	if part_data.dlc and not managers.dlc:is_dlc_unlocked(part_data.dlc) then
		return false
	end

	return true
end

--Check for legendary and unowned DLC parts in a blueprint.
--Needed in case people didn't install / uninstalled OSA.
local function has_invalid_parts(blueprint)
	for _, part_id in ipairs(blueprint) do
		if not can_use_part(part_id) then
			return true
		end
	end
	return false
end

--Delete unusable parts from a blueprint.
local function clean_blueprint(blueprint)
	local cleaned = {}
	for _, part_id in ipairs(blueprint) do
		if can_use_part(part_id) then
			table.insert(cleaned, part_id)
		end
	end
	return cleaned
end

local function get_part_global_value(part_id)
	local part_data = safe_get_part_data(part_id)
	if not part_data then
		--We tried
		return
	end

	--Handle custom parts
	if part_data.custom then
		return part_data.global_value or "normal"
	end

	return part_data.dlc and managers.dlc:dlc_to_global_value(part_data.dlc) or "normal"
end

--SDSS needs to update global values if you run it without OSA.
--Blueprints are removed when modifying weapons, BlackMarketManager:modify_weapon will assign wrong global value to removed parts if we don't do this.
local function set_global_values(crafted)
	local factory_id = crafted and crafted.factory_id
	local vanilla_parts = factory_id and managers.weapon_factory:get_default_blueprint_by_factory_id(factory_id)
	if not vanilla_parts then
		return
	end

	crafted.global_values = {}
	for _, part_id in ipairs(crafted.blueprint) do
		if not table.contains(vanilla_parts, part_id) then
			crafted.global_values[part_id] = get_part_global_value(part_id)
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

local function warn_blueprint_reset()
	local menu_title = managers.localization:text("sdss_dialog_title")
	local menu_message = managers.localization:text("sdss_dialog_blueprint_reset")

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
	if not update_weapon_unit then
		return
	end

	local crafted = self._global.crafted_items[category] and self._global.crafted_items[category][slot]
	if not crafted or not crafted.blueprint then
		return
	end

	local old_cosmetic_id = crafted.cosmetics and crafted.cosmetics.id
	local new_cosmetic_id = cosmetics and cosmetics.id
	if not old_cosmetic_id or not new_cosmetic_id then
		return
	end

	--Skip check when going to the same skin.
	if old_cosmetic_id == new_cosmetic_id then
		return
	end

	--Skip check if old skin has no parts.
	local old_cosmetic_data = old_cosmetic_id and tweak_data.blackmarket.weapon_skins[old_cosmetic_id]
	if not old_cosmetic_data or not old_cosmetic_data._sdss_blueprint then
		return
	end

	if crafted.blueprint and has_invalid_parts(crafted.blueprint) then
		crafted.blueprint = clean_blueprint(crafted.blueprint)
		self:add_crafted_weapon_blueprint_to_inventory(category, slot, {})
		crafted.blueprint = deep_clone(managers.weapon_factory:get_default_blueprint_by_factory_id(crafted.factory_id))
		crafted.global_values = {}
		warn_blueprint_reset()
	end
end)

Hooks:PreHook(BlackMarketManager, "on_remove_weapon_cosmetics", "SDSS-PreHook-BlackMarketManager:on_remove_weapon_cosmetics", function(self, category, slot, skip_update)
	if skip_update then
		return
	end

	local crafted = self._global.crafted_items[category] and self._global.crafted_items[category][slot]
	if not crafted or not crafted.blueprint then
		return
	end

	--Skip check if old skin has no parts.
	local old_cosmetic_id = crafted.cosmetics and crafted.cosmetics.id
	local old_cosmetic_data = old_cosmetic_id and tweak_data.blackmarket.weapon_skins[old_cosmetic_id]
	if not old_cosmetic_data or not old_cosmetic_data._sdss_blueprint then
		return
	end

	if crafted.blueprint and has_invalid_parts(crafted.blueprint) then
		crafted.blueprint = clean_blueprint(crafted.blueprint)
		self:add_crafted_weapon_blueprint_to_inventory(category, slot, {})
		crafted.blueprint = deep_clone(managers.weapon_factory:get_default_blueprint_by_factory_id(crafted.factory_id))
		crafted.global_values = {}
		warn_blueprint_reset()
	end
end)

Hooks:PreHook(BlackMarketManager, "on_sell_weapon", "SDSS-PreHook-BlackMarketManager:on_sell_weapon", function(self, category, slot, skip_verification)
	if skip_verification then
		return
	end

	local crafted = self._global.crafted_items[category] and self._global.crafted_items[category][slot]
	if not crafted or not crafted.blueprint then
		return
	end

	--Remove skin so attachments are added to inventory. Sanitize blueprint.
	crafted.cosmetics = nil
	crafted.blueprint = clean_blueprint(crafted.blueprint)
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
