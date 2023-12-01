-- chunkname: @core/wwise/lua/wwise_preview.lua

stingray.WwisePreview = stingray.WwisePreview or {}

local WwisePreview = stingray.WwisePreview
local Application = stingray.Application
local Wwise = stingray.Wwise
local WwiseWorld = stingray.WwiseWorld
local WwiseBankReference = require("core/wwise/lua/wwise_bank_reference")

WwisePreview.active_banks = WwisePreview.active_banks or {}

WwisePreview.play_event = function (world, bank_resource_name, event_name)
	if not Wwise then
		return
	end

	local active_banks = WwisePreview.active_banks
	local active_bank = active_banks[bank_resource_name]

	if not active_bank then
		active_bank = {
			name = bank_resource_name,
			active_events = {}
		}
		active_banks[bank_resource_name] = active_bank

		Wwise.load_bank(bank_resource_name)
		WwiseBankReference:add(bank_resource_name)
	end

	local active_events = active_bank.active_events
	local active_event = active_events[event_name]
	local wwise_world = Wwise.wwise_world(world)

	if active_event then
		WwiseWorld.stop_event(wwise_world, active_event.playing_id)
	else
		active_event = {}
		active_events[event_name] = active_event
	end

	active_event.playing_id = WwiseWorld.trigger_event(wwise_world, event_name)
end

WwisePreview.unload_bank = function (bank_resource_name)
	if not Wwise then
		return
	end

	WwiseBankReference:remove(bank_resource_name)

	if WwiseBankReference:count(bank_resource_name) == 0 then
		Wwise.unload_bank(bank_resource_name)
	end
end

WwisePreview.stop_event = function (world, bank_resource_name, event_name)
	if not Wwise then
		return
	end

	local active_bank = WwisePreview.active_banks[bank_resource_name]

	if active_bank then
		local active_events = active_bank.active_events
		local active_event = active_events[event_name]

		if active_event then
			local wwise_world = Wwise.wwise_world(world)

			WwiseWorld.stop_event(wwise_world, active_event.playing_id)

			active_events[event_name] = nil
		else
			print("Warning: WwisePreview.stop_active_event event ", event_name, "is not active.")
		end
	else
		print("Warning: WwisePreview.stop_active_event bank", bank_resource_name, "has no active events to stop.")
	end
end

local function notify_editor_event_finished(bank, event)
	Application.console_send({
		type = "wwise_event_finished",
		bank_resource_name = bank,
		event_name = event
	})
end

WwisePreview.stop_all_events = function (world, should_notify_editor)
	if not Wwise then
		return
	end

	local wwise_world = Wwise.wwise_world(world)
	local active_banks = WwisePreview.active_banks

	for bank_resource_name, active_bank in pairs(active_banks) do
		local active_events = active_bank.active_events

		for event_name, info in pairs(active_events) do
			WwiseWorld.stop_event(wwise_world, info.playing_id)

			if should_notify_editor == true then
				notify_editor_event_finished(bank_resource_name, event_name)
			end
		end

		WwiseBankReference:remove(bank_resource_name)

		if WwiseBankReference:count(bank_resource_name) == 0 then
			Wwise.unload_bank(bank_resource_name)
		end
	end

	WwisePreview.active_banks = {}
end

WwisePreview.update = function (world)
	if not Wwise then
		return
	end

	local wwise_world = Wwise.wwise_world(world)
	local active_banks = WwisePreview.active_banks

	for bank_resource_name, active_bank in pairs(active_banks) do
		local active_event_count = 0
		local active_events = active_bank.active_events

		for event_name, info in pairs(active_events) do
			if not WwiseWorld.is_playing(wwise_world, info.playing_id) then
				notify_editor_event_finished(bank_resource_name, event_name)

				active_events.event_name = nil
			else
				active_event_count = active_event_count + 1
			end
		end

		if active_event_count == 0 then
			WwiseBankReference:remove(bank_resource_name)

			if WwiseBankReference:count(bank_resource_name) == 0 then
				Wwise.unload_bank(bank_resource_name)
			end

			active_banks[bank_resource_name] = nil
		end
	end
end

return WwisePreview
