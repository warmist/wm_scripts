local args = {...}
local pos=copyall(df.global.world.units.active[0].pos)
for i,v in ipairs(df.global.world.items.other.IN_PLAY) do
	local name=dfhack.items.getDescription(v,0)

	if string.find(name,args[1]) then
		local x,y,z=dfhack.items.getPosition(v)
		print(i,x-pos.x,y-pos.y,z-pos.z)
	end
end