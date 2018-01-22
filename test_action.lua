local u=dfhack.gui.getSelectedUnit() or df.global.world.units.active[0]
local id=u.next_action_id
u.next_action_id=id+1
local m={x=u.pos.x+1,y=u.pos.y,z=u.pos.z,timer=3,timer_init=9,fatigue=0,flags=0}
u.actions:insert(0,{new=true,type=0,id=id,data={move=m}})
printall(u.actions[#u.actions-1])