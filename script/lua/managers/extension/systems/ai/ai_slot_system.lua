﻿-- chunkname: @script/lua/managers/extension/systems/ai/ai_slot_system.lua

require("script/lua/utils/global_utils")
require("script/lua/utils/ai_utils")

SlotSettings = {
	count = 9,
	level_unit_distance = 1.75,
	distance = 1.15,
	dialogue_surrounded_count = 4
}

local SLOTS_COUNT = SlotSettings.count

function SLOT_DISTANCE(extension)
	local distance = extension.is_level_unit and SlotSettings.level_unit_distance or SlotSettings.distance

	return distance
end

class("AISlotSystem", "ExtensionSystemBase")

AISlotSystem.extension_list = {
	"AIEnemySlotExtension",
	"AIAggroableSlotExtension",
	"AIPlayerSlotExtension"
}

local global_ai_target_units = AI_TARGET_UNITS

AISlotSystem.init = function (self, extension_system_creation_context, system_name, extension_list)
	AISlotSystem.super.init(self, extension_system_creation_context, system_name, extension_list)

	self.nav_world = Managers.state.extension:system("ai_system"):nav_world()
	self.unit_extension_data = {}
	self.update_slots_ai_units = {}
	self.update_slots_ai_units_prioritized = {}
	self.target_units = {}
	self.current_ai_index = 1
	self.total_slots_count = 0
	self.next_total_slot_count_update = 0
	self.next_disabled_slot_count_update = 0

	local layer_costs = {
		bot_poison_wind = 1,
		bot_ratling_gun_fire = 1,
		fire_grenade = 1,
		smoke_grenade = 1
	}

	table.merge(layer_costs, NAV_TAG_VOLUME_LAYER_COST_AI)

	self._traverse_logic = GwNavTraverseLogicData.create(self.nav_world)
	self._navtag_layer_cost_table = GwNavTagLayerCostTable.create()

	AiUtils.initialize_cost_table(self._navtag_layer_cost_table, layer_costs)
	GwNavTraverseLogicData.set_navtag_layer_cost_table(self._traverse_logic, self._navtag_layer_cost_table)
end

local SLOT_COLORS

AISlotSystem.destroy = function (self)
	if self._traverse_logic ~= nil then
		GwNavTagLayerCostTable.destroy(self._navtag_layer_cost_table)
		GwNavTraverseLogicData.destroy(self._traverse_logic)
	end
end

local SLOT_RADIUS = 0.5
local SLOT_POSITION_CHECK_INDEX = {
	CHECK_LEFT = 0,
	CHECK_FAR = 3,
	CHECK_RIGHT = 2,
	CHECK_NEAR = 4,
	CHECK_MIDDLE = 1
}
local SLOT_POSITION_CHECK_INDEX_SIZE = table.size(SLOT_POSITION_CHECK_INDEX)
local SLOT_POSITION_CHECK_RADIANS = {}

SLOT_POSITION_CHECK_RADIANS[SLOT_POSITION_CHECK_INDEX.CHECK_LEFT] = math.degrees_to_radians(-90)
SLOT_POSITION_CHECK_RADIANS[SLOT_POSITION_CHECK_INDEX.CHECK_RIGHT] = math.degrees_to_radians(90)

local function create_target_slots(target_unit, target_unit_extension, color_index)
	local target_slots = target_unit_extension.slots
	local total_slots_count = target_unit_extension.total_slots_count

	for i = 1, total_slots_count do
		local slot = {}

		slot.target_unit = target_unit
		slot.queue = {}
		slot.original_absolute_position = Vector3Box(0, 0, 0)
		slot.absolute_position = Vector3Box(0, 0, 0)
		slot.ghost_position = Vector3Box(0, 0, 0)
		slot.queue_direction = Vector3Box(0, 0, 0)
		slot.position_right = Vector3Box(0, 0, 0)
		slot.position_left = Vector3Box(0, 0, 0)
		slot.index = i
		slot.anchor_weight = 0
		slot.position_check_index = SLOT_POSITION_CHECK_INDEX.CHECK_MIDDLE
		target_slots[i] = slot

		local j = (i - 1) % 9 + 1

		slot.debug_color_name = SLOT_COLORS[color_index][j]
	end
end

local function delete_slot(slot, unit_extension_data)
	if not slot then
		return
	end

	local ai_unit = slot.ai_unit

	if ai_unit then
		local ai_unit_extension = unit_extension_data[ai_unit]

		if ai_unit_extension then
			ai_unit_extension.slot = nil
		end
	end

	local queue = slot.queue
	local queue_n = #queue

	for i = 1, queue_n do
		local ai_unit_waiting = queue[i]
		local ai_unit_waiting_extension = unit_extension_data[ai_unit_waiting]

		if ai_unit_waiting_extension then
			ai_unit_waiting_extension.waiting_on_slot = nil
		end
	end

	local target_unit = slot.target_unit
	local target_unit_extension = unit_extension_data[target_unit]

	if target_unit_extension then
		local target_slots = target_unit_extension.slots
		local target_slots_n = #target_slots

		for i = 1, target_slots_n do
			if target_slots[i] == slot then
				target_slots[i] = target_slots[target_slots_n]
				target_slots[i].index = i
				target_slots[target_slots_n] = nil

				break
			end
		end
	end

	if false then
		-- Nothing
	end

	slot = nil
end

local function disable_slot(slot, unit_extension_data)
	local ai_unit = slot.ai_unit

	if ai_unit then
		local ai_unit_extension = unit_extension_data[ai_unit]

		ai_unit_extension.slot = nil
		slot.ai_unit = nil
	end

	slot.disabled = true
	slot.released = false
end

local function enable_slot(slot)
	slot.disabled = false
end

local function slots_count(target_unit, unit_extension_data)
	local target_unit_extension = unit_extension_data[target_unit]
	local target_slots = target_unit_extension.slots
	local total_slots_count = target_unit_extension.total_slots_count
	local slots_n = 0

	for i = 1, total_slots_count do
		local slot = target_slots[i]

		if slot.ai_unit then
			slots_n = slots_n + 1
		end

		slots_n = slots_n + #slot.queue
	end

	return slots_n
end

local function detach_ai_unit_from_slot(ai_unit, unit_extension_data)
	local ai_unit_extension = unit_extension_data[ai_unit]

	if not ai_unit_extension then
		return
	end

	local slot = ai_unit_extension.slot
	local waiting_on_slot = ai_unit_extension.waiting_on_slot

	if slot then
		local queue = slot.queue
		local queue_n = #queue

		if queue_n > 0 then
			local ai_unit_waiting = queue[queue_n]
			local ai_unit_waiting_extension = unit_extension_data[ai_unit_waiting]

			slot.ai_unit = ai_unit_waiting
			ai_unit_waiting_extension.slot = slot
			ai_unit_waiting_extension.waiting_on_slot = nil
			queue[queue_n] = nil
		else
			slot.ai_unit = nil
		end

		local target_unit = slot.target_unit
		local target_unit_extension = unit_extension_data[target_unit]

		target_unit_extension.slots_count = slots_count(target_unit, unit_extension_data)
	elseif waiting_on_slot then
		local queue = waiting_on_slot.queue
		local queue_n = #queue

		for i = 1, queue_n do
			local ai_unit_waiting = queue[i]
			local ai_unit_waiting_extension = unit_extension_data[ai_unit_waiting]

			if ai_unit_waiting == ai_unit then
				queue[i] = queue[queue_n]
				queue[queue_n] = nil
			end
		end
	end

	ai_unit_extension.waiting_on_slot = nil
	ai_unit_extension.slot = nil
end

local unit_alive = AiUtils.unit_alive
local unit_knocked_down = AiUtils.unit_knocked_down

AISlotSystem.hot_join_sync = function (self, sender, player)
	return
end

local AI_UPDATES_PER_FRAME = 1
local SLOT_QUEUE_DISTANCE = 2.5
local SLOT_QUEUE_DISTANCE_SQ = SLOT_QUEUE_DISTANCE * SLOT_QUEUE_DISTANCE
local SLOT_QUEUE_RADIUS = 1.75
local SLOT_QUEUE_RADIUS_SQ = SLOT_QUEUE_RADIUS * SLOT_QUEUE_RADIUS
local SLOT_QUEUE_RANDOM_POS_MAX_UP = 1.5
local SLOT_QUEUE_RANDOM_POS_MAX_DOWN = 2
local SLOT_QUEUE_RANDOM_POS_MAX_HORIZONTAL = 3
local SLOT_Z_MAX_DOWN = 7.5
local SLOT_Z_MAX_UP = 4
local TARGET_MOVED = 0.15
local TARGET_SLOTS_UPDATE = 0.25
local TARGET_SLOTS_UPDATE_LONG = 1
local Z_MAX_DIFFERENCE = 1.5
local Z_MAX_DIFFERENCE_ABOVE = 0.5
local Z_MAX_DIFFERENCE_BELOW = 2.5
local NAVMESH_DISTANCE_FROM_WALL = 0.5
local MOVER_RADIUS = 0.6
local RAYCANGO_OFFSET = NAVMESH_DISTANCE_FROM_WALL + MOVER_RADIUS

AISlotSystem.do_slot_search = function (self, ai_unit, set)
	local ai_unit_extension = self.unit_extension_data[ai_unit]

	ai_unit_extension.do_search = set
end

local TARGET_OUTSIDE_NAVMESH_TIMEOUT = 2

AISlotSystem.has_target_been_outside_navmesh_too_long = function (self, target_unit, t)
	local unit_extension_data = self.unit_extension_data
	local target_unit_extension = unit_extension_data[target_unit]
	local outside_navmesh_at_t = target_unit_extension and target_unit_extension.outside_navmesh_at_t
	local intervention_time = math.max(CurrentSpecialsSettings.outside_navmesh_intervention.intervention_time, TARGET_OUTSIDE_NAVMESH_TIMEOUT)
	local has_target_been_outside_navmesh_too_long = outside_navmesh_at_t and t > outside_navmesh_at_t + intervention_time

	return has_target_been_outside_navmesh_too_long
end

local function clamp_position_on_navmesh(position, nav_world, above, below)
	below = below or Z_MAX_DIFFERENCE_BELOW
	above = above or Z_MAX_DIFFERENCE_ABOVE

	local position_on_navmesh
	local altitude = GwNavQueries.triangle_from_position(nav_world, position, above, below)

	if altitude then
		position_on_navmesh = Vector3.copy(position)
		position_on_navmesh.z = altitude
	end

	return altitude and position_on_navmesh or nil
end

function get_target_pos_on_navmesh(target_position, nav_world)
	local position_on_navmesh = clamp_position_on_navmesh(target_position, nav_world)

	if position_on_navmesh then
		return position_on_navmesh
	end

	local above_limit = Z_MAX_DIFFERENCE_ABOVE
	local below_limit = Z_MAX_DIFFERENCE_BELOW
	local horizontal_limit = 1
	local distance_from_nav_border = 0.05

	target_position = target_position - Vector3.up() * 1.75

	local border_position = GwNavQueries.inside_position_from_outside_position(nav_world, target_position, above_limit, below_limit, horizontal_limit, distance_from_nav_border)

	if border_position then
		return border_position
	end

	above_limit = Z_MAX_DIFFERENCE_ABOVE
	below_limit = Z_MAX_DIFFERENCE_BELOW
	position_on_navmesh = clamp_position_on_navmesh(target_position, nav_world, above_limit, below_limit)

	if position_on_navmesh then
		return position_on_navmesh
	end

	return nil
end

local PENALTY_TERM = 100

local function get_slot_queue_position(unit_extension_data, slot, nav_world, distance_modifier)
	local target_unit = slot.target_unit
	local ai_unit = slot.ai_unit

	if not unit_alive(target_unit) or not unit_alive(ai_unit) then
		return
	end

	local target_unit_extension = unit_extension_data[target_unit]
	local target_unit_position = target_unit_extension.position:unbox()
	local ai_unit_position = POSITION_LOOKUP[ai_unit]
	local slot_queue_direction = slot.queue_direction:unbox()
	local slot_queue_distance_modifier = distance_modifier or 0
	local target_to_ai_distance = Vector3.distance(target_unit_position, ai_unit_position)
	local slot_queue_distance = target_to_ai_distance + SLOT_QUEUE_DISTANCE + slot_queue_distance_modifier
	local slot_queue_position = target_unit_position + slot_queue_direction * slot_queue_distance
	local slot_queue_position_on_navmesh = clamp_position_on_navmesh(slot_queue_position, nav_world)
	local max_tries = 5
	local i = 1

	while not slot_queue_position_on_navmesh and i <= max_tries do
		slot_queue_distance = math.max(target_to_ai_distance * (1 - i / max_tries), SLOT_DISTANCE(target_unit_extension)) + SLOT_QUEUE_DISTANCE + slot_queue_distance_modifier
		slot_queue_position = target_unit_position + slot_queue_direction * slot_queue_distance
		slot_queue_position_on_navmesh = clamp_position_on_navmesh(slot_queue_position, nav_world)
		i = i + 1
	end

	local penalty_term = 0

	if not slot_queue_position_on_navmesh then
		penalty_term = PENALTY_TERM
		slot_queue_position = target_unit_position + slot_queue_direction * SLOT_QUEUE_DISTANCE

		return slot_queue_position, penalty_term
	else
		return slot_queue_position_on_navmesh, penalty_term
	end
end

local function offset_slot(target_unit, slot_absolute_position, target_unit_position)
	local target_velocity

	if ScriptUnit.has_extension(target_unit, "locomotion_system") then
		target_velocity = ScriptUnit.extension(target_unit, "locomotion_system"):current_velocity()
	else
		target_velocity = Vector3(0, 0, 0)
	end

	if Vector3.length(target_velocity) > 0.1 then
		local speed = Vector3.length(target_velocity)
		local move_direction = Vector3.normalize(target_velocity)
		local wanted_slot_offset = move_direction * speed
		local slot_to_target_dir = Vector3.normalize(target_unit_position - slot_absolute_position)
		local dot = Vector3.dot(slot_to_target_dir, move_direction)
		local predict_time = math.max(2 * (dot - 0.5), 0)
		local current_slot_offset = wanted_slot_offset * predict_time
		local slot_offset_position = slot_absolute_position + current_slot_offset

		return slot_offset_position
	else
		return slot_absolute_position
	end
end

AISlotSystem.improve_slot_position = function (self, ai_unit, t)
	if not unit_alive(ai_unit) then
		return
	end

	local ai_unit_position = POSITION_LOOKUP[ai_unit]
	local ai_unit_extension = self.unit_extension_data[ai_unit]
	local slot = ai_unit_extension.slot
	local waiting_on_slot = ai_unit_extension.waiting_on_slot
	local position

	if slot then
		if slot.ghost_position.x ~= 0 then
			position = slot.ghost_position:unbox()
		else
			position = slot.absolute_position:unbox()
		end
	elseif waiting_on_slot and t > ai_unit_extension.improve_wait_slot_position_t then
		local nav_world = self.nav_world
		local queue = waiting_on_slot.queue
		local distance_modifier = queue[1] == ai_unit and -0.5 or 0.5
		local slot_queue_position = get_slot_queue_position(self.unit_extension_data, waiting_on_slot, nav_world, distance_modifier)
		local above_limit = SLOT_QUEUE_RANDOM_POS_MAX_UP
		local below_limit = SLOT_QUEUE_RANDOM_POS_MAX_DOWN
		local horizontal_limit = SLOT_QUEUE_RANDOM_POS_MAX_HORIZONTAL
		local min_dist = 0
		local max_dist = SLOT_QUEUE_RADIUS
		local max_tries = 2
		local random_goal_function = LocomotionUtils.new_random_goal_uniformly_distributed_with_inside_from_outside_on_last
		local random_slot_position = slot_queue_position and random_goal_function(nav_world, nil, slot_queue_position, min_dist, max_dist, max_tries, nil, above_limit, below_limit, horizontal_limit) or nil
		local z_diff = random_slot_position and math.abs(ai_unit_position.z - random_slot_position.z) or 0
		local z_diff_exceded = z_diff > Z_MAX_DIFFERENCE
		local distance = random_slot_position and Vector3.distance(random_slot_position, ai_unit_position) or math.huge
		local close_distance = distance < 5

		position = random_slot_position

		if z_diff_exceded and close_distance then
			position = nil
		end

		ai_unit_extension.wait_slot_distance = distance
		ai_unit_extension.improve_wait_slot_position_t = t + Math.random() * 0.4
	else
		return
	end

	if not position then
		return
	end

	local distance_sq = Vector3.distance_squared(ai_unit_position, position)
	local navigation_extension = ScriptUnit.extension(ai_unit, "ai_navigation_system")
	local previous_destination = navigation_extension:destination()

	if distance_sq > 1 or Vector3.dot(position - ai_unit_position, previous_destination - ai_unit_position) < 0 then
		local ai_base_extension = ScriptUnit.extension(ai_unit, "ai_system")
		local breed = ai_base_extension:breed()
		local slot_distance_modifier = breed.slot_distance_modifier

		if slot and slot_distance_modifier then
			local target_unit = slot.target_unit
			local target_unit_extension = self.unit_extension_data[target_unit]
			local target_unit_position = target_unit_extension.position:unbox()
			local direction = position - target_unit_position
			local offset_vector = direction * slot_distance_modifier
			local wanted_position = position + offset_vector
			local nav_world = self.nav_world
			local nav_mesh_position = get_target_pos_on_navmesh(wanted_position, nav_world)

			if nav_mesh_position then
				position = nav_mesh_position
			end
		end

		navigation_extension:move_to(position)
	end
end

AISlotSystem.ai_unit_have_slot = function (self, ai_unit)
	local ai_unit_extension = self.unit_extension_data[ai_unit]

	if not ai_unit_extension then
		return false
	end

	local slot = ai_unit_extension.slot

	if not slot then
		return false
	end

	return true
end

AISlotSystem.ai_unit_wait_slot_distance = function (self, ai_unit)
	local ai_unit_extension = self.unit_extension_data[ai_unit]

	if not ai_unit_extension then
		return math.huge
	end

	local slot = ai_unit_extension.slot

	if slot then
		return math.huge
	end

	local waiting_on_slot = ai_unit_extension.waiting_on_slot

	if not waiting_on_slot then
		return math.huge
	end

	local distance = ai_unit_extension.wait_slot_distance or math.huge

	return distance
end

AISlotSystem.ai_unit_slot_position = function (self, ai_unit)
	local ai_unit_extension = self.unit_extension_data[ai_unit]

	if not ai_unit_extension then
		return nil
	end

	local slot = ai_unit_extension.slot or ai_unit_extension.waiting_on_slot

	if slot then
		return slot.absolute_position:unbox()
	end

	return nil
end

AISlotSystem.get_target_unit_slot_data = function (self, target_unit)
	local target_unit_extension = self.unit_extension_data[target_unit]
	local slots = target_unit_extension.slots

	return slots
end

local function update_target(target_unit, ai_unit, ai_blackboard, unit_extension_data, t)
	local ai_unit_extension = unit_extension_data[ai_unit]

	if not Unit.alive(target_unit) then
		ai_unit_extension.target = nil

		ai_unit_extension.target_position:store(0, 0, 0)

		if ai_unit_extension.slot then
			detach_ai_unit_from_slot(ai_unit, unit_extension_data)
		end

		return
	end

	local target_unit_position = POSITION_LOOKUP[target_unit]

	ai_unit_extension.target_position:store(target_unit_position)
end

local function rotate_position_from_origin(origin, position, radians, distance)
	local direction_vector = Vector3.normalize(Vector3.flat(position - origin))
	local rotation = Quaternion(-Vector3.up(), radians)
	local vector = Quaternion.rotate(rotation, direction_vector)
	local position_rotated = origin + vector * distance

	return position_rotated
end

local function set_slot_edge_positions(slot, target_unit_extension)
	local target_unit = slot.target_unit
	local unit_position = target_unit_extension.position:unbox()
	local slot_absolute_position = slot.original_absolute_position:unbox()
	local slot_radians = target_unit_extension.slot_radians
	local position_right = rotate_position_from_origin(unit_position, slot_absolute_position, slot_radians, SLOT_DISTANCE(target_unit_extension))
	local position_left = rotate_position_from_origin(unit_position, slot_absolute_position, -slot_radians, SLOT_DISTANCE(target_unit_extension))

	slot.position_right:store(position_right)
	slot.position_left:store(position_left)
end

local function set_slot_absolute_position(slot, position, target_unit_extension)
	local target_unit = slot.target_unit
	local target_position = target_unit_extension.position:unbox()
	local direction_vector = Vector3.normalize(Vector3.flat(position - target_position))

	slot.absolute_position:store(position)
	slot.queue_direction:store(direction_vector)
	set_slot_edge_positions(slot, target_unit_extension)
end

function get_slot_position_on_navmesh(target_unit, target_position, wanted_position, radians, distance, should_offset_slot, nav_world, above, below)
	local original_position = radians and rotate_position_from_origin(target_position, wanted_position, radians, distance) or wanted_position
	local offsetted_position = should_offset_slot and offset_slot(target_unit, original_position, target_position) or original_position
	local position_on_navmesh = clamp_position_on_navmesh(offsetted_position, nav_world, above, below)

	return position_on_navmesh, original_position
end

local function get_slot_position_on_navmesh_from_outside_target(target_position, slot_direction, radians, distance, nav_world, above, below)
	local position_on_navmesh
	local max_tries = 10
	local dist_per_try = 0.15

	if radians then
		local rotation = Quaternion(-Vector3.up(), radians)

		slot_direction = Quaternion.rotate(rotation, slot_direction)
	end

	for i = 0, max_tries - 1 do
		local wanted_position = target_position + slot_direction * (i * dist_per_try + distance)

		position_on_navmesh = clamp_position_on_navmesh(wanted_position, nav_world, above, below)

		if position_on_navmesh then
			break
		end
	end

	return position_on_navmesh, position_on_navmesh
end

local function get_reachable_slot_position_on_navmesh(slot, target_unit, target_position, wanted_position, radians, distance, should_offset_slot, nav_world, traverse_logic, above, below)
	local position_on_navmesh, original_position = get_slot_position_on_navmesh(target_unit, target_position, wanted_position, radians, distance, should_offset_slot, nav_world, above, below)
	local check_index = slot.position_check_index
	local is_using_middle_check = check_index == SLOT_POSITION_CHECK_INDEX.CHECK_MIDDLE
	local check_radians = not is_using_middle_check and SLOT_POSITION_CHECK_RADIANS[check_index] or nil
	local raycango_offset = RAYCANGO_OFFSET

	if position_on_navmesh then
		local check_position

		if is_using_middle_check then
			check_position = position_on_navmesh
		elseif check_index == SLOT_POSITION_CHECK_INDEX.CHECK_NEAR then
			local direction = wanted_position - target_position
			local offset_vector = direction * SLOT_RADIUS

			check_position = wanted_position - offset_vector
		elseif check_index == SLOT_POSITION_CHECK_INDEX.CHECK_FAR then
			local direction = wanted_position - target_position
			local offset_vector = direction * SLOT_RADIUS

			check_position = wanted_position + offset_vector
		else
			check_position = rotate_position_from_origin(position_on_navmesh, target_position, check_radians, SLOT_RADIUS)
		end

		local ray_target_pos = target_position + Vector3.normalize(check_position - target_position) * raycango_offset
		local ray_can_go = GwNavQueries.raycango(nav_world, check_position, ray_target_pos, traverse_logic)

		if not ray_can_go then
			position_on_navmesh = nil
		end
	elseif not is_using_middle_check then
		local check_position

		if check_index == SLOT_POSITION_CHECK_INDEX.CHECK_NEAR then
			local direction = wanted_position - target_position
			local offset_vector = direction * SLOT_RADIUS

			check_position = wanted_position - offset_vector
		elseif check_index == SLOT_POSITION_CHECK_INDEX.CHECK_FAR then
			local direction = wanted_position - target_position
			local offset_vector = direction * SLOT_RADIUS

			check_position = wanted_position + offset_vector
		else
			check_position = rotate_position_from_origin(wanted_position, target_position, check_radians, SLOT_RADIUS)
		end

		position_on_navmesh, original_position = get_slot_position_on_navmesh(target_unit, target_position, check_position, radians, distance, should_offset_slot, nav_world, above, below)

		if position_on_navmesh then
			local ray_target_pos = target_position + Vector3.normalize(position_on_navmesh - target_position) * raycango_offset
			local ray_can_go = GwNavQueries.raycango(nav_world, position_on_navmesh, ray_target_pos, traverse_logic)

			if ray_can_go then
				slot.position_check_index = SLOT_POSITION_CHECK_INDEX.CHECK_MIDDLE
			else
				position_on_navmesh = nil
			end
		end
	end

	if not position_on_navmesh then
		slot.position_check_index = (slot.position_check_index + 1) % SLOT_POSITION_CHECK_INDEX_SIZE
	end

	return position_on_navmesh, original_position
end

local OVERLAP_DISTANCE = 0.5
local OVERLAP_DISTANCE_SQ = OVERLAP_DISTANCE * OVERLAP_DISTANCE

local function overlap_with_other_target_slot(slot, target_units, unit_extension_data)
	local slot_target_unit = slot.target_unit
	local slot_position = slot.absolute_position:unbox()
	local target_units_n = #target_units

	for i = 1, target_units_n do
		repeat
			local target_unit = target_units[i]

			if target_unit == slot_target_unit then
				break
			end

			local target_unit_extension = unit_extension_data[target_unit]
			local target_slots = target_unit_extension.slots
			local total_slots_count = target_unit_extension.total_slots_count

			for j = 1, total_slots_count do
				repeat
					local target_slot = target_slots[j]

					if target_slot.disabled then
						break
					end

					local target_slot_position = target_slot.absolute_position:unbox()
					local distance_squared = Vector3.distance_squared(slot_position, target_slot_position)

					if distance_squared < OVERLAP_DISTANCE_SQ then
						return target_slot
					end
				until true
			end
		until true
	end

	return false
end

local OVERLAP_SLOT_TO_TARGET_DISTANCE = 1.2
local OVERLAP_SLOT_TO_TARGET_DISTANCE_SQ = OVERLAP_SLOT_TO_TARGET_DISTANCE * OVERLAP_SLOT_TO_TARGET_DISTANCE

local function overlap_with_other_target(slot, target_units, unit_extension_data)
	local slot_target_unit = slot.target_unit
	local slot_position = slot.absolute_position:unbox()
	local target_units_n = #target_units

	for i = 1, target_units_n do
		repeat
			local target_unit = target_units[i]

			if target_unit == slot_target_unit then
				break
			end

			local target_unit_position = unit_extension_data[target_unit].position:unbox()
			local distance_squared = Vector3.distance_squared(slot_position, target_unit_position)

			if distance_squared < OVERLAP_SLOT_TO_TARGET_DISTANCE_SQ then
				return true
			end
		until true
	end

	return false
end

local function disable_overlaping_slot(slot, overlap_slot, unit_extension_data, t)
	local target_unit = slot.target_unit
	local target_unit_extension = unit_extension_data[target_unit]
	local target_index = target_unit_extension.index
	local slot_index = slot.index
	local overlap_target_unit = overlap_slot.target_unit
	local overlap_target_unit_extension = unit_extension_data[overlap_target_unit]
	local overlap_target_index = overlap_target_unit_extension.index
	local overlap_slot_index = overlap_slot.index

	if overlap_slot_index < slot_index then
		disable_slot(slot, unit_extension_data)

		return true
	end

	if slot_index < overlap_slot_index then
		disable_slot(overlap_slot, unit_extension_data)

		return false
	end

	if overlap_target_index < target_index then
		disable_slot(slot, unit_extension_data)

		return true
	else
		disable_slot(overlap_slot, unit_extension_data)

		return false
	end
end

local function slot_is_behind_target(slot, ai_unit, target_unit_extension)
	local slot_position = slot.original_absolute_position:unbox()
	local ai_unit_position = POSITION_LOOKUP[ai_unit]
	local target_unit = slot.target_unit
	local target_unit_position = target_unit_extension.position:unbox()
	local flat_target_unit_to_slot_vector = Vector3.flat(slot_position - target_unit_position)
	local normalized_target_unit_to_slot_vector = Vector3.normalize(flat_target_unit_to_slot_vector)
	local flat_target_unit_to_ai_unit_vector = Vector3.flat(ai_unit_position - target_unit_position)
	local normalized_target_unit_to_ai_unit_vector = Vector3.normalize(flat_target_unit_to_ai_unit_vector)
	local dot_value = Vector3.dot(normalized_target_unit_to_slot_vector, normalized_target_unit_to_ai_unit_vector)

	return dot_value < 0.6
end

local function clear_ghost_position(slot)
	slot.ghost_position:store(Vector3(0, 0, 0))
end

local GHOST_ANGLE = 90
local GHOST_RADIANS = math.degrees_to_radians(GHOST_ANGLE)

local function set_ghost_position(target_unit_extension, slot, nav_world, traverse_logic)
	local slot_position = slot.absolute_position:unbox()
	local ai_unit = slot.ai_unit
	local ai_unit_position = POSITION_LOOKUP[ai_unit]
	local target_unit_position = target_unit_extension.position:unbox()
	local target_unit_to_ai_unit_vector = Vector3.normalize(ai_unit_position - target_unit_position)
	local distance = math.min(Vector3.distance(target_unit_position, ai_unit_position), 8)
	local ghost_position_left = rotate_position_from_origin(slot_position, ai_unit_position, -GHOST_RADIANS, distance)
	local ghost_position_right = rotate_position_from_origin(slot_position, ai_unit_position, GHOST_RADIANS, distance)
	local distance_ghost_position_left = Vector3.distance_squared(target_unit_position, ghost_position_left)
	local distance_ghost_position_right = Vector3.distance_squared(target_unit_position, ghost_position_right)
	local use_ghost_position_left = distance_ghost_position_right < distance_ghost_position_left
	local ghost_position = use_ghost_position_left and ghost_position_left or ghost_position_right
	local ghost_position_on_navmesh = clamp_position_on_navmesh(ghost_position, nav_world)
	local ghost_position_direction

	if ghost_position_on_navmesh then
		ghost_position_direction = Vector3.normalize(ghost_position_on_navmesh - slot_position)
	else
		ghost_position_direction = Vector3.normalize(ghost_position - slot_position)
	end

	local max_tries = 5

	for i = 1, max_tries do
		if ghost_position_on_navmesh then
			local ray_can_go = GwNavQueries.raycango(nav_world, ghost_position_on_navmesh, slot_position, traverse_logic)

			if ray_can_go then
				slot.ghost_position:store(ghost_position_on_navmesh)

				return
			end
		end

		local ghost_position_distance = SLOT_DISTANCE(target_unit_extension) + (distance - SLOT_DISTANCE(target_unit_extension)) * (max_tries - i) / max_tries

		ghost_position = target_unit_position + ghost_position_direction * ghost_position_distance
		ghost_position_on_navmesh = clamp_position_on_navmesh(ghost_position, nav_world)
	end

	clear_ghost_position(slot)
end

local function update_slot_anchor_weight(slot, target_unit, unit_extension_data)
	local target_unit_extension = unit_extension_data[target_unit]
	local target_slots = target_unit_extension.slots
	local slot_index = slot.index
	local total_slots_count = target_unit_extension.total_slots_count
	local score = 128
	local slot_valid = slot.ai_unit and not slot.released

	slot.anchor_weight = slot_valid and 256 or 0

	for i = 1, total_slots_count do
		local index = slot_index + i

		if total_slots_count < index then
			index = index - total_slots_count
		end

		local slot_right = target_slots[index]
		local slot_disabled = slot_right.disabled
		local slot_released = slot_right.released
		local ai_unit = slot_right.ai_unit

		if slot_disabled or not ai_unit then
			break
		end

		if not slot_released then
			slot.anchor_weight = slot.anchor_weight + score
			score = score / 2
		end
	end

	score = 128

	for i = 1, total_slots_count do
		local index = slot_index - i

		if index < 1 then
			index = index + total_slots_count
		end

		local slot_left = target_slots[index]
		local slot_disabled = slot_left.disabled
		local slot_released = slot_left.released
		local ai_unit = slot_left.ai_unit

		if slot_disabled or not ai_unit then
			break
		end

		if not slot_released then
			slot.anchor_weight = slot.anchor_weight + score
			score = score / 2
		end
	end
end

local function update_anchor_weights(target_unit, unit_extension_data)
	local target_unit_extension = unit_extension_data[target_unit]
	local target_slots = target_unit_extension.slots
	local total_slots_count = target_unit_extension.total_slots_count

	for i = 1, total_slots_count do
		local slot = target_slots[i]

		update_slot_anchor_weight(slot, target_unit, unit_extension_data)
	end
end

local RELEASE_SLOT_DISTANCE = 3
local RELEASE_SLOT_DISTANCE_SQ = RELEASE_SLOT_DISTANCE * RELEASE_SLOT_DISTANCE

local function check_to_release_slot(slot)
	if slot.disabled then
		return
	end

	local ai_unit = slot.ai_unit

	if not ai_unit then
		slot.released = false

		return
	end

	local ai_unit_position = POSITION_LOOKUP[ai_unit]
	local slot_position = slot.absolute_position:unbox()
	local distance_to_slot_position = Vector3.distance_squared(ai_unit_position, slot_position)
	local slot_released = distance_to_slot_position > RELEASE_SLOT_DISTANCE_SQ

	slot.released = slot_released
end

local function get_anchor_slot(target_unit, unit_extension_data)
	local target_unit_extension = unit_extension_data[target_unit]
	local target_slots = target_unit_extension.slots
	local total_slots_count = target_unit_extension.total_slots_count
	local best_slot = target_slots[1]
	local best_anchor_weight = best_slot.anchor_weight

	for i = 1, total_slots_count do
		repeat
			local slot = target_slots[i]
			local slot_disabled = slot.disabled

			if slot_disabled then
				break
			end

			local slot_anchor_weight = slot.anchor_weight

			if best_anchor_weight < slot_anchor_weight or slot_anchor_weight == best_anchor_weight and slot.index < best_slot.index then
				best_slot = slot
				best_anchor_weight = slot_anchor_weight
			end
		until true
	end

	return best_slot
end

local MAX_GET_SLOT_POSITION_TRIES = 24

local function update_anchor_slot_position(slot, unit_extension_data, should_offset_slot, nav_world, traverse_logic, above, below, target_outside_navmesh)
	local target_unit = slot.target_unit
	local target_unit_extension = unit_extension_data[target_unit]
	local target_position = target_unit_extension.position:unbox()
	local ai_unit = slot.ai_unit
	local ai_position = ai_unit and POSITION_LOOKUP[ai_unit]
	local direction_vector = ai_unit and Vector3.normalize(ai_position - target_position) or Vector3.forward()
	local slot_distance = SLOT_DISTANCE(target_unit_extension)
	local wanted_position = target_position + direction_vector * slot_distance
	local position_on_navmesh, original_position

	if target_outside_navmesh then
		position_on_navmesh, original_position = get_slot_position_on_navmesh_from_outside_target(target_position, direction_vector, nil, slot_distance, nav_world, above, below)
	else
		position_on_navmesh, original_position = get_reachable_slot_position_on_navmesh(slot, target_unit, target_position, wanted_position, nil, nil, should_offset_slot, nav_world, traverse_logic, above, below)
	end

	local i = 0

	while i <= MAX_GET_SLOT_POSITION_TRIES and not position_on_navmesh do
		local sign = i % 2 > 0 and -1 or 1
		local radians = math.ceil(i / 2) * sign

		if target_outside_navmesh then
			position_on_navmesh, original_position = get_slot_position_on_navmesh_from_outside_target(target_position, direction_vector, radians, slot_distance, nav_world, above, below)
		else
			position_on_navmesh, original_position = get_reachable_slot_position_on_navmesh(slot, target_unit, target_position, wanted_position, radians, slot_distance, should_offset_slot, nav_world, traverse_logic, above, below)
		end

		i = i + 1
	end

	if position_on_navmesh then
		slot.original_absolute_position:store(original_position)
		set_slot_absolute_position(slot, position_on_navmesh, target_unit_extension)

		return true, position_on_navmesh
	else
		slot.original_absolute_position:store(wanted_position)
		set_slot_absolute_position(slot, wanted_position, target_unit_extension)

		return false, wanted_position
	end
end

local function update_slot_position(target_unit, slot, slot_position, unit_extension_data, should_offset_slot, nav_world, traverse_logic, above, below, target_outside_navmesh)
	local target_unit_extension = unit_extension_data[target_unit]
	local target_position = target_unit_extension.position:unbox()
	local position_on_navmesh, original_position

	if target_outside_navmesh then
		position_on_navmesh, original_position = get_slot_position_on_navmesh_from_outside_target(target_position, Vector3.normalize(slot_position - target_position), nil, SLOT_DISTANCE(target_unit_extension), nav_world, above, below)
	else
		position_on_navmesh, original_position = get_reachable_slot_position_on_navmesh(slot, target_unit, target_position, slot_position, nil, nil, should_offset_slot, nav_world, traverse_logic, above, below)
	end

	if position_on_navmesh then
		slot.original_absolute_position:store(original_position)
		set_slot_absolute_position(slot, position_on_navmesh, target_unit_extension)

		return true, position_on_navmesh
	else
		slot.original_absolute_position:store(slot_position)
		set_slot_absolute_position(slot, slot_position, target_unit_extension)

		return false, slot_position
	end
end

local function disable_all_slots(target_unit, unit_extension_data)
	local target_unit_extension = unit_extension_data[target_unit]
	local target_slots = target_unit_extension.slots
	local total_slots_count = target_unit_extension.total_slots_count

	for i = 1, total_slots_count do
		local slot = target_slots[i]

		disable_slot(slot, unit_extension_data)
	end
end

local function update_slot_status(slot, is_on_navmesh, target_units, unit_extension_data)
	if is_on_navmesh then
		enable_slot(slot)
	else
		disable_slot(slot, unit_extension_data)

		return false
	end

	local overlaps_with_other_target = overlap_with_other_target(slot, target_units, unit_extension_data)

	if not overlaps_with_other_target then
		enable_slot(slot)
	else
		disable_slot(slot, unit_extension_data)

		return false
	end

	local overlap_slot = overlap_with_other_target_slot(slot, target_units, unit_extension_data)

	if overlap_slot then
		local disabled = disable_overlaping_slot(slot, overlap_slot, unit_extension_data)

		if not disabled then
			enable_slot(slot)
		else
			return false
		end
	end

	check_to_release_slot(slot)

	return true
end

local function update_target_slots_status(target_unit, target_units, unit_extension_data, nav_world, traverse_logic, outside_navmesh)
	Profiler.start("update_target_slots_status")

	local target_unit_extension = unit_extension_data[target_unit]
	local target_slots = target_unit_extension.slots
	local total_slots_count = target_unit_extension.total_slots_count
	local should_offset_slot = false

	for i = 1, total_slots_count do
		local slot = target_slots[i]
		local slot_position = slot.absolute_position:unbox()
		local is_on_navmesh = update_slot_position(target_unit, slot, slot_position, unit_extension_data, should_offset_slot, nav_world, traverse_logic, nil, nil, outside_navmesh)

		update_slot_status(slot, is_on_navmesh, target_units, unit_extension_data)
	end

	update_anchor_weights(target_unit, unit_extension_data)
	Profiler.stop()
end

local function update_target_slots_positions_on_ladder(target_unit, target_units, unit_extension_data, should_offset_slot, nav_world, traverse_logic, ladder_unit, bottom, top)
	local target_unit_extension = unit_extension_data[target_unit]
	local target_slots = target_unit_extension.slots
	local total_slots_count = target_unit_extension.total_slots_count
	local slot_offset_dist = 1
	local ladder_dir = Vector3.normalize(Vector3.flat(Quaternion.forward(Unit.world_rotation(ladder_unit, 1))))
	local ladder_right = Vector3.cross(ladder_dir, Vector3.up())
	local top_half = math.floor(total_slots_count / 2)
	local top_anchor_index = math.ceil(top_half / 2)
	local top_anchor_slot = target_slots[top_anchor_index]

	top_anchor_slot.original_absolute_position:store(top)
	set_slot_absolute_position(top_anchor_slot, top, target_unit_extension)
	update_slot_status(top_anchor_slot, true, target_units, unit_extension_data)

	local last_pos = top
	local success = true

	for i = top_anchor_index - 1, 1, -1 do
		local slot = target_slots[i]
		local new_wanted_pos = last_pos - ladder_right * slot_offset_dist

		success = success and GwNavQueries.raycango(nav_world, last_pos, new_wanted_pos, traverse_logic)

		slot.original_absolute_position:store(new_wanted_pos)
		set_slot_absolute_position(slot, new_wanted_pos, target_unit_extension)
		update_slot_status(slot, success, target_units, unit_extension_data)

		last_pos = new_wanted_pos
	end

	last_pos = top
	success = true

	for i = top_anchor_index + 1, top_half do
		local slot = target_slots[i]
		local new_wanted_pos = last_pos + ladder_right * slot_offset_dist

		success = success and GwNavQueries.raycango(nav_world, last_pos, new_wanted_pos, traverse_logic)

		slot.original_absolute_position:store(new_wanted_pos)
		set_slot_absolute_position(slot, new_wanted_pos, target_unit_extension)
		update_slot_status(slot, success, target_units, unit_extension_data)
	end

	local bottom_anchor_index = top_half + math.ceil((total_slots_count - top_half) / 2)
	local bottom_anchor_slot = target_slots[bottom_anchor_index]

	bottom_anchor_slot.original_absolute_position:store(bottom)
	set_slot_absolute_position(bottom_anchor_slot, bottom, target_unit_extension)
	update_slot_status(bottom_anchor_slot, true, target_units, unit_extension_data)

	last_pos = bottom

	local above = 1
	local below = 1
	local circle_radius = 1
	local center = bottom + circle_radius * ladder_dir
	local right_amount = bottom_anchor_index - 1 - top_half
	local angle_increment = math.pi / 2.5 / right_amount
	local increment = 1

	for i = bottom_anchor_index - 1, top_half + 1, -1 do
		local slot = target_slots[i]
		local angle = math.pi * 1.5 + increment * angle_increment
		local new_wanted_pos = center + circle_radius * (ladder_right * math.cos(angle) + ladder_dir * math.sin(angle))
		local z = GwNavQueries.triangle_from_position(nav_world, last_pos, above, below)

		if z then
			new_wanted_pos.z = z
		end

		slot.original_absolute_position:store(new_wanted_pos)
		set_slot_absolute_position(slot, new_wanted_pos, target_unit_extension)
		update_slot_status(slot, success, target_units, unit_extension_data)

		increment = increment + 1
	end

	local left_amount = total_slots_count - bottom_anchor_index

	angle_increment = math.pi / 2.5 / left_amount
	increment = 1
	last_pos = bottom

	for i = bottom_anchor_index + 1, total_slots_count do
		local slot = target_slots[i]
		local angle = math.pi * 1.5 - increment * angle_increment
		local new_wanted_pos = center + circle_radius * (ladder_right * math.cos(angle) + ladder_dir * math.sin(angle))
		local z = GwNavQueries.triangle_from_position(nav_world, last_pos, above, below)

		if z then
			new_wanted_pos.z = z
		end

		slot.original_absolute_position:store(new_wanted_pos)
		set_slot_absolute_position(slot, new_wanted_pos, target_unit_extension)
		update_slot_status(slot, success, target_units, unit_extension_data)

		increment = increment + 1
	end

	update_anchor_weights(target_unit, unit_extension_data)
end

local function update_target_slots_positions(target_unit, target_units, unit_extension_data, should_offset_slot, nav_world, traverse_logic, is_on_ladder, ladder_unit, bottom, top, target_outside_navmesh)
	Profiler.start("update_target_slots_positions")

	if is_on_ladder then
		update_target_slots_positions_on_ladder(target_unit, target_units, unit_extension_data, should_offset_slot, nav_world, traverse_logic, ladder_unit, bottom, top)

		return
	end

	local above, below

	if target_outside_navmesh then
		above, below = Z_MAX_DIFFERENCE_ABOVE, Z_MAX_DIFFERENCE_BELOW
	else
		above, below = Z_MAX_DIFFERENCE_ABOVE, Z_MAX_DIFFERENCE_BELOW
	end

	local target_unit_extension = unit_extension_data[target_unit]
	local target_slots = target_unit_extension.slots
	local anchor_slot = get_anchor_slot(target_unit, unit_extension_data)
	local total_slots_count = target_unit_extension.total_slots_count
	local slot_index = anchor_slot.index
	local is_on_navmesh = update_anchor_slot_position(anchor_slot, unit_extension_data, should_offset_slot, nav_world, traverse_logic, above, below, target_outside_navmesh)

	update_slot_status(anchor_slot, is_on_navmesh, target_units, unit_extension_data)

	for i = slot_index + 1, total_slots_count do
		local slot = target_slots[i]
		local slot_left = target_slots[i - 1]
		local position = slot_left.position_right:unbox()
		local is_on_navmesh = update_slot_position(target_unit, slot, position, unit_extension_data, should_offset_slot, nav_world, traverse_logic, above, below, target_outside_navmesh)

		update_slot_status(slot, is_on_navmesh, target_units, unit_extension_data)
	end

	for i = slot_index - 1, 1, -1 do
		local slot = target_slots[i]
		local slot_right = target_slots[i + 1]
		local position = slot_right.position_left:unbox()
		local is_on_navmesh = update_slot_position(target_unit, slot, position, unit_extension_data, should_offset_slot, nav_world, traverse_logic, above, below, target_outside_navmesh)

		update_slot_status(slot, is_on_navmesh, target_units, unit_extension_data)
	end

	update_anchor_weights(target_unit, unit_extension_data)
	Profiler.stop()
end

local OWNER_STICKY_VALUE = -3
local RELEASED_OWNER_DISTANCE_MODIFIER = -2

local function get_best_slot(target_unit, target_units, ai_unit, unit_extension_data, nav_world, t, skip_slots_behind_target)
	local ai_unit_position = POSITION_LOOKUP[ai_unit]
	local ai_unit_extension = unit_extension_data[ai_unit]
	local target_unit_extension = unit_extension_data[target_unit]
	local target_slots = target_unit_extension.slots
	local total_slots_count = target_unit_extension.total_slots_count
	local best_slot
	local best_score = math.huge
	local previous_slot = ai_unit_extension.slot

	for i = 1, total_slots_count do
		repeat
			local slot = target_slots[i]
			local disabled = slot.disabled

			if disabled then
				break
			end

			if skip_slots_behind_target and slot_is_behind_target(slot, ai_unit, target_unit_extension) then
				break
			end

			local slot_owner = slot.ai_unit
			local slot_released = slot.released
			local slot_position = slot.original_absolute_position:unbox()
			local slot_distance = Vector3.distance_squared(slot_position, ai_unit_position)
			local slot_score = math.huge

			if slot_owner then
				if slot_owner == ai_unit then
					slot_score = slot_distance + OWNER_STICKY_VALUE
				elseif slot_released then
					local owner_position = POSITION_LOOKUP[slot_owner]
					local owner_distance = Vector3.distance_squared(slot_position, owner_position) + RELEASED_OWNER_DISTANCE_MODIFIER

					if slot_distance < owner_distance then
						slot_score = slot_distance
					end
				end
			else
				slot_score = slot_distance
			end

			if slot_score < best_score then
				best_slot = slot
				best_score = slot_score
			end
		until true
	end

	if best_slot then
		repeat
			ai_unit_extension.temporary_wait_position = nil

			local current_slot = ai_unit_extension.slot

			if current_slot and current_slot == best_slot then
				break
			end

			local waiting_on_slot = ai_unit_extension.waiting_on_slot

			if current_slot or waiting_on_slot then
				detach_ai_unit_from_slot(ai_unit, unit_extension_data)
			end

			local previous_slot_owner = best_slot.ai_unit

			if previous_slot_owner then
				local previous_slot_owner_extension = unit_extension_data[previous_slot_owner]

				previous_slot_owner_extension.slot = nil
			end

			best_slot.ai_unit = ai_unit
			ai_unit_extension.slot = best_slot

			update_anchor_weights(target_unit, unit_extension_data)
		until true
	end

	if previous_slot ~= ai_unit_extension.slot then
		target_unit_extension.slots_count = slots_count(target_unit, unit_extension_data)
	elseif not best_slot and previous_slot and skip_slots_behind_target and slot_is_behind_target(previous_slot, ai_unit, target_unit_extension) then
		detach_ai_unit_from_slot(ai_unit, unit_extension_data)

		target_unit_extension.slots_count = slots_count(target_unit, unit_extension_data)
	end
end

SLOT_QUEUE_PENALTY_MULTIPLIER = 3

local function get_best_slot_to_wait_on(target_unit, ai_unit, unit_extension_data, nav_world, skip_slots_behind_target)
	local ai_unit_extension = unit_extension_data[ai_unit]
	local waiting_on_slot = ai_unit_extension.waiting_on_slot
	local target_unit_extension = unit_extension_data[target_unit]

	if waiting_on_slot then
		if waiting_on_slot.disabled or skip_slots_behind_target and slot_is_behind_target(waiting_on_slot, ai_unit, target_unit_extension) then
			detach_ai_unit_from_slot(ai_unit, unit_extension_data)

			waiting_on_slot = nil
		else
			return
		end
	end

	local ai_unit_position = POSITION_LOOKUP[ai_unit]
	local target_slots = target_unit_extension.slots
	local target_slots_n = #target_slots
	local best_distance = math.huge
	local best_slot

	for i = 1, target_slots_n do
		repeat
			local slot = target_slots[i]
			local queue = slot.queue
			local queue_n = #queue

			if slot.disabled then
				break
			end

			if skip_slots_behind_target and slot_is_behind_target(slot, ai_unit, target_unit_extension) then
				break
			end

			local slot_queue_position, additional_penalty = get_slot_queue_position(unit_extension_data, slot, nav_world)

			if not slot_queue_position then
				break
			end

			local slot_queue_distance = Vector3.distance_squared(slot_queue_position, ai_unit_position) + queue_n * queue_n * SLOT_QUEUE_PENALTY_MULTIPLIER + additional_penalty

			if slot_queue_distance < best_distance then
				best_distance = slot_queue_distance
				best_slot = slot
			end
		until true
	end

	if best_slot then
		local queue = best_slot.queue
		local queue_n = #queue

		queue[queue_n + 1] = ai_unit
		ai_unit_extension.waiting_on_slot = best_slot
	end
end

local function update_disabled_slots_count(target_units, unit_extension_data)
	local target_units = target_units
	local target_units_n = #target_units
	local target_unit_extensions = unit_extension_data

	for unit_i = 1, target_units_n do
		local target_unit = target_units[unit_i]
		local target_unit_extension = target_unit_extensions[target_unit]
		local target_slots = target_unit_extension.slots
		local target_slots_n = #target_slots
		local disabled_count = 0

		for slot_i = 1, target_slots_n do
			local slot = target_slots[slot_i]

			if slot.disabled then
				disabled_count = disabled_count + 1
			end
		end

		target_unit_extension.disabled_slots_count = disabled_count
	end
end

AISlotSystem.update = function (self, dt, t)
	if script_data.navigation_thread_disabled then
		self:physics_async_update(dt, t)
	else
		Profiler.start("wait for navigation thread")

		local nav_world = self.nav_world

		GwNavWorld.join_async_update(nav_world)

		NAVIGATION_RUNNING_IN_THREAD = false

		Profiler.stop()
	end
end

local debug_draw_slots, debug_print_slots_count
local SLOT_STATUS_UPDATE_INTERVAL = 0.25
local TOTAL_SLOTS_COUNT_UPDATE_INTERVAL = 1
local DISABLED_SLOTS_COUNT_UPDATE_INTERVAL = 1
local SLOT_SOUND_UPDATE_INTERVAL = 1
local TARGET_STOPPED_MOVING_SPEED_SQ = 0.25

AISlotSystem.physics_async_update = function (self, dt, t)
	self.t = t

	local target_units = self.target_units
	local target_units_n = #target_units

	if target_units_n == 0 then
		return
	end

	local nav_world = self.nav_world
	local unit_extension_data = self.unit_extension_data

	Profiler.start("ai")
	Profiler.start("update_target_slots")

	for i_target = 1, target_units_n do
		local target_unit = target_units[i_target]
		local target_unit_extension = unit_extension_data[target_unit]
		local successful = self:update_target_slots(t, target_unit, target_units, unit_extension_data, target_unit_extension, nav_world, self._traverse_logic)

		if successful then
			break
		end
	end

	Profiler.stop()

	if t > self.next_total_slot_count_update then
		Profiler.start("update_total_slots_count")
		self:update_total_slots_count()

		self.next_total_slot_count_update = t + TOTAL_SLOTS_COUNT_UPDATE_INTERVAL

		Profiler.stop()
	end

	if t > self.next_disabled_slot_count_update then
		Profiler.start("update_disabled_slots_count")
		update_disabled_slots_count(target_units, unit_extension_data)

		self.next_disabled_slot_count_update = t + DISABLED_SLOTS_COUNT_UPDATE_INTERVAL

		Profiler.stop()
	end

	local update_slots_ai_units_prioritized = self.update_slots_ai_units_prioritized
	local update_slots_ai_units_prioritized_n = #update_slots_ai_units_prioritized

	for i = 1, update_slots_ai_units_prioritized_n do
		local ai_unit = update_slots_ai_units_prioritized[i]

		self:update_ai_unit_slot(ai_unit, target_units, unit_extension_data, nav_world, t)

		update_slots_ai_units_prioritized[i] = nil
	end

	local update_slots_ai_units = self.update_slots_ai_units
	local update_slots_ai_units_n = #update_slots_ai_units

	if update_slots_ai_units_n < self.current_ai_index then
		self.current_ai_index = 1
	end

	local start_index = self.current_ai_index
	local end_index = math.min(start_index + AI_UPDATES_PER_FRAME - 1, update_slots_ai_units_n)

	self.current_ai_index = end_index + 1

	for i = start_index, end_index do
		local ai_unit = update_slots_ai_units[i]

		self:update_ai_unit_slot(ai_unit, target_units, unit_extension_data, nav_world, t)
	end

	Profiler.stop()
	Profiler.start("debug_slots")

	if script_data.ai_debug_slots then
		debug_draw_slots(unit_extension_data, nav_world, t)
		debug_print_slots_count(target_units, unit_extension_data)
	end

	Profiler.stop()
end

AISlotSystem.update_ai_unit_slot = function (self, ai_unit, target_units, unit_extension_data, nav_world, t)
	local ai_unit_dead = not unit_alive(ai_unit)

	if ai_unit_dead then
		detach_ai_unit_from_slot(ai_unit, unit_extension_data)

		return
	end

	local ai_unit_extension = unit_extension_data[ai_unit]
	local ai_system_extension = ScriptUnit.extension(ai_unit, "ai_system")
	local blackboard = ai_system_extension:blackboard()
	local target_unit = blackboard.target_unit or blackboard.SVP_target_unit

	update_target(target_unit, ai_unit, blackboard, unit_extension_data, t)

	if not target_unit then
		return
	end

	local target_unit_extension = unit_extension_data[target_unit]

	if not target_unit_extension then
		return
	end

	if not ai_unit_extension.do_search then
		return
	end

	local skip_slots_behind_target = false

	Profiler.start("get_best_slot")
	get_best_slot(target_unit, target_units, ai_unit, unit_extension_data, nav_world, t, skip_slots_behind_target)
	Profiler.stop()

	local slot = ai_unit_extension.slot

	if slot then
		check_to_release_slot(slot)
		Profiler.start("set_ghost_position")

		local slot_behind_target = slot_is_behind_target(slot, ai_unit, target_unit_extension)

		if slot_behind_target then
			set_ghost_position(target_unit_extension, slot, nav_world, self._traverse_logic)
		else
			clear_ghost_position(slot)
		end

		Profiler.stop()
	else
		Profiler.start("get_best_slot_to_wait_on")
		get_best_slot_to_wait_on(target_unit, ai_unit, unit_extension_data, nav_world, skip_slots_behind_target)
		Profiler.stop()
	end

	Profiler.start("improve_slot_position")
	self:improve_slot_position(ai_unit, t)
	Profiler.stop()
end

AISlotSystem.update_target_slots = function (self, t, target_unit, target_units, unit_extension_data, target_unit_extension, nav_world, traverse_logic)
	local dist_sq = 0
	local is_on_ladder, ladder_unit, bottom, top
	local was_on_ladder = target_unit_extension.was_on_ladder
	local status_ext = ScriptUnit.has_extension(target_unit, "status_system")

	if status_ext then
		is_on_ladder, ladder_unit = status_ext:get_is_on_ladder()

		if is_on_ladder then
			local failed_ladder

			bottom, top, failed_ladder = Managers.state.bot_nav_transition:get_ladder_coordinates(ladder_unit)
			is_on_ladder = not failed_ladder
		end

		target_unit_extension.was_on_ladder = is_on_ladder
	end

	local real_target_unit_position = POSITION_LOOKUP[target_unit]
	local target_unit_position = is_on_ladder and real_target_unit_position or get_target_pos_on_navmesh(real_target_unit_position, nav_world)
	local target_unit_position_known = target_unit_extension.position:unbox()
	local outside_navmesh_at_t = target_unit_extension.outside_navmesh_at_t
	local outside_navmesh = false

	if target_unit_position then
		dist_sq = Vector3.distance_squared(target_unit_position, target_unit_position_known)
		target_unit_extension.outside_navmesh_at_t = nil
	elseif outside_navmesh_at_t == nil or t < outside_navmesh_at_t + TARGET_OUTSIDE_NAVMESH_TIMEOUT then
		if outside_navmesh_at_t == nil then
			target_unit_extension.outside_navmesh_at_t = t
		end

		target_unit_position = target_unit_position_known
	else
		outside_navmesh = true
		target_unit_position = POSITION_LOOKUP[target_unit]
		dist_sq = Vector3.distance_squared(target_unit_position, target_unit_position_known)
	end

	if dist_sq > TARGET_MOVED or is_on_ladder ~= was_on_ladder or is_on_ladder and t > target_unit_extension.next_slot_status_update_at then
		local should_offset_slot = true

		target_unit_extension.position:store(target_unit_position)
		update_target_slots_positions(target_unit, target_units, unit_extension_data, should_offset_slot, nav_world, traverse_logic, is_on_ladder, ladder_unit, bottom, top, outside_navmesh)

		target_unit_extension.moved_at = t
		target_unit_extension.next_slot_status_update_at = t + SLOT_STATUS_UPDATE_INTERVAL

		return true
	end

	local moved_at = target_unit_extension.moved_at
	local target_locomotion = ScriptUnit.has_extension(target_unit, "locomotion_system") and ScriptUnit.extension(target_unit, "locomotion_system")
	local target_speed_sq = target_locomotion and Vector3.length_squared(target_locomotion:current_velocity()) or 0

	if not is_on_ladder and moved_at and t - moved_at > TARGET_SLOTS_UPDATE and (target_speed_sq <= TARGET_STOPPED_MOVING_SPEED_SQ or t - moved_at > TARGET_SLOTS_UPDATE_LONG) then
		local should_offset_slot = false

		update_target_slots_positions(target_unit, target_units, unit_extension_data, should_offset_slot, nav_world, traverse_logic, is_on_ladder, ladder_unit, bottom, top, outside_navmesh)

		target_unit_extension.moved_at = nil
		target_unit_extension.next_slot_status_update_at = t + SLOT_STATUS_UPDATE_INTERVAL

		return true
	end

	if t > target_unit_extension.next_slot_status_update_at then
		update_target_slots_status(target_unit, target_units, unit_extension_data, nav_world, traverse_logic, outside_navmesh)

		target_unit_extension.next_slot_status_update_at = t + SLOT_STATUS_UPDATE_INTERVAL

		return true
	end

	return false
end

AISlotSystem.update_total_slots_count = function (self)
	local target_units = self.target_units
	local target_units_n = #target_units
	local target_unit_extensions = self.unit_extension_data
	local slots_n = 0

	for i = 1, target_units_n do
		local target_unit = target_units[i]
		local target_unit_extension = target_unit_extensions[target_unit]
		local target_unit_slots = target_unit_extension.slots_count

		slots_n = slots_n + target_unit_slots
	end

	self.total_slots_count = slots_n
end

AISlotSystem.register_prioritized_ai_unit_update = function (self, unit)
	local update_slots_ai_units_prioritized = self.update_slots_ai_units_prioritized
	local update_slots_ai_units_prioritized_n = #update_slots_ai_units_prioritized

	update_slots_ai_units_prioritized[update_slots_ai_units_prioritized_n + 1] = unit
end

local AGGROABLE_SLOT_COLOR_INDEX = 5
local dummy_input = {}

AISlotSystem.on_add_extension = function (self, world, unit, extension_name, extension_init_data)
	local extension = {}

	ScriptUnit.set_extension(unit, "ai_slot_system", extension, dummy_input)

	self.unit_extension_data[unit] = extension

	if extension_name == "AIAggroableSlotExtension" or extension_name == "AIPlayerSlotExtension" then
		local is_level_unit = extension_name == "AIAggroableSlotExtension"

		if is_level_unit then
			POSITION_LOOKUP[unit] = Unit.world_position(unit, 1)
		end

		local total_slots_count = Unit.get_data(unit, "ai_slots_count") or SLOTS_COUNT
		local target_index = #self.target_units + 1

		extension.total_slots_count = total_slots_count
		extension.slot_radians = math.degrees_to_radians(360 / total_slots_count)
		extension.slots = {}
		extension.dogpile = 0
		extension.slots_count = 0
		extension.position = Vector3Box(POSITION_LOOKUP[unit])
		extension.moved_at = 0
		extension.next_slot_status_update_at = 0
		extension.valid_target = true
		extension.debug_color_name = SLOT_COLORS[AGGROABLE_SLOT_COLOR_INDEX][1]
		extension.disabled_slots_count = 0
		extension.index = target_index
		extension.is_level_unit = is_level_unit

		create_target_slots(unit, extension, AGGROABLE_SLOT_COLOR_INDEX)

		self.target_units[target_index] = unit
	end

	if extension_name == "AIEnemySlotExtension" then
		extension.target = nil
		extension.target_position = Vector3Box()
		extension.improve_wait_slot_position_t = 0
		self.update_slots_ai_units[#self.update_slots_ai_units + 1] = unit
	end

	return extension
end

AISlotSystem.on_remove_extension = function (self, unit, extension_name)
	self:on_freeze_extension(unit, extension_name)
	ScriptUnit.remove_extension(unit, self.NAME)
end

AISlotSystem.on_freeze_extension = function (self, unit, extension_name)
	local extension = self.unit_extension_data[unit]

	if extension == nil then
		return
	end

	local world = self.world
	local update_slots_ai_units = self.update_slots_ai_units
	local update_slots_ai_units_n = #update_slots_ai_units
	local update_slots_ai_units_prioritized = self.update_slots_ai_units_prioritized
	local update_slots_ai_units_prioritized_n = #update_slots_ai_units_prioritized
	local slots = self.slots

	if extension_name == "AIEnemySlotExtension" then
		if extension.slot or extension.waiting_on_slot then
			detach_ai_unit_from_slot(unit, self.unit_extension_data)
		end

		for i = 1, update_slots_ai_units_prioritized_n do
			local ai_unit = update_slots_ai_units_prioritized[i]

			if ai_unit == unit then
				update_slots_ai_units_prioritized[i] = update_slots_ai_units_prioritized[update_slots_ai_units_prioritized_n]
				update_slots_ai_units_prioritized[update_slots_ai_units_prioritized_n] = nil

				break
			end
		end

		for i = 1, update_slots_ai_units_n do
			local ai_unit = update_slots_ai_units[i]

			if ai_unit == unit then
				update_slots_ai_units[i] = update_slots_ai_units[update_slots_ai_units_n]
				update_slots_ai_units[update_slots_ai_units_n] = nil

				break
			end
		end
	end

	if extension_name == "AIPlayerSlotExtension" or extension_name == "AIAggroableSlotExtension" then
		if extension.slots then
			local target_slots = extension.slots
			local target_slots_n = #target_slots

			for i = target_slots_n, 0, -1 do
				local slot = target_slots[i]

				delete_slot(slot, self.unit_extension_data)
			end
		end

		local target_units_n = #self.target_units

		for i = 1, target_units_n do
			if self.target_units[i] == unit then
				self.target_units[i] = self.target_units[target_units_n]
				self.target_units[target_units_n] = nil

				break
			end
		end

		for i = 1, update_slots_ai_units_n do
			local extension = self.unit_extension_data[update_slots_ai_units[i]]

			if extension.target == unit then
				extension.target = nil
			end
		end
	end

	self.unit_extension_data[unit] = nil
end

function debug_draw_slots(unit_extension_data, nav_world, t)
	local drawer = Managers.state.debug:drawer({
		mode = "immediate",
		name = "AISlotSystem_immediate"
	})
	local targets = global_ai_target_units
	local z = Vector3.up() * 0.1

	for i_target, target_unit in pairs(targets) do
		repeat
			if not unit_alive(target_unit) then
				break
			end

			local target_unit_extension = unit_extension_data[target_unit]

			if not target_unit_extension or not target_unit_extension.valid_target then
				break
			end

			local target_slots = target_unit_extension.slots
			local target_slots_n = #target_unit_extension.slots
			local target_position = target_unit_extension.position:unbox()
			local target_color = Colors.get(target_unit_extension.debug_color_name)

			drawer:circle(target_position + z, 0.5, Vector3.up(), target_color)
			drawer:circle(target_position + z, 0.45, Vector3.up(), target_color)

			if target_unit_extension.next_slot_status_update_at then
				local percent = (t - target_unit_extension.next_slot_status_update_at) / SLOT_STATUS_UPDATE_INTERVAL

				drawer:circle(target_position + z, 0.45 * percent, Vector3.up(), target_color)
			end

			for i = 1, target_slots_n do
				repeat
					local slot = target_slots[i]
					local anchor_slot = get_anchor_slot(target_unit, unit_extension_data)
					local is_anchor_slot = slot == anchor_slot
					local ai_unit = slot.ai_unit
					local ai_unit_extension
					local alpha = ai_unit and 255 or 150
					local color = slot.disabled and Colors.get_color_with_alpha("gray", alpha) or Colors.get_color_with_alpha(slot.debug_color_name, alpha)

					if slot.absolute_position then
						local slot_absolute_position = slot.absolute_position:unbox()

						if unit_alive(ai_unit) then
							local ai_unit_position = POSITION_LOOKUP[ai_unit]
							local ai_unit_extension = unit_extension_data[ai_unit]

							drawer:circle(ai_unit_position + z, 0.35, Vector3.up(), color)
							drawer:circle(ai_unit_position + z, 0.3, Vector3.up(), color)

							local head_node = Unit.node(ai_unit, "c_head")
							local viewport_name = "player_1"
							local color_table = slot.disabled and Colors.get_table("gray") or Colors.get_table(slot.debug_color_name)
							local color_vector = Vector3(color_table[2], color_table[3], color_table[4])
							local offset_vector = Vector3(0, 0, -1)
							local text_size = 0.4
							local text = slot.index
							local category = "slot_index"

							if slot.ghost_position.x ~= 0 and not slot.disable_at then
								local ghost_position = slot.ghost_position:unbox()

								drawer:line(ghost_position + z, slot_absolute_position + z, color)
								drawer:sphere(ghost_position + z, 0.3, color)
								drawer:line(ghost_position + z, ai_unit_position + z, color)
							else
								drawer:line(slot_absolute_position + z, ai_unit_position + z, color)
							end
						end

						local text_size = 0.4
						local color_table = slot.disabled and Colors.get_table("gray") or Colors.get_table(slot.debug_color_name)
						local color_vector = Vector3(color_table[2], color_table[3], color_table[4])
						local category = "slot_index_" .. slot.index .. "_" .. i_target

						drawer:circle(slot_absolute_position + z, 0.5, Vector3.up(), color)
						drawer:circle(slot_absolute_position + z, 0.45, Vector3.up(), color)

						local slot_queue_position = get_slot_queue_position(unit_extension_data, slot, nav_world)

						if slot_queue_position then
							drawer:circle(slot_queue_position + z, SLOT_QUEUE_RADIUS, Vector3.up(), color)
							drawer:circle(slot_queue_position + z, SLOT_QUEUE_RADIUS - 0.05, Vector3.up(), color)
							drawer:line(slot_absolute_position + z, slot_queue_position + z, color)

							local queue = slot.queue
							local queue_n = #queue

							for i = 1, queue_n do
								local ai_unit_waiting = queue[i]
								local ai_unit_position = POSITION_LOOKUP[ai_unit_waiting]

								drawer:circle(ai_unit_position + z, 0.35, Vector3.up(), color)
								drawer:circle(ai_unit_position + z, 0.3, Vector3.up(), color)
								drawer:line(slot_queue_position + z, ai_unit_position, color)
							end
						end

						if slot.released then
							local color = Colors.get("green")

							drawer:sphere(slot_absolute_position + z, 0.2, color)
						end

						if is_anchor_slot then
							local color = Colors.get("red")

							drawer:sphere(slot_absolute_position + z, 0.3, color)
						end

						local check_index = slot.position_check_index
						local check_position = slot_absolute_position

						if check_index == SLOT_POSITION_CHECK_INDEX.CHECK_MIDDLE then
							-- Nothing
						elseif check_index == SLOT_POSITION_CHECK_INDEX.CHECK_NEAR then
							local direction = check_position - target_position
							local offset_vector = direction * SLOT_RADIUS * 0.5

							check_position = check_position - offset_vector
						elseif check_index == SLOT_POSITION_CHECK_INDEX.CHECK_FAR then
							local direction = check_position - target_position
							local offset_vector = direction * SLOT_RADIUS * 0.5

							check_position = check_position + offset_vector
						else
							local radians = SLOT_POSITION_CHECK_RADIANS[check_index]

							check_position = rotate_position_from_origin(check_position, target_position, radians, SLOT_RADIUS)
						end

						local ray_from_pos = target_position + Vector3.normalize(check_position - target_position) * RAYCANGO_OFFSET

						drawer:line(ray_from_pos + z, check_position + z, color)
						drawer:circle(check_position + z, 0.1, Vector3.up(), Color(255, 0, 255))
					end
				until true
			end
		until true
	end
end

function debug_print_slots_count(target_units, unit_extension_data)
	local target_slots = target_units
	local target_slots_n = #target_units
	local target_unit_extensions = unit_extension_data

	Debug.text("OCCUPIED SLOTS")

	for unit_i = 1, target_slots_n do
		local target_unit = target_units[unit_i]
		local target_unit_extension = target_unit_extensions[target_unit]
		local player_manager = Managers.player
		local owner_player = player_manager and player_manager:owner(target_unit)
		local display_name

		if owner_player then
			display_name = owner_player:profile_display_name()
		else
			display_name = tostring(target_unit)
		end

		local disabled_slots_count = target_unit_extension.disabled_slots_count
		local occupied_slots = target_unit_extension.slots_count
		local total_slots_count = target_unit_extension.total_slots_count
		local enabled_slots_count = total_slots_count - disabled_slots_count
		local debug_text = string.format("%s: %d|%d(%d)", display_name, occupied_slots, enabled_slots_count, total_slots_count)

		Debug.text(debug_text)
	end
end

AISlotSystem.set_allowed_layer = function (self, layer_name, allowed)
	local layer_id = LAYER_ID_MAPPING[layer_name]

	if allowed then
		GwNavTagLayerCostTable.allow_layer(self._navtag_layer_cost_table, layer_id)
	else
		GwNavTagLayerCostTable.forbid_layer(self._navtag_layer_cost_table, layer_id)
	end
end

SLOT_COLORS = {
	{
		"aqua_marine",
		"cadet_blue",
		"corn_flower_blue",
		"dodger_blue",
		"sky_blue",
		"midnight_blue",
		"medium_purple",
		"blue_violet",
		"dark_slate_blue"
	},
	{
		"dark_green",
		"green",
		"lime",
		"light_green",
		"dark_sea_green",
		"spring_green",
		"sea_green",
		"medium_aqua_marine",
		"light_sea_green"
	},
	{
		"maroon",
		"dark_red",
		"brown",
		"firebrick",
		"crimson",
		"red",
		"tomato",
		"coral",
		"indian_red",
		"light_coral"
	},
	{
		"orange",
		"gold",
		"dark_golden_rod",
		"golden_rod",
		"pale_golden_rod",
		"dark_khaki",
		"khaki",
		"olive",
		"yellow"
	},
	{
		"orange",
		"gold",
		"dark_golden_rod",
		"golden_rod",
		"pale_golden_rod",
		"dark_khaki",
		"khaki",
		"olive",
		"yellow"
	}
}
