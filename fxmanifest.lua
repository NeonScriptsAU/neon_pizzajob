fx_version 'cerulean'
game 'gta5'

author 'Neon Scripts'
description 'Pizza Delivery Job'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*',
}

dependencies {
    'ox_lib'
}
