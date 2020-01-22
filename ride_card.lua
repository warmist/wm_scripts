--BAH vanilla df lets you ride :<
local adv=df.global.units.active[0]
function GetItemsAtPos(pos)
    local ret={}
    for k,v in pairs(df.global.world.items.all) do
        if v.flags.on_ground and v.pos.x==pos.x and v.pos.y==pos.y and v.pos.z==pos.z then
            table.insert(ret,v)
        end
    end
    return ret
end
local items=GetItemsAtPos(adv.pos)

for i,item in ipairs(items) do
	if df.minecart:is_instance(item) then

        adv.riding_item_id=item.id
        item.general_refs:insert("#",{new=df.general_ref_unit_riderst,unit_id=adv.id})
        item.flags2.has_rider=true
        return true
	end
end