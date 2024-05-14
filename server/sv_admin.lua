if it.getCoreName() == 'esx' then

    local ESX = exports['es_extended']:getSharedObject()

    ESX.RegisterCommand({_U('COMMAND__ADMINMENU')}, 'user', function(xPlayer, args, showError)
        local src = xPlayer.source
        if IsPlayerAceAllowed(src, 'it-drugs') then
    
            if args[1] == nil then
                ShowNotification(src, _U('NOTIFICATION__ADMINMENU__USAGE'):format(_U('COMMAND__ADMINMENU')), "info")
                return
            end
            local menuType = args[1]
            if menuType == 'plants' then
                TriggerClientEvent('it-drugs:client:showMainAdminMenu', src, {menuType = 'plants'})
            elseif menuType == 'tables' then
                TriggerClientEvent('it-drugs:client:showMainAdminMenu', src, {menuType = 'tables'})
            else
                ShowNotification(src, _U('NOTIFICATION__ADMINMENU__USAGE'):format(_U('COMMAND__ADMINMENU')), "info")
            end
        else
            -- get user license
            local userLicense = GetPlayerIdentifiers(src)[1]
            local username = GetPlayerName(src)
    
            TriggerClientEvent('it-drugs:client:showAdminAlertBox', src, {userLicense = userLicense, username = username})
        end
    end, {help = _U('NOTIFICATION__ADMINMENU__USAGE'):format(_U('COMMAND__ADMINMENU')), validate = true, arguments = {{name = 'type', help = 'plants/tables', type = 'string', optional = false, default = 'plants'}}})

    ESX.RegisterCommand({_U('COMMAND__GROUNDHASH')}, 'user', function(xPlayer, args, showError)
        local src = xPlayer.source
        if IsPlayerAceAllowed(src, 'it-drugs') then
            TriggerClientEvent('it-drugs:client:showGroundHash', src)
        else
            -- get user license
            local userLicense = GetPlayerIdentifiers(src)[1]
            local username = GetPlayerName(src)
    
            TriggerClientEvent('it-drugs:client:showAdminAlertBox', src, {userLicense = userLicense, username = username})
        end
    end, {help = _U('COMMAND__GROUNDHASH__HELP')})

elseif it.getCoreName() == 'qb-core' then
    local QbCore = exports['qb-core']:GetCoreObject()

    QbCore.Commands.Add(_U('COMMAND__ADMINMENU'), _U('NOTIFICATION__ADMINMENU__USAGE'):format(_U('COMMAND__ADMINMENU')), {{name= 'type', help = 'plants/tables'}}, true, function(source, args)
        local src = source
        if IsPlayerAceAllowed(src, 'it-drugs') then
    
            if args[1] == nil then
                ShowNotification(src, _U('NOTIFICATION__ADMINMENU__USAGE'):format(_U('COMMAND__ADMINMENU')), "info")
                return
            end
            local menuType = args[1]
            if menuType == 'plants' then
                TriggerClientEvent('it-drugs:client:showMainAdminMenu', src, {menuType = 'plants'})
            elseif menuType == 'tables' then
                TriggerClientEvent('it-drugs:client:showMainAdminMenu', src, {menuType = 'tables'})
            else
                ShowNotification(src, _U('NOTIFICATION__ADMINMENU__USAGE'):format(_U('COMMAND__ADMINMENU')), "info")
            end
        else
            -- get user license
            local userLicense = GetPlayerIdentifiers(src)[1]
            local username = GetPlayerName(src)
    
            TriggerClientEvent('it-drugs:client:showAdminAlertBox', src, {userLicense = userLicense, username = username})
        end
    end)

    QbCore.Commands.Add(_U('COMMAND__GROUNDHASH'), _U('COMMAND__GROUNDHASH__HELP'), {}, false, function(source, args)
        local src = source
        if IsPlayerAceAllowed(src, 'it-drugs') then
            TriggerClientEvent('it-drugs:client:showGroundHash', src)
        else
            -- get user license
            local userLicense = GetPlayerIdentifiers(src)[1]
            local username = GetPlayerName(src)
    
            TriggerClientEvent('it-drugs:client:showAdminAlertBox', src, {userLicense = userLicense, username = username})
        end
    end)
end