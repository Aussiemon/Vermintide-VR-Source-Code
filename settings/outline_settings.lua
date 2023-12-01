-- chunkname: @settings/outline_settings.lua

OutlineSettings = OutlineSettings or {}
OutlineSettings.colors = {
	arrow = {
		1,
		1,
		0,
		0.5
	},
	bow = {
		1,
		1,
		0,
		0.5
	},
	handgun = {
		1,
		1,
		0,
		0.5
	},
	staff = {
		1,
		1,
		0,
		0.5
	},
	interactable = {
		1,
		1,
		0,
		0.5
	},
	lever = {
		0,
		1,
		1,
		0.1
	},
	rapier = {
		1,
		1,
		0,
		0.5
	},
	enemy = {
		0,
		1,
		1,
		0.1
	}
}
OutlineSettings.ranges = {
	enemy = 100,
	interactable = 0.25,
	arrow = BowSettings.string_grab_radius,
	bow = BowSettings.bow_interaction_radius,
	handgun = HandgunSettings.interaction_radius,
	staff = StaffSettings.pickup_interaction_radius,
	lever = LeverSettings.interaction_radius,
	rapier = RapierSettings.interaction_radius
}
