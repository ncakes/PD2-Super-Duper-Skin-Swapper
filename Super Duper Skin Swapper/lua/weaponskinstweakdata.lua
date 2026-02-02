if _G.OSA then
	return
end

--Warning: removing default_blueprint can trigger false-positives in the anti-piracy code.
Hooks:PostHook(BlackMarketTweakData, "_init_weapon_skins", "SDSS-PostHook-BlackMarketTweakData:_init_weapon_skins", function(self)
	--Make a list of all skins with blueprints
	SDSS.blueprint_skin_ids = {}
	for skin_id, skin in pairs(self.weapon_skins) do
		--Track skins with default blueprints and add a reference so we can remove and restore
		if skin.default_blueprint then
			table.insert(SDSS.blueprint_skin_ids, skin_id)
			skin._sdss_blueprint = skin.default_blueprint
		end

		if skin.rarity == "legendary" then
			--Remove unique name and unlock legendary skins
			skin.unique_name_id = nil
			--Set this flag so we know if we have to check for legendary parts
			skin._sdss_is_legendary = skin.locked and true or false
			skin.locked = nil
		else
			--Remove "MODIFICATIONS INCLUDED" description from non-legendary skins
			skin.desc_id = nil
		end
	end
end)
