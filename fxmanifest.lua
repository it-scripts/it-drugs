fx_version 'cerulean'
game 'gta5'

author '@allroundjonu'
description 'Advanced Drug System for FiveM'
version 'v1.4.3'

identifier 'it-drugs'

shared_script {
    '@ox_lib/init.lua'
}

ox_libs {
    'math',
}

shared_scripts {
    'shared/config.lua',
    'shared/functions.lua',
    'locales/en.lua',
    'locales/*.lua',
}

client_scripts {
    'client/cl_notarget.lua',

    'client/cl_admin.lua',
    'client/cl_menus.lua',
    'client/cl_dealer.lua',
    'client/cl_planting.lua',
    'client/cl_processing.lua',
    'client/cl_selling.lua',
    'client/cl_target.lua',
    'client/cl_using.lua',
    'client/cl_blips.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',

    'server/sv_admin.lua',
    'server/sv_dealer.lua',
    'server/sv_planting.lua',
    'server/sv_processing.lua',
    'server/sv_selling.lua',
    'server/sv_usableitems.lua',
    'server/sv_webhooks.lua',
    'server/sv_versioncheck.lua',
    'server/sv_setupdatabase.lua'
}

files = {
    'stream/freeze_it-drugs_table.ytyp',
    'stream/freeze_it-scripts_coke_table.ydr',
    'stream/freeze_it-scripts_meth_table.ytyp',
    'stream/freeze_it-scripts_weed_table.ydr',
    --------------Lemon Haze-------------------
    'stream/an_weed_yellow.ytd',
    'stream/an_weed_yellow_01_small_01b.ydr',
    'stream/an_weed_yellow_lrg_01b.ydr',
    'stream/an_weed_yellow_med_01b.ydr',
    'stream/an_weed_yellow+hi.ytd',
    'stream/an_weed.ytyp',
    ---------------Purple haze------------------
    'stream/an_weed_purple.ytd',
    'stream/an_weed_purple_01_small_01b.ydr',
    'stream/an_weed_purple_lrg_01b.ydr',
    'stream/an_weed_purple_med_01b.ydr',
    'stream/an_weed_purple+hi.ytd',
    ---------------White Widow------------------
    'stream/an_weed_white.ytd',
    'stream/an_weed_white_01_small_01b.ydr',
    'stream/an_weed_white_lrg_01b.ydr',
    'stream/an_weed_white_med_01b.ydr',
    'stream/an_weed_white+hi.ytd',
    ---------------blue berry------------------------
    'stream/an_weed_blue.ytd',
    'stream/an_weed_blue_01_small_01b.ydr',
    'stream/an_weed_blue_lrg_01b.ydr',
    'stream/an_weed_blue_med_01b.ydr',
    'stream/an_weed_blue+hi.ytd',
}

data_file 'DLC_ITYP_REQUEST' 'stream/freeze_it-drugs_table.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/freeze_it-scripts_coke_table.ydr'
data_file 'DLC_ITYP_REQUEST' 'stream/freeze_it-scripts_meth_table.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/freeze_it-scripts_weed_table.ydr'
------------------------Lemon haze-------------------------------
data_file 'DLC_ITYP_REQUEST' 'stream/an_weed_yellow.ytd'
data_file 'DLC_ITYP_REQUEST' 'stream/an_weed_yellow_01_small_01b.ydr'
data_file 'DLC_ITYP_REQUEST' 'stream/an_weed_yellow_lrg_01b.ydr'
data_file 'DLC_ITYP_REQUEST' 'stream/an_weed_yellow_med_01b.ydr'
data_file 'DLC_ITYP_REQUEST' 'stream/an_weed_yellow+hi.ytd'
data_file 'DLC_ITYP_REQUEST' 'stream/an_weed.ytyp'
-------------------------Purple haze-------------------------------
data_file 'DLC_ITYP_REQUEST' 'stream/an_weed_purple.ytd'
data_file 'DLC_ITYP_REQUEST' 'stream/an_weed_purple_01_small_01b.ydr'
data_file 'DLC_ITYP_REQUEST' 'stream/an_weed_purple_lrg_01b.ydr'
data_file 'DLC_ITYP_REQUEST' 'stream/an_weed_purple_med_01b.ydr'
data_file 'DLC_ITYP_REQUEST' 'stream/an_weed_purple+hi.ytd'
-------------------------White Widow-------------------------------
data_file 'DLC_ITYP_REQUEST' 'stream/an_weed_white.ytd'
data_file 'DLC_ITYP_REQUEST' 'stream/an_weed_white_01_small_01b.ydr'
data_file 'DLC_ITYP_REQUEST' 'stream/an_weed_white_lrg_01b.ydr'
data_file 'DLC_ITYP_REQUEST' 'stream/an_weed_white_med_01b.ydr'
data_file 'DLC_ITYP_REQUEST' 'stream/an_weed_white+hi.ytd'
-------------------------Blue berry--------------------------------
data_file 'DLC_ITYP_REQUEST' 'stream/an_weed_blue.ytd'
data_file 'DLC_ITYP_REQUEST' 'stream/an_weed_blue_01_small_01b.ydr'
data_file 'DLC_ITYP_REQUEST' 'stream/an_weed_blue_lrg_01b.ydr'
data_file 'DLC_ITYP_REQUEST' 'stream/an_weed_blue_med_01b.ydr'
data_file 'DLC_ITYP_REQUEST' 'stream/an_weed_blue+hi.ytd'


dependencies {
    'ox_lib',
    'oxmysql',
    'it_bridge'
}

lua54 'yes'
