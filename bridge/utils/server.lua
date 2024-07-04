function it.notify(source, message, type, length)
    TriggerClientEvent('it-drugs:client:Notify', source, message, type, length)
end