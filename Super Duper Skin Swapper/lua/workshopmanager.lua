_G[ModPath] = _G[ModPath] or {}
if _G[ModPath][RequiredScript] then return end
_G[ModPath][RequiredScript] = true

Hooks:PostHook(WorkshopManager, "init", "SDSS-PostHook-WorkshopManager:init", function(...)
	do
		--Vlad's Rodina sticker
		local parts = tweak_data.blackmarket.weapon_skins.ak74_rodina.parts
		local scale = 0.965
		parts.wpn_fps_ass_akm_body_upperreceiver_vanilla = {
			[Idstring("cover"):key()] = {
				sticker = Idstring("units/payday2_cash/safes/sputnik/sticker/sticker_starbomb_df"),
				uv_scale = Vector3(2.69309/scale, 2.69377/scale, 1),
				uv_offset_rot = Vector3(-0.153, 0.907, 0)
			}
		}
	end

	do
		--AK Little Brother sticker
		local parts = tweak_data.blackmarket.weapon_skins.ak74_bloodsplat.parts
		local scale = 0.965
		--Calculate from Rodina, <new> - <original>
		local offset = Vector3(-0.153, 0.907, 0) - Vector3(-0.165514, 0.893394, 0)
		parts.wpn_fps_ass_akm_body_upperreceiver_vanilla = {
			[Idstring("cover"):key()] = {
				uv_offset_rot = Vector3(0.235154, 0.864775, 0) + offset,
				sticker = Idstring("units/payday2_cash/safes/cf15/sticker/sticker_houston_df"),
				uv_scale = Vector3(3.69526/scale, 3.83828/scale, 1)
			}
		}
	end

	--Initialize weapons cache.
	--SDSS handles all checks.
	for weapon_id, _ in pairs(tweak_data.weapon) do
		SDSS:db_add_weapon(weapon_id)
	end

	--Initialize weapon skins cache. Must run after weapons cache.
	--Inherits data from the corresponding weapon.
	--SDSS handles all checks.
	for skin_id, skin_data in pairs(tweak_data.blackmarket.weapon_skins) do
		--Do this here so we catch custom skins. Why not.
		if skin_data.parts then
			SDSS.copy_all_parts_to_families(skin_data.parts)
		end
		SDSS:db_add_skin(skin_id)

		--Completely remove blueprints from custom skins if no OSA
		if not _G.OSA and skin_data.custom and skin_data.default_blueprint then
			skin_data.default_blueprint = nil
			skin_data._sdss_blueprint = nil--Just in case
		end
	end
end)
