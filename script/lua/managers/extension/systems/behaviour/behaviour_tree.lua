-- chunkname: @script/lua/managers/extension/systems/behaviour/behaviour_tree.lua

require("script/lua/managers/extension/systems/behaviour/nodes/bt_selector")
require("script/lua/managers/extension/systems/behaviour/nodes/bt_sequence")
require("script/lua/managers/extension/systems/behaviour/nodes/bt_random")
require("script/lua/managers/extension/systems/behaviour/nodes/bt_conditions")
require("script/lua/managers/extension/systems/behaviour/nodes/bt_dead_action")
require("script/lua/managers/extension/systems/behaviour/nodes/bt_idle_action")
require("script/lua/managers/extension/systems/behaviour/nodes/bt_spawning_action")
require("script/lua/managers/extension/systems/behaviour/nodes/bt_clan_rat_follow_action")
require("script/lua/managers/extension/systems/behaviour/nodes/bt_attack_action")
require("script/lua/managers/extension/systems/behaviour/nodes/bt_combat_shout_action")
require("script/lua/managers/extension/systems/behaviour/nodes/bt_climb_action")
require("script/lua/managers/extension/systems/behaviour/nodes/bt_storm_vermin_attack_action")
require("script/lua/managers/extension/systems/behaviour/nodes/bt_blocked_action")
class("BehaviorTree")

BehaviorTree.types = {}

BehaviorTree.init = function (self, lua_tree_node, name)
	self._root = nil
	self._name = name
	self._action_data = {}

	self:parse_lua_tree(lua_tree_node)
end

BehaviorTree.action_data = function (self)
	return self._action_data
end

BehaviorTree.root = function (self)
	return self._root
end

BehaviorTree.name = function (self)
	return self._name
end

local CLASS_NAME = 1

local function create_btnode_from_lua_node(lua_node, parent_btnode)
	local class_name = lua_node[CLASS_NAME]
	local identifier = lua_node.name
	local condition_name = lua_node.condition or "always_true"
	local hook_name = lua_node.hook
	local action_data = lua_node.action_data
	local class_type = rawget(_G, class_name)

	if not class_type then
		assert(false, "BehaviorTree: no class registered named( %q )", tostring(class_name))
	else
		return class_type:new(identifier, parent_btnode, condition_name, hook_name, lua_node), action_data
	end
end

BehaviorTree.parse_lua_tree = function (self, lua_root_node)
	self._root = create_btnode_from_lua_node(lua_root_node)

	self:parse_lua_node(lua_root_node, self._root)
end

BehaviorTree.parse_lua_node = function (self, lua_node, parent)
	local num_children = #lua_node

	for i = 2, num_children do
		local child = lua_node[i]
		local bt_node, action_data = create_btnode_from_lua_node(child, parent)

		if action_data then
			self._action_data[action_data.name] = action_data
		end

		fassert(bt_node.name, "Behaviour tree node with parent %q is missing name", lua_node.name)

		if parent then
			parent:add_child(bt_node)
		end

		self:parse_lua_node(child, bt_node)
	end

	if parent.ready then
		parent:ready(lua_node)
	end
end
