--Set a flag if the game is about to call BlackMarketManager:get_cosmetics_by_weapon_id for the sole purpose of creating mini-icons
Hooks:PreHook(MenuComponentManager, "create_weapon_mod_icon_list", "SDSS-PreHook-MenuComponentManager:create_weapon_mod_icon_list", function(self, weapon, category, factory_id, slot)
	SDSS._lazy = true
end)

--If not using OSA, temporarily remove default_blueprint while in crafting menu.
--Warning: removing default_blueprint can trigger false-positives in the anti-piracy code.
--We avoid this by blocking NetworkPeer:_verify_content(...) when in crafting menu.
if not _G.OSA then
	Hooks:PreHook(MenuComponentManager, "create_blackmarket_gui", "SDSS-PreHook-MenuComponentManager:create_blackmarket_gui", function(self, node)
		local node_name = node and node._parameters and node._parameters.name or ""
		if node_name == "blackmarket_crafting_node" then
			SDSS:remove_blueprints()
		end
	end)
end

--Leaving weapon customization screen.
--Save filters.
--Restore blueprints if no OSA.
Hooks:PreHook(MenuComponentManager, "close_blackmarket_gui", "SDSS-PreHook-MenuComponentManager:close_blackmarket_gui", function(self)
	local node = self._blackmarket_gui and self._blackmarket_gui._node or nil
	local node_name = node and node._parameters and node._parameters.name or ""
	if node_name == "blackmarket_crafting_node" then
		ncUtils.Settings:save(SDSS)

		if not _G.OSA then
			SDSS:restore_blueprints()
		end
	end
end)
