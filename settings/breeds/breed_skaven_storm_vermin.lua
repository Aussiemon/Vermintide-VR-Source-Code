﻿-- chunkname: @settings/breeds/breed_skaven_storm_vermin.lua

local breed_data = {
	has_inventory = true,
	using_first_attack = true,
	awards_positive_reinforcement_message = true,
	cannot_far_path = true,
	bone_lod_level = 1,
	smart_targeting_outer_width = 1,
	walk_speed = 2,
	animation_sync_rpc = "rpc_sync_anim_state_5",
	aoe_radius = 0.4,
	reach_distance = 2,
	target_selection = "horde_pick_closest_target_with_spillover",
	armor_category = 2,
	radius = 1,
	detection_radius = 12,
	patrol_detection_radius = 10,
	hit_reaction = "ai_default",
	panic_close_detection_radius_sq = 9,
	door_reach_distance = 3,
	default_inventory_template = "halberd",
	wwise_voice_switch_group = "stormvermin_vce",
	ragdoll_on_death = true,
	hit_effect_template = "HitEffectsStormVermin",
	smart_targeting_height_multiplier = 2.5,
	walk_only = true,
	horde_behavior = "storm_vermin",
	unit_template = "ai_unit_storm_vermin",
	no_stagger_duration = true,
	disable_crowd_dispersion = true,
	perception_previous_attacker_stickyness_value = -4.5,
	smart_object_template = "special",
	death_reaction = "ai_default",
	perception = "perception_regular",
	player_locomotion_constrain_radius = 0.7,
	death_sound_event = "Play_stormvermin_die_vce",
	weapon_reach = 2,
	variation_setting = "skaven_storm_vermin",
	horde_target_selection = "horde_pick_closest_target_with_spillover",
	smart_targeting_width = 0.2,
	death_squad_detection_radius = 8,
	behavior = "storm_vermin",
	base_unit = "units/beings/enemies/skaven_stormvermin/chr_skaven_stormvermin",
	aoe_height = 1.7,
	max_health = {
		default = 2
	},
	run_speed = {
		default = 2.3
	},
	size_variation_range = {
		default = {
			1.05,
			1.15
		}
	},
	animation_merge_options = {
		idle_animation_merge_options = {},
		walk_animation_merge_options = {},
		move_animation_merge_options = {}
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
				"j_neck",
				"j_spine1"
			}
		},
		neck = {
			prio = 1,
			dismember_chance = 1,
			actors = {
				"c_neck"
			},
			push_actors = {
				"j_head",
				"j_neck",
				"j_spine1"
			}
		},
		torso = {
			prio = 3,
			dismember_chance = 1,
			actors = {
				"c_spine2",
				"c_spine",
				"c_hips"
			},
			push_actors = {
				"j_neck",
				"j_spine1",
				"j_hips"
			}
		},
		left_arm = {
			prio = 4,
			dismember_chance = 1,
			actors = {
				"c_leftarm",
				"c_leftforearm",
				"c_lefthand"
			},
			push_actors = {
				"j_spine1",
				"j_leftshoulder",
				"j_leftarm"
			}
		},
		right_arm = {
			prio = 4,
			dismember_chance = 1,
			actors = {
				"c_rightarm",
				"c_rightforearm",
				"c_righthand"
			},
			push_actors = {
				"j_spine1",
				"j_rightshoulder",
				"j_rightarm"
			}
		},
		left_leg = {
			prio = 4,
			dismember_chance = 1,
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
			dismember_chance = 1,
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
			dismember_chance = 1,
			actors = {
				"c_tail1",
				"c_tail2",
				"c_tail3",
				"c_tail4",
				"c_tail5",
				"c_tail6"
			},
			push_actors = {
				"j_hips",
				"j_taill"
			}
		},
		afro = {
			prio = 5,
			actors = {
				"c_afro"
			}
		}
	},
	hitbox_ragdoll_translation = {
		c_leftupleg = "j_leftupleg",
		c_rightarm = "j_rightarm",
		c_righthand = "j_righthand",
		c_rightfoot = "j_rightfoot",
		c_tail2 = "j_tail2",
		c_rightleg = "j_rightleg",
		c_lefthand = "j_lefthand",
		c_tail5 = "j_tail5",
		c_leftleg = "j_leftleg",
		c_spine2 = "j_spine1",
		c_tail6 = "j_tail6",
		c_rightupleg = "j_rightupleg",
		c_tail1 = "j_taill",
		c_tail4 = "j_tail4",
		c_spine = "j_spine",
		c_head = "j_head",
		c_leftforearm = "j_leftforearm",
		c_righttoebase = "j_righttoebase",
		c_leftfoot = "j_leftfoot",
		c_neck = "j_neck",
		c_tail3 = "j_tail3",
		c_rightforearm = "j_rightforearm",
		c_leftarm = "j_leftarm",
		c_hips = "j_hips",
		c_lefttoebase = "j_lefttoebase"
	},
	ragdoll_actor_thickness = {
		j_rightfoot = 0.2,
		j_taill = 0.05,
		j_leftarm = 0.2,
		j_leftforearm = 0.2,
		j_leftleg = 0.2,
		j_tail3 = 0.05,
		j_rightarm = 0.2,
		j_leftupleg = 0.2,
		j_rightshoulder = 0.3,
		j_righthand = 0.2,
		j_righttoebase = 0.2,
		j_tail4 = 0.05,
		j_hips = 0.3,
		j_leftshoulder = 0.3,
		j_rightleg = 0.2,
		j_leftfoot = 0.2,
		j_spine1 = 0.3,
		j_tail5 = 0.05,
		j_rightupleg = 0.2,
		j_tail6 = 0.05,
		j_lefttoebase = 0.2,
		j_head = 0.3,
		j_neck = 0.3,
		j_spine = 0.3,
		j_lefthand = 0.2,
		j_rightforearm = 0.2,
		j_tail2 = 0.05
	},
	perception_exceptions = {
		poison_well = true,
		wizard_destructible = true
	},
	num_push_anims = {
		push_backward = 2
	},
	wwise_voices = {
		"low",
		"medium",
		"high"
	},
	debug_color = {
		255,
		200,
		0,
		170
	}
}

Breeds.skaven_storm_vermin = table.create_copy(Breeds.skaven_storm_vermin, breed_data)

local action_data = {
	follow = {
		cooldown = -1,
		action_weight = 1,
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
	special_attack_cleave = {
		range = 3,
		height = 3,
		width = 0.4,
		cooldown = 1,
		rotation_time = 1,
		fatigue_type = "blocked_sv_cleave",
		offset_forward = 0,
		damage_type = "cutting",
		move_anim = "move_fwd",
		offset_up = 0,
		attack_anim = "attack_special",
		damage = {
			default = 4
		},
		ignore_staggers = {
			true,
			false,
			false,
			true,
			true,
			false
		}
	},
	special_attack_sweep = {
		range = 2.2,
		height = 0.1,
		width = 2,
		cooldown = 1,
		rotation_time = 1,
		fatigue_type = "blocked_sv_sweep",
		offset_forward = 0.5,
		damage_type = "cutting",
		move_anim = "move_fwd",
		offset_up = 1,
		attack_anim = "attack_pounce",
		damage = {
			default = 4
		},
		ignore_staggers = {
			false,
			false,
			false,
			false,
			false,
			false
		}
	},
	combat_shout = {
		cooldown = -1,
		shout_anim = "shout",
		action_weight = 1
	},
	blocked = {
		blocked_anims = {
			"blocked",
			"blocked_2"
		}
	},
	stagger = {
		stagger_anims = {
			{
				fwd = {
					"stun_fwd_sword"
				},
				bwd = {
					"stun_bwd_sword"
				},
				left = {
					"stun_left_sword"
				},
				right = {
					"stun_right_sword"
				},
				dwn = {
					"stun_bwd_sword"
				}
			},
			{
				fwd = {
					"stagger_fwd"
				},
				bwd = {
					"stagger_bwd"
				},
				left = {
					"stagger_left"
				},
				right = {
					"stagger_right"
				},
				dwn = {
					"stagger_bwd"
				}
			},
			{
				fwd = {
					"stagger_fwd"
				},
				bwd = {
					"stagger_bwd"
				},
				left = {
					"stagger_left_heavy"
				},
				right = {
					"stagger_right_heavy"
				}
			},
			{
				fwd = {
					"stun_fwd_sword"
				},
				bwd = {
					"stun_bwd_sword"
				},
				left = {
					"stun_left_sword"
				},
				right = {
					"stun_right_sword"
				}
			},
			{
				fwd = {
					"stagger_fwd"
				},
				bwd = {
					"stagger_bwd_stab"
				},
				left = {
					"stagger_left"
				},
				right = {
					"stagger_right"
				}
			},
			{
				fwd = {
					"stagger_fwd_exp"
				},
				bwd = {
					"stagger_bwd_exp"
				},
				left = {
					"stagger_left_exp"
				},
				right = {
					"stagger_right_exp"
				}
			},
			{
				fwd = {
					"stagger_fwd"
				},
				bwd = {
					"stagger_bwd"
				},
				left = {
					"stagger_left"
				},
				right = {
					"stagger_right"
				}
			}
		}
	}
}

BreedActions.skaven_storm_vermin = table.create_copy(BreedActions.skaven_storm_vermin, action_data)
BreedActions.skaven_storm_vermin_commander = table.create_copy(BreedActions.skaven_storm_vermin_commander, action_data)
BreedActions.skaven_storm_vermin_commander.give_command = {}
