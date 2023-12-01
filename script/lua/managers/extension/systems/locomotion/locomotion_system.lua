-- chunkname: @script/lua/managers/extension/systems/locomotion/locomotion_system.lua

EngineOptimizedExtensions = false
EngineOptimized = false

require("script/lua/managers/extension/systems/locomotion/locomotion_templates_ai")
require("script/lua/managers/extension/systems/locomotion/locomotion_templates_ai_husk")

local LocomotionTemplates = LocomotionTemplates
local RPCS = {
	"rpc_set_animation_driven_script_movement",
	"rpc_set_script_driven",
	"rpc_set_animation_driven",
	"rpc_set_animation_translation_scale",
	"rpc_set_animation_rotation_scale",
	"rpc_set_affected_by_gravity",
	"rpc_teleport_unit_to",
	"rpc_constrain_ai"
}

class("LocomotionSystem", "ExtensionSystemBase")

LocomotionSystem.extension_list = {
	"AILocomotionExtension",
	"AIHuskLocomotionExtension"
}

LocomotionSystem.init = function (self, extension_system_creation_context, system_name, extension_list)
	LocomotionSystem.super.init(self, extension_system_creation_context, system_name, extension_list)

	if Managers.state.network then
		Managers.state.network:register_rpc_callbacks(self, unpack(RPCS))
	end

	self.world = extension_system_creation_context.world
	self.animation_lod_units = {}
	self.animation_lod_unit_current = nil
	self.lod0 = 0
	self.lod1 = 0
	self.current_physics_test_unit = nil
	self.player_units = {}
	self.template_data = {}

	local ai_system = Managers.state.extension:system("ai_system")
	local nav_world = ai_system:nav_world()

	for template_name, template in pairs(LocomotionTemplates) do
		if template_name ~= "AILocomotionExtensionC" then
			local data = {}

			template.init(data, nav_world)

			self.template_data[template_name] = data
		elseif template_name == "PlayerUnitLocomotionExtension" then
			local data = {}

			template.init(data, nav_world)

			self.template_data[template_name] = data
		end
	end

	if EngineOptimizedExtensions then
		if EngineOptimizedExtensions.init_husk_extensions then
			EngineOptimizedExtensions.init_husk_extensions()

			if GameSettingsDevelopment.use_engine_optimized_ai_locomotion then
				local physics_world = World.get_data(self.world, "physics_world")
				local game_session = Managers.state.network:game()

				EngineOptimizedExtensions.init_extensions(physics_world, GLOBAL_AI_NAVWORLD, game_session)
			end
		else
			EngineOptimizedExtensions.init_extensions()
		end

		if not GameSettingsDevelopment.use_engine_optimized_ai_locomotion then
			extensions.AILocomotionExtensionC = nil
		end
	end

	if EngineOptimized then
		EngineOptimized.bone_lod_init(GameSettingsDevelopment.bone_lod_husks.lod_out_range_sq, GameSettingsDevelopment.bone_lod_husks.lod_in_range_sq, GameSettingsDevelopment.bone_lod_husks.lod_multiplier)
	end
end

LocomotionSystem.destroy = function (self)
	if self.network_event_delegate then
		self.network_event_delegate:unregister(self)
	end

	if EngineOptimized then
		EngineOptimized.bone_lod_destroy()
	end

	if EngineOptimizedExtensions then
		if EngineOptimizedExtensions.destroy_husk_extensions then
			EngineOptimizedExtensions.destroy_husk_extensions()

			if GameSettingsDevelopment.use_engine_optimized_ai_locomotion then
				EngineOptimizedExtensions.destroy_extensions()
			end
		else
			EngineOptimizedExtensions.destroy_extensions()
		end
	end
end

LocomotionSystem.on_add_extension = function (self, world, unit, extension_name, extension_init_data)
	extension_init_data.system_data = self.template_data[extension_name]

	local extension = LocomotionSystem.super.on_add_extension(self, world, unit, extension_name, extension_init_data)

	return extension
end

LocomotionSystem.extensions_ready = function (self, world, unit, extension_name)
	local extension = ScriptUnit.extension(unit, "locomotion_system")

	if extension_name == "AILocomotionExtensionC" or extension_name == "AILocomotionExtension" or extension_name == "AIHuskLocomotionExtension" then
		local breed = ScriptUnit.extension(unit, "ai_system")._breed
		local bone_lod_level = breed.bone_lod_level

		if bone_lod_level > 0 and not script_data.bone_lod_disable then
			if EngineOptimized then
				extension.bone_lod_extension_id = EngineOptimized.bone_lod_register_extension(unit)
			end

			self.animation_lod_units[unit] = extension
			extension.bone_lod_level = bone_lod_level

			Unit.set_bones_lod(unit, 1)

			self.lod1 = self.lod1 + 1
		end

		extension.time_to_check = 0
	else
		self.player_units[unit] = extension
	end
end

LocomotionSystem.on_remove_extension = function (self, unit, extension_name)
	self:on_freeze_extension(unit, extension_name)
	LocomotionSystem.super.on_remove_extension(self, unit, extension_name)
end

LocomotionSystem.on_freeze_extension = function (self, unit, extension_name)
	if extension_name == "AILocomotionExtensionC" or extension_name == "AILocomotionExtension" or extension_name == "AIHuskLocomotionExtension" then
		local extension = self.animation_lod_units[unit]

		if extension then
			if EngineOptimized then
				EngineOptimized.bone_lod_unregister_extension(extension.bone_lod_extension_id)
			end

			self.animation_lod_units[unit] = nil
		end
	end
end

LocomotionSystem.update = function (self, dt, t)
	Profiler.start("LocomotionSystem")
	self:update_extensions(dt, t)
	Profiler.stop("LocomotionSystem")
end

LocomotionSystem.update_extensions = function (self, dt, t)
	Profiler.start("locomotion extension templates")

	for template_name, data in pairs(self.template_data) do
		Profiler.start(template_name)

		local template = LocomotionTemplates[template_name]

		template.update(data, t, dt)
		Profiler.stop(template_name)
	end

	Profiler.stop("locomotion extension templates")
end

LocomotionSystem.update_animation_lods = function (self)
	local player = Managers.player:local_player()
	local viewport_name = player.viewport_name
	local viewport = ScriptWorld.viewport(self.world, viewport_name)
	local camera = ScriptViewport.camera(viewport)

	EngineOptimized.bone_lod_update(self.world, camera)
end

LocomotionSystem.rpc_set_affected_by_gravity = function (self, sender, game_object_id, affected)
	local ai_system = Managers.state.extension:system("ai_system")
	local unit = ai_system:remote_unit(game_object_id)
	local locomotion_extension = ScriptUnit.extension(unit, "locomotion_system")

	locomotion_extension:set_affected_by_gravity(affected)
end

LocomotionSystem.rpc_set_animation_driven_movement = function (self, sender, game_object_id, animation_driven, script_driven_rotation, is_affected_by_gravity, position, rotation)
	local ai_system = Managers.state.extension:system("ai_system")
	local unit = ai_system:remote_unit(game_object_id)
	local locomotion_extension = ScriptUnit.extension(unit, "locomotion_system")

	locomotion_extension:set_animation_driven(animation_driven, is_affected_by_gravity, script_driven_rotation)

	if animation_driven then
		locomotion_extension:teleport_to(position, rotation, locomotion_extension:get_velocity())
	end
end

LocomotionSystem.rpc_set_animation_driven_script_movement = function (self, sender, game_object_id, position, rotation, is_affected_by_gravity)
	self:rpc_set_animation_driven_movement(sender, game_object_id, true, true, is_affected_by_gravity, position, rotation)
end

LocomotionSystem.rpc_set_animation_driven = function (self, sender, game_object_id, position, rotation, is_affected_by_gravity)
	self:rpc_set_animation_driven_movement(sender, game_object_id, true, false, is_affected_by_gravity, position, rotation)
end

LocomotionSystem.rpc_set_script_driven = function (self, sender, game_object_id, position, rotation, is_affected_by_gravity)
	self:rpc_set_animation_driven_movement(sender, game_object_id, false, true, is_affected_by_gravity)
end

LocomotionSystem.rpc_set_animation_translation_scale = function (self, sender, game_object_id, animation_translation_scale)
	local ai_system = Managers.state.extension:system("ai_system")
	local unit = ai_system:remote_unit(game_object_id)
	local locomotion_extension = ScriptUnit.extension(unit, "locomotion_system")

	locomotion_extension:set_animation_translation_scale(animation_translation_scale)
end

LocomotionSystem.rpc_set_animation_rotation_scale = function (self, sender, game_object_id, animation_rotation_scale)
	local ai_system = Managers.state.extension:system("ai_system")
	local unit = ai_system:remote_unit(game_object_id)
	local locomotion_extension = ScriptUnit.extension(unit, "locomotion_system")

	locomotion_extension:set_animation_rotation_scale(animation_rotation_scale)
end

LocomotionSystem.rpc_teleport_unit_to = function (self, sender, game_object_id, position, rotation)
	local ai_system = Managers.state.extension:system("ai_system")
	local unit = ai_system:remote_unit(game_object_id)
	local locomotion_extension = ScriptUnit.extension(unit, "locomotion_system")

	locomotion_extension:teleport_to(position, rotation)
end

LocomotionSystem.rpc_constrain_ai = function (self, sender, game_object_id, constrain, min, max)
	local ai_system = Managers.state.extension:system("ai_system")
	local unit = ai_system:remote_unit(game_object_id)
	local locomotion_extension = ScriptUnit.extension(unit, "locomotion_system")

	locomotion_extension:set_constrained(constrain, min, max)
end
