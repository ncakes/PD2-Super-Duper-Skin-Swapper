local key_map = {
	--AK family upper receiver. Not identical but looks good enough.
	--AK, RPK
	wpn_fps_ass_74_body_upperreceiver = Idstring("ak74_dustcover"):key(),
	--AK.762, Krinkov, IZHMA 12G
	wpn_fps_ass_akm_body_upperreceiver_vanilla = Idstring("cover"):key(),

	--AK family lower receiver.
	--AK, AK.762
	wpn_fps_ass_ak_body_lowerreceiver = Idstring("ak_base"):key(),
	--Krinkov, IZHMA 12G
	wpn_fps_smg_akmsu_body_lowerreceiver = Idstring("ak_base"):key(),
	--RPK
	wpn_fps_lmg_rpk_body_lowerreceiver = Idstring("ak_base"):key(),

	--AK.762 default stock / Folding Stock
	wpn_upg_ak_s_folding_vanilla = Idstring("folding"):key(),
	wpn_upg_ak_s_folding = Idstring("folding"):key(),

	--AK default stock / Skeleton Stock
	wpn_upg_ak_s_skfoldable_vanilla = Idstring("sk_foldable"):key(),
	wpn_upg_ak_s_skfoldable = Idstring("sk_foldable"):key(),

	--AK default magazine / Speed Pull Magazine
	wpn_fps_ass_74_m_standard = Idstring("ak74_mag"):key(),
	wpn_fps_upg_ak_m_quick = Idstring("ak74_mag"):key(),

	--CAR-4, AMR-16, Para
	wpn_fps_m4_upper_reciever_round = Idstring("round"):key(),
	--AMCAR when using sight
	wpn_fps_m4_upper_reciever_round_vanilla = Idstring("round"):key(),

	--AMCAR default stock / Standard Stock
	wpn_fps_upg_m4_s_standard_vanilla = Idstring("stock_standard"):key(),
	wpn_fps_upg_m4_s_standard = Idstring("stock_standard"):key(),

	--CAR-4 default magazine / Milspec Mag. / Speed Pull Magazine
	wpn_fps_m4_uupg_m_std_vanilla = Idstring("m4_mag_std"):key(),
	wpn_fps_m4_uupg_m_std = Idstring("m4_mag_std"):key(),
	wpn_fps_m4_upg_m_quick = Idstring("m4_mag_std"):key(),

	--AMCAR default magazine / Vintage Mag.
	wpn_fps_upg_m4_m_straight_vanilla = Idstring("straight"):key(),
	wpn_fps_upg_m4_m_straight = Idstring("straight"):key(),

	--Reinfeld/Loco stocks
	--Reinfeld default stock, Government Issue Tactical Stock
	wpn_fps_shot_r870_s_solid_vanilla = Idstring("solid"):key(),
	wpn_fps_shot_r870_s_solid_big = Idstring("solid"):key(),
	--Standard Stock, Police Shorty Stock
	wpn_fps_shot_r870_s_solid = Idstring("solid"):key(),
	wpn_fps_shot_shorty_s_solid_short = Idstring("solid"):key(),
}

local part_families = {
	{
		"wpn_fps_ass_74_body_upperreceiver",
		"wpn_fps_ass_akm_body_upperreceiver_vanilla",
	},
	{
		"wpn_fps_ass_ak_body_lowerreceiver",
		"wpn_fps_smg_akmsu_body_lowerreceiver",
		"wpn_fps_lmg_rpk_body_lowerreceiver",
	},
	{
		"wpn_upg_ak_s_folding_vanilla",
		"wpn_upg_ak_s_folding",
	},
	{
		"wpn_upg_ak_s_skfoldable_vanilla",
		"wpn_upg_ak_s_skfoldable",
	},
	{
		"wpn_fps_ass_74_m_standard",
		"wpn_fps_upg_ak_m_quick",
	},
	{
		"wpn_fps_m4_upper_reciever_round_vanilla",
		"wpn_fps_m4_upper_reciever_round",
	},
	{
		"wpn_fps_upg_m4_s_standard_vanilla",
		"wpn_fps_upg_m4_s_standard",
	},
	{
		"wpn_fps_m4_uupg_m_std_vanilla",
		"wpn_fps_m4_uupg_m_std",
		"wpn_fps_m4_upg_m_quick",
	},
	{
		"wpn_fps_upg_m4_m_straight_vanilla",
		"wpn_fps_upg_m4_m_straight",
	},
	{
		"wpn_fps_shot_r870_s_solid_vanilla",
		"wpn_fps_shot_r870_s_solid",
		"wpn_fps_shot_r870_s_solid_big",
		"wpn_fps_shot_shorty_s_solid_short",
	}
}

--Reference not copy.
local function _copy_part_to_family(src_part_data, family, parts)
	for _, dst_part_id in ipairs(family) do
		local dst_part_key = key_map[dst_part_id]
		--dst_part_id ~= src_part_id is guaranteed.
		--Otherwise both parts[dst_part_id] and parts[dst_part_id][dst_part_key] exist.
		if not parts[dst_part_id] or not parts[dst_part_id][dst_part_key] then
			parts[dst_part_id] = parts[dst_part_id] or {}
			parts[dst_part_id][dst_part_key] = src_part_data
		end
	end
end

function SDSS.copy_all_parts_to_families(parts)
	for _, family in ipairs(part_families) do
		for _, part_id in ipairs(family) do
			if parts[part_id] then
				local src_part_key = key_map[part_id]
				local src_part_data = parts[part_id][src_part_key]
				if src_part_data then
					_copy_part_to_family(src_part_data, family, parts)
					break
				end
			end
		end
	end
end
