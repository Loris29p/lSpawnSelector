--- A simple wrapper around SendNUIMessage that you can use to
--- dispatch actions to the React frame.
---
---@param action string The action you wish to target
---@param data any The data you wish to send along with this action
function SendReactMessage(action, data)
    SendNUIMessage({action = action, data = data})
end

local currentResourceName = GetCurrentResourceName()

local debugIsEnabled = GetConvarInt(
                           ('%s-debugMode'):format(currentResourceName), 0) == 1

--- A simple debug print function that is dependent on a convar
--- will output a nice prettfied message if debugMode is on
function debugPrint(...)
    if not debugIsEnabled then return end
    local args<const> = {...}

    local appendStr = ''
    for _, v in ipairs(args) do appendStr = appendStr .. ' ' .. tostring(v) end
    local msgTemplate = '^3[%s]^0%s'
    local finalMsg = msgTemplate:format(currentResourceName, appendStr)
    print(finalMsg)
end

function TeleportToWp(ped, pos, heading, safeModeDisabled, func)
    if not safeModeDisabled then
        -- // Is player in a vehicle and the driver? Then we'll use that to teleport.
        local pPed = ped or cache.ped
        local veh = IsPedInAnyVehicle(pPed, false) and
                        GetVehiclePedIsIn(pPed, false) or nil
        local inVehicle = veh ~= nil and GetPedInVehicleSeat(veh, -1) == pPed or
                              false

        local z = pos.z + 1.0

        local vehicleRestoreVisibility = inVehicle and IsEntityVisible(veh)
        local pedRestoreVisibility = IsEntityVisible(pPed)

        -- // Freeze vehicle or player location and fade out the entity to the network.

        -- // Fade out the screen and wait for it to be faded out completely.
        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do Wait(0) end

        if inVehicle then
            FreezeEntityPosition(veh, true)
            if IsEntityVisible(veh) then
                NetworkFadeOutEntity(veh, true, false)
            end
        else
            ClearPedTasksImmediately(pPed)
            FreezeEntityPosition(pPed, true)
            if IsEntityVisible(pPed) then
                NetworkFadeOutEntity(pPed, true, false)
            end
        end

        if func then func() end

        local pId = pPed and PlayerId() or nil

        if pId then
            StartPlayerTeleport(PlayerId(), pos.x, pos.y, pos.z, heading,
                                inVehicle, true, true)

            while IsPlayerTeleportActive() do Wait(0) end
        else
            -- // This will be used to get the return value from the groundz native.
            local groundZ = 850.0

            -- // Bool used to determine if the groundz coord could be found.
            local found = false

            RequestCollisionAtCoord(pos.x, pos.y, z)
            NewLoadSceneStart(pos.x, pos.y, z, pos.x, pos.y, z, 50.0, 0)

            local tempTimer = GetGameTimer()
            while IsNetworkLoadingScene() do
                if GetGameTimer() - tempTimer > 1000 then
                    print(
                        "Waiting for the scene to load is taking too long (more than 1s). Breaking from wait loop.")
                    break
                end
                Wait(0)
            end

            if inVehicle then
                SetEntityCoords(veh, pos.x, pos.y, z, false, false, false, true)
            else
                SetEntityCoords(pPed, pos.x, pos.y, z, false, false, false, true)
            end

            tempTimer = GetGameTimer()
            while not HasCollisionLoadedAroundEntity(pPed) do
                if GetGameTimer() - tempTimer > 1000 then
                    print(
                        "Waiting for the collision to load is taking too long (more than 1s). Breaking from wait loop.")
                    break
                end
                Wait(0)
            end

            found, groundZ = GetGroundZCoordWithOffsets(pos.x, pos.y, z)
            tempTimer = GetGameTimer()
            if not found then z = 950 end
            while not found do
                z = z - 25.0
                found, groundZ = GetGroundZCoordWithOffsets(pos.x, pos.y, z)
                Wait(0)

                if z < 0.0 then break end
            end

            if found then
                print("Ground coordinate found: " .. groundZ)
                if inVehicle then
                    SetEntityCoords(veh, pos.x, pos.y, groundZ, false, false,
                                    false, true)
                    -- // We need to unfreeze the vehicle because sometimes having it frozen doesn't place the vehicle on the ground properly.
                    FreezeEntityPosition(veh, false)
                    SetVehicleOnGroundProperly(veh)
                    -- // Re-freeze until screen is faded in again.
                    FreezeEntityPosition(veh, true)
                else
                    SetEntityCoords(pPed, pos.x, pos.y, groundZ, false, false,
                                    false, true)
                end
            else
                local safePos = pos
                GetNthClosestVehicleNode(pos.x, pos.y, pos.z, 0, safePos, 0, 0,
                                         0)

                print(
                    "Could not find a safe ground coord. Placing you on the nearest road instead.")

                -- // Teleport vehicle, or player.
                if inVehicle then
                    SetEntityCoords(veh, safePos.x, safePos.y, safePos.z, false,
                                    false, false, true)
                    FreezeEntityPosition(veh, false)
                    SetVehicleOnGroundProperly(veh)
                    -- // Re-freeze until screen is faded in again.
                    FreezeEntityPosition(veh, true)
                else
                    SetEntityCoords(pPed, safePos.x, safePos.y, safePos.z,
                                    false, false, false, true)
                end
            end

            if heading then
                if inVehicle then
                    SetEntityHeading(veh, heading)
                else
                    SetEntityHeading(pPed, heading)
                end
            end
        end

        -- // Once the teleporting is done, unfreeze vehicle or player and fade them back in.
        if inVehicle then
            if vehicleRestoreVisibility then
                NetworkFadeInEntity(veh, true)
                if not pedRestoreVisibility then
                    SetEntityVisible(pPed, false, false)
                end
            end
            FreezeEntityPosition(veh, false)
        else
            if pedRestoreVisibility then
                NetworkFadeInEntity(pPed, true)
            end
            FreezeEntityPosition(pPed, false)
        end

        DoScreenFadeIn(500)
        SetGameplayCamRelativePitch(0.0, 1.0)

        return true
    else
        local pPed = ped or PlayerPedId()

        RequestCollisionAtCoord(pos.x, pos.y, pos.z);

        SetEntityCoords(pPed, pos.x, pos.y, pos.z, false, false, false, true);

        if heading then SetEntityHeading(pPed, heading) end

        if func then func() end

        return true
    end
end
