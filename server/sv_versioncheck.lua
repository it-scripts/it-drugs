--== VERSION CHECK ==--

-- pars the jason code to a table
local function parseJson(data)
    local decodedData = json.decode(data)
    return decodedData
end

local currentVersionFile = parseJson(LoadResourceFile(GetCurrentResourceName(), "version"))
local remoteVersionFile = nil
local updatePath

local function checkResourceVersion(err, responseText, headers)
    remoteVersionFile = parseJson(responseText)
    if responseText == nil or remoteVersionFile == nil then
        print("^5======================================^7")
        print(' ')
        print('^8ERROR: ^0Failed to check for update.')
        print(' ')
        print("^5======================================^7")
        return
    end
    
    if currentVersionFile.version >= remoteVersionFile.version then
        print("^5======================================^7")
        print("^2[it-drugs] - The Script is up to date!")
        print("^7Current Version: ^4" .. remoteVersionFile.version .. "^7.")
        print('^7Branch: ^4'..Config.Branch.."^7.")
        print("^5======================================^7")
        return
    end

    print("^5======================================^7")
    print('^8[it-drugs] - New update available now!')
    print('^7Current Version: ^4'..currentVersionFile.version..'^7.')
    print('^7New Version: ^4'..remoteVersionFile.version..'^7.')
    print('^7Branch: ^4'..Config.Branch.."^7.")
    print('^7Notes: ^4' ..remoteVersionFile.message.. '^7.')
    print(' ')
    print('^4Download it now on https://github.com/'..updatePath)
    print("^5======================================^7")

    SendToWebhook(0, 'message', nil, '### [it-drugs] - New update available now!\n **Current Version:** '..currentVersionFile.version..'\n **New Version:** '..remoteVersionFile.version..'\n **Branch:** '..Config.Branch..'\n **Notes:** '..remoteVersionFile.message..'\n **Download it now on:** [GitHub](https://github.com/'..updatePath..')')
end

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() and Config.EnableVersionCheck then
        Wait(3000)
        updatePath = "it-scripts/it-drugs"
        local branch = Config.Branch
        PerformHttpRequest("https://raw.githubusercontent.com/"..updatePath.."/"..branch.."/version", checkResourceVersion, "GET")
    end
end)
