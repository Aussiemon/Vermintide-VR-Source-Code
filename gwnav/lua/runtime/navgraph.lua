-- chunkname: @gwnav/lua/runtime/navgraph.lua

require("gwnav/lua/safe_require")

local NavGraph = safe_require_guard()
local NavClass = safe_require("gwnav/lua/runtime/navclass")

NavGraph = NavClass(NavGraph)

local GwNavGraph = stingray.GwNavGraph

NavGraph.init = function (self, world_or_database, bidirectional_edges, point_table, color, layer_id, smartobject_id, user_data_id)
	self.nav_navgraph = GwNavGraph.create(world_or_database, bidirectional_edges, point_table, color, layer_id, smartobject_id, user_data_id)
end

NavGraph.shutdown = function (self)
	GwNavGraph.destroy(self.nav_navgraph)

	self.nav_navgraph = nil
end

NavGraph.add_to_database = function (self)
	GwNavGraph.add_to_database(self.nav_navgraph)
end

NavGraph.remove_from_database = function (self)
	GwNavGraph.remove_from_database(self.nav_navgraph)
end

return NavGraph
