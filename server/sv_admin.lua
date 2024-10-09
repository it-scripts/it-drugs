lib.addCommand(_U('COMMAND__ADMINMENU'), {
    help = _U('NOTIFICATION__ADMINMENU__USAGE'):format(_U('COMMAND__ADMINMENU')),
    params = {
        {
            name = 'type',
            help = 'plants/tables',
            type = 'string',
            optional = false,
        }
    }
}, function(source, args, raw)
    local src = source
    if IsPlayerAceAllowed(src, 'it-drugs') then
        if args.type == nil then
            ShowNotification(src, _U('NOTIFICATION__ADMINMENU__USAGE'):format(_U('COMMAND__ADMINMENU')), "info")
            return
        end
        local menuType = args.type
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

lib.addCommand(_U('COMMAND__GROUNDHASH'), {
    help = _U('COMMAND__GROUNDHASH__HELP')
}, function(source, args, raw)
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