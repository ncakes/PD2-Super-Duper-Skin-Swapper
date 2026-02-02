--Cache the removed IP content skins
--We temporarily remove the flag before calling BlackMarketGui:choose_weapon_mods_callback
--This lets us preview unowned IP content skins
Hooks:PostHook(EconomyTweakData, "_init_ip_content", "SDSS-PostHook-EconomyTweakData:_init_ip_content", function(self, tweak_data)
	SDSS.removed_skins = {}
	for k, v in pairs(tweak_data.blackmarket.weapon_skins) do
		if v.is_marketable == false then
			SDSS.removed_skins[k] = v
		end
	end
end)
