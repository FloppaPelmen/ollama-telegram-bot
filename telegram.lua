local geoScanner = peripheral.find("geoScanner")
local turtle = require("turtle")
local fuelThreshold = 500
local startPosition = {x = 0, y = 0, z = 0}

if not geoScanner then error("GeoScanner not found!") end

local function isValidPosition(x, y, z)
    return y >= 60 and not (y < 10 or y > 200)
end

local function moveTo(x, y, z)
    local currentX, currentY, currentZ = gps.locate(5)
    if not currentX then error("GPS signal lost!") end

    while currentX ~= x or currentY ~= y or currentZ ~= z do
        if turtle.getFuelLevel() < fuelThreshold then
            print("Low fuel, returning to start position...")
            returnToStart()
        end

        if currentY < y then
            if turtle.up() then currentY = currentY + 1 end
        elseif currentY > y then
            if turtle.down() then currentY = currentY - 1 end
        elseif currentX < x then
            if turtle.forward() then currentX = currentX + 1 end
        elseif currentX > x then
            if turtle.back() then currentX = currentX - 1 end
        elseif currentZ < z then
            turtle.turnRight()
            if turtle.forward() then currentZ = currentZ + 1 end
            turtle.turnLeft()
        elseif currentZ > z then
            turtle.turnLeft()
            if turtle.forward() then currentZ = currentZ - 1 end
            turtle.turnRight()
        end

        currentX, currentY, currentZ = gps.locate(5)
    end
end

local function returnToStart()
    moveTo(startPosition.x, startPosition.y, startPosition.z)
    print("Returned to start position.")
end

local function attackMob()
    while turtle.attack() do sleep(0.5) end
end

local function isHostileMob(entity)
    local hostileMobs = {"minecraft:zombie", "minecraft:skeleton", "minecraft:creeper", "minecraft:spider"}
    for _, mob in ipairs(hostileMobs) do
        if entity.name == mob then return true end
    end
    return false
end

local function main()
    startPosition = {x = gps.locate(5)}
    if not startPosition.x then error("Initial GPS signal lost!") end

    while true do
        local mobs = geoScanner.getClosestEntities()
        if #mobs == 0 then
            print("No mobs detected.")
            sleep(5)
        else
            local closestMob
            for _, mob in ipairs(mobs) do
                if isHostileMob(mob) and isValidPosition(mob.x, mob.y, mob.z) then
                    closestMob = mob
                    break
                end
            end

            if closestMob then
                print("Targeting mob:", closestMob.name)
                if turtle.getFuelLevel() < fuelThreshold then
                    returnToStart()
                else
                    moveTo(closestMob.x, closestMob.y, closestMob.z)
                    attackMob()
                end
            else
                print("No valid hostile mobs found.")
                sleep(5)
            end
        end
    end
end

local success, err = pcall(main)
if not success then print("Error:", err) end
