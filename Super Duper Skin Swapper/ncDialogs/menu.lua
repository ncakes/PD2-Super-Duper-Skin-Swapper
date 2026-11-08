function ncDialogs:show(title, message, options, settings)
	if not managers or not managers.system_menu then
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
	if #buttons == 1 then
		buttons[1].cancel_button = false
	end

	self:_show(title, message, buttons, parsed.focus_button, settings)
end

function ncDialogs:_show(title, message, buttons, focus, settings)
	local data = {
		id = self:_next_id(),
		title = title,
		text = message,
		button_list = buttons,
		focus_button = focus,
		no_buttons = false,
		force = settings.force == true,
	}

	managers.system_menu:show(data)
end
