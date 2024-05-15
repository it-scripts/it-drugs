function it.notify(source, message, type, length)
    TriggerClientEvent('it-lib:client:Notify', source, message, type, length)
end