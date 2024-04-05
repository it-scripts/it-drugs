function it.getPlayerData()
    if it.core == 'qb-core' then
        return CoreObject.Functions.GetPlayerData()
    elseif it.core == 'esx' then
        return CoreObject.GetPlayerData()
    end
end

function it.getCitizenId()
    local citizenId = lib.callback.await('it-lib:getCitizenId', false)
    return citizenId
end

function it.getPlayerJob()
    local job = {}
    local playerData = it.getPlayerData()

    if it.core == 'qb-core' then
        job = {
            name = playerData.job.name,
            label = playerData.job.label,
            grade_name = playerData.job.grade,
            grade_label = playerData.job.grade.name,
            grade_salary = playerData.job.payment,
            isboss = playerData.job.isboss,
            onduty = playerData.job.onduty
        }
    elseif it.core == 'esx' then
        job = {
            name = playerData.job.name,
            label = playerData.job.label,
            grade_name = playerData.job.grade_name,
            grade_label = playerData.job.grade_label,
            grade_salary = playerData.job.grade_salary,
            isboss = playerData.job.grade_name == 'boss' or false,
            onduty = true
        }
    end
    return job
end

function it.getPlayerGang()
    local gang = {}
    local playerData = it.getPlayerData()

    if it.core == 'qb-core' then
        gang = {
            name = playerData.gang.name,
            label = playerData.gang.label,
            grade_name = playerData.gang.grade.level,
            grade_label = playerData.gang.grade.name,
            isboss = playerData.gang.isboss,
        }
    elseif it.core == 'esx' then
        gang = {
            name = playerData.job.name,
            label = playerData.job.label,
            grade_name = playerData.job.grade_name,
            grade_label = playerData.job.grade_label,
            isboss = playerData.job.grade_name == 'boss' or false,
        }
    end
    return gang
end

function it.getPlayerMoney(type)
    local playerData = it.getPlayerData()
    if it.core == 'qb-core' then
        local types = { ['cash'] = 'cash', ['bank'] = 'bank', ['black'] = false }

        if types[type] then
            return playerData.money[types[type]]
        end
        return false
    elseif it.core == 'esx' then
        local types = { ['cash'] = 'money', ['bank'] = 'bank', ['black'] = 'black_money' }

        if types[type] then
            return playerData.accounts[types[type]]
        end
        return false
    end
end

function it.getPlayerName()
    local playerData = it.getPlayerData()
    if it.core == 'qb-core' then
        return playerData.charinfo.firstname .. ' ' .. playerData.charinfo.lastname
    elseif it.core == 'esx' then
        return lib.callback.await('it-lib:getPlayerName', false)
    end
end

function it.getLicences()
    local licences = lib.callback.await('it-lib:getLicences', false)
    return licences
end

function it.getLicence(licenseType)
    local licence = lib.callback.await('it-lib:getLicence', false, licenseType)
    return licence
end