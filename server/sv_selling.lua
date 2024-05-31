local getCopsAmount = function()
	local copsAmount = 0
	local onlinePlayers = it.getPlayers()
	for i=1, #onlinePlayers do
		local player = it.getPlayer(onlinePlayers[i])
		if player then
			local job = it.getPlayerJob(player)
			for _, v in pairs(Config.PoliceJobs) do
				if job.name == v then
					if it.getCoreName() == "qb-core" and Config.OnlyCopsOnDuty and not job.onduty then return end
					copsAmount = copsAmount + 1
				end
			end
		end
	end
	return copsAmount
end

RegisterNetEvent('it-drugs:server:initiatedrug', function(cad)
	local src = source
	local Player = it.getPlayer(src)
	if Player then
		local price = cad.price * cad.amount
		if Config.SellSettings['giveBonusOnPolice'] then
			local copsamount = getCopsAmount()
			if copsamount > 0 and copsamount < 3 then
				price = price * 1.2
			elseif copsamount >= 3 and copsamount <= 6 then
				price = price * 1.5
			elseif copsamount >= 7 and copsamount <= 10 then
				price = price * 1.7
			elseif copsamount >= 10 then
				price = price * 2.0
			end
		end
		price = math.floor(price)
		if it.hasItem(src, cad.item, cad.amount) then
			if it.removeItem(src, tostring(cad.item), cad.amount) then
				math.randomseed(GetGameTimer())
				local stealChance = math.random(0, 100)
				if stealChance < Config.SellSettings['stealChance'] then
					ShowNotification(src, _U('NOTIFICATION__STOLEN__DRUG'), 'error')
				else
					it.addMoney(src, "cash", price, "Money from Drug Selling")
					ShowNotification(src, _U('NOTIFICATION__SOLD__DRUG'):format(price), 'success')
				end
				local coords = GetEntityCoords(GetPlayerPed(src))
				SendToWebhook(src, 'sell', nil, ({item = cad.item, amount = cad.amount, price = price, coords = coords}))
				if Config.Debug then print('You got ' .. cad.amount .. ' ' .. cad.item .. ' for $' .. price) end
			else
				ShowNotification(src, _U('NOTIFICATION__SELL__FAIL'):format(cad.item), 'error')
			end
		else
			ShowNotification(src, _U('NOTIFICATION__NO__ITEM__LEFT'):format(cad.item), 'error')
		end
	end
end)

lib.callback.register('it-drugs:server:getCopsAmount', function(source)
	local copsAmount = getCopsAmount()
	return copsAmount
end)