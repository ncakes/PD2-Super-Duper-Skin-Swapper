Hooks:PostHook(WeaponTweakData, "init", "SDSS-PostHook-WeaponTweakData:init", function(self, ...)
	--Set family flag
	for family_id, weapons in pairs(SDSS.families) do
		for _, weapon_id in ipairs(weapons) do
			if self[weapon_id] then
				self[weapon_id]._sdss_fam = family_id
			end
		end
	end
	--Set category
	for weapon_id, weapon_data in pairs(self) do
		if weapon_data.categories then
			for _, category in ipairs(weapon_data.categories) do
				if category ~= "akimbo" and category ~= "revolver" then
					self[weapon_id]._sdss_cat = category
					break
				end
			end
		end
	end
end)
