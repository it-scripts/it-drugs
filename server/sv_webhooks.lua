local webhookUrl= "https://discord.com/api/webhooks/*******************************************" -- Discord Webhook Link

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


local messagesToSend = {}

local function buildPlaceHolderEmbed(type, itemData)
    local embed = {
        ["color"] = 4374938,
        ["author"] = {
            ["name"] = Config.Webhook['name'],
            ["icon_url"] = Config.Webhook['avatar'],
            ["url"] = Config.Webhook['avatar'],
        }
    }
    if type == 'plant' then
        embed["title"] = "Plant: "..Config.Plants[itemData.type].label.." ("..itemData.entity..")"
        embed["description"] = "### Plant History:\n"
        embed["fields"] = {
            {
                ["name"] = "Plant Data:",
                ["value"] = "**ID:** `"..itemData.id.."`\n"..
                            "**Type:** `"..itemData.type.."`\n"..	
                            "**Coords:** `"..itemData.coords.."`\n"..
                            "**Growtime:**`" ..(itemData.growtime).."min`\n"..
                            "**Start Time:** <t:"..itemData.time..">\n"..
                            "**End Time:** <t:"..(itemData.time + (itemData.growtime * 60))..">\n",
                ["inline"] = false,
            },
        }
        embed["footer"] = {
            ["text"] = os.date("%c"),
            ["icon_url"] = Config.Webhook['avatar'],
        }
    elseif type == 'table' then
        embed["title"] = "Table: "..itemData.entity
        embed["description"] = "### Table History:\n"
        embed["fields"] = {
            {
                ["name"] = "Table Data:",
                ["value"] = "**ID:** `"..itemData.id.."`\n"..
                            "**Type:** `"..itemData.type.."`\n"..	
                            "**Coords:** `"..itemData.coords.."`\n",
                ["inline"] = false,
            },
        }
        embed["footer"] = {
            ["text"] = os.date("%c"),
            ["icon_url"] = Config.Webhook['avatar'],
        }
    elseif type == 'sell' then
        embed["title"] = "Drugs Sold"
        embed["description"] = "### Info\n"
        embed["fields"] = {
            {
                ["name"] = "Sell Data:",
                ["value"] = "**Item:** `"..itemData.item.."`\n"..	
                            "**Amount:** `"..itemData.amount.."`\n"..
                            "**Price:** `"..itemData.price.."`\n"..
                            "**Coords:** `"..itemData.coords.."`\n",
                ["inline"] = false,
            },
        }
        embed["footer"] = {
            ["text"] = os.date("%c"),
            ["icon_url"] = Config.Webhook['avatar'],
        }
    elseif type == 'message' then
        embed["title"] = "Script Message"
        embed["description"] = itemData
        embed["footer"] = {
            ["text"] = os.date("%c"),
            ["icon_url"] = Config.Webhook['avatar'],
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

function SendToWebhook(source, type, action, itemData)
    if not Config.Webhook['active'] then return end
    local entity = itemData.entity
    local embedMessage = nil
    if type == 'message' then
        embedMessage = buildPlaceHolderEmbed(type, itemData)
        PerformHttpRequest(webhookUrl, function(err, text, headers) 
            if err == 200 or err == 204 then
            else
                lib.print.info('[WEBHOOK ERROR] ' .. errors[err] .. ' (' .. err .. ')')
                Config.Webhook['active'] = false
            end
        end, 'POST', json.encode({username = Config.Webhook['name'], avatar_url = Config.Webhook['avatar'], embeds = {embedMessage}}), { ['Content-Type'] = 'application/json' })
        return
    end

    local discordID = getPlayerDiscordId(source)

    if type == 'sell' then
        embedMessage = buildPlaceHolderEmbed(type, itemData)
        embedMessage["description"] = embedMessage["description"].."> [<t:"..os.time()..":d><t:"..os.time()..":t>]: <@"..discordID..">: Sold "..itemData.amount.." "..itemData.item.." for $"..itemData.price.."\n"
        PerformHttpRequest(webhookUrl, function(err, text, headers) 
            if err == 200 or err == 204 then
            else
                lib.print.info('[WEBHOOK ERROR] ' .. errors[err] .. ' (' .. err .. ')')
                Config.Webhook['active'] = false
            end
        end, 'POST', json.encode({username = Config.Webhook['name'], avatar_url = Config.Webhook['avatar'], embeds = {embedMessage}}), { ['Content-Type'] = 'application/json' })
        return
    end

    if messagesToSend[entity] == nil then
        embedMessage = buildPlaceHolderEmbed(type, itemData)
        messagesToSend[entity] = embedMessage
    end
    local time = os.time()

    if type == 'plant' then
        if action == 'plant' then
            messagesToSend[entity]["description"] = messagesToSend[entity]["description"].."> [<t:"..time..":d><t:"..time..":t>]: <@"..discordID..">: Planted Plant\n"
        elseif action == 'fertilize' then
            messagesToSend[entity]["description"] = messagesToSend[entity]["description"].."> [<t:"..time..":d><t:"..time..":t>]: <@"..discordID..">: Fertilized Plant\n"
        elseif action == 'water' then
            messagesToSend[entity]["description"] = messagesToSend[entity]["description"].."> [<t:"..time..":d><t:"..time..":t>]: <@"..discordID..">: Watered Plant\n"
        elseif action == 'harvest' then
            messagesToSend[entity]["description"] = messagesToSend[entity]["description"].."> [<t:"..time..":d><t:"..time..":t>]: <@"..discordID..">: Harvested Plant\n"
        elseif action == 'destroy' then
            messagesToSend[entity]["description"] = messagesToSend[entity]["description"].."> [<t:"..time..":d><t:"..time..":t>]: <@"..discordID..">: Destroyed Plant\n"
        end
    elseif type == 'table' then
        if action == 'place' then
            messagesToSend[entity]["description"] = messagesToSend[entity]["description"].."> [<t:"..time..":d><t:"..time..":t>]: <@"..discordID..">: Placed Table\n"
        elseif action == 'remove' then
            messagesToSend[entity]["description"] = messagesToSend[entity]["description"].."> [<t:"..time..":d><t:"..time..":t>]: <@"..discordID..">: Removed Table\n"
        elseif action == 'process' then 
            messagesToSend[entity]["description"] = messagesToSend[entity]["description"].."> [<t:"..time..":d><t:"..time..":t>]: <@"..discordID..">: Processed Item\n"
        end
    end
end


CreateThread(function()
    if not Config.Webhook['active'] then return end
    while true do
        Wait(1000 * 60) -- Wait 1 minute
        if messagesToSend == nil then return end
        for k,v in pairs(messagesToSend) do
            PerformHttpRequest(webhookUrl, function(err, text, headers) 
                if err == 200 or err == 204 then
                    messagesToSend[k] = nil
                else
                    lib.print.info('[WEBHOOK ERROR] ' .. errors[err] .. ' (' .. err .. ')')
                    Config.Webhook['active'] = false
                end
            end, 'POST', json.encode({username = Config.Webhook['name'], avatar_url = Config.Webhook['avatar'], embeds = {v}}), { ['Content-Type'] = 'application/json' })
        end
    end
end)