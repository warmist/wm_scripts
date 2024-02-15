--An annoted copy of adv-ai customized for Rithaniel @ discord

--NOTE to Rithaniel: this needs some changes for the what happens when unit got the item.

-- Includes and configuration
local script=require "gui.script" 
local wakeup_ticks=100

--utility

--format a nicer name for a unit
function nice_name( unit )
	local race=df.creature_raw.find(unit.race)
	local caste=race.caste[unit.caste]
	return string.format("%s (%s)",dfhack.TranslateName(unit.name),caste.caste_name[0]);
end
--square of distance between two points
function dist_sq( p1,p2 )
	local dx=p1.x-p2.x
	local dy=p1.y-p2.y
	local dz=p1.z-p2.z
	return dx*dx+dy*dy+dz*dz
end
--find closest item on group from position
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
--set unit to go to the place
function set_unit_target_pos( unit,pos )
	--set target position
	unit.idle_area.x=pos.x
    unit.idle_area.y=pos.y
    unit.idle_area.z=pos.z
	--set some stuff, note: type is not imporant if i remember correctly
    unit.idle_area_type=df.unit_station_type.Commander
    unit.idle_area_threshold=0
    unit.follow_distance=50
    --invalidate old path, this makes df generate a new one
    unit.path.dest={x=unit.idle_area.x,y=unit.idle_area.y,z=unit.idle_area.z}
    unit.path.goal=df.unit_path_goal.SeekStation
    unit.path.path.x:resize(0)
    unit.path.path.y:resize(0)
    unit.path.path.z:resize(0)
end
--get item that is hauled by the unit, this is needed as unit might have equipment
function get_hauled_item( unit )
	for i,v in ipairs(unit.inventory) do
		if v.mode==df.unit_inventory_item.T_mode.Hauled then
			return v,i
		end
	end
end
--ai functions

--make unit move the position with "near_dist" as (optional) threshold distance treshold
function ai_move_to(unit, pos,near_dist )
	near_dist=near_dist or 0
	local nds=near_dist*near_dist --we use squared dist as simple perf. improvement
	--this value might need increasing for bigger (or all) forts as it's intended for adv-mode
	local max_iter=100 --how many iterations to retry the distance check

	--set unit goal to move to
	print("Move to start")
    set_unit_target_pos(unit,pos)
    print("waiting to get close")
	--calculate distance for first check
    near_dist=dist_sq(unit.pos,pos)
    if near_dist<=nds then
    	return true --oh we are done!
    else
    	for i=1,max_iter do --retry every `wakeup_ticks` checking if we are close enough
    		script.sleep(wakeup_ticks,"ticks")
    		near_dist=dist_sq(unit.pos,pos)
    		print("waiting to get close",math.sqrt(near_dist))
    		if near_dist<=nds then
    			return true --goal reached
    		end
			--if goal is not reached, reset unit "ai" to move to it. 
			--  This might be not needed for enemy units as their ai is not interrupted by random jobs/etc
    		set_unit_target_pos(unit,pos)
    	end
    end
	--failure case, as something went wrong (e.g. death? fights? etc...)
	--NB: TODO probably could check if unit is still alive tbh
    print("Failed to get close over "..max_iter.." iterations")
    return false
end

--add item to the unit as hauled
function ai_haul( unit,item )
	--no cheating!
	if dist_sq(unit.pos,item.pos)>0 then --check if unit is close enough
		print("WARN: ai_haul but too far")
		return false,"haul failed: too far"
	else
		--if close, then add to inventory
		return dfhack.items.moveToInventory(item,unit,df.unit_inventory_item.T_mode.Hauled,-1)
	end
end
--remove hauled item and place it on ground
function ai_drop_haul( unit )
	local item=get_hauled_item(unit)
	if item then
		dfhack.items.moveToGround(item.item,unit.pos)
	else
		print("WARN: ai_drop_haul, but not hauling")
	end
end

--actual "meat" of the script
--this is intended to be called as coroutine, so the code becomes very simple
--TODO: what happens if game saves/exits in the middle?
function steal_item( unit,item )
	--already had the item, drop the old one. Might be commented out, 
	--	so the enemy could stack up a few items
	if get_hauled_item(unit) then
		ai_drop_haul(unit)
	end
	--these functions can stop execution of this script and wait until something happens
	print("item found:",item)
	--we want unit first to move the item
	ai_move_to(unit,item.pos)
	print("moved to item, hauling")
	--then add it to hauled items
	ai_haul(unit,item)
	print("moving to target")

	--TODO: add some sort of escape logic here?
end
local unit
local item
--TODO: this next line needs unit and item as input, but how do we select them?
script.start(steal_item,unit,item)