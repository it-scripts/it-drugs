local blips = {}

local function calculateCenterPoint(coords)
    -- Initialize variables
    local avgX = 0
    local avgY = 0
    local numCoords = #coords

    -- Iterate through coordinates and accumulate sums
    for i = 1, numCoords do
        avgX = avgX + coords[i].x
        avgY = avgY + coords[i].y
    end

    -- Calculate averages
    avgX = avgX / numCoords
    avgY = avgY / numCoords

    -- Create and return center point vector2
    return vector2(avgX, avgY)
end
  


CreateThread(function ()
    for k, v in pairs(Config.Zones) do
        if v.blip.display then
            local center = calculateCenterPoint(v.coords)

            local blip = AddBlipForCoord(center.x, center.y, 200.0)
            SetBlipSprite(blip, v.blip.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, 0.8)
            SetBlipColour(blip, v.blip.displayColor)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(v.blip.displayText)
            EndTextCommandSetBlipName(blip)
            table.insert(blips, blip)
        end 
    end
end)


-- Remove Blips on Resource Stop
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for k, v in pairs(blips) do
            RemoveBlip(v)
        end
    end
end)