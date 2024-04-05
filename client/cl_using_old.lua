local currentDrug = nil

-- Effects need while loop
local drugEffects = {
    infinateStamina = false,
    healthRegen = false,
    foodRegen = false,
    cameraShake = false,
    strength = false,
    outOfBody = false
}

-- Status Effects (Effects that need to be removed)
local runningSpeedIncrease = false
local drunkWalk = false
local psycoWalk = false
local fogEffect = false
local confusionEffect = false
local whiteoutEffect = false
local intenseEffect = false
local focusEffect = false

local function loadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(500)
    end
end

local addDrugEffect = function(effect)
    local ped = PlayerPedId()

    if drugEffects[effect] == nil then return end
    drugEffects[effect] = true

    if effect == "infinateStamina" then
        runningSpeedIncrease = true
        SetPedMoveRateOverride(PlayerId(), 10.0)
        SetRunSprintMultiplierForPlayer(PlayerId(), 1.49)
    elseif effect == "drunkWalk" then
        loadAnimDict("MOVE_M@DRUNK@VERYDRUNK")
        SetPedMovementClipset(ped, "MOVE_M@DRUNK@VERYDRUNK", true)
        drunkWalk = true
    elseif effect == "psycoWalk" then
        loadAnimDict("MOVE_M@QUICK")
        SetPedMovementClipset(ped, "MOVE_M@QUICK", true)
        psycoWalk = true
    elseif effect == "fogEffect" then
        AnimpostfxPlay("DrugsDrivingIn", 30000, true)
        AnimpostfxPlay("DrugsMichaelAliensFightIn", 100000, true)
        fogEffect = true
    elseif effect == "confusionEffect" then
        AnimpostfxPlay("Rampage", 30000, true)
        AnimpostfxPlay("Dont_tazeme_bro", 30000, true)
    elseif effect == "whiteoutEffect" then
        AnimpostfxPlay("DrugsDrivingIn", 30000, true)
        nimpostfxPlay("PeyoteIn", 100000, true)
        whiteoutEffect = true
    elseif effect == "intenseEffect" then
        AnimpostfxPlay("DrugsDrivingIn", 30000, true)
        AnimpostfxPlay("DMT_flight_intro", 100000, true)
        intenseEffect = true
    elseif effect == "focusEffect" then
        AnimpostfxPlay("FocusIn", 10000, true)
        focusEffect = true
    end
end

local clearDrugEffecst = function()

    print('Clearing Drug Effects')

    local playerPed = PlayerPedId()

    ShakeGameplayCam("MEDIUM_EXPLOSION_SHAKE", 0.0)
    ShakeGameplayCam("FAMILY5_DRUG_TRIP_SHAKE", 0.0)

    if runningSpeedIncrease then
        SetPedMoveRateOverride(playerPed, 0.0)
        SetRunSprintMultiplierForPlayer(playerPed, 1.0)
        runningSpeedIncrease = false
    end 
    if drunkWalk or psycoWalk then
        ResetPedMovementClipset(playerPed, 0)
        drunkWalk = false
        psycoWalk = false
    end

    if fogEffect then
        CreateThread(function()
            AnimpostfxStop("DrugsDrivingIn")
            AnimpostfxPlay("DrugsDrivingOut", 20000, true)
            AnimpostfxStop("DrugsMichaelAliensFightIn")
            Wait(20000)
            AnimpostfxStop("DrugsDrivingOut")
            fogEffect = false
        end)
    end

    if confusionEffect then
        CreateThread(function()
            AnimpostfxStop("DMT_flight_intro")
            AnimpostfxPlay("DMT_flight_outro", 20000, true)
            Wait(20000)
            AnimpostfxStop("DMT_flight_outro")
            confusionEffect = false
        end)
    end
    
    if whiteoutEffect then
        CreateThread(function()
            AnimpostfxStop("DrugsDrivingIn")
            AnimpostfxPlay("DrugsDrivingOut", 20000, true)
            AnimpostfxStop("DrugsMichaelAliensFightIn")
            Wait(20000)
            AnimpostfxStop("DrugsDrivingOut")
            whiteoutEffect = false
        end)
    end
    
    if intenseEffect then
        CreateThread(function()
            AnimpostfxStop("DrugsDrivingIn")
            AnimpostfxPlay("DrugsDrivingOut", 20000, true)
            AnimpostfxStop("DrugsMichaelAliensFightIn")
            Wait(20000)
            AnimpostfxStop("DrugsDrivingOut")
            intenseEffect = false
        end)
    end
   
    if focusEffect then
        CreateThread(function()
            AnimpostfxStop("FocusIn")
            AnimpostfxPlay("FocusOut", 10000, true)
            focusEffect = false
        end)
    end
end

RegisterNetEvent('it-drugs:client:takeDrug', function(drugItem)
    print('Drug Used: '..drugItem)
    if currentDrug ~= nil then
        QBCore.Functions.Notify("You are already on a drug..", "error")
        return
    end

    local drug = Config.Drugs[drugItem]
    local playerPed = PlayerPedId()

    print(drugItem)
    print(drug)
    if drug == nil then return end
    if drug.animation == 'pill' then
        loadAnimDict('mp_suicide')
        TaskPlayAnim(playerPed, 'mp_suicide', 'pill', 3.0, 3.0, 2000, 48, 0, false, false, false)
    elseif drug.animation == 'sniff' then
        loadAnimDict('anim@mp_player_intcelebrationmale@face_palm')
        TaskPlayAnim(playerPed, 'anim@mp_player_intcelebrationmale@face_palm', 'face_palm', 3.0, 3.0, 3000, 48, 0, false, false, false)
    elseif drug.animation == 'smoke' then
        loadAnimDict('amb@world_human_smoking_pot@female@base')
        TaskPlayAnim(playerPed, 'amb@world_human_smoking_pot@female@base', 'base', 3.0, 3.0, 3000, 48, 0, false, false, false)
    end

    for _, effect in ipairs(drug.effects) do
        addDrugEffect(effect)
    end

    Wait(drug.time * 1000)

    clearDrugEffecst()
end)

-- Theads
CreateThread(function()
    while true do
        if drugEffects.infinateStamina then
            RestorePlayerStamina(PlayerId(), 1.0)
            Wait(0)
        else
            Wait(1000)
        end
    end
end)

CreateThread(function()
    while true do
        if drugEffects.healthRegen then
            local ped = PlayerPedId()
            local health = GetEntityHealth(playerPed)
            if health < 200 then
                SetEntityHealth(ped, health + 5)
            end
            Wait(3000)
        else
            Wait(3000)
        end
    end
end)

CreateThread(function()
    while true do
        if drugEffects.foodRegen then
            TriggerEvent("QBCore:Server:SetMetaData", "hunger", 40000)
            TriggerEvent("QBCore:Server:SetMetaData", "thirst", 20000)
            Citizen.Wait(4000)
        else
            Wait(1000)
        end
    end
end)

CreateThread(function()
    while true do
        if drugEffects.cameraShake then
            ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", 0.02)
            Wait(1100)
        else
            Wait(1000)
        end
    end
end)

CreateThread(function()
    while true do
        if drugEffects.strength then
            local pid = PlayerId()
            local ped = PlayerPedId()
            if GetSelectedPedWeapon(ped) == GetHashKey("WEAPON_UNARMED") then
                SetPlayerMeleeWeaponDamageModifier(pid, 2.0)
            end
            Citizen.Wait(5)
        else
            Citizen.Wait(1000)
        end
    end
end)

CreateThread(function()
    while true do
        if drugEffects.outOfBody then
            ShakeGameplayCam("FAMILY5_DRUG_TRIP_SHAKE", 3.2)
            Citizen.Wait(10000)
        else
            Citizen.Wait(1000)
        end
    end
end)