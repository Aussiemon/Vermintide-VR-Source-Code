-- chunkname: @script/lua/managers/hud/damage_hud.lua

require("settings/player_health_settings")
class("DamageHud")

DamageHud.init = function (self, world, gui)
	self._world = world
	self._gui = gui
end

DamageHud.update = function (self, dt, t)
	if self._damage_indicator then
		self:_update_damage_indicator(dt)
	end
end

DamageHud.add_damage_indicator = function (self, damage, params)
	local damage_indicator = self._damage_indicator or {}
	local start_alpha = PlayerHealthSettings.damage_indicator_start_alpha

	damage_indicator.alpha = start_alpha
	self._damage_indicator = damage_indicator
end

DamageHud._update_damage_indicator = function (self, dt)
	local damage_indicator = self._damage_indicator
	local fade_out_speed = PlayerHealthSettings.damage_indicator_fade_out_speed
	local alpha = damage_indicator.alpha - fade_out_speed * dt

	if alpha > 0 then
		local gui_size = Managers.state.hud.size
		local position = Vector2(0, 0)
		local size = Vector2(gui_size[1], gui_size[2])
		local color = Colors.get_color_with_alpha("red", alpha * 255)

		Gui.bitmap(self._gui, "white_dot_inverted", position, size, color)

		damage_indicator.alpha = alpha
	else
		self._damage_indicator = nil
	end
end

DamageHud.set_injury_level = function (self, injury_level)
	assert(PlayerHealthSettings.injury_levels[injury_level], "No such injury level")

	if injury_level == self._injury_level then
		return
	end

	local injury_level_data = PlayerHealthSettings.injury_levels[injury_level]
	local color_grading = injury_level_data.color_grading

	if color_grading then
		self:_set_color_grading(color_grading)
	else
		self:_disable_color_grading()
	end

	self._injury_level = injury_level
end

DamageHud._set_color_grading = function (self, color_grading)
	local world = self._world
	local data_component_manager = stingray.EntityManager.data_component(world)
	local all_entity_handles = stingray.World.entities(world)

	for _, entity_handle in ipairs(all_entity_handles) do
		local all_data_component_handles = {
			stingray.DataComponent.instances(data_component_manager, entity_handle)
		}

		for _, data_component_handle in ipairs(all_data_component_handles) do
			local shading_environment_mapping_resource_name = stingray.DataComponent.get_property(data_component_manager, entity_handle, data_component_handle, {
				"shading_environment_mapping"
			})

			if shading_environment_mapping_resource_name == "core/stingray_renderer/shading_environment_components/color_grading" then
				local shading_env_entity = entity_handle
				local color_grading_component = data_component_handle
				local enabled_value = true
				local color_grading_map_value = color_grading

				stingray.DataComponent.set_property(data_component_manager, shading_env_entity, color_grading_component, {
					"color_grading_enabled"
				}, enabled_value)
				stingray.DataComponent.set_property(data_component_manager, shading_env_entity, color_grading_component, {
					"color_grading_map"
				}, color_grading_map_value)
			end
		end
	end
end

DamageHud._disable_color_grading = function (self)
	local world = self._world
	local data_component_manager = stingray.EntityManager.data_component(world)
	local all_entity_handles = stingray.World.entities(world)

	for _, entity_handle in ipairs(all_entity_handles) do
		local all_data_component_handles = {
			stingray.DataComponent.instances(data_component_manager, entity_handle)
		}

		for _, data_component_handle in ipairs(all_data_component_handles) do
			local shading_environment_mapping_resource_name = stingray.DataComponent.get_property(data_component_manager, entity_handle, data_component_handle, {
				"shading_environment_mapping"
			})

			if shading_environment_mapping_resource_name == "core/stingray_renderer/shading_environment_components/color_grading" then
				local shading_env_entity = entity_handle
				local color_grading_component = data_component_handle
				local enabled_value = false

				stingray.DataComponent.set_property(data_component_manager, shading_env_entity, color_grading_component, {
					"color_grading_enabled"
				}, enabled_value)
			end
		end
	end
end
