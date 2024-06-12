jetpack = {}

local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

local sounds = {}
local particles = {}
local equip = {}

local m_gravity = player_monoids.gravity
local m_speed = player_monoids.speed

-- hudbar id
jetpack.HB_NAME = 'jetpack:charge'
-- update interval (charge, inventory and hudbar)
jetpack.HB_DELTA = 1
-- jetpack charge. default 150000 ~ 10 min (250 EU/s)
jetpack.JET_CHARGE_MAX = 150000
-- power consumption per second
jetpack.JET_POWER = 250
-- maximum vertical velocity in air
jetpack.JET_MAX_VELOCITY = 5

-- jet state
local JET_STATE_OFF = 0
local JET_STATE_ON = 1

local JET_STATE_UP = 1
local JET_STATE_UP_SLOW = 2

local JET_STATE_HOLD = 3
local JET_STATE_HOVER = 4

local JET_STATE_DOWN = 5
local JET_STATE_DOWN_SLOW = 6

-- recipes
minetest.register_craftitem('jetpack:battery', {
    description = 'Jetpack battery',
    inventory_image = 'jetpack_battery.png',
})

minetest.register_craftitem('jetpack:blades', {
    description = 'Blades',
    inventory_image = 'jetpack_blade.png',
})

minetest.register_craftitem('jetpack:cable', {
    description = 'Cable',
    inventory_image = 'jetpack_cable.png',
})

minetest.register_craftitem('jetpack:battery_core', {
    description = 'Jetpack battery core',
    inventory_image = 'jetpack_battery_core.png',
})

minetest.register_craftitem('jetpack:motor', {
    description = 'Electric engine',
    inventory_image = 'jetpack_engine.png',
})

armor:register_armor('jetpack:jetpack', {
    description = 'Jetpack',
    texture = 'jetpack_jetpack.png',
    inventory_image = 'jetpack_jetpack_inv.png',
    groups = {armor_torso=1, armor_heal=0, armor_use=0, physics_speed=-0.04, physics_gravity=0.04},
    armor_groups = {fleshy=10},
    damage_groups = {cracky=2, snappy=3, choppy=2, crumbly=1, level=2}
})

minetest.register_craft({
    output = 'jetpack:cable 3',
    recipe = {
        {'basic_materials:copper_wire', 'basic_materials:copper_wire', 'basic_materials:copper_wire'},
    },
})

minetest.register_craft({
    output = 'jetpack:battery_core',
    recipe = {
        {'jetpack:cable', 'basic_materials:copper_wire', 'jetpack:cable'},
        {'basic_materials:energy_crystal_simple', 'default:diamond', 'basic_materials:energy_crystal_simple'},
        {'jetpack:cable', 'basic_materials:copper_wire', 'jetpack:cable'},
    },
})

minetest.register_craft({
    output = 'jetpack:battery',
    recipe = {
        {'default:steel_ingot', 'basic_materials:gold_wire', 'default:steel_ingot'},
        {'jetpack:cable', 'jetpack:battery_core', 'jetpack:cable'},
        {'default:steel_ingot', 'basic_materials:gold_wire', 'default:steel_ingot'},
    },
})

minetest.register_craft({
    output = 'jetpack:blades 2',
    recipe = {
        {'', 'default:steel_ingot', ''},
        {'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'},
        {'', 'default:steel_ingot', ''},
    },
})

minetest.register_craft({
    output = 'jetpack:motor',
    type = 'shapeless',
    recipe = {'basic_materials:motor', 'jetpack:blades'},
})

minetest.register_craft({
    output = 'jetpack:jetpack',
    recipe = {
        {'default:steel_ingot', 'jetpack:battery', 'default:steel_ingot'},
        {'jetpack:motor', 'jetpack:cable', 'jetpack:motor'},
        {'', '', ''}
    },
})

-- allow charging in machines
local technic_enabled = minetest.get_modpath('technic');
local elepower_enabled = minetest.get_modpath('elepower');

if technic_enabled then
    dofile(modpath .. '/technic.lua')
elseif elepower_enabled then
    dofile(modpath .. '/elepower.lua')
else
    dofile(modpath .. '/jetpack.lua')
end

-- register charge hudbar
hb.register_hudbar(jetpack.HB_NAME, 0xFFFFFF, 'Charge', { icon = 'jetpack_charge_icon.png', bgicon = 'jetpack_charge_bgicon.png',  bar = 'jetpack_charge_bar.png' }, 0, jetpack.JET_CHARGE_MAX, true)

-- end of flight
jetpack.off = function (player)
    local playerName = player:get_player_name()

    if sounds[playerName] then
        minetest.sound_stop(sounds[playerName])
        sounds[playerName] = nil
    end

    if particles[playerName] then
        minetest.delete_particlespawner(particles[playerName])
        particles[playerName] = nil
    end

    equip[playerName].state = JET_STATE_HOLD
    equip[playerName].engine = JET_STATE_OFF

    m_gravity:del_change(player, 'jetpack:gravity')
    m_speed:del_change(player, 'jetpack:speed')
end

-- start lift up
jetpack.on = function (player)
    local playerName = player:get_player_name()

    if equip[playerName] then
        equip[playerName].engine = JET_STATE_ON
    end

    if not sounds[playerName] then
        sounds[playerName] = minetest.sound_play('jetpack_loop', {
            max_hear_distance = 8,
            gain = 20.0,
            object = player,
            loop = true
        })
    end

    if not particles[playerName] then
        particles[playerName] = minetest.add_particlespawner({
            amount = 10,
            time = 0,
            glow = 4,
            texture = 'jetpack_particle.png',
            attached = player,
            minpos = {x=-0.2, y=0.8, z=-0.15},
            maxpos = {x=0.2, y=0.8, z=-0.15},
            minvel = {x=-1, y=-4, z=-1},
            maxvel = {x=1, y=-4, z=1},
            minacc = {x=0, y=-1, z=0},
            minexptime = 0.2,
            maxexptime = 0.2,
            minsize = 4,
            maxsize = 4
        })
    end

    m_speed:add_change(player, 2, 'jetpack:speed')
end

-- completely disable
jetpack.destroy = function (player)
    local playerName = player:get_player_name()
    local playerMeta = player:get_meta()

    jetpack.off(player)

    hb.hide_hudbar(player, jetpack.HB_NAME)

    playerMeta:set_string('jetpack:armor', '')
    equip[playerName] = nil
end

-- get charge value
jetpack.get_charge = function (playerName)
    local inv = minetest.get_inventory({type='detached', name=playerName..'_armor'})
    local itemstack = inv:get_stack('armor', equip[playerName].slot)
    return jetpack.get_item_charge(itemstack);
end

-- set charge value
jetpack.set_charge = function (playerName, currentCharge)
    local inv = minetest.get_inventory({type='detached', name=playerName..'_armor'})
    local itemstack = inv:get_stack('armor', equip[playerName].slot)

    jetpack.set_item_charge(itemstack, currentCharge);

    inv:set_stack('armor', equip[playerName].slot, itemstack)
    equip[playerName].charge = currentCharge
end

-- save player state
jetpack.save_state = function (player)
    local playerName = player:get_player_name()
    local playerMeta = player:get_meta()
    local state = ''

    if equip[playerName] then
        state = minetest.serialize(equip[playerName])
    end

    playerMeta:set_string('jetpack:armor', state)
end

-- get player state
jetpack.get_state = function (player)
    local name = player:get_player_name()
    return equip[name]
end

minetest.register_on_leaveplayer(function(player)
    jetpack.save_state(player)
end)

minetest.register_on_shutdown(function()
    local player

    for name, val in pairs(equip) do
        player = minetest.get_player_by_name(name)
        if player then
            jetpack.save_state(player)
        end
    end
end)

-- set on equip
armor:register_on_equip(function(player, index, stack)
    if stack:get_name() ~= 'jetpack:jetpack' then return end

    local playerName = player:get_player_name()
    local playerMeta = player:get_meta()
    local state = minetest.deserialize(playerMeta:get_string('jetpack:armor'))

    local charge = jetpack.get_item_charge(stack)

    equip[playerName] = {
        charge = charge,
        slot = index,
        state = JET_STATE_HOLD,
        engine = JET_STATE_OFF
    }

    if state then
        jetpack.set_charge(playerName, state.charge)
        if state.engine == JET_STATE_ON then
            jetpack.on(player)
        end
    end

    local hudstate = hb.get_hudbar_state(player, jetpack.HB_NAME)

    if not hudstate then
        hb.init_hudbar(player, jetpack.HB_NAME, equip[playerName].charge, jetpack.JET_CHARGE_MAX, false)
    else
        hb.change_hudbar(player, jetpack.HB_NAME, equip[playerName].charge)
        hb.unhide_hudbar(player, jetpack.HB_NAME)
    end
end)

-- off if destroyed or unequipped
armor:register_on_destroy(function(player, index, stack)
    if stack:get_name() ~= 'jetpack:jetpack' then return end
    jetpack.destroy(player)
end)

armor:register_on_unequip(function(player, index, stack)
    if stack:get_name() ~= 'jetpack:jetpack' then return end
    jetpack.destroy(player)
end)

local time = 0
local delta = 0
minetest.register_globalstep(function(dtime)
    time = time + dtime
    delta = delta + dtime
    if time < 0.1 then return end

    time = 0

    local player, pos, node, controls, engine, currentCharge, state, velocity

    for name, val in pairs(equip) do
        if not val then goto jet_loop_skip end
        if val.charge <= 0 then goto jet_loop_skip end

        player = minetest.get_player_by_name(name)
        if not player then goto jet_loop_skip end

        engine = val.engine
        state = val.state

        pos = player:get_pos()
        node = minetest.get_node({x=pos.x,y=pos.y-1,z=pos.z})
        controls = player:get_player_control()
        velocity = player:get_velocity()

        -- go up
        if controls.jump and node.name == 'air' then
            if engine == JET_STATE_OFF then
                jetpack.on(player)
            end
        end

        if engine == JET_STATE_ON then
            -- check if we are moving too fast
            if state == JET_STATE_UP_SLOW and velocity.y >= jetpack.JET_MAX_VELOCITY then
                -- m_gravity:del_change(player, 'jetpack:gravity')
                m_gravity:add_change(player, 0.5, 'jetpack:gravity')
                state = JET_STATE_HOLD
            end

            if state == JET_STATE_DOWN_SLOW and velocity.y < -jetpack.JET_MAX_VELOCITY then
                m_gravity:add_change(player, -0.5, 'jetpack:gravity')
                state = JET_STATE_HOLD
            end

            -- flight control up & down
            if controls.jump then
                if (state == JET_STATE_HOLD or state == JET_STATE_HOVER) and velocity.y < jetpack.JET_MAX_VELOCITY then
                    state = JET_STATE_UP
                end

                if state == JET_STATE_UP then
                    m_gravity:add_change(player, -0.5, 'jetpack:gravity')
                    state = JET_STATE_UP_SLOW
                end
            else
                if controls.sneak then
                    if (state == JET_STATE_HOLD or state == JET_STATE_HOVER) and velocity.y > -jetpack.JET_MAX_VELOCITY then
                        state = JET_STATE_DOWN
                    end

                    if state == JET_STATE_DOWN then
                        m_gravity:del_change(player, 'jetpack:gravity')
                        state = JET_STATE_DOWN_SLOW
                    end
                else
                    -- 'hover' mode
                    if math.abs(velocity.y) > 1 then
                        if velocity.y > 0 then
                            m_gravity:add_change(player, 0.1, 'jetpack:gravity')
                        else
                            m_gravity:add_change(player, -0.1, 'jetpack:gravity')
                        end
                        state = JET_STATE_HOVER
                    end

                    if state == JET_STATE_HOVER and math.abs(velocity.y) < 0.1 then
                        m_gravity:add_change(player, 0, 'jetpack:gravity')
                        state = JET_STATE_HOLD
                    end
                end
            end

            equip[name].state = state

            if node.name ~= 'air' then
                jetpack.off(player)
            end
        end

        if delta > jetpack.HB_DELTA then
            if engine == JET_STATE_ON then
                currentCharge = jetpack.get_charge(name)
                currentCharge = currentCharge - delta * jetpack.JET_POWER

                if currentCharge < jetpack.HB_DELTA * jetpack.JET_POWER then
                    -- ouch!
                    jetpack.off(player)
                    currentCharge = 0
                end

                -- update item in inventory
                jetpack.set_charge(name, currentCharge)
                hb.change_hudbar(player, jetpack.HB_NAME, currentCharge)
            end
            delta = 0
        end

        ::jet_loop_skip::
    end
end)
