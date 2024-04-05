function PoliceAlert()
    -- Add Your alert system here
	-- exports['ps-dispatch']:DrugSale() -- (PS DISPATCH)
	TriggerServerEvent('police:server:policeAlert', 'Drug sale in progress') -- (DEFAULT QBCore)
	if Config.Debug then print('Police Notify Function triggered') end
end