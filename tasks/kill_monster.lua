local plugin_label = 'arkham_asylum' -- change to your plugin name

local utils = require "core.utils"
local settings = require 'core.settings'
local tracker = require 'core.tracker'

local ignore_list = {
    ['S11_BabyBelial_Apparition'] = true
}

local status_enum = {
    IDLE = 'idle',
    WALKING = 'walking to enemy',
}
local task = {
    name = 'kill_monster', -- change to your choice of task name
    status = status_enum['IDLE'],
}
local get_closest_enemies = function ()
    local local_player = get_local_player()
    if not local_player then return end
    local player_pos = get_player_position()
    local enemies = target_selector.get_near_target_list(player_pos, 50)
    local closest_enemy, closest_enemy_dist
    local closest_elite, closest_elite_dist
    local closest_champ, closest_champ_dist
    local closest_boss, closest_boss_dist
    for _, enemy in pairs(enemies) do
        if ignore_list[enemy:get_skin_name()] then goto continue end
        local health = enemy:get_current_health()
        local dist = utils.distance(player_pos, enemy)
        if enemy:is_boss() and
            (closest_boss_dist == nil or dist < closest_boss_dist)
        then
            closest_boss = enemy
            closest_boss_dist = dist
        end
        local raycast_reachable = utility.is_ray_cast_walkeable(player_pos, enemy:get_position(), 0.5, dist)
        if health > 1 and dist <= settings.check_distance and raycast_reachable then
            if closest_enemy_dist == nil or dist < closest_enemy_dist then
                closest_enemy = enemy
                closest_enemy_dist = dist
            end
            if enemy:is_elite() and
                (closest_elite_dist == nil or dist < closest_elite_dist)
            then
                closest_elite = enemy
                closest_elite_dist = dist
            end
            if enemy:is_champion() and
                (closest_champ_dist == nil or dist < closest_champ_dist)
            then
                closest_champ = enemy
                closest_champ_dist = dist
            end
        end
        ::continue::
    end
    return closest_enemy, closest_elite, closest_champ, closest_boss
end

task.shouldExecute = function ()
    local enemy, elite, champion, boss = get_closest_enemies()
    return settings.interact_shrine and
        (enemy ~= nil or elite ~= nil or
        champion ~= nil or boss ~= nil) and
        (utils.player_in_zone("EGD_MSWK_World_02") or
        utils.player_in_zone("EGD_MSWK_World_01"))
end
task.Execute = function ()
    local local_player = get_local_player()
    if not local_player then return end
    BatmobilePlugin.pause(plugin_label)
    BatmobilePlugin.update(plugin_label)
    orbwalker.set_clear_toggle(true)

    local enemy, elite, champion, boss = get_closest_enemies()
    local target = boss or champion or elite or enemy

    if target and utils.distance(local_player, target) > 1 then
        BatmobilePlugin.set_target(plugin_label, target)
        BatmobilePlugin.move(plugin_label)
        task.status = status_enum['WALKING']
    else
        BatmobilePlugin.clear_target(plugin_label)
        task.status = status_enum['IDLE']
    end
end

return task