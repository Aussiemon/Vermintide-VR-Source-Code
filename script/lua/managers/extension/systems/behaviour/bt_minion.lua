-- chunkname: @script/lua/managers/extension/systems/behaviour/bt_minion.lua

local USE_PRECOMPILED_ROOT_TABLES = false

BreedBehaviors = {}
BreedBehaviors.pack_rat = {
	"BTSelector",
	{
		"BTDeadAction",
		condition = "is_dead",
		name = "dead"
	},
	{
		"BTSpawningAction",
		condition = "spawn",
		name = "spawn"
	},
	{
		"BTBlockedAction",
		name = "blocked",
		condition = "blocked",
		action_data = BreedActions.skaven_clan_rat.blocked
	},
	{
		"BTCombatShoutAction",
		name = "victory_shout",
		condition = "level_ended",
		action_data = BreedActions.skaven_clan_rat.combat_shout
	},
	{
		"BTSelector",
		{
			"BTClimbAction",
			condition = "at_climb_smartobject",
			name = "climb"
		},
		condition = "at_smartobject",
		name = "smartobject"
	},
	{
		"BTAttackAction",
		name = "normal_attack",
		condition = "target_reached",
		action_data = BreedActions.skaven_clan_rat.normal_attack
	},
	{
		"BTCombatShoutAction",
		name = "combat_shout",
		condition = "wait_slot_reached",
		action_data = BreedActions.skaven_clan_rat.combat_shout
	},
	{
		"BTClanRatFollowAction",
		name = "follow",
		condition = "can_see_target",
		action_data = BreedActions.skaven_clan_rat.follow
	},
	{
		"BTIdleAction",
		name = "idle"
	},
	name = "pack"
}
BreedBehaviors.storm_vermin = {
	"BTSelector",
	{
		"BTDeadAction",
		condition = "is_dead",
		name = "dead"
	},
	{
		"BTSpawningAction",
		condition = "spawn",
		name = "spawn"
	},
	{
		"BTBlockedAction",
		name = "blocked",
		condition = "blocked",
		action_data = BreedActions.skaven_storm_vermin.blocked
	},
	{
		"BTCombatShoutAction",
		name = "victory_shout",
		condition = "level_ended",
		action_data = BreedActions.skaven_storm_vermin.combat_shout
	},
	{
		"BTSelector",
		{
			"BTClimbAction",
			condition = "at_climb_smartobject",
			name = "climb"
		},
		condition = "at_smartobject",
		name = "smartobject"
	},
	{
		"BTRandom",
		{
			"BTStormVerminAttackAction",
			name = "attack_cleave",
			weight = 1,
			action_data = BreedActions.skaven_storm_vermin.special_attack_cleave
		},
		{
			"BTStormVerminAttackAction",
			name = "attack_sweep",
			weight = 1,
			action_data = BreedActions.skaven_storm_vermin.special_attack_sweep
		},
		condition = "target_reached",
		name = "combat"
	},
	{
		"BTCombatShoutAction",
		name = "combat_shout",
		condition = "wait_slot_reached",
		action_data = BreedActions.skaven_storm_vermin.combat_shout
	},
	{
		"BTClanRatFollowAction",
		name = "follow",
		condition = "can_see_target",
		action_data = BreedActions.skaven_storm_vermin.follow
	},
	{
		"BTIdleAction",
		name = "idle"
	},
	name = "storm_vermin"
}
BreedBehaviors.rat_ogre = {
	"BTSelector",
	{
		"BTDeadAction",
		condition = "is_dead",
		name = "dead"
	},
	{
		"BTSpawningAction",
		condition = "spawn",
		name = "spawn"
	},
	{
		"BTSelector",
		{
			"BTClimbAction",
			condition = "at_climb_smartobject",
			name = "climb"
		},
		condition = "at_smartobject",
		name = "smartobject"
	},
	{
		"BTStormVerminAttackAction",
		name = "attack_slam",
		condition = "target_reached",
		action_data = BreedActions.skaven_rat_ogre.special_attack_slam
	},
	{
		"BTClanRatFollowAction",
		name = "follow",
		condition = "can_see_target",
		action_data = BreedActions.skaven_rat_ogre.follow
	},
	{
		"BTIdleAction",
		name = "idle"
	},
	name = "rat_ogre"
}

if USE_PRECOMPILED_ROOT_TABLES then
	for bt_name, bt_node in pairs(BreedBehaviors) do
		bt_node[1] = "BTSelector_" .. bt_name
		bt_node.name = bt_name .. "_GENERATED"
	end
else
	for bt_name, bt_node in pairs(BreedBehaviors) do
		bt_node[1] = "BTSelector"
		bt_node.name = bt_name
	end
end
