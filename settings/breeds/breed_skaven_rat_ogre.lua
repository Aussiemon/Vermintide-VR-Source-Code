-- chunkname: @settings/breeds/breed_skaven_rat_ogre.lua

local breed_data = {
	detection_radius = 9999999,
	has_inventory = false,
	slot_distance_modifier = 1,
	blood_effect_name = "fx/impact_blood_ogre",
	combat_detect_player_stinger = "enemy_ratogre_stinger",
	unit_template = "ai_unit_rat_ogre",
	walk_speed = 2,
	exchange_order = 1,
	animation_sync_rpc = "rpc_sync_anim_state_5",
	jump_slam_gravity = 19,
	reach_distance = 7,
	use_aggro = true,
	use_avoidance = false,
	ignore_nav_propagation_box = true,
	cannot_far_path = true,
	poison_resistance = 100,
	armor_category = 3,
	hit_reaction = "ai_default",
	door_reach_distance = 4.5,
	no_stagger_duration = false,
	default_inventory_template = "rat_ogre",
	ragdoll_on_death = false,
	smart_targeting_outer_width = 1.4,
	hit_effect_template = "HitEffectsRatOgre",
	smart_targeting_height_multiplier = 1.5,
	walk_only = false,
	radius = 2,
	combat_spawn_stinger = "enemy_ratogre_stinger",
	bone_lod_level = 0,
	target_selection = "horde_pick_closest_target_with_spillover",
	perception_previous_attacker_stickyness_value = -7.75,
	smart_object_template = "rat_ogre",
	aoe_radius = 1,
	proximity_system_check = true,
	death_reaction = "ai_default",
	perception = "perception_regular",
	player_locomotion_constrain_radius = 1.5,
	bot_opportunity_target_melee_range_while_ranged = 5,
	num_forced_slams_at_target_switch = 0,
	awards_positive_reinforcement_message = true,
	bot_opportunity_target_melee_range = 7,
	bots_should_flank = true,
	far_off_despawn_immunity = true,
	bot_optimal_melee_distance = 2,
	trigger_dialogue_on_target_switch = true,
	smart_targeting_width = 0.6,
	headshot_coop_stamina_fatigue_type = "headshot_special",
	behavior = "rat_ogre",
	base_unit = "units/beings/enemies/skaven_rat_ogre/chr_skaven_rat_ogre",
	aoe_height = 2.4,
	run_only = true,
	max_health = {
		default = 10,
		cart = 10
	},
	death_animations = {
		"death",
		"death_forward",
		"death_left",
		"death_right",
		"death_backward"
	},
	run_speed = {
		default = 7,
		cart = 7
	},
	size_variation_range = {
		default = {
			0.95,
			1.05
		},
		cart = {
			1.45,
			1.55
		}
	},
	allowed_layers = {
		bot_poison_wind = 1.5,
		ledges = 2.5,
		planks = 1.5,
		barrel_explosion = 10,
		bot_ratling_gun_fire = 3,
		ledges_with_fence = 2.5,
		doors = 1.5,
		teleporters = 5,
		smoke_grenade = 4,
		fire_grenade = 10
	},
	hit_zones = {
		full = {
			prio = 1,
			actors = {}
		},
		head = {
			prio = 1,
			actors = {
				"c_head"
			},
			push_actors = {
				"j_head",
				"j_spine1"
			}
		},
		neck = {
			prio = 1,
			actors = {
				"c_neck1",
				"c_spine1"
			},
			push_actors = {
				"j_head",
				"j_spine1"
			}
		},
		torso = {
			prio = 3,
			actors = {
				"c_spine2",
				"c_spine",
				"c_hips",
				"c_leftshoulder",
				"c_rightshoulder"
			},
			push_actors = {
				"j_spine1",
				"j_hips"
			}
		},
		left_arm = {
			prio = 4,
			actors = {
				"c_leftarm",
				"c_leftforearm",
				"c_lefthand"
			},
			push_actors = {
				"j_spine1"
			}
		},
		right_arm = {
			prio = 4,
			actors = {
				"c_rightarm",
				"c_rightforearm",
				"c_righthand"
			},
			push_actors = {
				"j_spine1"
			}
		},
		left_leg = {
			prio = 4,
			actors = {
				"c_leftupleg",
				"c_leftleg",
				"c_leftfoot",
				"c_lefttoebase"
			},
			push_actors = {
				"j_leftfoot",
				"j_rightfoot",
				"j_hips"
			}
		},
		right_leg = {
			prio = 4,
			actors = {
				"c_rightupleg",
				"c_rightleg",
				"c_rightfoot",
				"c_righttoebase"
			},
			push_actors = {
				"j_leftfoot",
				"j_rightfoot",
				"j_hips"
			}
		},
		tail = {
			prio = 4,
			actors = {
				"c_tail1",
				"c_tail2",
				"c_tail3",
				"c_tail4",
				"c_tail5",
				"c_tail6"
			},
			push_actors = {
				"j_hips"
			}
		}
	},
	blood_effect_nodes = {
		{
			triggered = false,
			node = "fx_wound_001"
		},
		{
			triggered = false,
			node = "fx_wound_002"
		},
		{
			triggered = false,
			node = "fx_wound_003"
		},
		{
			triggered = false,
			node = "fx_wound_004"
		},
		{
			triggered = false,
			node = "fx_wound_005"
		},
		{
			triggered = false,
			node = "fx_wound_006"
		},
		{
			triggered = false,
			node = "fx_wound_007"
		},
		{
			triggered = false,
			node = "fx_wound_008"
		},
		{
			triggered = false,
			node = "fx_wound_009"
		},
		{
			triggered = false,
			node = "fx_wound_010"
		},
		{
			triggered = false,
			node = "fx_wound_011"
		},
		{
			triggered = false,
			node = "fx_wound_012"
		},
		{
			triggered = false,
			node = "fx_wound_013"
		}
	},
	blood_intensity = {
		mtr_skin = "blood_intensity"
	},
	num_push_anims = {},
	debug_color = {
		255,
		20,
		20,
		20
	},
	blackboard_init_data = {
		ladder_distance = math.huge
	}
}

Breeds.skaven_rat_ogre = table.create_copy(Breeds.skaven_rat_ogre, breed_data)

local action_data = {
	follow = {
		cooldown = -1,
		start_anims_name = {
			bwd = "move_start_bwd",
			fwd = "move_start_fwd",
			left = "move_start_left",
			right = "move_start_right"
		},
		start_anims_data = {
			move_start_fwd = {},
			move_start_bwd = {
				dir = -1,
				rad = math.pi
			},
			move_start_left = {
				dir = 1,
				rad = math.pi / 2
			},
			move_start_right = {
				dir = -1,
				rad = math.pi / 2
			}
		}
	},
	special_attack_slam = {
		range = 4,
		height = 3,
		width = 0.4,
		cooldown = 1,
		rotation_time = 1,
		fatigue_type = "blocked_sv_cleave",
		offset_forward = 0,
		damage_type = "clawing",
		move_anim = "move_fwd",
		offset_up = 0,
		attack_anim = {
			"attack_slam",
			"attack_slam_2",
			"attack_slam_3",
			"attack_slam_4"
		},
		damage = {
			default = 5,
			cart = 10
		}
	}
}

BreedActions.skaven_rat_ogre = table.create_copy(BreedActions.skaven_rat_ogre, action_data)
