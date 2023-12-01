-- chunkname: @foundation/script/util/class.lua

function class(class_name, ...)
	local class_table = rawget(_G, class_name)
	local super_name = ...
	local super

	if select("#", ...) >= 1 then
		fassert(super_name ~= nil, "Trying to inherit from nil")

		super = rawget(_G, super_name)

		fassert(super, "Trying to inherit from nonexistant %q", super_name)
	end

	if not class_table then
		class_table = {
			super = super
		}
		class_table.__index = class_table

		class_table.new = function (self, ...)
			local object = {}

			setmetatable(object, class_table)

			if object.init then
				object:init(...)
			end

			return object
		end

		class_table.new_inplace = function (self, inplace_table, ...)
			local object = inplace_table

			setmetatable(object, class_table)

			if object.init then
				object:init(...)
			end

			return object
		end

		class_table.__class_name = class_name

		rawset(_G, class_name, class_table)
	end

	if super then
		for k, v in pairs(super) do
			if k ~= "__index" and k ~= "new" and k ~= "new_inplace" and k ~= "super" then
				class_table[k] = v
			end
		end
	end
end
