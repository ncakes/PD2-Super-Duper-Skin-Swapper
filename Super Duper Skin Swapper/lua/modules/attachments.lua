---@class SDSS.Attachments
SDSS.Attachments = {}
SDSS.Attachments.blueprints_suppressed = false

function SDSS.Attachments:register_blueprints(skin_tweak)
	self.blueprint_skin_ids = {}

	for skin_id, skin_data in pairs(skin_tweak) do
		if skin_data.default_blueprint then
			table.insert(self.blueprint_skin_ids, skin_id)
			skin_data._sdss_blueprint = skin_data.default_blueprint
		end
	end
end

function SDSS.Attachments:remove_blueprints()
	self.blueprints_suppressed = true
	local skin_tweak = tweak_data.blackmarket.weapon_skins
	for _, k in ipairs(self.blueprint_skin_ids or {}) do
		skin_tweak[k].default_blueprint = nil
	end
end

function SDSS.Attachments:restore_blueprints()
	local skin_tweak = tweak_data.blackmarket.weapon_skins
	for _, k in ipairs(self.blueprint_skin_ids or {}) do
		skin_tweak[k].default_blueprint = skin_tweak[k]._sdss_blueprint
	end
	self.blueprints_suppressed = false
end

local function safe_get_part_data(part_id)
	return tweak_data
		and tweak_data.weapon
		and tweak_data.weapon.factory
		and tweak_data.weapon.factory.parts
		and tweak_data.weapon.factory.parts[part_id]
end

-- Global values
local function get_part_global_value(part_id)
	local part_data = safe_get_part_data(part_id)
	if not part_data then
		return
	end

	if part_data.custom then
		return part_data.global_value or "normal"
	end

	return part_data.dlc
		and managers.dlc:dlc_to_global_value(part_data.dlc)
		or "normal"
end

function SDSS.Attachments:set_global_values(crafted)
	if not crafted or not crafted.blueprint or not crafted.factory_id then
		return
	end

	local vanilla_parts = managers.weapon_factory:get_default_blueprint_by_factory_id(crafted.factory_id)
	if not vanilla_parts then
		return
	end

	crafted.global_values = {}
	for _, part_id in ipairs(crafted.blueprint) do
		if not table.contains(vanilla_parts, part_id) then
			crafted.global_values[part_id] = get_part_global_value(part_id)
		end
	end
end

local function can_use_part(part_id)
	local part_data = safe_get_part_data(part_id)
	if not part_data then
		--We tried.
		return true
	end

	--BeardLib parts, do nothing.
	if part_data.custom then
		return true
	end

	--Legendary part.
	--U242.1 has added the unatainable tag to the Plush Phoenix Upper/Lower Body.
	if part_data.unatainable then
		return false
	end

	--Unowned DLC
	if part_data.dlc and not managers.dlc:is_dlc_unlocked(part_data.dlc) then
		return false
	end

	return true
end

--Check for legendary and unowned DLC parts.
function SDSS.Attachments:has_invalid_parts(crafted)
	for _, part_id in ipairs(crafted.blueprint) do
		if not can_use_part(part_id) then
			return true
		end
	end

	return false
end

--Note: this is a destructive sanitization, not a repair.
--Call this only when you are going to destroy blueprint.
--i.e. selling weapon or resetting to default attachments.
function SDSS.Attachments:sanitize_blueprint(crafted)
	local cleaned = {}
	for _, part_id in ipairs(crafted.blueprint) do
		if can_use_part(part_id) then
			table.insert(cleaned, part_id)
		end
	end
	crafted.blueprint = cleaned
end

--Reset a weapon to default if it contains invalid parts.
function SDSS.Attachments:reset_if_invalid(crafted, category, slot, silent)
	if not self:has_invalid_parts(crafted) then
		return
	end

	self:sanitize_blueprint(crafted)
	managers.blackmarket:add_crafted_weapon_blueprint_to_inventory(category, slot, {})
	crafted.blueprint = deep_clone(managers.weapon_factory:get_default_blueprint_by_factory_id(crafted.factory_id))
	crafted.global_values = {}

	if not silent then
		local menu_title = managers.localization:text("sdss_dialog_title")
		local menu_message = managers.localization:text("sdss_dialog_blueprint_reset")
		local menu_options = {
			{
				text = managers.localization:text("sdss_dialog_button_dismiss")
			}
		}
		ncDialogs:show(menu_title, menu_message, menu_options)
	end
end
