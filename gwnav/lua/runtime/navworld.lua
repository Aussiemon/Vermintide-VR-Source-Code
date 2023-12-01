-- chunkname: @gwnav/lua/runtime/navworld.lua

require("gwnav/lua/safe_require")

local NavWorld = safe_require_guard()
local NavClass = safe_require("gwnav/lua/runtime/navclass")

NavWorld = NavClass(NavWorld)

local NavHelpers = safe_require("gwnav/lua/runtime/navhelpers")
local NavBot = safe_require("gwnav/lua/runtime/navbot")
local NavBoxObstacle = safe_require("gwnav/lua/runtime/navboxobstacle")
local NavCylinderObstacle = safe_require("gwnav/lua/runtime/navcylinderobstacle")
local NavGraph = safe_require("gwnav/lua/runtime/navgraph")
local NavTagVolume = safe_require("gwnav/lua/runtime/navtagvolume")
local NavBotConfiguration = safe_require("gwnav/lua/runtime/navbotconfiguration")
local Math = stingray.Math
local Vector2 = stingray.Vector2
local Vector3 = stingray.Vector3
local Vector3Box = stingray.Vector3Box
local Matrix4x4 = stingray.Matrix4x4
local Matrix4x4Box = stingray.Matrix4x4Box
local Quaternion = stingray.Quaternion
local QuaternionBox = stingray.QuaternionBox
local Gui = stingray.Gui
local World = stingray.World
local Unit = stingray.Unit
local Camera = stingray.Camera
local Color = stingray.Color
local LineObject = stingray.LineObject
local Level = stingray.Level
local Script = stingray.Script
local GwNavWorld = stingray.GwNavWorld
local GwNavBot = stingray.GwNavBot
local GwNavQueries = stingray.GwNavQueries
local GwNavAStar = stingray.GwNavAStar
local GwNavTagVolume = stingray.GwNavTagVolume
local GwNavBoxObstacle = stingray.GwNavBoxObstacle
local GwNavCylinderObstacle = stingray.GwNavCylinderObstacle
local GwNavGraph = stingray.GwNavGraph
local GwNavTraversal = stingray.GwNavTraversal
local _navworlds = {}

NavWorld.get_navworld = function (level)
	return _navworlds[level]
end

NavWorld.get_graph_connector_sub_graph_smartobject_id = function (subgraph_idx, original_smartobject_id)
	local shifted = NavHelpers.bit_left_shift(original_smartobject_id, 8)

	return NavHelpers.bit_or(shifted, subgraph_idx)
end

NavWorld.get_graph_connector_sub_graph_original_smartobject_id = function (smartobject_id)
	return NavHelpers.bit_right_shift(original_smartobject_id, 8)
end

NavWorld.init = function (self, world, level, database_count)
	database_count = database_count or 1
	self.world = world
	self.level = level
	self.transform = Matrix4x4Box(Level.pose(level))
	self.bot_configurations = {}
	self.bots = {}
	self.navgraphs = {}
	self.navtagvolumes = {}
	self.navboxobstacles = {}
	self.navcylinderobstacles = {}
	self.smartobject_types = {}
	self.markers = {}
	self.gwnavworld = GwNavWorld.create(self.transform:unbox(), database_count)
	self.render_mesh = false

	local visualdebug_server_port = 4888
	local bot_units = {}
	local navworld_unit

	for ku, unit in pairs(Level.units(level)) do
		if Unit.alive(unit) and Unit.has_data(unit, "GwNavWorld") then
			navworld_unit = unit

			self:init_fromnavworldunit(unit)
			GwNavWorld.init_visual_debug_server(self.gwnavworld, visualdebug_server_port)

			break
		end
	end

	for ku, unit in pairs(Level.units(level)) do
		if Unit.alive(unit) and Unit.has_data(unit, "GwNavWorld") and unit ~= navworld_unit then
			error("More than one GwNavWorld in level " .. tostring(self.level))
		elseif Unit.alive(unit) and Unit.has_data(unit, "GwNavBotConfiguration") then
			self:init_bot_configuration(unit)
		elseif Unit.alive(unit) and Unit.has_data(unit, "GwNavGraphConnector") then
			self:init_graph_connector(unit)
		elseif Unit.alive(unit) and Unit.has_data(unit, "GwNavTagBox") then
			self:init_tagbox(unit)
		elseif Unit.alive(unit) and Unit.has_data(unit, "GwNavBoxObstacle") then
			self:add_boxobstacle(unit)
		elseif Unit.alive(unit) and Unit.has_data(unit, "GwNavCylinderObstacle") then
			self:add_cylinderobstacle(unit)
		elseif Unit.alive(unit) and Unit.has_data(unit, "GwNavMarker") then
			self:init_navmarker(unit)
		elseif Unit.alive(unit) and Unit.has_data(unit, "GwNavBot") then
			bot_units[#bot_units + 1] = unit
		end
	end

	for ku, unit in pairs(bot_units) do
		self:init_bot(unit)
	end

	_navworlds[level] = self
end

NavWorld.add_navdata = function (self, resource_name)
	self.navdata = GwNavWorld.add_navdata(self.gwnavworld, resource_name)
end

NavWorld.init_bot = function (self, unit)
	local configuration_name = Unit.get_data(unit, "GwNavBot", "configuration_name")
	local bot_configuration = self.bot_configurations[configuration_name]

	if bot_configuration then
		return NavBot(self, unit, bot_configuration)
	end

	return nil
end

NavWorld.init_bot_from_unit = function (self, unit, configuration_unit)
	local configuration_name = Unit.get_data(configuration_unit, "GwNavBotConfiguration", "configuration_name")
	local bot_configuration = self.bot_configurations[configuration_name]

	if bot_configuration then
		return NavBot(self, unit, bot_configuration)
	end

	return nil
end

NavWorld.get_navbot = function (self, unit)
	return self.bots[unit]
end

NavWorld.init_navmarker = function (self, unit)
	self.markers[#self.markers + 1] = unit
end

NavWorld.set_smartobject_cost_multiplier = function (self, smartobject_id, cost_multiplier, smartobject_type)
	self.smartobject_types[smartobject_id] = smartobject_type

	GwNavWorld.set_smartobject_cost_multiplier(self.gwnavworld, smartobject_id, cost_multiplier)
end

NavWorld.unset_smartobject = function (self, smartobject_id)
	GwNavWorld.unset_smartobject(self.gwnavworld, smartobject_id)
end

NavWorld.allow_smartobject = function (self, smartobject_id)
	GwNavWorld.allow_smartobject(self.gwnavworld, smartobject_id)
end

NavWorld.forbid_smartobject = function (self, smartobject_id)
	GwNavWorld.forbid_smartobject(self.gwnavworld, smartobject_id)
end

NavWorld.get_smartobject_type = function (self, smartobject_id)
	return self.smartobject_types[smartobject_id]
end

NavWorld.set_dynamicnavmesh_budget = function (self, budget)
	GwNavWorld.set_dynamicnavmesh_budget(self.gwnavworld, budget)
end

NavWorld.set_pathfinder_budget = function (self, budget)
	GwNavWorld.set_pathfinder_budget(self.gwnavworld, budget)
end

NavWorld.init_fromnavworldunit = function (self, unit)
	if Unit.has_data(unit, "GwNavWorld", "dynamicnavmesh_budget") then
		self:set_dynamicnavmesh_budget(Unit.get_data(unit, "GwNavWorld", "dynamicnavmesh_budget"))
	end

	if Unit.has_data(unit, "GwNavWorld", "pathfinder_budget") then
		self:set_pathfinder_budget(Unit.get_data(unit, "GwNavWorld", "pathfinder_budget"))
	end

	if Unit.has_data(unit, "GwNavWorld", "render_navdata") then
		self.render_mesh = Unit.get_data(unit, "GwNavWorld", "render_navdata")
	end

	if Unit.has_data(unit, "GwNavWorld", "enable_crowd_dispersion") and Unit.get_data(unit, "GwNavWorld", "enable_crowd_dispersion") == true then
		GwNavWorld.enable_crowd_dispersion(self.gwnavworld)
	end
end

NavWorld.init_bot_configuration = function (self, unit)
	local configuration_name = Unit.get_data(unit, "GwNavBotConfiguration", "configuration_name")

	self.bot_configurations[configuration_name] = NavBotConfiguration(unit)
end

NavWorld.init_graph_connector = function (self, unit)
	local sampling_step = math.max(1, NavHelpers.unit_script_data(unit, 1, "GwNavGraphConnector", "sampling_step"))
	local unitPos = Matrix4x4.transform(self.transform:unbox(), Unit.world_position(unit, 1))
	local unitRot = Unit.world_rotation(unit, 1)
	local unitScale = Unit.local_scale(unit, 1)
	local forward = Quaternion.forward(unitRot)
	local right = Quaternion.right(unitRot)
	local up = Quaternion.up(unitRot)
	local down_up = NavHelpers.unit_script_data(unit, true, "GwNavGraphConnector", "down_up")
	local up_down = NavHelpers.unit_script_data(unit, true, "GwNavGraphConnector", "up_down")
	local bidirectional_edges = down_up and up_down
	local half_subdivision_count = math.floor(0.5 * unitScale[1] / sampling_step)
	local current_vertex_left_offset = half_subdivision_count * sampling_step
	local sub_graph_count = half_subdivision_count * 2 + 1
	local enable_crowd_dispersion = false
	local crowd_dispersion_slot_capacity, crowd_dispersion_slot_duration

	if GwNavWorld.is_crowd_dispersion_enabled(self.gwnavworld) then
		enable_crowd_dispersion = NavHelpers.unit_script_data(unit, false, "GwNavGraphConnector", "enable_crowd_dispersion")

		if enable_crowd_dispersion == true then
			if Unit.has_data(unit, "GwNavGraphConnector", "crowd_dispersion_max_bot_per_time_interval") then
				crowd_dispersion_slot_capacity = NavHelpers.unit_script_data(unit, 1, "GwNavGraphConnector", "crowd_dispersion_max_bot_per_time_interval")

				print_warning("script data `GwNavGraphConnector.crowd_dispersion_max_bot_per_time_interval is deprecated`. Please use `GwNavGraphConnector.crowd_dispersion_slot_capacity`")
			end

			if Unit.has_data(unit, "GwNavGraphConnector", "crowd_dispersion_time_interval_in_seconds") then
				crowd_dispersion_slot_duration = NavHelpers.unit_script_data(unit, 2, "GwNavGraphConnector", "crowd_dispersion_time_interval_in_seconds")

				print_warning("script data `GwNavGraphConnector.crowd_dispersion_time_interval_in_seconds is deprecated`. Please use `GwNavGraphConnector.crowd_dispersion_slot_duration`")
			end

			crowd_dispersion_slot_capacity = NavHelpers.unit_script_data(unit, 1, "GwNavGraphConnector", "crowd_dispersion_slot_capacity")
			crowd_dispersion_slot_duration = NavHelpers.unit_script_data(unit, 2, "GwNavGraphConnector", "crowd_dispersion_slot_duration")
		end
	end

	local smartobject_type = NavHelpers.unit_script_data(unit, "Jump", "GwNavGraphConnector", "smartobject_type")
	local is_exclusive, color, layer_id, smartobject_id, user_data_id = NavHelpers.get_layer_and_smartobject(unit, "GwNavGraphConnector")

	if is_exclusive then
		error("NavGraph should not have exclusive navtag it will be ignored")
	elseif smartobject_id == -1 then
		print_warning("NavGraph should be associated to a smartobject id, it will be defaulted to 0")

		smartobject_id = 0
	end

	local database_ids = NavHelpers.unit_script_data(unit, {
		0
	}, "GwNavGraphConnector", "database_ids")
	local temp_a = unitPos
	local temp_b = unitPos + forward * unitScale[2] + up * unitScale[3]

	for i = 1, sub_graph_count do
		local graph_smartobject_id = smartobject_id

		if enable_crowd_dispersion == true then
			graph_smartobject_id = NavWorld.get_graph_connector_sub_graph_smartobject_id(i, smartobject_id)
		end

		self:set_smartobject_cost_multiplier(graph_smartobject_id, 1, smartobject_type)

		local control_points = {}
		local start_idx = 1
		local down_idx = 2

		if bidirectional_edges == false and up_down == true then
			start_idx = 2
			down_idx = 1
		end

		control_points[start_idx] = temp_a - right * current_vertex_left_offset
		control_points[down_idx] = temp_b - right * current_vertex_left_offset

		for _, db_id in ipairs(database_ids) do
			local gwnavdatabase = GwNavWorld.database(self.gwnavworld, db_id)
			local navgraph = NavGraph(gwnavdatabase, bidirectional_edges, control_points, color, layer_id, graph_smartobject_id, user_data_id)

			navgraph:add_to_database()

			self.navgraphs[#self.navgraphs + 1] = navgraph

			if enable_crowd_dispersion == true then
				GwNavWorld.register_all_navgraphedges_for_crowd_dispersion(self.gwnavworld, navgraph.nav_navgraph, crowd_dispersion_slot_capacity, crowd_dispersion_slot_duration)
			end
		end

		current_vertex_left_offset = current_vertex_left_offset - sampling_step
	end
end

NavWorld.init_tagbox = function (self, unit)
	local half_extent_x = NavHelpers.unit_script_data(unit, 1, "GwNavTagBox", "half_extent", "x")
	local half_extent_y = NavHelpers.unit_script_data(unit, 1, "GwNavTagBox", "half_extent", "y")
	local half_extent_z = NavHelpers.unit_script_data(unit, 1, "GwNavTagBox", "half_extent", "z")
	local local_center = Vector3(NavHelpers.unit_script_data(unit, 0, "GwNavTagBox", "offset", "x"), NavHelpers.unit_script_data(unit, 0, "GwNavTagBox", "offset", "y"), NavHelpers.unit_script_data(unit, 0, "GwNavTagBox", "offset", "z"))
	local is_exclusive, color, layer_id, smartobject_id = NavHelpers.get_layer_and_smartobject(unit, "GwNavTagBox")
	local unitPos = Unit.world_position(unit, 1) + local_center
	local unitRot = Unit.world_rotation(unit, 1)
	local forward = Quaternion.forward(unitRot)
	local right = Quaternion.right(unitRot)
	local up = Quaternion.up(unitRot)
	local point_table = {
		unitPos + forward * half_extent_x - right * half_extent_y,
		unitPos + forward * half_extent_x + right * half_extent_y,
		unitPos - forward * half_extent_x + right * half_extent_y,
		unitPos - forward * half_extent_x - right * half_extent_y
	}
	local alt_min = unitPos[3] - half_extent_z
	local alt_max = unitPos[3] + half_extent_z
	local tag_volume = NavTagVolume(self.gwnavworld, point_table, alt_min, alt_max, is_exclusive, color, layer_id, smartobject_id)

	self.navtagvolumes[#self.navtagvolumes + 1] = tag_volume

	self.navtagvolumes[#self.navtagvolumes]:add_to_world()

	if GwNavWorld.is_crowd_dispersion_enabled(self.gwnavworld) then
		local enable_crowd_dispersion = NavHelpers.unit_script_data(unit, false, "GwNavTagBox", "enable_crowd_dispersion")

		if enable_crowd_dispersion == true then
			local crowd_dispersion_length_to_consider = NavHelpers.unit_script_data(unit, 2 * min(half_extent_x, half_extent_y), "GwNavTagBox", "crowd_dispersion_length_to_consider")

			if Unit.has_data(unit, "GwNavTagBox", "crowd_dispersion_max_bot_per_time_interval") then
				crowd_dispersion_slot_capacity = NavHelpers.unit_script_data(unit, 1, "GwNavTagBox", "crowd_dispersion_max_bot_per_time_interval")

				print_warning("script data `GwNavTagBox.crowd_dispersion_max_bot_per_time_interval is deprecated`. Please use `GwNavTagBox.crowd_dispersion_slot_capacity`")
			end

			if Unit.has_data(unit, "GwNavTagBox", "crowd_dispersion_time_interval_in_seconds") then
				crowd_dispersion_slot_duration = NavHelpers.unit_script_data(unit, 2, "GwNavTagBox", "crowd_dispersion_time_interval_in_seconds")

				print_warning("script data `GwNavTagBox.crowd_dispersion_time_interval_in_seconds is deprecated`. Please use `GwNavTagBox.crowd_dispersion_slot_duration`")
			end

			local crowd_dispersion_slot_capacity = NavHelpers.unit_script_data(unit, 1, "GwNavTagBox", "crowd_dispersion_slot_capacity")
			local crowd_dispersion_slot_duration = NavHelpers.unit_script_data(unit, 2, "GwNavTagBox", "crowd_dispersion_slot_duration")

			GwNavWorld.register_tagvolume_for_crowd_dispersion(self.gwnavworld, tag_volume.nav_tagvolume, crowd_dispersion_length_to_consider, crowd_dispersion_slot_capacity, crowd_dispersion_slot_duration)
		end
	end
end

NavWorld.add_boxobstacle = function (self, unit)
	self.navboxobstacles[unit] = NavBoxObstacle(self, unit)

	self.navboxobstacles[unit]:add_to_world()
end

NavWorld.remove_boxobstacle = function (self, unit)
	if self.navboxobstacles[unit] then
		self.navboxobstacles[unit]:remove_from_world()

		self.navboxobstacles[unit] = nil
	end
end

NavWorld.add_cylinderobstacle = function (self, unit)
	self.navcylinderobstacles[unit] = NavCylinderObstacle(self, unit)

	self.navcylinderobstacles[unit]:add_to_world()
end

NavWorld.remove_cylinderobstacle = function (self, unit)
	if self.navcylinderobstacles[unit] then
		self.navcylinderobstacles[unit]:remove_from_world()

		self.navcylinderobstacles[unit] = nil
	end
end

NavWorld.add_bot = function (self, bot)
	self.bots[bot.unit] = bot
end

NavWorld.remove_bot = function (self, bot)
	self.bots[bot.unit] = nil
end

NavWorld.force_all_bots_to_repath = function (self)
	for kb, bot in pairs(self.bots) do
		bot:force_repath()
	end
end

NavWorld.update = function (self, dt)
	if dt <= 0 then
		dt = 0.001
	end

	for unit, bot in pairs(self.bots) do
		if Unit.alive(unit) and bot then
			bot:update(dt)
		end
	end

	for unit, box in pairs(self.navboxobstacles) do
		if Unit.alive(unit) and box then
			box:update(dt)
		end
	end

	for unit, cylinder in pairs(self.navcylinderobstacles) do
		if Unit.alive(unit) and cylinder then
			cylinder:update(dt)
		end
	end

	GwNavWorld.update(self.gwnavworld, dt)
end

NavWorld.shutdown = function (self)
	self.markers = {}

	self:clear_bot_configuration()
	self:clear_bots()
	self:clear_navgraphs()
	self:clear_tagboxes()
	self:clear_boxobstacles()
	self:clear_cylinderobstacles()
	GwNavWorld.remove_navdata(self.navdata)

	self.navdata = nil

	GwNavWorld.destroy(self.gwnavworld)

	self.gwnavworld = nil
	_navworlds[self.level] = nil
end

NavWorld.clear_bot_configuration = function (self)
	for kc, configuration in pairs(self.bot_configurations) do
		configuration:shutdown()
	end

	self.bot_configurations = {}
end

NavWorld.clear_navgraphs = function (self)
	for kg, graph in pairs(self.navgraphs) do
		graph:shutdown()
	end

	self.navgraphs = {}
end

NavWorld.clear_tagboxes = function (self)
	for kn, volume in pairs(self.navtagvolumes) do
		volume:remove_from_world()
		volume:shutdown()
	end

	self.navtagvolumes = {}
end

NavWorld.clear_boxobstacles = function (self)
	for kb, box in pairs(self.navboxobstacles) do
		box:remove_from_world()
		box:shutdown()
	end

	self.navboxobstacles = {}
end

NavWorld.clear_cylinderobstacles = function (self)
	for kc, cylinder in pairs(self.navcylinderobstacles) do
		cylinder:remove_from_world()
		cylinder:shutdown()
	end

	self.navcylinderobstacles = {}
end

NavWorld.clear_bots = function (self)
	for kb, bot in pairs(self.bots) do
		bot:shutdown()
	end

	self.bots = {}
end

NavWorld.debug_draw = function (self, gui, line_object)
	if self.render_mesh == false then
		return
	end

	GwNavWorld.build_database_visual_geometry(self.gwnavworld)

	local tile_count = GwNavWorld.database_tile_count(self.gwnavworld)
	local black = Color(255, 0, 0, 0)

	for tile = 1, tile_count do
		local triangle_count = GwNavWorld.database_tile_triangle_count(self.gwnavworld, tile)

		for i = 1, triangle_count do
			local temp_size = Script.temp_byte_count()
			local a, b, c, tri_color = GwNavWorld.database_triangle(self.gwnavworld, tile, i)

			if a ~= nil then
				Gui.triangle(gui, a, b, c, 1, tri_color)
				LineObject.add_line(line_object, black, a, b)
				LineObject.add_line(line_object, black, b, c)
				LineObject.add_line(line_object, black, c, a)
			end

			Script.set_temp_byte_count(temp_size)
		end
	end
end

NavWorld.visual_debug_camera = function (self, camera)
	local pos = Camera.world_position(camera)
	local camera_pose = Camera.world_pose(camera)
	local forward = Matrix4x4.forward(camera_pose)
	local up = Matrix4x4.up(camera_pose)

	GwNavWorld.set_visual_debug_camera_transform(self.gwnavworld, pos, pos + forward, up)
end

return NavWorld
