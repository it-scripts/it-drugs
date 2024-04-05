function it.notify(source, message, type, length)
    if it.core == 'qb-core' then
        TriggerClientEvent('qb-core:client:Notify', source, message, type, length)
    elseif it.core == 'esx' then
        TriggerClientEvent('esx:showNotification', source, message, type, length)
    end
end