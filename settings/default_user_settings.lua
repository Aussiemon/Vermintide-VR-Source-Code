-- chunkname: @settings/default_user_settings.lua

local differentiation_settings = {
	low = {
		particle_async_update = true,
		max_ragdolls = 5,
		max_levitating_ragdolls = 2,
		extra_particle_trail = false,
		index = 1,
		title = "Low",
		particle_vector_fields = false,
		particle_collisions = false,
		dismember_enabled = false,
		apex_enabled = false
	},
	high = {
		particle_async_update = true,
		max_ragdolls = 10,
		max_levitating_ragdolls = 5,
		extra_particle_trail = true,
		index = 2,
		title = "High",
		particle_vector_fields = true,
		particle_collisions = true,
		dismember_enabled = true,
		apex_enabled = true
	}
}

DefaultUserSettings = {}

DefaultUserSettings.set_default_user_settings = function ()
	local set_default = false

	for setting_name, settings in pairs(differentiation_settings) do
		for key, value in pairs(settings) do
			if Application.user_setting("differentiation", setting_name, key) == nil then
				Application.set_user_setting("differentiation", setting_name, key, value)

				set_default = true
			end
		end
	end

	if set_default then
		Application.save_user_settings()
	end
end
