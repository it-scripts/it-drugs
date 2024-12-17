
-- \ Locals and tables
local SoldPeds = {}
local SellZone = {}
local currentZone = nil
local sellZones = {}

-- \ Create Zones for the drug sales
if not Config.SellEverywhere['enabled'] then
	for k, v in pairs(Config.SellZones) do
		local coords = {}
		for _, point in ipairs(v.points) do
			table.insert(coords, vector3(point.x, point.y, point.z))
		end

		sellZones[k] = lib.zones.poly({
			points = coords,
			thickness = v.thickness,
			debug = Config.DebugPoly,
			onEnter = function()
				CreateSellingTargets()
				currentZone = k
				if Config.Debug then lib.print.info("Entered Zone ["..k.."]") end
			end,
			onExit = function()
				currentZone = nil
				RemoveSellTarget()
				if Config.Debug then lib.print.info("Exited Zone ["..k.."]") end
			end,
			inside = function()
				if Config.Debug then lib.print.info("Inside Zone ["..k.."]") end
			end
		})
		if Config.Debug then lib.print.info('Zone Created: '..k) end
	end
end

CreateThread(function()
	if not Config.SellEverywhere['enabled'] and Config.ManualZoneChecker then
		while true do
			Wait(1000)
			local ped = PlayerPedId()
			local pedCoords = GetEntityCoords(ped)
			for k, zone in pairs(sellZones) do
				if zone:contains(pedCoords) then
					if currentZone ~= k then
						zone:onEnter()
						if Config.Debug then lib.print.info("Entered Zone ["..k.."]") end
					end
					if Config.Debug then lib.print.info("Inside Zone ["..k.."]") end
				elseif currentZone == k then
					zone:onExit()
					currentZone = nil
					if Config.Debug then lib.print.info("Exited Zone ["..k.."]") end
				end
			end
		end
	end
end)

-- \ Play five animation for both player and ped
local function PlayGiveAnim(tped)
	local pid = PlayerPedId()
	FreezeEntityPosition(pid, true)
	TaskPlayAnim(pid, "mp_common", "givetake2_a", 8.0, -8, 2000, 0, 1, 0,0,0)
	TaskPlayAnim(tped, "mp_common", "givetake2_a", 8.0, -8, 2000, 0, 1, 0,0,0)
	FreezeEntityPosition(pid, false)
end

-- \ Add Old Ped to table
local function AddSoldPed(entity)
    SoldPeds[entity] = true
end

--\ Check if ped is in table
local function HasSoldPed(entity)
    return SoldPeds[entity] ~= nil
end

RegisterNetEvent('it-drugs:client:checkSellOffer', function(entity)
	local copsAmount = lib.callback.await('it-drugs:server:getCopsAmount', false)

	if copsAmount < Config.MinimumCops then
		ShowNotification(nil, _U('NOTIFICATION__NOT__INTERESTED'), 'error')
		if Config.Debug then lib.print.info('Not Enough Cops Online') end
		return
	end
	
	local isSoldtoPed = HasSoldPed(entity)
	if isSoldtoPed then
		ShowNotification(nil, _U('NOTIFICATION__ALLREADY__SPOKE'), 'error')
		return
	end

	SetEntityAsMissionEntity(entity, true, true)
	TaskTurnPedToFaceEntity(entity, PlayerPedId(), -1)
	Wait(500)

	-- seed math random
	math.randomseed(GetGameTimer())
	local sellChance = math.random(0, 100)

	if sellChance > Config.SellSettings['sellChance'] then
		ShowNotification(nil, _U('NOTIFICATION__CALLING__COPS'), 'error')
		TaskUseMobilePhoneTimed(entity, 8000)
		SetPedAsNoLongerNeeded(entity)
		ClearPedTasks(PlayerPedId())
		AddSoldPed(entity)

		local coords = GetEntityCoords(entity)
		SendPoliceAlert(coords)
		return
	end

	local zoneConfig = nil
	if Config.SellEverywhere['enabled'] then
		zoneConfig = Config.SellEverywhere
	else
		if not currentZone then return end
		zoneConfig = Config.SellZones[currentZone]
	end

	local sellAmount = math.random(Config.SellSettings['sellAmount'].min, Config.SellSettings['sellAmount'].max)
	local sellItemData = nil
	local playerItems = 0

	if Config.SellSettings['onlyAvailableItems'] then
		local availabeItems = {}
		for _, itemData in pairs(zoneConfig.drugs) do
			if it.hasItem(itemData.item)then
				table.insert(availabeItems, itemData)
			end
		end

		if #availabeItems == 0 then
			ShowNotification(nil, _U('NOTIFICATION__NO__DRUGS'), 'error')
			SetPedAsNoLongerNeeded(entity)
			return
		end

		-- seed math random
		math.randomseed(GetGameTimer())
		sellItemData = availabeItems[math.random(1, #availabeItems)]
		playerItems = it.getItemCount(sellItemData.item)
	else
		sellItemData = zoneConfig.drugs[math.random(1, #zoneConfig.drugs)]
		playerItems = it.getItemCount(sellItemData.item)
		if playerItems == 0 then
			ShowNotification(nil, _U('NOTIFICATION__NO__DRUGS'), 'error')
			SetPedAsNoLongerNeeded(entity)
			return
		end
	end
	
	if playerItems < sellAmount then
		sellAmount = playerItems
	end

	TriggerEvent('it-drugs:client:showSellMenu', {item = sellItemData.item, price = sellItemData.price, amount = sellAmount, entity = entity})
	SetTimeout(Config.SellSettings['sellTimeout']*1000, function()
		if Config.Debug then lib.print.info('Sell Menu Timeout... Current Menu', lib.getOpenContextMenu()) end
		if lib.getOpenContextMenu() ~= nil then
			local currentMenu = lib.getOpenContextMenu()
			if currentMenu == 'it-drugs-sell-menu' then
				ShowNotification(nil, _U('NOTIFICATION__TO__LONG'), 'error')
				lib.hideContext(false)
				SetPedAsNoLongerNeeded(entity)
			end
		end
	end)
end) 

-- \ event handler to server (execute server side)
RegisterNetEvent('it-drugs:client:salesInitiate', function(cad)
	AddSoldPed(cad.tped)
	if cad.type == 'close' then
		ShowNotification(nil, _U('NOTIFICATION__OFFER__REJECTED'), 'error')
		SetPedAsNoLongerNeeded(cad.tped)
	else
		PlayGiveAnim(cad.tped)
		TriggerServerEvent('it-drugs:server:initiatedrug', cad)
		SetPedAsNoLongerNeeded(cad.tped)
	end
end)
