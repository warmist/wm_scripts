local a=df.global.world.armies.all


function find_player_group(  )
	for i,v in ipairs(a) do
		if v.flags.player then
			return i,v
		end
	end
end

local id,pl=find_player_group()
print("player:",id)
--[[for i,v in ipairs(pl.members) do
	print(i,v.nemesis_id)
	local nr=df.nemesis_record.find(v.nemesis_id)
	printall(nr.figure)
end]]
local p={pl.pos.x,pl.pos.y}
for i,v in ipairs(a) do
	if v.pos.x==p[1] and v.pos.y==p[2] and i~=id then
		print("army:",i,v)
		printall(v)
	end
end