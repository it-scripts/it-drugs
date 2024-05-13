RegisterCommand(_U('COMMAND__ADMINMENU'), function(source, args, rawCommand)
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
end, false)