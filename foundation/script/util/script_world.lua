﻿-- chunkname: @foundation/script/util/script_world.lua

require("foundation/script/util/script_viewport")

ScriptWorld = ScriptWorld or {}

ScriptWorld.name = function (world)
	return World.get_data(world, "name")
end

ScriptWorld.activate = function (world)
	World.set_data(world, "active", true)
end

ScriptWorld.deactivate = function (world)
	World.set_data(world, "active", false)
end

ScriptWorld.pause = function (world)
	World.set_data(world, "paused", true)
end

ScriptWorld.unpause = function (world)
	World.set_data(world, "paused", false)
end

ScriptWorld.create_viewport = function (world, name, template, layer)
	local viewports = World.get_data(world, "viewports")

	fassert(viewports[name] == nil, "Viewport %q already exists", name)

	local viewport = Application.create_viewport(world, template)

	Viewport.set_data(viewport, "layer", layer or 1)
	Viewport.set_data(viewport, "active", true)

	viewports[name] = viewport

	local camera_unit = World.spawn_unit(world, "core/units/camera")
	local camera = Unit.camera(camera_unit, "camera")

	Camera.set_data(camera, "unit", camera_unit)
	Viewport.set_data(viewport, "camera", camera)
	ScriptWorld._update_render_queue(world)

	return viewport
end

ScriptWorld.create_global_free_flight_viewport = function (world, template)
	fassert(not World.has_data(world, "global_free_flight_viewport"), "Trying to spawn global freeflight viewport when one already exists.")

	local viewports = World.get_data(world, "viewports")

	if table.is_empty(viewports) then
		return nil
	end

	local bottom_layer = math.huge
	local bottom_layer_vp

	for key, vp in pairs(viewports) do
		local layer = Viewport.get_data(vp, "layer")

		if layer < bottom_layer then
			bottom_layer, bottom_layer_vp = layer, vp
		end
	end

	local free_flight_viewport = Application.create_viewport(world, template)

	Viewport.set_data(free_flight_viewport, "layer", Viewport.get_data(bottom_layer_vp, "layer"))
	World.set_data(world, "global_free_flight_viewport", free_flight_viewport)

	local camera_unit = World.spawn_unit(world, "core/units/camera")
	local camera = Unit.camera(camera_unit, "camera")

	Camera.set_data(camera, "unit", camera_unit)

	local bottom_layer_camera = ScriptViewport.camera(bottom_layer_vp)
	local pose = Camera.local_pose(bottom_layer_camera)

	ScriptCamera.set_local_pose(camera, pose)

	local vertical_fov = Camera.vertical_fov(bottom_layer_camera)

	Camera.set_vertical_fov(camera, vertical_fov)
	Viewport.set_data(free_flight_viewport, "camera", camera)

	return free_flight_viewport
end

ScriptWorld.destroy_global_free_flight_viewport = function (world)
	local viewport = World.get_data(world, "global_free_flight_viewport")

	fassert(viewport, "Trying to destroy global free flight viewport when none exists.")

	local camera = Viewport.get_data(viewport, "camera")
	local camera_unit = Camera.get_data(camera, "unit")

	World.destroy_unit(world, camera_unit)
	Application.destroy_viewport(world, viewport)
	World.set_data(world, "global_free_flight_viewport", nil)
end

ScriptWorld.global_free_flight_viewport = function (world)
	return World.get_data(world, "global_free_flight_viewport")
end

ScriptWorld.create_free_flight_viewport = function (world, overridden_viewport_name, template)
	local overridden_viewport = ScriptWorld.viewport(world, overridden_viewport_name)
	local free_flight_viewport = Application.create_viewport(world, template)

	Viewport.set_data(free_flight_viewport, "layer", Viewport.get_data(overridden_viewport, "layer"))

	local free_flight_viewports = World.get_data(world, "free_flight_viewports")

	fassert(free_flight_viewports[overridden_viewport_name] == nil, "Free flight viewport %q already exists", overridden_viewport_name)

	free_flight_viewports[overridden_viewport_name] = free_flight_viewport

	local camera_unit = World.spawn_unit(world, "core/units/camera")
	local camera = Unit.camera(camera_unit, "camera")

	Camera.set_data(camera, "unit", camera_unit)

	local overridden_viewport_camera = ScriptViewport.camera(overridden_viewport)
	local pose = Camera.local_pose(overridden_viewport_camera)

	ScriptCamera.set_local_pose(camera, pose)
	Viewport.set_data(free_flight_viewport, "camera", camera)
	Viewport.set_data(free_flight_viewport, "overridden_viewport", overridden_viewport)
	ScriptWorld._update_render_queue(world)

	return free_flight_viewport
end

ScriptWorld.destroy_free_flight_viewport = function (world, name)
	local viewports = World.get_data(world, "free_flight_viewports")

	fassert(viewports[name], "Viewport %q doesn't exist", name)

	local viewport = viewports[name]

	viewports[name] = nil

	local camera = Viewport.get_data(viewport, "camera")
	local camera_unit = Camera.get_data(camera, "unit")

	World.destroy_unit(world, camera_unit)
	Application.destroy_viewport(world, viewport)
	ScriptWorld._update_render_queue(world)
end

ScriptWorld.destroy_viewport = function (world, name)
	local viewports = World.get_data(world, "viewports")

	fassert(viewports[name], "Viewport %q doesn't exist", name)

	local viewport = viewports[name]

	viewports[name] = nil

	local camera = Viewport.get_data(viewport, "camera")
	local camera_unit = Camera.get_data(camera, "unit")

	World.destroy_unit(world, camera_unit)
	Application.destroy_viewport(world, viewport)
	ScriptWorld._update_render_queue(world)
end

ScriptWorld.activate_viewport = function (world, viewport)
	Viewport.set_data(viewport, "active", true)
	ScriptWorld._update_render_queue(world)
end

ScriptWorld.deactivate_viewport = function (world, viewport)
	Viewport.set_data(viewport, "active", false)
	ScriptWorld._update_render_queue(world)
end

ScriptWorld.has_viewport = function (world, name)
	local viewports = World.get_data(world, "viewports")

	return viewports[name] and true or false
end

ScriptWorld.viewport = function (world, name, return_free_flight_viewport)
	local viewport

	if return_free_flight_viewport then
		viewport = World.get_data(world, "free_flight_viewports")[name] or World.get_data(world, "viewports")[name]
	else
		viewport = World.get_data(world, "viewports")[name]
	end

	fassert(viewport, "Viewport %q doesn't exist", name)

	return viewport
end

ScriptWorld.free_flight_viewport = function (world, name)
	local viewports = World.get_data(world, "free_flight_viewports")

	fassert(viewports[name], "Free flight viewport %q doesn't exists", name)

	return viewports[name]
end

ScriptWorld.update = function (world, dt, anim_callback, scene_callback)
	if World.get_data(world, "active") then
		if World.get_data(world, "paused") then
			dt = 0
		end

		Profiler.start(ScriptWorld.name(world))

		if anim_callback then
			World.update_animations_with_callback(world, dt, anim_callback)
		else
			World.update_animations(world, dt)
		end

		if scene_callback then
			World.update_scene_with_callback(world, dt, scene_callback)
		else
			World.update_scene(world, dt)
		end

		Profiler.stop()
	else
		World.update(world, dt)
	end
end

ScriptWorld.render = function (world)
	local shading_env = World.get_data(world, "shading_environment")

	if not shading_env then
		return
	end

	local global_free_flight_viewport = World.get_data(world, "global_free_flight_viewport")

	if global_free_flight_viewport then
		ShadingEnvironment.blend(shading_env, World.get_data(world, "shading_settings"))
		ShadingEnvironment.apply(shading_env)

		if World.has_data(world, "shading_callback") then
			local callback = World.get_data(world, "shading_callback")

			callback(world, shading_env)
		end

		local camera = ScriptViewport.camera(global_free_flight_viewport)

		Application.render_world(world, camera, global_free_flight_viewport, shading_env)
	else
		local render_queue = World.get_data(world, "render_queue")

		if table.is_empty(render_queue) then
			return
		end

		if not World.get_data(world, "avoid_blend") then
			ShadingEnvironment.blend(shading_env, World.get_data(world, "shading_settings"))
		end

		if World.has_data(world, "shading_callback") then
			local callback = World.get_data(world, "shading_callback")

			callback(world, shading_env)
		end

		if not World.get_data(world, "avoid_blend") then
			ShadingEnvironment.apply(shading_env)
		end

		for _, viewport in ipairs(render_queue) do
			local camera = ScriptViewport.camera(viewport)

			Application.render_world(world, camera, viewport, shading_env)
		end
	end
end

ScriptWorld._update_render_queue = function (world)
	local render_queue = {}
	local viewports = World.get_data(world, "viewports")
	local free_flight_viewports = World.get_data(world, "free_flight_viewports")

	for name, viewport in pairs(viewports) do
		if ScriptViewport.active(viewport) then
			render_queue[#render_queue + 1] = free_flight_viewports[name] or viewport
		end
	end

	local function comparator(v1, v2)
		return Viewport.get_data(v1, "layer") < Viewport.get_data(v2, "layer")
	end

	table.sort(render_queue, comparator)
	World.set_data(world, "render_queue", render_queue)
end

ScriptWorld.create_shading_environment = function (world, shading_environment_name, shading_callback, mood_setting)
	local shading_env = World.create_shading_environment(world, shading_environment_name)

	World.set_data(world, "shading_environment", shading_env)
	World.set_data(world, "shading_callback", shading_callback)
	World.set_data(world, "shading_settings", {
		mood_setting,
		1
	})

	return shading_env
end

ScriptWorld.load_level = function (world, name, object_sets, position, rotation, shading_callback, mood_setting)
	local levels = World.get_data(world, "levels")

	fassert(levels[name] == nil, "Level %q already loaded", name)

	local level = World.load_level_with_object_sets(world, name, object_sets or {}, {}, position or Vector3.zero(), rotation or Quaternion.identity())

	levels[name] = level

	Profiler.start("shading_env_name")

	local shading_env_name = Level.get_data(level, "shading_environment") or "core/stingray_renderer/environments/midday/midday"

	if shading_env_name:len() > 0 then
		local shading_env = World.get_data(world, "shading_environment")

		if shading_env then
			World.set_shading_environment(world, shading_env, shading_env_name)

			if shading_callback then
				World.set_data(world, "shading_callback", shading_callback)
			end

			if mood_setting then
				World.set_data(world, "shading_settings", {
					mood_setting,
					1
				})
			end
		else
			shading_env = ScriptWorld.create_shading_environment(world, shading_env_name, shading_callback, mood_setting or "default")

			World.set_shading_environment(world, shading_env, shading_env_name)
		end
	end

	Profiler.stop()

	return level
end

ScriptWorld.level = function (world, name)
	local levels = World.get_data(world, "levels")

	fassert(levels[name], "Level %q doesn't exist", name)

	return levels[name]
end

ScriptWorld.destroy_level = function (world, name)
	local levels = World.get_data(world, "levels")

	fassert(levels[name], "Level %q doesn't exist", name)
	World.destroy_level(world, levels[name])

	levels[name] = nil
end

ScriptWorld.create_particles_linked = function (world, effect_name, unit, node, policy, pose)
	local id = World.create_particles(world, effect_name, Vector3(0, 0, 0))

	pose = pose or Matrix4x4.identity()

	World.link_particles(world, id, unit, node, pose, policy)

	return id
end
