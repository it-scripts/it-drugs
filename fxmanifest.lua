fx_version 'cerulean'
game 'gta5'

author '@allroundjonu'
description 'Advanced Drug System for FiveM'
version 'v1.3.0'

identifier 'it-drugs'

shared_script {
    '@ox_lib/init.lua'
}

shared_scripts {
    'shared/config.lua',
    'bridge/init.lua',
    'shared/functions.lua',
    'locales/en.lua',
    'locales/*.lua',
    'bridge/**/shared.lua',
    '@es_extended/imports.lua',
}

client_scripts {

    'bridge/**/client.lua',

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

    'bridge/**/server.lua',
    'bridge/**/server/*.lua',
    
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
}

data_file 'DLC_ITYP_REQUEST' 'stream/freeze_it-drugs_table.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/freeze_it-scripts_coke_table.ydr'
data_file 'DLC_ITYP_REQUEST' 'stream/freeze_it-scripts_meth_table.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/freeze_it-scripts_weed_table.ydr'

dependencies {
    'ox_lib',
    'oxmysql'
}

lua54 'yes'
usefxv2oal 'yes'