_G[ModPath] = _G[ModPath] or {}
if _G[ModPath][RequiredScript] then return end
_G[ModPath][RequiredScript] = true

Hooks:PostHook(Setup, "init_managers", "SDSS-PostHook-Setup:init_managers", function(self, managers)
	managers.system_menu:add_dialog_shown_callback(function(dialog)
		if dialog:id() == "sdss_menu_id_67" then
			local gui = dialog._panel_script
			local message = gui._scroll_panel:child("text")
			if alive(message) then
				message:set_align("center")
				message:set_vertical("center")
				message:animate(function(o)
					local period = 1
					local elapsed = 0
					while true do
						local dt = coroutine.yield()
						elapsed = (elapsed + dt) % period
						local progress = elapsed / period
						local angle = math.sin(360 * progress) * 20
						o:set_rotation(angle)
					end
				end)
			end
		end
	end)
end)
