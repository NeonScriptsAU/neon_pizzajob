local QBCore = nil
local ESX = nil

if Config.Framework == 'QB' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'ESX' then
    ESX = exports['es_extended']:getSharedObject()
end

local activeDeliveries = {}

local Utils = require('server/sv_utils')

local function getIdentifier(Player)
    if Config.Framework == 'QB' then
        return Player.PlayerData.citizenid
    elseif Config.Framework == 'ESX' then
        return Player.getIdentifier()
    end
end

local function giveVehicleKeys(source, plate, netid)
    if Config.VehicleKeys == 'qb' then
        TriggerClientEvent('vehiclekeys:client:SetOwner', source, plate)
    elseif Config.VehicleKeys == 'qbx' then
        exports['qbx_vehiclekeys']:GiveKeys(source, plate)
    elseif Config.VehicleKeys == 'wasabi' then
        exports['wasabi_carlock']:GiveKey(source, plate)
    elseif Config.VehicleKeys == 'mrnewb' then
        exports.MrNewbVehicleKeys:GiveKeys(source, netid)
    end
end

local function removeVehicleKeys(source, plate, netid)
    if Config.VehicleKeys == 'qb' then
        TriggerClientEvent('vehiclekeys:client:RemoveKeys', source, plate)
    elseif Config.VehicleKeys == 'qbx' then
        exports['qbx_vehiclekeys']:RemoveKeys(source, plate)
    elseif Config.VehicleKeys == 'wasabi' then
        exports['wasabi_carlock']:RemoveKey(source, plate)
    elseif Config.VehicleKeys == 'mrnewb' then
        exports.MrNewbVehicleKeys:RemoveKeys(source, netid)
    end
    local entity = NetworkGetEntityFromNetworkId(netid)
    DeleteEntity(entity)
end

RegisterNetEvent('neon_pizzajob:giveVehicleKeys', function(plate, netid)
    local src = source
    giveVehicleKeys(src, plate, netid)
end)

RegisterNetEvent('neon_pizzajob:removeVehicleKeys', function(plate, netid)
    local src = source
    removeVehicleKeys(src, plate, netid)
end)

local function checkPlayerExists(identifier, callback)
    MySQL.scalar('SELECT COUNT(*) FROM neon_pizzajob WHERE identifier = ?', {identifier}, function(count)
        callback(count > 0)
    end)
end

local function insertPlayer(identifier)
    MySQL.insert('INSERT INTO neon_pizzajob (identifier, total_deliveries) VALUES (?, ?)', {identifier, 0})
end

local function updateTotalDeliveries(identifier)
    MySQL.update('UPDATE neon_pizzajob SET total_deliveries = total_deliveries + 1 WHERE identifier = ?', {identifier})
end

RegisterNetEvent('neon_pizzajob:startDelivering', function()
    local src = source
    activeDeliveries[src] = true
end)

RegisterNetEvent('neon_pizzajob:stopDelivering', function()
    local src = source
    activeDeliveries[src] = nil
end)

RegisterNetEvent('neon_pizzajob:completeDelivery', function()
    local src = source
    local Player

    if Config.Framework == 'QB' then
        Player = QBCore.Functions.GetPlayer(src)
    elseif Config.Framework == 'ESX' then
        Player = ESX.GetPlayerFromId(src)
    end

    if Player and activeDeliveries[src] then
        local payAmount = math.random(Config.Pay.min, Config.Pay.max)

        if Config.Framework == 'QB' then
            Player.Functions.AddMoney("cash", payAmount, "Pizza Delivery")
        elseif Config.Framework == 'ESX' then
            Player.addAccountMoney('money', payAmount)
        end

        local steamName = GetPlayerName(src)

        Utils.logDeliveryCompletion(steamName, payAmount)

        local identifier = getIdentifier(Player)
        checkPlayerExists(identifier, function(exists)
            if exists then
                updateTotalDeliveries(identifier)
            else
                insertPlayer(identifier)
                updateTotalDeliveries(identifier)
            end
        end)

        activeDeliveries[src] = true
    else
        local steamName = GetPlayerName(src)
        Utils.logSuspiciousActivity(steamName, "Attempted delivery payment without being active.")
        print("Failed payment attempt: player not actively delivering.")
    end
end)

RegisterNetEvent('neon_pizzajob:requestLeaderboard', function()
    local src = source
    MySQL.query('SELECT identifier, total_deliveries FROM neon_pizzajob ORDER BY total_deliveries DESC LIMIT 10', {}, function(results)
        local leaderboard = {}

        for _, row in ipairs(results) do
            local identifier = row.identifier
            local firstname, lastname = "Unknown", ""

            if Config.Framework == 'QB' then
                local player = QBCore.Functions.GetPlayerByCitizenId(identifier)
                if player then
                    firstname = player.PlayerData.charinfo.firstname
                    lastname = player.PlayerData.charinfo.lastname
                end
            elseif Config.Framework == 'ESX' then
                local player = ESX.GetPlayerFromIdentifier(identifier)
                if player then
                    firstname = player.get('firstName') or "Unknown"
                    lastname = player.get('lastName') or ""
                end
            end

            table.insert(leaderboard, {
                identifier = identifier,
                firstname = firstname,
                lastname = lastname,
                total_deliveries = row.total_deliveries
            })
        end

        TriggerClientEvent('neon_pizzajob:receiveLeaderboard', src, leaderboard)
    end)
end)