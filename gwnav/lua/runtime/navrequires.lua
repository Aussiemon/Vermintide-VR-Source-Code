-- chunkname: @gwnav/lua/runtime/navrequires.lua

require("gwnav/lua/safe_require")
safe_require("gwnav/lua/runtime/navflowcallbacks")

NavBot = safe_require("gwnav/lua/runtime/navbot")
NavBotConfiguration = safe_require("gwnav/lua/runtime/navbotconfiguration")
NavBoxObstacle = safe_require("gwnav/lua/runtime/navboxobstacle")
NavClass = safe_require("gwnav/lua/runtime/navclass")
NavCylinderObstacle = safe_require("gwnav/lua/runtime/navcylinderobstacle")
NavDefaultSmartObjectFollower = safe_require("gwnav/lua/runtime/navdefaultsmartobjectfollower")
NavGraph = safe_require("gwnav/lua/runtime/navgraph")
NavHelpers = safe_require("gwnav/lua/runtime/navhelpers")
NavMeshCamera = safe_require("gwnav/lua/runtime/navmeshcamera")
NavRoute = safe_require("gwnav/lua/runtime/navroute")
NavTagVolume = safe_require("gwnav/lua/runtime/navtagvolume")
NavWorld = safe_require("gwnav/lua/runtime/navworld")
