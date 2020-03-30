# Changelog

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
