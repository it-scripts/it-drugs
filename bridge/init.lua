it = setmetatable({
    name = "it-lib",
    context = IsDuplicityVersion() and "server" or "client",
}, {
    __nexindex = function(self, name, fn)
        rawset(self, name, fn)
    end    
})

cache = {
    resource = it.name,
    game = GetGameName();
}

-- Get Core Object
if GetResourceState('qb-core') == 'started' then
    it.core = 'qb-core'
    CoreObject = exports['qb-core']:GetCoreObject()
    RegisterNetEvent('QBCore:Client:UpdateObject', function ()
        CoreObject = exports['qb-core']:GetCoreObject()
    end)
elseif GetResourceState('es_extended') == 'started' then
    it.core = 'esx'
    CoreObject = exports['es_extended']:getSharedObject()
end


--[[ if GetResourceState('ox_inventory') ~= 'started' and GetResourceState('es_extended') == 'started' then
    it.inventory = 'esx'
elseif GetResourceState('qb-inventory') == 'started' then
    it.inventory = 'qb'
elseif GetResourceState('ox_inventory') == 'started' then
    it.inventory = 'ox'
end ]]


-- Get Inventory Object
if GetResourceState('ox_inventory') == 'started' then
    it.inventory = 'ox'
elseif GetResourceState('qb-inventory') == 'started' then
    it.inventory = 'qb'
elseif GetResourceState('ox_inventory') ~= 'started' and GetResourceState('es_extended') == 'started' then
    it.inventory = 'esx'
end

function it.hasLoaded() return true end