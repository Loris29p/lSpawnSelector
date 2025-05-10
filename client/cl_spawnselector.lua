BOUTIQUE = BOUTIQUE or {}
BOUTIQUE.Config = BOUTIQUE.Config or {}

AddEventHandler("spawnselector:open", function()
    OpenUI(true, "spawnselector", {}, {
        title = BOUTIQUE.Config.title,
        subtitle = BOUTIQUE.Config.subtitle,
        serverLogo = BOUTIQUE.Config.serverLogo,
        color = BOUTIQUE.Config.color,
        spawns = BOUTIQUE.Config.spawns,
        translate = BOUTIQUE.Config.translate
    })
end)

RegisterNetEvent('CORE.UI:spawnselector:spawn', function(data)
    local pPed = PlayerPedId()

    if not data then return end
    local spawn = data.spawn
    if not spawn then return end
    spawn = BOUTIQUE.Config.spawns[spawn + 1]

    if spawn.position then
        TriggerEvent("CORE.UI:Close")
        TeleportToWp(pPed, spawn.position, spawn.position.w)
    end
end)