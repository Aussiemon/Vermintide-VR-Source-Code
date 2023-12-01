-- chunkname: @script/lua/utils/ai_utils.lua

require("settings/unit_variation_settings")

local unit_get_data = Unit.get_data
local script_data = script_data
local unit_alive = Unit.alive

AiUtils = AiUtils or {}

AiUtils.get_actual_attacker_unit = function (attacker_unit)
	if ScriptUnit.has_extension(attacker_unit, "projectile_system") and not ScriptUnit.has_extension(attacker_unit, "limited_item_track_system") then
		local projectile_extension = ScriptUnit.extension(attacker_unit, "projectile_system")

		attacker_unit = projectile_extension.owner_unit
	end

	return attacker_unit
end

AiUtils.unit_alive = function (unit)
	if not unit_alive(unit) then
		return false
	end

	local health_extension = ScriptUnit.has_extension(unit, "health_system")
	local is_alive = health_extension and health_extension:is_alive()

	return is_alive
end

AiUtils.unit_knocked_down = function (unit)
	if not unit_alive(unit) then
		return false
	end

	if not ScriptUnit.has_extension(unit, "status_system") then
		return false
	end

	local status_system = ScriptUnit.extension(unit, "status_system")
	local is_knocked_down = status_system:is_knocked_down()

	return is_knocked_down
end

AiUtils.get_default_breed_move_speed = function (unit, blackboard)
	local move_speed
	local breed = blackboard.breed
	local walk_only = breed.walk_only

	if blackboard.is_passive or walk_only then
		move_speed = breed.passive_walk_speed or breed.walk_speed
	else
		move_speed = blackboard.run_speed
	end

	return move_speed
end

AiUtils.initialize_cost_table = function (navtag_layer_cost_table, allowed_layers)
	for layer_id, layer_name in ipairs(LAYER_ID_MAPPING) do
		local layer_cost = allowed_layers[layer_name]

		if layer_cost == 0 or layer_cost == nil then
			GwNavTagLayerCostTable.forbid_layer(navtag_layer_cost_table, layer_id)
		else
			GwNavTagLayerCostTable.allow_layer(navtag_layer_cost_table, layer_id)
			GwNavTagLayerCostTable.set_layer_cost_multiplier(navtag_layer_cost_table, layer_id, layer_cost)
		end
	end
end

AiUtils.kill_unit = function (victim_unit, attacker_unit, hit_zone_name, damage_type, damage_direction)
	local damage = 255
	local health_extension = ScriptUnit.extension(victim_unit, "health_system")
	local no_score, no_peer_id = true
	local params = {
		hit_node_index = 1,
		score_disabled = true,
		hit_force = 1,
		hit_direction = Vector3(0, 0, -1)
	}

	health_extension:add_damage(damage, params)
end

local function tint_part(unit, variation)
	local variable_value = math.random(variation.min, variation.max)
	local variable_name = variation.variable
	local materials = variation.materials
	local meshes = variation.meshes
	local num_materials = #materials
	local Mesh_material = Mesh.material
	local Mesh_has_material = Mesh.has_material
	local Material_set_scalar = Material.set_scalar
	local index_offset = Script.index_offset()
	local end_offset = 1 - index_offset

	if not meshes then
		for i = index_offset, Unit.num_meshes(unit) - end_offset do
			local current_mesh = Unit.mesh(unit, i)

			for material_i = 1, num_materials do
				local material = materials[material_i]

				if Mesh_has_material(current_mesh, material) then
					local current_material = Mesh_material(current_mesh, material)

					Material_set_scalar(current_material, variable_name, variable_value)
				end
			end
		end
	else
		for i = 1, #meshes do
			local mesh = meshes[i]
			local current_mesh = Unit.mesh(unit, mesh)

			for material_i = 1, num_materials do
				local material = materials[material_i]
				local current_material = Mesh_material(current_mesh, material)

				Material_set_scalar(current_material, variable_name, variable_value)
			end
		end
	end
end

local function enable_parts(unit, variationsettings, body_parts)
	for i = 1, #body_parts do
		local body_part = body_parts[i]
		local part_settings = variationsettings.body_parts[body_part]
		local variation = part_settings[math.random(#part_settings)]

		if variation.group then
			Unit.set_visibility(unit, variation.group, true)

			local tint_variation = variationsettings.material_variations[variation.group]

			if tint_variation then
				tint_part(unit, tint_variation)
			end

			if variation.enables then
				enable_parts(unit, variationsettings, variation.enables)
			end
		end
	end
end

AiUtils.set_unit_variation = function (unit, variation)
	local variationsettings = UnitVariationSettings[variation]

	tint_part(unit, variationsettings.material_variations.skin_tint)

	if variationsettings.material_variations.cloth_tint ~= nil then
		tint_part(unit, variationsettings.material_variations.cloth_tint)
	end

	Unit.set_visibility(unit, "all", false)
	enable_parts(unit, variationsettings, variationsettings.enabled_from_start)
end

AiUtils.check_parry = function (attacking_unit, target_unit)
	if attacking_unit == target_unit then
		return false
	end

	local entities = Managers.state.extension:get_entities("ParryExtension")

	for unit, parry_extension in pairs(entities) do
		repeat
			local is_parrying = parry_extension:is_parrying()

			if not is_parrying then
				break
			end

			local blackboard = Unit.get_data(attacking_unit, "blackboard")

			blackboard.blocked = true

			return true
		until true
	end

	return false
end
