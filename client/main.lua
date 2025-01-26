local pedModel = Config.Ped.model
local deliveryVehicle = nil
local isDelivering = false
local currentDelivery = nil
local targetZoneId = nil
local currentDeliveryBlip = nil
local playerVehicles = {}

local function getRandomDeliveryLocation()
    local locations = Config.Deliveries.locations
    return locations[math.random(1, #locations)]
end

function startDelivering()
    local vehicleHash = GetHashKey(Config.Deliveries.vehicle)
    local uniquePlate = "PIZZA" .. tostring(math.random(100, 999))

    lib.notify({
        title = 'Delivery Started',
        description = 'Head to your vehicle and follow the waypoint!',
        type = 'inform'
    })

    RequestModel(vehicleHash)
    while not HasModelLoaded(vehicleHash) do
        Wait(500)
    end

    local vehicle = CreateVehicle(vehicleHash, Config.Deliveries.spawnLocation.x, Config.Deliveries.spawnLocation.y, Config.Deliveries.spawnLocation.z, Config.Deliveries.spawnLocation.w, true, false)
    SetVehicleNumberPlateText(vehicle, uniquePlate)
    playerVehicles[PlayerPedId()] = NetworkGetNetworkIdFromEntity(vehicle)
    TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)



    TriggerServerEvent('neon_pizzajob:giveVehicleKeys', uniquePlate, NetworkGetNetworkIdFromEntity(vehicle))

    isDelivering = true
    TriggerServerEvent('neon_pizzajob:startDelivering')
    currentDelivery = getRandomDeliveryLocation()
    SetDeliveryWaypoint(currentDelivery)
    createDeliveryBlip(currentDelivery)
end

function SetDeliveryWaypoint(delivery)
    if delivery and delivery.location then
        SetNewWaypoint(delivery.location.x, delivery.location.y)
    end
end

function RemovePreviousMarkerAndTarget()
    if targetZoneId then
        if Config.Target == 'ox_target' then
            exports.ox_target:removeZone(targetZoneId)
        elseif Config.Target == 'qb-target' then
            exports['qb-target']:RemoveZone('delivery_zone')
        end
        targetZoneId = nil
    end

    if currentDeliveryBlip then
        RemoveBlip(currentDeliveryBlip)
        currentDeliveryBlip = nil
    end

    if Config.Target == 'none' then
        lib.hideTextUI()
    end
end

local function addTarget(coords, label, options)
    if Config.Target == 'ox_target' then
        return exports.ox_target:addSphereZone({
            coords = coords,
            radius = options.distance or 1.5,
            options = {
                {
                    label = "Deliver Pizza",
                    icon = 'fa-solid fa-box',
                    onSelect = options.onSelect,
                    canInteract = options.canInteract
                }
            }
        })
    elseif Config.Target == 'qb-target' then
        exports['qb-target']:AddBoxZone('delivery_zone', coords, 1.0, 1.0, {
            name = 'delivery_zone',
            heading = 0,
            debugPoly = false,
            minZ = coords.z - 1.0,
            maxZ = coords.z + 1.0,
        }, {
            options = {
                {
                    label = "Deliver Pizza",
                    icon = 'fa-solid fa-box',
                    action = options.onSelect
                }
            },
            distance = options.distance or 1.5
        })
    elseif Config.Target == 'none' then
        CreateThread(function()
            local showing = false
            while true do
                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)
                local distance = #(playerCoords - coords)

                if distance <= (options.distance or 1.5) then
                    if not showing then
                        lib.showTextUI("[E] Deliver Pizza", {
                            position = "right-center",
                        })
                        showing = true
                    end

                    if IsControlJustReleased(0, 38) then
                        options.onSelect()
                    end
                else
                    if showing then
                        lib.hideTextUI()
                        showing = false
                    end
                end

                Wait(0)
            end
        end)
    end
end

function createDeliveryBlip(delivery)
    local deliveryCoords = delivery.location
    RemovePreviousMarkerAndTarget()

    currentDeliveryBlip = AddBlipForCoord(deliveryCoords.x, deliveryCoords.y, deliveryCoords.z)
    SetBlipSprite(currentDeliveryBlip, 1)
    SetBlipColour(currentDeliveryBlip, 5)
    SetBlipScale(currentDeliveryBlip, 0.8)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Delivery Location")
    EndTextCommandSetBlipName(currentDeliveryBlip)

    targetZoneId = addTarget(deliveryCoords, "Deliver Pizza", {
        icon = 'fa-solid fa-box',
        distance = 1.5,
        onSelect = function()
            StartDeliveryAnimation()
        end,
        canInteract = function()
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local distance = #(playerCoords - vector3(deliveryCoords.x, deliveryCoords.y, deliveryCoords.z))

            return not IsPedInAnyVehicle(playerPed, false) and distance <= 1.5
        end
    })
end

function StartDeliveryAnimation()
    local playerPed = PlayerPedId()
    local animDict = "anim@heists@box_carry@"
    local animName = "idle"
    local prop = "prop_pizza_box_02"
    local propBone = 28422
    local propPlacement = {0.0100, -0.1000, -0.1590, 20.0000007, 0.0, 0.0}

    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(10)
    end

    local propEntity = CreateObject(GetHashKey(prop), GetEntityCoords(playerPed), true, true, false)
    AttachEntityToEntity(propEntity, playerPed, GetPedBoneIndex(playerPed, propBone),
        propPlacement[1], propPlacement[2], propPlacement[3],
        propPlacement[4], propPlacement[5], propPlacement[6],
        true, true, false, true, 1, true
    )

    TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, -1, 49, 0, false, false, false)

    if lib.progressCircle({
        duration = Config.DeliveryTime or 3000,
        position = 'bottom',
        label = 'Delivering Pizza',
        useWhileDead = false,
        canCancel = false,
        disable = {
            car = true,
            move = true,
            combat = true,
            mouse = false
        }
    }) then
        ClearPedTasks(playerPed)
        DetachEntity(propEntity, true, true)
        DeleteObject(propEntity)

        CompleteDelivery()
    end
end

function CompleteDelivery()
    TriggerServerEvent('neon_pizzajob:completeDelivery')

    lib.notify({
        title = 'Delivery Complete',
        description = 'Pizza delivered. Please move onto the next delivery.',
        type = 'success'
    })

    local newDelivery
    repeat
        newDelivery = getRandomDeliveryLocation()
    until newDelivery ~= currentDelivery

    currentDelivery = newDelivery
    SetDeliveryWaypoint(currentDelivery)
    createDeliveryBlip(currentDelivery)
end

function StopDelivering()
    local playerVehicle = playerVehicles[PlayerPedId()]
    local vehicle = NetworkGetEntityFromNetworkId(playerVehicle)

    if playerVehicle and DoesEntityExist(vehicle) then
        local plate = GetVehicleNumberPlateText(vehicle)
        TriggerServerEvent('neon_pizzajob:removeVehicleKeys', plate, playerVehicle)
        playerVehicles[PlayerPedId()] = nil
    end

    lib.notify({
        title = 'Delivery Stopped',
        description = 'You have stopped delivering pizzas. The vehicle has been removed.',
        type = 'inform'
    })

    RemovePreviousMarkerAndTarget()
    SetWaypointOff()
    TriggerServerEvent('neon_pizzajob:stopDelivering')
    isDelivering = false
    currentDelivery = nil
end

local function viewLeaderboard()
    TriggerServerEvent('neon_pizzajob:requestLeaderboard')
end

local function displayLeaderboardMenu(leaderboardData)
    local leaderboardOptions = {}

    for i, playerData in ipairs(leaderboardData) do
        table.insert(leaderboardOptions, {
            title = string.format("Rank %d: %s %s", i, playerData.firstname, playerData.lastname),
            description = string.format("Total Deliveries: %d", playerData.total_deliveries),
            icon = 'fa-solid fa-user'
        })
    end

    lib.registerContext({
        id = 'leaderboard_menu',
        title = 'Top Pizza Deliverers',
        options = leaderboardOptions,
        onExit = function() end
    })

    lib.showContext('leaderboard_menu')
end

RegisterNetEvent('neon_pizzajob:receiveLeaderboard', function(leaderboardData)
    displayLeaderboardMenu(leaderboardData)
end)

local function openChefMenu()
    local options = {}

    if isDelivering then
        table.insert(options, {
            title = 'Stop Delivering',
            description = 'Stop delivering pizzas and return the vehicle.',
            icon = 'fa-solid fa-stop',
            iconColor = '#FF0000',
            onSelect = function()
                StopDelivering()
            end
        })
    else
        table.insert(options, {
            title = 'Start Deliveries',
            description = 'Start delivering pizzas around the city.',
            icon = 'fa-solid fa-play',
            iconColor = '#00FF00',
            onSelect = function()
                startDelivering()
            end
        })
    end

    table.insert(options, {
        title = 'View Leaderboard',
        description = 'See the top pizza deliverers!',
        icon = 'fa-solid fa-trophy',
        onSelect = function()
            viewLeaderboard()
        end
    })

    lib.registerContext({
        id = 'chef_menu',
        title = 'Pizza Deliveries',
        options = options
    })

    lib.showContext('chef_menu')
end

local function addTargetOptions(ped)
    if Config.Target == 'ox_target' then
        exports.ox_target:addLocalEntity(ped, {
            {
                label = Config.TargetSettings.label,
                distance = Config.TargetSettings.distance,
                size = Config.TargetSettings.size,
                icon = 'fa-solid fa-pizza-slice',
                canInteract = function()
                    local playerPed = PlayerPedId()
                    return not IsPedInAnyVehicle(playerPed, false) and not IsEntityDead(playerPed)
                end,
                onSelect = function()
                    openChefMenu()
                end
            }
        })
    elseif Config.Target == 'qb-target' then
        exports['qb-target']:AddTargetEntity(ped, {
            options = {
                {
                    label = Config.TargetSettings.label,
                    icon = 'fa-solid fa-pizza-slice',
                    action = function()
                        openChefMenu()
                    end
                }
            },
            distance = Config.TargetSettings.distance
        })
    elseif Config.Target == 'none' then
        CreateThread(function()
            local showing = false
            while true do
                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)
                local pedCoords = GetEntityCoords(ped)
                local distance = #(playerCoords - pedCoords)

                if distance <= Config.TargetSettings.distance then
                    if not showing then
                        lib.showTextUI("[E] " .. Config.TargetSettings.label, {
                            position = "right-center",
                        })
                        showing = true
                    end

                    if IsControlJustReleased(0, 38) then
                        openChefMenu()
                    end
                else
                    if showing then
                        lib.hideTextUI()
                        showing = false
                    end
                end

                Wait(0)
            end
        end)
    end
end

local function spawnPed()
    local pedHash = GetHashKey(pedModel)

    CreateThread(function()
        RequestModel(pedHash)
        local timeout = 5000
        while not HasModelLoaded(pedHash) do
            Wait(500)
            timeout = timeout - 500
        end

        if HasModelLoaded(pedHash) then
            local pedZ = Config.Ped.location.z - 1.0
            local ped = CreatePed(4, pedHash, Config.Ped.location.x, Config.Ped.location.y, pedZ, Config.Ped.location.w, false, true)
            SetEntityInvincible(ped, true)
            FreezeEntityPosition(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            addTargetOptions(ped)
        end
    end)
end

local function createBlip()
    CreateThread(function()
        local blip = AddBlipForCoord(Config.Ped.location.x, Config.Ped.location.y, Config.Ped.location.z)
        SetBlipSprite(blip, Config.Blip.sprite)
        SetBlipColour(blip, Config.Blip.color)
        SetBlipScale(blip, Config.Blip.size)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.Blip.label)
        EndTextCommandSetBlipName(blip)
    end)
end

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        spawnPed()
        createBlip()
    end
end)