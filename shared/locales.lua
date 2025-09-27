--[[
    https://github.com/it-scripts/it-drugs

    This file is licensed under GPL-3.0 or higher <https://www.gnu.org/licenses/gpl-3.0.en.html>

    Copyright © 2025 AllRoundJonU <https://github.com/allroundjonu>
]]
Locales = {}
local currentLocale = Config.Language or 'en'

-- Function to load locale data from JSON file
local function LoadLocaleFile(locale)
    local resourceName = GetCurrentResourceName()
    local path = ('locales/%s.json'):format(locale)
    local fileContent = LoadResourceFile(resourceName, path)
    
    if fileContent then
        local success, result = pcall(json.decode, fileContent)
        if success and result and result[locale] then
            return result[locale]
        else
            lib.print.error('Error loading locale file:: ', locale)
        end
    else
        lib.print.error('Locale file not found: ', path)
    end
    return nil
end

-- Function to initialize locales
function InitLocales()
    -- Dynamically detect available locale files
    local resourceName = GetCurrentResourceName()
    local localeFiles = {}
    local i = 0
    
    -- Loop through potential locale files
    while true do
        local locale = GetResourceMetadata(resourceName, 'locale_' .. i, 0)
        if not locale then break end
        table.insert(localeFiles, locale)
        i = i + 1
    end
    
    -- If no locales specified in metadata, try to find them in the locales folder
    if #localeFiles == 0 then
        -- This lists files in the locales directory (works in FiveM)
        local files = {}
        for i=0, 256 do
            local fileName = ('locales/%s.json'):format(tostring(i))
            local fileContent = LoadResourceFile(resourceName, fileName)
            if fileContent then
                local file = fileName:match('locales/(.+)%.json')
                if file then
                    table.insert(files, file)
                end
            else
                -- Try common language codes
                local commonLangs = {'en', 'de', 'fr', 'es', 'it', 'pt', 'pl', 'ru', 'nl', 'sv', 'cs', 'hu', 'tr', 'no', 'da', 'fi', 'ja', 'ko', 'zh'}
                for _, lang in ipairs(commonLangs) do
                    local langFile = ('locales/%s.json'):format(lang)
                    local langContent = LoadResourceFile(resourceName, langFile)
                    if langContent then
                        table.insert(files, lang)
                    end
                end
                break
            end
        end
        
        localeFiles = files
    end
    
    if Config.Debug then
        lib.print.info('^3Found locale files: ' .. table.concat(localeFiles, ', ') .. '^7')
    end
    
    -- Load locales from JSON files
    for _, locale in ipairs(localeFiles) do
        local localeData = LoadLocaleFile(locale)
        if localeData then
            Locales[locale] = localeData
            if Config.Debug then
                lib.print.info('^2Loaded locale: ' .. locale .. '^7')
            end
        else
            if Config.Debug then
                lib.print.info('^1Failed to load locale: ' .. locale .. '^7')
            end
        end
    end
    
    -- Ensure at least one locale is loaded (fallback to English if possible)
    if not next(Locales) then
        lib.print.info('^1No locales were loaded. Using fallback.^7')
        Locales['en'] = {
            ['missing_translation'] = 'Translation system could not be initialized'
        }
    end
    
    return true
end

-- Translation function with support for parameters
function _U(key, ...)
    local args = {...}
    local locale = Locales[currentLocale] or Locales['en'] -- Fallback to English
    
    local text = locale[key]
    if not text then
        if Config.Debug then
            lib.print.info('^1Missing translation key: ' .. key .. '^7')
        end
        return key -- Return the key as fallback
    end
    
    -- If there are arguments, format the string
    if #args > 0 and type(text) == 'string' then
        text = text:format(table.unpack(args))
    end
    
    return text
end

-- Initialize locales when the resource starts
CreateThread(function()
    InitLocales()
    if Config.Debug then
        lib.print.info('^2Locales initialized successfully^7')
    end
end)