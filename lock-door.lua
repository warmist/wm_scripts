local cursor=copyall(df.global.cursor)

local door=dfhack.buildings.findAtTile(cursor)
if door and df.is_instance(df.building_doorst,door) then
	door.door_flags.forbidden=true
	door.door_flags.pet_passable=false --optional
else
	if door then
		qerror("Not a door at cursor")
	else
		qerror("No building (esp. doors) at cursor")
	end
end