-- chunkname: @script/lua/managers/extension/systems/behaviour/nodes/bt_dead_action.lua

require("script/lua/managers/extension/systems/behaviour/nodes/bt_node")
class("BTDeadAction", "BTNode")

BTDeadAction.init = function (self, ...)
	BTDeadAction.super.init(self, ...)
end

BTDeadAction.name = "BTDeadAction"

BTDeadAction.enter = function (self, unit, blackboard, t)
	return
end

BTDeadAction.leave = function (self, unit, blackboard, t)
	return
end

BTDeadAction.run = function (self, unit, blackboard, t, dt)
	return "done"
end
