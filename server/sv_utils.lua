local webhooks = {
    DeliveryCompletion = "YOUR_WEBHOOK_HERE", -- Replace with your webhook URL
    SuspiciousActivity = "YOUR_WEBHOOK_HERE"  -- Replace with your webhook URL
}

-- Function to send logs to Discord
local function sendEmbedLog(webhookUrl, title, description, color)
    PerformHttpRequest(webhookUrl, function(err, text, headers) end, "POST", json.encode({
        embeds = { {
            title = title,
            description = description,
            color = color
        } }
    }), { ["Content-Type"] = "application/json" })
end

local Utils = {}

function Utils.logDeliveryCompletion(steamName, rewardAmount)
    local description = string.format("**Player:** %s\n**Money Earned:** $%d", steamName, rewardAmount)
    sendEmbedLog(webhooks.DeliveryCompletion, "Pizza Delivery Completed", description, 3066993) -- Green embed
end

function Utils.logSuspiciousActivity(steamName, reason)
    local description = string.format("**Player:** %s\n**Reason:** %s", steamName, reason)
    sendEmbedLog(webhooks.SuspiciousActivity, "Suspicious Activity Detected", description, 15158332) -- Red embed
end

return Utils