local c=copyall(df.global.cursor)

function find_plant(  )
	for i,v in ipairs(df.global.world.plants.all) do
	if v.pos.x==c.x and v.pos.y==c.y and v.pos.z==c.z then
		print(i,v)
		return i,v
	end
end
end
function is_good_plant( p )
	local raw=df.global.world.raws.plants.all[p.material]
	--print("==============")
	--printall(raw)
	--print("==============")
	--printall(raw.material_defs)
	--print("==============")
	local matinfo=dfhack.matinfo.decode(raw.material_defs.type_basic_mat,raw.material_defs.idx_basic_mat)
	--printall(matinfo)
	if matinfo.material.flags.EDIBLE_RAW or matinfo.material.flags.EDIBLE_COOLED then
		return true
	end
end
local _,p=find_plant()
print(is_good_plant(p))
local d=dfhack.maps.getTileFlags(c)
d.dig=df.tile_dig_designation.Default
local b=dfhack.maps.getTileBlock(c)
b.flags.designated=true