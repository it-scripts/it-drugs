--[[
    https://github.com/it-scripts/it-drugs

    This file is licensed under GPL-3.0 or higher <https://www.gnu.org/licenses/gpl-3.0.en.html>

    Copyright © 2025 AllRoundJonU <https://github.com/allroundjonu>
]]
lib.addCommand(_U('COMMAND__ADMINMENU'), {
    help = _U('NOTIFICATION__ADMINMENU__USAGE', _U('COMMAND__ADMINMENU')),
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
            ShowNotification(src, _U('NOTIFICATION__ADMINMENU__USAGE', _U('COMMAND__ADMINMENU')), "info")
            return
        end
        local menuType = args.type
        if menuType == 'plants' then
            TriggerClientEvent('it-drugs:client:showMainAdminMenu', src, {menuType = 'plants'})
        elseif menuType == 'tables' then
            TriggerClientEvent('it-drugs:client:showMainAdminMenu', src, {menuType = 'tables'})
        else
            ShowNotification(src, _U('NOTIFICATION__ADMINMENU__USAGE', _U('COMMAND__ADMINMENU')), "info")
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

lib.addCommand('changeBucket', {
    help = "Change the bucket of a player",
    params = {
        {
            name = 'playerId',
            help = 'ID of the player to change the bucket for',
            type = 'number',
            optional = false,
        },
        {
            name = 'bucketId',
            help = 'ID of the bucket to change to',
            type = 'number',
            optional = false,
        }
    }
}, function(source, args, raw)

    
    local playerId = args.playerId
    local bucketId = tonumber(args.bucketId)
    local src = source

    if playerId and bucketId then
        SetPlayerRoutingBucket(playerId, bucketId)
        print(("Player %d changed to bucket %d"):format(playerId, bucketId))
        ShowNotification(src, "Changed Player Bucket to".. bucketId, "Success")
    else
        ShowNotification(src, "Faild to change bucket", "Error")
    end
end)