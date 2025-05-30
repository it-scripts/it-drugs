--[[
    https://github.com/it-scripts/it-drugs

    This file is licensed under GPL-3.0 or higher <https://www.gnu.org/licenses/gpl-3.0.en.html>

    Copyright © 2025 AllRoundJonU <https://github.com/allroundjonu>
]]
-- Setup the Database from the it_drugs.sql file
DatabaseSetuped = false

-- Define table structures
local tables = {
    drug_plants = {
        create = 'CREATE TABLE IF NOT EXISTS drug_plants ('..
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
            ');',
        columns = {
            {name = 'id', type = 'VARCHAR(11)', nullable = false, default = nil},
            {name = 'owner', type = 'LONGTEXT', nullable = true, default = 'NULL'},
            {name = 'coords', type = 'LONGTEXT', nullable = false, default = nil},
            {name = 'dimension', type = 'INT(11)', nullable = false, default = nil},
            {name = 'time', type = 'INT(255)', nullable = false, default = nil},
            {name = 'type', type = 'VARCHAR(100)', nullable = false, default = nil},
            {name = 'health', type = 'DOUBLE', nullable = false, default = '100'},
            {name = 'fertilizer', type = 'DOUBLE', nullable = false, default = '0'},
            {name = 'water', type = 'DOUBLE', nullable = false, default = '0'},
            {name = 'growtime', type = 'INT(11)', nullable = false, default = nil}
        }
    },
    drug_processing = {
        create = 'CREATE TABLE IF NOT EXISTS drug_processing ('..
            'id VARCHAR(11) NOT NULL, PRIMARY KEY(id),'..
            'coords LONGTEXT NOT NULL,'..
            'rotation DOUBLE NOT NULL,'..
            'dimension INT(11) NOT NULL,'..
            'owner LONGTEXT NOT NULL,'..
            'type VARCHAR(100) NOT NULL'..
            ');',
        columns = {
            {name = 'id', type = 'VARCHAR(11)', nullable = false, default = nil},
            {name = 'coords', type = 'LONGTEXT', nullable = false, default = nil},
            {name = 'rotation', type = 'DOUBLE', nullable = false, default = nil},
            {name = 'dimension', type = 'INT(11)', nullable = false, default = nil},
            {name = 'owner', type = 'LONGTEXT', nullable = false, default = nil},
            {name = 'type', type = 'VARCHAR(100)', nullable = false, default = nil}
        }
    }
}

-- Check if a column exists in a table
local function columnExists(tableName, columnName, callback)
    local query = string.format("SELECT COUNT(*) as count FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '%s' AND COLUMN_NAME = '%s'", tableName, columnName)
    MySQL.scalar(query, {}, function(result)
        callback(result and result > 0)
    end)
end

-- Add column to table if it doesn't exist
local function addColumnIfNotExists(tableName, column)
    columnExists(tableName, column.name, function(exists)
        if not exists then
            local defaultValue = column.default and ('DEFAULT ' .. column.default) or ''
            local nullable = column.nullable and 'NULL' or 'NOT NULL'
            local query = string.format("ALTER TABLE %s ADD COLUMN %s %s %s %s", 
                tableName, column.name, column.type, nullable, defaultValue)
            
            MySQL.rawExecute(query, {}, function(response)
                if not response then
                    lib.print.error(string.format('[setupDatabase] Failed to add column %s to %s', column.name, tableName))
                elseif Config.Debug then
                    lib.print.info(string.format('[setupDatabase] Added column %s to %s', column.name, tableName))
                end
            end)
        end
    end)
end

-- Check all required columns for a table
local function checkTableColumns(tableName, columns)
    for _, column in ipairs(columns) do
        addColumnIfNotExists(tableName, column)
    end
end

-- Setup database with tables and columns verification
local function setupDatabase()
    local setupCompleted = false
    local errorOccurred = false
    local tablesProcessed = 0
    
    for tableName, tableData in pairs(tables) do
        MySQL.rawExecute(tableData.create, {}, function(response)
            if not response then
                errorOccurred = true
                lib.print.error(string.format('[setupDatabase] Failed to create %s table', tableName))
            else
                if Config.Debug then
                    lib.print.info(string.format('[setupDatabase] %s table verified', tableName))
                end
                
                -- Check all columns exist
                checkTableColumns(tableName, tableData.columns)
            end
            
            tablesProcessed = tablesProcessed + 1
            if tablesProcessed >= 2 then
                setupCompleted = not errorOccurred
            end
        end)
    end
    
    -- Wait for processing to complete
    while not setupCompleted and not errorOccurred do
        Wait(100)
    end
    
    return setupCompleted
end

-- Initialize database setup
CreateThread(function()
    if not Config.ManualDatabaseSetup then
        while not setupDatabase() do
            Wait(500)
            lib.print.warn('[setupDatabase] Retrying database setup...')
        end
        lib.print.info('[setupDatabase] Database setup completed successfully')
    end

    DatabaseSetuped = true
end)