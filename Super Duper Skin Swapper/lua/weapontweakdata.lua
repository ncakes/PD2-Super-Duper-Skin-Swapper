--Tag each weapon with a category for the same category filter
Hooks:PostHook(WeaponTweakData, "init", "SDSS-PostHook-WeaponTweakData:init", function(self, ...)
	for weapon_id, weapon_data in pairs(self) do
		self[weapon_id]._sdss_cat = SDSS:get_sdss_category(weapon_data.categories or {})
	end
end)
