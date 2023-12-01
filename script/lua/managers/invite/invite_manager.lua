-- chunkname: @script/lua/managers/invite/invite_manager.lua

class("InviteManager")

InviteManager.init = function (self)
	self.lobby_data = nil
	self._enabled = rawget(_G, "Steam") and not not rawget(_G, "Friends")

	if not self._enabled then
		print("InviteManager not enabled")
		print("Steam", rawget(_G, "Steam"), "Friends", rawget(_G, "Friends"))

		return
	end

	print("InviteManager enabled")

	self._invite_types = {}
	self._invite_types[Friends.INVITE_LOBBY] = "Friends.INVITE_LOBBY"
	self._invite_types[Friends.INVITE_SERVER] = "Friends.INVITE_SERVER"
	self._invite_types[Friends.NO_INVITE] = "Friends.NO_INVITE"
end

InviteManager.poll_boot_invite = function (self)
	if self._enabled then
		local invite_type, lobby_id = Friends.boot_invite()

		if invite_type == Friends.NO_INVITE then
			-- Nothing
		elseif invite_type == Friends.INVITE_LOBBY then
			print("Friends.INVITE_LOBBY")
			print(self._invite_types[invite_type], lobby_id)

			self._lobby_id = lobby_id

			return true
		elseif invite_type == Friends.INVITE_SERVER then
			print("Friends.INVITE_SERVER")
		end
	end
end

InviteManager.poll_invite = function (self)
	if self._enabled then
		local invite_type, lobby_id, parameters, friend_id = Friends.next_invite()

		if invite_type == Friends.NO_INVITE then
			-- Nothing
		elseif invite_type == Friends.INVITE_LOBBY then
			print("Friends.INVITE_LOBBY")
			print(invite_type, lobby_id, parameters, friend_id)

			self._lobby_id = lobby_id

			return true
		elseif invite_type == Friends.INVITE_SERVER then
			print("Friends.INVITE_SERVER")
		end
	end
end

InviteManager.join_last_invite = function (self)
	print("Join last invite", self._lobby_id)
	Network.update(0, self)
	Managers.lobby:join_lobby_by_lobby_id(self._lobby_id)

	self._lobby_id = nil
end
