-- chunkname: @script/lua/managers/popup/popup_manager.lua

require("script/lua/views/popup_view")
class("PopupManager")

PopupManager.init = function (self)
	self._world = GLOBAL_WORLD
	self._current_popup_id = 1
	self._active_popup_id = nil
	self._popup_queue = {}
	self._popup_data = {}
	self._active_popup = PopupView:new(self._world, {
		message = "",
		header = ""
	}, self)
end

PopupManager.queue_popup = function (self, header, message)
	local popup_id = self._current_popup_id

	self._popup_data[popup_id] = {
		header = header,
		message = message
	}
	self._popup_queue[#self._popup_queue + 1] = popup_id
	self._current_popup_id = self._current_popup_id + 1

	return popup_id
end

PopupManager.reinitialize = function (self)
	self._world = GLOBAL_WORLD

	if self._active_popup then
		local popup_data = self._popup_queue[self._active_popup_id]

		self._active_popup = PopupView:new(self._world, popup_data, self)
	end
end

PopupManager.has_popup = function (self)
	return #self._popup_queue > 0
end

PopupManager.query_popup_done = function (self, popup_id)
	return self._popup_data[popup_id] == nil
end

PopupManager.update = function (self, dt, t, input_controller)
	if self._active_popup_id then
		if self._active_popup:update(dt, t, input_controller) then
			self._active_popup:enable(false, input_controller)

			self._popup_data[self._active_popup_id] = nil

			table.remove(self._popup_queue, 1)

			self._active_popup_id = nil

			if #self._popup_queue > 0 then
				self._active_popup_id = self._popup_queue[1]

				local popup_data = self._popup_data[self._active_popup_id]

				self._active_popup:enable(true, input_controller, popup_data)
			end
		end
	elseif #self._popup_queue > 0 then
		self._active_popup_id = self._popup_queue[1]

		local popup_data = self._popup_data[self._active_popup_id]

		self._active_popup:enable(true, input_controller, popup_data)
	end
end

PopupManager.destroy = function (self)
	if self._active_popup then
		self._active_popup:destroy()

		self._active_popup = nil
	end
end
