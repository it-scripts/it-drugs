Config = Config or {}
Locales = Locales or {}

-- ┌───────────────────────────────────┐
-- │  ____                           _ │
-- │ / ___| ___ _ __   ___ _ __ __ _| |│
-- │| |  _ / _ \ '_ \ / _ \ '__/ _` | |│
-- │| |_| |  __/ | | |  __/ | | (_| | |│
-- │ \____|\___|_| |_|\___|_|  \__,_|_|│
-- └───────────────────────────────────┘
-- All general settings like language or webhook can be found here

--[[
    The first thing will be to choose our main language, here you can choose
    between the default languages that you will find within locales/*,
    if yours is not there, feel free to create it!
]]
Config.Language = 'en'

Config.Target = 'ox_target' --'qb-target' -- Target script name (qb-target, ox_target or false to disable)

--[[
    Here you set up the discord webhook, you can find more information about
    this in the server/webhook.lua file.
    If you dont know what a webhook is, you can read more about it here:
    https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks
]]
Config.Webhook = {
    ['active'] = false, -- Set to true to enable the webhook
    ['url'] = nil, -- This will do nothing set you webhook url in server/sv_webhook.lua
    ['name'] = 'it-drugs', -- Name for the webhook
    ['avatar'] = 'https://i.imgur.com/KvZZn88.png', -- Avatar for the webhook
    ['color'] = 16711680, -- Default color for the webhook
}

--- Growing Related Settings
Config.rayCastingDistance = 7.0 -- distance in meters
Config.FireTime = 10000 -- in ms
Config.ClearOnStartup = true -- Clear dead plants on script start-up

-- ┌───────────────────────────┐
-- │ _____                     │
-- │|__  /___  _ __   ___  ___ │
-- │  / // _ \| '_ \ / _ \/ __|│
-- │ / /| (_) | | | |  __/\__ \│
-- │/____\___/|_| |_|\___||___/│
-- └───────────────────────────┘

Config.OnlyZones = false -- Allow drug growth only in defined zones
Config.GlobalGrowTime = 30 -- Time in minutes for a plant to grow

Config.Zones = {
    ['weed_zone_one'] = { -- Zone id (Musst be unique)
        coords = {
            vector2(2058.4727, 4878.3384), -- Zone coords
            vector2(2005.5208, 4929.1909),
            vector2(1979.8605, 4903.5918),
            vector2(2031.4441, 4851.1611),
        },
        growMultiplier = 2, -- GlobalGrowTime / growMultiplier = Time in minutes for a plant to grow in this zone
        
        blip = {
            display = true, -- Display blip on map
            sprite = 469, -- Select blip from (https://docs.fivem.net/docs/game-references/blips/)
            displayColor = 2, -- Select blip color from (https://docs.fivem.net/docs/game-references/blips/)
            displayText = 'Weed Zone',
        },
        exclusive = {'weed_lemonhaze_seed'} -- Types of drugs that will be affected in this are.
    },
    ['weed_zone_two'] = { -- Zone id (Musst be unique)
        coords = {
            vector2(2068.0283, 4887.9902), -- Zone coords
            vector2(2098.0339, 4917.5977),
            vector2(2045.6102, 4969.4971),
            vector2(2016.1580, 4940.1895),
        },
        growMultiplier = 2, -- GlobalGrowTime / growMultiplier = Time in minutes for a plant to grow in this zone
        blip = {
            display = true, -- Display blip on map
            sprite = 469, -- Select blip from (https://docs.fivem.net/docs/game-references/blips/)
            displayColor = 2, -- Select blip color from (https://docs.fivem.net/docs/game-references/blips/)
            displayText = 'Weed Zone',
        },
        exclusive = {'weed_lemonhaze_seed'} -- Types of drugs that will be affected in this are.
    },
}


-- ┌─────────────────────────────┐
-- │ ____  _             _       │
-- │|  _ \| | __ _ _ __ | |_ ___ │
-- │| |_) | |/ _` | '_ \| __/ __|│
-- │|  __/| | (_| | | | | |_\__ \│
-- │|_|   |_|\__,_|_| |_|\__|___/│
-- └─────────────────────────────┘

Config.OnlyAllowedGrounds = false -- Allow drug growth only on allowed grounds
Config.AllowedGrounds = {   -- Allowed ground types for planting
    1109728704, -- fields
    -1942898710, -- grass/dirt
    510490462, -- dirt path
    -1286696947,
    -1885547121,
    223086562,
    -461750719,
    1333033863,
    -1907520769,
}

Config.WaterDecay = 1 -- Percent of water that decays every minute
Config.FertilizerDecay = 0.7 -- Percent of fertilizers that decays every minute

Config.FertilizerThreshold = 10
Config.WaterThreshold = 10
Config.HealthBaseDecay = {7, 10} -- Min/Max Amount of health decay when the plant is below the above thresholds for water and nutrition

Config.PlantWater = { -- Create water for plants
    ['watering_can'] = 25, -- Item and percent it adds to overall plant water
}

Config.PlantFertilizer = { -- Create fertilizer for plants
    ['fertilizer'] = 33, -- Item and percent it adds to overall plant food
}

Config.PlantTypes = {
    -- small is growth 0-30%, medium is 30-80%, large is 80-100%
    ["plant1"] = {
        [1] = {"bkr_prop_weed_01_small_01a", -0.5},
        [2] = {"bkr_prop_weed_med_01a", -0.5},
        [3] = {"bkr_prop_weed_lrg_01a", -0.5},
    },
    ["plant2"] = {
        [1] = {"bkr_prop_weed_01_small_01b", -0.5},
        [2] = {"bkr_prop_weed_med_01b",-0.5},
        [3] = {"bkr_prop_weed_lrg_01b", -0.5},
    },
    ["small_plant"] = {
        [1] = {"bkr_prop_weed_bud_02b", 0},
        [2] = {"bkr_prop_weed_bud_02b", 0},
        [3] = {"bkr_prop_weed_bud_02a", 0},
    }
}

Config.Plants = { -- Create seeds for drugs

    ['weed_lemonhaze_seed'] = {
        growthTime = 180, -- Cutsom growth time in minutes false if you want to use the global growth time
        label = 'Lemon Haze', --
        plantType = 'plant1', -- Choose plant types from (plant1, plant2, small_plant)
        products = { -- Item the plant is going to produce when harvested with the max amount
            ['weed_lemonhaze'] = {min = 1, max = 4},  
            --['other_item'] = {min = 1, max = 2}
        },
        seed = {
            chance = 50, -- Percent of getting back the seed
            min = 1, -- Min amount of seeds
            max = 2 -- Max amount of seeds
        },
        time = 3000 -- Time it takes to plant/harvest in miliseconds
    },
    ['coca_seed'] = {
        growthTime = 180, -- Cutsom growth time in minutes false if you want to use the global growth time
        label = 'Coca Plant', --
        plantType = 'small_plant', -- Choose plant types from (plant1, plant2, small_plant) also you can change plants yourself in main/client.lua line: 2
        products = {coca = {min = 1, max = 2}}, -- Item the plant is going to produce when harvested with the max amount
        seed = {
            chance = 50, -- Percent of getting back the seed
            min = 1, -- Min amount of seeds
            max = 2 -- Max amount of seeds
        },
        time = 3000 -- Time it takes to harvest in miliseconds
    },
}

--[[
    Next you have to prepeare the Processing settings. You can create as many processing tables as you want.
    You can create use as many ingrediants as you want. You can also change the processing table models to your liking.
    Each table is for proccessing a specific drug type. You can also create to tables for the same drug type.

]]

-- ┌─────────────────────────────────────────────────┐
-- │ ____                              _             │
-- │|  _ \ _ __ ___   ___ ___  ___ ___(_)_ __   __ _ │
-- │| |_) | '__/ _ \ / __/ _ \/ __/ __| | '_ \ / _` |│
-- │|  __/| | | (_) | (_|  __/\__ \__ \ | | | | (_| |│
-- │|_|   |_|  \___/ \___\___||___/___/_|_| |_|\__, |│
-- │                                           |___/ │
-- └─────────────────────────────────────────────────┘

Config.EnableProcessing = true -- Enable crafting system
Config.ShowIngrediants = true -- Show ingrediants in the processing table

Config.ProccesingSkillCheck = true -- Enable skill check for processingTables (Replaces the progressbar)
Config.SkillCheck = {
    difficulty = {'easy', 'easy', 'medium', 'easy'},
    keys = {'w', 'a', 's', 'd'}
}

Config.ProcessingTables = { -- Create processing table
    ['weed_processing_table'] = {
        type = 'weed',
        model = 'bkr_prop_weed_table_01a', -- Exanples: bkr_prop_weed_table_01a, bkr_prop_meth_table01a, bkr_prop_coke_table01a
        time = 10, -- Time in seconds to process 1 item
        ingrediants = {
            ['paper'] = 1,
            ['weed_lemonhaze'] = 3
        },
        output = 'joint', -- Processed item
    },
    
    ['cocaine_processing_table'] = {
        type = 'cocaine',
        model = 'bkr_prop_coke_table01a', -- Exanples: bkr_prop_weed_table_01a, bkr_prop_meth_table01a, bkr_prop_coke_table01a
        time = 10, -- Time in seconds to process 1 item
        ingrediants = {
            ['coca'] = 3,
            ['nitrous'] = 1
        },
        output = 'cocaine', -- Processed item
    },
}

-- ┌────────────────────────────┐
-- │ ____                       │
-- │|  _ \ _ __ _   _  __ _ ___ │
-- │| | | | '__| | | |/ _` / __|│
-- │| |_| | |  | |_| | (_| \__ \│
-- │|____/|_|   \__,_|\__, |___/│
-- │                  |___/     │
-- └────────────────────────────┘

--[[ Possible Drug Effects:
    runningSpeedIncrease, 
    infinateStamina,
    moreStrength,
    healthRegen,
    foodRegen,
    drunkWalk,
    psycoWalk,
    outOfBody,
    cameraShake,
    fogEffect,
    confusionEffect,
    whiteoutEffect,
    intenseEffect,
    focusEffect
--]]

Config.EnableDrugs = true -- Enable drug effects
Config.Drugs = { -- Create you own drugs

    ['joint'] = {
        label = 'Joint',
        animation = 'smoke', -- Animations: blunt, sniff, pill
        time = 30, -- Time of the Effects
        effects = { -- Effects: runningSpeedIncrease, infinateStamina, moreStrength, healthRegen, foodRegen, drunkWalk, psycoWalk, outOfBody, cameraShake, fogEffect, confusionEffect, whiteoutEffect, intenseEffect, focusEffect
            'intenseEffect',
            'healthRegen',
            'moreStrength',
            'drunkWalk'
        }
    },
    ['cocaine'] = {
        label = 'Cocaine',
        animation = 'sniff', -- Animations: blunt, sniff, pill
        time = 60, -- Time of the Effects
        effects = { -- Effects: runningSpeedIncrease, infinateStamina, moreStrength, healthRegen, foodRegen, drunkWalk, psycoWalk, outOfBody, cameraShake, fogEffect, confusionEffect, whiteoutEffect, intenseEffect, focusEffect
            'runningSpeedIncrease',
            'infinateStamina',
            'fogEffect',
            'psycoWalk'
        }
    },
}

--[[
    You also can sell the drugs you created. You can create as many sell zones as you want.
    You can also change the sell zone models to your liking. You can change the price of each drug in each zone.
]]

-- ┌──────────────────────────────┐
-- │ ____       _ _ _             │
-- │/ ___|  ___| | (_)_ __   __ _ │
-- │\___ \ / _ \ | | | '_ \ / _` |│
-- │ ___) |  __/ | | | | | | (_| |│
-- │|____/ \___|_|_|_|_| |_|\__, |│
-- │                        |___/ │
-- └──────────────────────────────┘

Config.EnableSelling = true -- Enable selling system (Currently selling is disabled)

Config.MinimumCops = 0 -- Minimum cops required to sell drugs
Config.ChanceSell = 70 -- Chance to sell drug (in %)
Config.RandomMinSell = 1 -- Random sell amount range min
Config.RandomMaxSell = 6 -- Random sell amount range max
Config.SellTimeout = 10 -- Max time you get to choose your option (secs)
Config.GiveBonusOnPolice = true -- Give bonus money if there is police online
Config.ShouldToggleSelling = false -- This option decides whether the person has to toggle selling in a zone (radialmenu/command) (Recommended: false)

Config.SellZones = {
    ['groove'] = {
        points = {
            vector2(250.90760803223, -1866.3974609375),
            vector2(146.70475769043, -1990.5447998047),
            vector2(130.3134765625, -2034.3944091797),
            vector2(95.291275024414, -2030.4129638672),
            vector2(88.095336914062, -2009.6634521484),
            vector2(68.878730773926, -1978.8924560547),
            vector2(-153.59761047363, -1779.4030761719),
            vector2(-97.692588806152, -1750.6363525391),
            vector2(-50.927833557129, -1733.6020507812),
            vector2(49.590217590332, -1689.9705810547)
        },
        minZ = 18.035144805908,
        maxZ = 75.059997558594,
    },
    ['vinewood'] = {
        points = {
            vector2(-663.80639648438, 114.2766418457),
            vector2(-660.09497070312, 299.65426635742),
            vector2(-546.58837890625, 275.86111450196),
            vector2(-542.21002197266, 357.8136291504),
            vector2(-519.6430053711, 349.90490722656),
            vector2(-512.67572021484, 276.3483581543),
            vector2(21.216751098632, 278.6813659668),
            vector2(49.785594940186, 339.29946899414),
            vector2(108.84923553466, 399.87518310546),
            vector2(124.068069458, 384.4684753418),
            vector2(92.195236206054, 354.55239868164),
            vector2(170.3550567627, 377.32186889648),
            vector2(841.11456298828, 199.74020385742),
            vector2(530.7640991211, -193.10136413574)
        },
        minZ = 45.0,
        maxZ = 125.0
    },
    ['forumdr'] = {
        points = {
            vector2(-181.78276062012, -1767.562133789),
            vector2(-232.15049743652, -1728.5841064454),
            vector2(-257.00219726562, -1706.3781738282),
            vector2(-316.23831176758, -1670.7681884766),
            vector2(-317.6089477539, -1671.6815185546),
            vector2(-339.08483886718, -1659.1655273438),
            vector2(-345.54052734375, -1655.4389648438),
            vector2(-370.05755615234, -1640.6751708984),
            vector2(-357.4814453125, -1617.630859375),
            vector2(-344.98095703125, -1605.980834961),
            vector2(-308.92208862304, -1544.8927001954),
            vector2(-304.6683959961, -1535.6296386718),
            vector2(-307.36282348632, -1531.2420654296),
            vector2(-303.91906738282, -1514.8071289062),
            vector2(-302.4489440918, -1508.5216064454),
            vector2(-299.51068115234, -1489.9995117188),
            vector2(-297.42388916016, -1452.6616210938),
            vector2(-297.9144897461, -1445.0788574218),
            vector2(-300.47821044922, -1410.740600586),
            vector2(-243.52647399902, -1409.9093017578),
            vector2(-228.14682006836, -1408.454711914),
            vector2(-214.2696685791, -1404.2430419922),
            vector2(-202.69938659668, -1398.415649414),
            vector2(-176.32830810546, -1382.9993896484),
            vector2(-140.07070922852, -1360.1298828125),
            vector2(-131.92518615722, -1353.8952636718),
            vector2(-126.67826080322, -1347.0697021484),
            vector2(-122.79215240478, -1338.1767578125),
            vector2(-122.24575042724, -1335.2940673828),
            vector2(-88.574974060058, -1337.8919677734),
            vector2(-83.885818481446, -1337.3891601562),
            vector2(-72.32137298584, -1347.8657226562),
            vector2(-55.457233428956, -1349.6873779296),
            vector2(-46.141300201416, -1350.8635253906),
            vector2(0.30536636710166, -1350.3518066406),
            vector2(19.377029418946, -1349.9018554688),
            vector2(46.155563354492, -1350.2407226562),
            vector2(56.231525421142, -1346.1237792968),
            vector2(61.976043701172, -1336.847290039),
            vector2(61.876712799072, -1331.4219970704),
            vector2(94.016792297364, -1317.3137207032),
            vector2(98.473731994628, -1315.1446533204),
            vector2(100.91152191162, -1318.8972167968),
            vector2(116.59771728516, -1309.0223388672),
            vector2(115.354637146, -1306.6965332032),
            vector2(142.13439941406, -1291.261352539),
            vector2(143.9640197754, -1293.9191894532),
            vector2(159.81324768066, -1280.7825927734),
            vector2(166.5573272705, -1270.3135986328),
            vector2(203.52110290528, -1282.7435302734),
            vector2(231.76536560058, -1329.863647461),
            vector2(215.84732055664, -1346.2076416016),
            vector2(190.12483215332, -1387.3775634766),
            vector2(162.40365600586, -1423.5834960938),
            vector2(154.98637390136, -1424.7723388672),
            vector2(126.23979187012, -1458.2556152344),
            vector2(108.94204711914, -1478.851196289),
            vector2(113.4779586792, -1482.6186523438),
            vector2(111.75213623046, -1484.7049560546),
            vector2(109.91118621826, -1483.4962158204),
            vector2(92.817611694336, -1503.7390136718),
            vector2(69.58283996582, -1526.8861083984),
            vector2(39.489440917968, -1562.9592285156),
            vector2(16.217784881592, -1590.7109375),
            vector2(0.90857058763504, -1609.6218261718),
            vector2(-22.47274017334, -1636.7037353516),
            vector2(-65.98893737793, -1687.4913330078)
        },
        minZ = 15.0,
        maxZ = 38.0
    },
}

Config.SellZoneDrugs = {
     -- Multiple drugs can be added to a zone like shown below
     ["groove"] = { -- must be the same as in one of the SellZones!!
        { item = 'weed_packaged', price = math.random(100, 200)},
        { item = 'meth_packaged', price = math.random(100, 200)},
        { item = 'coke_packaged', price = math.random(100, 200)},
    },
    ["vinewood"] = {
        { item = 'weed_packaged', price = math.random(100, 200)},
        { item = 'meth_packaged', price = math.random(100, 200)},
        { item = 'coke_packaged', price = math.random(100, 200)},
    },
    ["forumdr"] = {
        { item = 'weed_packaged', price = math.random(100, 200)},
        { item = 'meth_packaged', price = math.random(100, 200)},
        { item = 'coke_packaged', price = math.random(100, 200)},
    },
}

Config.BlacklistPeds = { 
    -- Peds you cant sell drugs to
    "mp_m_shopkeep_01",
    "s_m_y_ammucity_01",
    "s_m_m_lathandy_01",
    "s_f_y_clubbar_01",
    "ig_talcc",
    "g_f_y_vagos_01",
    "hc_hacker",
    "s_m_m_migrant_01",
}


function ShowNotification(message, type)
    -- Bridge.Functions.Notify(message, type) are the default Framework notifications
    -- You can change this to your own notification systems
    if type == 'error' then
        it.notify(message, "error")
    elseif type == 'success' then
        it.notify(message, "success")
    else
        it.notify(message)
    end
end

--[[
    Debug mode, you can see all kinds of prints/logs using debug,
    but it's only for development.
]]
Config.EnableVersionCheck = true -- Enable version check
Config.Branch = 'main' -- Set to 'master' to use the master branch, set to 'development' to use the dev branch
Config.Debug = false -- Set to true to enable debug mode
Config.DebugPoly = false -- Set to true to enable debug mode for PolyZone
