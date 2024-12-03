--[[
    Here you set up the discord webhook, you can find more information about
    this in the server/webhook.lua file.
    If you dont know what a webhook is, you can read more about it here:
    https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks
]]
local webhookSettings = {
    ['active'] = false, -- Set to true to enable the webhook
    ['name'] = 'it-drugs', -- Name for the webhook
    ['avatar'] = 'https://i.imgur.com/mbM87BJ.png', -- Avatar for the webhook
    ['urls'] = {
        ['plant'] = nil, --'', -- Webhook URL for plant actions
        ['table'] = nil, --'', -- Webhook URL for table actions
        ['sell'] = nil, --'', -- Webhook URL for sell actions
        ['message'] = nil, -- Webhook URL for messages
    }
}

local errors = {
    [200] = "Everything is fine the webhook message was sent successfully!",
    [204] = "Everything is fine the webhook message was sent successfully but without any content! (You don't need to worry about this)",

    [400] = "Your webhook URL is invalid!",
    [401] = "Your webhook URL is invalid!",
    [404] = "Your webhook URL is invalide!",
    [405] = "Your webhook URL is invalide!",
    [429] = "You are being rate limited by Discord!",
    [500] = "Discord is having internal server issues!",
    [502] = "Discord is having internal server issues!",
    [503] = "Discord is having internal server issues!",
    [504] = "Discord is having internal server issues!",
}

local messagesToSend = {
    ['plant'] = {},
    ['table'] = {},
}

local function buildPlaceHolderEmbed(type, messageData)
    local embed = {
        ["color"] = 4374938,
        ["author"] = {
            ["name"] = webhookSettings['name'],
            ["icon_url"] = webhookSettings['avatar'],
            ["url"] = webhookSettings['avatar'],
        }
    }
    if type == 'plant' then
        embed["title"] = "Plant: "..Config.Plants[messageData.seed].label.." ("..messageData.netId..")"
        embed["description"] = "### Plant History:\n"
        embed["fields"] = {
            {
                ["name"] = "Plant Data:",
                ["value"] = "**ID:** `"..messageData.id.."`\n"..
                            "**Owner:** `"..messageData.owner.."`\n"..
                            "**Coords:** `"..messageData.coords.."`\n"..
                            "**Growtime:**`" ..(messageData.growtime).."min`\n"..
                            "**Start Time:** <t:"..messageData.plantTime..">\n"..
                            "**End Time:** <t:"..(messageData.plantTime + (messageData.growtime * 60))..">\n",
                ["inline"] = false,
            },
        }
        embed["footer"] = {
            ["text"] = os.date("%c"),
            ["icon_url"] = webhookSettings['avatar'],
        }
    elseif type == 'table' then
        embed["title"] = "Table: "..messageData.netId
        embed["description"] = "### Table History:\n"
        embed["fields"] = {
            {
                ["name"] = "Table Data:",
                ["value"] = "**ID:** `"..messageData.id.."`\n"..
                            "**Owner:** `"..messageData.owner.."`\n"..
                            "**Type:** `"..messageData.tableType.."`\n"..
                            "**Coords:** `"..messageData.coords.."`\n",
                ["inline"] = false,
            },
        }
        embed["footer"] = {
            ["text"] = os.date("%c"),
            ["icon_url"] = webhookSettings['avatar'],
        }
    elseif type == 'sell' then
        embed["title"] = "Drugs Sold"
        embed["description"] = "### Info\n"
        embed["fields"] = {
            {
                ["name"] = "Sell Data:",
                ["value"] = "**Item:** `"..messageData.item.."`\n"..	
                            "**Amount:** `"..messageData.amount.."`\n"..
                            "**Price:** `"..messageData.price.."`\n"..
                            "**Coords:** `"..messageData.coords.."`\n",
                ["inline"] = false,
            },
        }
        embed["footer"] = {
            ["text"] = os.date("%c"),
            ["icon_url"] = webhookSettings['avatar'],
        }
    elseif type == 'message' then
        embed["title"] = "Script Message"
        embed["description"] = messageData.description
        embed["footer"] = {
            ["text"] = os.date("%c"),
            ["icon_url"] = webhookSettings['avatar'],
        }
    end
    return embed
end

local function getPlayerDiscordId(source)
    local src = source
    local discordID = 'NA'
    for k,v in pairs(GetPlayerIdentifiers(source)) do 
        if string.sub(v, 1, string.len("discord:")) == "discord:" then
            discordID = string.gsub(v, "discord:", "")
        end
    end
    return discordID
end

function SendToWebhook(source, type, action, messageData)
    if not webhookSettings['active'] then return end
    local id = messageData.id
    local embedMessage = nil
    if type == 'message' then
        if webhookSettings['urls']['message'] == nil then return end

        embedMessage = buildPlaceHolderEmbed(type, messageData)
        PerformHttpRequest(webhookSettings['urls']['message'], function(err, text, headers) 
            if err == 200 or err == 204 then
            else
                lib.print.info('[WEBHOOK ERROR] ' .. errors[err] .. ' (' .. err .. ')')
                webhookSettings['urls']['message'] = nil
            end
        end, 'POST', json.encode({username = webhookSettings['name'], avatar_url = webhookSettings['avatar'], embeds = {embedMessage}}), { ['Content-Type'] = 'application/json' })
        return
    end

    local discordID = getPlayerDiscordId(source)

    if type == 'sell' then
        if webhookSettings['urls']['sell'] == nil then return end

        embedMessage = buildPlaceHolderEmbed(type, messageData)
        embedMessage["description"] = embedMessage["description"].."> [<t:"..os.time()..":d><t:"..os.time()..":t>]: <@"..discordID..">: Sold "..messageData.amount.." "..messageData.item.." for $"..messageData.price.."\n"
        PerformHttpRequest(webhookSettings['urls']['sell'], function(err, text, headers) 
            if err == 200 or err == 204 then
            else
                lib.print.info('[WEBHOOK ERROR] ' .. errors[err] .. ' (' .. err .. ')')
                webhookSettings['urls']['sell'] = nil
            end
        end, 'POST', json.encode({username = webhookSettings['name'], avatar_url = webhookSettings['avatar'], embeds = {embedMessage}}), { ['Content-Type'] = 'application/json' })
        return
    end

    if not messagesToSend[type][id] then
        embedMessage = buildPlaceHolderEmbed(type, messageData)
        messagesToSend[type][id] = embedMessage
    end
    local time = os.time()

    if type == 'plant' then
        if action == 'plant' then
            messagesToSend['plant'][id]["description"] = messagesToSend['plant'][id]["description"].."> [<t:"..time..":d><t:"..time..":t>]: <@"..discordID..">: Planted Plant\n"
        elseif action == 'fertilize' then
            messagesToSend['plant'][id]["description"] = messagesToSend['plant'][id]["description"].."> [<t:"..time..":d><t:"..time..":t>]: <@"..discordID..">: Fertilized Plant\n"
        elseif action == 'water' then
            messagesToSend['plant'][id]["description"] = messagesToSend['plant'][id]["description"].."> [<t:"..time..":d><t:"..time..":t>]: <@"..discordID..">: Watered Plant\n"
        elseif action == 'harvest' then
            messagesToSend['plant'][id]["description"] = messagesToSend['plant'][id]["description"].."> [<t:"..time..":d><t:"..time..":t>]: <@"..discordID..">: Harvested Plant\n"
        elseif action == 'destroy' then
            messagesToSend['plant'][id]["description"] = messagesToSend['plant'][id]["description"].."> [<t:"..time..":d><t:"..time..":t>]: <@"..discordID..">: Destroyed Plant\n"
        end
    elseif type == 'table' then
        if action == 'place' then
            messagesToSend['table'][id]["description"] = messagesToSend['table'][id]["description"].."> [<t:"..time..":d><t:"..time..":t>]: <@"..discordID..">: Placed Table\n"
        elseif action == 'remove' then
            messagesToSend['table'][id]["description"] = messagesToSend['table'][id]["description"].."> [<t:"..time..":d><t:"..time..":t>]: <@"..discordID..">: Removed Table\n"
        elseif action == 'process' then 
            messagesToSend['table'][id]["description"] = messagesToSend['table'][id]["description"].."> [<t:"..time..":d><t:"..time..":t>]: <@"..discordID..">: Processed Item\n"
        end
    end
end


CreateThread(function()
    if not webhookSettings['active'] then return end
    while true do
        Wait(1000 * 60) -- Wait 1 minute
        if messagesToSend == nil then return end
        for webhookType, messageList in pairs(messagesToSend) do
            for messageId, messages in pairs(messageList) do
                local webhookUrl = webhookSettings['urls'][webhookType]

                if webhookUrl then
                    PerformHttpRequest(webhookUrl, function(err, text, headers)
                        if err == 200 or err == 204 then
                            messagesToSend[webhookType][messageId] = nil
                        else
                            lib.print.info('[WEBHOOK ERROR] ' .. errors[err] .. ' (' .. err .. ')')
                            webhookSettings['urls'][webhookType] = nil
                        end
                    end, 'POST', json.encode({username = webhookSettings['name'], avatar_url = webhookSettings['avatar'], embeds = {messages}}), { ['Content-Type'] = 'application/json' })
                end
            end
        end
    end
end)