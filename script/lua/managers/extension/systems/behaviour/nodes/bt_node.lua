﻿-- chunkname: @script/lua/managers/extension/systems/behaviour/nodes/bt_node.lua

require("script/lua/managers/extension/systems/behaviour/nodes/bt_conditions")

local CONDITIONS = BTConditions

class("BTNode")

BTNode.init = function (self, identifier, parent, condition_name, hook_name, tree_node)
	self._parent = parent
	self._identifier = identifier
	self._tree_node = tree_node

	local condition = CONDITIONS[condition_name]

	assert(condition, "No condition called %q", condition_name)

	self._condition_name = condition_name
end

BTNode.condition = function (self, blackboard)
	return CONDITIONS[self._condition_name](blackboard, self._tree_node.condition_args)
end

BTNode.id = function (self)
	return self._identifier
end

BTNode.evaluate = function (self, unit, blackboard, t, dt)
	if not self:condition(blackboard) then
		return "failed"
	end

	return self:run(unit, blackboard, t, dt)
end

BTNode.enter = function (self, unit, ai_data, t, dt)
	return
end

BTNode.leave = function (self, unit, ai_data, t, dt)
	return
end

BTNode.parent = function (self)
	return self._parent
end

BTNode.run = function (self, unit, ai_data, t, dt)
	error(false, "Implement in inherited class: " .. self:name())
end

BTNode.set_running_child = function (self, unit, blackboard, t, node, reason)
	Profiler.start("set_running_child")

	local old_node = blackboard.running_nodes[self._identifier]

	if old_node == node then
		Profiler.stop("set_running_child")

		return
	end

	blackboard.running_nodes[self._identifier] = node

	if old_node then
		old_node:set_running_child(unit, blackboard, t, nil, reason)
		old_node:leave(unit, blackboard, t, reason)
	elseif self._parent ~= nil and node ~= nil then
		self._parent:set_running_child(unit, blackboard, t, self, "aborted")
	end

	if node then
		node:enter(unit, blackboard, t)
	end

	Profiler.stop("set_running_child")
end

BTNode.current_running_child = function (self, blackboard)
	local node = blackboard.running_nodes[self._identifier]

	return node
end
