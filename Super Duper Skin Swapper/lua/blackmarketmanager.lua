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

--In standalone mode, blueprints are removed when modifying weapons.
--SDSS needs to repair global values.
--Otherwise, BlackMarketManager:modify_weapon will assign wrong global value to removed parts.
Hooks:PostHook(BlackMarketManager, "load", "SDSS-PostHook-BlackMarketManager:load", function(self, ...)
	for _, category in ipairs({"primaries", "secondaries"}) do
		for slot, crafted in pairs(self._global.crafted_items[category] or {}) do
			SDSS.Attachments:set_global_values(crafted)
		end
	end
end)

Hooks:PreHook(BlackMarketManager, "_set_weapon_cosmetics", "SDSS-PreHook-BlackMarketManager:_set_weapon_cosmetics", function(self, category, slot, cosmetics, update_weapon_unit)
	local crafted = self:get_crafted_category_slot(category, slot)
	if not crafted or not crafted.blueprint then
		return
	end

	local old_cosmetic_id = crafted.cosmetics and crafted.cosmetics.id
	if not old_cosmetic_id then
		return
	end

	local new_cosmetic_id = cosmetics and cosmetics.id
	--Skip when going to the same skin.
	if old_cosmetic_id == new_cosmetic_id then
		return
	end

	--Skip if old skin has no parts.
	--Important: check _sdss_blueprint because default_blueprint is suppressed in crafting.
	local old_cosmetic_data = old_cosmetic_id and tweak_data.blackmarket.weapon_skins[old_cosmetic_id]
	if not old_cosmetic_data or not old_cosmetic_data._sdss_blueprint then
		return
	end

	local silent = not update_weapon_unit
	SDSS.Attachments:reset_if_invalid(crafted, category, slot, silent)
end)

--The game can automatically call this to remove skins that don't exist or you don't own.
--If we are not in weapon customization, default_blueprint will be set.
--Remove for this single entry and restore afterwards.
Hooks:PreHook(BlackMarketManager, "on_remove_weapon_cosmetics", "SDSS-PreHook-BlackMarketManager:on_remove_weapon_cosmetics", function(self, category, slot, skip_update)
	local crafted = self:get_crafted_category_slot(category, slot)
	if not crafted or not crafted.blueprint then
		return
	end

	--Skip if old skin has no parts.
	--Important: check _sdss_blueprint because default_blueprint is suppressed in crafting.
	local old_cosmetic_id = crafted.cosmetics and crafted.cosmetics.id
	local old_cosmetic_data = old_cosmetic_id and tweak_data.blackmarket.weapon_skins[old_cosmetic_id]
	if not old_cosmetic_data or not old_cosmetic_data._sdss_blueprint then
		return
	end

	--Clean up invalid attachments before the skin is removed.
	local silent = skip_update and true or false
	SDSS.Attachments:reset_if_invalid(crafted, category, slot, silent)

	if old_cosmetic_data.default_blueprint then
		SDSS.Attachments.restore_skin = old_cosmetic_id
		old_cosmetic_data.default_blueprint = nil
	end
end)

Hooks:PostHook(BlackMarketManager, "on_remove_weapon_cosmetics", "SDSS-PostHook-BlackMarketManager:on_remove_weapon_cosmetics", function(self, category, slot, skip_update)
	local skin_id = SDSS.Attachments.restore_skin
	SDSS.Attachments.restore_skin = nil
	if skin_id then
		local skin_data = tweak_data.blackmarket.weapon_skins[skin_id]
		skin_data.default_blueprint = skin_data._sdss_blueprint
	end

	local crafted = self:get_crafted_category_slot(category, slot)
	if not crafted then
		return
	end

	--Bugfix: locked name is not reset when skin is removed in base game.
	crafted.locked_name = nil
end)

Hooks:PreHook(BlackMarketManager, "on_sell_weapon", "SDSS-PreHook-BlackMarketManager:on_sell_weapon", function(self, category, slot, skip_verification)
	local crafted = self:get_crafted_category_slot(category, slot)
	if not crafted or not crafted.blueprint then
		return
	end

	--Remove skin so attachments are added to inventory. Sanitize blueprint.
	local skin_id = crafted.cosmetics and crafted.cosmetics.id
	local skin_data = skin_id and tweak_data.blackmarket.weapon_skins[skin_id]
	if skin_data and skin_data.default_blueprint then
		crafted.cosmetics = nil
		if SDSS.Attachments:has_invalid_parts(crafted) then
			SDSS.Attachments:sanitize_blueprint(crafted)
		end
	end
end)

--Remove locked name after applying legendary skin
Hooks:PostHook(BlackMarketManager, "_set_weapon_cosmetics", "SDSS-PostHook-BlackMarketManager:_set_weapon_cosmetics", function(self, category, slot, cosmetics, update_weapon_unit)
	local crafted = self:get_crafted_category_slot(category, slot)
	if not crafted then
		return
	end

	crafted.locked_name = nil
end)
