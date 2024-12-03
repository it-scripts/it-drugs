function it.round(value, numDecimalPlaces)
    if not numDecimalPlaces then return math.floor(value + 0.5) end
    local power = 10 ^ numDecimalPlaces
    return math.floor((value * power) + 0.5) / (power)
end

function it.getCoreName()
    return it.core
end

function it.getInventoryName()
    return it.inventory
end

function it.getCoreObject()
    return CoreObject
end

function it.generateUUID()
    local random = math.random
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

function it.generateCustomID(length)
    if length == nil then length = 8 end
    if length == 36 then return it.generateUUID() end
    if length > 36 then length = 36 end
    local randomId = it.generateUUID()
    return string.sub(randomId, 1, length)
end