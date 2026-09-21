# Changelog

## v3.2

*2026-09-21 - Update 248.1*

- Filter performance update:
	- Prevent filters from being reloaded on UI update if filter settings were not changed.
	- Prevent the base game from doing unnecessary sorting/filtering on skins since it will be overwritten by SDSS.
	- Added a cache for data used to process filters.
	- Reworked handling of unowned IP content skins.
- Bugfixes:
	- Fixed a bug in the Restoration Mod compatibility where weapon icons would not be used on swapped skins.
	- Added some extra checks for detecting when Optional Skin Attachments and Hide Duplicate Skins are active.
	- Fixed an issue where the scrolling was not reset on a filter refresh.
- SDSS standalone changes (i.e. when not using OSA):
	- Updated handling of legendary attachments leftover from before installing SDSS.
	- Added handling for DLC attachments leftover from being installing SDSS.
	- Fixed an issue where attachments which are normally part of a skin would not be added to inventory if a weapon using that skin was sold.
	- Fixed a bug where customizing a gadget or reticle would restore skin blueprints while still in weapon customization.
- Cleanup:
	- Removed tempfix for custom BeardLib skins that use the old weapon icon path.

## v3.1

*2026-09-11 - Update 247.3*

- Bug fixes:
	- Fixed global values not being correctly assigned to custom weapon attachments (thanks DeadMansChest).
	- Fixed an issue where attachments on custom weapon skins were not deleted when Custom Skins Safe Mode was enabled.
	- Fixed an issue which was blocking the bugfix for renaming weapons after removing legendary skins.
	- Fixes for compatibility with Multiple Weapon Mod Rows mod.
- Filter changes:
	- Filter status is now shown as a popup when mousing over the filter button to prevent the buttons from moving.
	- Individual filters can be reset by right clicking the filter button.
	- Filters are only saved to disk when leaving the weapon customization screen.
	- Weapon category filter opens a submenu to filter by the same category as your current weapon or a specific category.
	- Weapon family filter opens a submenu to choose a weapon family. The "Same Family" option has been removed. Only a few weapons have a family so it almost always behaved as "Correct Weapon".
	- Weapon families updated to only include the weapons that share enough parts.
		- AK family: AK, (Golden) AK.762, IZHMA 12G, RPK, (Akimbo) Krinkov.
		- CAR family: AMCAR, CAR-4, AMR-16, (Akimbo) Para.
		- Reinfeld family: Reinfeld 880, Locomotive 12G.
		- Chimano family removed.
- Streamlined integration with Optional Skin Attachments and Hide Duplicate Skins (separate mods):
	- Replaced the deprecated features warning with a welcome message. New users will be given a prompt to install OSA/HDS on first launch.
		- OSA and HDS can now be downloaded in-game via the BLT updater.
		- Download buttons for OSA/HDS have been added to the SDSS options menu. They only appear if the mods aren't installed.
	- HDS v2.1+ and OSA v5.0+ come with pre-configured settings for SDSS.
		- A new installation of OSA or HDS will use the presets automatically when SDSS is detected.
		- OSA and HDS have buttons in their options menus to manually apply the recommended presets.
	- Added shortcuts to the OSA/HDS options menus inside the SDSS options menu (if installed).
- Cleanup:
	- Refactor to use shared utilities.

## v3.0.2

*2026-02-04 - Update 242.2*

- Added an option to disable the background of the skin mini-icons.

## v3.0.1

*2026-02-03 - Update 242.2*

- Update for compatibility with Restoration Mod.

## v3.0

*2026-02-02 - Update 242.2*

- Major overhaul for compatibility with Optional Skin Attachments and Hide Duplicate Skins. Super Duper Skin Swapper will work without these mods but you will lose some functionality.
- Features which have been moved to other mods:
	- All legendary skin features have been moved to Optional Skin Attachments.
	- Support for skin-included attachments has been moved to Optional Skin Attachments.
	- Weapon color settings moved to Optional Skin Attachments.
	- Preview options moved to Optional Skin Attachments.
	- Duplicate hiding moved to Hide Duplicate Skins.
- Fixed a bug in the base game where skins were not sorted in the correct order.
- Significant performance boost due to new implementation of filters.
- Filter changes:
	- Filters update immediately.
	- Filters are always enabled and persistent.
	- Added a sorting filter.
	- Removed confirmation dialogs.
	- Updated safe filter to restore IP content skins.
	- Removed wear filter.
	- Removed single/akimbo weapon filter option (now a base game feature).
- UI changes:
	- Weapon customization always uses the single-hand version of skin icons.
	- Active filters are highlighted.
	- Added a background to the weapon skin mini-icon in inventory.
- Custom weapon skins:
	- Attachments on BeardLib custom weapon skins disabled. Can be overridden by OSA settings.
	- Tempfix for custom BeardLib skins that use the old weapon icon path.
- Removed features:
	- U242 Vlad's Rodina texture fix removed (fixed in base game now).

## v2.4

*2026-01-20 - Update 242*

- Fixes for U242 courtesy of [6IX].
	- Crashfix related to Midas Touch Barrel.
	- Fix weapon skin icons when modifying weapons.
	- Fix weapon skin mini-icons in inventory.
	- Fix missing textures when using Vlad's Rodina skin with AK default magazine and Speed Pull Magazine.
	- Crashfix for Epic games.

## v2.3

*2021-05-26 - Update 207.1*

- Fixed an issue where rarity backgrounds could be set incorrectly for BeardLib universal skins.
- Tempfix for an issue where the Immortal Python default weapon color option wasn't being set.

## v2.2

*2021-04-26 - Update 205*

- Filter buttons are now enabled by default. Filter options have been extended.
	- Option to filter by safe.
	- Option to filter by rarity.
	- Option to filter by wear.
	- Option to filter by weapon family.
- Unowned skins are no longer hidden by default. "Hide Unowned Skin" setting has been removed and is now available as a filter button instead.
- Added "Fast Previews" option. When enabled, double clicking an owned skin will preview it instead of applying it. Disabled by default.
- Added a slider to limit number of page buttons. Doesn't need to be changed unless your page numbers are still getting cut off.
- Changed some default settings, only affects new users.
	- Default duplicate hiding mode changed to "Best Normal & Stat".
	- Legendary attachments will be allowed on akimbo variants by default.

## v2.1.1

*2021-04-24 - Update 205*

- Fixed a small bug in duplicate hiding that could cause crashes (thanks =THT= Communismo).

## v2.1

*2021-04-23 - Update 205*

- Added a page number scaling option to prevent page numbers from being cut off due to too many skins. Enabled by default.
	- Note: if you have a ridiculous amount of duplicate skins, page numbers might still be cut off. Turn on duplicate skin hiding if this is happening to you. This works even if you own every skin in the game.
- Added an option to preview different wears on skins. Enabled by default.
- Added an option to filter which skins are shown. This option is still in beta and is disabled by default.
	- Added an option to save the chosen filter settings after the game is reloaded (e.g. after playing a heist or closing the game). This option is still in beta and is disabled by default.
- Removed the option to enable/disable skin swapping for normal skins. This is being replaced by the filter settings.
- Removed the option to enable/disable skin swapping for BeardLib skins. This option is now always enabled.

## v2.0.3

*2021-04-11 - Update 205*

- Remove stats option has been modified to remove all weapon stats except for concealment in order to prevent detection risk sync issues.
- Midas Touch Barrel will now use the default position for the front sight post when equipping the Marksman Sight (to prevent the front sight post from floating in the air).

## v2.0.2

*2021-04-08 - Update 205*

- Fixed an issue where default color pattern scale was being applied to weapon skins (thanks Sydney).
- Internal changes:
	- Reworked hiding of legendary skins on akimbo weapon variants.
	- Removed a useless quickplay check.

## v2.0.1

*2021-04-06 - Update 205*

- Hotfix for a crash related to weapons skins without attachments.

## v2.0

*2021-04-05 - Update 205*

- Updated the mod to work with the latest version of the game (U205).
	- Crashfix: resolved compatibility issues with BeardLib's updated universal weapon skin system.
	- Crashfix: resolved compatibility issues with U201 changes to the weapon color system.
	- Fixed an issue where the rarity background for weapon colors was not being set properly (thanks GreenGhost21).
- Attachments which are part of weapon skins can now be equipped for free like in the base game.
- DLC attachments which are part of weapons skins can now be equipped even if you do not own the DLC (like in the base game).
- Added option to set Immortal Python as default weapon color. Disabled by default.
- Added option to choose default default paint scheme for weapon colors.
- Added option to choose default wear for weapon colors.
- Added option to choose default pattern scale for weapon colors.

## v1.5

*2020-04-27 - Update 199 Mark II Hotfix 2*

- Added option to enable/disable skin swapping in options menu.
- Fixed a crash that could occur if custom skins were uninstalled without first removing them from weapons.

## v1.4

*2020-03-30 - Update 199 Mark II Hotfix 2*

- Added the ability to customize the laser color on legendary attachments. Vlad's Rodina Laser and Santa's Slayers Laser could already use custom colors and have not been changed. List of affected attachments:
	- Admiral Barrel
	- Anarcho Barrel
	- Apex Barrel
	- Astatoz Foregrip
	- Demon Barrel
	- Mars Ultor Barrel
	- Plush Phoenix Barrel
- Added option to allow BeardLib custom skins to be used on all weapons. Does not affect BeardLib universal skins. Enabled by default.
- Added option to remove stats from legendary attachments. Disabled by default.
- Minor/internal changes:
	- Reworked localization integration with Suppressed Raven Admiral Barrel mod.
	- Reworked BlackMarketManager:player_owns_silenced_weapon() check when SRAB is in use.
	- Visible skins are set after BlackMarketManager:load() even when online.

## v1.3.1

*2020-03-26 - Update 199 Mark II Hotfix 2*

- Legendary attachments on single Crosskill and Akimbo Deagle disabled due to sync issues. Will look into bringing them back in the future.
- Legendary attachments are still available on the Akimbo Kobus 90 and Akimbo Judge. Legendary attachments applied on Akimbo Kobus 90 and Akimbo Judge are now validated.

## v1.3

*2020-03-26 - Update 199 Mark II Hotfix 2*

- Reworked method for validating weapon modifications.
- Reworked method for removing legendary attachments from Akimbo Kobus 90 and Akimbo Judge when "Allow Variants" is off to prevent sync issues.
- Reworked method for adding legendary attachments to single Crosskill and Akimbo Deagle to prevent sync issues.

## v1.2

*2020-03-24 - Update 199 Mark II Hotfix 2*

- Added support for custom skins.

## v1.1.1

*2020-03-22 - Update 199 Mark II Hotfix 2*

- Skin mini-icon now supports BeardLib's universal skins.

## v1.1

*2020-03-22 - Update 199 Mark II Hotfix 2*

- Real skin will be displayed as a mini-icon when a weapon is selected in inventory.
- Wear override option removed.

## v1.0

*2020-03-21 - Update 199 Mark II Hotfix 2*

- Initial release.
