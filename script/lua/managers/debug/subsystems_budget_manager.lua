-- chunkname: @script/lua/managers/debug/subsystems_budget_manager.lua

require("settings/subsystem_budgets")

ScopesBudget = ScopesBudget or {}

class("SubsystemsBudgetManager")

SubsystemsBudgetManager.init = function (self)
	for profile_scope, budget in pairs(SubsystemBudgets) do
		self:add_scope(profile_scope, budget)
	end
end

SubsystemsBudgetManager.destroy = function (self)
	return
end

SubsystemsBudgetManager.update = function (self)
	for scope, budget in pairs(ScopesBudget) do
		local scope_duration = Profiler.get_scope_duration(scope)

		if scope_duration ~= nil and budget < scope_duration * 1000 then
			print("Scope " .. scope .. " is out it's duration budget - actual duration is " .. string.format("%.2f", scope_duration * 1000) .. " ms budget is " .. budget .. " ms")
		end
	end
end

SubsystemsBudgetManager.add_scope = function (self, name, budget)
	ScopesBudget[name] = budget
end
