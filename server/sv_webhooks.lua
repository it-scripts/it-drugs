local webhookUrl= "https://discord.com/api/webhooks/***********/*************************************************" -- Discord Webhook Link

local errors = {
    [200] = "Everything is fine the webhook message was sent successfully!",
    [204] = "Everything is fine the webhook message was sent successfully but without any content! (You don't need to worry about this)",

    [400] = "Your webhook message is invalid!",
    [401] = "Your webhook URL is invalid!",
    [404] = "Your webhook URL is invalide!",
    [429] = "You are being rate limited by Discord!",
    [500] = "Discord is having internal server issues!",
    [502] = "Discord is having internal server issues!",
    [503] = "Discord is having internal server issues!",
    [504] = "Discord is having internal server issues!",
}

RegisterNetEvent('it-smallheists:server:sendWebhook')
AddEventHandler('it-smallheists:server:sendWebhook', function(title, message, color, ping)
    local src = source
    sendWebhook(src, title, message, color, ping)
end)

function sendWebhook(source, title, message, color, ping)

    if not Config.Webhook['active'] then return end

    local postData = {}

    local license = 'NA'
    local discordID = 'NA'
    local fivem = 'NA'

    local nameSource = 'NA'

    if source == 0 then
        source = 'Console'
    end

    if source ~= 'Console' then

        nameSource = GetPlayerName(source)

        for k,v in pairs(GetPlayerIdentifiers(source)) do 
            if string.sub(v, 1, string.len("license:")) == "license:" then
                license = v
            elseif string.sub(v, 1, string.len("discord:")) == "discord:" then
                discordID = string.gsub(v, "discord:", "")
            elseif string.sub(v, 1, string.len("fivem:")) == "fivem:" then
                fivem = v
            end
        end
    end

    local embed = {
        ["color"] = Config.Webhook['color'] or color,
        ["author"] = {
            ["name"] = Config.Webhook['name'],
            ["icon_url"] = Config.Webhook['avatar'],
            ["url"] = Config.Webhook['avatar'],
        },
        ["fields"] = {
            {
                ["name"] = "**Player Details: **"..nameSource..' ('..source..')',
                ["value"] = "**Discord ID:** <@"..discordID.."> *("..discordID..")* \n**License:** "..license.."\n**fivem:** "..fivem,
                ["inline"] = false,
            },
        },
        ["title"] = title,
        ["description"] = message,
        ["footer"] = {
            ["text"] = os.date("%c"),
            ["icon_url"] = Config.Webhook['avatar'],
        },
    }
    if ping then
        postData = {username = Config.Webhook['name'], avatar_url = Config.Webhook['avatar'], content = '@everyone', embeds = {}}
    else
        postData = {username = Config.Webhook['name'], avatar_url = Config.Webhook['avatar'], embeds = {}}
    end
    postData.embeds[#postData.embeds + 1] = embed
    PerformHttpRequest(webhookUrl, function(err, text, headers) 
    if err == 200 or err == 204 then
    else
        print('[WEBHOOK ERROR] ' .. errors[err] .. ' (' .. err .. ')')
        Config.Webhook['active'] = false
    end
    end, 'POST', json.encode(postData), { ['Content-Type'] = 'application/json' })
end