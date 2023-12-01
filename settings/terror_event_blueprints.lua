-- chunkname: @settings/terror_event_blueprints.lua

require("script/lua/utils/loaded_dice")

local function count_breed(breed_name)
	return Managers.state.spawn:count_units_by_breed(breed_name)
end

WeightedRandomTerrorEvents = {}
TerrorEventBlueprints = {
	event_horde_drachenfels = {
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 5
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 5
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 5
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"continue_when",
			condition = function (t)
				return count_breed("skaven_clan_rat") < 1 and count_breed("skaven_storm_vermin") < 1
			end
		},
		{
			"delay",
			duration = 5
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 3
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 4
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 3
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 4
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"continue_when",
			condition = function (t)
				return count_breed("skaven_clan_rat") < 1 and count_breed("skaven_storm_vermin") < 1
			end
		},
		{
			"delay",
			duration = 4
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 4
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 4
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"continue_when",
			condition = function (t)
				return count_breed("skaven_clan_rat") < 1 and count_breed("skaven_storm_vermin") < 1
			end
		},
		{
			"delay",
			duration = 5
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 4
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 4
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"continue_when",
			condition = function (t)
				return count_breed("skaven_clan_rat") < 1 and count_breed("skaven_storm_vermin") < 1
			end
		},
		{
			"delay",
			duration = 5
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 3
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 3
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 3
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 3
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 3
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"continue_when",
			condition = function (t)
				return count_breed("skaven_clan_rat") < 1 and count_breed("skaven_storm_vermin") < 1
			end
		},
		{
			"delay",
			duration = 5
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 3
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 3
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 3
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 3
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"continue_when",
			condition = function (t)
				return count_breed("skaven_clan_rat") < 1 and count_breed("skaven_storm_vermin") < 1
			end
		},
		{
			"delay",
			duration = 5
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 5
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 4
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 4
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 4
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 4
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"continue_when",
			condition = function (t)
				return count_breed("skaven_clan_rat") < 1 and count_breed("skaven_storm_vermin") < 1
			end
		},
		{
			"delay",
			duration = 5
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 4
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 4
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 4
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"continue_when",
			condition = function (t)
				return count_breed("skaven_clan_rat") < 1 and count_breed("skaven_storm_vermin") < 1
			end
		},
		{
			"delay",
			duration = 5
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 4
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 4
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 3
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 1
		},
		{
			"continue_when",
			condition = function (t)
				return count_breed("skaven_clan_rat") < 1 and count_breed("skaven_storm_vermin") < 1
			end
		},
		{
			"delay",
			duration = 5
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 5
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_left_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_right_portal",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_top_portal",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"continue_when",
			condition = function (t)
				return count_breed("skaven_clan_rat") < 1 and count_breed("skaven_storm_vermin") < 1
			end
		}
	},
	event_horde_forest = {
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 4
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 4
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 4
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"continue_when",
			condition = function (t)
				return count_breed("skaven_clan_rat") < 1 and count_breed("skaven_storm_vermin") < 1
			end
		},
		{
			"delay",
			duration = 5
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 3
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 4
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 3
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 4
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"continue_when",
			condition = function (t)
				return count_breed("skaven_clan_rat") < 1 and count_breed("skaven_storm_vermin") < 1
			end
		},
		{
			"delay",
			duration = 5
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 4
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 4
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"continue_when",
			condition = function (t)
				return count_breed("skaven_clan_rat") < 1 and count_breed("skaven_storm_vermin") < 1
			end
		},
		{
			"delay",
			duration = 5
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 4
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 4
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"continue_when",
			condition = function (t)
				return count_breed("skaven_clan_rat") < 1 and count_breed("skaven_storm_vermin") < 1
			end
		},
		{
			"delay",
			duration = 5
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 3
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 3
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 3
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 3
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 3
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"continue_when",
			condition = function (t)
				return count_breed("skaven_clan_rat") < 1 and count_breed("skaven_storm_vermin") < 1
			end
		},
		{
			"delay",
			duration = 5
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 3
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 3
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 3
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 3
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"continue_when",
			condition = function (t)
				return count_breed("skaven_clan_rat") < 1 and count_breed("skaven_storm_vermin") < 1
			end
		},
		{
			"delay",
			duration = 5
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 4
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 4
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 4
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 4
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 4
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"continue_when",
			condition = function (t)
				return count_breed("skaven_clan_rat") < 1 and count_breed("skaven_storm_vermin") < 1
			end
		},
		{
			"delay",
			duration = 5
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 4
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 3
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 4
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"continue_when",
			condition = function (t)
				return count_breed("skaven_clan_rat") < 1 and count_breed("skaven_storm_vermin") < 1
			end
		},
		{
			"delay",
			duration = 5
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 4
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 3
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 3
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 1
		},
		{
			"continue_when",
			condition = function (t)
				return count_breed("skaven_clan_rat") < 1 and count_breed("skaven_storm_vermin") < 1
			end
		},
		{
			"delay",
			duration = 5
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "player_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 5
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_cliff",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_log",
			composition_type = "event_vr_01"
		},
		{
			"event_horde",
			target = "door_1",
			limit_spawners = 2,
			spawner_id = "spawner_forest_hill",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"continue_when",
			condition = function (t)
				return count_breed("skaven_clan_rat") < 1 and count_breed("skaven_storm_vermin") < 1
			end
		}
	},
	event_horde_rail_1 = {
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "enemy_spawn1_game_event_1",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "enemy_spawn2_game_event_1",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "enemy_spawn1_game_event_1",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "enemy_spawn1_game_event_1",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 3
		},
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "enemy_spawn2_game_event_1",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "enemy_spawn2_game_event_1",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 3
		},
		{
			"event_horde",
			limit_spawners = 2,
			spawner_id = "enemy_spawn1_game_event_1",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			limit_spawners = 2,
			spawner_id = "enemy_spawn1_game_event_1",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 3
		},
		{
			"event_horde",
			limit_spawners = 2,
			spawner_id = "enemy_spawn2_game_event_1",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			limit_spawners = 2,
			spawner_id = "enemy_spawn2_game_event_1",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			limit_spawners = 2,
			spawner_id = "enemy_spawn2_game_event_1",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			limit_spawners = 2,
			spawner_id = "enemy_spawn1_game_event_1",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			limit_spawners = 2,
			spawner_id = "enemy_spawn1_game_event_1",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			limit_spawners = 2,
			spawner_id = "enemy_spawn1_game_event_1",
			composition_type = "event_vr_01"
		},
		{
			"continue_when",
			condition = function (t)
				return count_breed("skaven_clan_rat") < 1 and count_breed("skaven_storm_vermin") < 1
			end
		},
		{
			"delay",
			duration = 3
		}
	},
	event_horde_rail_2 = {
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "spawner_enemy_event2_1",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 2
		},
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "spawner_enemy_event2_1",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 8
		},
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "spawner_enemy_event2_2",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 8
		},
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "spawner_enemy_event2_1",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "spawner_enemy_event2_1",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 6
		},
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "spawner_enemy_event2_2",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "spawner_enemy_event2_2",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"continue_when",
			condition = function (t)
				return count_breed("skaven_clan_rat") < 1 and count_breed("skaven_storm_vermin") < 1
			end
		},
		{
			"delay",
			duration = 15
		},
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "spawner_enemy_event2_1",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "spawner_enemy_event2_1",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 8
		},
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "spawner_enemy_event2_2",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "spawner_enemy_event2_2",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 6
		},
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "spawner_enemy_event2_3",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "spawner_enemy_event2_3",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 12
		},
		{
			"continue_when",
			condition = function (t)
				return count_breed("skaven_clan_rat") < 1 and count_breed("skaven_storm_vermin") < 1
			end
		},
		{
			"delay",
			duration = 15
		},
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "spawner_enemy_event2_1",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "spawner_enemy_event2_1",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 8
		},
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "spawner_enemy_event2_2",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "spawner_enemy_event2_2",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 6
		},
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "spawner_enemy_event2_3",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "spawner_enemy_event2_3",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 12
		},
		{
			"continue_when",
			condition = function (t)
				return count_breed("skaven_clan_rat") < 1 and count_breed("skaven_storm_vermin") < 1
			end
		},
		{
			"delay",
			duration = 15
		},
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "spawner_enemy_event2_1",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "spawner_enemy_event2_1",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 7
		},
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "spawner_enemy_event2_2",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "spawner_enemy_event2_2",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 5
		},
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "spawner_enemy_event2_3",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "spawner_enemy_event2_3",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 11
		},
		{
			"continue_when",
			condition = function (t)
				return count_breed("skaven_clan_rat") < 1 and count_breed("skaven_storm_vermin") < 1
			end
		},
		{
			"delay",
			duration = 15
		},
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "spawner_enemy_event2_1",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "spawner_enemy_event2_1",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 6
		},
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "spawner_enemy_event2_2",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "spawner_enemy_event2_2",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 4
		},
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "spawner_enemy_event2_3",
			composition_type = "event_vr_01"
		},
		{
			"delay",
			duration = 1
		},
		{
			"event_horde",
			limit_spawners = 1,
			spawner_id = "spawner_enemy_event2_3",
			composition_type = "event_vr_01_stormvermin"
		},
		{
			"delay",
			duration = 10
		},
		{
			"continue_when",
			condition = function (t)
				return count_breed("skaven_clan_rat") < 1 and count_breed("skaven_storm_vermin") < 1
			end
		},
		{
			"delay",
			duration = 15
		}
	},
	event_horde_rail_rat_ogre = {
		{
			"event_horde",
			limit_spawners = 2,
			spawner_id = "spawner_rat_ogre",
			composition_type = "event_vr_rat_ogre"
		}
	}
}

for chunk_name, chunk in pairs(WeightedRandomTerrorEvents) do
	for i = 1, #chunk, 2 do
		local event_name = chunk[i]

		fassert(TerrorEventBlueprints[event_name], "TerrorEventChunk %s has a bad event: '%s'.", chunk_name, tostring(event_name))
	end

	chunk.loaded_probability_table = LoadedDice.create_from_mixed(chunk)
end
