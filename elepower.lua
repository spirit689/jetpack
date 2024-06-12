
local tooldef = minetest.registered_items['jetpack:jetpack']

local defgroups = tooldef.groups
defgroups['ele_tool'] = 1

minetest.override_item('jetpack:jetpack', {
    ele_capacity = jetpack.JET_CHARGE_MAX,
    ele_storage = 0,
    groups = defgroups
})

jetpack.get_item_charge = function (itemstack)
    return ele.tools.get_tool_property(itemstack, "storage")
end

jetpack.set_item_charge = function (itemstack, currentCharge)
    local meta = itemstack:get_meta()
    meta:set_int("storage", currentCharge)
    itemstack = ele.tools.update_tool_wear(itemstack)
end
