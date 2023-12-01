-- chunkname: @script/lua/managers/extension/systems/outlines/outline_system.lua

require("settings/outline_settings")
class("OutlineSystem", "ExtensionSystemBase")

OutlineSystem.extension_list = {
	"ArrowOutlineExtension",
	"BowOutlineExtension",
	"HandgunOutlineExtension",
	"StaffOutlineExtension",
	"InteractableOutlineExtension",
	"LeverOutlineExtension",
	"RapierOutlineExtension",
	"EnemyOutlineExtension"
}

OutlineSystem.init = function (self, extension_system_creation_context, system_name, extension_list)
	OutlineSystem.super.init(self, extension_system_creation_context, system_name, extension_list)

	self.world = extension_system_creation_context.world
	self.physics_world = World.get_data(self.world, "physics_world")
	self.unit_extension_data = {}
	self.units = {}
	self.current_index = 0
end

OutlineSystem.on_add_extension = function (self, world, unit, extension_name)
	local extension = {}

	if extension_name == "ArrowOutlineExtension" then
		extension.color = OutlineSettings.colors.arrow
		extension.distance = OutlineSettings.ranges.arrow
		extension.method = "within_distance_hand"
		extension.branch_key = "rimlight_unit"
		extension.mask = 1
		extension.enabled = true
		extension.unit_node = 1
	end

	if extension_name == "BowOutlineExtension" then
		extension.color = OutlineSettings.colors.bow
		extension.distance = OutlineSettings.ranges.bow
		extension.method = "within_distance"
		extension.branch_key = "rimlight_unit"
		extension.mask = 1
		extension.enabled = true
	end

	if extension_name == "HandgunOutlineExtension" then
		extension.color = OutlineSettings.colors.handgun
		extension.distance = OutlineSettings.ranges.handgun
		extension.method = "within_distance"
		extension.branch_key = "rimlight_unit"
		extension.mask = 1
		extension.enabled = true
	end

	if extension_name == "StaffOutlineExtension" then
		extension.color = OutlineSettings.colors.staff
		extension.distance = OutlineSettings.ranges.staff
		extension.method = "within_distance"
		extension.branch_key = "rimlight_unit"
		extension.mask = 1
		extension.enabled = true
	end

	if extension_name == "InteractableOutlineExtension" then
		extension.color = OutlineSettings.colors.interactable
		extension.distance = OutlineSettings.ranges.interactable
		extension.method = "within_distance"
		extension.branch_key = "rimlight_unit"
		extension.mask = 1
		extension.enabled = true
	end

	if extension_name == "LeverOutlineExtension" then
		extension.color = OutlineSettings.colors.lever
		extension.distance = OutlineSettings.ranges.lever
		extension.method = "always"
		extension.branch_key = "rimlight_unit"
		extension.mask = 1
		extension.enabled = false
		extension.mesh_name = "g_drachenfels_lever_01_arm"
	end

	if extension_name == "RapierOutlineExtension" then
		extension.color = OutlineSettings.colors.rapier
		extension.distance = OutlineSettings.ranges.rapier
		extension.method = "within_distance"
		extension.branch_key = "rimlight_unit"
		extension.mask = 1
		extension.enabled = true
	end

	if extension_name == "EnemyOutlineExtension" then
		extension.color = OutlineSettings.colors.enemy
		extension.distance = OutlineSettings.ranges.enemy
		extension.method = "always"
		extension.branch_key = "rimlight_unit"
		extension.mask = 1
		extension.enabled = true
	end

	extension.set_method = function (method)
		extension.method = method
	end

	extension.set_outlined = function (outlined)
		if outlined then
			local mesh_name = extension.mesh_name
			local color = Vector4(unpack(extension.color))

			self:outline_unit(unit, extension.branch_key, color, extension.mask, true, mesh_name)

			extension.outlined = true
		else
			local mesh_name = extension.mesh_name
			local color = Vector4(unpack(extension.color))

			self:outline_unit(unit, extension.branch_key, color, extension.mask, false, mesh_name)

			extension.outlined = false
		end
	end

	extension.outlined = false

	ScriptUnit.set_extension(unit, "outline_system", extension, {})

	self.unit_extension_data[unit] = extension
	self.units[#self.units + 1] = unit

	return extension
end

OutlineSystem.on_remove_extension = function (self, unit, extension_name)
	self.unit_extension_data[unit] = nil

	table.remove(self.units, table.find(self.units, unit))
	ScriptUnit.remove_extension(unit, self.NAME)
end

OutlineSystem.set_vr_controller = function (self, vr_controller)
	self._vr_controller = vr_controller
end

OutlineSystem.update = function (self, dt, t)
	if #self.units == 0 then
		return
	end

	if script_data.disable_outlines then
		return
	end

	for index, unit in pairs(self.units) do
		repeat
			local extension = self.unit_extension_data[unit]

			if not extension then
				break
			end

			local method = extension.method

			if not method then
				break
			end

			local already_outlined = extension.outlined
			local outline_enabled = extension.enabled
			local do_outline = self[method](self, unit, extension)
			local mesh_name = extension.mesh_name

			if do_outline and outline_enabled then
				if not already_outlined then
					local mesh_name = extension.mesh_name
					local color = Vector4(unpack(extension.color))
					local mask = extension.mask

					self:outline_unit(unit, extension.branch_key, color, mask, true, mesh_name)

					extension.outlined = true
				end

				break
			end

			if already_outlined then
				local mesh_name = extension.mesh_name
				local color = Vector4(unpack(extension.color))
				local mask = extension.mask

				self:outline_unit(unit, extension.branch_key, color, mask, false, mesh_name)

				extension.outlined = false
			end
		until true
	end
end

OutlineSystem.outline_unit = function (self, unit, branch_key, color, mask, do_outline, mesh_name)
	if mesh_name then
		local mesh = Unit.mesh(unit, mesh_name)

		if mesh then
			Mesh.set_shader_pass_flag(mesh, branch_key, do_outline)

			local num_materials = Mesh.num_materials(mesh)

			for i = 1, num_materials do
				local material = Mesh.material(mesh, i)

				Material.set_shader_pass_flag(material, branch_key, do_outline)
				Material.set_vector4(material, "dev_selection_color", color)
				Material.set_scalar(material, "dev_selection_mask", mask)
			end
		else
			printf("tried to set shader pass flag for nonexisting mesh (%s) in unit %s", mesh_name, tostring(unit))
		end
	else
		local num_meshes = Unit.num_meshes(unit)

		for i = 1, num_meshes do
			local mesh = Unit.mesh(unit, i)

			Mesh.set_shader_pass_flag(mesh, branch_key, do_outline)

			local num_materials = Mesh.num_materials(mesh)

			for i = 1, num_materials do
				local material = Mesh.material(mesh, i)

				Material.set_shader_pass_flag(material, branch_key, do_outline)
				Material.set_vector4(material, "dev_selection_color", color)
				Material.set_scalar(material, "dev_selection_mask", mask)
			end
		end
	end
end

OutlineSystem.distance_to_unit = function (self, unit, wand_hand, unit_node, wand_node, back)
	local wand = self._vr_controller:get_wand(wand_hand)
	local wand_input = wand:input()
	local wand_position = wand_input:wand_unit_position(wand_node)
	local distance = math.huge

	if unit_node then
		local unit_position = Unit.world_position(unit, unit_node)

		distance = Vector3.distance(wand_position, unit_position)
	else
		local pose, half_extents = Unit.box(unit)
		local unit_center = Matrix4x4.translation(pose)

		distance = Vector3.distance(wand_position, unit_center)
	end

	return distance
end

OutlineSystem.enable_highlight = function (self, unit)
	local extension = self.unit_extension_data[unit]

	if extension then
		extension.enabled = true
	end
end

OutlineSystem.disable_highlight = function (self, unit)
	local extension = self.unit_extension_data[unit]

	if extension then
		extension.enabled = false
	end
end

OutlineSystem.never = function (self, unit, extension)
	return false
end

OutlineSystem.always = function (self, unit, extension)
	return true
end

OutlineSystem.within_distance = function (self, unit, extension)
	local distance = extension.distance
	local left_distance = self:distance_to_unit(unit, "left")
	local right_distance = self:distance_to_unit(unit, "right")

	return left_distance <= distance or right_distance <= distance
end

OutlineSystem.within_distance_hand = function (self, unit, extension)
	local distance = extension.distance
	local hand = extension.hand

	if not hand then
		return false
	end

	local hand_distance = self:distance_to_unit(unit, hand, extension.unit_node, extension.wand_node)

	return hand_distance <= distance
end

OutlineSystem.outside_distance = function (self, unit, extension)
	local distance = extension.distance
	local left_distance = self:distance_to_unit(unit, "left")
	local right_distance = self:distance_to_unit(unit, "right")

	return distance < left_distance or distance < right_distance
end
