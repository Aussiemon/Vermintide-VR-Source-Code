-- chunkname: @settings/weapon_setup.lua

require("script/lua/unit_extensions/extension_staff")
require("script/lua/unit_extensions/extension_generic_weapon")
require("script/lua/unit_extensions/bow_extension")

weapons = weapons or {}
weapons = {
	{
		unit_name = "units/weapons/player/wpn_brw_staff_05/wpn_brw_staff_05",
		script = "ExtensionStaff",
		pos_offset = {
			0,
			-0.35,
			0
		},
		rot_offset = {
			-95,
			0,
			0
		}
	},
	{
		unit_name = "units/weapons/player/wpn_fencingsword_02_t1/wpn_fencingsword_02_t1_3p",
		pos_offset = {
			0,
			-0.1,
			0
		},
		rot_offset = {
			-95,
			0,
			0
		}
	},
	{
		unit_name = "units/weapons/player/wpn_empire_basic_mace/wpn_empire_basic_mace_t1_3p",
		pos_offset = {
			0,
			-0.1,
			0
		},
		rot_offset = {
			-95,
			0,
			0
		}
	},
	{
		unit_name = "units/weapons/player/wpn_empire_shield_03/wpn_emp_shield_03_3p",
		pos_offset = {
			0,
			-0.1,
			0
		},
		rot_offset = {
			-45,
			-15,
			-90
		}
	},
	{
		unit_name = "units/weapons/player/wpn_emp_pistol_03_t1/wpn_emp_pistol_03_t1_3p",
		pos_offset = {
			0,
			0,
			0
		},
		rot_offset = {
			-45,
			0,
			0
		}
	},
	{
		unit_name = "units/weapons/player/wpn_we_sword_01_t2/wpn_we_sword_01_t2_3p",
		pos_offset = {
			0,
			-0.1,
			0
		},
		rot_offset = {
			-95,
			0,
			0
		}
	},
	{
		unit_name = "content/models/props/racket/Racket",
		pos_offset = {
			0,
			-0.1,
			0
		},
		rot_offset = {
			-95,
			0,
			0
		}
	},
	{
		unit_name = "content/models/props/ball/Ball_weapon",
		pos_offset = {
			0,
			0,
			0
		},
		rot_offset = {
			0,
			0,
			0
		}
	}
}
