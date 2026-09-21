_G[ModPath] = _G[ModPath] or {}
if _G[ModPath][RequiredScript] then return end
_G[ModPath][RequiredScript] = true

if SDSS:is_osa_installed() and SDSS:is_hds_installed() then
	return
end

--If OSA/HDS not installed, enable the download buttons in the settings.
--Display warning if user has not opted out.
Hooks:PostHook(MenuMainState, "at_enter", "SDSS-PostHook-MenuMainState:at_enter", function(...)
	if not SDSS:is_osa_installed() then
		ncUtils.Menu:enable_item("dl_osa_button", SDSS)
	end
	if not SDSS:is_hds_installed() then
		ncUtils.Menu:enable_item("dl_hds_button", SDSS)
	end

	--Clicking do not warn will never show the message again.
	--Clicking add to download manager creates the OSA/HDS directories and adds the downloads to the BLT updater.
	--The directories are then detected as installed even if the user doesn't install OSA/HDS immediately.
	if not SDSS.settings.do_not_warn then
		local menu_title = managers.localization:text("sdss_dialog_title")
		local menu_message = managers.localization:text("sdss_dialog_welcome")
		local menu_options = {
			{
				text = managers.localization:text("sdss_dialog_add_to_download_manager"),
				callback = function()
					SDSS:add_osa_hds_to_updates()
				end,
			},
			{
				text = managers.localization:text("sdss_dialog_do_not_show_again"),
				is_focused_button = true,
				callback = function()
					SDSS.settings.do_not_warn = true
					ncUtils.Settings:save(SDSS)
				end,
			}
		}
		QuickMenu:new(menu_title, menu_message, menu_options):Show()
	end
end)
