local opened_modules = {}

RegisterNetEvent("CORE.UI:ClearOpenedModules")
AddEventHandler("CORE.UI:ClearOpenedModules", function() opened_modules = {} end)

function OpenUI(show, page, data, props, block)
    data = data or {}
    props = props or {}

    SetNuiFocus(show, show)
    SendReactMessage('setVisible', show)

    if page then
        SendReactMessage('setPage', {page = page, props = props})
    end

    if block then
        SendReactMessage('setBlocked', block)
    end

    if data and data.event then
        if not opened_modules[page] then
            opened_modules[page] = true
            Wait(500)
        end
        SendReactMessage(data.event.message, data.event.data)
    end
end

RegisterNetEvent("CORE.UI:Open")
AddEventHandler("CORE.UI:Open", function(page, data, props, block)
    OpenUI(true, page, data, props, block)
end)

RegisterNetEvent("CORE.UI:SendReactMessage")
AddEventHandler("CORE.UI:SendReactMessage", function(data) 
    SendReactMessage(data.event, data.data) 
end)

RegisterNetEvent("CORE.UI:Close")
AddEventHandler("CORE.UI:Close", function() 
    OpenUI(false) 
end)

RegisterNetEvent("CORE.UI:setPage")
AddEventHandler("CORE.UI:setPage", function(page) 
    OpenUI(true, page) 
end)

RegisterNetEvent('CORE.UI:hideFrame', function()
    OpenUI(false)
end)

RegisterNUICallback('NUICALLBACK', function(data, cb)
    print('CORE.UI:' .. data.event, data.data)
    TriggerEvent('CORE.UI:' .. data.event, data.data)

    cb({})
end)