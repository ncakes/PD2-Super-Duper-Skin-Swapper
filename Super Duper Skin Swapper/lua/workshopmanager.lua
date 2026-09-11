Hooks:PostHook(WorkshopManager, "init", "SDSS-PostHook-WorkshopManager:init", function(...)
	--Get weapon ID from a weapon skin.
	--Also handles weapon ID lists and returns the parent ID if applicable.
	local function get_skin_weapon_id(skin_data)
		--Has weapon ID, easy.
		if skin_data.weapon_id then
			return skin_data.weapon_id
		end
		--If multiple weapon IDs, take first one and check if it has a parent ID.
		if skin_data.weapon_ids then
			local weapon_id = skin_data.weapon_ids[1]
			if tweak_data.weapon[weapon_id] and tweak_data.weapon[weapon_id].parent_weapon_id then
				return tweak_data.weapon[weapon_id].parent_weapon_id
			end
			return weapon_id
		end
	end

	local weapon_skins = tweak_data and tweak_data.blackmarket and tweak_data.blackmarket.weapon_skins
	for skin_id, skin_data in pairs(weapon_skins or {}) do
		--Tag each skin with a category.
		--Also tag with a family if it has one.
		--Do it here after tweak_data is initialized and also so we can process custom skins.
		--Ignore Immortal Python (tam) and color skins.
		--Stolen from BlackMarketManager:is_weapon_skin_tam(skin_id)
		local is_tam = skin_data.global_value == "tam" and not skin_data.is_a_color_skin and string.match(skin_id, "tam")
		if not is_tam and not skin_data.is_a_color_skin then
			local weapon_id = get_skin_weapon_id(skin_data)
			if weapon_id then
				--Tag each skin with a family
				for family_id, weapons in pairs(SDSS.families) do
					if table.contains(weapons, weapon_id) then
						skin_data._sdss_fam = family_id
					end
				end

				--Tag each skin with a category
				local weapon_data = tweak_data.weapon[weapon_id]
				if weapon_data then
					skin_data._sdss_cat = SDSS:get_sdss_category(weapon_data.categories or {})
				end
			else
				log("SDSS found skin with no weapon_id", skin_id)
			end
		end

		--Completely remove blueprints from custom skins if no OSA
		if not _G.OSA and skin_data.custom and skin_data.default_blueprint then
			skin_data.default_blueprint = nil
			skin_data._sdss_blueprint = nil--Just in case
		end
	end
end)
