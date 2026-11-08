local function build_classic_pages(buttons, page_size, next_page_text, first_page_text)
	local count = #buttons
	local cancel_button
	if count > 0 and buttons[count].cancel_button then
		cancel_button = buttons[count]
		count = count - 1
	end

	local total = math.max(1, math.ceil(count / page_size))
	local pages = {}

	for page = 1, total do
		local page_buttons = {}
		local first = (page - 1) * page_size + 1
		local last = math.min(page * page_size, count)

		for i = first, last do
			page_buttons[#page_buttons + 1] = buttons[i]
		end

		local page_focus
		if total > 1 then
			--Left arrow is select button glyph U+E004
			--Right arrow is start button glyph U+E005
			local text = page < total and (next_page_text .. " ") or (" " .. first_page_text)
			local navigation = (page < total) and (page + 1) or 1
			--Still need to set the callback later.
			page_buttons[#page_buttons + 1] = {text = text, navigation = navigation}
			page_focus = #page_buttons
		end

		if cancel_button then
			page_buttons[#page_buttons + 1] = cancel_button
		end

		page_focus = page_focus or #page_buttons

		pages[page] = {buttons = page_buttons, focus = page_focus}
	end

	return pages
end

function ncDialogs:show_paginated_classic(title, message, options, settings)
	if not managers or not managers.system_menu then
		return
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

	local buttons = parsed.button_list
	if #buttons == 0 then
		buttons[1] = {text = managers.localization:text("dialog_ok")}
	end

	--Prevent double callback execution bug when pressing Esc on menus with one option.
	if #buttons == 1 then
		buttons[1].cancel_button = false
	end

	local pages = build_classic_pages(
		buttons,
		page_size,
		settings.next_page_text or "NEXT PAGE",
		settings.first_page_text or "FIRST PAGE"
	)

	--Calculate initial focus if specified.
	local initial_page = 1
	local initial_focus
	if parsed.focus_button then
		local focus = parsed.focus_button
		local is_cancel = buttons[focus].cancel_button

		if is_cancel then
			initial_focus = #pages[1].buttons
		else
			initial_page = math.ceil(focus / page_size)
			initial_focus = (focus - 1) % page_size + 1
		end
	end

	local show_page
	show_page = function(page, focus)
		local current = pages[page]
		local page_title = #pages > 1 and string.format("%s (%d/%d)", title, page, #pages) or title
		return self:_show(page_title, message, current.buttons, focus or current.focus, settings)
	end

	--Setup navigation callback.
	if #pages > 1 then
		for _, page_data in ipairs(pages) do
			for _, button in ipairs(page_data.buttons) do
				if button.navigation then
					button.callback_func = function()
						show_page(button.navigation)
					end
				end
			end
		end
	end

	return show_page(initial_page, initial_focus)
end
