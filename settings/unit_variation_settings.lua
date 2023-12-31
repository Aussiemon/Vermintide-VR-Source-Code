﻿-- chunkname: @settings/unit_variation_settings.lua

UnitVariationSettings = {}
UnitVariationSettings.skaven_clan_rat = {
	enabled_from_start = {
		"lower_body",
		"upper_body",
		"head",
		"left_arm",
		"right_arm",
		"legs"
	},
	body_parts = {
		lower_body = {
			{
				weight = 1,
				group = "hipcloth"
			}
		},
		upper_body = {
			{
				group = "body_hood",
				weight = 1,
				enables = {
					"body_scarf"
				}
			},
			{
				group = "body_tunic",
				weight = 1,
				enables = {
					"body_scarf"
				}
			},
			{
				group = "body_tunic_hood",
				weight = 1,
				enables = {
					"body_scarf"
				}
			},
			{
				weight = 1,
				group = "body_nothing"
			}
		},
		head = {
			{
				group = "head_helmet_fur",
				weight = 1,
				enables = {
					"head_helmet"
				}
			},
			{
				group = "head_hood",
				weight = 1,
				enables = {
					"head_helmet"
				}
			},
			{
				weight = 1,
				group = "head_mask"
			},
			{
				weight = 1,
				group = "head_nothing"
			}
		},
		left_arm = {
			{
				weight = 1,
				group = "left_arm_leather"
			},
			{
				weight = 1,
				group = "left_arm_metal"
			},
			{
				weight = 1,
				group = "left_arm_nothing"
			},
			{
				weight = 1,
				group = "left_arm_straps"
			}
		},
		right_arm = {
			{
				weight = 1,
				group = "right_arm_leather"
			},
			{
				weight = 1,
				group = "right_arm_metal"
			},
			{
				weight = 1,
				group = "right_arm_nothing"
			},
			{
				weight = 1,
				group = "right_arm_straps"
			}
		},
		legs = {
			{
				weight = 1,
				group = "leg_straps"
			},
			{
				weight = 1
			}
		},
		body_scarf = {
			{
				weight = 1,
				group = "head_helmet_fur"
			},
			{
				weight = 1
			}
		},
		head_helmet = {
			{
				group = "head_helmet_soft",
				weight = 1,
				enables = {
					"head_helmet_sharp_extras"
				}
			},
			{
				group = "head_helmet_sharp",
				weight = 1,
				enables = {
					"head_helmet_soft_extras"
				}
			}
		},
		head_helmet_sharp_extras = {
			{
				weight = 1,
				group = "head_helmet_sharp_nails_1"
			},
			{
				weight = 1,
				group = "head_helmet_sharp_nails_2"
			},
			{
				weight = 1,
				group = "head_helmet_sharp_nails_3"
			},
			{
				weight = 1
			}
		},
		head_helmet_soft_extras = {
			{
				weight = 1,
				group = "head_helmet_soft_nails_1"
			},
			{
				weight = 1,
				group = "head_helmet_soft_nails_2"
			},
			{
				weight = 1,
				group = "head_helmet_soft_nails_3"
			},
			{
				weight = 1
			}
		}
	},
	material_variations = {
		skin_tint = {
			variable = "gradient_variation",
			min = 0,
			max = 28,
			materials = {
				"mtr_skin",
				"mtr_fur"
			}
		},
		hip_cloth = {
			min = 0,
			variable = "gradient_variation",
			max = 31,
			materials = {
				"mtr_outfit"
			},
			meshes = {
				"g_hipcloth_lod0",
				"g_hipcloth_lod1",
				"g_hipcloth_lod2"
			}
		},
		leg_straps = {
			min = 0,
			variable = "gradient_variation",
			max = 31,
			materials = {
				"mtr_outfit"
			},
			meshes = {
				"g_legs_straps_lod0",
				"g_legs_straps_lod1",
				"g_legs_straps_lod2"
			}
		},
		body_hood = {
			min = 0,
			variable = "gradient_variation",
			max = 31,
			materials = {
				"mtr_outfit"
			},
			meshes = {
				"g_body_hood_lod0",
				"g_body_hood_lod1",
				"g_body_hood_lod2"
			}
		},
		body_tunic_hood = {
			min = 0,
			variable = "gradient_variation",
			max = 31,
			materials = {
				"mtr_outfit"
			},
			meshes = {
				"g_body_tunic_hood_lod0",
				"g_body_tunic_hood_lod1",
				"g_body_tunic_hood_lod2"
			}
		},
		body_tunic = {
			min = 0,
			variable = "gradient_variation",
			max = 31,
			materials = {
				"mtr_outfit"
			},
			meshes = {
				"g_body_tunic_lod0",
				"g_body_tunic_lod1",
				"g_body_tunic_lod2"
			}
		},
		scarf = {
			min = 0,
			variable = "gradient_variation",
			max = 31,
			materials = {
				"mtr_outfit"
			},
			meshes = {
				"g_scarf_lod0",
				"g_scarf_lod1",
				"g_scarf_lod2"
			}
		},
		head_mask = {
			min = 0,
			variable = "gradient_variation",
			max = 31,
			materials = {
				"mtr_outfit"
			},
			meshes = {
				"g_head_mask_lod0",
				"g_head_mask_lod1",
				"g_head_mask_lod2"
			}
		},
		head_straps = {
			min = 0,
			variable = "gradient_variation",
			max = 31,
			materials = {
				"mtr_outfit"
			},
			meshes = {
				"g_head_straps_lod0",
				"g_head_straps_lod1",
				"g_head_straps_lod2"
			}
		},
		head_hood = {
			min = 0,
			variable = "gradient_variation",
			max = 31,
			materials = {
				"mtr_outfit"
			},
			meshes = {
				"g_head_hood_lod0",
				"g_head_hood_lod1",
				"g_head_hood_lod2"
			}
		},
		left_arm_straps = {
			min = 0,
			variable = "gradient_variation",
			max = 31,
			materials = {
				"mtr_outfit"
			},
			meshes = {
				"g_arm_left_straps_lod0",
				"g_arm_left_straps_lod1",
				"g_arm_left_straps_lod2"
			}
		},
		right_arm_straps = {
			min = 0,
			variable = "gradient_variation",
			max = 31,
			materials = {
				"mtr_outfit"
			},
			meshes = {
				"g_arm_right_straps_lod0",
				"g_arm_right_straps_lod1",
				"g_arm_right_straps_lod2"
			}
		}
	}
}
UnitVariationSettings.skaven_clan_rat_baked = {
	enabled_from_start = {
		"upper_body"
	},
	body_parts = {
		upper_body = {
			{
				weight = 1,
				group = "body_hood"
			},
			{
				weight = 1,
				group = "body_tunic"
			},
			{
				weight = 1,
				group = "body_tunic_hood"
			},
			{
				weight = 1,
				group = "body_nothing"
			}
		}
	},
	material_variations = {
		skin_tint = {
			variable = "gradient_variation",
			min = 0,
			max = 28,
			materials = {
				"mtr_skin",
				"mtr_fur"
			}
		},
		cloth_tint = {
			variable = "gradient_variation",
			min = 0,
			max = 31,
			materials = {
				"mtr_outfit"
			}
		}
	}
}
UnitVariationSettings.skaven_slave = {
	enabled_from_start = {
		"lower_body",
		"head",
		"left_arm",
		"right_arm",
		"legs"
	},
	body_parts = {
		lower_body = {
			{
				weight = 1,
				group = "hipcloth"
			}
		},
		head = {
			{
				weight = 1,
				group = "head_straps"
			}
		},
		left_arm = {
			{
				weight = 1,
				group = "left_arm_straps"
			},
			{
				weight = 1
			}
		},
		right_arm = {
			{
				weight = 1,
				group = "right_arm_straps"
			},
			{
				weight = 1
			}
		},
		legs = {
			{
				weight = 1,
				group = "leg_straps"
			},
			{
				weight = 1
			}
		}
	},
	material_variations = {
		skin_tint = {
			variable = "gradient_variation",
			min = 0,
			max = 28,
			materials = {
				"mtr_skin",
				"mtr_fur"
			}
		},
		hip_cloth = {
			min = 0,
			variable = "gradient_variation",
			max = 31,
			materials = {
				"mtr_outfit"
			},
			meshes = {
				"g_hipcloth_lod0",
				"g_hipcloth_lod1",
				"g_hipcloth_lod2"
			}
		},
		leg_straps = {
			min = 0,
			variable = "gradient_variation",
			max = 31,
			materials = {
				"mtr_outfit"
			},
			meshes = {
				"g_legs_straps_lod0",
				"g_legs_straps_lod1",
				"g_legs_straps_lod2"
			}
		},
		head_straps = {
			min = 0,
			variable = "gradient_variation",
			max = 31,
			materials = {
				"mtr_outfit"
			},
			meshes = {
				"g_head_straps_lod0",
				"g_head_straps_lod1",
				"g_head_straps_lod2"
			}
		},
		left_arm_straps = {
			min = 0,
			variable = "gradient_variation",
			max = 31,
			materials = {
				"mtr_outfit"
			},
			meshes = {
				"g_arm_left_straps_lod0",
				"g_arm_left_straps_lod1",
				"g_arm_left_straps_lod2"
			}
		},
		right_arm_straps = {
			min = 0,
			variable = "gradient_variation",
			max = 31,
			materials = {
				"mtr_outfit"
			},
			meshes = {
				"g_arm_right_straps_lod0",
				"g_arm_right_straps_lod1",
				"g_arm_right_straps_lod2"
			}
		}
	}
}
UnitVariationSettings.skaven_slave_baked = {
	enabled_from_start = {
		"aux"
	},
	body_parts = {
		aux = {
			{
				weight = 1,
				group = "empty"
			}
		}
	},
	material_variations = {
		skin_tint = {
			variable = "gradient_variation",
			min = 0,
			max = 28,
			materials = {
				"mtr_skin",
				"mtr_fur"
			}
		},
		cloth_tint = {
			variable = "gradient_variation",
			min = 0,
			max = 31,
			materials = {
				"mtr_outfit"
			}
		}
	}
}
UnitVariationSettings.skaven_storm_vermin = {
	enabled_from_start = {
		"full"
	},
	body_parts = {
		full = {
			{
				weight = 1,
				group = "armor"
			}
		}
	},
	material_variations = {
		skin_tint = {
			variable = "gradient_variation",
			min = 0,
			max = 0,
			materials = {
				"mtr_skin",
				"mtr_fur"
			}
		},
		armor = {
			min = 0,
			variable = "gradient_variation",
			max = 31,
			materials = {
				"mtr_outfit"
			},
			meshes = {
				"g_stormvermin_armor_lod0",
				"g_stormvermin_armor_lod1",
				"g_stormvermin_armor_lod2"
			}
		}
	}
}
