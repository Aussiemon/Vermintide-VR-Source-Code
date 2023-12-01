-- chunkname: @settings/network_lookup.lua

require("settings/material_effect_mappings")

local SKIP_RELOAD = SKIP_RELOAD or false

if not SKIP_RELOAD then
	function init_lookup_table(self, name)
		if SKIP_RELOAD then
			return
		end

		for index, str in ipairs(self) do
			fassert(not self[str], "[NetworkLookup.lua] Duplicate entry %q in %q.", str, AnimationEventLookup)

			self[str] = index
		end

		local index_error_print = "[NetworkLookup.lua] Table " .. name .. " does not contain key: "
		local meta = {
			__index = function (_, key)
				error(index_error_print .. tostring(key))
			end
		}

		setmetatable(self, meta)
	end

	local function parse_map(lookup_name, map)
		local t = {}

		for name, _ in pairs(map) do
			t[#t + 1] = name
		end

		NetworkLookup[lookup_name] = t
	end

	NetworkLookup = {}

	parse_map("levels", LevelSettings.levels)

	NetworkLookup.interaction_types = {
		"n/a",
		"riser",
		"string",
		"staff",
		"off_hand"
	}

	dofile("settings/network_lookup/animation_event_lookup")
	dofile("settings/network_lookup/sound_event_lookup")
	dofile("settings/network_lookup/score_type_lookup")
	dofile("settings/network_lookup/damage_type_lookup")

	NetworkLookup.surface_material_effects = {}

	for name, _ in pairs(MaterialEffectMappings) do
		NetworkLookup.surface_material_effects[#NetworkLookup.surface_material_effects + 1] = name
	end

	for key, lookup_table in pairs(NetworkLookup) do
		init_lookup_table(lookup_table, key)
	end

	SKIP_RELOAD = true
end
