-- chunkname: @script/lua/flow_callbacks.lua

ProjectFlowCallbacks = ProjectFlowCallbacks or {}

ProjectFlowCallbacks.example = function (t)
	local message = t.Text or ""

	print("Example Node Message: " .. message)
end

ProjectFlowCallbacks.flow_callback_set_play_area_location = function (params)
	local unit = params.unit
	local node = params.node

	if unit then
		Managers.vr:set_tracking_space_unit(unit, node)
	else
		Managers.vr:set_tracking_space_pose(Matrix4x4.identity())
	end
end

ProjectFlowCallbacks.flow_callback_load_next_level = function (params)
	Managers.state.event:trigger("change_level")
end

ProjectFlowCallbacks.flow_callback_register_sound_environment = function (params)
	local volume_name = params.VolumeName
	local prio = params.Prio
	local ambient_sound_event = params.AmbientSoundEvent
	local fade_time = params.FadeTime
	local aux_bus_name = params.AuxBusName
	local environment_state = params.EnvironmentState
	local extension_manager = Managers.state.extension

	if extension_manager then
		local sound_environment_system = extension_manager:system("sound_environment_system")

		sound_environment_system:register_sound_environment(volume_name, prio, ambient_sound_event, fade_time, aux_bus_name, environment_state)
	end
end

ProjectFlowCallbacks.flow_callback_force_terror_event = function (params)
	local event_name = params.EventType

	TerrorEventMixer.start_event(event_name)
end

ProjectFlowCallbacks.flow_callback_stop_terror_event = function (params)
	local event_name = params.EventType

	TerrorEventMixer.stop_event(event_name)
end

ProjectFlowCallbacks.flow_callback_kill_enemies_within_radius = function (params)
	do return end

	local position = params.Position
	local radius = params.Radius
	local world = Application.flow_callback_context_world()
	local physics_world = World.physics_world(world)
	local hit_units = {}
	local hit_enemies = {}

	local function overlap_callback(actors)
		for _, actor in pairs(actors) do
			local unit = Actor.unit(actor)

			if unit and not hit_units[unit] then
				hit_units[unit] = true

				if Unit.get_data(unit, "enemy") then
					table.insert(hit_enemies, unit)
				end
			end
		end

		for _, enemy in pairs(hit_enemies) do
			Unit.flow_event(enemy, "shot")
		end
	end

	PhysicsWorld.overlap(physics_world, overlap_callback, "shape", "sphere", "position", position, "size", radius, "collision_filter", "filter_melee")
end

local empty_table = {}

ProjectFlowCallbacks.flow_callback_hit_unit = function (params)
	local unit = params.unit
	local has_health_extension = ScriptUnit.has_extension(unit, "health_system")

	if not has_health_extension then
		return
	end

	local health_extension = ScriptUnit.extension(unit, "health_system")

	health_extension:add_damage(1, empty_table)
end

ProjectFlowCallbacks.flow_callback_add_unit_extensions = function (params)
	local unit = params.unit
	local unit_level_id = tonumber(params.unit_level_id)
	local breed_name = params.breed
	local breed = Breeds[breed_name]
	local base_unit_name = breed.base_unit
	local extension_manager = Managers.state.extension
	local ai_system = extension_manager:system("ai_system")
	local nav_world = ai_system:nav_world()
	local max_health = Managers.state.spawn:breed_max_health(breed_name)
	local extension_data = {
		HealthExtension = {
			health = max_health,
			ragdoll_on_death = breed.ragdoll_on_death,
			breed_name = breed_name
		},
		AIHitReactionExtension = {
			breed_name = breed_name
		},
		AILevelUnitBaseExtension = {
			breed = breed,
			unit_level_id = unit_level_id
		}
	}

	if params.add_outline then
		extension_data.EnemyOutlineExtension = {}
	end

	Unit.set_data(unit, "breed", breed)

	local world = Application.flow_callback_context_world()

	Managers.state.spawn:_add_unit_extensions(world, unit, extension_data)
end

ProjectFlowCallbacks.flow_callback_enable_highlight = function (params)
	local unit = params.unit
	local outline_extension = Managers.state.extension:system("outline_system")

	if outline_extension then
		outline_extension:enable_highlight(unit)
	end
end

ProjectFlowCallbacks.flow_callback_disable_highlight = function (params)
	local unit = params.unit
	local outline_extension = Managers.state.extension:system("outline_system")

	if outline_extension then
		outline_extension:disable_highlight(unit)
	end
end

ProjectFlowCallbacks.flow_callback_add_target_unit = function (params)
	local unit = params.unit
	local target_unit = params.target_unit
	local hit_flow_event = params.hit_flow_event

	Unit.set_data(unit, "target_unit", target_unit)
	Unit.set_data(unit, "hit_flow_event", hit_flow_event)
end

ProjectFlowCallbacks.flow_callback_animation_callback = function (params)
	local unit = params.Unit

	if not unit or not Unit.alive(unit) then
		return
	end

	local callback = params.Callback
	local param = params.Param1
	local is_server = true
	local in_session = Managers.state.network and Managers.state.network:state() == "in_session"

	if in_session then
		is_server = Managers.lobby.server
	end

	local cb

	if is_server then
		cb = AnimationCallbackTemplates.server[callback]

		if cb then
			cb(unit, param)
		end
	end

	cb = AnimationCallbackTemplates.client[callback]

	if cb then
		cb(unit, param)
	end
end

ProjectFlowCallbacks.flow_callback_play_footstep_surface_material_effects = function (params)
	EffectHelper.flow_cb_play_footstep_surface_material_effects(params.EffectName, params.Unit, params.Object, params.FootDirection)
end

ProjectFlowCallbacks.flow_callback_end_conditions_met = function (params)
	local defeat = params.Defeat
	local result = defeat and "defeat" or "victory"

	Managers.state.game_mode:set_end_conditions_met(result)
end

ProjectFlowCallbacks.flow_callback_start_conditions_met = function (params)
	Managers.state.game_mode:set_start_conditions_met()
end

function flow_callback_play_surface_material_effect(params)
	local hit_unit = params.HitUnit
	local world = Unit.world(hit_unit)
	local wwise_world = Wwise.wwise_world(world)
	local sound_character
	local normal = params.Normal
	local rotation = Quaternion.look(normal, Vector3.up())

	EffectHelper.play_surface_material_effects(params.EffectName, world, wwise_world, hit_unit, params.Position, rotation, normal, sound_character, params.Husk)
end

ProjectFlowCallbacks.flow_callback_set_interactable = function (params)
	local unit = params.unit
	local is_interactable = params.set_interactable
	local interactable_extension = ScriptUnit.extension(unit, "interactable_system")

	if interactable_extension then
		interactable_extension:set_interactable(is_interactable)
	end
end

ProjectFlowCallbacks.flow_callback_reset_lever = function (params)
	local unit = params.unit
	local lever_extension = ScriptUnit.extension(unit, "interactable_system")

	lever_extension:flow_callback_reset()
end

ProjectFlowCallbacks.flow_callback_ragdoll = function (params)
	assert(params.unit)

	local unit = params.unit
	local ragdoll_system = Managers.state.extension:system("ragdoll_system")

	ragdoll_system:ragdoll_unit_and_add_to_pool(unit)
end

ProjectFlowCallbacks.get_level_survival_time = function (params)
	local level_name = params.level_name
	local level_settings = LevelSettings.levels[level_name]
	local time = Game.startup_commands.survival_time or level_settings.survival_time or 0

	return {
		survival_time = time
	}
end

ProjectFlowCallbacks.vibrate_controller = function (params)
	local length = params.length
	local strength = params.strength
	local controller = params.controller

	assert(controller == "left" or controller == "right")

	local vr_controller = Managers.vr:get_vr_controller()
	local wand = vr_controller:get_wand(controller)
	local input = wand:input()

	input:vibrate(length, strength)
end
