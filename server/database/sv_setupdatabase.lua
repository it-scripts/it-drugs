-- Setup the Database from the it_drugs.sql file
DatabaseSetuped = false

local function setupDatabase()
    local drugPlantsFile = LoadResourceFile(GetCurrentResourceName(), 'server/database/drug_plants.sql')

    local plantStatements = {}
    for line in drugPlantsFile:gsub("\r\n", "\n"):gsub("\n\n", "\n"):gmatch("[^\n]+") do
        table.insert(plantStatements, line)
    end
    
    for i = 1, #plantStatements do
        MySQL.rawExecute(plantStatements[i], {}, function(response)
            if response then
                if Config.Debug then lib.print.info('Executed SQL Statment ' .. plantStatements[i]) end
            else
                lib.print.error('Failed to execute SQL statement: ' .. plantStatements[i])
                return
            end
        end)
    end
    
    local drugProcessingFile = LoadResourceFile(GetCurrentResourceName(), 'server/database/drug_processing.sql')
    
    local proccessingStatements = {}
    for line in drugProcessingFile:gsub("\r\n", "\n"):gsub("\n\n", "\n"):gmatch("[^\n]+") do
        table.insert(proccessingStatements, line)
    end
    
    for i = 1, #proccessingStatements do
        MySQL.rawExecute(proccessingStatements[i], {}, function(response)
            if response then
                if Config.Debug then lib.print.info('Executed SQL Statment ' .. proccessingStatements[i]) end
            else
                lib.print.error('Failed to execute SQL statement: ' .. proccessingStatements[i])
                return
            end
        end)
    end

    return true
end

CreateThread(function()
    while not setupDatabase() do
        Wait(100)
    end
    DatabaseSetuped = true
end)