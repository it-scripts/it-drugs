-- ┌─────────────────────────────────────────────┐
-- │ _____                 _   _                 │
-- │|  ___|   _ _ __   ___| |_(_) ___  _ __  ___ │
-- │| |_ | | | | '_ \ / __| __| |/ _ \| '_ \/ __|│
-- │|  _|| |_| | | | | (__| |_| | (_) | | | \__ \│
-- │|_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/│
-- └─────────────────────────────────────────────┘

function SendPoliceAlert(coords)
    -- Add You own police alert system here
    local message = 'Drug Dealer spotted at '..coords
    TriggerEvent('chat:addMessage', {
        args = {message}
    })
end

function ShowNotification(source, message, type)
    -- Bridge.Functions.Notify(message, type) are the default Framework notifications
    -- You can change this to your own notification systems
    if source ~= nil then -- Server Messages
        if type == 'error' then
            it.notify(source, message, "error")
        elseif type == 'success' then
            it.notify(source, message, "success")
        else
            it.notify(source, message)
        end
    else -- Client Messages
        if type == 'error' then
            it.notify(message, "error")
        elseif type == 'success' then
            it.notify(message, "success")
        else
            it.notify(message)
        end
    end
end


--- Show a progress bar
---@param progressBarData table
---@return boolean success
function ShowProgressBar(progressBarData)

    if lib.progressBar({
        duration = progressBarData.duration,
        label = progressBarData.label,
        useWhileDead = progressBarData.useWhileDead,
        disable = progressBarData.disable,
        canCancel = progressBarData.canCancel,
        controlDisables = progressBarData.controlDisables,
        anim = progressBarData.anim,
    }) then
        return true
    else
        return false
    end
end