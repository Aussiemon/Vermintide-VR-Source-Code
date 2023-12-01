-- chunkname: @settings/staff_settings.lua

StaffSettings = {
	always_dismember_impact = false,
	min_charge_time = 0.1,
	projectile_speed_min = 8,
	charge_time = 3,
	max_sound_movement_speed = 5,
	min_spiral_speed = 2,
	projectile_scale_max = 1,
	impact_force = 2,
	charge_pull_time = 2,
	pickup_interaction_radius = 0.5,
	impact_damage = 3,
	projectile_speed_max = 26,
	flight_damage_radius_min = 0.1,
	spiral_expansion_time = 0.2,
	always_dismember_flight = false,
	gravity_min = 0.05,
	impact_damage_radius_max = 1.2,
	min_throw_length = 0.1,
	uses_vectorfield_suffix = true,
	flight_damage_radius_max = 0.5,
	projectile_scale_min = 0.2,
	flight_damage = 2,
	gravity_max = 0.3,
	draw_interaction_radius = 0.25,
	impact_damage_radius_min = 0.3,
	fire_skull_sound_time = 1.8,
	flight_force = 0.25,
	max_spiral_speed = 5,
	melee = {
		force = 0.75,
		attack_threshold_speed = 1,
		damage = 1,
		hit_vibration_strength = 0.0035
	},
	grip_position_offset = {
		0,
		0,
		-0.12
	},
	grip_rotation_offset = {
		0,
		0,
		225
	},
	hmd_forward_influence = {
		look = 0,
		seek_modifier = 1,
		seek = 0,
		half_angle = 45
	},
	impact_explosion = {
		max_force = 5,
		max_radius = 3,
		time_to_play = 0.2
	},
	charge_pull_ragdolls = {
		max_lift_speed = 60,
		max_bonus_inner_radius = 1,
		min_inner_radius = 1,
		min_radius = 1,
		min_speed = 3,
		max_bonus_radius = 1.5,
		max_bonus_speed = 60
	},
	projectile_vortex_ragdolls = {
		pull_speed = 5,
		radius = 5,
		whirl_speed = 1
	},
	charge_pull_particles = {
		max_charge_whirl_speed = 6,
		max_charge_radius = 5,
		max_charge_pull_speed = 5
	},
	charge_pull_cloth = {
		max_charge_whirl_speed = 10,
		max_charge_radius = 7,
		max_charge_pull_speed = 10
	},
	projectile_push_cloth = {
		radius = 5,
		push_speed = 30
	},
	ragdoll_particle_link_pull = {
		speed = 1
	},
	vibration_functions = {
		pickup_staff = function (dt, time_since_start)
			local total_time = 0.5
			local start_strength = 0
			local end_strength = 0
			local time_left = total_time - time_since_start
			local percentage_done = time_since_start / total_time
			local done = total_time <= time_since_start
			local vibration_strength = math.lerp(start_strength, end_strength, percentage_done)

			return vibration_strength, done
		end,
		pickup_off_hand = function (dt, time_since_start)
			local total_time = 0.4
			local start_strength = 0
			local end_strength = 0
			local time_left = total_time - time_since_start
			local percentage_done = time_since_start / total_time
			local done = total_time <= time_since_start
			local vibration_strength = math.lerp(start_strength, end_strength, percentage_done)

			return vibration_strength, done
		end,
		charge_staff = function (dt, time_since_start)
			local ramp_up_time = 3
			local start_strength = 0
			local end_strength = 0
			local percentage_done = math.min(3, time_since_start) / ramp_up_time
			local vibration_strength = math.lerp(start_strength, end_strength, percentage_done)

			return vibration_strength, false
		end,
		charge_off_hand = function (dt, time_since_start)
			local ramp_up_time = 4
			local start_strength = 0
			local end_strength = 0
			local percentage_done = math.min(3, time_since_start) / ramp_up_time
			local vibration_strength = math.lerp(start_strength, end_strength, percentage_done)

			return vibration_strength, false
		end
	}
}
