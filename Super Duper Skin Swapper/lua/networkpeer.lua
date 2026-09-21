_G[ModPath] = _G[ModPath] or {}
if _G[ModPath][RequiredScript] then return end
_G[ModPath][RequiredScript] = true

if _G.OSA then
	return
end

--Block while in crafting menu so we don't accidentally flag other people for using skin attachments.
--Couldn't get this function to run, not sure why. Should be fine though.
--Also block in weapon color customization. Previously, opening weapon color triggered a close which restored blueprints but we block it now.
local orig_NetworkPeer__verify_content = NetworkPeer._verify_content
function NetworkPeer:_verify_content(...)
	local scene = managers.menu_scene and managers.menu_scene:get_current_scene_template()
	if scene == "blackmarket_crafting" or scene == "blackmarket_weapon_color" then
		return true
	end
	return orig_NetworkPeer__verify_content(self, ...)
end
