local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

local sounds = {}
local particles = {}
local equip = {}

local m_gravity = player_monoids.gravity
local m_speed = player_monoids.speed

-- hudbar id
local HB_NAME = 'charge'
-- update interval (charge, inventory and hudbar)
local HB_DELTA = 1
-- jetpack charge. default 150000 ~ 10 min (250 EU/s)
local JET_CHARGE_MAX = 150000
-- power consumption per second
local JET_POWER = 250

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
    damage_groups = {cracky=2, snappy=3, choppy=2, crumbly=1, level=2},
    on_refill = technic.refill_RE_charge,
    wear_represents = 'technic_RE_charge'
})

minetest.register_craft({
    output = 'jetpack:battery',
    recipe = {
        {'technic:carbon_steel_ingot', 'technic:fine_gold_wire', 'technic:carbon_steel_ingot'},
        {'technic:mv_cable', 'technic:green_energy_crystal', 'technic:mv_cable'},
        {'technic:carbon_steel_ingot', 'technic:fine_gold_wire', 'technic:carbon_steel_ingot'},
    },
})

minetest.register_craft({
    output = 'jetpack:blades 2',
    recipe = {
        {'', 'technic:carbon_steel_ingot', ''},
        {'technic:carbon_steel_ingot', 'technic:carbon_steel_ingot', 'technic:carbon_steel_ingot'},
        {'', 'technic:carbon_steel_ingot', ''},
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
        {'technic:carbon_steel_ingot', 'jetpack:battery', 'technic:carbon_steel_ingot'},
        {'jetpack:motor', 'technic:mv_cable', 'jetpack:motor'},
        {'', '', ''}
    },
})

-- register technic charge
technic.register_power_tool('jetpack:jetpack', JET_CHARGE_MAX)

-- register charge hudbar
hb.register_hudbar(HB_NAME, 0xFFFFFF, 'Charge', { icon = 'jetpack_charge_icon.png', bgicon = 'jetpack_charge_bgicon.png',  bar = 'jetpack_charge_bar.png' }, 0, JET_CHARGE_MAX, true)

local function jetpack_off (player)
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

local function jetpack_on (player)
    local playerName = player:get_player_name()

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

    equip[playerName].engine = JET_STATE_ON

    m_speed:add_change(player, 2, 'jetpack:speed')
end

local function jetpack_destroy (player)
    local playerName = player:get_player_name()

    jetpack_off(player)

    hb.hide_hudbar(player, HB_NAME)
    equip[playerName] = nil
end

minetest.register_on_joinplayer(function(player)
    local playerMeta = player:get_meta()
    local state = playerMeta:get('jetpack:armor')

    hb.init_hudbar(player, HB_NAME, 0)
    hb.hide_hudbar(player, HB_NAME)
end)

-- set on equip
armor:register_on_equip(function(player, index, stack)
    local itemMeta = minetest.deserialize(stack:get_metadata()) or {}
    local playerName = player:get_player_name()
    local charge = itemMeta.charge or 0

    if stack:get_name() == 'jetpack:jetpack' then
        hb.change_hudbar(player, HB_NAME, charge)
        hb.unhide_hudbar(player, HB_NAME)

        equip[playerName] = {
            charge = charge,
            slot = index,
            state = JET_STATE_HOLD,
            engine = JET_STATE_OFF
        }
    end
end)

-- off if destroyed or unequipped
armor:register_on_destroy(function(player, index, stack)
    if stack:get_name() ~= 'jetpack:jetpack' then return end
    jetpack_destroy(player)
end)

armor:register_on_unequip(function(player, index, stack)
    if stack:get_name() ~= 'jetpack:jetpack' then return end
    jetpack_destroy(player)
end)

local time = 0
local delta = 0
minetest.register_globalstep(function(dtime)
    time = time + dtime
    delta = delta + dtime
    if time < 0.1 then return end

    time = 0

    local player, pos, node, controls, engine, currentCharge, state, velocity, inv, itemstack, stackIndex

    for name, val in pairs(equip) do
        player = minetest.get_player_by_name(name)

        if not player then return end

        engine = val.engine
        currentCharge = val.charge
        state = val.state

        pos = player:getpos()
        node = minetest.get_node({x=pos.x,y=pos.y-1,z=pos.z})
        controls = player:get_player_control()
        velocity = player:get_velocity()

        -- go up
        if controls.jump and node.name == 'air' then
            if engine == JET_STATE_OFF then
                jetpack_on(player)
            end
        end

        if engine == JET_STATE_ON then
            -- check if we are moving too fast
            if state == JET_STATE_UP_SLOW and velocity.y >= 15 then
                m_gravity:del_change(player, 'jetpack:gravity')
                state = JET_STATE_HOLD
            end

            if state == JET_STATE_DOWN_SLOW and velocity.y < -15 then
                m_gravity:add_change(player, -1, 'jetpack:gravity')
                state = JET_STATE_HOLD
            end

            -- flight control up & down
            if controls.jump then
                if state == JET_STATE_HOLD and velocity.y < 15 then
                    state = JET_STATE_UP
                end

                if state == JET_STATE_UP then
                    m_gravity:add_change(player, -0.3, 'jetpack:gravity')
                    state = JET_STATE_UP_SLOW
                end
            else
                if controls.sneak then
                    if (state == JET_STATE_HOLD or state == JET_STATE_HOVER) and velocity.y > -15 then
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
                jetpack_off(player)
            end
        end

        if delta > HB_DELTA then
            if engine == JET_STATE_ON then
                currentCharge = currentCharge - delta * JET_POWER
                if currentCharge < HB_DELTA * JET_POWER then
                    -- ouch!
                    jetpack_off(player)
                    currentCharge = 0
                end

                equip[name].charge = currentCharge

                -- update item in inventory
                inv = minetest.get_inventory({type='detached', name=name..'_armor'})
                stackIndex = equip[name].slot

                itemstack = ItemStack('jetpack:jetpack')
                itemstack:set_metadata(minetest.serialize({ charge = currentCharge }))
                technic.set_RE_wear(itemstack, currentCharge, JET_CHARGE_MAX)

                inv:set_stack('armor', stackIndex, itemstack)
                hb.change_hudbar(player, HB_NAME, currentCharge)
            end
            delta = 0
        end
    end
end)
