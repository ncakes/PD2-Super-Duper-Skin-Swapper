function ncDialogs:show_input(title, message, options, settings)
	if not managers or not managers.system_menu then
		return
	end

	local TextInputDialog = self.TextInputDialog
	if not TextInputDialog then
		log("[ncDialogs] ERROR: TextInputDialog not initialized")
		return
	end

	title = title or "ncDialogs"
	message = message or ""
	options = options or {}
	settings = settings or {}

	local parsed = self:_parse_options(options, title)
	if not parsed then
		return
	end

	local buttons = parsed.button_list
	if #buttons == 0 then
		buttons[1] = {text = managers.localization:text("dialog_ok")}
	end

	--Prevent double callback execution bug when pressing Esc on menus with one option.
	--TextInputDialog handles single-button Esc separately, but normalize the flag for consistency.
	if #buttons == 1 then
		buttons[1].cancel_button = false
	end

	local data = {
		id = self:_next_id(),
		title = title,
		text = message,
		button_list = buttons,
		focus_button = parsed.focus_button,
		initial_text = settings.initial_text or "",
		can_cancel = settings.can_cancel,
		no_buttons = false,
	}

	local dialog = TextInputDialog:new(managers.system_menu, data)
	managers.system_menu:_show_instance(dialog, settings.force == true)
end
