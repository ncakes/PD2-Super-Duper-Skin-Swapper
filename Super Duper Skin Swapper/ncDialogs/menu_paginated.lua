function ncDialogs:show_paginated(title, message, options, settings)
	if not managers or not managers.system_menu then
		return
	end

	local PaginatedDialog = self.PaginatedDialog
	if not PaginatedDialog then
		log("[ncDialogs] WARNING: PaginatedDialog not initialized, falling back to classic pagination")
		return self:show_paginated_classic(title, message, options, settings)
	end

	title = title or "ncDialogs"
	message = message or ""
	options = options or {}
	settings = settings or {}

	local page_size = settings.page_size or 8
	if type(page_size) ~= "number" or page_size < 1 or page_size % 1 ~= 0 then
		return
	end

	local parsed = self:_parse_options(options, title)
	if not parsed then
		return
	end

	local option_buttons = parsed.button_list
	local cancel_button
	local focus = parsed.focus_button
	do
		local i = #option_buttons
		if i > 0 then
			if option_buttons[i].cancel_button then
				--Focus -1 means focus on cancel button.
				if focus == i then
					focus = -1
				end
				cancel_button = option_buttons[i]
				option_buttons[i] = nil
			end
		end
	end

	if #option_buttons == 0 and not cancel_button then
		cancel_button = {text = managers.localization:text("dialog_ok")}
	end

	--Prevent double callback execution bug when pressing Esc on menus with one option.
	if #option_buttons == 0 and cancel_button then
		cancel_button.cancel_button = nil
	end

	local data = {
		id = self:_next_id(),
		title = title,
		text = message,
		option_buttons = option_buttons,
		cancel_button = cancel_button,
		focus_button = focus,
		page_size = page_size,
		no_buttons = false,
	}

	local dialog = PaginatedDialog:new(managers.system_menu, data)
	managers.system_menu:_show_instance(dialog, settings.force == true)
end
