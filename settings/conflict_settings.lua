-- chunkname: @settings/conflict_settings.lua

require("script/lua/utils/loaded_dice")
require("settings/terror_event_blueprints")
require("settings/breeds")

HordeSettings = {
	default = {
		skip_chance = 0,
		chance_of_vector = 0.75,
		spawn_cooldown = 0.7,
		retry_cap = 20,
		disabled = false,
		mix_paced_hordes = true,
		breeds = {
			Breeds.skaven_clan_rat
		},
		compositions = {
			event_vr_03 = {
				{
					name = "plain",
					weight = 7,
					breeds = {
						"skaven_clan_rat",
						{
							3,
							3
						}
					}
				}
			},
			event_vr_02 = {
				{
					name = "plain",
					weight = 7,
					breeds = {
						"skaven_clan_rat",
						{
							2,
							2
						}
					}
				}
			},
			event_vr_01 = {
				{
					name = "plain",
					weight = 7,
					breeds = {
						"skaven_clan_rat",
						{
							1,
							1
						}
					}
				}
			},
			event_vr_rat_ogre = {
				{
					name = "plain",
					weight = 7,
					breeds = {
						"skaven_rat_ogre",
						{
							1,
							1
						}
					}
				}
			},
			event_vr_01_mix = {
				{
					name = "mixed",
					weight = 7,
					breeds = {
						"skaven_clan_rat",
						{
							1,
							1
						},
						"skaven_storm_vermin",
						{
							1,
							1
						}
					}
				}
			},
			event_vr_02_mix = {
				{
					name = "mixed",
					weight = 7,
					breeds = {
						"skaven_clan_rat",
						{
							2,
							2
						},
						"skaven_storm_vermin",
						{
							1,
							1
						}
					}
				}
			},
			event_vr_03_mix = {
				{
					name = "mixed",
					weight = 7,
					breeds = {
						"skaven_clan_rat",
						{
							3,
							3
						},
						"skaven_storm_vermin",
						{
							1,
							1
						}
					}
				}
			},
			event_vr_01_stormvermin = {
				{
					name = "mixed",
					weight = 7,
					breeds = {
						"skaven_storm_vermin",
						{
							1,
							1
						}
					}
				}
			},
			event_vr_02_stormvermin = {
				{
					name = "mixed",
					weight = 7,
					breeds = {
						"skaven_storm_vermin",
						{
							2,
							2
						}
					}
				}
			},
			event_vr_03_stormvermin = {
				{
					name = "mixed",
					weight = 7,
					breeds = {
						"skaven_storm_vermin",
						{
							3,
							3
						}
					}
				}
			},
			event_smaller = {
				{
					name = "plain",
					weight = 7,
					breeds = {
						"skaven_clan_rat",
						{
							8,
							10
						}
					}
				},
				{
					name = "mixed",
					weight = 3,
					breeds = {
						"skaven_clan_rat",
						{
							5,
							6
						},
						"skaven_clan_rat",
						{
							1,
							2
						}
					}
				}
			},
			event_small = {
				{
					name = "plain",
					weight = 7,
					breeds = {
						"skaven_slave",
						{
							13,
							15
						}
					}
				},
				{
					name = "mixed",
					weight = 3,
					breeds = {
						"skaven_slave",
						{
							10,
							12
						},
						"skaven_clan_rat",
						{
							2,
							4
						}
					}
				}
			},
			event_medium = {
				{
					name = "plain",
					weight = 7,
					breeds = {
						"skaven_slave",
						{
							22,
							23
						}
					}
				},
				{
					name = "mixed",
					weight = 3,
					breeds = {
						"skaven_slave",
						{
							12,
							14
						},
						"skaven_clan_rat",
						{
							5,
							6
						}
					}
				}
			},
			event_large = {
				{
					name = "plain",
					weight = 7,
					breeds = {
						"skaven_slave",
						{
							32,
							35
						}
					}
				},
				{
					name = "mixed",
					weight = 3,
					breeds = {
						"skaven_slave",
						{
							27,
							29
						},
						"skaven_clan_rat",
						{
							6,
							7
						}
					}
				}
			},
			performance_test = {
				{
					name = "mixed",
					weight = 3,
					breeds = {
						"skaven_slave",
						{
							15,
							15
						},
						"skaven_clan_rat",
						{
							15,
							15
						}
					}
				}
			},
			pathfind_test_light = {
				{
					name = "plain",
					weight = 7,
					breeds = {
						"skaven_slave",
						{
							50,
							50
						}
					}
				}
			},
			small = {
				{
					name = "plain",
					weight = 7,
					breeds = {
						"skaven_slave",
						{
							20,
							22
						}
					}
				},
				{
					name = "mixed",
					weight = 3,
					breeds = {
						"skaven_slave",
						{
							14,
							18
						}
					}
				}
			},
			medium = {
				{
					name = "plain",
					weight = 7,
					breeds = {
						"skaven_slave",
						{
							35,
							40
						}
					}
				}
			},
			large = {
				{
					name = "plain",
					weight = 7,
					breeds = {
						"skaven_slave",
						{
							40,
							45
						}
					}
				}
			},
			mini_patrol = {
				{
					name = "few_clanrats",
					weight = 10,
					breeds = {
						"skaven_clan_rat",
						{
							3,
							5
						}
					}
				}
			},
			event_courtyard_extra_spice = {
				{
					name = "plain",
					weight = 25,
					breeds = {
						"skaven_slave",
						{
							0,
							5
						},
						"skaven_clan_rat",
						{
							6,
							9
						}
					}
				},
				{
					name = "somevermin",
					weight = 2,
					breeds = {
						"skaven_clan_rat",
						{
							5,
							7
						},
						"skaven_storm_vermin_commander",
						{
							1,
							2
						}
					}
				}
			},
			event_courtyard_extra_big_spice = {
				{
					name = "plain",
					weight = 10,
					breeds = {
						"skaven_clan_rat",
						{
							11,
							13
						}
					}
				},
				{
					name = "lotsofvermin",
					weight = 3,
					breeds = {
						"skaven_storm_vermin_commander",
						{
							3,
							4
						}
					}
				}
			},
			event_farm_extra_spice = {
				{
					name = "plain",
					weight = 6,
					breeds = {
						"skaven_clan_rat",
						{
							8,
							11
						}
					}
				},
				{
					name = "avermin",
					weight = 3,
					breeds = {
						"skaven_clan_rat",
						{
							8,
							11
						},
						"skaven_storm_vermin_commander",
						1
					}
				},
				{
					name = "somevermin",
					weight = 1,
					breeds = {
						"skaven_clan_rat",
						{
							4,
							6
						},
						"skaven_storm_vermin_commander",
						2
					}
				}
			},
			event_farm_extra_big_spice = {
				{
					name = "plain",
					weight = 5,
					breeds = {
						"skaven_clan_rat",
						{
							13,
							16
						},
						"skaven_storm_vermin_commander",
						1
					}
				},
				{
					name = "lotsofvermin",
					weight = 5,
					breeds = {
						"skaven_slave",
						{
							7,
							10
						},
						"skaven_storm_vermin_commander",
						3
					}
				}
			},
			event_merchant_ambush = {
				{
					name = "plain",
					weight = 10,
					breeds = {
						"skaven_clan_rat",
						{
							11,
							14
						}
					}
				},
				{
					name = "somevermin",
					weight = 2,
					breeds = {
						"skaven_clan_rat",
						{
							6,
							8
						},
						"skaven_storm_vermin_commander",
						{
							1,
							2
						}
					}
				}
			},
			wizard_event_smaller_hard = {
				{
					name = "plain",
					weight = 25,
					breeds = {
						"skaven_clan_rat",
						{
							12,
							14
						}
					}
				},
				{
					name = "somevermin",
					weight = 2,
					breeds = {
						"skaven_clan_rat",
						{
							7,
							8
						},
						"skaven_storm_vermin_commander",
						{
							1,
							2
						}
					}
				}
			},
			wizard_event_small_hard = {
				{
					name = "plain",
					weight = 10,
					breeds = {
						"skaven_clan_rat",
						{
							18,
							19
						}
					}
				},
				{
					name = "somevermin",
					weight = 3,
					breeds = {
						"skaven_storm_vermin_commander",
						{
							2,
							3
						}
					}
				}
			},
			sewers_event_smaller_hard = {
				{
					name = "plain",
					weight = 5,
					breeds = {
						"skaven_clan_rat",
						{
							6,
							9
						}
					}
				},
				{
					name = "somevermin",
					weight = 5,
					breeds = {
						"skaven_clan_rat",
						{
							4,
							5
						},
						"skaven_storm_vermin_commander",
						1
					}
				}
			},
			sewers_event_small_hard = {
				{
					name = "plain",
					weight = 5,
					breeds = {
						"skaven_slave",
						{
							2,
							4
						},
						"skaven_clan_rat",
						{
							12,
							14
						}
					}
				},
				{
					name = "somevermin",
					weight = 5,
					breeds = {
						"skaven_clan_rat",
						{
							4,
							5
						},
						"skaven_storm_vermin_commander",
						2
					}
				}
			},
			end_boss_event_smaller_hard = {
				{
					name = "plain",
					weight = 6,
					breeds = {
						"skaven_slave",
						{
							4,
							6
						},
						"skaven_clan_rat",
						{
							6,
							9
						}
					}
				},
				{
					name = "somevermin",
					weight = 2,
					breeds = {
						"skaven_clan_rat",
						{
							6,
							8
						},
						"skaven_storm_vermin_commander",
						1
					}
				},
				{
					name = "somevermin",
					weight = 2,
					breeds = {
						"skaven_clan_rat",
						{
							8,
							11
						}
					}
				}
			},
			end_boss_event_small_hard = {
				{
					name = "plain",
					weight = 6,
					breeds = {
						"skaven_clan_rat",
						{
							11,
							13
						}
					}
				},
				{
					name = "somevermin",
					weight = 2,
					breeds = {
						"skaven_storm_vermin_commander",
						3
					}
				},
				{
					name = "clanvermin",
					weight = 2,
					breeds = {
						"skaven_clan_rat",
						{
							3,
							5
						},
						"skaven_storm_vermin_commander",
						2
					}
				}
			},
			end_boss_event_stormvermin = {
				{
					name = "somevermin",
					weight = 3,
					breeds = {
						"skaven_storm_vermin_commander",
						6
					}
				}
			},
			end_boss_event_stormvermin_small = {
				{
					name = "somevermin",
					weight = 3,
					breeds = {
						"skaven_storm_vermin_commander",
						4
					}
				}
			},
			end_boss_event_rolling = {
				{
					name = "plain",
					weight = 3,
					breeds = {
						"skaven_clan_rat",
						{
							8,
							13
						}
					}
				},
				{
					name = "plain_slave",
					weight = 3,
					breeds = {
						"skaven_slave",
						{
							4,
							9
						},
						"skaven_clan_rat",
						{
							5,
							9
						}
					}
				},
				{
					name = "somevermin",
					weight = 2,
					breeds = {
						"skaven_storm_vermin_commander",
						{
							2,
							3
						}
					}
				},
				{
					name = "somevermin_slave",
					weight = 2,
					breeds = {
						"skaven_slave",
						{
							4,
							9
						},
						"skaven_storm_vermin_commander",
						2
					}
				}
			},
			event_docks_warehouse_extra_spice = {
				{
					name = "few_clanrats",
					weight = 10,
					breeds = {
						"skaven_clan_rat",
						{
							5,
							7
						}
					}
				},
				{
					name = "storm_clanrats",
					weight = 3,
					breeds = {
						"skaven_clan_rat",
						{
							3,
							5
						},
						"skaven_storm_vermin_commander",
						{
							1,
							2
						}
					}
				}
			},
			event_generic_short_level_extra_spice = {
				{
					name = "few_clanrats",
					weight = 10,
					breeds = {
						"skaven_clan_rat",
						{
							5,
							7
						}
					}
				},
				{
					name = "storm_clanrats",
					weight = 3,
					breeds = {
						"skaven_clan_rat",
						{
							3,
							5
						},
						"skaven_storm_vermin_commander",
						{
							1,
							2
						}
					}
				}
			},
			event_generic_short_level_stormvermin = {
				{
					name = "somevermin",
					weight = 3,
					breeds = {
						"skaven_storm_vermin_commander",
						{
							3,
							4
						}
					}
				}
			},
			city_wall_extra_spice = {
				{
					name = "few_clanrats",
					weight = 10,
					breeds = {
						"skaven_clan_rat",
						{
							5,
							7
						}
					}
				},
				{
					name = "storm_clanrats",
					weight = 1,
					breeds = {
						"skaven_clan_rat",
						{
							4,
							5
						},
						"skaven_storm_vermin_commander",
						1
					}
				}
			},
			event_generic_long_level_extra_spice = {
				{
					name = "few_clanrats",
					weight = 25,
					breeds = {
						"skaven_clan_rat",
						{
							4,
							5
						}
					}
				},
				{
					name = "storm_clanrats",
					weight = 2,
					breeds = {
						"skaven_clan_rat",
						{
							2,
							3
						},
						"skaven_storm_vermin_commander",
						1
					}
				}
			},
			event_generic_long_level_stormvermin = {
				{
					name = "somevermin",
					weight = 3,
					breeds = {
						"skaven_storm_vermin_commander",
						{
							2,
							3
						}
					}
				}
			},
			event_magnus_horn_smaller = {
				{
					name = "plain",
					weight = 10,
					breeds = {
						"skaven_clan_rat",
						{
							6,
							9
						}
					}
				},
				{
					name = "somevermin",
					weight = 3,
					breeds = {
						"skaven_clan_rat",
						{
							4,
							5
						},
						"skaven_storm_vermin_commander",
						{
							1,
							2
						}
					}
				}
			},
			event_magnus_horn_small = {
				{
					name = "plain",
					weight = 10,
					breeds = {
						"skaven_clan_rat",
						{
							17,
							19
						}
					}
				},
				{
					name = "lotsofvermin",
					weight = 3,
					breeds = {
						"skaven_clan_rat",
						{
							4,
							5
						},
						"skaven_storm_vermin_commander",
						{
							2,
							3
						}
					}
				}
			},
			event_survival_medium_intensity = {
				{
					name = "clanrats",
					weight = 2,
					breeds = {
						"skaven_clan_rat",
						{
							15,
							21
						}
					}
				}
			},
			event_survival_high_intensity = {
				{
					name = "many_clanrats",
					weight = 2,
					breeds = {
						"skaven_clan_rat",
						{
							25,
							31
						}
					}
				}
			},
			event_survival_storm_horde = {
				{
					name = "many_stormvermin",
					weight = 2,
					breeds = {
						"skaven_clan_rat",
						{
							6,
							8
						},
						"skaven_storm_vermin_commander",
						{
							14,
							17
						}
					}
				}
			},
			event_survival_storm_band = {
				{
					name = "some_stormvermin",
					weight = 2,
					breeds = {
						"skaven_clan_rat",
						{
							6,
							8
						},
						"skaven_storm_vermin_commander",
						{
							2,
							3
						}
					}
				}
			},
			event_survival_slaves_small = {
				{
					name = "slaves_a",
					weight = 1,
					breeds = {
						"skaven_slave",
						{
							25,
							25
						}
					}
				}
			},
			event_survival_slaves_large = {
				{
					name = "slaves_a",
					weight = 1,
					breeds = {
						"skaven_slave",
						{
							40,
							40
						}
					}
				}
			},
			event_survival_main = {
				{
					name = "main_a",
					weight = 1,
					breeds = {
						"skaven_clan_rat",
						{
							28,
							30
						}
					}
				}
			},
			event_survival_flank = {
				{
					name = "flank_a",
					weight = 1,
					breeds = {
						"skaven_clan_rat",
						{
							17,
							30
						}
					}
				},
				{
					name = "flank_b",
					weight = 1,
					breeds = {
						"skaven_clan_rat",
						{
							9,
							11
						},
						"skaven_slave",
						{
							25,
							30
						}
					}
				}
			},
			event_survival_pinch = {
				{
					name = "pinch_a",
					weight = 1,
					breeds = {
						"skaven_clan_rat",
						{
							20,
							23
						}
					}
				},
				{
					name = "pinch_b",
					weight = 1,
					breeds = {
						"skaven_clan_rat",
						{
							12,
							12
						},
						"skaven_slave",
						{
							20,
							22
						}
					}
				}
			},
			event_survival_flush = {
				{
					name = "main_a",
					weight = 1,
					breeds = {
						"skaven_clan_rat",
						{
							25,
							28
						}
					}
				},
				{
					name = "main_b",
					weight = 1,
					breeds = {
						"skaven_clan_rat",
						{
							7,
							13
						},
						"skaven_slave",
						{
							28,
							28
						}
					}
				}
			},
			event_survival_pack = {
				{
					name = "pack_a",
					weight = 1,
					breeds = {
						"skaven_clan_rat",
						13,
						"skaven_storm_vermin_commander",
						2
					}
				}
			},
			event_survival_stormvermin = {
				{
					name = "main_a",
					weight = 1,
					breeds = {
						"skaven_storm_vermin_commander",
						5
					}
				}
			},
			event_survival_stormvermin_few = {
				{
					name = "main_a",
					weight = 1,
					breeds = {
						"skaven_storm_vermin_commander",
						3
					}
				}
			},
			event_survival_extra = {
				{
					name = "extra_a",
					weight = 1,
					breeds = {
						"skaven_clan_rat",
						{
							14,
							15
						},
						"skaven_storm_vermin_commander",
						{
							2,
							3
						}
					}
				}
			},
			event_tutorial_slave = {
				{
					name = "plain",
					weight = 1,
					breeds = {
						"skaven_slave",
						{
							1,
							1
						}
					}
				}
			},
			event_tutorial_clanrat = {
				{
					name = "plain",
					weight = 1,
					breeds = {
						"skaven_clan_rat",
						{
							1,
							1
						}
					}
				}
			},
			event_tutorial_stormvermin = {
				{
					name = "plain",
					weight = 1,
					breeds = {
						"skaven_storm_vermin_commander",
						{
							1,
							1
						}
					}
				}
			},
			benchmark_clanrat = {
				{
					name = "plain",
					weight = 25,
					breeds = {
						"skaven_clan_rat",
						{
							5,
							5
						}
					}
				}
			},
			benchmark_stormvermin = {
				{
					name = "lotsofvermin",
					weight = 3,
					breeds = {
						"skaven_storm_vermin_commander",
						{
							2,
							2
						}
					}
				}
			},
			ai_benchmark_cycle_slaves = {
				{
					name = "slaves",
					weight = 3,
					breeds = {
						"skaven_slave",
						{
							20,
							20
						}
					}
				}
			},
			ai_benchmark_cycle_clanrat = {
				{
					name = "clanrats",
					weight = 3,
					breeds = {
						"skaven_clan_rat",
						{
							10,
							10
						}
					}
				}
			},
			ai_benchmark_cycle_stormvermin = {
				{
					name = "stormvermins",
					weight = 3,
					breeds = {
						"skaven_storm_vermin_commander",
						{
							4,
							4
						}
					}
				}
			},
			event_portals_slaves_small = {
				{
					name = "slaves_small",
					weight = 1,
					breeds = {
						"skaven_slave",
						{
							15,
							20
						}
					}
				}
			},
			event_portals_slaves_large = {
				{
					name = "slaves_large",
					weight = 1,
					breeds = {
						"skaven_slave",
						{
							28,
							32
						}
					}
				}
			},
			event_portals_clanrats = {
				{
					name = "clanrats",
					weight = 1,
					breeds = {
						"skaven_clan_rat",
						{
							17,
							18
						}
					}
				}
			},
			event_portals_flank = {
				{
					name = "flank_a",
					weight = 1,
					breeds = {
						"skaven_clan_rat",
						{
							10,
							12
						}
					}
				},
				{
					name = "flank_b",
					weight = 1,
					breeds = {
						"skaven_clan_rat",
						{
							2,
							3
						},
						"skaven_slave",
						{
							10,
							15
						}
					}
				}
			},
			event_portals_flush = {
				{
					name = "flush",
					weight = 1,
					breeds = {
						"skaven_clan_rat",
						{
							7,
							8
						},
						"skaven_slave",
						{
							20,
							30
						}
					}
				}
			},
			event_portals_pack = {
				{
					name = "pack",
					weight = 1,
					breeds = {
						"skaven_clan_rat",
						8,
						"skaven_storm_vermin_commander",
						2
					}
				}
			},
			event_portals_stormvermin = {
				{
					name = "stormvermin",
					weight = 1,
					breeds = {
						"skaven_storm_vermin_commander",
						{
							3,
							4
						}
					}
				}
			}
		},
		ambush = {
			max_size,
			max_horde_spawner_dist = 35,
			max_spawners = 15,
			min_hidden_spawner_dist = 10,
			composition_type = "medium",
			start_delay = 3.45,
			max_hidden_spawner_dist = 20,
			min_horde_spawner_dist = 1
		},
		vector = {
			max_size,
			max_horde_spawner_dist = 15,
			start_delay = 8,
			max_hidden_spawner_dist = 20,
			min_hidden_spawner_dist = 0,
			main_path_dist_from_players = 30,
			composition_type = "large",
			max_spawners = 4,
			main_path_chance_spawning_ahead = 0.67,
			min_horde_spawner_dist = 0
		},
		amount = {
			27,
			30
		},
		range_spawner_units = {
			2,
			6
		},
		range_hidden_spawn = {
			5,
			30
		},
		num_spawnpoints = {
			4,
			8
		}
	}
}
HordeSettings.disabled = table.clone(HordeSettings.default)
HordeSettings.disabled.disabled = true

local weights = {}

for key, setting in pairs(HordeSettings) do
	if setting.compositions then
		for size, composition in pairs(setting.compositions) do
			table.clear_array(weights, #weights)

			for i, variant in ipairs(composition) do
				weights[i] = variant.weight
			end

			composition.loaded_probs = {
				LoadedDice.create(weights)
			}
		end
	end
end

CurrentHordeSettings = HordeSettings.default

local crash = false
local compositions = HordeSettings.default.compositions

for name, elements in pairs(TerrorEventBlueprints) do
	for i = 1, #elements do
		local element = elements[i]
		local element_type = element[1]

		if element_type == "event_horde" and not compositions[element.composition_type] then
			print(string.format("Bad or misspelled composition_type '%s' in event '%s', element number %d", tostring(element.composition_type), name, i))

			crash = true
		end
	end
end

if crash then
	-- Nothing
end
