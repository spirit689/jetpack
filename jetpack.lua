
jetpack.get_item_charge = function (itemstack)
    local meta = itemstack:get_meta()
    return meta:get_float('jetpack:charge')
end

jetpack.set_item_charge = function (itemstack, currentCharge)
    local meta = itemstack:get_meta()
    local wear = 65535 - 65535 * currentCharge / jetpack.JET_CHARGE_MAX

    meta:set_float('jetpack:charge', currentCharge)
    itemstack:set_wear(wear)
end

-- charging capsule restores 25% energy on use

minetest.register_craftitem('jetpack:charging_capsule', {
    description = 'Energy capsule',
    inventory_image = 'jetpack_charging_capsule.png',
    on_use = function (itemstack, user, pointed_thing)
        local amount = math.floor(jetpack.JET_CHARGE_MAX / 4)
        local state = jetpack.get_state(user)

        if not state then
            return nil
        end

        local name = user:get_player_name()
        local charge = jetpack.get_charge(name)
        local pos = user:get_pos()

        if jetpack.JET_CHARGE_MAX - charge >= amount then
            jetpack.set_charge(name, charge + amount)
            hb.change_hudbar(user, jetpack.HB_NAME, charge + amount)

            minetest.sound_play('jetpack_charge', {pos = pos, gain = 1.0, max_hear_distance = 8}, true)
            itemstack:take_item()
        end

        return itemstack
    end
})

minetest.register_craft({
    output = 'jetpack:charging_capsule 16',
    recipe = {
        {'', 'jetpack:cable', ''},
        {'default:paper', 'default:mese_crystal_fragment', 'default:paper'},
    },
})
