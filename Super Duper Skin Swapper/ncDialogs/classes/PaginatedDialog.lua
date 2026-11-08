if not TextBoxGui then return end
if not (SystemMenuManager and SystemMenuManager.GenericDialog) then return end
if not (tweak_data and tweak_data.menu) then return end

--Pad 10 above and below to make sure everything stays inside.
local FOOTER_HEIGHT = tweak_data.menu.pd2_medium_font_size + 20
local CANCEL_BUTTON_NAME = "ncd_cancel"

_G.ncDialogs_PaginatedDialogGui = class(TextBoxGui)

function ncDialogs_PaginatedDialogGui:init(ws, title, text, content_data, config)
	self._page_size = content_data.page_size
	self._total_pages = math.max(1, math.ceil(#content_data.option_buttons / content_data.page_size))
	ncDialogs_PaginatedDialogGui.super.init(self, ws, title, text, content_data, config)
end

--Resize buttons panel.
function ncDialogs_PaginatedDialogGui:_setup_buttons_panel(info_area, buttons, focus, only_buttons)
	local panel = ncDialogs_PaginatedDialogGui.super._setup_buttons_panel(
		self, info_area, buttons, focus, only_buttons
	)

	--Account for initializing on a short page.
	--Leave a gap before cancel when paginating.
	if self._total_pages > 1 then
		local row_h = panel:h() / #buttons
		local cancel = panel:child(CANCEL_BUTTON_NAME)

		if alive(cancel) then
			panel:set_h((self._page_size + 2) * row_h)
			cancel:set_y((self._page_size + 1) * row_h)

			if self._text_box_focus_button then
				self:_set_button_selected(self._text_box_focus_button, true)
			end
		else
			panel:set_h(self._page_size * row_h)
		end

		panel:set_bottom(info_area:h() - 10)
	end

	return panel
end

function ncDialogs_PaginatedDialogGui:setup_pagination()
	if self._total_pages <= 1 then
		return
	end

	local info = self._panel:child("info_area")
	local footer = info:panel({
		name = "ncd_pagination",
		layer = 5,
		w = 160,
		h = FOOTER_HEIGHT,
	})
	footer:set_left(0)
	footer:set_bottom(info:h())

	local font = tweak_data.menu.pd2_medium_font
	local size = tweak_data.menu.pd2_medium_font_size
	local color = tweak_data.screen_colors.button_stage_3

	local gap = 0
	self._page_left = footer:bitmap({
		name = "prev",
		texture = "guis/textures/menu_arrows",
		texture_rect = {24, 0, 24, 24},
		x = 0,
		w = 24,
		h = 24,
		color = color,
		layer = 6,
	})
	self._page_left:set_bottom(footer:h() - 10 - 2)
	self._page_left:set_left(10)

	self._page_label = footer:text({
		name = "page",
		text = "1 / 1",
		font = font,
		font_size = size,
		color = color,
		align = "center",
		vertical = "center",
		x = 0,
		w = 60,
		h = size,
		layer = 6
	})
	self._page_label:set_bottom(footer:h() - 10 - 1)
	self._page_label:set_left(self._page_left:right() + gap)

	self._page_right = footer:bitmap({
		name = "next",
		texture = "guis/textures/menu_arrows",
		texture_rect = {24, 0, 24, 24},
		rotation = 180,
		x = 0,
		w = 24,
		h = 24,
		color = color,
		layer = 6,
	})
	self._page_right:set_bottom(footer:h() - 10 - 1)
	self._page_right:set_left(self._page_label:right() - 1 + gap)

	footer:set_w(self._page_right:right() + 10)
end

function ncDialogs_PaginatedDialogGui:set_page(page)
	if self._total_pages <= 1 then
		return
	end

	local active_color = tweak_data.screen_colors.button_stage_2
	local inactive_color = tweak_data.screen_colors.button_stage_3:with_alpha(0.35)

	self._page = page
	self._page_label:set_text(tostring(page) .. " / " .. tostring(self._total_pages))
	self._page_left:set_color(page > 1 and active_color or inactive_color)
	self._page_right:set_color(page < self._total_pages and active_color or inactive_color)
end

function ncDialogs_PaginatedDialogGui:replace_page_buttons(buttons, focus)
	if self._total_pages <= 1 then
		return
	end

	local info = self._panel:child("info_area")
	info:remove(self._text_box_buttons_panel)
	self._text_box_focus_button = nil
	self:_setup_buttons_panel(info, buttons, focus, false)
end

--PaginatedDialog:mouse_moved() doesn't work, need to control it here.
--Important: check alive, otherwise game crashes during a dialog close.
function ncDialogs_PaginatedDialogGui:mouse_moved(x, y)
	local used, pointer = ncDialogs_PaginatedDialogGui.super.mouse_moved(self, x, y)
	if self._total_pages <= 1 then
		return used, pointer
	end

	if not alive(self._panel) then
		return used, pointer
	end

	local info = self._panel:child("info_area")
	if not alive(info) then
		return used, pointer
	end

	local footer = info:child("ncd_pagination")
	if not alive(footer) then
		return used, pointer
	end

	local prev_button = footer:child("prev")
	local next_button = footer:child("next")
	if self._page > 1 and alive(prev_button) and prev_button:inside(x, y) then
		return true, "link"
	elseif self._page < self._total_pages and alive(next_button) and next_button:inside(x, y) then
		return true, "link"
	end

	return used, pointer
end

local PaginatedDialog = class(SystemMenuManager.GenericDialog)
PaginatedDialog.PANEL_SCRIPT_CLASS = "ncDialogs_PaginatedDialogGui"

--Build page buttons and clamp focus to the available options.
--Focus -1 means focus on the last button (Cancel, if present).
function PaginatedDialog:_page_buttons(page, focus)
	focus = focus or -1

	local result = {}
	local start = (page - 1) * self._page_size + 1
	for i = start, math.min(start + self._page_size - 1, #self._option_buttons) do
		result[#result + 1] = self._option_buttons[i]
	end

	--Clamp to real options. Negative focus means last button, handle later.
	focus = math.min(focus, #result)

	if self._cancel_button then
		result[#result + 1] = self._cancel_button
	end

	if focus < 1 then
		focus = #result
	end
	focus = math.max(1, focus)

	return result, focus
end

function PaginatedDialog:init(manager, data)
	self._option_buttons = data.option_buttons
	self._cancel_button = data.cancel_button
	if self._cancel_button then
		self._cancel_button.id_name = CANCEL_BUTTON_NAME
	end
	self._page_size = data.page_size
	self._total_pages = math.max(1, math.ceil(#self._option_buttons / self._page_size))

	--Set initial focused button and page.
	local page = 1
	local page_focus = -1
	if data.focus_button and data.focus_button > 0 then
		page = math.ceil(data.focus_button / self._page_size)
		page_focus = (data.focus_button - 1) % self._page_size + 1
	end
	self._page = page

	data.button_list, data.focus_button = self:_page_buttons(page, page_focus)

	PaginatedDialog.super.init(self, manager, data)
	self._panel_script:setup_pagination()
	self._panel_script:set_page(self._page)
end

--Short pages with only one option should not be considered single-button pages.
--Prevent vanilla from automatically invoking the option callback on Esc.
function PaginatedDialog:dialog_cancel_callback()
	if #self._option_buttons > 1 and not self._cancel_button then
		return
	end

	return PaginatedDialog.super.dialog_cancel_callback(self)
end

function PaginatedDialog:change_page(direction)
	local next_page = self._page + direction
	if next_page < 1 or next_page > self._total_pages then
		return
	end

	--Check what button we are focused on.
	local panel = self._panel_script
	local focus = panel._text_box_focus_button
	if self._cancel_button and focus == #self._data.button_list then
		focus = -1
	end

	self._page = next_page
	local buttons, next_focus = self:_page_buttons(next_page, focus)
	self._data.button_list = buttons
	self._panel_script:replace_page_buttons(buttons, next_focus)
	self._panel_script:set_page(next_page)
end

--Handle clicking navigation buttons.
--Handle mouse wheel navigation.
function PaginatedDialog:mouse_pressed(o, button, x, y)
	if self._total_pages > 1 and self._input_enabled then
		if button == Idstring("0") then
			local mx, my = managers.mouse_pointer:convert_1280_mouse_pos(x, y)
			local footer = self._panel_script._panel:child("info_area"):child("ncd_pagination")
			if alive(footer) and footer:inside(mx, my) then
				if self._page > 1 and footer:child("prev"):inside(mx, my) then
					self:change_page(-1)
				elseif self._page < self._total_pages and footer:child("next"):inside(mx, my) then
					self:change_page(1)
				end
				--Consume all clicks within the footer to prevent overlapping buttons from activating.
				return
			end
		end

		if button == Idstring("mouse wheel up") then
			self:change_page(-1)
			return
		elseif button == Idstring("mouse wheel down") then
			self:change_page(1)
			return
		end
	end
	return PaginatedDialog.super.mouse_pressed(self, o, button, x, y)
end

--Change page with arrow keys.
function PaginatedDialog:update_input(t, dt)
	PaginatedDialog.super.update_input(self, t, dt)
	if self._total_pages > 1 and self._input_enabled then
		if self._controller:get_input_bool("menu_left") then
			if not self._page_key_down then
				self:change_page(-1)
			end
			self._page_key_down = true
		elseif self._controller:get_input_bool("menu_right") then
			if not self._page_key_down then
				self:change_page(1)
			end
			self._page_key_down = true
		else
			self._page_key_down = false
		end
	end
end

ncDialogs.PaginatedDialog = PaginatedDialog
