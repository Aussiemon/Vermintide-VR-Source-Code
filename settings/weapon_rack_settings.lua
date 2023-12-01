-- chunkname: @settings/weapon_rack_settings.lua

WeaponRackSettings = {
	default = {
		bow = {
			node_name = "weapon_001",
			unit_name = "units/weapons/player/wpn_we_bow_03_t1/wpn_bow",
			position_offset = {
				0,
				0,
				0.4
			},
			rotation_offset = {
				180,
				0,
				-90
			},
			settings = BowSettings
		},
		pistol = {
			node_name = "weapon_005",
			unit_name = "units/weapons/player/wpn_empire_pistol_repeater/wpn_empire_pistol_repeater_t1",
			position_offset = {
				0.1,
				0,
				0
			},
			rotation_offset = {
				0,
				90,
				-90
			},
			settings = HandgunSettings
		},
		staff = {
			node_name = "weapon_003",
			unit_name = "units/weapons/player/wpn_hag_staff_01/wpn_hag_staff_01",
			position_offset = {
				0,
				0,
				0.3
			},
			rotation_offset = {
				0,
				0,
				180
			},
			settings = StaffSettings
		},
		rapier = {
			node_name = "weapon_004",
			unit_name = "units/weapons/player/wpn_fencingsword_03_t1/wpn_fencingsword_03_t1_3p",
			position_offset = {
				0,
				0,
				0.5
			},
			rotation_offset = {
				180,
				0,
				180
			},
			settings = RapierSettings
		}
	}
}
WeaponRackConfig = {
	respawn_units = false,
	respawn_time = 3
}
