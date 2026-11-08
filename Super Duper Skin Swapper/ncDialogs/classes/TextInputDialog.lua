if not TextBoxGui then return end
if not (SystemMenuManager and SystemMenuManager.GenericDialog) then return end
if not (tweak_data and tweak_data.menu) then return end
if not SearchBoxGuiObject then return end

local TEXT_INPUT_HEIGHT = tweak_data.menu.pd2_medium_font_size
local TEXT_INPUT_HEIGHT_PAD = 12

_G.ncDialogs_TextInputDialogGui = class(TextBoxGui)
function ncDialogs_TextInputDialogGui:_override_info_area_size(info_area, scroll_panel, buttons_panel)
	local extra_height = TEXT_INPUT_HEIGHT + 2*TEXT_INPUT_HEIGHT_PAD
	info_area:set_h(scroll_panel:bottom() + buttons_panel:h() + 15 + extra_height)
end

local TextInputDialog = class(SystemMenuManager.GenericDialog)
TextInputDialog.PANEL_SCRIPT_CLASS = "ncDialogs_TextInputDialogGui"

function TextInputDialog:init(manager, data)
	TextInputDialog.super.init(self, manager, data)
	local gui = self._panel_script
	local host = gui._panel
	local scroll_panel = gui._scroll_panel
	local description = scroll_panel:child("text")
	local w = host:w() - 20
	self._searchbox = SearchBoxGuiObject:new(host, self._ws, data.initial_text or "", {
		x = (host:w() - w) / 2,
		y = scroll_panel:y() + description:h() + TEXT_INPUT_HEIGHT_PAD,
		w = w,
		h = TEXT_INPUT_HEIGHT,
		layer = 100
	})
	self._searchbox.placeholder_text:set_text("")

	--Stop text from being cleared when escape is pressed.
	local orig_search_key_press = self._searchbox.search_key_press
	function self._searchbox:search_key_press(o, k)
		if k == Idstring("esc") then
			return
		end
		return orig_search_key_press(self, o, k)
	end

	--Vanilla disconnects keyboard handlers but leaves the text callback registered.
	--Inactive search boxes can therefore still receive text from other dialogs.
	--Clear the callback and reset its flag so it can reconnect when reactivated.
	local orig_disconnect_search_input = self._searchbox.disconnect_search_input
	function self._searchbox:disconnect_search_input()
		orig_disconnect_search_input(self)
		self.panel:enter_text(nil)
		self._enter_text_set = nil
	end

	--Do nothing, let the dialog handle Enter and Esc.
	function self._searchbox:esc_key_callback()
	end
	function self._searchbox:enter_key_callback()
	end

	--Prevent focus loss on mouse clicks.
	function self._searchbox:mouse_pressed()
		return false
	end
end

--Esc dismisses without submitting for single-button input dialogs.
--If can_cancel is false, single-button input dialogs cannot be dismissed.
--For multi-button dialogs, the cancel button callback will be executed if defined.
function TextInputDialog:dialog_cancel_callback()
	if #self._data.button_list == 1 then
		if self._data.can_cancel ~= false then
			self:fade_out_close()
		end
		return
	end

	return TextInputDialog.super.dialog_cancel_callback(self)
end

function TextInputDialog:button_pressed(index)
	if not self._searchbox then
		return
	end

	local callback = self._data.button_list[index].callback_func
	local data = {
		text = self._searchbox.text:text(),
	}

	self:fade_out_close()

	if callback then
		callback(data)
	end
end

function TextInputDialog:set_input_enabled(enabled)
	TextInputDialog.super.set_input_enabled(self, enabled)
	if not self._searchbox then
		return
	end

	if enabled then
		self._searchbox:connect_search_input()
	else
		self._searchbox:disconnect_search_input()
	end
end

function TextInputDialog:_dispose_searchbox()
	if self._searchbox then
		self._searchbox:destroy()
		self._searchbox = nil
	end
end

function TextInputDialog:close()
	self:_dispose_searchbox()
	TextInputDialog.super.close(self)
end

function TextInputDialog:force_close()
	self:_dispose_searchbox()
	TextInputDialog.super.force_close(self)
end

ncDialogs.TextInputDialog = TextInputDialog
