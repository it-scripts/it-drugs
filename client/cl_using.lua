local infinateStamina = false
local healthRegen = false
local foodRegen = false
local cameraShake = false
local strength = false
local outOfBody = false

local function loadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(500)
    end
end

Citizen.CreateThread(
    function()
        while true do
            if healthRegen then
                local ped = PlayerPedId()
                local health = GetEntityHealth(ped)
                SetEntityHealth(ped, health + 5)
                Citizen.Wait(3000)
            else
                Citizen.Wait(3000)
            end
        end
    end
)

Citizen.CreateThread(
    function()
        while true do
            if outOfBody then
                local pid = PlayerId()
                ShakeGameplayCam("FAMILY5_DRUG_TRIP_SHAKE", 3.2)
                Citizen.Wait(10000)
            else
                Citizen.Wait(1000)
            end
        end
    end
)

Citizen.CreateThread(
    function()
        while true do
            if cameraShake then
                local pid = PlayerId()
                ShakeGameplayCam("MEDIUM_EXPLOSION_SHAKE", 0.2)
                Citizen.Wait(1100)
            else
                Citizen.Wait(1000)
            end
        end
    end
)

Citizen.CreateThread(
    function()
        while true do
            if infinateStamina then
                local pid = PlayerId()
                RestorePlayerStamina(pid, 1.0)
                Citizen.Wait(0)
            else
                Citizen.Wait(1000)
            end
        end
    end
)

Citizen.CreateThread(function()
    while true do
        if foodRegen then
            --TriggerEvent("QBCore:Server:SetMetaData", "hunger", 40000)
            --TriggerEvent("QBCore:Server:SetMetaData", "thirst", 20000)
            Citizen.Wait(4000)
        else
            Citizen.Wait(1000)
        end
    end
end)


Citizen.CreateThread(
    function()
        while true do
            if strength then
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
    end
)

function addEffect(effect, status)
    local ped = PlayerPedId()

    if effect == "runningSpeedIncrease" then
        if status then
            Citizen.CreateThread(
                function()
                    Citizen.Wait(30000)
                    SetPedMoveRateOverride(PlayerId(), 10.0)
                    SetRunSprintMultiplierForPlayer(PlayerId(), 1.49)
                end
            )
        else
            SetPedMoveRateOverride(PlayerId(), 0.0)
            SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
        end
    elseif effect == "infinateStamina" then
        if status then
            Citizen.CreateThread(
                function()
                    Citizen.Wait(30000)
                    infinateStamina = true
                end
            )
        else
            infinateStamina = false
        end
    elseif effect == "moreStrength" then
        if status then
            Citizen.CreateThread(
                function()
                    Citizen.Wait(30000)
                    strength = true
                end
            )
        else
            strength = false
        end
    elseif effect == "healthRegen" then
        if status then
            Citizen.CreateThread(
                function()
                    Citizen.Wait(30000)
                    healthRegen = true
                end
            )
        else
            healthRegen = false
        end
    elseif effect == "foodRegen" then
        if status then
            Citizen.CreateThread(
                function()
                    Citizen.Wait(30000)
                    foodRegen = true
                end
            )
        else
            foodRegen = false
        end
    elseif effect == "drunkWalk" then
        if status then
            Citizen.CreateThread(
                function()
                    RequestAnimSet("MOVE_M@DRUNK@VERYDRUNK")
                    while not HasAnimSetLoaded("MOVE_M@DRUNK@VERYDRUNK") do
                        Citizen.Wait(0)
                    end

                    Citizen.Wait(30000)
                    SetPedMovementClipset(ped, "MOVE_M@DRUNK@VERYDRUNK", true)
                end
            )
        else
            ResetPedMovementClipset(ped, 0)
        end
    elseif effect == "psycoWalk" then
        if status then
            Citizen.CreateThread(
                function()
                    RequestAnimSet("MOVE_M@QUICK")
                    while not HasAnimSetLoaded("MOVE_M@QUICK") do
                        Citizen.Wait(0)
                    end

                    Citizen.Wait(30000)
                    SetPedMovementClipset(ped, "MOVE_M@QUICK", true)
                end
            )
        else
            ResetPedMovementClipset(ped, 0)
        end
    elseif effect == "outOfBody" then
        if status then
            Citizen.CreateThread(
                function()
                    Citizen.Wait(30000)
                    outOfBody = true
                end
            )
        else
            ShakeGameplayCam("FAMILY5_DRUG_TRIP_SHAKE", 0.0)
            outOfBody = false
        end
    elseif effect == "cameraShake" then
        if status then
            Citizen.CreateThread(
                function()
                    Citizen.Wait(30000)
                    cameraShake = true
                end
            )
        else
            ShakeGameplayCam("MEDIUM_EXPLOSION_SHAKE", 0.0)
            cameraShake = false
        end
    elseif effect == "fogEffect" then
        if status then
            Citizen.CreateThread(
                function()
                    AnimpostfxPlay("DrugsDrivingIn", 30000, true)
                    Citizen.Wait(30000)

                    AnimpostfxPlay("DrugsMichaelAliensFightIn", 100000, true)
                end
            )
        else
            Citizen.CreateThread(
                function()
                    AnimpostfxStop("DrugsDrivingIn")
                    AnimpostfxPlay("DrugsDrivingOut", 20000, true)
                    AnimpostfxStop("DrugsMichaelAliensFightIn")
                    Citizen.Wait(20000)
                    AnimpostfxStop("DrugsDrivingOut")
                end
            )
        end
    elseif effect == "confusionEffect" then
        if status then
            Citizen.CreateThread(
                function()
                    AnimpostfxPlay("Rampage", 30000, true)
                    Citizen.Wait(30000)
                    AnimpostfxPlay("Dont_tazeme_bro", 30000, true)
                end
            )
        else
            Citizen.CreateThread(
                function()
                    AnimpostfxStop("Rampage")
                    AnimpostfxStop("Dont_tazeme_bro")
                    AnimpostfxPlay("RampageOut", 20000, true)
                    Citizen.Wait(20000)
                    AnimpostfxStop("RampageOut")
                end
            )
        end
    elseif effect == "whiteoutEffect" then
        if status then
            Citizen.CreateThread(
                function()
                    AnimpostfxPlay("DrugsDrivingIn", 30000, true)
                    Citizen.Wait(30000)
                    AnimpostfxPlay("PeyoteIn", 100000, true)
                end
            )
        else
            Citizen.CreateThread(
                function()
                    AnimpostfxPlay("DrugsDrivingOut", 20000, true)
                    AnimpostfxPlay("PeyoteOut", 20000, true)
                    AnimpostfxStop("PeyoteIn")
                    AnimpostfxStop("DrugsDrivingIn")
                    Citizen.Wait(20000)
                    AnimpostfxStop("DrugsDrivingOut")
                    AnimpostfxStop("PeyoteOut")
                end
            )
        end
    elseif effect == "intenseEffect" then
        if status then
            Citizen.CreateThread(
                function()
                    AnimpostfxPlay("DrugsDrivingIn", 30000, true)
                    Citizen.Wait(30000)
                    AnimpostfxPlay("DMT_flight_intro", 100000, true)
                end
            )
        else
            Citizen.CreateThread(
                function()
                    AnimpostfxPlay("DrugsDrivingOut", 20000, true)
                    AnimpostfxStop("DMT_flight_intro")
                    AnimpostfxStop("DrugsDrivingIn")
                    Citizen.Wait(20000)
                    AnimpostfxStop("DrugsDrivingOut")
                end
            )
        end
    elseif effect == "focusEffect" then
        if status then
            Citizen.CreateThread(
                function()
                    AnimpostfxPlay("FocusIn", 100000, true)
                end
            )
        else
            AnimpostfxStop("FocusIn")
            AnimpostfxPlay("FocusOut", 10000, false)
        end
    end
end

RegisterNetEvent('it-drugs:client:takeDrug', function(drugItem)
    print('Drug Used: '..drugItem)
    --[[ if currentDrug ~= nil then
        QBCore.Functions.Notify("You are already on a drug..", "error")
        return
    end ]]

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
        addEffect(effect, true)
    end

    Wait(drug.time * 1000)

    for _, effect in ipairs(drug.effects) do
        addEffect(effect, false)
    end
end)

