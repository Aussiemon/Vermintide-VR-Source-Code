-- chunkname: @foundation/script/util/state_machine.lua

local profiler_names = {}

local function profiler_scope(state_name, scope_type)
	assert(state_name, "State without name not allowed.")

	local scope = profiler_names[state_name]

	if scope == nil then
		scope = {
			create = state_name .. ":new",
			enter = state_name .. ":on_enter",
			exit = state_name .. ":on_exit"
		}
		profiler_names[state_name] = scope
	end

	local scope_name = scope[scope_type]

	assert(scope_name)

	return scope_name
end

class("StateMachine")

StateMachine.DEBUG = true

local function debug_print(format, ...)
	if script_data.network_debug or StateMachine.DEBUG then
		printf("[StateMachine] " .. format, ...)
	end
end

StateMachine.init = function (self, parent, start_state, params, profiling_debugging_enabled)
	self._parent = parent
	self._profiling_debugging_enabled = profiling_debugging_enabled

	debug_print("Init %-30s", start_state.__class_name)
	self:_change_state(start_state, params)
end

StateMachine._change_state = function (self, new_state, params)
	if self._state then
		if self._state.on_exit and self._profiling_debugging_enabled then
			debug_print("Exiting  %-30s with on_exit()", self._state.__class_name)

			local scope_name = profiler_scope(self._state.__class_name, "exit")

			Profiler.start(scope_name)
			self._state:on_exit(params)
			Profiler.stop(scope_name)
		elseif self._state.on_exit then
			debug_print("Exiting  %-30s", self._state.__class_name)
			self._state:on_exit(params)
		else
			debug_print("Exiting  %-30s", self._state.__class_name)
		end
	end

	if self._profiling_debugging_enabled then
		local scope_name = profiler_scope(new_state.__class_name, "create")

		Profiler.start(scope_name)

		self._state = new_state:new()

		Profiler.stop(scope_name)
	else
		self._state = new_state:new()
	end

	self._state.parent = self._parent

	if self._state.on_enter and self._profiling_debugging_enabled then
		debug_print("Entering %-30s with on_enter()", new_state.__class_name)

		local scope_name = profiler_scope(self._state.__class_name, "enter")

		Profiler.start(scope_name)
		self._state:on_enter(params)
		Profiler.stop(scope_name)
	elseif self._state.on_enter then
		debug_print("Entering %-30s", new_state.__class_name)
		self._state:on_enter(params)
	else
		debug_print("Entering %-30s", new_state.__class_name)
	end
end

StateMachine.pre_update = function (self, dt, t)
	if self._state and self._state.pre_update then
		self._state:pre_update(dt, t)
	end
end

StateMachine.update = function (self, dt, t)
	local new_state, exit_params = self._state:update(dt, t)

	if new_state then
		self:_change_state(new_state, exit_params)
	end
end

StateMachine.state = function (self)
	return self._state
end

StateMachine.post_update = function (self, dt, t)
	if self._state and self._state.post_update then
		self._state:post_update(dt, t)
	end
end

StateMachine.render = function (self)
	if self._state and self._state.render then
		self._state:render()
	end
end

StateMachine.destroy = function (self, ...)
	debug_print("destroying")

	if self._state and self._state.on_exit then
		debug_print("Exiting %-30s with on_exit()", self._state.__class_name)
		self._state:on_exit(...)
	end
end
