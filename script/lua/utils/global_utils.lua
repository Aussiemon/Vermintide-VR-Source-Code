-- chunkname: @script/lua/utils/global_utils.lua

script_data.debug_ai_movement = false
script_data.show_spawners = false
script_data.ai_debug_slots = false
script_data.disable_crowd_dispersion = false
script_data.debug_scoring = false
script_data.debug_show_complete_level = false
script_data.auto_kill_start_skaven = false
script_data.debug_health = false
script_data.debug_spawning = false
script_data.debug_parry = false
script_data.nav_mesh_debug = false

local release_build = Application.build() == "release"
local script_data = script_data

script_data.disable_debug_position_lookup = release_build and true or nil

local unit_alive = Unit.alive

local function ignore_ai_target(unit)
	if ScriptUnit.has_extension(unit, "status_system") then
		local status_extension = ScriptUnit.extension(unit, "status_system")

		return status_extension:is_ready_for_assisted_respawn()
	end

	return false
end

RESOLUTION_LOOKUP = RESOLUTION_LOOKUP or {}
POSITION_LOOKUP = POSITION_LOOKUP or {}
REMOVE_FROM_POSITION_LOOKUP = REMOVE_FROM_POSITION_LOOKUP or {}
BLACKBOARDS = BLACKBOARDS or {}

local position_lookup = POSITION_LOOKUP
local remove_from_position_lookup = REMOVE_FROM_POSITION_LOOKUP
local position_lookup_backup = {}
local resolution_lookup = RESOLUTION_LOOKUP

function CLEAR_POSITION_LOOKUP()
	table.clear(position_lookup)
	table.clear(position_lookup_backup)
end

function UPDATE_POSITION_LOOKUP()
	Profiler.start("UPDATE_POSITION_LOOKUP")

	for unit, _ in pairs(remove_from_position_lookup) do
		position_lookup[unit] = nil
		remove_from_position_lookup[unit] = nil
	end

	local world_position = Unit.world_position

	for unit, _ in pairs(position_lookup) do
		position_lookup[unit] = world_position(unit, 1)
	end

	if script_data.debug_enabled and not script_data.disable_debug_position_lookup then
		for unit, _ in pairs(position_lookup) do
			position_lookup_backup[unit] = world_position(unit, 1)
		end
	end

	Profiler.stop()
end

function UPDATE_RESOLUTION_LOOKUP()
	Profiler.start("UPDATE_RESOLUTION_LOOKUP")

	local w, h = Application.resolution()
	local resolution_modified = w ~= resolution_lookup.res_w or h ~= resolution_lookup.res_h

	if resolution_modified then
		resolution_lookup.res_w = w
		resolution_lookup.res_h = h

		AccomodateViewport()

		resolution_lookup.scale = UIResolutionScale()
		resolution_lookup.inv_scale = 1 / resolution_lookup.scale
	end

	resolution_lookup.modified = resolution_modified

	Profiler.stop()
end

local cleared = false

function VALIDATE_POSITION_LOOKUP()
	if not script_data.debug_enabled then
		return
	end

	if script_data.disable_debug_position_lookup then
		if not cleared then
			script_data.position_lookup_backup = {}
			cleared = true
		end

		return
	end

	Profiler.start("VALIDATE_POSITION_LOOKUP")

	cleared = false

	for unit, pos in pairs(position_lookup) do
		local alive, info = unit_alive(unit)

		assert(alive, "Unit was destroyed but not removed from POSITION_LOOKUP ", tostring(info))

		local other_pos = position_lookup_backup[unit]

		if other_pos and Vector3.distance_squared(pos, other_pos) > 0.0001 then
			assert(false, "Modified cached vector3, bad coder!! [%s ==> %s]", tostring(other_pos), tostring(pos))
		end
	end

	table.clear(position_lookup_backup)
	Profiler.stop()
end

PLAYER_UNITS = {}
PLAYER_POSITIONS = {}
PLAYER_AND_BOT_UNITS = {}
PLAYER_AND_BOT_POSITIONS = {}
VALID_PLAYERS_AND_BOTS = {}
AI_TARGET_UNITS = {}

local function is_valid(unit)
	return unit_alive(unit) and not ScriptUnit.extension(unit, "status_system").ready_for_assisted_respawn
end

function UPDATE_PLAYER_LISTS()
	local ai_target_units = AI_TARGET_UNITS
	local j = 1
	local aggro_system = Managers.state.extension:system("aggro_system")
	local aggroable_units = aggro_system.aggroable_units
	local ai_unit_alive = AiUtils.unit_alive

	for unit, _ in pairs(aggroable_units) do
		if ai_unit_alive(unit) and not ignore_ai_target(unit) then
			ai_target_units[j] = unit
			j = j + 1
		end
	end

	while ai_target_units[j] do
		ai_target_units[j] = nil
		j = j + 1
	end
end

function REMOVE_PLAYER_UNIT_FROM_LISTS(player_unit)
	local player_units = PLAYER_UNITS
	local player_positions = PLAYER_POSITIONS
	local size = #player_units

	for i = 1, size do
		if player_unit == player_units[i] then
			player_units[i] = player_units[size]
			player_units[size] = nil
			player_positions[i] = player_positions[size]
			player_positions[size] = nil

			break
		end
	end

	VALID_PLAYERS_AND_BOTS[player_unit] = nil

	local player_and_bot_units = PLAYER_AND_BOT_UNITS
	local player_and_bot_positions = PLAYER_AND_BOT_POSITIONS
	local ai_target_units = AI_TARGET_UNITS
	local ai_target_units_size = #ai_target_units

	size = #player_and_bot_units

	for i = 1, size do
		if player_unit == player_and_bot_units[i] then
			player_and_bot_units[i] = player_and_bot_units[size]
			player_and_bot_units[size] = nil
			player_and_bot_positions[i] = player_and_bot_positions[size]
			player_and_bot_positions[size] = nil
			ai_target_units[i] = ai_target_units[ai_target_units_size]
			ai_target_units[ai_target_units_size] = nil

			break
		end
	end
end

function REMOVE_AGGRO_UNITS(aggro_unit)
	local ai_target_units = AI_TARGET_UNITS
	local size = #ai_target_units

	for i = 1, size do
		if aggro_unit == ai_target_units[i] then
			ai_target_units[i] = ai_target_units[size]
			ai_target_units[size] = nil

			break
		end
	end
end
