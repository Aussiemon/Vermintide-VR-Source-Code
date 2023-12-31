﻿-- chunkname: @script/lua/unit_extensions/ai/ai_brain.lua

require("script/lua/managers/extension/systems/behaviour/behaviour_tree")
require("script/lua/managers/extension/systems/behaviour/bt_minion")
class("AIBrain")

local script_data = script_data

AIBrain.init = function (self, world, unit, blackboard, breed, behavior)
	self._unit = unit

	Unit.set_data(unit, "blackboard", blackboard)

	blackboard.remembered_threat_pos = Vector3Box()
	self._blackboard = blackboard
	blackboard.attacks_done = 0
	blackboard.breed = breed
	blackboard.destination_dist = 0
	blackboard.nav_target_dist_sq = 0

	self:load_brain(behavior)
end

AIBrain.destroy = function (self)
	self:exit_last_action()
end

AIBrain.init_utility_actions = function (self, blackboard, breed)
	local utility_actions = {}
	local actions = self._bt:action_data()

	for action_name, data in pairs(actions) do
		utility_actions[action_name] = {
			last_time = 0,
			time_since_last = math.huge
		}

		if data.init_blackboard then
			for name, value in pairs(data.init_blackboard) do
				blackboard[name] = value
			end
		end
	end

	blackboard.utility_actions = utility_actions
end

AIBrain.load_brain = function (self, tree_name)
	self._current_action = nil

	local ai_system = Managers.state.extension:system("ai_system")

	self._bt = ai_system:behavior_tree(tree_name)

	fassert(self._bt, "Cannot find behavior tree '%s' specified for unit '%s'", tree_name, self._unit)
end

AIBrain.bt = function (self)
	return self._bt
end

AIBrain.exit_last_action = function (self)
	local blackboard = self._blackboard

	blackboard.exit_last_action = true

	local root = self._bt:root()
	local t = 0

	root:set_running_child(self._unit, blackboard, t, nil, "aborted")
end

AIBrain.update = function (self, unit, t, dt)
	Profiler.start("unknown_node")

	local result = self._bt:root():evaluate(unit, self._blackboard, t, dt)

	Profiler.stop("unknown_node")
end

AIBrain.update = function (self, unit, t, dt)
	local blackboard = self._blackboard
	local leaf_node = self._bt:root()

	while leaf_node and leaf_node:current_running_child(blackboard) do
		leaf_node = leaf_node:current_running_child(blackboard)
	end

	Profiler.start(leaf_node and leaf_node:id() or "unknown_node")

	local result = self._bt:root():evaluate(unit, blackboard, t, dt)

	Profiler.stop()
end

AIBrain.debug_draw_behaviours = function (self)
	self._bt_strings = self._bt_strings or {}

	local index = 1
	local unit = self._unit
	local blackboard = self._blackboard

	if Unit.alive(unit) and self._current_action then
		local tree_name = self._bt:id()

		if tree_name ~= "nil_tree" then
			local blackboard = self._blackboard
			local node_name = self._current_action:id()
			local color = Managers.state.debug:color(unit)
			local x, y, z, w = Quaternion.to_elements(color)
			local color_vector = Vector3(y, z, w)
			local moving = blackboard.move_state or "?"
			local locomotion = ScriptUnit.extension(unit, "locomotion_system")
			local go_id = Managers.state.unit_storage:go_id(unit)
			local target = blackboard.target_unit and " (X) " or " (-)"
			local bt_string = "(" .. go_id .. ") " .. tree_name .. "->" .. node_name .. target .. " " .. moving
			local offset = Vector3.up() * (2.1 + index * 0.1)

			if not self._bt_strings[tree_name] then
				Managers.state.debug_text:clear_unit_text(unit, nil)
				Managers.state.debug_text:output_unit_text(bt_string, 0.1, unit, 0, offset, nil, "behavior_tree", color_vector, nil, index)

				index = index + 1
			elseif bt_string ~= self._bt_strings[tree_name] then
				Managers.state.debug_text:clear_unit_text(unit, nil)
				Managers.state.debug_text:output_unit_text(bt_string, 0.1, unit, 0, offset, nil, "behavior_tree", color_vector, nil, index)
			end

			self._bt_strings[tree_name] = self._bt_strings[tree_name] or " "

			if bt_string ~= self._bt_strings[tree_name] then
				-- Nothing
			end

			self._bt_strings[tree_name] = bt_string

			if blackboard.target_unit then
				QuickDrawer:sphere(Unit.local_position(blackboard.target_unit, 0), 0.5, Color(255, 100, 0))
			end
		end
	end
end

AIBrain.debug_draw_current_behavior = function (self)
	local unit = self._unit
	local node = self._bt:root()
	local bb = self._blackboard
	local child = node:current_running_child(bb)

	while child do
		node = child
		child = node:current_running_child(bb)
	end

	local string = node._identifier
	local offset = Vector3(0, 0, 4)
	local color = Vector3(255, 255, 255)

	Managers.state.debug_text:clear_unit_text(unit, nil)
	Managers.state.debug_text:output_unit_text(string, 0.25, unit, 0, offset, nil, "bt_debug", color, nil, 1)
end
