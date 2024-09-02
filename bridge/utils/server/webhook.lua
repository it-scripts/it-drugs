local webhooks = {}

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

---@class EmbedMessage: OxClass
EmbedMessage = lib.class('EmbedMessage')

function EmbedMessage:constructor()
    ---@type table
    self['author'] = {
        ---@type string: Name of the author
        ['name'] = "it-scripts",
        ---@type string: URL to the icon
        ['icon_url'] = "",
        ---@type string: URL when clicking on the author
        ['url'] = "https://discord.it-scripts.com"
    }
    ---@type string: Title of the Embed Message
    self['title'] = "Embed Title"
    ---@type string: Description of the Embed Message
    self['description'] = nil
    ---@type number: Color of the Embed Message
    self['color'] = 0

    ---@type table: Fields of the Embed Message
    self['fields'] = {}

    ---@type table: Footer of the Embed Message
    self['footer'] = {
        ---@type string: Text of the footer
        ['text'] = "it-scripts© | "..os.date('%Y-%m-%d %H:%M:%S'),
        ---@type string: URL to the icon
        ['icon_url'] = '',
    }
end

--- Create a new EmbedMessage from a table
---@param table table
function EmbedMessage:fromTable(table)
    self['author'] = table.author
    self['title'] = table.title
    self['description'] = table.description
    self['color'] = table.color
    self['fields'] = table.fields
    self['footer'] = table.footer
end

--- Set the user of the embed message
---@param name string: Name of the user
---@param avatar string: URL to the avatar
function EmbedMessage:setUser(name, avatar)
    self['author']['name'] = name
    self['author']['icon_url'] = avatar
end

--- Set the title of the embed message
---@param title string: Title
function EmbedMessage:setTitle(title)
    self['title'] = title
end

--- Set the description of the embed message
--- @param description string: Description
function EmbedMessage:setDescription(description)
    self['description'] = description
end

--- Set the color of the embed message
---@param color number: Color code in decimal
function EmbedMessage:setColor(color)
    self['color'] = color
end

--- Add a field to the embed message
---@param field EmbedField: Field to add
function EmbedMessage:addField(field)
    table.insert(self['fields'], field)
end

--- Set the footer of the embed message
--- @param text string: Text of the footer
--- @param icon_url string: URL to the icon
--- @param timestamp string: Timestamp
function EmbedMessage:setFooter(text, icon_url, timestamp)
    self['footer']['text'] = text
    self['footer']['icon_url'] = icon_url
    if timestamp then
        self['timestamp'] = timestamp
    end
end

---@class EmbedField: OxClass
EmbedField = lib.class('EmbedField')

function EmbedField:constructor()
    ---@type string
    self['name'] = nil
    ---@type string
    self['value'] = nil
    ---@type boolean
    self['inline'] = false
end

---@param table table
function EmbedField:fromTable(table)
    self['name'] = table.name
    self['value'] = table.value
    self['inline'] = table.inline
end

---@param title string
function EmbedField:setTitle(title)
    -- Get Lenght of the title
    local titleLength = string.len(title)

    -- Check if the title is longer than 256 characters
    if titleLength > 256 then
        title = string.sub(title, 1, 253) .. '...'
    end

    self['name'] = title
end

function EmbedField:setValue(value)
    self['value'] = value
end

function EmbedField:setInline(inline)
    self['inline'] = inline
end

---@class Webhook: OxClass
---@field url string
---@field embeds EmbedMessage[]
---@field username string
---@field avatar_url string
Webhook = lib.class('Webhook')

function Webhook:constructor(id, url)
    self.id = id
    self.url = url
    self.embeds = {}
    self.username = nil
    self.avatar_url = nil

    webhooks[id] = self
end

--- Add an embed to the webhook
--- @param embed EmbedMessage: Embed to add
function Webhook:addEmbedMessage(embed)
    table.insert(self.embeds, embed)
end

--- Set the username of the webhook
--- @param username string: Username
--- @param avatar_url string: URL to the avatar
function Webhook:setUsername(username, avatar_url)
    self.username = username
    self.avatar_url = avatar_url
end

--- Send the webhook
--- @param webhook Webhook: Webhook to send
--- @param callback function: Callback function
function Webhook:send(callback)
    local data = {
        username = self.username,
        avatar_url = self.avatar_url,
        embeds = self.embeds
    }

    PerformHttpRequest(self.url, function(statusCode, response, headers)

        if statusCode == 200 or statusCode == 204 then
            if Config.Debug then
                lib.print.debug('[WEBHOOK] ' .. self.id .. ' was sent successfully!')
            end
            self.embeds = {}
            webhooks[self.url] = self
        end

        if statusCode ~= 200 and statusCode ~= 204 then
            lib.print.error('[WEBHOOK ERROR] ' .. errors[statusCode] .. ' (' .. statusCode .. ')')
        end
        if callback then
            callback(statusCode, response, headers)
        end
    end, 'POST', json.encode(data), { ['Content-Type'] = 'application/json'})
end

function GetWebhookById(webhookId)
    return webhooks[webhookId]
end