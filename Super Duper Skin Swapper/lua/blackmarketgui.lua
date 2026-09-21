_G[ModPath] = _G[ModPath] or {}
if _G[ModPath][RequiredScript] then return end
_G[ModPath][RequiredScript] = true

Hooks:PreHook(BlackMarketGui, "choose_weapon_mods_callback", "SDSS-PreHook-BlackMarketGui:choose_weapon_mods_callback", function()
	--Set these flags to prevent vanilla code from needlessly sorting.
	--We need to hijack BlackMarketGuiTabItem:init to set on_create_data ourselves.
	--Important: disable these flags immediately in PreHook-BlackMarketGuiTabItem:init
	SDSS.flags.lazy_cosmetics = true
	SDSS.flags.lazy_instances = true

	--Force a filter reload. Disable in PostHook-BlackMarketGuiTabItem:init
	SDSS.flags.reload_filters = true
	--Tempfix, need to figure out how not to reset the cursor to first weapon skin on first run
	SDSS.flags.first_run = true

	--If not using OSA, temporarily remove default_blueprint while in crafting menu.
	--Warning: removing default_blueprint can trigger false-positives in the anti-piracy code.
	--We avoid this by blocking NetworkPeer:_verify_content(...) when in crafting menu.
	--Also block in weapon color menu.
	if not _G.OSA then
		SDSS:remove_blueprints()
	end
end)

--Detect when leaving weapon customization. Note: this is also triggered when:
	--Opening weapon color customization.
	--Closing gadget customization.
	--Closing reticle customization.
Hooks:PreHook(BlackMarketGui, "close", "SDSS-PreHook-BlackMarketGui:close", function(self)
	local node = self._node
	local node_name = node and node._parameters and node._parameters.name
	if node_name ~= "blackmarket_crafting_node" then
		return
	end

	--Use this flag so we know to ignore fake closes.
	if SDSS.flags.ignore_next_close then
		SDSS.flags.ignore_next_close = false
		return
	end

	ncUtils.Settings:save(SDSS)

	if not _G.OSA then
		SDSS:restore_blueprints()
	end
end)

--Entering weapon color customization.
Hooks:PreHook(BlackMarketGui, "open_customize_weapon_color_menu", "SDSS-PreHook-BlackMarketGui:open_customize_weapon_color_menu", function()
	SDSS.flags.ignore_next_close = true
end)

--Customize reticle.
Hooks:PreHook(BlackMarketGui, "open_reticle_switch_menu", "SDSS-PreHook-BlackMarketGui:open_reticle_switch_menu", function()
	SDSS.flags.ignore_next_close = true
end)

--Customize gadget.
Hooks:PreHook(BlackMarketGui, "open_customize_gadget_menu", "SDSS-PreHook-BlackMarketGui:open_customize_gadget_menu", function()
	SDSS.flags.ignore_next_close = true
end)

--Real-time filters.
--Restoration Mod fully overwrites populate_weapon_cosmetics, move sorting here.
Hooks:PreHook(BlackMarketGuiTabItem, "init", "SDSS-PreHook-BlackMarketGuiTabItem:init", function(self, main_panel, data, ...)
	if data.name ~= "weapon_cosmetics" then
		return
	end

	--Important: revert these flags immediately.
	SDSS.flags.lazy_cosmetics = false
	SDSS.flags.lazy_instances = false

	--Use real skin icon.
	SDSS.flags.real_icon = true

	if SDSS.flags.reload_filters then
		--if _G.RestorationCoreCallbacks then
			--Maybe only sort if Restoration Mod is detected?
			--Performance seems fast enough for now.
			--Let's not complicate the code.
		--end

		local crafted = managers.blackmarket:get_crafted_category(data.category)[data.prev_node_data and data.prev_node_data.slot]
		local weapon_id = crafted.weapon_id

		local sort_mode = SDSS:get_filter_state("filter_sort")

		local has_skins = {}
		local instance_sort_data = {}
		local cosmetics_sort_data = {}

		--Get all instances which pass our filter
		local all_instances = managers.blackmarket:get_cosmetics_instances_by_weapon_id(weapon_id)
		for _, instance_id in ipairs(all_instances) do
			local cache = SDSS:db_get_instance(instance_id)
			if cache and SDSS:passes_filters(weapon_id, cache.skin_id, true) then
				has_skins[cache.skin_id] = true

				--Instances are unlocked which sort low-high by default ("off").
				local rarity = 0
				if sort_mode == "lowhigh" or sort_mode == "off" then
					rarity = cache.rarity_index
				elseif sort_mode == "highlow" then
					rarity = -cache.rarity_index
				end

				table.insert(instance_sort_data, {
					id = instance_id,
					sort_keys = {
						rarity = rarity,
						name = cache.name_localized,
						skin_id = cache.skin_id,
						quality = -cache.quality_index,
						bonus = -cache.bonus_index,
					},
				})
			end
		end

		--Get all weapon skins in the game which pass our filter
		for skin_id, skin_data in pairs(tweak_data.blackmarket.weapon_skins) do
			if not has_skins[skin_id] then
				local cache = SDSS:db_get_skin(skin_id)
				if cache and SDSS:passes_filters(weapon_id, skin_id, true) then
					local rarity = 0
					if sort_mode == "lowhigh" then
						rarity = cache.rarity_index
					elseif sort_mode == "highlow" then
						rarity = -cache.rarity_index
					elseif sort_mode == "off" then
						--Unlocked skins sort low-high rarity, locked skins high-low.
						--Custom skins are unlocked.
						rarity = cache.custom and cache.rarity_index or -cache.rarity_index
					end

					table.insert(cosmetics_sort_data, {
						id = skin_id,
						data = skin_data,
						custom = cache.custom,
						sort_keys = {
							custom = cache.custom and 0 or 1,--Custom first.
							rarity = rarity,
							name = cache.name_localized,
							skin_id = skin_id,
						},
					})
				end
			end
		end

		local sort_order = {
			"custom",
			"rarity", "name", "skin_id",
			"quality", "bonus",
		}

		local function sort_func(x, y)
			local x_keys = x.sort_keys
			local y_keys = y.sort_keys
			for _, k in ipairs(sort_order) do
				if x_keys[k] ~= y_keys[k] then
					return x_keys[k] < y_keys[k]
				end
			end
			return x.id < y.id
		end

		table.sort(instance_sort_data, sort_func)
		table.sort(cosmetics_sort_data, sort_func)

		local new_instances = {}
		local new_cosmetics = {}
		for _, v in ipairs(instance_sort_data) do
			table.insert(new_instances, v.id)
		end
		for _, v in ipairs(cosmetics_sort_data) do
			if not SDSS.settings.filter_hide_unowned or v.custom then
				table.insert(new_cosmetics, {
					id = v.id,
					data = v.data,
				})
			end
		end

		--Clean old data
		for i, _ in ipairs(data) do
			data[i] = nil
		end
		data.on_create_data = {
			instances = new_instances,
			cosmetics = new_cosmetics,
		}
	end
end)

--Proper sorting
Hooks:PostHook(BlackMarketGui, "populate_weapon_cosmetics", "SDSS-PostHook-BlackMarketGui:populate_weapon_cosmetics", function(self, data)
	if #data < 1 then
		return
	end

	local indices = not SDSS.flags.reload_filters and SDSS.cache.indices
	if not indices then
		indices = {}
		for i = 1, #data do
			indices[i] = i
		end
		--Apply a sort
		local sort_mode = SDSS:get_filter_state("filter_sort")
		for _, v in ipairs(data) do
			--{"unlocked":true,"equipped":false,"category":"primaries","name":"empty","slot":12,"name_localized":""}
			local is_empty = (v.name == "empty")

			--v.cosmetic_id is skin_id.
			--For instances, v.name is instance_id. Otherwise, v.name is skin_id.
			local is_instance = not is_empty and (v.cosmetic_id ~= v.name)

			local sort_keys = {
				empty = is_empty and 1 or 0,--Empty always last.
				color = v.is_a_color_skin and 0 or 1,--Color always first.
				unlocked = v.unlocked and 0 or 1,--Unlocked before locked.
				--rarity = rarity,
				name = v.name_localized or "",
				skin_id = v.cosmetic_id or "",
				--quality = -quality,
				--bonus = -bonus,
			}

			local rarity, quality, bonus
			if v.is_a_color_skin or is_empty then
				--Color and empty always takes priority.
				--Only one color skin so doesn't matter, just initialize to whatever.
				rarity = 0
				quality = 5
				bonus = 0
			else
				local cache = is_instance and SDSS:db_get_instance(v.name) or SDSS:db_get_skin(v.cosmetic_id)
				if not cache then
					log("ERROR: failed to load from cache.", v.name, v.cosmetic_id)
					return
				end

				--For alphabetical sort, rarity_index stays at 0.
				rarity = 0
				if sort_mode == "lowhigh" then
					rarity = cache.rarity_index
				elseif sort_mode == "highlow" then
					rarity = -cache.rarity_index
				elseif sort_mode == "off" then
					--Unlocked skins sort low-high rarity, locked skins high-low
					rarity = v.unlocked and cache.rarity_index or -cache.rarity_index
				end

				--Default to mint condition / no bonus if not an instance
				--These only matter when not using HideDupeSkins
				quality = is_instance and cache.quality_index or 5
				bonus = is_instance and cache.bonus_index or 0
			end

			--Rarity sort order already processed
			sort_keys.rarity = rarity

			--High to low quality always. Bonus first always.
			sort_keys.quality = -quality
			sort_keys.bonus = -bonus

			v.sort_keys = sort_keys
		end

		local sort_order = {
			"empty", "color", "unlocked",
			"rarity", "name", "skin_id",
			"quality", "bonus"
		}

		local function arg_sort_func(x, y)
			local x_keys = data[x].sort_keys
			local y_keys = data[y].sort_keys
			for _, k in ipairs(sort_order) do
				if x_keys[k] ~= y_keys[k] then
					return x_keys[k] < y_keys[k]
				end
			end
			return data[x].name < data[y].name
		end

		table.sort(indices, arg_sort_func)
		SDSS.cache.indices = indices
	end

	local temp = {}
	for new_index, old_index in ipairs(indices) do
		temp[new_index] = data[old_index]
	end
	for i, v in ipairs(temp) do
		data[i] = v
	end
end)

local active_reset_color = Color.red
local inactive_reset_color = Color(255, 127, 127, 127) / 255
local active_filter_color = Color.yellow
local inactive_filter_color = tweak_data.screen_colors.button_stage_3
local button_highlight_color = tweak_data.screen_colors.button_stage_2

--Page number scaling and filter options
Hooks:PostHook(BlackMarketGuiTabItem, "init", "SDSS-PostHook-BlackMarketGuiTabItem:init", function(self, main_panel, data, ...)
	--Check if we are on weapon skins page
	if self._name ~= "weapon_cosmetics" then
		return
	end

	--Not resetting selected slot on a filter refresh can cause a visual bug
	--when using more weapon mod rows. If the filter refresh results in fewer
	--skins than before but you still have a valid selected slot, the bottom
	--rows can become empty. The scroll bar may also disappear if all of the
	--skins now fit on one page. This makes it appear as if some skins have
	--disappeared. The scroll wheel also doesn't work but you can navigate
	--with arrow keys still. Just reset the selected slot on every filter
	--refresh, it also makes more sense.
	if SDSS.flags.first_run then
		--But we don't want to do it on the first run, tempfix.
		SDSS.flags.first_run = false
	elseif SDSS.flags.reload_filters then
		self._slot_selected = 1
		self:set_scroll_y(1)
	end

	--We're done, revert flags.
	SDSS.flags.real_icon = false
	SDSS.flags.reload_filters = false

	--Page number scaling
	if self._tab_pages_panel then
		--Limit amount of displayed page numbers to prevent them from going off screen
		local max_pages = SDSS.settings.page_buttons_max
		--Check if pages panel is too long
		--n_buttons is pages + 2 (because there is also a left arrow and right arrow button)
		local n_buttons = self._tab_pages_panel.num_children and self._tab_pages_panel:num_children()
		if n_buttons and n_buttons > (max_pages + 2) then
			local n_pages = n_buttons - 2
			--Do minus one because we always have to include page 1 so that's one less page we can use
			local step = math.ceil(n_pages/(max_pages - 1))

			local prev_item
			for i, child in ipairs(self._tab_pages_panel:children()) do
				if i == 1 then
					--Left arrow is always first item, always show
					prev_item = child
				elseif i == 2 then
					--Always show page 1
					child:set_left(prev_item:right() + 6)
					prev_item = child
				else
					--Page number is i-1 because first index is the left arrow
					local page = i - 1
					--If not on last page
					if page < n_pages then
						if page % step == 0 then
							--Only show steps
							child:set_left(prev_item:right() + 6)
							prev_item = child
						else
							--Hide. Set visible doesn't work because, it just makes it invisible but you can still click on it.
							child:set_width(0)
							child:set_height(0)
						end
					else
						--Always include last page and right arrow
						child:set_left(prev_item:right() + 6)
						prev_item = child
					end
				end
			end
			self._tab_pages_panel:set_w(prev_item:right())
			self._tab_pages_panel:set_right(self._grid_panel:right())
		end
	end

	--Filter buttons
	do
		local small_font = tweak_data.menu.pd2_small_font
		local small_font_size = tweak_data.menu.pd2_small_font_size
		--Make Panel
		self._tab_filters_panel = self._panel:panel({
			visible = false,--If we don't set this to false at the start, the button becomes visible again after we apply or preview a weapon mod
			w = self._grid_panel:w(),
			h = small_font_size,
		})

		--Filter buttons
		local prev_button
		for _, button_name in ipairs(SDSS.filter_buttons) do
			local is_reset = SDSS:filter_is_reset_button(button_name)

			local color
			if is_reset then
				color = SDSS:filter_is_active() and active_reset_color or inactive_reset_color
			else
				color = SDSS:filter_is_active(button_name) and active_filter_color or inactive_filter_color
			end

			--Add icon for toggles
			local is_toggle = not is_reset and SDSS:filter_is_toggle(button_name)
			if is_toggle then
				local texture, texture_rect = "guis/textures/menu_tickbox", {
					SDSS.settings[button_name] and 24 or 0,
					0,
					24,
					24,
				}
				local checkbox = self._tab_filters_panel:bitmap({
					name = button_name.."_checkbox",
					texture = texture,
					texture_rect = texture_rect,
					color = color,
				})
				checkbox:set_size(24, 24)
				if prev_button then
					checkbox:set_left(prev_button:right() + 15)
				end
				checkbox:set_top(self._tab_filters_panel:top() - 2)

				prev_button = checkbox
			end
			local locstring = SDSS:filter_button_locstring(button_name)
			local button = self._tab_filters_panel:text({
				name = button_name,
				vertical = "center",
				align = "center",
				text = managers.localization:to_upper_text(locstring),
				font = small_font,
				font_size = small_font_size,
				color = color,
			})

			local _, _, tw, th = button:text_rect()
			button:set_size(tw, th)
			if prev_button then
				local offset = not is_toggle and 15 or 0
				button:set_left(prev_button:right() + offset)
			end
			prev_button = button
		end

		--If pages panel, set 2 units below
		--If no pages panel, set 2 + 26 units below weapon mods so filter buttons don't move
		local top
		if self._tab_pages_panel then
			top = self._tab_pages_panel:bottom() + 2
		else
			top = self._grid_panel:bottom() + 2 + 26
		end

		self._tab_filters_panel:set_top(top)
		self._tab_filters_panel:set_w(prev_button:right())
		self._tab_filters_panel:set_right(self._grid_panel:right())
	end

	--Current filter indicator, will show on hover
	do
		local small_font = tweak_data.menu.pd2_small_font
		local small_font_size = tweak_data.menu.pd2_small_font_size
		self._tab_filter_status = self._panel:panel({
			visible = false,
			w = self._grid_panel:w(),
			h = small_font_size,
			layer = 10,
		})
		local label = self._tab_filter_status:text({
			name = "status",
			vertical = "center",
			align = "center",
			text = "Filter Status Placeholder",
			font = small_font,
			font_size = small_font_size,
			color = button_highlight_color,
			layer = 2,
		})

		--When using multiple weapon mod rows, page numbers are not displayed.
		--Make the background transparent in this case.
		local num_rows = self.my_slots_dimensions and self.my_slots_dimensions[2] or 1
		local rect = self._tab_filter_status:rect({
			name = "background",
			alpha = (num_rows > 1) and 0 or 0.9,
			color = Color(255, 64, 64, 64) / 255,
			layer = 1,
		})

		label:set_h(small_font_size)
		rect:set_h(small_font_size)
		local _, _, tw, _ = label:text_rect()
		label:set_w(tw+8)
		rect:set_w(tw+8)

		self._tab_filter_status:set_bottom(self._tab_filters_panel:top() - 4)
	end
end)

--If a button is a toggle, get the associated checkbox
local function get_checkbox(button)
	local has_checkbox = SDSS:filter_is_toggle(button:name())
	if has_checkbox then
		return button:parent():child(button:name().."_checkbox")
	end
end
--If a button is a checkbox, get the associated textbox
local function get_textbox(button)
	local is_checkbox = button.set_texture_rect and true or false
	if is_checkbox then
		local desc_name = ncUtils.String:strip_suffix(button:name(), "_checkbox")
		return button:parent():child(desc_name)
	end
end

--Show or hide the filter status popup
function BlackMarketGuiTabItem:sdss_update_filter_status_popup(button)
	local filter_state
	local desc_button

	local hide = false
	if not button then
		hide = true
	elseif SDSS:filter_is_reset_button(button:name()) then
		hide = true
	else
		--For toggles, make sure we use textbox to get the filter state
		desc_button = get_textbox(button) or button
		filter_state = SDSS:get_filter_state(desc_button:name())
		if filter_state == "off" then
			hide = true
		end
	end

	if hide then
		self._tab_filter_status:set_w(0)
		self._tab_filter_status:set_visible(false)
		return
	end

	--Update and show
	local label = self._tab_filter_status:child("status")
	local rect = self._tab_filter_status:child("background")

	--For toggles, align on checkbox icon
	local align_button = get_checkbox(button) or button

	local loc_string = SDSS:filter_state_locstring(desc_button:name())
	label:set_text(managers.localization:to_upper_text(loc_string))

	local _, _, tw, _ = label:text_rect()
	label:set_w(tw+8)
	rect:set_w(tw+8)

	self._tab_filter_status:set_w(rect:w())

	--Center align, need an offset for the checkbox.
	local w_diff = self._tab_filter_status:w() - align_button:w()
	if desc_button ~= align_button then
		w_diff = w_diff - desc_button:w()
	end
	--Positive moves right, negatives moves left
	local right_shift = not align_button.set_texture_rect and 0 or 2
	self._tab_filter_status:set_left(align_button:left() + align_button:parent():left() - w_diff/2 + right_shift)

	self._tab_filter_status:set_visible(true)
end

--Needed for right click
local orig_BlackMarketGui_mouse_pressed = BlackMarketGui.mouse_pressed
function BlackMarketGui:mouse_pressed(button, x, y)
	local node = self._node
	local node_name = node and node._parameters and node._parameters.name
	if node_name == "blackmarket_crafting_node" then
		local tab = self._tabs and self._tabs[1]
		local tab_name = tab and tab._name
		if tab_name == "weapon_cosmetics" and tab._selected then
			if tab._tab_filters_panel and tab._tab_filters_panel:inside(x, y) then
				tab:mouse_pressed(button, x, y)
				return
			end
		end
	end

	return orig_BlackMarketGui_mouse_pressed(self, button, x, y)
end

--Handle clicking filters button
local orig_BlackMarketGuiTabItem_mouse_pressed = BlackMarketGuiTabItem.mouse_pressed
function BlackMarketGuiTabItem:mouse_pressed(button, x, y)
	if alive(self._tab_filters_panel) and self._tab_filters_panel:inside(x, y) then
		for _, child in ipairs(self._tab_filters_panel:children()) do
			if child:inside(x, y) then
				--Disable clicking
				if SDSS:filter_is_reset_button(child:name()) and not SDSS:filter_is_active() then
					return
				end

				--For toggle, use textbox for processing
				local filter_id = not child.set_texture_rect and child:name() or get_textbox(child):name()

				if button == Idstring("0") then
					SDSS:filter_button_handler(filter_id)
				elseif button == Idstring("1") and SDSS:filter_is_active(filter_id) then
					--Right click resets a single filter
					SDSS:reset_filter(filter_id)
					SDSS:refresh_blackmarket_ui()
				end

				return
			end
		end
	end

	return orig_BlackMarketGuiTabItem_mouse_pressed(self, button, x, y)
end

--Set filter button visibility
Hooks:PreHook(BlackMarketGuiTabItem, "refresh", "SDSS-PreHook-BlackMarketGuiTabItem:refresh", function(self)
	if self._name ~= "weapon_cosmetics" then
		return
	end

	if alive(self._tab_filters_panel) then
		self._tab_filters_panel:set_visible(self._selected)
		self:sdss_update_filter_status_popup()
	end
end)

--Highlighting, mostly just copied
local orig_BlackMarketGuiTabItem_mouse_moved = BlackMarketGuiTabItem.mouse_moved
function BlackMarketGuiTabItem:mouse_moved(x, y)
	if alive(self._tab_filters_panel) then
		local used = false
		local pointer = "arrow"

		self._tab_filters_highlighted = self._tab_filters_highlighted or {}
		for _, child in ipairs(self._tab_filters_panel:children()) do
			local is_reset = child:name() == "filter_reset"

			if child:inside(x, y) then
				if not self._tab_filters_highlighted[child:name()] then
					--Inside, not highlighted.
					if is_reset and not SDSS:filter_is_active() then
						--Nothing
					else
						--Highlight
						child:set_color(button_highlight_color)
						self._tab_filters_highlighted[child:name()] = true

						--For toggles, also highlight checkbox or textbox
						local sibling = get_checkbox(child) or get_textbox(child)
						if sibling then
							sibling:set_color(button_highlight_color)
							self._tab_filters_highlighted[sibling:name()] = true
						end

						managers.menu_component:post_event("highlight")
						self:sdss_update_filter_status_popup(child)
						used, pointer = true, "link"
					end
				else
					--Inside, highlighted.
					if not self._tab_filter_status:visible() then
						self:sdss_update_filter_status_popup(child)
					end
					used, pointer = true, "link"
				end
			else
				if self._tab_filters_highlighted[child:name()] then
					--Not inside, highlighted.
					local sibling = get_checkbox(child) or get_textbox(child)
					if not sibling or not sibling:inside(x, y) then
						--Button
						local color
						if is_reset then
							color = SDSS:filter_is_active() and active_reset_color or inactive_reset_color
						else
							local filter_id = not child.set_texture_rect and child:name() or sibling:name()
							color = SDSS:filter_is_active(filter_id) and active_filter_color or inactive_filter_color
						end
						child:set_color(color)
						self._tab_filters_highlighted[child:name()] = false
					end
				else
					--Not inside, not highlighted.
					--Nothing. Handled by sibling if inside.
				end
			end
		end

		if used then
			return used, pointer
		end
		--If we didn't return, we are not inside any filter button
		if self._tab_filter_status:visible() then
			self:sdss_update_filter_status_popup()
		end
	end

	return orig_BlackMarketGuiTabItem_mouse_moved(self, x, y)
end

--Clear useless/misleading stats of skins from weapon modification menu
Hooks:PreHook(BlackMarketGui, "update_info_text", "SDSS-PreHook-BlackMarketGui:update_info_text", function(self)
	local slot_data = self._slot_data
	local tab_data = self._tabs[self._selected]._data
	local prev_data = tab_data.prev_node_data
	local ids_category = Idstring(slot_data.category)
	local identifier = tab_data.identifier
	if identifier == self.identifiers.weapon_cosmetic then
		slot_data.comparision_data = nil
	end
end)
Hooks:PostHook(BlackMarketGui, "update_info_text", "SDSS-PostHook-BlackMarketGui:update_info_text", function(self)
	local slot_data = self._slot_data
	local tab_data = self._tabs[self._selected]._data
	local prev_data = tab_data.prev_node_data
	local ids_category = Idstring(slot_data.category)
	local identifier = tab_data.identifier
	if identifier == self.identifiers.weapon_cosmetic then
		self._stats_panel:hide()
	end
end)

--Double click previews
local orig_BlackMarketGui_press_first_btn = BlackMarketGui.press_first_btn
function BlackMarketGui:press_first_btn(button)
	if SDSS.settings.fast_preview and button == Idstring("0") then
		if self._btns and self._btns.wcc_preview then
			local btn = self._btns.wcc_preview
			if btn:visible() and btn._data.callback then
				managers.menu_component:post_event("menu_enter")
				btn._data.callback(self._slot_data, self._data.topic_params)
				return true
			end
		end
	end

	return orig_BlackMarketGui_press_first_btn(self, button)
end

--Mini skin icon in corner when a weapon with a swapped skin is selected
Hooks:PostHook(BlackMarketGui, "populate_weapon_category_new", "SDSS-PostHook-BlackMarketGui:populate_weapon_category_new", function(self, data)
	local category = data.category
	local crafted_category = managers.blackmarket:get_crafted_category(category) or {}

	--TODO: redundant max_items
	local max_items = data.override_slots and data.override_slots[1] * data.override_slots[2] or 9
	local max_rows = tweak_data.gui.WEAPON_ROWS_PER_PAGE or 3
	max_items = max_rows * (data.override_slots and data.override_slots[1] or 3)

	for i = 1, max_items, 1 do
		local slot = data[i].slot
		if slot and crafted_category[slot] and crafted_category[slot].cosmetics then
			local crafted = crafted_category[slot]
			local weapon_id = crafted.weapon_id
			local skin_id = crafted.cosmetics.id
			local skin_data = skin_id and tweak_data.blackmarket.weapon_skins[skin_id]
			if skin_data and not skin_data.is_a_color_skin and not SDSS:weapon_cosmetics_type_check_for_real(weapon_id, skin_id) then
				local texture_path, _ = managers.blackmarket:get_weapon_icon_path(skin_data.weapon_id, crafted.cosmetics)
				if texture_path then
					local icon_list = managers.menu_component:create_weapon_mod_icon_list(crafted.weapon_id, category, crafted.factory_id, slot)
					data[i].mini_icons = data[i].mini_icons or {}
					--Background
					if SDSS.settings.mini_icon_bg then
						table.insert(data[i].mini_icons, {
							layer = 2,
							color = Color(255, 77, 198, 255) / 255,
							blend_mode = "add",
							alpha = 0.35,
							h = 24,
							w = 48,
							right = 0,
							bottom = math.floor((#icon_list - 1) / 11) * 25 + 24,
						})
					end
					--Weapon
					table.insert(data[i].mini_icons, {
						stream = false,
						layer = 3,
						texture = texture_path,
						h = 24,
						w = 48,
						right = 0,
						bottom = math.floor((#icon_list - 1) / 11) * 25 + 24,
					})
				end
			end
		end
	end
end)
