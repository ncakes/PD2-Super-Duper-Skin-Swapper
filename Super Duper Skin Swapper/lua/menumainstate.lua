if _G.OSA then
	return
end

--Temporary: warn people about deprecated features
Hooks:PostHook(MenuMainState, "at_enter", "SDSS-PostHook-MenuMainState:at_enter", function(self, ...)
	if not SDSS.settings.do_not_warn then
		local menu_title = managers.localization:text("sdss_dialog_title")
		local menu_message = "IMPORTANT: LEGENDARY WEAPON SKIN FEATURES HAVE BEEN REMOVED. DUPLICATE WEAPON SKIN HIDING HAS BEEN REMOVED.\n\nLegendary weapon attachment support is now provided by Optional Skin Attachments which is compatible with Super Duper Skin Swapper. Hide Duplicate Skins is available as a standalone mod and is also compatible. Both can be found on ModWorkshop."

		local menu_options = {
			{
				text = managers.localization:text("dialog_ok"),
				is_cancel_button = true,
				is_focused_button = true,
			},
			{
				text = "Do not show this message again",
				callback = function()
					SDSS.settings.do_not_warn = true
					SDSS:save_settings()
				end,
			}
		}
		QuickMenu:new(menu_title, menu_message, menu_options):Show()
	end
end)
