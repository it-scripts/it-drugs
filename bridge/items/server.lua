ConsumableItems = {}
local ox_inventory = exports.ox_inventory
local origen_inventory = exports.origen_inventory

--- Check if the player has the item in the inventory.
---@param source number: The player's server ID.
---@param item string: The item name.
---@param amount number | nil : The amount of the item.
---@return boolean: If the player has the item.
function it.hasItem(source, item, amount, metadata)
    if not amount then amount = 1 end

    if it.inventory == 'ox' then
        local itemData = ox_inventory:GetItem(source, item, metadata or nil, true)
        if itemData then
            if itemData >= amount then return true else return false end
        end
    end

    if it.inventory == 'origen' then
        local itemCount = origen_inventory:GetItemCount(source, item, metadata or nil, true)
        if itemCount then
            if itemCount >= amount then return true else return false end
        end
    end

    if it.inventory == 'codem' then
        local hasItem = exports['codem-inventory']:GetItemsTotalAmount(source, item)
        if hasItem then
            if hasItem >= amount then return true else return false end
        end
    end

    -- Failback to the default framwork inventory functions --

	if it.core == "qb-core" then
		local Player = CoreObject.Functions.GetPlayer(source)
		if not Player then return false end
        local itemData = Player.Functions.GetItemByName(item)
        if itemData ~= nil then
            if itemData.amount >= amount then return true else return false end
        else return false
        end
    end

	if it.core == "esx" then
		local Player = CoreObject.GetPlayerFromId(source)
		local esxItem = Player.getInventoryItem(item)
        if esxItem then
            if esxItem.count >= amount then return true else return false end
        end
	end

    -- Error Messages when the function fails --
    lib.print.error('[' ..it.name..' | hasItem] There was an error while cheching if the player has the item ' .. item .. ' in the inventory. [ERR-INV-01]')
    lib.print.error('[' ..it.name..' | hasItem] Need more information about this error? Look here https://help.it-scripts.com/errors/inventory')
    return false
end

--- Give the player an item.
---@param source number: The player's server ID.
---@param item string: The item name.
---@param amount number: The amount of the item.
---@param metadata table | nil: The metadata of the item.
---@return boolean: If the item was given to the player.
function it.giveItem(source, item, amount, metadata)

    if not amount then amount = 1 end

    if it.inventory == 'ox' then
        local added, _ = ox_inventory:AddItem(source, item, amount, metadata or nil)
        return added
    end

    -- TODO: Check if there is a feedback
    if it.inventory == 'origen' then
        local added, _ = origen_inventory:AddItem(source, item, amount, nil, nil, metadata or nil)
        return added
    end

    -- TODO: Check if there is a feedback
    if it.inventory == 'codem' then
        local added = exports['codem-inventory']:AddItem(source, item, amount, nil, metadata or nil)
        return added
    end

    -- Failback to the default framwork inventory functions --

	if it.core == "qb-core" then
		local Player = CoreObject.Functions.GetPlayer(source)
		if not Player then return end
		if Player.Functions.AddItem(item, amount, false, metadata or {}) then
            TriggerClientEvent("inventory:client:ItemBox", source, CoreObject.Shared.Items[item], "add", amount)
            return true
        end
    end
	
    if it.core == "esx" then
		local Player = CoreObject.GetPlayerFromId(source)
        local original_amount = Player.getInventoryItem(item)?.count
		Player.addInventoryItem(item, amount, metadata or {})
        local new_amount = Player.getInventoryItem(item)?.count
        if new_amount >= original_amount + amount then
            return true
        end
	end

    -- Error Messages when the function fails --
    lib.print.error('[bridge | giveItem] There was an error while giving the player the item ' .. item .. ' in the inventory. [ERR-INV-02]')
    lib.print.error('[bridge | giveItem] Need more information about this error? Look here https://help.it-scripts.com/errors/inventory')
    return false
end

lib.callback.register('it-drugs:server:giveItem', function(source, item, amount, metadata)
    local added = it.giveItem(source, item, amount, metadata)
    return added
end)

--- Remove the item from the player's inventory.
---@param source number: The player's server ID.
---@param item string: The item name.
---@param amount number: The amount of the item.
---@param metadata table | nil: The metadata of the item.
---@return boolean
function it.removeItem(source, item, amount, metadata)

    if not amount then amount = 1 end

    if it.inventory == 'ox' then
        local removedItem = ox_inventory:GetItem(source, item, metadata or nil, true)
        if removedItem >= amount then
            ox_inventory:RemoveItem(source, item, amount, metadata or nil)
            return true
        else
            if Config.Debug then lib.print.info('[bridge | removeItem] The player does not have the item ' .. item .. ' in the inventory.') end
            return false
        end
    end

    if it.inventory == 'origen' then
        local removedItem = origen_inventory:GetItemCount(source, item, metadata or nil, true)
        if removedItem >= amount then
            origen_inventory:RemoveItem(source, item, amount, nil, metadata or nil)
            return true
        end
    end

    if it.inventory == 'codem' then
        local removedItem = exports['codem-inventory']:GetItemsTotalAmount(source, item)
        if removedItem >= amount then
            exports['codem-inventory']:RemoveItem(source, item, amount) -- slot can be added as a third parameter
            return true
        end
    end
    
    -- Failback to the default framwork inventory functions --

	if it.core == "qb-core" then
        local Player = CoreObject.Functions.GetPlayer(source)
		if not Player then return false end
		if Player.Functions.RemoveItem(item, amount) then
            TriggerClientEvent("inventory:client:ItemBox", source, CoreObject.Shared.Items[item], "remove", amount)
            return true
        end
    end

	if it.core == "esx" then
        local Player = CoreObject.GetPlayerFromId(source)
        if not Player then return false end
        local removedItem = Player.getInventoryItem(item)
        if removedItem.count >= amount then
            Player.removeInventoryItem(item, amount)
            return true
        end
	end

    -- Error Messages when the function fails --
    lib.print.error('[bridge | removeItem] There was an error while removing the item ' .. item .. ' from the inventory. [ERR-INV-03]')
    lib.print.error('[bridge | removeItem] Need more information about this error? Look here https://help.it-scripts.com/errors/inventory')
    return false
end

lib.callback.register('it-drugs:server:removeItem', function(source, item, amount, metadata)
    local removed = it.removeItem(source, item, amount, metadata)
    return removed
end)

--- Create a usable item.
---@param item string: The item name.
---@param cb function: The callback function.
function it.createUsableItem(item, cb)
    if ConsumableItems[item] then print('[it-lib] The item ' .. item .. ' is already registered as a consumable item. Skipping the registration of this item.') end
	
    if it.inventory == 'origen' then
        origen_inventory:CreateUseableItem(item, cb)
        ConsumableItems[item] = cb
    end
    
    -- Failback to the default framwork inventory functions --

    if it.core == "qb-core" then
		CoreObject.Functions.CreateUseableItem(item, cb)
        ConsumableItems[item] = cb
    end

	if it.core == "esx" then
		CoreObject.RegisterUsableItem(item, cb)
        ConsumableItems[item] = cb
    end
end

function it.toggleItem(source, toggle, name, amount, metadata)
    if toggle == 1 or toggle == true then
        it.giveItem(source, name, amount, metadata or nil)
    elseif toggle == 0 or toggle == false then
        it.removeItem(source, name, amount, metadata or nil)
    end
end

--- Get the item count of a specific item in the player's inventory.
---@param source number: The player's server ID.
---@param item string: The item name.
---@param metadata table | nil: The metadata of the item.
---@return number: The amount of the item.
function it.getItemCount(source, item, metadata)
    if it.inventory == 'ox' then
        local itemData = ox_inventory:GetItem(source, item, nil, true)
        if itemData then return itemData else
            lib.print.error('[bridge | getItemCount] There was an error while getting the item count of ' .. item .. ' in the inventory. [ERR-INV-04]')
            return 0
        end
    end

    if it.inventory == 'origen' then
        local itemCount = origen_inventory:GetItemCount(source, item, metadata or nil, true)
        if itemCount then return itemCount else
            lib.print.error('[bridge | getItemCount] There was an error while getting the item count of ' .. item .. ' in the inventory. [ERR-INV-05]')
            return 0
        end
    end

    if it.inventory == 'codem' then
        local itemCount = exports['codem-inventory']:GetItemAmount(source, item)
        if itemCount then return itemCount else
            lib.print.error('[bridge | getItemCount] There was an error while getting the item count of ' .. item .. ' in the inventory. [ERR-INV-06]')
            return 0
        end
    end

    -- Failback to the default framwork inventory functions --

	if it.core == "qb-core" then
		local Player = CoreObject.Functions.GetPlayer(source)
		if not Player then return 0 end
        local itemData = Player.Functions.GetItemByName(item)
        if itemData then return itemData.amount else return 0 end
    end

    if it.core == "esx" then
		local Player = CoreObject.GetPlayerFromId(source)
		local itemData = Player.getInventoryItem(item)
		if itemData then return itemData.count else return 0 end
	end

    lib.print.error('[bridge | getItemCount] There was an error while getting the item count of ' .. item .. ' in the inventory. [ERR-INV-07]')
    return 0
end

--- Get the item label of a specific item.
--- @param source number: The player's server ID.
--- @param itemName string: The item name.
--- @return string | nil: The item label.
function it.getItemLabel(source, itemName)
    local itemLabel
    if it.inventory == 'ox' then
        itemLabel = lib.callback.await('it-lib:client:getItemLabel', source, itemName)
    end

    if it.inventory == 'origen' then
        if origen_inventory.GetItemLabel then
            itemLabel = origen_inventory.GetItemLabel(itemName)
        end
    end

    if it.inventory == 'codem' then
        if exports['codem-inventory']:GetItemLabel(itemName) then
            itemLabel = exports['codem-inventory']:GetItemLabel(itemName)
        end
    end

    if it.core == 'qb-core' then
        if CoreObject.Shared.Items[itemName] then
            itemLabel = CoreObject.Shared.Items[itemName].label
        end
    end
    if it.core == 'esx' then
        if CoreObject.GetItemLabel then
            itemLabel = CoreObject.GetItemLabel(itemName)
        end
    end
    return itemLabel or itemName
end

lib.callback.register('it-lib:server:getItemLabel', function(source, itemName)
    local itemLabel = it.getItemLabel(source, itemName)
    return itemLabel
end)

lib.callback.register('it-lib:hasItem', function(source, item, amount)
    local hasItem = it.hasItem(source, item, amount)
    return hasItem
end)

lib.callback.register('it-lib:getItemCount', function(source, item)
    local itemCount = it.getItemCount(source, item)
    return itemCount
end)

RegisterNetEvent('it-lib:toggleItem', function(toggle, name, amount, metadata)
    local source = source
    it.toggleItem(source, toggle, name, amount, metadata)
end)