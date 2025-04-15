local turtle = require("turtle")
local fuelThreshold = 500
local startPosition = {x = 0, y = 0, z = 0}
local chestPosition = {x = 0, y = 0, z = 0} -- Позиция контейнера с топливом

-- Функция проверки допустимости позиции
local function isValidPosition(x, y, z)
    return x and y and z and y >= 60 and y <= 200
end

-- Алгоритм A* для поиска пути
local function findPath(startX, startY, startZ, targetX, targetY, targetZ)
    local openSet = {}
    local closedSet = {}
    local cameFrom = {}

    local heuristic = function(x1, y1, z1, x2, y2, z2)
        return math.abs(x1 - x2) + math.abs(y1 - y2) + math.abs(z1 - z2)
    end

    table.insert(openSet, {x = startX, y = startY, z = startZ, g = 0, h = heuristic(startX, startY, startZ, targetX, targetY, targetZ)})

    while #openSet > 0 do
        -- Находим узел с наименьшей стоимостью f = g + h
        local current
        for _, node in ipairs(openSet) do
            if not current or (node.g + node.h) < (current.g + current.h) then
                current = node
            end
        end

        -- Если достигли цели
        if current.x == targetX and current.y == targetY and current.z == targetZ then
            local path = {}
            while cameFrom[current] do
                table.insert(path, 1, current)
                current = cameFrom[current]
            end
            return path
        end

        -- Перемещаем текущий узел в closedSet
        table.remove(openSet, table.indexOf(openSet, current))
        table.insert(closedSet, current)

        -- Проверяем соседние узлы
        local neighbors = {
            {x = current.x + 1, y = current.y, z = current.z},
            {x = current.x - 1, y = current.y, z = current.z},
            {x = current.x, y = current.y + 1, z = current.z},
            {x = current.x, y = current.y - 1, z = current.z},
            {x = current.x, y = current.y, z = current.z + 1},
            {x = current.x, y = current.y, z = current.z - 1}
        }

        for _, neighbor in ipairs(neighbors) do
            if isValidPosition(neighbor.x, neighbor.y, neighbor.z) and not table.contains(closedSet, neighbor) then
                local tentativeG = current.g + 1
                local existingNode = table.find(openSet, neighbor)

                if not existingNode or tentativeG < existingNode.g then
                    cameFrom[neighbor] = current
                    neighbor.g = tentativeG
                    neighbor.h = heuristic(neighbor.x, neighbor.y, neighbor.z, targetX, targetY, targetZ)

                    if not existingNode then
                        table.insert(openSet, neighbor)
                    end
                end
            end
        end
    end

    return nil -- Путь не найден
end

-- Функция перемещения по пути
local function followPath(path)
    for _, node in ipairs(path) do
        local currentX, currentY, currentZ = gps.locate(5)
        if not currentX then error("GPS signal lost!") end

        while currentX ~= node.x or currentY ~= node.y or currentZ ~= node.z do
            if turtle.getFuelLevel() < fuelThreshold then
                print("Low fuel, returning to start position...")
                returnToStart()
            end

            -- Разрушаем блоки, если они мешают
            if turtle.detect() then turtle.dig() end
            if turtle.detectUp() then turtle.digUp() end
            if turtle.detectDown() then turtle.digDown() end

            if currentY < node.y then
                if turtle.up() then currentY = currentY + 1 end
            elseif currentY > node.y then
                if turtle.down() then currentY = currentY - 1 end
            elseif currentX < node.x then
                if turtle.forward() then currentX = currentX + 1 end
            elseif currentX > node.x then
                if turtle.back() then currentX = currentX - 1 end
            elseif currentZ < node.z then
                turtle.turnRight()
                if turtle.forward() then currentZ = currentZ + 1 end
                turtle.turnLeft()
            elseif currentZ > node.z then
                turtle.turnLeft()
                if turtle.forward() then currentZ = currentZ - 1 end
                turtle.turnRight()
            end

            currentX, currentY, currentZ = gps.locate(5)
        end
    end
end

-- Возвращение в начальную позицию
local function returnToStart()
    local path = findPath(gps.locate(5), startPosition.x, startPosition.y, startPosition.z)
    if path then
        followPath(path)
    else
        error("Cannot find path to start position!")
    end
end

-- Атака моба
local function attackMob()
    while turtle.attack() do sleep(0.5) end
end

-- Дозаправка топлива
local function refuel()
    local path = findPath(gps.locate(5), chestPosition.x, chestPosition.y, chestPosition.z)
    if path then
        followPath(path)
        for i = 1, 16 do
            turtle.select(i)
            if turtle.refuel(0) then
                print("Refueled from slot", i)
                break
            end
        end
        returnToStart()
    else
        error("Cannot find path to fuel chest!")
    end
end

-- Основной цикл
local function main()
    local initialPosition = gps.locate(5)
    if not initialPosition then error("Initial GPS signal lost!") end
    startPosition = {x = initialPosition[1], y = initialPosition[2], z = initialPosition[3]}

    while true do
        -- Ищем мобов в непосредственной близости
        local foundMob = false
        for _ = 1, 4 do
            if turtle.attack() then
                print("Mob detected and attacked!")
                attackMob()
                foundMob = true
                break
            end
            turtle.turnRight()
        end

        if not foundMob then
            print("No mobs detected nearby. Moving forward...")
            if turtle.getFuelLevel() < fuelThreshold then
                refuel()
            end

            -- Разрушаем блоки, если они мешают
            if turtle.detect() then turtle.dig() end
            if turtle.detectUp() then turtle.digUp() end
            if turtle.detectDown() then turtle.digDown() end

            turtle.forward()
        end

        sleep(1)
    end
end

local success, err = pcall(main)
if not success then print("Error:", err) end
