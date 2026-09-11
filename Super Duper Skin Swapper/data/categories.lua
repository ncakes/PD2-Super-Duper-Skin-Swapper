--These are the internal names for the main categories.
--Some weapons also have an additional "akimbo" or "revolver" category which we ignore.
--Special weapons have a category not in this list, we will categorize them all as "special".
SDSS.categories = {
	"pistol",
	"shotgun",
	"smg",
	"assault_rifle",
	"lmg",
	"snp",
}

--Official AK/CAR definitions can be found in akm4_shootout
SDSS.families = {
	--CAR
	car = {
		"amcar",--AMCAR, official
		"new_m4",--CAR-4, official
		"m16",--AMR-16, official
		"olympic",--Para, official
		"x_olympic",--Akimbo Para
	},
	--AK
	ak = {
		"ak74",--AK, official
		"akm",--AK.762, official
		"akm_gold",--Golden AK.762, official
		"saiga",--IZHMA 12G, official
		"rpk",--RPK, official
		"akmsu",--Krinkov, official
		"x_akmsu",--Akimbo Krinkov
		--"flint",--AK17, official but doesn't actually share parts.
	},
	--Mossberg
	mossberg = {
		"r870",--Reinfeld 880
		"serbu",--Locomotive 12G
	},
}
