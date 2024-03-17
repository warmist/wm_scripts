local b=dfhack.gui.getSelectedBuilding()
local h=df.machine_tile_set:new()
df.global.world.buildings:get_machine_hookup_list(h,b:getType(),b:getSubtype(),b.x1,b.y1,b.x2,b.y2,b.z,0)

printall(h.tiles)
printall(h.can_connect)