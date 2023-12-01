-- chunkname: @script/lua/utils/conflict_utils.lua

require("settings/breeds")

ConflictUtils = {}

local ConflictUtils = ConflictUtils
local distance_squared = Vector3.distance_squared
local length_squared = Vector3.length_squared
local debug_table = {
	{},
	{}
}
local SPHERES, LINES = 1, 2
local RED, YELLOW, GREEN, WHITE = 1, 2, 3, 4
local math_random = Math.random
local colors = {
	QuaternionBox(255, 184, 46, 0),
	QuaternionBox(255, 250, 140, 0),
	QuaternionBox(255, 0, 220, 0),
	QuaternionBox(200, 235, 235, 235)
}

ConflictUtils.random_interval = function (numbers)
	if type(numbers) == "table" then
		return math_random(numbers[1], numbers[2])
	else
		return numbers
	end
end
