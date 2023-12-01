-- chunkname: @script/lua/managers/transition/transition_manager.lua

class("TransitionManager")

TransitionManager.init = function (self)
	self._color = Vector3Box(0, 0, 0)
	self._fade_state = "out"
	self._fade = 0
	self._gui = nil

	self:set_world(GLOBAL_WORLD)
end

TransitionManager.set_world = function (self, world)
	if self._gui then
		print("TransitionManager -> World.destroy_gui")
		World.destroy_gui(self._world, self._gui)
	end

	if world then
		self._gui = World.create_screen_gui(world, "immediate")
		self._world = world
	else
		self._gui = nil
		self._world = nil
	end
end

TransitionManager.reinitialize = function (self)
	self._gui = nil

	self:set_world(GLOBAL_WORLD)
end

TransitionManager.destroy = function (self)
	if self._gui and self._world then
		World.destroy_gui(self._world, self._gui)

		self._gui = nil
	end
end

TransitionManager.fade_in = function (self, speed, callback)
	self._fade_state = "fade_in"
	self._fade_speed = speed
	self._callback = callback

	if script_data.debug_transition_manager then
		print("[TransitionManager:fade_in]", Script.callstack())
	end
end

TransitionManager.fade_out = function (self, speed, callback)
	self._fade_state = "fade_out"
	self._fade_speed = -speed
	self._callback = callback

	if script_data.debug_transition_manager then
		print("[TransitionManager:fade_out]", Script.callstack())
	end
end

TransitionManager.force_fade_in = function (self)
	self._fade_state = "in"
	self._fade_speed = 0
	self._fade = 1

	if self._callback then
		self._callback()

		self._callback = nil
	end
end

TransitionManager.force_fade_out = function (self)
	self._fade_state = "out"
	self._fade_speed = 0
	self._fade = 0

	if self._callback then
		self._callback()

		self._callback = nil
	end
end

TransitionManager._render = function (self, dt)
	local color = self._color:unbox()

	Gui.rect(self._gui, Vector3(0, 0, 100), Vector2(3000, 1500), Color(self._fade * 255, color.x, color.y, color.z))
end

TransitionManager.update = function (self, dt)
	Profiler.start("TransitionManager:update()")

	local state = self._fade_state

	if state == "fade_in" or state == "fade_out" then
		self._fade = self._fade + self._fade_speed * dt

		if state == "fade_in" and self._fade >= 1 then
			self._fade = 1
			self._fade_state = "in"

			if self._callback then
				local callback = self._callback

				self._callback = nil

				callback()
			end
		elseif state == "fade_out" and self._fade <= 0 then
			self._fade = 0
			self._fade_state = "out"

			if self._callback then
				local callback = self._callback

				self._callback = nil

				callback()
			end
		end
	end

	if self._fade_state ~= "out" and self._gui then
		self:_render(dt)
	end

	Profiler.stop("TransitionManager:update()")
end
