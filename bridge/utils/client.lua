function it.notify(message, type, length)
    if it.core == 'qb-core' then
        CoreObject.Functions.Notify(message, type, length)
    elseif it.core == 'esx' then
        CoreObject.ShowNotification(message, type, length)
    end
end

RegisterNetEvent('it-lib:client:Notify', function(message, type, length)
    it.notify(message, type, length)
end)