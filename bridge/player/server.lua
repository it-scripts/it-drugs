function it.getPlayer(source)

    if it.core == 'qb-core' then
        return CoreObject.Functions.GetPlayer(source)
    end

    if it.core == 'esx' then
        return CoreObject.GetPlayerFromId(source)
    end

    if it.core == 'ND_Core' then
        return CoreObject.getPlayer(source)
    end

    lib.print.error('['..it.name..' | getPlayer] Unable to get player object. It seems like the framework is not supported.')
    lib.print.error('['..it.name..' | getPlayer] Debug information:', "Core: "..it.core, "it:", it, "cache:", cache)
    return nil
end

function it.getPlayers()
    if it.core == 'qb-core' then
        return CoreObject.Functions.GetPlayers()
    end

    if it.core == 'esx' then
        return CoreObject.GetPlayers()
    end

    if it.core == 'ND_Core' then
        return CoreObject.getPlayers()
    end

    lib.print.error('['..it.name..' | getPlayers] Unable to collect players. It seems like the framework is not supported.')
    lib.print.error('['..it.name..' | getPlayer] Debug information:', "Core: "..it.core, "it:", it, "cache:", cache)
    return nil
end

function it.getPlayerJob(player)

    if not player then
        lib.print.error('['..it.name..' | getPlayerJob] No player object provided.')
        return nil
    end

    if it.core == 'qb-core' then

        local job = player.PlayerData.job

        return {
            name = job.name,
            label = job.label,
            grade_name = job.grade,
            grade_label = job.grade.name,
            grade_salary = job.payment,
            grade_level = job.grade.level,
            isboss = job.isboss,
            onduty = job.onduty
        }
    end

    if it.core == 'esx' then

        local job = player.getJob()

        return {
            name = job.name,
            label = job.label,
            grade_name = job.grade_name,
            grade_label = job.grade_label,
            grade_salary = job.grade_salary,
            grade_level = job.grade,
            isboss = job.grade_name == 'boss' or false,
            onduty = true
        }
    end

    if it.core == 'ND_Core' then
        local jobName, jobInfo = player.getJob()

        return {
            name = jobName,
            label = jobInfo.label,
            grade_name = jobInfo.rank,
            grade_label = jobInfo.rankName,
            grade_salary = 0,
            isboss = player.job.grade_name == 'boss' or false,
            onduty = jobInfo.isJob
        }
    end

    lib.print.error('['..it.name..' | getPlayerJob] Unable to get player job. It seems like the framework is not supported.')
    lib.print.error('['..it.name..' | getPlayerJob] Debug information:', "Core: "..it.core, "it:", it, "cache:", cache)
end

-- Money
function it.addMoney(source, moneyType, amount, reason)
   if not reason then reason = 'unknown' end
   local Player = it.getPlayer(source)

   if not Player then
       lib.print.error('['..it.name..' | addMoney] Unable to get player object.')
       return false
   end

   local types = {
        ['cash'] = {
            ['qbcore'] = 'cash',
            ['esx'] = 'money',
            ['ND_Core'] = 'cash'
        },
        ['bank'] = {
            ['qbcore'] = 'bank',
            ['esx'] = 'bank',
            ['ND_Core'] = 'bank'
        },
        ['black_money'] = {
            ['qbcore'] = 'black_money',
            ['esx'] = 'black_money',
            ['ND_Core'] = nil,
        }
    }

    if it.core == 'qb-core' then
        moneyType = types[moneyType]['qbcore']
        local success = Player.Functions.AddMoney(moneyType, amount, reason)
        return success
    end

    if it.core == 'esx' then
        moneyType = types[moneyType]['esx']
        local currentMoney = Player.getAccount(moneyType).money
        Player.addAccountMoney(moneyType, amount)
        if currentMoney + amount == currentMoney then
            lib.print.info('['..it.name..' | addMoney] Unable to add money. It seems like the money was not added.')
            return false
        end
        return true
    end

    if it.core == 'ND_Core' then
        moneyType = types[moneyType]['ND_Core']
        local success = Player.addMoney(moneyType, amount, reason)
        return success
    end

    lib.print.error('['..it.name..' | addMoney] Unable to add money. It seems like the framework is not supported.')
    lib.print.error('['..it.name..' | addMoney] Debug information:', "Core: "..it.core, "it:", it, "cache:", cache)
    return false
end

function it.removeMoney(source, moneyType, amount, reason)
    if not reason then reason = 'unknown' end
    local Player = it.getPlayer(source)

    if not Player then
        lib.print.error('['..it.name..' | removeMoney] Unable to get player object.')
        return false
    end

    local types = {
        ['cash'] = {
            ['qbcore'] = 'cash',
            ['esx'] = 'money',
            ['ND_Core'] = 'cash'
        },
        ['bank'] = {
            ['qbcore'] = 'bank',
            ['esx'] = 'bank',
            ['ND_Core'] = 'bank'
        },
        ['black_money'] = {
            ['qbcore'] = 'black_money',
            ['esx'] = 'black_money',
            ['ND_Core'] = nil,
        }
    }

    if it.core == 'qb-core' then
        moneyType = types[moneyType]['qbcore']
        local success = Player.Functions.RemoveMoney(moneyType, amount, reason)
        return success

    end
    if it.core == 'esx' then
        moneyType = types[moneyType]['esx']
        local currentMoney = Player.getAccount(moneyType).money
        Player.removeAccountMoney(moneyType, amount)
        if currentMoney - amount == currentMoney then
            lib.print.info('['..it.name..' | removeMoney] Unable to remove money. It seems like the money was not removed.')
            return false
        end
        return true
    end
    
    if it.core == 'ND_Core' then
        moneyType = types[moneyType]['ND_Core']
        local success = Player.deductMoney(moneyType, amount, reason)
        return success
    end

    lib.print.error('['..it.name..' | removeMoney] Unable to remove money. It seems like the framework is not supported.')
    lib.print.error('['..it.name..' | removeMoney] Debug information:', "Core: "..it.core, "it:", it, "cache:", cache)
end

function it.getMoney(source, moneyType)
    local Player = it.getPlayer(source)

    if not Player then
        lib.print.error('['..it.name..' | getMoney] Unable to get player object.')
        return false
    end

    local types = {
        ['cash'] = {
            ['qbcore'] = 'cash',
            ['esx'] = 'money',
            ['ND_Core'] = 'cash'
        },
        ['bank'] = {
            ['qbcore'] = 'bank',
            ['esx'] = 'bank',
            ['ND_Core'] = 'bank'
        },
        ['black_money'] = {
            ['qbcore'] = 'black_money',
            ['esx'] = 'black_money',
            ['ND_Core'] = nil
        }
    }

    if it.core == 'qb-core' then
        moneyType = types[moneyType]['qbcore']
        if Player.Functions.GetMoney(moneyType) then
            return Player.Functions.GetMoney(moneyType)
        end
    end

    if it.core == 'esx' then
        moneyType = types[moneyType]['esx']
        if Player.getAccount(moneyType) then
            return Player.getAccount(moneyType).money
        end
        
    end

    if it.core == 'ND_Core' then
        moneyType = types[moneyType]['ND_Core']
        if Player.getData(moneyType) then
            return Player.getData(moneyType)
        end
    end

    lib.print.error('['..it.name..' | getMoney] Unable to get money. It looks as if this account does not exist:', moneyType, '[ERR-MONEY-01]')
    lib.print.error('['..it.name..' | getMoney] More information about this error: https://help.it-scripts.com/errors')
    return 0
end

function it.setMoney(source, moneyType, amount)
    local Player = it.getPlayer(source)

    if not Player then
        lib.print.error('['..it.name..' | setMoney] Unable to get player object.')
        return false
    end

    local types = {
        ['cash'] = {
            ['qbcore'] = 'cash',
            ['esx'] = 'money'
        },
        ['bank'] = {
            ['qbcore'] = 'bank',
            ['esx'] = 'bank'
        },
        ['black_money'] = {
            ['qbcore'] = 'black_money',
            ['esx'] = 'black_money'
        }
    }

    if it.core == 'qb-core' then
        moneyType = types[moneyType]['qbcore']
        Player.Functions.SetMoney(moneyType, amount)
    elseif it.core == 'esx' then
        moneyType = types[moneyType]['esx']
        Player.setAccountMoney(moneyType, amount)
    end

    lib.print.error('['..it.name..' | setMoney] Unable to set money. It seems like the framework is not supported.')
    lib.print.error('['..it.name..' | setMoney] Debug information:', "Core: "..it.core, "it:", it, "cache:", cache)
end

-- Licences
function it.getLicences(source)
    local Player = it.getPlayer(source)

    if it.core == 'qb-core' then
        return Player.PlayerData.metadata['licences'] or false
    end

    if it.core == 'esx' then
        TriggerEvent('esx_license:getLicenses', source, function(licenses)
            return licenses or false
        end)
    end

    if it.core == 'ND_Core' then
        return Player.getMetadata("licenses") or false
    end

    lib.print.error('['..it.name..' | getLicences] Unable to get licences. It seems like the framework is not supported.')
    lib.print.error('['..it.name..' | getLicences] Debug information:', "Core: "..it.core, "it:", it, "cache:", cache)
    return false
end

function it.getLicence(source, licenseType)
    local Player = it.getPlayer(source)

    if it.core == 'qb-core' then
        local licenses = Player.PlayerData.metadata['licences']
        return licenses[licenseType] or false
    end

    if it.core == 'esx' then
        TriggerEvent('esx_license:getLicense', source, function(license)
            return license[licenseType] or false
        end)
    end

    if it.core == 'ND_Core' then
        local licenses = it.getLicences(source)

        for i=1, #licenses do
            local license = licenses[i]
            if licenses.type == licenseType then
                return Player.getLicense(licenses.identifier) or false
            end
        end
    end

    lib.print.error('['..it.name..' | getLicence] Unable to get licence. It seems like the framework is not supported.')
    lib.print.error('['..it.name..' | getLicence] Debug information:', "Core: "..it.core, "it:", it, "cache:", cache)
    return false
end

function it.addLicence(source, licenseType, expire)
    local Player = it.getPlayer(source)

    if it.core == 'qb-core' then
        local licenses = Player.PlayerData.metadata['licences']
        licenses[licenseType] = true
        Player.Functions.SetMetaData('licences', licenses)
        return true
    end

    if it.core == 'esx' then
        TriggerEvent('esx_license:addLicense', source, licenseType, function()
            return true
        end)
    end

    if it.core == 'ND_Core' then
        local licenses = it.getLicences(source)
        for i=1, #licenses do
            local license = licenses[i]
            if licenses.type == licenseType then
                Player.addLicense(licenseType, expire or nil)
                return true
            end
        end
        
    end

    lib.print.error('['..it.name..' | addLicence] Unable to add licence. It seems like the framework is not supported.')
    lib.print.error('['..it.name..' | addLicence] Debug information:', "Core: "..it.core, "it:", it, "cache:", cache)
    return false
end

function it.removeLicence(source, licenseType)
    local Player = it.getPlayer(source)
    if it.core == 'qb-core' then
        local licenses = Player.PlayerData.metadata['licences']
        licenses[licenseType] = false
        Player.Functions.SetMetaData('licences', licenses)
        return true
    elseif it.core == 'esx' then
        TriggerEvent('esx_license:removeLicense', source, licenseType, function()
            return true
        end)
    end


    return false
end

function it.getCitizenId(source)
    local Player = it.getPlayer(source)
    if it.core == 'qb-core' then
        local citizenid = Player.PlayerData.citizenid
        return citizenid
    end

    if it.core == 'esx' then
        local citizenid = Player.getIdentifier()
        return citizenid
    end

    if it.core == 'ND_Core' then
        local citizenid = Player.getData('identifier')
        return citizenid
    end

    lib.print.error('['..it.name..' | getCitizenId] Unable to get citizen id. It seems like the framework is not supported.')
    lib.print.error('['..it.name..' | getCitizenId] Debug information:', "Core: "..it.core, "it:", it, "cache:", cache)
    return false
end

function it.getPlayerName(source)
    local Player = it.getPlayer(source)

    if it.core == 'qb-core' then
        return Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    end

    if it.core == 'esx' then
        return Player.name
    end

    if it.core == 'ND_Core' then
        return Player.getData('name')
    end

    lib.print.error('['..it.name..' | getPlayerName] Unable to get player name. It seems like the framework is not supported.')
    lib.print.error('['..it.name..' | getPlayerName] Debug information:', "Core: "..it.core, "it:", it, "cache:", cache)
    return false
end

-- OX Callbacks
lib.callback.register('it-lib:getPlayerName', function(source)
    return it.getPlayerName(source)
end)

lib.callback.register('it-lib:getCitizenId', function(source)
    return it.getCitizenId(source)
end)

lib.callback.register('it-lib:getLicences', function(source)
    return it.getLicences(source)
end)

lib.callback.register('it-lib:getLicence', function(source, licenseType)
    return it.getLicence(source, licenseType)
end)