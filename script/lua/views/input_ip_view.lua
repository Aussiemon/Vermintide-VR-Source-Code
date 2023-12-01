-- chunkname: @script/lua/views/input_ip_view.lua

local templates = require("script/lua/simple_gui/gui_templates")

class("InputIPView")

local elements = {
	{
		name = "background",
		template_type = "rect",
		color = {
			255,
			0,
			0,
			0
		},
		offset = {
			0,
			0,
			0
		},
		area_size = {
			1000,
			1000
		}
	},
	{
		text = "Input IP:",
		template_type = "selection",
		name = "join_ip_label",
		depends_on = "background",
		original_text = "Input IP: ",
		offset = {
			0,
			0,
			0
		},
		size = {
			400,
			1000
		}
	},
	{
		text = "Join Game",
		template_type = "header",
		name = "header",
		depends_on = "background",
		offset = {
			0,
			0,
			0
		}
	}
}

for _, element in ipairs(elements) do
	elements[element.name] = element
end

InputIPView.init = function (self, world, input, parent)
	self._world = world
	self._input = input
	self._parent = parent
	self._dirty = true
	self._digits_in_row = 0
	self._ip_address = {}

	self:_create_gui()
end

InputIPView._create_gui = function (self)
	self._size = {
		1000,
		1000
	}
	self._gui = World.create_world_gui(self._world, Matrix4x4.identity(), self._size[1], self._size[2], "material", "gui/single_textures/gui", "material", "gui/fonts/gw_fonts", "immediate")

	print("InputIPView -> World.create_world_gui")
end

InputIPView.update = function (self, dt, t)
	self:_update_position(dt, t)
	self:_update_flashing(dt, t)
	self:_update_ui(dt, t)
	self:_update_input(dt, t)
end

InputIPView._update_position = function (self, dt, t)
	local hmd_pose = Managers.vr:hmd_world_pose()

	if Matrix4x4.is_valid(hmd_pose.head) then
		local pose = hmd_pose.head
		local right = Matrix4x4.right(pose)
		local up = Matrix4x4.up(pose)

		Matrix4x4.set_translation(pose, Matrix4x4.translation(pose) + hmd_pose.forward * 2 + right * -0.5 + up * -0.5)

		if Matrix4x4.is_valid(pose) then
			Gui.move(self._gui, pose)
		end
	end
end

InputIPView._update_flashing = function (self, dt, t)
	if self._flashing then
		local element = elements[self._flashing]

		if not self._flashing_timer then
			self._flashing_timer = self._flashing_timer or 0
			element.old_color = table.clone(element.color)
		end

		local red_value = 128 + math.sin(self._flashing_timer * 35) * 128

		element.color = {
			255,
			red_value,
			0,
			0
		}
		self._flashing_timer = self._flashing_timer + dt

		if self._flashing_timer > 1.5 then
			element.color = table.clone(element.old_color)
			element.old_color = nil

			table.dump(element.color, "COLOR", 2)

			self._dirty = true
			self._flashing = nil
			self._flashing_timer = nil
		end
	end
end

InputIPView._verify_ip_address = function (self)
	local digits = 0
	local dots = 0

	for idx, digit in ipairs(self._ip_address) do
		if digits < 3 and type(tonumber(digit)) == "number" then
			digits = digits + 1
		elseif digit == "." then
			digits = 0
			dots = dots + 1
		else
			return false
		end
	end

	return dots == 3
end

InputIPView._update_input = function (self, dt, t)
	if self._flashing then
		return
	end

	if Keyboard.pressed(Keyboard.ENTER) then
		if self:_verify_ip_address() then
			self._parent:join_by_ip(self._ip_address_str)
		else
			self._flashing = "join_ip_label"
		end
	elseif Keyboard.pressed(Keyboard.ESCAPE) then
		self._parent:switch_view("TitleView")

		return
	end

	if Keyboard.any_pressed() then
		local keys = Keyboard.keystrokes()

		for _, key in pairs(keys) do
			local value = tonumber(key)

			if value == Keyboard.BACKSPACE then
				table.remove(self._ip_address, #self._ip_address)

				self._digits_in_row = 0
			elseif #self._ip_address < 15 then
				if type(value) == "number" and value < 10 and self._digits_in_row < 3 then
					self._digits_in_row = self._digits_in_row + 1
					self._ip_address[#self._ip_address + 1] = key
				elseif key == "." then
					self._digits_in_row = 0
					self._ip_address[#self._ip_address + 1] = key
				end
			end
		end

		local label = elements.join_ip_label

		label.text = label.original_text
		self._ip_address_str = ""

		for _, digit in ipairs(self._ip_address) do
			self._ip_address_str = self._ip_address_str .. digit
		end

		label.text = label.text .. self._ip_address_str
	end
end

InputIPView._update_ui = function (self, dt, t)
	if self._dirty then
		for _, element in ipairs(elements) do
			SimpleGui.update_element(self._gui, element, elements, templates)
		end

		self._dirty = false
	end

	for _, element in ipairs(elements) do
		SimpleGui.render_element(self._gui, element)
	end
end

InputIPView.destroy = function (self)
	print("InputIPView -> World.destroy_gui")
	World.destroy_gui(self._world, self._gui)

	self._gui = nil
end
