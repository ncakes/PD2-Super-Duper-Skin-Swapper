if _G.OSA then
	return
end

--Block while in crafting menu so we don't accidentally flag other people for using skin attachments.
--Couldn't get this function to run, not sure why. Should be fine though.
local orig_NetworkPeer__verify_content = NetworkPeer._verify_content
function NetworkPeer:_verify_content(...)
	if managers.menu_scene and managers.menu_scene:get_current_scene_template() == "blackmarket_crafting" then
		return true
	end
	return orig_NetworkPeer__verify_content(self, ...)
end
