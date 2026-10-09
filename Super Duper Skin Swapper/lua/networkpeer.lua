_G[ModPath] = _G[ModPath] or {}
if _G[ModPath][RequiredScript] then return end
_G[ModPath][RequiredScript] = true

if _G.OSA then
	return
end

--Block so we don't accidentally flag other people for using skin attachments when blueprints are suppressed.
--Couldn't get this function to run during weapon customization, not sure why. Should be fine though.
local orig_NetworkPeer__verify_content = NetworkPeer._verify_content
function NetworkPeer:_verify_content(...)
	if SDSS.flags.blueprints_suppressed then
		return true
	end

	return orig_NetworkPeer__verify_content(self, ...)
end
