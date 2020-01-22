local c=copyall(df.global.cursor)



local function find_plant( p )
	local ps=df.global.world.plants.all
	for i,v in ipairs(ps) do
		if v.pos.x==p.x and v.pos.y==p.y and v.pos.z==p.z then
			return i,v
		end
	end
end

local _,p=find_plant(c)

p.grow_counter=p.grow_counter+1000000
printall(p)