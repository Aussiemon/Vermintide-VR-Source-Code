-- chunkname: @settings/player_health_settings.lua

PlayerHealthSettings = {
	damage_indicator_fade_out_speed = 0.5,
	damage_indicator_start_alpha = 0.25,
	regeneration_speed = 3,
	haptic_feedback_duration = 0.25,
	regeneration_delay = 5,
	max_health = {
		default = 40,
		cart = 40
	},
	injury_levels = {
		uninjured = {
			health = {
				max = 1,
				min = 0.6
			}
		},
		light_injured = {
			color_grading = "environment/textures/color_grading_desaturated_half",
			health = {
				max = 0.59,
				min = 0.3
			}
		},
		heavy_injured = {
			color_grading = "environment/textures/color_grading_desaturated_full",
			health = {
				max = 0.29,
				min = 0
			}
		}
	}
}
