function it.getPlayer(source)
    if it.core == 'qb-core' then
        return CoreObject.Functions.GetPlayer(source)
    elseif it.core == 'esx' then
        return CoreObject.GetPlayerFromId(source)
    end
end

function it.getPlayers()
    if it.core == 'qb-core' then
        return CoreObject.Functions.GetQBPlayers()
    elseif it.core == 'esx' then
        return CoreObject.GetPlayers()
    end
end

function it.getPlayerJob(player)
    local job = {}
    if it.core == 'qb-core' then
        job = {
            name = player.job.name,
            label = player.job.label,
            grade_name = player.job.grade,
            grade_label = player.job.grade.name,
            grade_salary = player.job.payment,
            isboss = player.job.isboss,
            onduty = player.job.onduty
        }
    elseif it.core == 'esx' then
        job = {
            name = player.job.name,
            label = player.job.label,
            grade_name = player.job.grade_name,
            grade_label = player.job.grade_label,
            grade_salary = player.job.grade_salary,
            isboss = player.job.grade_name == 'boss' or false,
            onduty = true
        }
    end
    return job
end

-- Money
function it.addMoney(source, moneyType, amount, reason)
   if not reason then reason = 'unknown' end
   local Player = it.getPlayer(source)
   local addedMoney = false
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
        addedMoney = Player.Functions.AddMoney(moneyType, amount, reason)
    elseif it.core == 'esx' then
        moneyType = types[moneyType]['esx']
        local currentMoney = Player.getAccount(moneyType).money
        Player.addAccountMoney(moneyType, amount)
        if currentMoney + amount == Player.getAccount(moneyType) then
            addedMoney = true
        end
    end
    return addedMoney
end

function it.removeMoney(source, moneyType, amount, reason)
    if not reason then reason = 'unknown' end
    local Player = it.getPlayer(source)
    local removedMoney = false
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
        removedMoney = Player.Functions.RemoveMoney(moneyType, amount, reason)
    elseif it.core == 'esx' then
        moneyType = types[moneyType]['esx']
        local currentMoney = Player.getAccount(moneyType)
        Player.removeAccountMoney(moneyType, amount)
        if currentMoney - amount == currentMoney then
            removedMoney = false
        else
            removedMoney = true
        end
    end
    return removedMoney
end

function it.getMoney(source, moneyType)
    local Player = it.getPlayer(source)
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
        return Player.Functions.GetMoney(moneyType)
    elseif it.core == 'esx' then
        moneyType = types[moneyType]['esx']
       return Player.getAccount(moneyType)
    end
    return false
end

function it.setMoney(source, moneyType, amount)
    local Player = it.getPlayer(source)
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
end

-- Licences
function it.getLicences(source)
    local Player = it.getPlayer(source)
    if it.core == 'qb-core' then
        return Player.PlayerData.metadata['licences'] or false
    elseif it.core == 'esx' then
        TriggerEvent('esx_license:getLicenses', source, function(licenses)
            return licenses or false
        end)
    end
    return false
end

function it.getLicence(source, licenseType)
    local Player = it.getPlayer(source)
    if it.core == 'qb-core' then
        local licenses = Player.PlayerData.metadata['licences']
        return licenses[licenseType] or false
    elseif it.core == 'esx' then
        TriggerEvent('esx_license:getLicense', source, function(license)
            return license[licenseType] or false
        end)
    end
    return false
end


function it.addLicence(source, licenseType)
    local Player = it.getPlayer(source)
    if it.core == 'qb-core' then
        local licenses = Player.PlayerData.metadata['licences']
        licenses[licenseType] = true
        Player.Functions.SetMetaData('licences', licenses)
        return true
    elseif it.core == 'esx' then
        TriggerEvent('esx_license:addLicense', source, licenseType, function()
            return true
        end)
    end
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
    elseif it.core == 'esx' then
        local citizenid = Player.license
        return citizenid
    end
    return false
end

function it.getPlayerName(source)
    local Player = it.getPlayer(source)
    if it.core == 'qb-core' then
        local player_name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
        return player_name
    elseif it.core == 'esx' then
        local player_name = Player.name
        return player_name
    end
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