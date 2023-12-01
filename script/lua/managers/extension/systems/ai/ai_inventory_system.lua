-- chunkname: @script/lua/managers/extension/systems/ai/ai_inventory_system.lua

require("settings/ai_inventory_templates")
require("script/lua/unit_extensions/ai/ai_inventory_extension")

local RPCS = {
	"rpc_ai_inventory_wield",
	"rpc_ai_drop_single_item",
	"rpc_ai_show_single_item"
}

class("AIInventorySystem", "ExtensionSystemBase")

AIInventorySystem.extension_list = {
	"AIInventoryExtension"
}

AIInventorySystem.init = function (self, extension_system_creation_context, system_name, extension_list)
	AIInventorySystem.super.init(self, extension_system_creation_context, system_name, extension_list)

	self.is_server = extension_system_creation_context.is_server
	self.unit_extension_data = {}
	self.units_to_wield = {}
	self.units_to_wield_n = 0
	self.units_to_drop = {}
	self.units_to_drop_n = 0
end

AIInventorySystem.destroy = function (self)
	if self.network_event_delegate then
		self.network_event_delegate:unregister(self)
	end
end

AIInventorySystem.drop_item = function (self, unit)
	self.units_to_drop_n = self.units_to_drop_n + 1
	self.units_to_drop[self.units_to_drop_n] = unit
end

local function link_unit(attachment_node_linking, world, target, source)
	for i, attachment_nodes in ipairs(attachment_node_linking) do
		local source_node = attachment_nodes.source
		local target_node = attachment_nodes.target
		local source_node_index = type(source_node) == "string" and Unit.node(source, source_node) or source_node
		local target_node_index = type(target_node) == "string" and Unit.node(target, target_node) or target_node

		World.link_unit(world, target, target_node_index, source, source_node_index)
	end
end

local dummy_input = {}

AIInventorySystem.on_add_extension = function (self, world, unit, extension_name, extension_init_data)
	local extension

	assert(next(extension_init_data) ~= nil, "AI's unit template specifies inventory extension but no init data was sent")

	extension_init_data.world = self._world
	extension_init_data.is_server = self.is_server
	extension = AIInventoryExtension:new(unit, extension_init_data)

	ScriptUnit.set_extension(unit, "ai_inventory_system", extension, dummy_input)

	self.unit_extension_data[unit] = extension

	self:inventory_wield(unit)

	return extension
end

AIInventorySystem.on_remove_extension = function (self, unit, extension_name)
	local units_to_wield = self.units_to_wield
	local units_to_wield_n = self.units_to_wield_n
	local i = 1

	while i <= units_to_wield_n do
		if unit == units_to_wield[i] then
			units_to_wield[i] = units_to_wield[units_to_wield_n]
			units_to_wield_n = units_to_wield_n - 1
		else
			i = i + 1
		end
	end

	self.units_to_wield_n = units_to_wield_n

	local units_to_drop = self.units_to_drop
	local units_to_drop_n = self.units_to_drop_n

	i = 1

	while i <= units_to_drop_n do
		if unit == units_to_drop[i] then
			units_to_drop[i] = units_to_drop[units_to_drop_n]
			units_to_drop_n = units_to_drop_n - 1
		else
			i = i + 1
		end
	end

	self.units_to_drop_n = units_to_drop_n

	ScriptUnit.remove_extension(unit, self.NAME)
end

AIInventorySystem.update = function (self, context, t, dt)
	local world = self._world
	local units_to_wield = self.units_to_wield
	local units_to_wield_n = self.units_to_wield_n

	for i = 1, units_to_wield_n do
		local unit = units_to_wield[i]
		local extension = self.unit_extension_data[unit]

		extension.wielded = true

		local inventory_item_definitions = extension.inventory_item_definitions
		local inventory_item_units = extension.inventory_item_units
		local inventory_items_n = extension.dropped and 0 or extension.inventory_items_n

		for j = 1, inventory_items_n do
			local item = inventory_item_definitions[j]
			local attachment_node_linking = item.attachment_node_linking

			if attachment_node_linking.wielded then
				local item_unit = inventory_item_units[j]

				link_unit(attachment_node_linking.wielded, world, item_unit, unit)
			end
		end
	end

	self.units_to_wield_n = 0

	local units_to_drop = self.units_to_drop
	local units_to_drop_n = self.units_to_drop_n

	for i = 1, units_to_drop_n do
		local unit = units_to_drop[i]
		local extension = self.unit_extension_data[unit]

		assert(extension.dropped == nil)

		extension.dropped = true

		local inventory_item_definitions = extension.inventory_item_definitions
		local inventory_items_n = extension.inventory_items_n

		for j = 1, inventory_items_n do
			extension:drop_single_item(j)
		end

		if script_data.ai_debug_inventory then
			printf("[AIInventorySystem] unit[%s] dropping all items", tostring(unit))
		end
	end

	self.units_to_drop_n = 0
end

AIInventorySystem.rpc_ai_inventory_wield = function (self, sender, go_id)
	local unit = self.unit_storage:unit(go_id)

	if unit == nil then
		return
	end

	self.units_to_wield_n = self.units_to_wield_n + 1
	self.units_to_wield[self.units_to_wield_n] = unit
end

AIInventorySystem.inventory_wield = function (self, unit)
	assert(unit)

	self.units_to_wield_n = self.units_to_wield_n + 1
	self.units_to_wield[self.units_to_wield_n] = unit
end

AIInventorySystem.rpc_ai_drop_single_item = function (self, sender, unit_id, item_inventory_index)
	local unit = self.unit_storage:unit(unit_id)

	if unit == nil then
		return
	end

	local ai_inventory_extension = ScriptUnit.extension(unit, "ai_inventory_system")

	ai_inventory_extension:drop_single_item(item_inventory_index)
end

AIInventorySystem.rpc_ai_show_single_item = function (self, sender, unit_id, item_inventory_index, show)
	local unit = self.unit_storage:unit(unit_id)

	if unit == nil then
		return
	end

	local ai_inventory_extension = ScriptUnit.extension(unit, "ai_inventory_system")

	ai_inventory_extension:show_single_item(item_inventory_index, show)
end

AIInventorySystem.hot_join_sync = function (self, sender)
	for unit, extension in pairs(self.unit_extension_data) do
		extension:hot_join_sync(sender)
	end
end
