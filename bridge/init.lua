it = setmetatable({
    name = GetCurrentResourceName(),
    context = IsDuplicityVersion() and "server" or "client",
}, {
    __nexindex = function(self, name, fn)
        rawset(self, name, fn)
    end
})

cache = {
    resource = GetResourceMetadata(it.name, 'identifier', 0),
    game = GetGameName();
    version = GetResourceMetadata(it.name, 'version', 0),
    supportedFrameworks = {
        'qb-core',
        'es_extended',
        'ND_Core',
        'qbx_core'
    },
    supportedInventories = {
        'ox_inventory',
        'qb-inventory',
        'qs-inventory',
        'es_extended',
        'origen_inventory',
        'codem-inventory'
    },
}

--- Check of ox_lib is installed and enabled
if GetResourceState('ox_lib') ~= 'started' then
    lib.print.error('['..it.name..'] To use this script you need to have ox_lib installed and started bevor this script!')
    return
end

-- Function do get the farmework and core object of the server

--- Detect the framework of the server
---@param framework string | 'autodetect' | 'qb-core' | 'es_extended'
---@return table | nil
local function detectFramwork(framework)

    local function detectQbCore()
        if GetResourceState('qb-core') == 'started' or GetResourceState('qbx_core') == 'started' then
            local qbcore = exports['qb-core']:GetCoreObject()
            if qbcore then
                it.core = 'qb-core'
                return qbcore
            end
            return nil
        end
    end

    local function detectEsx()
        if GetResourceState('es_extended') == 'started' then
            local esx = exports['es_extended']:getSharedObject()
            if esx then
                it.core = 'esx'
                return esx
            end
            return nil
        end
    end

    local function detectNDCore()
        if GetResourceState('ND_Core') == 'started' then
            local ndcore = exports['ND_Core']:GetCoreObject()
            if ndcore then
                it.core = 'nd-core'
                return ndcore
            end
            return nil
        end
    end

    if framework == 'autodetect' then
        local qbcore = detectQbCore()
        if qbcore then
            return qbcore
        end

        local qbox = detectQbCore()
        if qbox then
            return qbox
        end

        local esx = detectEsx()
        if esx then
            return esx
        end

        local ndcore = detectNDCore()
        if ndcore then
            return ndcore
        end

        return nil
    else
        if not lib.table.contains(cache.supportedFrameworks, framework) then
            lib.print.error('['..it.name..'] The selected framework is not supported: ' .. framework)
        else
            if framework == 'qb-core' then
                local qbcore = detectQbCore()
                if qbcore then
                    return qbcore
                end
            elseif framework == 'qbx_core' then
                local qbox = detectQbCore()
                if qbox then
                    return qbox
                end
            elseif framework == 'es_extended' then
                local esx = detectEsx()
                if esx then
                    return esx
                end
            elseif framework == 'nd-core' then
                local ndcore = detectNDCore()
                if ndcore then
                    return ndcore
                end
            end
            return nil
        end
    end
end

--- Detect the inventory of the server
---@param inventory string | 'autodetect' | 'ox_inventory' | 'qb-inventory' | 'es_extended' | 'origen_inventory' | 'mInventory'
---@return boolean
local function detectInventory(inventory)
    local function detectOxInventory()
        if GetResourceState('ox_inventory') == 'started' then
            return true
        end
    end

    local function detectQbInventory()
        if GetResourceState('qb-inventory') == 'started' then
            return true
        end
    end

    local function detectQsInventory()
        if GetResourceState('qs-inventory') == 'started' then
            return true
        end
    end

    local function detectESXInventory()
        if GetResourceState('es_extended') == 'started' then
            return true
        end
    end

    local function detectOriginsInventory()
        if GetResourceState('origen_inventory') == 'started' then
            return true
        end
    end

    local function detectCodemInventory()
        if GetResourceState('codem-inventory') == 'started' then
            return true
        end
    end

    if inventory == 'autodetect' then
        local ox = detectOxInventory()
        if ox then
            it.inventory = 'ox'
            return ox
        end

        local qb = detectQbInventory()
        if qb then
            it.inventory = 'qb'
            return qb
        end

        local qs = detectQsInventory()
        if qs then
            if it.core == 'qb-core' then
                it.inventory = 'qb'
            else
                it.inventory = 'esx'
            end
            return qs
        end
        
        local esx = detectESXInventory()
        if esx then
            it.inventory = 'esx'
            return esx
        end

        local origen = detectOriginsInventory()
        if origen then
            it.inventory = 'origen'
            return origen
        end

        local codem = detectCodemInventory()
        if codem then
            it.inventory = 'codem'
            return codem
        end
        return false
    else
        if not lib.table.contains(cache.supportedInventories, inventory) then
            lib.print.error('['..it.name..'] The selected inventory is not supported: ' .. inventory)
            return false
        else
            if inventory == 'ox_inventory' then
                local ox = detectOxInventory()
                if ox then
                    it.inventory = 'ox'
                    return ox
                end
            elseif inventory == 'qb-inventory' then
                local qb = detectQbInventory()
                if qb then
                    it.inventory = 'qb'
                    return qb
                end
            elseif inventory == 'qs-inventory' then
                local qs = detectQsInventory()
                if qs then
                    if it.core == 'qb-core' then
                        it.inventory = 'qb'
                    else
                        it.inventory = 'esx'
                    end
                    return qs
                end
            elseif inventory == 'es_extended' then
                local esx = detectESXInventory()
                if esx then
                    it.inventory = 'esx'
                    return esx
                end
            elseif inventory == 'origen_inventory' then
                local origen = detectOriginsInventory()
                if origen then
                    it.inventory = 'origen'
                    return origen
                end
            elseif inventory == 'codem-inventory' then
                local codem = detectCodemInventory()
                if codem then
                    it.inventory = 'codem'
                    return codem
                end
            else
                return false
            end
        end
        return false
    end
end


if Config.Framework == 'autodetect' then
    CoreObject = detectFramwork('autodetect')
    if not CoreObject then
        lib.print.error('['..it.name..'] No supported framework detected! Did you rename your core resource?')
    else
        if Config.Debug then lib.print.info('['..it.name..'] Detected framework: ' .. it.core) end
    end
else
    local framework = Config.Framework
    CoreObject = detectFramwork(framework)
    if not CoreObject then
        lib.print.error('['..it.name..'] Cannot find the resource for the selcted framework: ', framework)
    else
        if Config.Debug then lib.print.info('['..it.name..'] Detected framework: ', it.core) end
    end
end

if Config.Inventory == 'autodetect' then
    local inventory = detectInventory('autodetect')
    if not inventory then
        lib.print.error('['..it.name..'] No supported inventory detected! Did you rename your inventory resource?')
    else
        if Config.Debug then lib.print.info('['..it.name..'] Detected inventory: ' .. it.inventory) end
    end
else
    local inventory = Config.Inventory
    local result = detectInventory(inventory)
    if not result then
        lib.print.info('['..it.name..'] Cannot find the resource for the selected inventory: ', inventory)
    else
        if Config.Debug then lib.print.info('['..it.name..'] Detected inventory: ', it.inventory) end
    end
end


function it.hasLoaded()
    if CoreObject and it.inventory then
        return true
    end

    return false
end