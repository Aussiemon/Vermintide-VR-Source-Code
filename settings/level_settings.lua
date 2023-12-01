-- chunkname: @settings/level_settings.lua

LevelSettings = LevelSettings or {}
LevelSettings.levels = {
	inn = {
		package_name = "levels/inn/inn",
		resource_name = "levels/inn/inn"
	},
	cart = {
		wind_strength = 3,
		package_name = "levels/rail/rail_cart_02_test",
		resource_name = "levels/rail/rail_cart_02_test"
	},
	drachenfels = {
		survival_time = 300,
		package_name = "levels/vr/drachenfels",
		final_wave = 10,
		resource_name = "levels/vr/drachenfels"
	},
	forest = {
		wind_strength = 5,
		package_name = "levels/forest/forest",
		survival_time = 300,
		resource_name = "levels/forest/forest",
		final_wave = 10
	},
	loading = {
		package_name = "levels/loading/loading",
		resource_name = "levels/loading/loading"
	}
}
LevelSettings.default_level = "inn"
LevelSettings.level_sequence = {
	"inn",
	"drachenfels",
	"forest",
	"cart"
}
