Config = {}

Config.AmazingScripts = true
Config.VersionChecker = true 

-- Framework Configuration
Config.Framework = 'QB' -- Choose from > 'QB' & 'ESX' (Leave as 'QB' if you are using QBX)

-- Target System Configuration
Config.Target = 'ox_target' -- Choose Target system. Default 'ox_target'. Options: 'ox_target', 'qb-target', 'none' (Will use TextUI)

-- Config for Delivering Pizza Progress Bar
Config.DeliveryTime = 5000  -- Time in milliseconds for the progress bar to complete

-- Config for Payment on Delivery
Config.Pay = {
    min = 50, -- Minimum amount for each delivery
    max = 100 -- Maximum amount for each delivery
}

-- Ped Configuration
Config.Ped = {
    location = vector4(215.5753, -23.9149, 69.7021, 158.2341),
    model = "s_m_y_chef_01",
}

-- Blip Configuration (No separate location, uses ped location)
Config.Blip = {
    sprite = 488,
    color = 1,
    size = 0.8,
    label = "Pizza Delivery",
}

-- Target Settings for the Ped
Config.TargetSettings = {
    label = "Talk to Chef",
    distance = 1.5,
    size = 1.0,
}

-- Delivery Settings
Config.Deliveries = {
    vehicle = 'panto',
    spawnLocation = vector4(220.0990, -32.8182, 69.7189, 68.5840),

    -- Delivery Locations
    locations = {
        [1] = { 
            location = vector3(206.4080, -86.0276, 69.3822)
        },
        [2] = {
            location = vector3(329.3652, -225.2551, 54.2218)
        },
        [3] = {
            location = vector3(1303.2076, -527.3721, 71.4606)
        },
        [4] = {
            location = vector3(1328.6552, -536.0223, 72.4408)
        },
        [5] = {
            location = vector3(1348.2975, -546.7674, 73.8913)
        },
        [6] = {
            location = vector3(1373.2633, -555.7613, 74.6857)
        },
        [7] = {
            location = vector3(1388.9089, -569.5203, 74.4957)
        },
        [8] = {
            location = vector3(1386.2338, -593.4677, 74.4839)
        },
        [9] = {
            location = vector3(1367.2441, -606.6927, 74.7109)
        },
        [10] = {
            location = vector3(1341.3439, -597.2584, 74.7009)
        },
        [11] = {
            location = vector3(1323.4661, -583.1940, 73.2447)
        },
        [12] = {
            location = vector3(1301.0762, -574.2172, 71.7322)
        },
        [13] = {
            location = vector3(331.4731, 465.2437, 151.2560)
        },
        [14] = {
            location = vector3(315.6923, 502.0507, 153.1797)
        },
        [15] = {
            location = vector3(324.9917, 537.1765, 153.8885)
        },
        [16] = {
            location = vector3(224.0782, 513.4530, 140.9175)
        },
        [17] = {
            location = vector3(107.0312, 466.7024, 147.5619)
        },
        [18] = {
            location = vector3(79.9463, 486.2843, 148.2014)
        },
        [19] = {
            location = vector3(57.5254, 449.5797, 147.0729)
        },
        [20] = {
            location = vector3(43.0662, 468.8459, 148.0959)
        }
        -- Add more locations here
    }
}
