-- chunkname: @core/stingray_renderer/entities/reflection_probe/reflection_probe.lua

local EntityManager = stingray.EntityManager
local Light = stingray.Light
local Material = stingray.Material
local Math = stingray.Math
local Matrix4x4 = stingray.Matrix4x4
local Script = stingray.Script
local Unit = stingray.Unit
local Vector3 = stingray.Vector3
local World = stingray.World
local type_name = Script.type_name
local probe_unit_resource_name = "core/stingray_renderer/entities/reflection_probe/probe"

local function get_entity_pose(transform_component, entity)
	return transform_component:instances(entity) and transform_component:local_pose(entity) or Matrix4x4.identity()
end

local function get_entity_reflection_probe_data(data_component, entity)
	local component_handles, num_components = data_component:instances_with_tag_in_entity(entity, "reflection_probe")

	return component_handles[1]
end

local function set_probe_unit_material(probe_unit, material_resource)
	local light = Unit.light(probe_unit, "probe")

	if light ~= nil then
		Unit.set_light_material(probe_unit, light, material_resource or "")
	end
end

local function set_probe_unit_material_properties(probe_unit, data_component, e, i)
	local light = Unit.light(probe_unit, "probe")

	if light == nil then
		return
	end

	local material = Light.material(light)

	if material == nil then
		return
	end

	local trace_min, trace_max, falloff, light_min, light_max = Vector3(data_component:get_property(e, i, "trace_box_min")), Vector3(data_component:get_property(e, i, "trace_box_max")), Vector3(data_component:get_property(e, i, "falloff")), Vector3(data_component:get_property(e, i, "light_box_min")), Vector3(data_component:get_property(e, i, "light_box_max"))

	Light.set_box_min(light, light_min)
	Light.set_box_max(light, light_max)
	Material.set_vector3(material, "trace_box_min", trace_min)
	Material.set_vector3(material, "trace_box_max", trace_max)
	Material.set_vector3(material, "falloff", falloff)
end

stingray.components = stingray.components or {}
stingray.components.ReflectionProbe = stingray.components.ReflectionProbe or {
	name = "reflection_probe",
	entity_data = {}
}

local ReflectionProbe = stingray.components.ReflectionProbe
local entity_data = ReflectionProbe.entity_data

local function get_probe_unit(probe_units_by_component_by_entity, entity, component)
	local probe_units_by_component = probe_units_by_component_by_entity[entity]

	return probe_units_by_component and probe_units_by_component[component]
end

local function set_probe_unit(probe_units_by_component_by_entity, entity, component, probe_unit)
	assert(type_name(entity) == "Entity" and EntityManager.alive(entity))
	assert(type_name(component) == "number" and component >= 0)
	assert(probe_unit == nil or type_name(probe_unit) == "Unit" and Unit.alive(probe_unit))

	local probe_units_by_component = probe_units_by_component_by_entity[entity]

	if probe_unit == nil then
		if probe_units_by_component ~= nil then
			probe_units_by_component[component] = nil

			if not next(probe_units_by_component) then
				probe_units_by_component_by_entity[entity] = nil
			end
		end
	else
		if probe_units_by_component == nil then
			probe_units_by_component = {}
			probe_units_by_component_by_entity[entity] = probe_units_by_component
		end

		probe_units_by_component[component] = probe_unit
	end
end

local function make_selection_mask(world_component_data)
	world_component_data._selection_mask_counter = world_component_data._selection_mask_counter + 1

	return world_component_data._selection_mask_counter % 255 + 1
end

local function spawned(world, instances, show_gizmo)
	local world_component_data = entity_data[world]
	local _selection_masks_by_probe_unit = world_component_data._selection_masks_by_probe_unit
	local _probe_units_by_component_by_entity = world_component_data._probe_units_by_component_by_entity
	local transform_component = EntityManager.transform_component(world)
	local data_component = EntityManager.data_component()
	local component_instances = {}

	for i = 1, #instances, 2 do
		local entity = instances[i]
		local component = instances[i + 1]
		local existing_unit = get_probe_unit(_probe_units_by_component_by_entity, entity, component)

		if Unit.alive(existing_unit) then
			World.destroy_unit(world, existing_unit)
		end

		local pose = get_entity_pose(transform_component, entity)
		local probe_unit = World.spawn_unit(world, probe_unit_resource_name, pose)

		Unit.set_visibility(probe_unit, "gizmo", show_gizmo)
		set_probe_unit(_probe_units_by_component_by_entity, entity, component, probe_unit)

		_selection_masks_by_probe_unit[probe_unit] = make_selection_mask(world_component_data)

		local data_component_handle = get_entity_reflection_probe_data(data_component, entity)

		if data_component_handle ~= nil then
			set_probe_unit_material(probe_unit, data_component:get_property(entity, data_component_handle, "material"))
			set_probe_unit_material_properties(probe_unit, data_component, entity, data_component_handle)
		end
	end
end

ReflectionProbe.world_created = function (world)
	assert(entity_data[world] == nil)

	entity_data[world] = {
		_selection_mask_counter = 0,
		_probe_units_by_component_by_entity = {},
		_selection_masks_by_probe_unit = {}
	}
end

ReflectionProbe.world_destroyed = function (world)
	assert(entity_data[world] ~= nil)

	entity_data[world] = nil
end

ReflectionProbe.spawned = function (world, instances)
	spawned(world, instances, false)
end

ReflectionProbe.editor_spawned = function (world, instances)
	if entity_data[world] == nil then
		ReflectionProbe.world_created(world)
	end

	spawned(world, instances, true)
end

ReflectionProbe.unspawned = function (world, instances)
	local world_component_data = entity_data[world]
	local _selection_masks_by_probe_unit = world_component_data._selection_masks_by_probe_unit
	local _probe_units_by_component_by_entity = world_component_data._probe_units_by_component_by_entity

	for i = 1, #instances, 2 do
		local entity = instances[i]
		local component = instances[i + 1]
		local existing_unit = get_probe_unit(_probe_units_by_component_by_entity, entity, component)

		set_probe_unit(_probe_units_by_component_by_entity, entity, component, nil)

		_selection_masks_by_probe_unit[existing_unit] = nil

		if Unit.alive(existing_unit) then
			World.destroy_unit(world, existing_unit)
		end
	end
end

ReflectionProbe.editor_update = function (world, dt)
	local world_component_data = entity_data[world]
	local transform_component = EntityManager.transform_component(world)
	local data_component = EntityManager.data_component()

	for entity, probe_units_by_component in pairs(world_component_data._probe_units_by_component_by_entity) do
		local pose = get_entity_pose(transform_component, entity)

		for _, probe_unit in pairs(probe_units_by_component) do
			local data_component_handle = get_entity_reflection_probe_data(data_component, entity)

			if data_component_handle ~= nil then
				set_probe_unit_material_properties(probe_unit, data_component, entity, data_component_handle)
			end

			Unit.set_local_pose(probe_unit, 1, pose)
			World.update_unit(Unit.world(probe_unit), probe_unit)
		end
	end
end

ReflectionProbe.editor_raycast = function (world, instances, ray_start, ray_dir, ray_length, are_gizmos_visible, result)
	local world_component_data = entity_data[world]
	local _probe_units_by_component_by_entity = world_component_data._probe_units_by_component_by_entity
	local include_hidden_meshes = false

	for i = 1, #instances, 2 do
		local entity = instances[i]
		local component = instances[i + 1]
		local probe_unit = get_probe_unit(_probe_units_by_component_by_entity, entity, component)

		if Unit.alive(probe_unit) then
			local temp_size = Script.temp_byte_count()
			local pose, radius = UnitUtils.unscaled_box(probe_unit)
			local oobb_distance = Intersect.ray_box(ray_start, ray_dir, pose, radius)
			local is_oobb_hit_by_ray = oobb_distance ~= nil and oobb_distance < ray_length

			Script.set_temp_byte_count(temp_size)

			if is_oobb_hit_by_ray then
				local distance, normal = Unit.mesh_raycast(probe_unit, ray_start, ray_dir, ray_length, include_hidden_meshes)

				if distance ~= nil and distance < ray_length then
					ray_length = distance
					result.entity = entity
					result.component = component
					result.distance = distance
					result.normal = normal
				end
			end
		end
	end
end

ReflectionProbe.editor_inside_frustum = function (world, instances, n1, o1, n2, o2, n3, o3, n4, o4, are_gizmos_visible, result)
	local world_component_data = entity_data[world]
	local _probe_units_by_component_by_entity = world_component_data._probe_units_by_component_by_entity

	for i = 1, #instances, 2 do
		local entity = instances[i]
		local component = instances[i + 1]
		local probe_unit = get_probe_unit(_probe_units_by_component_by_entity, entity, component)

		if Unit.alive(probe_unit) then
			local temp_size = Script.temp_byte_count()
			local pose, radius = UnitUtils.unscaled_box(probe_unit)

			if Math.box_in_frustum(pose, radius, n1, o1, n2, o2, n3, o3, n4, o4) then
				result[entity] = true
			end

			Script.set_temp_byte_count(temp_size)
		end
	end
end

ReflectionProbe.editor_intersects_frustum = function (world, instances, n1, o1, n2, o2, n3, o3, n4, o4, n5, o5, n6, o6, p1, p2, p3, p4, p5, p6, p7, p8, are_gizmos_visible, result)
	local world_component_data = entity_data[world]
	local _probe_units_by_component_by_entity = world_component_data._probe_units_by_component_by_entity

	for i = 1, #instances, 2 do
		local entity = instances[i]
		local component = instances[i + 1]
		local probe_unit = get_probe_unit(_probe_units_by_component_by_entity, entity, component)

		if Unit.alive(probe_unit) then
			local temp_size = Script.temp_byte_count()
			local pose, radius = UnitUtils.unscaled_box(probe_unit)

			if Math.box_intersects_frustum(pose, radius, n1, o1, n2, o2, n3, o3, n4, o4, n5, o5, n6, o6, p1, p2, p3, p4, p5, p6, p7, p8) then
				result[entity] = true
			end

			Script.set_temp_byte_count(temp_size)
		end
	end
end

ReflectionProbe.editor_highlight_changed = function (world, instances, highlight_color)
	local world_component_data = entity_data[world]
	local _selection_masks_by_probe_unit = world_component_data._selection_masks_by_probe_unit
	local _probe_units_by_component_by_entity = world_component_data._probe_units_by_component_by_entity

	for i = 1, #instances, 2 do
		local entity = instances[i]
		local component = instances[i + 1]
		local probe_unit = get_probe_unit(_probe_units_by_component_by_entity, entity, component)

		if Unit.alive(probe_unit) then
			local selection_mask = _selection_masks_by_probe_unit[probe_unit]

			UnitUtils.set_unit_selection_color(probe_unit, highlight_color, selection_mask)
		end
	end
end

ReflectionProbe.editor_apply_pre_render_visibility = function (world, instances, is_object_visible, are_gizmos_visible)
	local world_component_data = entity_data[world]
	local _probe_units_by_component_by_entity = world_component_data._probe_units_by_component_by_entity

	for i = 1, #instances, 2 do
		local entity = instances[i]
		local component = instances[i + 1]
		local probe_unit = get_probe_unit(_probe_units_by_component_by_entity, entity, component)

		if Unit.alive(probe_unit) then
			Unit.set_visibility(probe_unit, "gizmo", is_object_visible and are_gizmos_visible)
		end
	end
end

ReflectionProbe.editor_unspawned = ReflectionProbe.unspawned

return {
	component = ReflectionProbe
}
