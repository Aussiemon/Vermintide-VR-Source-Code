-- chunkname: @script/game.lua

Game = Game or {}

local function import(lib)
	for k, v in pairs(lib) do
		rawset(_G, k, v)
	end
end

if stingray then
	import(stingray)
end

local meta = {
	__newindex = function (t, k, v)
		if rawget(t, k) == nil then
			local info = debug.getinfo(2, "S")

			if k ~= "to_console_line" and info and info.what ~= "main" and info.what ~= "C" then
				error(string.format("Cannot assign undeclared global %q", k), 2)
			end
		end

		rawset(t, k, v)
	end,
	__index = function (t, k)
		local info = debug.getinfo(2, "S")

		if k ~= "to_console_line" and info and info.what ~= "main" and info.what ~= "C" then
			error(string.format("Cannot access undeclared global %q", k), 2)
		end
	end
}

setmetatable(_G, meta)

script_data = script_data or {}

function init()
	Game:init()
end

function update(dt)
	Game:update(dt)
	Profiler.start("LUA update world")
	World.update(GLOBAL_WORLD, dt)
	Profiler.stop("LUA update world")
end

function shutdown()
	Game:shutdown()
end

function render()
	Game:render()
end

Game.init = function (self)
	self:_require_scripts()
	DefaultUserSettings.set_default_user_settings()
	self:_parse_commands()
	self:_setup_window()
	self:_init_managers()
	self:_setup_state_machine()
end

Game._setup_window = function (self)
	Window.set_focus()
	Window.set_mouse_focus(true)

	if Game.startup_commands["window-title"] then
		Window.set_title(Game.startup_commands["window-title"])
	else
		Window.set_title("Vermintide VR")
	end
end

Game.parse_runtime_args = function (self)
	local args = {
		Application.argv()
	}
	local commands = {}

	table.dump(args, "Application Arguments", 2)

	local i = 1
	local num_args = #args

	while i <= num_args do
		local arg = args[i]
		local params = {}

		i = i + 1

		local arg_args = 0

		while args[i] and string.sub(args[i], 1, 1) ~= "-" and string.sub(args[i], 1, 1) ~= "+" do
			params[#params + 1] = args[i]
			i = i + 1
			arg_args = arg_args + 1
		end

		commands[string.sub(arg, 2)] = arg_args == 0 and true or arg_args == 1 and params[1] or params
	end

	return commands
end

Game._parse_commands = function (self)
	Game.startup_commands = self:parse_runtime_args()

	print("")
	table.dump(Game.startup_commands, "startup_commands", 2)
	print("")
end

Game._require_scripts = function (self)
	require("core/wwise/lua/wwise_flow_callbacks")
	require("foundation/script/util/class")
	require("foundation/script/util/error")
	require("foundation/script/util/math")
	require("foundation/script/util/misc_util")
	require("foundation/script/util/table")
	require("foundation/script/util/callback")
	require("foundation/script/managers/managers")
	require("foundation/script/managers/package/package_manager")
	require("foundation/script/util/state_machine")
	require("foundation/script/managers/time/time_manager")
	require("script/lua/managers/debug/subsystems_budget_manager")
	require("script/lua/managers/transition/transition_manager")
	require("script/lua/managers/popup/popup_manager")
	require("script/lua/managers/leaderboards/leaderboard_manager")
	require("script/lua/managers/unlock/unlock_manager")
	require("foundation/script/managers/token/token_manager")
	require("settings/default_user_settings")
	require("script/lua/game_states/state_splash")
end

GLOBAL_WORLD = GLOBAL_WORLD or {}

Game._init_managers = function (self)
	Managers.package = PackageManager

	Managers.package:init()
	Managers.package:load("levels/loading/loading", "loading")
	self:_setup_global_world()

	Managers.time = TimeManager:new()
	Managers.transition = TransitionManager:new()
	Managers.budget = SubsystemsBudgetManager:new()
	Managers.popup = PopupManager:new()
	Managers.unlock = UnlockManager:new()

	local vr_manager = SteamVrManager:new(0.01, 1000, "vr_target", "vr_hud")

	if not vr_manager:is_enabled() then
		if Application.build() == "release" then
			Application.quit_with_message("Failed to initialize SteamVR")

			return
		end

		vr_manager = MockVrManager:new(0.01, 1000)
	end

	Managers.vr = vr_manager
	Managers.token = TokenManager:new()
	Managers.leaderboards = LeaderboardManager:new()
end

function RESET_WORLD()
	Application.release_world(GLOBAL_WORLD)
	Game:_setup_global_world()
end

Game._setup_global_world = function (self)
	GLOBAL_WORLD = Application.new_world()

	local shading_env = World.create_shading_environment(GLOBAL_WORLD, "core/stingray_renderer/environments/midday/midday")

	World.set_data(GLOBAL_WORLD, "shading_environment", shading_env)
	World.set_data(GLOBAL_WORLD, "levels", {})
end

Game._setup_state_machine = function (self)
	Game.params = {}
	self._machine = StateMachine:new(self, StateSplash, Game.params)
end

Game.update = function (self, dt)
	Managers.budget:update()
	Managers.time:update(dt)

	local t = Managers.time:time("main")

	if Managers.sizzle_reel then
		Managers.sizzle_reel:update(dt)
	end

	if Managers.lobby then
		Managers.lobby:update(dt)
	end

	self._machine:pre_update(dt)
	Managers.package:update(dt)
	self._machine:update(dt, t)
	Managers.vr:update(dt)
	Managers.transition:update(dt)
	Managers.token:update(dt, Managers.time:time("main"))
	Managers.leaderboards:update(dt)

	if Game.quit then
		print("##################################")
		print("Exiting...")
		print("##################################")
		Application.quit()
	end
end

Game.render = function (self)
	self._machine:render()
	Managers.vr:render()

	if Managers.sizzle_reel then
		Managers.sizzle_reel:render()
	end
end

Game.shutdown = function (self)
	self._machine:destroy()
	Managers:destroy()
	Application.release_world(GLOBAL_WORLD)
end
