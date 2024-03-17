local utils=require 'utils'
c=copyall(df.global.cursor)
function get_tree_block( pos )
	local block_x=math.floor(math.floor(pos.x/16)/3)
	local block_y=math.floor(math.floor(pos.y/16)/3)
	local map=df.global.world.map
	local col=map.map_block_columns[block_x+block_y*map.x_count_block]
	return col
end
function getPlant(pos)
	local c=get_tree_block(pos)
	--local arr=df.global.world.plants.all
	local arr=c.plants
	for k,v in pairs(arr) do
		if v.pos.x==pos.x and v.pos.y==pos.y and pos.z==v.pos.z then
			print(k)
			return v
		end
	end
end
function pos_compare(other,p1)
    if (p1.x ~= other.x) then return (p1.x - other.x) end
    if (p1.y ~= other.y) then return (p1.y - other.y) end
    return p1.z - other.z;
end

function plant_tree(pos,type,grown)
	--todo check tiletype

	local block=dfhack.maps.getTileBlock(pos)
	local col=get_tree_block(pos)
	local x=math.fmod(pos.x,16)
	local y=math.fmod(pos.y,16)
	block.tiletype[x][y]=df.tiletype.Sapling
	
	local plant=df.plant:new()
	plant.material=type
	plant.pos=pos
	plant.hitpoints=400000
	if grown then
		plant.grow_counter=500000
	end
	local plants=df.global.world.plants
	utils.insert_sorted(plants.all,plant,"pos",pos_compare)
	utils.insert_sorted(plants.tree_dry,plant,"pos",pos_compare)
	
	utils.insert_sorted(col.plants,plant,"pos",pos_compare)
end
function find_tree( name )
	local full_cap=string.upper(name)
	--todo partial match okay too?
	local plants=df.global.world.raws.plants
	for k,v in ipairs(plants.trees) do
		if v.id==full_cap then
			return plants.trees_idx[k] --anon_1 is prob id but this does not need df-structure update/research :P
		end
	end
end
--getPlant(c)
local args={...}
local tree_type=find_tree(args[1])
if tree_type==nil then
	qerror("Tree type not found")
end
plant_tree(c,tree_type,args[2]=="grown")
