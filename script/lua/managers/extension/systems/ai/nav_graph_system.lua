-- chunkname: @script/lua/managers/extension/systems/ai/nav_graph_system.lua

class("NavGraphSystem", "ExtensionSystemBase")

local WANTED_LEDGELATOR_VERSION = "2016.SEPTEMBER.22.13"

NavGraphSystem.extension_list = {}

NavGraphSystem.init = function (self, extension_system_creation_context, system_name, extension_list)
	NavGraphSystem.super.init(self, extension_system_creation_context, system_name, extension_list)

	self.world = extension_system_creation_context.world
	self.nav_world = Managers.state.extension:system("ai_system"):nav_world()

	local version
	local level_name = self._level_name
	local level_settings = LevelSettings.levels[level_name]
	local level_resource_name = level_settings.resource_name

	self.level_resource_name = level_resource_name

	if level_settings.no_bots_allowed then
		self.ledgelator_version = WANTED_LEDGELATOR_VERSION
		self.smart_objects = {}
	elseif level_resource_name then
		local smart_object_path = level_resource_name .. "_smartobjects"

		if Application.can_get("lua", smart_object_path) then
			local smart_objects = require(smart_object_path)

			self.smart_objects, self.smart_object_count, version = smart_objects.smart_objects, smart_objects.smart_object_count, smart_objects.version
			self.ledgelator_version = smart_objects.ledgelator_version

			if self.smart_objects == nil then
				self.smart_objects = smart_objects
			end

			package.loaded[smart_object_path] = nil
			package.load_order[#package.load_order] = nil
		else
			self.smart_objects = {}
		end

		printf("Nav graph ledgelator version: Found version=%s Wanted version=%s", tostring(self.ledgelator_version), WANTED_LEDGELATOR_VERSION)
	end

	self.smart_object_types = {}
	self.smart_object_data = {}
	self.line_object = World.create_line_object(self.world)
	self._navgraphs = {}

	self:init_nav_graphs()
end

NavGraphSystem.destroy = function (self)
	for i, navgraph in ipairs(self._navgraphs) do
		GwNavGraph.remove_from_database(navgraph)
		GwNavGraph.destroy(navgraph)
	end
end

local control_points = {}

NavGraphSystem.init_nav_graphs = function (self)
	local nav_world = self.nav_world
	local smart_objects = self.smart_objects
	local debug_color = Colors.get("orange")

	for smart_object_id, smart_object_unit_data in pairs(smart_objects) do
		for smart_object, smart_object_data in pairs(smart_object_unit_data) do
			local smart_object_type = smart_object_data.smart_object_type or "ledges"
			local layer_id = LAYER_ID_MAPPING[smart_object_type]

			control_points[1] = Vector3Aux.unbox(smart_object_data.pos1)
			control_points[2] = Vector3Aux.unbox(smart_object_data.pos2)

			local is_bidirectional = true

			if smart_object_unit_data.is_one_way or smart_object_type ~= "teleporter" and math.abs(control_points[1].z - control_points[2].z) > SmartObjectSettings.jump_up_max_height then
				is_bidirectional = false
			end

			smart_object_data.data.is_bidirectional = is_bidirectional

			local smart_object_index = smart_object_data.smart_object_index

			self.smart_object_types[smart_object_index] = smart_object_type
			self.smart_object_data[smart_object_index] = smart_object_data.data

			local navgraph = GwNavGraph.create(nav_world, is_bidirectional, control_points, debug_color, layer_id, smart_object_index)

			GwNavGraph.add_to_database(navgraph)

			if not script_data.disable_crowd_dispersion then
				GwNavWorld.register_all_navgraphedges_for_crowd_dispersion(nav_world, navgraph, 1, 100)
			end

			self._navgraphs[#self._navgraphs + 1] = navgraph

			if script_data.visualize_ledges then
				local drawer = Managers.state.debug:drawer({
					mode = "retained",
					name = "NavGraphConnectorExtension"
				})
				local debug_color_fail = Colors.get("red")

				if smart_object_type == "ledges" or smart_object_type == "ledges_with_fence" then
					if smart_object_data.data.ledge_position1 then
						drawer:line(control_points[1], Vector3Aux.unbox(smart_object_data.data.ledge_position1), debug_color)
						drawer:line(Vector3Aux.unbox(smart_object_data.data.ledge_position1), Vector3Aux.unbox(smart_object_data.data.ledge_position2), debug_color)
						drawer:line(control_points[2], Vector3Aux.unbox(smart_object_data.data.ledge_position2), debug_color)
					else
						drawer:line(control_points[1], Vector3Aux.unbox(smart_object_data.data.ledge_position), debug_color)
						drawer:line(control_points[2], Vector3Aux.unbox(smart_object_data.data.ledge_position), debug_color)
					end

					if not smart_object_data.data.is_bidirectional then
						drawer:vector(control_points[1], Vector3.up(), debug_color)
					end
				elseif smart_object_type == "jumps" then
					drawer:line(control_points[1], control_points[2], Colors.get("aqua_marine"))
				else
					drawer:line(control_points[1], control_points[2], debug_color)
				end

				local is_position_on_navmesh = GwNavQueries.triangle_from_position(nav_world, control_points[1])

				if is_position_on_navmesh then
					drawer:sphere(control_points[1], 0.05, debug_color)
				else
					drawer:sphere(control_points[1], 0.05, debug_color_fail)
				end

				is_position_on_navmesh = GwNavQueries.triangle_from_position(nav_world, control_points[2])

				if is_position_on_navmesh then
					drawer:sphere(control_points[2], 0.05, debug_color)
				else
					drawer:sphere(control_points[2], 0.05, debug_color_fail)
				end
			end
		end
	end
end

NavGraphSystem.update = function (self, context, t, dt)
	if script_data.nav_mesh_debug then
		self:debug_draw_nav_mesh(self.nav_world, self.world, self.line_object)
	end

	if self.ledgelator_version ~= WANTED_LEDGELATOR_VERSION and math.floor(t) % 10 > 3 then
		-- Nothing
	end
end

NavGraphSystem.get_smart_object_type = function (self, smart_object_id)
	return self.smart_object_types[smart_object_id]
end

NavGraphSystem.debug_draw_nav_mesh = function (self, nav_world, world, line_object)
	GwNavWorld.build_database_visual_geometry(nav_world)

	local tile_count = GwNavWorld.database_tile_count(nav_world)

	for tile = 1, tile_count do
		local triangle_count = GwNavWorld.database_tile_triangle_count(nav_world, tile)

		for i = 1, triangle_count do
			local num_vectors, num_quaternions, num_matrices = Script.temp_byte_count()
			local a, b, c, tri_color = GwNavWorld.database_triangle(nav_world, tile, i)

			if a then
				LineObject.add_line(line_object, tri_color, a, b)
				LineObject.add_line(line_object, tri_color, b, c)
				LineObject.add_line(line_object, tri_color, c, a)
			end

			Script.set_temp_byte_count(num_vectors, num_quaternions, num_matrices)
		end
	end

	LineObject.dispatch(world, line_object)
	LineObject.reset(line_object)
end

NavGraphSystem.get_smart_object_data = function (self, smart_object_id)
	return self.smart_object_data[smart_object_id]
end
