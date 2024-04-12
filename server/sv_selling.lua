if true then return end
if it.getCoreName() == 'esx' then return end
RegisterNetEvent('it-drugs:server:initiatedrug', function(cad)
	local src = source
	local Player = it.getPlayer(src)
	if Player then
		local price = cad.price * cad.amt
		if Config.GiveBonusOnPolice then
			local copsamount = 1
			if copsamount > 0 and copsamount < 3 then
				price = price * 1.2
			elseif copsamount >= 3 and copsamount <= 6 then
				price = price * 1.5
			elseif copsamount >= 7 and copsamount <= 10 then
				price = price * 2.0
			end
		end
		price = math.floor(price)
		if it.hasItem(src, cad.item, cad.amt) then
			if it.removeItem(src, tostring(cad.item), cad.amt) then
			
				it.addMoney("cash", price, "Money from Drug Selling")
				ShowNotification(_U('NOTIFICATION_SOLD_DRUG'):format(price), 'success')
				if Config.Debug then print('You got ' .. cad.amt .. ' ' .. cad.item .. ' for $' .. price) end
			else
				ShowNotification(_U('NOTIFICATION_SELL_FAIL'):format(cad.item), 'error')
			end
		else
			ShowNotification(_U('NOTIFICATION_NO_ITEM_LEFT'):format(cad.item), 'error')
		end
	end
end)