-- chunkname: @settings/bow_settings.lua

BowSettings = {
	base_vibration_strength = 0.003,
	bow_interaction_radius = 0.3,
	time_until_arrow_respawns_after_shot = 0.4,
	draw_deadzone = 0.0005,
	string_grab_radius = 0.35,
	gravity = 15,
	damage = 1,
	always_dismember = false,
	max_draw_distance = 0.85,
	rotation_speed = 10,
	min_draw_distance = 0.17,
	force = 0.5,
	arrow_speed = 100,
	arrow_base_rotation = {
		-90,
		0,
		0
	},
	base_scale = {
		1.2,
		1.2,
		1.2
	},
	hmd_forward_influence = {
		look = 0,
		seek_modifier = 1,
		seek = 0,
		half_angle = 45
	},
	grip_position_offset = {
		0,
		0,
		-0.005
	},
	grip_rotation_offset = {
		-50,
		0,
		0
	},
	hand_rotation_offset = {
		50,
		0,
		0
	},
	arrow_push_cloth = {
		speed = 75,
		radius = 3
	}
}
