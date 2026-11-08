function ncDialogs:_next_id()
	self._id = (self._id or 0) + 1
	return "ncdialogs_menu_id_" .. tostring(self._id)
end

--Convert QuickMenu-style options into native dialog buttons.
--Returns nil on invalid options.
function ncDialogs:_parse_options(options, title)
	local buttons = {}
	local focus

	for i, option in ipairs(options) do
		if option.is_cancel_button and i ~= #options then
			log(string.format(
				"[ncDialogs] ERROR: is_cancel_button only allowed on last option: %s option %d/%d (%s)",
				tostring(title), i, #options, tostring(option.text)
			))
			return nil
		end

		local callback_func
		local callback = option.callback
		local data = option.data

		--Preserve callback data while forwarding additional arguments.
		if callback then
			if data ~= nil then
				callback_func = function(...)
					callback(data, ...)
				end
			else
				callback_func = function(...)
					callback(...)
				end
			end
		end

		buttons[i] = {
			text = option.text,
			cancel_button = option.is_cancel_button,
			callback_func = callback_func,
		}

		if option.is_focused_button then
			focus = i
		end
	end

	return {
		button_list = buttons,
		focus_button = focus,
	}
end
