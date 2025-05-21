﻿--[[
    https://github.com/it-scripts/it-drugs

    This file is licensed under GPL-3.0 or higher <https://www.gnu.org/licenses/gpl-3.0.en.html>

    Copyright © 2025 AllRoundJonU <https://github.com/allroundjonu>
]]
local currentDrug = nil
local cooldowns = {}

local drugEffects = {
    ['runningSpeedIncrease'] = false,
    ['infinateStamina'] = false,
    ['moreStrength'] = false,
    ['healthRegen'] = false,
    ['foodRegen'] = false,
    ['armor'] = false,
    ['drunkWalk'] = false,
    ['psycoWalk'] = false,
    ['outOfBody'] = false,
    ['cameraShake'] = false,
    ['fogEffect'] = false,
    ['confusionEffect'] = false,
    ['whiteoutEffect'] = false,
    ['intenseEffect'] = false,
    ['focusEffect'] = false,
    ['superJump'] = false,
    ['swimming'] = false
}

local function loadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(500)
    end
end

local setDrugEffects = function(effects)

    if Config.Debug then lib.print.info('Drug Effects:', effects) end
    local ped = PlayerPedId()
    for _, effect in pairs(effects) do

        -- regex 'armor-([0-9]+)' to get the armor value
        local armor = effect:match('armor%-([0-9]+)') -- armor-99
        if armor then effect = 'armor' end

        if drugEffects[effect] == nil then if Config.Debug then lib.print.error('[setDrugEffects] | unable to find effect', effect) end return end
        drugEffects[effect] = true

        if effect == "runningSpeedIncrease" then
            SetPedMoveRateOverride(PlayerId(), 10.0)
            SetRunSprintMultiplierForPlayer(PlayerId(), 1.49)
        elseif effect == "drunkWalk" then
            CreateThread(function()
                RequestAnimSet("MOVE_M@DRUNK@VERYDRUNK")
                while not HasAnimSetLoaded("MOVE_M@DRUNK@VERYDRUNK") do
                    Wait(0)
                end
                SetPedMovementClipset(ped, "MOVE_M@DRUNK@VERYDRUNK", 200)
            end)
        elseif effect == "psycoWalk" then
            CreateThread(function()
                RequestAnimSet("MOVE_M@QUICK")
                while not HasAnimSetLoaded("MOVE_M@QUICK") do
                    Wait(0)
                end
                SetPedMovementClipset(ped, "MOVE_M@QUICK", 200)
            end)
        elseif effect == "fogEffect" then
            CreateThread(function()
                AnimpostfxPlay("DrugsDrivingIn", 5000, true)
                Wait(5000)
                AnimpostfxPlay("DrugsMichaelAliensFightIn", 100000, true)
            end)
        elseif effect == "confusionEffect" then
            CreateThread(function()
                AnimpostfxPlay("Rampage", 5000, true)
                Wait(5000)
                AnimpostfxPlay("Dont_tazeme_bro", 100000, true)
            end)
        elseif effect == "whiteoutEffect" then
            CreateThread(function()
                AnimpostfxPlay("DrugsDrivingIn", 5000, true)
                Wait(5000)
                AnimpostfxPlay("PeyoteIn", 100000, true)
            end)
        elseif effect == "intenseEffect" then
            CreateThread(function()
                AnimpostfxPlay("DrugsDrivingIn", 5000, true)
                Wait(5000)
                AnimpostfxPlay("DMT_flight_intro", 100000, true)
            end)
        elseif effect == "focusEffect" then
            CreateThread(function()
                AnimpostfxPlay("FocusIn", 100000, true)
            end)
        elseif effect == "armor" then
            -- get armor value from the effect
            local armorValue = tonumber(armor)
            SetPedArmour(ped, GetPedArmour(ped) + armorValue)
        end
    end
    if Config.Debug then lib.print.info('Drug Effects:', drugEffects) end
end

local clearDrugEffects = function()
    if Config.Debug then lib.print.info('Clearing Drug Effects') end
    local ped = PlayerPedId()

    SetPedMoveRateOverride(PlayerId(), 0.0)
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    ResetPedMovementClipset(ped, 0)
    ShakeGameplayCam("FAMILY5_DRUG_TRIP_SHAKE", 0.0)
    ShakeGameplayCam("MEDIUM_EXPLOSION_SHAKE", 0.0)

    for effect, state in pairs(drugEffects) do

        if effect == "fogEffect" and state then
            CreateThread(function()
                AnimpostfxStop("DrugsDrivingIn")
                    AnimpostfxPlay("DrugsDrivingOut", 5000, true)
                    AnimpostfxStop("DrugsMichaelAliensFightIn")
                    Wait(5000)
                    AnimpostfxStop("DrugsDrivingOut")
            end)
        elseif effect == "confusionEffect" and state then
            CreateThread(function()
                AnimpostfxStop("Rampage")
                AnimpostfxStop("Dont_tazeme_bro")
                AnimpostfxPlay("RampageOut", 5000, true)
                Wait(5000)
                AnimpostfxStop("RampageOut")
            end)
        elseif effect == "whiteoutEffect" and state then
            CreateThread(function()
                AnimpostfxPlay("DrugsDrivingOut", 5000, true)
                    AnimpostfxPlay("PeyoteOut", 5000, true)
                    AnimpostfxStop("PeyoteIn")
                    AnimpostfxStop("DrugsDrivingIn")
                    Wait(5000)
                    AnimpostfxStop("DrugsDrivingOut")
                    AnimpostfxStop("PeyoteOut")
            end)
        elseif effect == "intenseEffect" and state then
            CreateThread(function()
                AnimpostfxPlay("DrugsDrivingOut", 5000, true)
                    AnimpostfxStop("DMT_flight_intro")
                    AnimpostfxStop("DrugsDrivingIn")
                    Wait(5000)
                    AnimpostfxStop("DrugsDrivingOut")
            end)
        elseif effect == "focusEffect" and state then
            AnimpostfxStop("FocusIn")
            AnimpostfxPlay("FocusOut", 5000, false)
        elseif effect == "swimming" and state then
            SetPedConfigFlag(ped, 65, false)
        end
        drugEffects[effect] = false
    end
    -- Reset player screen effects
    currentDrug = nil
end

CreateThread(function()
    local ped = PlayerPedId()
    while true do
        if drugEffects['infinateStamina'] then
            RestorePlayerStamina(PlayerId(), 1.0)
            Wait(0)
        else
            Wait(5000)
        end
    end
end)

CreateThread(function()
    while true do
        if drugEffects['healthRegen'] then
            local ped = PlayerPedId()
            local health = GetEntityHealth(ped)
            if health < 200 then
                SetEntityHealth(ped, health + 1)
            end
            Wait(2000)
        else
            Wait(5000)
        end
    end
end)

CreateThread(function()
    while true do
        if drugEffects['outOfBody'] then
            ShakeGameplayCam("FAMILY5_DRUG_TRIP_SHAKE", 3.2)
            Wait(10000)
        else
            Wait(5000)
        end
    end
end)

CreateThread(function()
    while true do
        if drugEffects['cameraShake'] then
            ShakeGameplayCam("MEDIUM_EXPLOSION_SHAKE", 1.0)
            Wait(1100)
        else
            Wait(5000)
        end
    end
end)

CreateThread(function()
    while true do
        if drugEffects['moreStrength'] then
            local pid = PlayerId()
            local ped = PlayerPedId()
            if GetSelectedPedWeapon(ped) == GetHashKey("WEAPON_UNARMED") then
                SetPlayerMeleeWeaponDamageModifier(pid, 2.0)
            end
            Wait(5)
        else
            Wait(5000)
        end
    end
end)

CreateThread(function()
    while true do
        if drugEffects['foodRegen'] then
            FoodRegen()
        else
            Wait(5000)
        end
    end
end)

CreateThread(function()
    while true do
        if drugEffects['superJump'] then
            SetSuperJumpThisFrame(PlayerId())
            SetPedCanRagdoll(PlayerPedId(), false)
            Wait(0)
        else
            Wait(5000)
        end
    end
end)

CreateThread(function()
    while true do
        if drugEffects['swimming'] then
            SetPedConfigFlag(PlayerPedId(), 65, true)
            Wait(0)
        else
            Wait(5000)
        end
    end
end)

RegisterNetEvent('it-drugs:client:takeDrug', function(drugItem)
    local drugData = Config.Drugs[drugItem]
    local ped = PlayerPedId()

    if drugData == nil then
        ShowNotification(nil, _U('NOTIFICATION__DRUG__NO__EFFECT'), "error")
        return
    end

    if Config.Debug then lib.print.info('[takeDrug] | Drug Data:', drugData) end
    if cooldowns[drugItem] ~= nil then
        local time = GetGameTimer()
        if time > cooldowns[drugItem] then
            cooldowns[drugItem] = time + drugData.cooldown * 1000 + drugData.time * 1000
        else
            ShowNotification(nil, _U('NOTIFICATION__DRUG__COOLDOWN'), "info")
            return
        end
    else
        cooldowns[drugItem] = GetGameTimer() + (drugData.cooldown * 1000 + (drugData.time * 1000))
    end

    currentDrug = drugItem

    if drugData.animation == 'pill' then
        loadAnimDict('mp_suicide')
        TaskPlayAnim(ped, 'mp_suicide', 'pill', 3.0, 3.0, 2000, 48, 0, false, false, false)
    elseif drugData.animation == 'sniff' then
        loadAnimDict('anim@mp_player_intcelebrationmale@face_palm')
        TaskPlayAnim(ped, 'anim@mp_player_intcelebrationmale@face_palm', 'face_palm', 3.0, 3.0, 3000, 48, 0, false, false, false)
    elseif drugData.animation == 'smoke' then
        loadAnimDict('amb@world_human_smoking_pot@female@base')
        TaskPlayAnim(ped, 'amb@world_human_smoking_pot@female@base', 'base', 3.0, 3.0, 3000, 48, 0, false, false, false)
    end
    setDrugEffects(drugData.effects)

    SetTimeout(drugData.time * 1000, clearDrugEffects)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if currentDrug == nil then return end
    clearDrugEffects()
end)

lib.callback.register('it-drugs:client:isDrugOnCooldown', function(drugItem)
    local cooldown = cooldowns[drugItem]
    if not cooldown then
        return false
    else
        local time = GetGameTimer()
        if time < cooldown then
            return true
        else
            return false
        end
    end
end)

lib.callback.register('it-drugs:client:getCurrentDrugEffect', function()
    return currentDrug
end)