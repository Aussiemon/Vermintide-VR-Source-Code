-- chunkname: @script/lua/helpers/effect_helper.lua

require("settings/material_effect_mappings")
require("script/lua/helpers/wwise_utils")

script_data.debug_material_effects = nil
EffectHelper = EffectHelper or {}
EffectHelper.temporary_material_drawer_mapping = {}

local Unit = stingray.Unit
local Vector3 = stingray.Vector3
local World = stingray.World
local Actor = stingray.Actor
local Matrix4x4 = stingray.Matrix4x4
local Quaternion = stingray.Quaternion
local Vector3Box = stingray.Vector3Box
local PhysicsWorld = stingray.PhysicsWorld
local Wwise = stingray.Wwise
local WwiseWorld = stingray.WwiseWorld
local LineObject = stingray.LineObject
local Color = stingray.Color

EffectHelper.play_surface_material_effects = function (effect_name, world, wwise_world, hit_unit, position, rotation, normal, sound_character, husk)
	local effect_settings = MaterialEffectMappings[effect_name]

	fassert(not Unit.get_data(hit_unit, "breed"), "Trying to apply surface material effect to unit %q with breed.", hit_unit)
	fassert(not ScriptUnit.has_extension(hit_unit, "ai_inventory_item_system"), "Trying to apply surface material effect to unit %q with ai_inventory_item extension.", hit_unit)

	local material_ids = EffectHelper.query_material_surface(hit_unit, position, rotation)
	local material
	local has_material = true

	if material_ids then
		if material_ids[1] == 0 or material_ids[1] == nil then
			has_material = false
		end
	else
		has_material = false
	end

	if not has_material then
		material = DefaultSurfaceMaterial
	else
		material = MaterialIDToName.surface_material[material_ids[1]]

		if not material and script_data.debug_material_effects then
			local drawer = Managers.state.debug:drawer({
				mode = "retained",
				name = "DEBUG_DRAW_IMPACT_DECAL_HIT"
			})
			local fwd = Quaternion.forward(rotation) * MaterialEffectSettings.material_query_depth
			local draw_pos = position - fwd * 0.5

			drawer:vector(draw_pos, fwd, Color(255, 255, 0, 0))
		elseif script_data.debug_material_effects then
			table.dump(material_ids)
		end
	end

	if script_data.debug_material_effects and material then
		local drawer = Managers.state.debug:drawer({
			mode = "retained",
			name = "DEBUG_DRAW_IMPACT_DECAL_HIT"
		})
		local fwd = Quaternion.forward(rotation) * MaterialEffectSettings.material_query_depth
		local draw_pos = position - fwd * 0.5

		drawer:vector(draw_pos, fwd, Color(255, 0, 255, 0))
	end

	local sound = effect_settings.sound and effect_settings.sound[material]

	if sound then
		local wwise_source_id = WwiseWorld.make_auto_source(wwise_world, position, rotation)

		if script_data.debug_material_effects then
			printf("[EffectHelper:play_surface_material_effects()] playing sound %s", sound.event)
		end

		if sound.parameters then
			for parameter_name, parameter_value in pairs(sound.parameters) do
				if script_data.debug_material_effects then
					printf("   sound param: %q, sound_value %q", parameter_name, parameter_value)
				end

				WwiseWorld.set_switch(wwise_world, parameter_name, parameter_value, wwise_source_id)
			end
		end

		if sound_character then
			if script_data.debug_material_effects then
				printf("   sound param: \"sound_character\", sound_value %q", sound_character)
			end

			WwiseWorld.set_switch(wwise_world, "character", sound_character, wwise_source_id)
		end

		if script_data.debug_material_effects then
			printf("   sound param: \"husk\", sound_value %q", husk and "true" or "false")
		end

		WwiseWorld.set_switch(wwise_world, "husk", husk and "true" or "false", wwise_source_id)
		WwiseWorld.trigger_event(wwise_world, sound.event, wwise_source_id)
	end

	local particles = effect_settings.particles and effect_settings.particles[material]

	if particles then
		local normal_rotation = Quaternion.look(normal, Vector3.up())

		World.create_particles(world, particles, position, normal_rotation)
	end
end

EffectHelper.play_skinned_surface_material_effects = function (effect_name, world, wwise_world, position, rotation, normal, husk, enemy_type, damage_sound, no_damage, hit_zone_name)
	local effect_settings = MaterialEffectMappings[effect_name]
	local material = "flesh"

	if no_damage then
		material = "armored"
	end

	local sound = effect_settings.sound and effect_settings.sound[material]

	if sound then
		local source_id = WwiseWorld.make_auto_source(wwise_world, position)

		if sound.parameters then
			for parameter_name, parameter_value in pairs(sound.parameters) do
				WwiseWorld.set_switch(wwise_world, source_id, parameter_name, parameter_value)
			end
		end

		if enemy_type then
			WwiseWorld.set_switch(wwise_world, "enemy_type", enemy_type, source_id)
		end

		if damage_sound then
			WwiseWorld.set_switch(wwise_world, "damage_sound", damage_sound, source_id)
		end

		if hit_zone_name then
			WwiseWorld.set_switch(wwise_world, "hit_zone", hit_zone_name, source_id)
		end

		local husk_value = husk and "true" or "false"

		WwiseWorld.set_switch(wwise_world, "husk", husk_value, source_id)

		local event = no_damage and sound.event.no_damage_event or sound.event

		if script_data.debug_material_effects then
			print("playing event ", event)
			print("\tenemy_type ", enemy_type)
			print("\tdamage_sound ", damage_sound)
			print("\thit_zone ", hit_zone_name)
			print("\thusk ", husk_value)

			if sound.parameters then
				for param_name, param_value in pairs(sound.parameters) do
					print("\t" .. param_name .. " ", param_value)
				end
			end
		end

		WwiseWorld.trigger_event(wwise_world, sound.event, source_id)
	end

	local particles = effect_settings.particles and effect_settings.particles[material]

	if particles then
		local normal_rotation = Quaternion.look(normal, Vector3.up())

		World.create_particles(world, particles, position, normal_rotation)
	end
end

EffectHelper.player_melee_hit_particles = function (world, particles_name, hit_position, hit_direction, damage_type, hit_unit)
	local hit_rotation = Quaternion.look(hit_direction)

	World.create_particles(world, particles_name, hit_position, hit_rotation)

	if damage_type and Managers.state.blood then
		Managers.state.blood:spawn_blood_ball(hit_position, hit_direction, damage_type, hit_unit)
	end
end

EffectHelper.play_melee_hit_effects = function (sound_event, world, hit_position, sound_type, husk, enemy_type, dealt_damage)
	local source_id, wwise_world = WwiseUtils.make_position_auto_source(world, hit_position)

	WwiseWorld.set_switch(wwise_world, "enemy_type", enemy_type, source_id)
	WwiseWorld.set_switch(wwise_world, "damage_sound", sound_type, source_id)
	WwiseWorld.set_switch(wwise_world, "husk", tostring(husk or false), source_id)
	WwiseWorld.trigger_event(wwise_world, sound_event, source_id)
end

EffectHelper.play_melee_hit_effects_enemy = function (sound_event, enemy_hit_sound, world, victim_unit, damage_type, is_husk)
	local source_id, wwise_world = WwiseUtils.make_unit_auto_source(world, victim_unit)

	WwiseWorld.set_switch(wwise_world, "husk", tostring(is_husk or false), source_id)
	WwiseWorld.set_switch(wwise_world, "enemy_hit_sound", enemy_hit_sound, source_id)
	WwiseWorld.trigger_event(wwise_world, sound_event, source_id)
end

EffectHelper.remote_play_surface_material_effects = function (effect_name, world, unit, position, rotation, normal, is_server)
	local network_manager = Managers.state.network
	local level = LevelHelper:current_level(world)
	local unit_level_index = Level.unit_index(level, unit)
	local unit_game_object_id = network_manager:unit_game_object_id(unit)
	local effect_name_id = NetworkLookup.surface_material_effects[effect_name]
	local network_safe_position = NetworkUtils.network_safe_position(position)

	if not network_safe_position then
		return
	end

	if unit_game_object_id then
		if is_server then
			network_manager.network_transmit:send_rpc_clients("rpc_surface_mtr_fx", effect_name_id, unit_game_object_id, position, rotation, Vector3.normalize(normal))
		else
			network_manager.network_transmit:send_rpc_server("rpc_surface_mtr_fx", effect_name_id, unit_game_object_id, position, rotation, Vector3.normalize(normal))
		end
	elseif unit_level_index then
		if is_server then
			network_manager.network_transmit:send_rpc_clients("rpc_surface_mtr_fx_lvl_unit", effect_name_id, unit_level_index, position, rotation, Vector3.normalize(normal))
		else
			network_manager.network_transmit:send_rpc_server("rpc_surface_mtr_fx_lvl_unit", effect_name_id, unit_level_index, position, rotation, Vector3.normalize(normal))
		end
	end
end

EffectHelper.remote_play_skinned_surface_material_effects = function (effect_name, world, position, rotation, normal, enemy_type, damage_sound, no_damage, hit_zone_name, is_server)
	local network_manager = Managers.state.network
	local effect_name_id = NetworkLookup.surface_material_effects[effect_name]
	local network_safe_position = NetworkUtils.network_safe_position(position)

	if not network_safe_position then
		return
	end

	if is_server then
		network_manager.network_transmit:send_rpc_clients("rpc_skinned_surface_mtr_fx", effect_name_id, position, rotation, Vector3.normalize(normal))
	else
		network_manager.network_transmit:send_rpc_server("rpc_skinned_surface_mtr_fx", effect_name_id, position, rotation, Vector3.normalize(normal))
	end
end

EffectHelper.create_surface_material_drawer_mapping = function (effect_name)
	local material_drawer_mapping = MaterialEffectMappings[effect_name].decal.material_drawer_mapping

	for _, material in ipairs(MaterialEffectSettings.material_contexts.surface_material) do
		local drawer

		if type(material_drawer_mapping[material]) == "string" then
			drawer = material_drawer_mapping[material]
		elseif type(material_drawer_mapping[material]) == "table" then
			local num_drawers = #material_drawer_mapping[material]
			local drawer_num = math.random(1, num_drawers)

			drawer = material_drawer_mapping[material][drawer_num]
		else
			drawer = nil
		end

		EffectHelper.temporary_material_drawer_mapping[material] = drawer
	end

	return EffectHelper.temporary_material_drawer_mapping
end

EffectHelper.flow_cb_play_footstep_surface_material_effects = function (effect_name, unit, object, foot_direction)
	local foot_node_index = Unit.node(unit, object)
	local raycast_offset = MaterialEffectSettings.footstep_raycast_offset
	local raycast_position = Unit.world_position(unit, foot_node_index) + Vector3(0, 0, raycast_offset)
	local raycast_direction = Vector3(0, 0, -1)
	local raycast_range = MaterialEffectSettings.footstep_raycast_max_range
	local sound_character = Unit.get_data(unit, "sound_character")
	local world = EffectHelper.world
	local physics_world = World.physics_world(world)
	local wwise_world = Wwise.wwise_world(world)
	local debug = script_data.debug_material_effects
	local hit, position, distance, normal, actor = PhysicsWorld.raycast(physics_world, raycast_position, raycast_direction, raycast_range, "closest", "types", "both", "collision_filter", "filter_ground_material_check")
	local husk = false

	if hit then
		local hit_unit = Actor.unit(actor)
		local rotation = Quaternion.look(Vector3(0, 0, -1), foot_direction)

		EffectHelper.play_surface_material_effects(effect_name, world, wwise_world, hit_unit, position, rotation, normal, sound_character, husk)
	else
		if debug then
			local drawer = Managers.state.debug:drawer({
				mode = "retained",
				name = "DEBUG_DRAW_IMPACT_DECAL_HIT"
			})

			drawer:vector(raycast_position, raycast_direction * raycast_range, Color(255, 255, 0, 0))
		end

		local effect_settings = MaterialEffectMappings[effect_name]
		local material = DefaultSurfaceMaterial
		local sound = effect_settings.sound and effect_settings.sound[material]

		if sound then
			local wwise_source_id, wwise_world = WwiseUtils.make_position_auto_source(world, raycast_position + raycast_direction * raycast_range)

			if debug then
				printf("[EffectHelper:play_surface_material_effects()] playing sound %s", sound.event)
				printf("   sound param: \"husk\", sound_value %q", husk and "true" or "false")
			end

			WwiseWorld.set_switch(wwise_world, "husk", husk and "true" or "false", wwise_source_id)

			if sound.parameters then
				for parameter_name, parameter_value in pairs(sound.parameters) do
					if debug then
						printf("   sound param: %q, sound_value %q", parameter_name, parameter_value)
					end

					WwiseWorld.set_switch(wwise_world, parameter_name, parameter_value, wwise_source_id)
				end
			end

			if sound_character then
				if debug then
					printf("   sound param: \"sound_character\", sound_value %q", sound_character)
				end

				WwiseWorld.set_switch(wwise_world, "character", sound_character, wwise_source_id)
			end

			WwiseWorld.trigger_event(wwise_world, sound.event, wwise_source_id)
		end
	end
end

local material = {
	"surface_material"
}

EffectHelper.query_material_surface = function (hit_unit, position, rotation)
	local query_forward = Quaternion.forward(rotation)
	local query_vector = query_forward * MaterialEffectSettings.material_query_depth
	local query_start_position = position - query_vector * 0.5
	local query_end_position = position + query_vector * 0.5

	return Unit.query_material(hit_unit, query_start_position, query_end_position, material)
end
