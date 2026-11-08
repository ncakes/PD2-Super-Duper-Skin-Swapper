_G[ModPath] = _G[ModPath] or {}
if _G[ModPath][RequiredScript] then return end
_G[ModPath][RequiredScript] = true

if _G.OSA then
	return
end

--Warning: removing default_blueprint can trigger false-positives in the anti-piracy code.
Hooks:PostHook(BlackMarketTweakData, "_init_weapon_skins", "SDSS-PostHook-BlackMarketTweakData:_init_weapon_skins", function(self)
	for skin_id, skin_data in pairs(self.weapon_skins) do
		--Rename legendary skins. Remove customization locks on legendary skins.
		skin_data.unique_name_id = nil
		skin_data.locked = nil

		--Remove "MODIFICATIONS INCLUDED" description from non-legendary skins.
		if skin_data.rarity ~= "legendary" then
			skin_data.desc_id = nil
		end
	end

	SDSS.Attachments:register_blueprints(self.weapon_skins)
end)
