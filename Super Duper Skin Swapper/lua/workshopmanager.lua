_G[ModPath] = _G[ModPath] or {}
if _G[ModPath][RequiredScript] then return end
_G[ModPath][RequiredScript] = true

Hooks:PostHook(WorkshopManager, "init", "SDSS-PostHook-WorkshopManager:init", function(...)
	--Initialize weapons cache.
	--SDSS handles all checks.
	for weapon_id, _ in pairs(tweak_data.weapon) do
		SDSS:db_add_weapon(weapon_id)
	end

	--Initialize weapon skins cache. Must run after weapons cache.
	--Inherits data from the corresponding weapon.
	--SDSS handles all checks.
	for skin_id, skin_data in pairs(tweak_data.blackmarket.weapon_skins) do
		SDSS:db_add_skin(skin_id)

		--Completely remove blueprints from custom skins if no OSA
		if not _G.OSA and skin_data.custom and skin_data.default_blueprint then
			skin_data.default_blueprint = nil
			skin_data._sdss_blueprint = nil--Just in case
		end
	end
end)
