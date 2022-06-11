local script=require "gui.script"
local wakeup_ticks=100
--utility
function get_companions(unit)
    unit=unit or df.global.world.units.active[0]
    local t_nem=dfhack.units.getNemesis(unit)
    if t_nem==nil then
        qerror("Invalid unit! No nemesis record")
    end
    local ret={}
    for k,v in pairs(t_nem.companions) do
        local u=df.nemesis_record.find(v)
        if u.unit then
            table.insert(ret,u.unit)
        end
    end
    return ret
end
function nice_name( unit )
	local race=df.creature_raw.find(unit.race)
	local caste=race.caste[unit.caste]
	return string.format("%s (%s)",dfhack.TranslateName(unit.name),caste.caste_name[0]);
end
function dist_sq( p1,p2 )
	local dx=p1.x-p2.x
	local dy=p1.y-p2.y
	local dz=p1.z-p2.z
	return dx*dx+dy*dy+dz*dz
end
function find_nearest_item_onground( pos,item_type )
	local item_list=df.global.world.items.other[0] --TODO: in_play
	local best_dist=math.huge
	local best_item
	for i,v in ipairs(item_list) do
		if v:getType()==item_type and v.flags.on_ground then
			local distsq=dist_sq(pos,v.pos)
			if best_dist>distsq then
				best_dist=distsq
				best_item=v
			end
		end
	end
	return best_item,math.sqrt(best_dist)
end
function set_unit_target_pos( unit,pos )
	unit.idle_area.x=pos.x
    unit.idle_area.y=pos.y
    unit.idle_area.z=pos.z

    unit.idle_area_type=df.unit_station_type.Commander
    unit.idle_area_threshold=0
    unit.follow_distance=50
    --invalidate old path
    unit.path.dest={x=unit.idle_area.x,y=unit.idle_area.y,z=unit.idle_area.z}
    unit.path.goal=df.unit_path_goal.SeekStation
    unit.path.path.x:resize(0)
    unit.path.path.y:resize(0)
    unit.path.path.z:resize(0)
end
function get_hauled_item( unit )
	for i,v in ipairs(unit.inventory) do
		if v.mode==df.unit_inventory_item.T_mode.Hauled then
			return v,i
		end
	end
end
--ai functions

function ai_move_to(unit, pos,near_dist )
	near_dist=near_dist or 0
	local nds=near_dist*near_dist
	local max_iter=100
	print("Move to start")
    set_unit_target_pos(unit,pos)
    print("waiting to get close")

    near_dist=dist_sq(unit.pos,pos)
    if near_dist<=nds then
    	return true
    else
    	for i=1,max_iter do
    		script.sleep(wakeup_ticks,"ticks")
    		near_dist=dist_sq(unit.pos,pos)
    		print("waiting to get close",math.sqrt(near_dist))
    		if near_dist<=nds then
    			return true
    		end
    		set_unit_target_pos(unit,pos)
    	end
    end
    print("Failed to get close over "..max_iter.." iterations")
    return false
end
function ai_move_to_unit(unit, trg_unit,near_dist )
	near_dist=near_dist or (math.sqrt(2)+0.000001) --one tile away is also good?
	local nds=near_dist*near_dist
	local max_iter=100
	print("Move to unit start")
    set_unit_target_pos(unit,trg_unit.pos)
    print("waiting to get close")

    near_dist=dist_sq(unit.pos,trg_unit.pos)
    if near_dist<=nds then
    	return true
    else
    	for i=1,max_iter do
    		script.sleep(wakeup_ticks,"ticks")
    		near_dist=dist_sq(unit.pos,trg_unit.pos)
    		print("waiting to get close",math.sqrt(near_dist))
    		if near_dist<=nds then
    			return true
    		end
    		set_unit_target_pos(unit,trg_unit.pos)
    	end
    end
    print("Failed to get close over "..max_iter.." iterations")
    return false
end
function ai_haul( unit,item )
	--no cheating!
	if dist_sq(unit.pos,item.pos)>0 then
		print("WARN: ai_haul but too far")
		return false,"haul failed: too far"
	else
		return dfhack.items.moveToInventory(item,unit,df.unit_inventory_item.T_mode.Hauled,-1)
	end
end
function ai_drop_haul( unit )
	local item=get_hauled_item(unit)
	if item then
		dfhack.items.moveToGround(item.item,unit.pos)
	else
		print("WARN: ai_drop_haul, but not hauling")
	end
end

--actual code
function haul_me_stuff( unit,me )
	if get_hauled_item(unit) then
		ai_drop_haul(unit)
	end
	print("finding stuff")
	local item,d=find_nearest_item_onground(unit.pos,df.item_type.WOOD)
	print("item found:",item,d)
	ai_move_to(unit,item.pos)
	print("moved to item, hauling")
	ai_haul(unit,item)
	print("moving to target")
	ai_move_to_unit(unit,me)
	print("dropping haul")
	ai_drop_haul(unit)
	print("ai script 'haul_me_stuff' complete")
end
script.start(haul_me_stuff,get_companions()[2],df.global.world.units.active[0])