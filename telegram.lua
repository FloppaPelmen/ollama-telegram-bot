local geo = peripheral.find("geoScanner")
local startX, startY, startZ = gps.locate()
local hostileMobs = {}
local scannedArea = {}
local minY = 60
local fuelThreshold = 1000

local function getFuel()
  return turtle.getFuelLevel()
end

local function moveTo(x, y, z)
  local function tryForward()
    for i = 1, 5 do
      if turtle.forward() then return true end
      turtle.attack()
      sleep(0.2)
    end
    return false
  end

  local function faceDirection(dx, dz)
    local directions = { {1,0}, {0,1}, {-1,0}, {0,-1} }
    for i = 1, 4 do
      if directions[i][1] == dx and directions[i][2] == dz then
        while i ~= 1 do
          turtle.turnRight()
          i = (i % 4) + 1
        end
        break
      end
    end
  end

  local cx, cy, cz = gps.locate()
  local dx, dy, dz = x - cx, y - cy, z - cz
  for i = 1, math.abs(dy) do
    if dy > 0 then turtle.up() else turtle.down() end
  end
  while dx ~= 0 or dz ~= 0 do
    local stepX = dx ~= 0 and (dx > 0 and 1 or -1) or 0
    local stepZ = dz ~= 0 and (dz > 0 and 1 or -1) or 0
    faceDirection(stepX, stepZ)
    if tryForward() then
      dx = dx - stepX
      dz = dz - stepZ
    else
      break
    end
  end
end

local function scan()
  local ok, entities = pcall(geo.scanEntities)
  if not ok or not entities then return {} end
  local results = {}
  for _, e in pairs(entities) do
    if e.y >= minY and e.hostile and not scannedArea[e.x..","..e.y..","..e.z] then
      table.insert(results, e)
      scannedArea[e.x..","..e.y..","..e.z] = true
    end
  end
  return results
end

local function attackAround()
  for i = 1, 4 do
    turtle.attack()
    turtle.turnRight()
  end
  turtle.attackUp()
  turtle.attackDown()
end

local function returnToStart()
  moveTo(startX, startY, startZ)
end

local function main()
  while true do
    if getFuel() < fuelThreshold then returnToStart() break end
    local mobs = scan()
    if #mobs == 0 then sleep(3) goto continue end
    table.sort(mobs, function(a, b)
      local ax, ay, az = gps.locate()
      local da = math.abs(a.x - ax) + math.abs(a.y - ay) + math.abs(a.z - az)
      local db = math.abs(b.x - ax) + math.abs(b.y - ay) + math.abs(b.z - az)
      return da < db
    end)
    local target = mobs[1]
    moveTo(target.x, target.y, target.z)
    attackAround()
    ::continue::
  end
end

main()
