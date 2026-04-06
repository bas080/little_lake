-- luacheck: read_globals luanti_check

local test, gen = luanti_check()
local range = 40

test("Spawns little lakes in expected places", function(t)
	local player = gen.player_pos({
		pos = { y = range + 2 },
	})

	local function on_emerge()
		local pos = player:get_pos()
		local node_pos = core.find_node_near(pos, range, "default:water_source", true)

		-- Retry if the node was a sea level node.
		if node_pos == nil then
			return t.retry("Did not find a water source")
		end

		t.done("Found the little lake")
	end

	t.emerge(on_emerge)
end)
