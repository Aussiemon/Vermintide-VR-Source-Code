-- chunkname: @settings/breeds.lua

require("settings/smartobject_settings")
require("settings/nav_tag_volume_settings")
require("settings/network_lookup")

Breeds = Breeds or {}
BreedLookup = {}
BreedReverseLookup = {}
BreedActions = BreedActions or {}
BreedHitZonesLookup = BreedHitZonesLookup or {}

dofile("settings/breeds/breed_skaven_clan_rat")
dofile("settings/breeds/breed_skaven_storm_vermin")
dofile("settings/breeds/breed_skaven_rat_ogre")

for breed_name, breed_data in pairs(Breeds) do
	local lookup = BreedHitZonesLookup[breed_name]

	if lookup then
		breed_data.hit_zones_lookup = lookup

		assert(breed_data.debug_color, "breed needs a debug color")
	end
end

for breed_name, breed in pairs(Breeds) do
	local index = #BreedLookup + 1

	BreedLookup[index] = breed_name
	BreedReverseLookup[breed_name] = index
end

init_lookup_table(BreedLookup, "BreedLookup")
init_lookup_table(BreedReverseLookup, "BreedReverseLookup")

for breed_name, breed_actions in pairs(BreedActions) do
	for action_name, action_data in pairs(breed_actions) do
		action_data.name = action_name
	end
end

LAYER_ID_MAPPING = {
	"ledges",
	"ledges_with_fence",
	"jumps",
	"doors",
	"planks",
	"bot_poison_wind",
	"teleporters"
}
NAV_TAG_VOLUME_LAYER_COST_AI = NAV_TAG_VOLUME_LAYER_COST_AI or {}
NAV_TAG_VOLUME_LAYER_COST_BOTS = NAV_TAG_VOLUME_LAYER_COST_BOTS or {}

for _, layer_name in ipairs(NavTagVolumeLayers) do
	LAYER_ID_MAPPING[#LAYER_ID_MAPPING + 1] = layer_name
	NAV_TAG_VOLUME_LAYER_COST_AI[layer_name] = NAV_TAG_VOLUME_LAYER_COST_AI[layer_name] or 1
	NAV_TAG_VOLUME_LAYER_COST_BOTS[layer_name] = NAV_TAG_VOLUME_LAYER_COST_BOTS[layer_name] or 1
end

for k, v in ipairs(LAYER_ID_MAPPING) do
	LAYER_ID_MAPPING[v] = k
end

local PerceptionTypes = {
	perception_pack_master = true,
	perception_no_seeing = true,
	perception_regular = true,
	perception_rat_ogre = true,
	perception_all_seeing = true,
	perception_all_seeing_re_evaluate = true
}
local TargetSelectionTypes = {
	pick_rat_ogre_target_idle = true,
	pick_ninja_approach_target = true,
	pick_rat_ogre_target_with_weights = true,
	pick_flee_target = true,
	pick_pounce_down_target = true,
	pick_closest_target_with_spillover = true,
	pick_solitary_target = true,
	horde_pick_closest_target_with_spillover = true,
	pick_pack_master_target = true,
	pick_no_targets = true,
	pick_closest_target = true
}

for name, breed in pairs(Breeds) do
	breed.name = name

	if not breed.allowed_layers then
		breed.allowed_layers = {
			bot_poison_wind = 1.5,
			ledges = 0.5,
			planks = 1.5,
			barrel_explosion = 10,
			bot_ratling_gun_fire = 3,
			ledges_with_fence = 0.5,
			doors = 1.5,
			teleporters = 5,
			smoke_grenade = 4,
			fire_grenade = 10
		}
	end

	if breed.perception and not PerceptionTypes[breed.perception] then
		error("Bad perception type '" .. breed.perception .. "' specified in breed .. '" .. breed.name .. "'.")
	end

	if breed.target_selection and not TargetSelectionTypes[breed.target_selection] then
		error("Bad 'target_selection' type '" .. breed.target_selection .. "' specified in breed .. '" .. breed.name .. "'.")
	end

	if breed.smart_object_template == nil then
		breed.smart_object_template = "fallback"
	end
end
