﻿-- chunkname: @foundation/script/managers/chat/chat_manager.lua

require("scripts/ui/views/chat_gui")
class("ChatManager")

ChatManager.init = function (self)
	self.channels = {}
	self.chat_messages = {}
	self.peer_ignore_list = SaveData.chat_ignore_list or {}

	self:create_chat_gui()
end

ChatManager.create_chat_gui = function (self)
	local top_world = Managers.world:world("top_ingame_view")

	self._ui_top_renderer = UIRenderer.create(top_world, "material", "materials/ui/ui_1080p_chat", "material", "materials/fonts/arial", "material", "materials/fonts/hell_shark_font", "material", "materials/fonts/gw_fonts")

	local context = {
		input_manager = Managers.input,
		ui_top_renderer = self._ui_top_renderer,
		chat_manager = self
	}

	self.chat_gui = ChatGui:new(context)
	self.gui_enabled = true
end

ChatManager.set_profile_synchronizer = function (self, profile_synchronizer)
	self.chat_gui:set_profile_synchronizer(profile_synchronizer)
end

ChatManager.set_wwise_world = function (self, wwise_world)
	self.chat_gui:set_wwise_world(wwise_world)
end

ChatManager.set_input_manager = function (self, input_manager)
	self.chat_gui:set_input_manager(input_manager)
end

ChatManager.register_network_event_delegate = function (self, network_event_delegate)
	network_event_delegate:register(self, "rpc_chat_message")

	self.network_event_delegate = network_event_delegate
end

ChatManager.unregister_network_event_delegate = function (self)
	if self.network_event_delegate then
		self.network_event_delegate:unregister(self)

		self.network_event_delegate = nil
	end
end

ChatManager.setup_network_context = function (self, network_context)
	print(string.format("[ChatManager] Setting up network context, host_peer_id:%s my_peer_id:%s", network_context.host_peer_id, network_context.my_peer_id))

	self.is_server = network_context.is_server
	self.host_peer_id = network_context.host_peer_id
	self.my_peer_id = network_context.my_peer_id
end

ChatManager.ignoring_peer_id = function (self, peer_id)
	return self.peer_ignore_list[peer_id]
end

ChatManager.ignore_peer_id = function (self, peer_id)
	self.peer_ignore_list[peer_id] = true

	if rawget(_G, "Steam") then
		SaveData.chat_ignore_list = self.peer_ignore_list

		Managers.save:auto_save(SaveFileName, SaveData, nil)
	end
end

ChatManager.remove_ignore_peer_id = function (self, peer_id)
	self.peer_ignore_list[peer_id] = nil

	if rawget(_G, "Steam") then
		SaveData.chat_ignore_list = self.peer_ignore_list

		Managers.save:auto_save(SaveFileName, SaveData, nil)
	end
end

ChatManager.destroy = function (self)
	self.chat_gui:destroy()

	self.chat_gui = nil

	local top_world = Managers.world:world("top_ingame_view")

	UIRenderer.destroy(self._ui_top_renderer, top_world)

	self.channels = nil
end

ChatManager.register_channel = function (self, channel_id, members_func)
	print("[ChatManager] Registering channel %s", channel_id)

	local channels = self.channels

	if Application.platform() == "xb1" then
		if channels[channel_id] then
			Application.warning(string.format("[ChatManager] Tried to add already registered channel %q", channel_id))
		end
	else
		assert(channels[channel_id] == nil, "[ChatManager] Tried to add already registered channel %q", channel_id)
	end

	channels[channel_id] = {
		members_func = members_func
	}
end

ChatManager.unregister_channel = function (self, channel_id)
	print("[ChatManager] Unregistering channel %s", channel_id)

	self.channels[channel_id] = nil
end

ChatManager.chat_is_focused = function (self)
	return self.chat_gui.chat_focused
end

ChatManager.enable_gui = function (self, enable)
	self.gui_enabled = enable
end

ChatManager.update = function (self, dt, t, menu_active, menu_input_service, no_unblock)
	if self.gui_enabled then
		self.chat_gui:update(dt, menu_active, menu_input_service, no_unblock)
	end
end

ChatManager.send_chat_message = function (self, channel_id, message)
	fassert(self:has_channel(channel_id), "Haven't registered channel: %s", tostring(channel_id))

	local localization_param = ""
	local is_system_message = false
	local pop_chat = true
	local my_peer_id = self.my_peer_id
	local is_dev = SteamHelper.is_dev(my_peer_id)

	if self.is_server then
		local members = self:channel_members(channel_id)

		for _, member in pairs(members) do
			if member ~= my_peer_id then
				RPC.rpc_chat_message(member, channel_id, my_peer_id, message, localization_param, is_system_message, pop_chat, is_dev)
			end
		end
	else
		local host_peer_id = self.host_peer_id

		if host_peer_id then
			RPC.rpc_chat_message(host_peer_id, channel_id, my_peer_id, message, localization_param, is_system_message, pop_chat, is_dev)
		end
	end

	self:_add_message_to_list(channel_id, my_peer_id, message, is_system_message, pop_chat, is_dev)
end

ChatManager.send_system_chat_message_to_all_except = function (self, channel_id, message_id, localization_param, excluded_peer_id, pop_chat)
	fassert(self:has_channel(channel_id), "Haven't registered channel: %s", tostring(channel_id))

	local is_system_message = true

	pop_chat = pop_chat or false

	local is_dev = false

	if self.is_server then
		local my_peer_id = self.my_peer_id
		local members = self:channel_members(channel_id)

		for _, member in pairs(members) do
			if member ~= my_peer_id and member ~= excluded_peer_id then
				RPC.rpc_chat_message(member, channel_id, excluded_peer_id, message_id, localization_param, is_system_message, pop_chat, is_dev)
			end
		end
	else
		local host_peer_id = self.host_peer_id

		if host_peer_id then
			RPC.rpc_chat_message(host_peer_id, channel_id, excluded_peer_id, message_id, localization_param, is_system_message, pop_chat, is_dev)
		end
	end

	local message_sender = "SYSTEM"
	local message = string.format(Localize(message_id), localization_param)

	self:_add_message_to_list(channel_id, message_sender, message, is_system_message, pop_chat, is_dev)
end

ChatManager.send_system_chat_message = function (self, channel_id, message_id, localization_param, pop_chat)
	fassert(self:has_channel(channel_id), "Haven't registered channel: %s", tostring(channel_id))

	local is_system_message = true

	pop_chat = pop_chat or false

	local is_dev = false
	local my_peer_id = self.my_peer_id

	if self.is_server then
		local members = self:channel_members(channel_id)

		for _, member in pairs(members) do
			if member ~= my_peer_id then
				RPC.rpc_chat_message(member, channel_id, my_peer_id, message_id, localization_param, is_system_message, pop_chat, is_dev)
			end
		end
	else
		local host_peer_id = self.host_peer_id

		if host_peer_id then
			RPC.rpc_chat_message(host_peer_id, channel_id, my_peer_id, message_id, localization_param, is_system_message, pop_chat, is_dev)
		end
	end

	local message_sender = "SYSTEM"
	local message = string.format(Localize(message_id), localization_param)

	self:_add_message_to_list(channel_id, message_sender, message, is_system_message, pop_chat, is_dev)
end

ChatManager.add_local_system_message = function (self, channel_id, message, pop_chat)
	fassert(self:has_channel(channel_id), "Haven't registered channel: %s", tostring(channel_id))

	local message_sender = "SYSTEM"
	local is_system_message = true
	local is_dev = false

	self:_add_message_to_list(channel_id, message_sender, message, is_system_message, pop_chat, is_dev)
end

ChatManager.channel_members = function (self, channel_id)
	local channel = self.channels[channel_id]

	assert(channel, "[ChatManager] Trying to get members from unregistered channel %q", channel_id)

	local members = channel.members_func()

	return members
end

ChatManager.is_channel_member = function (self, channel_id)
	local channel = self.channels[channel_id]
	local members = channel.members_func()
	local my_peer_id = self.my_peer_id

	for _, member in pairs(members) do
		if member == my_peer_id then
			return true
		end
	end
end

ChatManager.has_channel = function (self, channel_id)
	return self.channels[channel_id] and true
end

ChatManager.rpc_chat_message = function (self, sender, channel_id, message_sender, message, localization_param, is_system_message, pop_chat, is_dev)
	if not self:has_channel(channel_id) then
		return
	end

	if self.peer_ignore_list[sender] then
		return
	end

	if self.is_server then
		local members = self:channel_members(channel_id)
		local my_peer_id = self.my_peer_id

		for _, member in pairs(members) do
			if member ~= my_peer_id and member ~= sender then
				RPC.rpc_chat_message(member, channel_id, message_sender, message, localization_param, is_system_message, pop_chat, is_dev)
			end
		end
	end

	if self:is_channel_member(channel_id) then
		if is_system_message then
			message_sender = "SYSTEM"
			message = string.format(Localize(message), localization_param)
		end

		self:_add_message_to_list(channel_id, message_sender, message, is_system_message, pop_chat, is_dev)
	end
end

ChatManager._add_message_to_list = function (self, channel_id, message_sender, message, is_system_message, pop_chat, is_dev)
	local chat_messages = self.chat_messages

	chat_messages[#chat_messages + 1] = {
		channel_id = channel_id,
		message_sender = message_sender,
		message = message,
		is_system_message = is_system_message,
		pop_chat = pop_chat,
		is_dev = is_dev
	}
end

ChatManager.get_chat_messages = function (self, destination_table)
	local chat_messages = self.chat_messages

	for i, message_data in pairs(chat_messages) do
		destination_table[i] = message_data
		chat_messages[i] = nil
	end
end
