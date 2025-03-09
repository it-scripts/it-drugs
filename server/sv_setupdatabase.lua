-- Setup the Database from the it_drugs.sql file
DatabaseSetuped = false

local plantSetupStatment = 'CREATE TABLE IF NOT EXISTS drug_plants ('..
    'id VARCHAR(11) NOT NULL, PRIMARY KEY(id),'..
    'owner LONGTEXT DEFAULT NULL,'..
    'coords LONGTEXT NOT NULL,'..
    'dimension INT(11) NOT NULL,'..
    'time INT(255) NOT NULL,'..
    'type VARCHAR(100) NOT NULL,'..
    'health DOUBLE NOT NULL DEFAULT 100,'..
    'fertilizer DOUBLE NOT NULL DEFAULT 0,'..
    'water DOUBLE NOT NULL DEFAULT 0,'..
    'growtime INT(11) NOT NULL'..
    ');'

local proccessingStatement = 'CREATE TABLE IF NOT EXISTS drug_processing ('..
    'id VARCHAR(11) NOT NULL, PRIMARY KEY(id),'..
    'coords LONGTEXT NOT NULL,'..
    'rotation DOUBLE NOT NULL,'..
    'dimension INT(11) NOT NULL,'..
    'owner LONGTEXT NOT NULL,'..
    'type VARCHAR(100) NOT NULL'..
    ');'


local function setupDatabase()
    MySQL.rawExecute(plantSetupStatment, {}, function(response)
        if not response then
            lib.print.error('[setupDatabase] Faild to create plant database')
        else
            if Config.Debug then
                lib.print.info('[setupDatabase] Plant database created:', response)
            end
        end
    end)
    
    MySQL.rawExecute(proccessingStatement, {}, function(response)
        if not response then
            lib.print.error('[setupDatabase] Faild to create processing database')
        else
            if Config.Debug then
                lib.print.info('[setupDatabase] Plant database created:', response)
            end
        end
    end)
  
    return true
end

CreateThread(function()

    if not Config.ManualDatabaseSetup then
        while not setupDatabase() do
            Wait(100)
        end
    end

    DatabaseSetuped = true
end)