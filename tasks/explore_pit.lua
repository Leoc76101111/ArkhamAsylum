local plugin_label = 'arkham_asylum' -- change to your plugin name

local utils = require "core.utils"
local settings = require 'core.settings'
local tracker = require 'core.tracker'

local status_enum = {
    IDLE = 'idle',
    EXPLORING = 'exploring',
    RESETING = 'reseting explorer',
    INTERACTING = 'interacting with portal',
    WALKING = 'walking to portal'
}
local task = {
    name = 'explore_pit', -- change to your choice of task name
    status = status_enum['IDLE'],
    portal_found = false,
    portal_exit = -1
}
local get_portal = function ()
    local local_player = get_local_player()
    if not local_player then return end
    local player_pos = get_player_position()
    local actors = actors_manager:get_ally_actors()
    for _, actor in pairs(actors) do
        if actor:is_interactable() then
            local actor_name = actor:get_skin_name()
            if actor_name == 'EGD_MSWK_World_PortalTileSetTravel' or
                actor_name == 'EGD_MSWK_World_PortalToFinalEncounter' or
                actor_name == 'S11_EGD_MSWK_World_BelialPortalToFinalEncounter'
            then
                local dist = utils.distance(player_pos, actor)
                if dist <= settings.check_distance then
                    return actor
                end
            end
        end
    end
    return nil
end
task.shouldExecute = function ()
    return (utils.player_in_zone("EGD_MSWK_World_02") or
        utils.player_in_zone("EGD_MSWK_World_01"))
end
task.Execute = function ()
    local local_player = get_local_player()
    if not local_player then return end
    orbwalker.set_clear_toggle(true)
    local portal = get_portal()
    if portal == nil then
        if task.portal_found then
            BatmobilePlugin.reset()
            task.portal_found = false
            task.portal_exit = get_time_since_inject()
            return
        end
        if task.portal_exit + 1 < get_time_since_inject() then
            BatmobilePlugin.resume(plugin_label)
            BatmobilePlugin.update(plugin_label)
            BatmobilePlugin.move(plugin_label)
            task.status = status_enum['EXPLORING']
        else
            task.status = status_enum['RESETING']
            BatmobilePlugin.reset()
        end
    elseif utils.distance(local_player, portal) < 2 then
        task.portal_found = true
        interact_object(portal)
        task.status = status_enum['INTERACTING']
    else
        BatmobilePlugin.pause(plugin_label)
        BatmobilePlugin.update(plugin_label)
        BatmobilePlugin.set_target(plugin_label, portal)
        BatmobilePlugin.move(plugin_label)
        task.status = status_enum['MOVING']
    end
end

return task