_G[ModPath] = _G[ModPath] or {}
if _G[ModPath][RequiredScript] then return end
_G[ModPath][RequiredScript] = true

--Set a flag if the game is about to call BlackMarketManager:get_cosmetics_by_weapon_id for the sole purpose of creating mini-icons
Hooks:PreHook(MenuComponentManager, "create_weapon_mod_icon_list", "SDSS-PreHook-MenuComponentManager:create_weapon_mod_icon_list", function(self, weapon, category, factory_id, slot)
	SDSS.flags.lazy_cosmetics = true
end)
