-- chunkname: @script/lua/managers/debug/debug_manager.lua

require("script/lua/managers/debug/debug_drawer")
require("script/lua/managers/debug/debug")
class("DebugManager")

QuickDrawer = QuickDrawer or true
QuickDrawerStay = QuickDrawerStay or true

DebugManager.init = function (self, world, level)
	self._world = world
	self._level = level
	self._drawers = {}
	self._actor_draw = {}
	QuickDrawer = self:drawer({
		name = "quick_debug",
		mode = "immediate"
	})
	QuickDrawerStay = self:drawer({
		name = "quick_debug_stay",
		mode = "retained"
	})

	Debug.setup(world)
end

DebugManager.drawer = function (self, options)
	options = options or {}

	local drawer_name = options.name
	local drawer

	if drawer_name == nil then
		local line_object = World.create_line_object(self._world)

		drawer = DebugDrawer:new(line_object, options.mode)
		self._drawers[#self._drawers + 1] = drawer
	elseif self._drawers[drawer_name] == nil then
		local line_object = World.create_line_object(self._world)

		drawer = DebugDrawer:new(line_object, options.mode)
		self._drawers[drawer_name] = drawer
	else
		drawer = self._drawers[drawer_name]
	end

	return drawer
end

DebugManager.reset_drawer = function (self, drawer_name)
	if self._drawers[drawer_name] then
		self._drawers[drawer_name]:reset()
	end
end

DebugManager.update = function (self, dt, t)
	Profiler.start("DebugManager:update()")
	self:_update_actor_draw(dt)

	for drawer_name, drawer in pairs(self._drawers) do
		Profiler.start(drawer_name)
		drawer:update(self._world)
		Profiler.stop()
	end

	if self._level and script_data.auto_kill_start_skaven and t > 2 and not self._start_skaven_killed then
		Level.trigger_event(self._level, "debug_kill_start_skaven")

		self._start_skaven_killed = true
	end

	Debug.update(dt, t)
	Profiler.stop("DebugManager:update()")
end

DebugManager._update_actor_draw = function (self, dt)
	local world = self._world
	local physics_world = World.get_data(world, "physics_world")
	local pose = World.debug_camera_pose(world)

	for _, data in pairs(self._actor_draw) do
		PhysicsWorld.overlap(physics_world, function (...)
			self:_actor_draw_overlap_callback(data, ...)
		end, "shape", "sphere", "size", data.range, "pose", pose, "types", "both", "collision_filter", data.collision_filter)

		if data.actors then
			local drawer = self._actor_drawer

			for _, actor in ipairs(data.actors) do
				drawer:actor(actor, data.color:unbox(), pose)
			end
		end
	end
end

DebugManager._actor_draw_overlap_callback = function (self, data, actors)
	data.actors = actors
end

DebugManager.enable_actor_draw = function (self, collision_filter, color, range)
	local world = self._world
	local physics_world = World.physics_world(world)

	PhysicsWorld.immediate_overlap(physics_world, "shape", "sphere", "size", 0.1, "position", Vector3(0, 0, 0), "types", "both", "collision_filter", collision_filter)

	self._actor_drawer = self:drawer({
		mode = "immediate",
		name = "_actor_drawer"
	})
	self._actor_draw[collision_filter] = {
		color = QuaternionBox(color),
		range = range,
		collision_filter = collision_filter
	}
end

DebugManager.disable_actor_draw = function (self, collision_filter)
	self._actor_draw[collision_filter] = nil
end

DebugManager.color = function (self, unit, alpha)
	fassert(Unit.alive(unit), "Trying to get color from a destroyed unit")

	local alpha = alpha or 255

	self._unit_color_list = self._unit_color_list or {}

	if not self._unit_color_list[unit] then
		self._unit_color_list[unit] = self:_get_next_color_index()
	end

	local color_index = self._unit_color_list[unit]
	local color_table = GameSettingsDevelopment.debug_unit_colors[color_index]
	local color = Color(alpha, color_table[1], color_table[2], color_table[3])

	return color, color_index
end

DebugManager._get_next_color_index = function (self)
	for unit, color_index in pairs(self._unit_color_list) do
		if not Unit.alive(unit) then
			self._unit_color_list[unit] = nil
		end
	end

	for index, color in pairs(GameSettingsDevelopment.debug_unit_colors) do
		if not self:_color_index_in_use(index) then
			return index
		end
	end

	return 1
end

DebugManager._color_index_in_use = function (self, index)
	for unit, color_index in pairs(self._unit_color_list) do
		if index == color_index then
			return true
		end
	end

	return false
end

DebugManager._create_screen_gui = function (self)
	self._screen_gui = World.create_screen_gui(self._world, "material", "materials/fonts/arial", "material", "materials/fonts/hell_shark_font", "material", "materials/fonts/gw_fonts", "immediate")
end

DebugManager.draw_screen_rect = function (self, x, y, z, w, h, color)
	if not self._screen_gui then
		self:_create_screen_gui()
	end

	Gui.rect(self._screen_gui, Vector3(x, y, z or 1), Vector2(w, h), color or Color(255, 255, 255, 255))
end

DebugManager.draw_screen_text = function (self, x, y, z, text, size, color, font)
	if not self._screen_gui then
		self:_create_screen_gui()
	end

	local font_type = font or "hell_shark"
	local font_by_resolution = UIFontByResolution({
		dynamic_font = true,
		font_type = font_type,
		font_size = size
	})
	local font, size, material = unpack(font_by_resolution)

	Gui.text(self._screen_gui, text, font, size, material, Vector3(x, y, z), color or Color(255, 255, 255, 255))
end

DebugManager.screen_text_extents = function (self, text, size)
	if not self._screen_gui then
		self:_create_screen_gui()
	end

	local min, max = Gui.text_extents(self._screen_gui, text, GameSettings.ingame_font.font, size)
	local width = max[1] - min[1]
	local height = max[3] - min[3]

	return width, height
end

DebugManager.destroy = function (self)
	if self._screen_gui then
		print("DebugManager -> World.destroy_gui")
		World.destroy_gui(self._world, self._screen_gui)

		self._screen_gui = nil
	end

	Debug.teardown()
end
