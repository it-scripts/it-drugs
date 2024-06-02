ConsumableItems = {}
local ox_inventory = exports.ox_inventory

function it.hasItem(source, item, amount)
    if not amount then amount = 1 end
    if it.inventory == 'ox' then
        local itemData = ox_inventory:GetItem(source, item, nil, true)
        if itemData >= amount then return true end
	elseif it.core == "qb-core" then
		local Player = CoreObject.Functions.GetPlayer(source)
		if not Player then return false end
        local itemData = Player.Functions.GetItemByName(item)
        if not itemData then return false end
		if itemData.amount >= amount then return true end
	elseif it.core == "esx" then
		local Player = CoreObject.GetPlayerFromId(source)
		local esxItem = Player.getInventoryItem(item)
        if not esxItem then return false end
		if esxItem.count >= amount then return true end
	end
    return false
end

function it.giveItem(source, item, amount, metadata)
    if it.inventory == 'ox' then
        local added, _ = ox_inventory:AddItem(source, item, amount, metadata)
        return added
	elseif it.core == "qb-core" then
		local Player = CoreObject.Functions.GetPlayer(source)
		if not Player then return end
		if Player.Functions.AddItem(item, amount, false, metadata or {}) then
            TriggerClientEvent("inventory:client:ItemBox", source, CoreObject.Shared.Items[item], "add", amount)
            return true
        end
	elseif it.core == "esx" then
		local Player = CoreObject.GetPlayerFromId(source)
        local original_amount = Player.getInventoryItem(item)?.count
		Player.addInventoryItem(item, amount, metadata or {})
        local new_amount = Player.getInventoryItem(item)?.count
        if new_amount >= original_amount + amount then
            return true
        end
	end
    return false
end

function it.removeItem(source, item, amount, metadata)
    if it.inventory == 'ox' then
        local removedItem = ox_inventory:GetItem(source, item, metadata or nil, true)
        if removedItem >= amount then
            ox_inventory:RemoveItem(source, item, amount, metadata or nil)
            return true
        end
	elseif it.core == "qb-core" then
        local Player = CoreObject.Functions.GetPlayer(source)
		if not Player then return end
		if Player.Functions.RemoveItem(item, amount) then
            TriggerClientEvent("inventory:client:ItemBox", source, CoreObject.Shared.Items[item], "remove", amount)
            return true
        end
	elseif it.core == "esx" then
        local Player = CoreObject.GetPlayerFromId(source)
        local removedItem = Player.getInventoryItem(item)
        if removedItem.count >= amount then
            Player.removeInventoryItem(item, amount)
            return true
        end
	end
    return false
end

function it.createUsableItem(item, cb)
    if ConsumableItems[item] then print('[it-LIB] The item ' .. item .. ' is already registered as a consumable item. Skipping the registration of this item.') end
	if it.core == "qb-core" then
		CoreObject.Functions.CreateUseableItem(item, cb)
        ConsumableItems[item] = cb
	elseif it.core == "esx" then
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

function it.getItemCount(source, item)
    if it.inventory == 'ox' then
        local itemData = ox_inventory:GetItem(source, item, nil, true)
        if itemData then return itemData else return 0 end
	elseif it.core == "qb-core" then
		local Player = CoreObject.Functions.GetPlayer(source)
		if not Player then return 0 end
        local itemData = Player.Functions.GetItemByName(item)
        if itemData then return itemData.amount else return 0 end
	elseif it.core == "esx" then
		local Player = CoreObject.GetPlayerFromId(source)
		local itemData = Player.getInventoryItem(item)
		if itemData then return itemData.count else return 0 end
	end
    return 0
end

lib.callback.register('it-lib:hasItem', function(source, item, amount)
    local hasItem = it.hasItem(source, item, amount)
    --lib.print.info('The player has the item ' .. item .. ' with the amount of ' .. amount .. ': ' .. tostring(hasItem))
    return hasItem
end)

lib.callback.register('it-lib:getItemCount', function(source, item)
    local itemCount = it.getItemCount(source, item)
    return itemCount
end)

lib.callback.register('it-lib:getItemLabel', function(source, itemName)
    local itemLabel = CoreObject.GetItemLabel(itemName)
    return itemLabel
end)

RegisterNetEvent('it-lib:toggleItem', function(toggle, name, amount, metadata)
    local source = source
    it.toggleItem(source, toggle, name, amount, metadata)
end)