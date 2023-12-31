﻿-- chunkname: @settings/breeds/breed_skaven_clan_rat.lua

local breed_data = {
	target_selection = "horde_pick_closest_target_with_spillover",
	using_first_attack = true,
	cannot_far_path = true,
	bone_lod_level = 1,
	has_inventory = true,
	walk_speed = 2.75,
	poison_resistance = 70,
	animation_sync_rpc = "rpc_sync_anim_state_7",
	armor_category = 1,
	reach_distance = 2,
	increase_incoming_damage_fx = "fx/chr_enemy_clanrat_damage_buff",
	detection_radius = 12,
	hit_reaction = "ai_default",
	radius = 2,
	door_reach_distance = 3,
	wield_inventory_on_spawn = true,
	default_inventory_template = "default",
	increase_incoming_damage_fx_node = "c_head",
	ragdoll_on_death = true,
	hit_effect_template = "HitEffectsSkavenClanRat",
	wwise_voice_switch_group = "clan_rat_vce",
	passive_walk_speed = 2,
	horde_behavior = "pack_rat",
	has_running_attack = true,
	unit_template = "ai_unit_clan_rat",
	allow_aoe_push = true,
	perception_previous_attacker_stickyness_value = -7.75,
	smart_object_template = "default_clan_rat",
	stagger_duration_mod = 1,
	death_reaction = "ai_default",
	perception = "perception_regular",
	player_locomotion_constrain_radius = 0.7,
	death_sound_event = "Play_clan_rat_die_vce",
	weapon_reach = 2,
	variation_setting = "skaven_clan_rat_baked",
	horde_target_selection = "horde_pick_closest_target_with_spillover",
	use_backstab_vo = true,
	behavior = "pack_rat",
	base_unit = "units/beings/enemies/skaven_clan_rat/chr_skaven_clan_rat_baked",
	aoe_height = 1.4,
	during_horde_detection_radius = 15,
	opt_base_unit = {
		"units/beings/enemies/skaven_clan_rat/chr_skaven_clan_rat_baked_var1",
		"units/beings/enemies/skaven_clan_rat/chr_skaven_clan_rat_baked_var2",
		"units/beings/enemies/skaven_clan_rat/chr_skaven_clan_rat_baked_var3",
		"units/beings/enemies/skaven_clan_rat/chr_skaven_clan_rat_baked_var4"
	},
	max_health = {
		default = 1
	},
	run_speed = {
		default = 3.5
	},
	size_variation_range = {
		default = {
			0.95,
			1.05
		}
	},
	animation_merge_options = {
		idle_animation_merge_options = {},
		move_animation_merge_options = {},
		walk_animation_merge_options = {},
		interest_point_animation_merge_options = {}
	},
	hit_zones = {
		full = {
			prio = 1,
			actors = {}
		},
		head = {
			prio = 1,
			dismember_chance = 1,
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
				"j_tail1"
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
	num_push_anims = {
		push_backward = 2
	},
	wwise_voices = {
		"indy_low",
		"indy_medium",
		"indy_high",
		"james_low",
		"james_medium",
		"james_high",
		"danijel_high",
		"danijel_medium",
		"danijel_low",
		"magnus_high",
		"magnus_low",
		"magnus_medium"
	},
	debug_color = {
		255,
		200,
		40,
		40
	},
	stagger_duration_difficulty_mod = {
		harder = 0.75,
		hard = 0.9,
		normal = 1,
		hardest = 0.6,
		easy = 1
	}
}

Breeds.skaven_clan_rat = table.create_copy(Breeds.skaven_clan_rat, breed_data)
BreedActionDimishingDamageDifficulty = {
	easy = {
		{
			damage = 2,
			cooldown = {
				2,
				5
			}
		},
		{
			damage = 1.5,
			cooldown = {
				2,
				5
			}
		},
		{
			damage = 1,
			cooldown = {
				2,
				5
			}
		},
		{
			damage = 1,
			cooldown = {
				2,
				5
			}
		},
		{
			damage = 1,
			cooldown = {
				3,
				7
			}
		},
		{
			damage = 1,
			cooldown = {
				3,
				7
			}
		},
		{
			damage = 1,
			cooldown = {
				3,
				7
			}
		},
		{
			damage = 1,
			cooldown = {
				4,
				8
			}
		},
		{
			damage = 1,
			cooldown = {
				4,
				8
			}
		}
	},
	normal = {
		{
			damage = 2,
			cooldown = {
				2,
				3
			}
		},
		{
			damage = 2,
			cooldown = {
				2,
				3
			}
		},
		{
			damage = 1.5,
			cooldown = {
				2,
				3
			}
		},
		{
			damage = 1,
			cooldown = {
				2.25,
				3.25
			}
		},
		{
			damage = 1,
			cooldown = {
				2.5,
				3.5
			}
		},
		{
			damage = 1,
			cooldown = {
				2.75,
				3.75
			}
		},
		{
			damage = 1,
			cooldown = {
				3,
				4
			}
		},
		{
			damage = 1,
			cooldown = {
				3.25,
				4.25
			}
		},
		{
			damage = 1,
			cooldown = {
				3.5,
				4.5
			}
		}
	},
	hard = {
		{
			damage = 2,
			cooldown = {
				1,
				1.5
			}
		},
		{
			damage = 2,
			cooldown = {
				1,
				1.5
			}
		},
		{
			damage = 1.5,
			cooldown = {
				1,
				1.5
			}
		},
		{
			damage = 1,
			cooldown = {
				1.25,
				1.75
			}
		},
		{
			damage = 1,
			cooldown = {
				1.5,
				2
			}
		},
		{
			damage = 1,
			cooldown = {
				1.75,
				2.25
			}
		},
		{
			damage = 1,
			cooldown = {
				2,
				2.5
			}
		},
		{
			damage = 1,
			cooldown = {
				2.25,
				3.25
			}
		},
		{
			damage = 1,
			cooldown = {
				2.5,
				3.5
			}
		}
	},
	survival_hard = {
		{
			damage = 2,
			cooldown = {
				1,
				1.5
			}
		},
		{
			damage = 2,
			cooldown = {
				1,
				1.5
			}
		},
		{
			damage = 1.5,
			cooldown = {
				1,
				1.5
			}
		},
		{
			damage = 1,
			cooldown = {
				1.25,
				1.75
			}
		},
		{
			damage = 1,
			cooldown = {
				1.5,
				2
			}
		},
		{
			damage = 1,
			cooldown = {
				1.75,
				2.25
			}
		},
		{
			damage = 1,
			cooldown = {
				2,
				2.5
			}
		},
		{
			damage = 1,
			cooldown = {
				2.25,
				3.25
			}
		},
		{
			damage = 1,
			cooldown = {
				2.5,
				3.5
			}
		}
	},
	harder = {
		{
			damage = 2.5,
			cooldown = {
				0.5,
				1
			}
		},
		{
			damage = 2,
			cooldown = {
				0.5,
				1
			}
		},
		{
			damage = 1.5,
			cooldown = {
				0.5,
				1
			}
		},
		{
			damage = 1,
			cooldown = {
				0.5,
				1
			}
		},
		{
			damage = 1,
			cooldown = {
				0.6,
				1.1
			}
		},
		{
			damage = 1,
			cooldown = {
				0.7,
				1.2
			}
		},
		{
			damage = 1,
			cooldown = {
				0.8,
				1.3
			}
		},
		{
			damage = 1,
			cooldown = {
				0.9,
				1.4
			}
		},
		{
			damage = 1,
			cooldown = {
				1,
				1.5
			}
		}
	},
	survival_harder = {
		{
			damage = 2.5,
			cooldown = {
				0.5,
				1
			}
		},
		{
			damage = 2,
			cooldown = {
				0.5,
				1
			}
		},
		{
			damage = 1.5,
			cooldown = {
				0.5,
				1
			}
		},
		{
			damage = 1,
			cooldown = {
				0.5,
				1
			}
		},
		{
			damage = 1,
			cooldown = {
				0.6,
				1.1
			}
		},
		{
			damage = 1,
			cooldown = {
				0.7,
				1.2
			}
		},
		{
			damage = 1,
			cooldown = {
				0.8,
				1.3
			}
		},
		{
			damage = 1,
			cooldown = {
				0.9,
				1.4
			}
		},
		{
			damage = 1,
			cooldown = {
				1,
				1.5
			}
		}
	},
	hardest = {
		{
			damage = 2.5,
			cooldown = {
				0,
				0.25
			}
		},
		{
			damage = 2,
			cooldown = {
				0,
				0.25
			}
		},
		{
			damage = 2,
			cooldown = {
				0,
				0.25
			}
		},
		{
			damage = 1.8,
			cooldown = {
				0,
				0.3
			}
		},
		{
			damage = 1.6,
			cooldown = {
				0,
				0.35
			}
		},
		{
			damage = 1.4,
			cooldown = {
				0,
				0.4
			}
		},
		{
			damage = 1.2,
			cooldown = {
				0,
				0.45
			}
		},
		{
			damage = 1,
			cooldown = {
				0,
				0.5
			}
		},
		{
			damage = 1,
			cooldown = {
				0,
				0.5
			}
		}
	},
	survival_hardest = {
		{
			damage = 2.5,
			cooldown = {
				0,
				0.25
			}
		},
		{
			damage = 2,
			cooldown = {
				0,
				0.25
			}
		},
		{
			damage = 2,
			cooldown = {
				0,
				0.25
			}
		},
		{
			damage = 1.8,
			cooldown = {
				0,
				0.3
			}
		},
		{
			damage = 1.6,
			cooldown = {
				0,
				0.35
			}
		},
		{
			damage = 1.4,
			cooldown = {
				0,
				0.4
			}
		},
		{
			damage = 1.2,
			cooldown = {
				0,
				0.45
			}
		},
		{
			damage = 1,
			cooldown = {
				0,
				0.5
			}
		},
		{
			damage = 1,
			cooldown = {
				0,
				0.5
			}
		}
	}
}

local action_data = {
	alerted = {
		cooldown = -1,
		action_weight = 1,
		start_anims_name = {
			bwd = "alerted_bwd",
			fwd = "alerted_fwd",
			left = "alerted_left",
			right = "alerted_right"
		},
		start_anims_data = {
			alerted_fwd = {},
			alerted_bwd = {
				dir = -1,
				rad = math.pi
			},
			alerted_left = {
				dir = 1,
				rad = math.pi / 2
			},
			alerted_right = {
				dir = -1,
				rad = math.pi / 2
			}
		}
	},
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
	normal_attack = {
		player_push_speed = 3,
		fatigue_type = "blocked_attack",
		action_weight = 1,
		damage_type = "cutting",
		move_anim = "move_fwd",
		default_attack = {
			anims = "attack_pounce",
			damage_box_range = {
				flat = 2,
				up = 1.7,
				down = -0.75
			}
		},
		high_attack = {
			z_threshold = 1.5,
			anims = {
				"attack_reach_up",
				"attack_reach_up_2",
				"attack_reach_up_3",
				"attack_reach_up_4"
			},
			damage_box_range = {
				flat = 1.5,
				up = 3.8,
				down = 0
			}
		},
		mid_attack = {
			z_threshold = -0.6,
			flat_threshold = 1.5,
			anims = {
				"attack_pounce_down",
				"attack_pounce_down_2",
				"attack_pounce_down_3"
			},
			damage_box_range = {
				flat = 2,
				up = 1.7,
				down = -2
			}
		},
		low_attack = {
			z_threshold = -0.6,
			anims = {
				"attack_reach_down",
				"attack_reach_down_2",
				"attack_reach_down_3"
			},
			damage_box_range = {
				flat = 1,
				up = 1.7,
				down = -3
			}
		},
		knocked_down_attack = {
			z_threshold = 0.6,
			anims = {
				"attack_pounce_down",
				"attack_pounce_down_2",
				"attack_pounce_down_3"
			},
			damage_box_range = {
				flat = 1,
				up = 1.7,
				down = -3
			}
		},
		damage = {
			default = 3
		},
		dimishing_damage = {}
	},
	combat_shout = {
		cooldown = -1,
		shout_anim = "shout",
		action_weight = 1
	},
	blocked = {
		blocked_anims = {
			"blocked",
			"blocked_2",
			"blocked_3"
		}
	},
	stagger = {
		scale_animation_speeds = true,
		stagger_anims = {
			{
				fwd = {
					"stun_bwd_sword"
				},
				bwd = {
					"stun_fwd_sword"
				},
				left = {
					"stun_left_sword",
					"stun_left_sword_2",
					"stun_left_sword_3"
				},
				right = {
					"stun_right_sword",
					"stun_right_sword_2",
					"stun_right_sword_3"
				},
				dwn = {
					"stun_down"
				}
			},
			{
				fwd = {
					"stagger_fwd"
				},
				bwd = {
					"stagger_bwd",
					"stagger_bwd_2"
				},
				left = {
					"stagger_left",
					"stagger_left_2",
					"stagger_left_3",
					"stagger_left_4"
				},
				right = {
					"stagger_right",
					"stagger_right_2",
					"stagger_right_3",
					"stagger_right_4"
				},
				dwn = {
					"stun_down"
				}
			},
			{
				fwd = {
					"stagger_fwd"
				},
				bwd = {
					"stagger_bwd_fall",
					"stagger_bwd_fall_2"
				},
				left = {
					"stagger_left_heavy",
					"stagger_left_heavy_2",
					"stagger_left_heavy_3"
				},
				right = {
					"stagger_right_heavy",
					"stagger_right_heavy_2",
					"stagger_right_heavy_3"
				},
				dwn = {
					"stun_down"
				}
			},
			{
				fwd = {
					"stun_fwd_ranged_light",
					"stun_fwd_ranged_light_2"
				},
				bwd = {
					"stun_bwd_ranged_light",
					"stun_bwd_ranged_light_2"
				},
				left = {
					"stun_left_ranged_light",
					"stun_left_ranged_light_2"
				},
				right = {
					"stun_right_ranged_light",
					"stun_right_ranged_light_2"
				}
			},
			{
				fwd = {
					"stagger_fwd"
				},
				bwd = {
					"stagger_bwd_stab",
					"stagger_bwd_stab_2"
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
					"stagger_fwd_exp",
					"stagger_fwd_exp_2"
				},
				bwd = {
					"stagger_bwd_exp",
					"stagger_bwd_exp_2"
				},
				left = {
					"stagger_left_exp",
					"stagger_left_exp_2"
				},
				right = {
					"stagger_right_exp",
					"stagger_right_exp_2"
				}
			},
			{
				fwd = {
					"stun_bwd_sword"
				},
				bwd = {
					"stagger_short_bwd",
					"stagger_short_bwd_2",
					"stagger_short_bwd_3",
					"stagger_short_bwd_4",
					"stagger_short_bwd_5"
				},
				left = {
					"stun_left_sword",
					"stun_left_sword_2",
					"stun_left_sword_3",
					"stagger_short_bwd_4",
					"stagger_short_bwd_5"
				},
				right = {
					"stun_right_sword",
					"stun_right_sword_2",
					"stun_right_sword_3",
					"stagger_short_bwd_4",
					"stagger_short_bwd_5"
				},
				dwn = {
					"stun_down"
				}
			}
		}
	}
}

BreedActions.skaven_clan_rat = table.create_copy(BreedActions.skaven_clan_rat, action_data)
