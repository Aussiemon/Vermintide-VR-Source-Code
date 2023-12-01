-- chunkname: @settings/ai_inventory_templates.lua

require("settings/attachment_node_linking")

local items = {}

items.wpn_skaven_sword_01 = {
	unit_name = "units/weapons/enemy/wpn_skaven_short_sword/wpn_skaven_short_sword",
	attachment_node_linking = AttachmentNodeLinking.ai_sword
}
items.wpn_skaven_triangle_shield = {
	drop_on_hit = true,
	unit_name = "units/weapons/enemy/wpn_skaven_triangle_shield/wpn_skaven_triangle_shield",
	attachment_node_linking = AttachmentNodeLinking.ai_shield
}
items.wpn_skaven_halberd_41 = {
	drop_on_hit = true,
	unit_name = "units/weapons/enemy/wpn_skaven_set/wpn_skaven_halberd_41",
	attachment_node_linking = AttachmentNodeLinking.ai_spear
}

local item_categories = {}

item_categories.sword = {
	items.wpn_skaven_sword_01
}
item_categories.halberd = {
	items.wpn_skaven_halberd_41
}
item_categories.shield = {
	items.wpn_skaven_triangle_shield
}
InventoryConfigurations = {}
InventoryConfigurations.empty = {
	anim_state_event = "to_sword",
	items = {}
}
InventoryConfigurations.sword = {
	enemy_hit_sound = "sword",
	anim_state_event = "to_sword",
	items = {
		item_categories.sword
	}
}
InventoryConfigurations.halberd = {
	enemy_hit_sound = "spear",
	anim_state_event = "to_spear",
	items = {
		item_categories.halberd
	}
}
InventoryConfigurations.sword_and_shield = {
	enemy_hit_sound = "sword",
	anim_state_event = "to_shield_1h",
	items = {
		item_categories.sword,
		item_categories.shield
	}
}
AIInventoryTemplates = {}

local melee_configurations = {
	"sword"
}

AIInventoryTemplates.random_melee = function ()
	local index = math.random(1, #melee_configurations)
	local config_name = melee_configurations[index]

	return config_name
end

AIInventoryTemplates.default = function ()
	return AIInventoryTemplates.random_melee()
end

for category_name, category in pairs(item_categories) do
	category.count = #category
	category.name = category_name
end

for config_name, config in pairs(InventoryConfigurations) do
	config.items_n = #config.items

	assert(AIInventoryTemplates[config_name] == nil, "Can't override configuration based templates")

	AIInventoryTemplates[config_name] = function ()
		return config_name
	end
end
