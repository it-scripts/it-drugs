if true then return end
if it.getCoreName() == 'esx' then return end

-- \ Locals and tables
local SoldPeds = {}
local SellZone = {}
local CurrentZone = nil
local AllowedTarget = true
local InitiateSellProgress = false

-- \ Create Zones for the drug sales
for k, v in pairs(Config.SellZones) do
    SellZone[k] = PolyZone:Create(v.points, {
        name= k,
        minZ = v.minZ,
        maxZ = v.maxZ,
        debugPoly = Config.DebugPoly,
    })
end
-- \ Play five animation for both player and ped
local function PlayGiveAnim(tped)
	local pid = PlayerPedId()
	FreezeEntityPosition(pid, true)
	-- QBCore.Functions.RequestAnimDict('mp_common')
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

local function ShowSellMenu(ped, item, amt, price)
	InitiateSellProgress = true
	local SaleMenu = {
		{
			header = tostring(amt).."x "..it.getItemLabel(item).." für "..it.Round(amt * price, 0).."$",
			isMenuHeader = true
		},
		{
			header = _U('MENU_ACCEPT_OFFER'),
			params = {
				event = 'it-drugs:salesinitiate',
				args = {
					type = 'buy',
					item = item,
					price = price,
					amt = amt,
					tped = ped
				}
			}
		},
		{
			header = _U('MENU_REJECT_OFFER'),
			params = {
				event = 'it-drugs:salesinitiate',
				args = {
					type = 'close',
					tped = ped
				}
			}
		}
	}
	exports['qb-menu']:openMenu(SaleMenu)
	SetTimeout(Config.SellTimeout*1000, function()
		if InitiateSellProgress then
			TriggerEvent("it-drugs:notify", _U('NOTIFICATION_TO_LONG'))
			TriggerEvent("qb-menu:client:closeMenu")
			SetPedAsNoLongerNeeded(ped)
		end
	end)
end

local function GetItems(drug)
    local amount = 0
    local items = QBCore.Functions.GetPlayerData().items
    for _, v in pairs(items) do
        if v.name == drug then
            amount = v.amount
            break
        end
    end
    return amount
end

local function InitiateSell(ped)
	if not CurrentZone then return end
	local index = Config.SellZoneDrugs[CurrentZone.name]
	local randamt = math.random(Config.RandomMinSell, Config.RandomMaxSell)
	local tries = 0
	for i=1, #index do
		Wait(200) -- done change this
		local data = index[math.random(1, #index)]
		local maxamt = GetItems(data.item)
		local price = data.price
		if maxamt ~= 0 then
			if randamt > maxamt then randamt = 1 end
			ShowSellMenu(ped, data.item, randamt, price)
			break
		else
			tries = tries + i
			if tries == #index then SetPedAsNoLongerNeeded(ped) TriggerEvent('QBCore:Notify', _U('NOTIFICATION_FALSE_DRUG')) end
			if Config.Debug then print('You dont have ['..data.item..'] to sell') end
		end
	end
end

-- \ Interact with the ped
local function InteractPed(ped)
	local Playerjob = QBCore.Functions.GetPlayerData().job
	SetEntityAsMissionEntity(ped, true, true)
	TaskTurnPedToFaceEntity(ped, PlayerPedId(), Config.SellTimeout*1000)
	Wait(500)
	if Playerjob.name == 'police' then
		TriggerEvent('QBCore:Notify', 'Locals hate cops!')
		SetPedAsNoLongerNeeded(ped)
		if Config.Debug then print('Police Not allowed') end
		return
	end
	local percent = math.random(1, 100)
	if percent < Config.ChanceSell then
		InitiateSell(ped)
	else
		if Config.Debug then print('Police has been notified') end
		TriggerEvent('it-drugs:notify', _U('NOTIFICATION_CALLING_COPS'))
		TaskUseMobilePhoneTimed(ped, 8000)
		PoliceAlert()
		SetPedAsNoLongerNeeded(ped)
	end
end

-- \ Initialize the drug sales
local function InitiateSales(entity)
	
	if 1 > Config.MinimumCops then
		ShowNotification(_U('NOTIFICATION_NOT_INTERESTED'))
		if Config.Debug then print('Not Enough Cops') end
	else
		local netId = NetworkGetNetworkIdFromEntity(entity)
		local isSoldtoPed = HasSoldPed(netId)
		if isSoldtoPed then ShowNotification(_U('NOTIFICATION_ALLREADY_SPOKE')) return false end
		AddSoldPed(netId)
		InteractPed(entity)
		if Config.Debug then print('Drug Sales Initiated now proceding to interact') end
	end
	
end

-- \ Blacklist Ped Models
local function isPedBlacklisted(ped)
	local model = GetEntityModel(ped)
	for i = 1, #Config.BlacklistPeds do
		if model == GetHashKey(Config.BlacklistPeds[i]) then
			return true
		end
	end
	return false
end

-- \ Sell Drugs to peds inside the sellzone
--[[ local function CreateTarget()
	exports['qb-target']:AddGlobalPed({
		options = {
			{
				icon = 'fas fa-comments',
				label = _U('TARGET_TALK'),
				action = function(entity)
					InitiateSales(entity)
				end,
				canInteract = function(entity)
					if CurrentZone then
						if not IsPedDeadOrDying(entity, false) and not IsPedInAnyVehicle(entity, false) and CurrentZone.inside and (GetPedType(entity)~=28) and (not IsPedAPlayer(entity)) and (not isPedBlacklisted(entity)) and not IsPedInAnyVehicle(PlayerPedId(), false) then
							return true
						end
					end
					return false
				end,
			}
		},
		distance = 4,
	})
end
exports('CreateTarget', CreateTarget) ]]

-- \ Remove Sell Drugs to peds inside the sellzone
--[[ local function RemoveTarget()
	exports['qb-target']:RemoveGlobalPed({"Talk"})
end ]]

-- \ This will toggle allowing/disallowing target even if inside zone
local function IsTargetAllowed(value)
	AllowedTarget = value
end

-- \ event handler to server (execute server side)
RegisterNetEvent('it-drugs:salesinitiate', function(cad)
	if cad.type == 'close' then
		InitiateSellProgress = false
		TriggerEvent("it-drugs:notify", _U('NOTIFICATION_OFFER_REJECTED'))
		TriggerEvent("qb-menu:client:closeMenu")
		SetPedAsNoLongerNeeded(cad.tped)
	else
		InitiateSellProgress = false
		PlayGiveAnim(cad.tped)
		TriggerServerEvent('it-drugs:server:initiatedrug', cad)
		SetPedAsNoLongerNeeded(cad.tped)
	end
end)


-- \ Check if inside sellzone
CreateThread(function()
	while true do
		if SellZone and next(SellZone) then
			local ped = PlayerPedId()
			local coord = GetEntityCoords(ped)
			for k, _ in pairs(SellZone) do
				if SellZone[k] then
					if SellZone[k]:isPointInside(coord) then
						SellZone[k].inside = true
                        CurrentZone = SellZone[k]
						if not SellZone[k].target then
							SellZone[k].target = true
							--CreateTarget()
							if Config.Debug then print("Target Added ["..CurrentZone.name.."]") end
						end
						if Config.Debug then print(json.encode(CurrentZone)) end
					else
						SellZone[k].inside = false
						if SellZone[k].target then
							SellZone[k].target = false
							--RemoveTarget()
							if Config.Debug then print("Target Removed ["..CurrentZone.name.."]") end
						end
					end
				end
			end
		end
		Wait(1000)
	end
end)