local register_decoration = luanti_utils.dofile("register_decoration.lua")
local is_buildable_to = luanti_utils.dofile("is_buildable_to.lua")

-- 1. First we walk to x+ till we hit the wall
-- 2. Then we walk with a node always on our left hand side.
-- 3. If we close the loop within 200 steps we get the positions.
-- 4. We then loop the positions and place default:water_source.

-- Consider moving this to luanti_utils also.

local function walk_fixed_direction(start_pos, max_steps)
    local pos = vector.new(start_pos)
    local dir = { x = 0, y = 0, z = 1 } -- fixed direction

    for i = 1, max_steps do
        local next_pos = vector.add(pos, dir)

        if is_buildable_to(next_pos) then
            return pos -- hit a wall
        else
            pos = next_pos
        end
    end

    return nil -- did not hit a wall within max_steps
end

local function turn_left(dir)
    return { x = -dir.z, y = 0, z = dir.x }
end

local function turn_right(dir)
    return { x = dir.z, y = 0, z = -dir.x }
end

local function walk_wall(start_pos, start_dir, max_steps)
    local pos = vector.new(start_pos)
    local dir = vector.new(start_dir)
    local visited = {}

    for i = 1, max_steps do
        print(i, dump(pos), dump(dir))
        local left = turn_left(dir)
        local left_pos = vector.add(pos, left)
        local front_pos = vector.add(pos, dir)

        if core.get_node(left_pos).name == "air" then
            -- left free → turn left and move
            dir = left
            pos = left_pos
            table.insert(visited, vector.new(pos))
        elseif core.get_node(front_pos).name == "air" then
            -- forward free → move forward
            pos = front_pos
            table.insert(visited, vector.new(pos))
        else
            -- blocked left and forward → turn right
            dir = turn_right(dir)
            -- stay in place this step
        end

        -- Need to do a unique on the table to remove duplicate positions.

        -- check if returned to start
        if vector.equals(pos, start_pos) and #visited > 5 then
            return visited
        end
    end

    return {} -- did not return to start within 200 steps
end

-- Consider moving to luanti_utils to get positions of thing to fill
local function flood_fill_3d(start_pos, max_iterations)
    local queue = { vector.new(start_pos) }
    local visited = {}
    local result = {}

    local qi = 1
    local count = 0
    local escaped = false

    while queue[qi] do
        local pos = queue[qi]
        qi = qi + 1

        local key = vector.to_string(pos)

        if not visited[key] then
            visited[key] = true

            local node = core.get_node_or_nil(pos)
            if node == nil then
                return false
            end
            -- Is buildable to is the check I want.

            if is_buildable_to(node) then
                table.insert(result, pos)

                count = count + 1
                if count >= max_iterations then
                    return false
                end

                -- neighbors: XZ + down
                table.insert(queue, vector.add(pos, { x = 1, y = 0, z = 0 }))
                table.insert(queue, vector.add(pos, { x = -1, y = 0, z = 0 }))
                table.insert(queue, vector.add(pos, { x = 0, y = 0, z = 1 }))
                table.insert(queue, vector.add(pos, { x = 0, y = 0, z = -1 }))
                table.insert(queue, vector.add(pos, { x = 0, y = -1, z = 0 }))
            end
        end
    end

    return result, count
end

local function fill_water_along_wall(start_pos)
    local flood = flood_fill_3d(start_pos, 2000)

    if not flood or #flood < 15 then
        return
    end

    -- Step 3 & 4: loop over positions and place water_source
    for _, pos in ipairs(flood) do
        core.set_node(pos, { name = "default:water_source" })
    end
end

local up = { x = 0, y = 1, z = 0 }

register_decoration({
    name = "little_lake:lake",
    place_on = { "group:soil", "group:stone" },
    deco_type = "simple",
    fill_ratio = 0.01, -- controls how often lakes spawn
    y_min = -200,
    y_max = 100,
    flags = "all_floors",
    on_position = function(pos)
        print("I AM ON A LAKE")
        fill_water_along_wall(vector.add(pos, up))
    end,
})
