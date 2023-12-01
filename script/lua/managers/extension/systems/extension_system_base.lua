-- chunkname: @script/lua/managers/extension/systems/extension_system_base.lua

class("ExtensionSystemBase")

ExtensionSystemBase.init = function (self, extension_system_creation_context, system_name, extension_list)
	self.is_server = extension_system_creation_context.is_server
	self._world = extension_system_creation_context.world
	self._level = extension_system_creation_context.level
	self._level_name = extension_system_creation_context.level_name
	self.name = system_name
	self._extension_init_context = {
		world = self._world,
		level = self._level,
		level_name = self._level_name
	}

	local network = Managers.lobby

	if network then
		local is_server = network.server

		self._network_mode = is_server and "server" or "client"
		self._extension_init_context.network_mode = self._network_mode
	end

	self._update_list = {}
	self._extensions = {}
	self._profiler_names = {}

	for i = 1, #extension_list do
		local extension_name = extension_list[i]

		self._update_list[extension_name] = {
			pre_update = {},
			update = {},
			post_update = {},
			hot_join_sync = {}
		}
		self._extensions[extension_name] = 0
		self._profiler_names[extension_name] = extension_name .. " [ALL]"
	end
end

ExtensionSystemBase.on_add_extension = function (self, world, unit, extension_name, extension_init_data)
	local extension_alias = self.NAME
	local extension = ScriptUnit.add_extension(self._extension_init_context, unit, extension_name, extension_alias, extension_init_data)

	self._extensions[extension_name] = (self._extensions[extension_name] or 0) + 1

	if extension.pre_update then
		self._update_list[extension_name].pre_update[unit] = extension
	end

	if extension.update then
		self._update_list[extension_name].update[unit] = extension
	end

	if extension.post_update then
		self._update_list[extension_name].post_update[unit] = extension
	end

	if extension.hot_join_sync then
		self._update_list[extension_name].hot_join_sync[unit] = extension
	end

	return extension
end

ExtensionSystemBase.on_remove_extension = function (self, unit, extension_name)
	local extension = ScriptUnit.has_extension(unit, self.NAME)

	assert(extension, "Trying to remove non-existing extension %q from unit %s", extension_name, unit)
	ScriptUnit.remove_extension(unit, self.NAME)

	self._extensions[extension_name] = self._extensions[extension_name] - 1
	self._update_list[extension_name].pre_update[unit] = nil
	self._update_list[extension_name].update[unit] = nil
	self._update_list[extension_name].post_update[unit] = nil
	self._update_list[extension_name].hot_join_sync[unit] = nil
end

ExtensionSystemBase.pre_update = function (self, dt, t)
	Profiler.start("ExtensionSystemBase:pre_update()")

	local update_list = self._update_list

	for extension_name, _ in pairs(self._extensions) do
		local profiler_name = self._profiler_names[extension_name]

		Profiler.start(profiler_name)

		for unit, extension in pairs(update_list[extension_name].pre_update) do
			extension:pre_update(unit, dt, t)
		end

		Profiler.stop(profiler_name)
	end

	Profiler.stop("ExtensionSystemBase:pre_update()")
end

ExtensionSystemBase.enable_update_function = function (self, extension_name, update_function_name, unit, extension)
	self._update_list[extension_name][update_function_name][unit] = extension
end

ExtensionSystemBase.disable_update_function = function (self, extension_name, update_function_name, unit)
	self._update_list[extension_name][update_function_name][unit] = nil
end

ExtensionSystemBase.hot_join_sync = function (self, peer_id)
	Profiler.start("ExtensionSystemBase:hot_join_sync()")

	local update_list = self._update_list

	for extension_name, _ in pairs(self._extensions) do
		local profiler_name = self._profiler_names[extension_name]

		Profiler.start(profiler_name)

		for unit, extension in pairs(update_list[extension_name].hot_join_sync) do
			extension:hot_join_sync(peer_id)
		end

		Profiler.stop(profiler_name)
	end

	Profiler.stop("ExtensionSystemBase:hot_join_sync()")
end

ExtensionSystemBase.update = function (self, dt, t)
	Profiler.start("ExtensionSystemBase:update()")

	local update_list = self._update_list

	for extension_name, _ in pairs(self._extensions) do
		local profiler_name = self._profiler_names[extension_name]

		Profiler.start(profiler_name)

		for unit, extension in pairs(update_list[extension_name].update) do
			extension:update(unit, dt, t)
		end

		Profiler.stop(profiler_name)
	end

	Profiler.stop("ExtensionSystemBase:update()")
end

ExtensionSystemBase.post_update = function (self, dt, t)
	Profiler.start("ExtensionSystemBase:post_update()")

	local update_list = self._update_list

	for extension_name, _ in pairs(self._extensions) do
		local profiler_name = self._profiler_names[extension_name]

		Profiler.start(profiler_name)

		for unit, extension in pairs(update_list[extension_name].post_update) do
			extension:post_update(unit, dt, t)
		end

		Profiler.stop(profiler_name)
	end

	Profiler.stop("ExtensionSystemBase:post_update()")
end

ExtensionSystemBase.update_extension = function (self, extension_name, dt, t)
	error("ExtensionSystemBase:update_extension() called")

	local update_list = self._update_list

	for unit, extension in pairs(update_list[extension_name].update) do
		extension:update(unit, dt, t)
	end
end

ExtensionSystemBase.destroy = function (self)
	return
end
