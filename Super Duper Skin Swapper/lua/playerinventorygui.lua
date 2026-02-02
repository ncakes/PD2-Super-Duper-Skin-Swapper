--Clear useless/misleading stats from inventory loadout menu when skin mini-icon is highlighted
Hooks:PostHook(PlayerInventoryGui, "_update_stats", "SDSS-PostHook-PlayerInventoryGui:_update_stats", function(self, name)
	local box = self._boxes_by_name[name]
	if box and box.params and box.params.mod_data then
		if box.params.mod_data.selected_tab == "weapon_cosmetics" then
			local cosmetics = managers.blackmarket:get_weapon_cosmetics(box.params.mod_data.category, box.params.mod_data.slot)
			if cosmetics then
				self._info_panel:clear()
			end
		end
	end
end)
