_G[ModPath] = _G[ModPath] or {}
if _G[ModPath][RequiredScript] then return end
_G[ModPath][RequiredScript] = true

--Actually leaving weapon customization. Also applies to previewing mods.
Hooks:PreHook(MenuCallbackHandler, "_left_blackmarket", "SDSS-PreHook-MenuCallbackHandler:_left_blackmarket", function()
	ncUtils.Settings:save(SDSS)

	if not _G.OSA then
		SDSS:restore_blueprints()
	end
end)
