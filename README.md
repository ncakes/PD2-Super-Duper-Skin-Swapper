# Super Duper Skin Swapper

## Overview

Super Duper Skin Swapper allows any skin (and weapon color) to be used on any weapon. Main features:

- **Filters:** Filter buttons are added to the weapon customization UI to find skins by rarity, safe, and weapon category. Individual filters can be reset by right clicking.
- **Visual Indicator:** Weapons with a swapped skin are displayed as a default weapon with a rarity background. The equipped skin will be shown as a mini-icon (similar to how weapon colors work).
- **Fast Preview:** Option to quickly preview skins by double-clicking. Off by default.

As of v3.0, Super Duper Skin Swapper is compatible with [Optional Skin Attachments](https://github.com/ncakes/PD2-Optional-Skin-Attachments) and [Hide Duplicate Skins](https://github.com/ncakes/PD2-Hide-Duplicate-Skins). These can also be downloaded in-game via the SDSS options menu. SDSS no longer natively supports skin-included attachments or duplicate skin hiding.

### How Search Works

Searching has been added in SDSS 4.0. Search terms are separated by spaces. Every term must match the beginning of a word in the **skin name** or **weapon name**. Terms can match across both names and capitalization doesn't matter.

- All terms must match, but order doesn't matter.
	- Example: `safe car crash` and `car crash safe` both find the CAR-4 Safe Crasher.
- Matches must be at the start of a word.
	- Example: `safe crash` finds the CAR-4 Safe Crasher, but `safe ash` does not.
- Special characters are handled flexibly and can usually be left out.
	- Example: `car-4`, `car 4`, and `car4` all find CAR-4 skins.

Search works like a normal filter but the search is not saved when restarting or reloading the game. Right-clicking the search button resets the search, just like any other filter.

## Compatibility

Super Duper Skin Swapper v3.0+ is compatible with [Optional Skin Attachments](https://github.com/ncakes/PD2-Optional-Skin-Attachments) v4.0+ and [Hide Duplicate Skins](https://github.com/ncakes/PD2-Hide-Duplicate-Skins) v2.0+.

Update 242 changed how skin icons are handled and vanilla players will now see a missing texture in the loadout screen. Modded players with OSA or SDSS will see the real weapon with a rarity background. Sometimes there is a bug where skins flash for an instant and then disappear, showing a default weapon. This is a base-game issue which affects both modded and vanilla players. I am not sure what causes this bug. Regardless, when in-game, all players will be able to see the skin applied on your gun.

SDSS is compatible with custom weapon skins, I tested it with the [AK.762 | Cyber Midnight Reborn](https://modworkshop.net/mod/25718).

SDSS is compatible with custom weapons, I tested it with the [Akimbo Steakout 12G](https://modworkshop.net/mod/19092).

## Installation

This mod requires [SuperBLT](https://superblt.znix.xyz).

Download `Super-Duper-Skin-Swapper_<ver>.zip` from the [latest release page](https://github.com/ncakes/PD2-Super-Duper-Skin-Swapper/releases/latest) and extract the entire contents to your `mods` folder.

```
C:\Program Files (x86)\Steam\steamapps\common\PAYDAY 2\mods
```

## Acknowledgments

Credit goes to SAR_Boats for writing the original [Super Skin Swapper](https://modworkshop.net/mod/17343).

Big thanks to Kamikaze94 for updating [WolfHUD](https://github.com/Kamikaze94/WolfHUD) to be compatible with this mod.

Thanks to GreenGhost21 for feedback during development.

Many thanks to Ludor Experiens and △urelius for their fixes that kept this mod alive between U201 and U205.

Many thanks to [6IX] for the U242 fixes.
