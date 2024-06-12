
minetest.override_item('jetpack:jetpack', {
    on_refill = technic.refill_RE_charge,
    wear_represents = 'technic_RE_charge'
})

-- register technic charge
technic.register_power_tool('jetpack:jetpack', jetpack.JET_CHARGE_MAX)

jetpack.get_item_charge = function (itemstack)
    local meta = itemstack:get_meta()
    return meta:get_float('technic:charge')
end

jetpack.set_item_charge = function (itemstack, currentCharge)
    local meta = itemstack:get_meta()
    meta:set_float('technic:charge', currentCharge)
    technic.set_RE_wear(itemstack, currentCharge, jetpack.JET_CHARGE_MAX)
end
