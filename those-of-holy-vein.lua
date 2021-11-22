--[[
	Random idea #1773: those of the holy vein:
	Your dwarves start with a vein of <some special holy material>. Any dwarf that gets too far from it, dies (not necessarily immediately). However there would be some arcane rituals that can be done to propagate the vein. 
	Mod1: vein grows itself randomly, thus the fort must grow with it
	Mod2: vein only grows in obsidian (not sure how to get started though.... maybe obsidian walls are ok too?)
	Bonus points (aka power goal): dwarves are birthed from the "clusters" that sometimes are embedded in the vein

	Implementation thoughts:
		* due to complexity of checking world it might be better to be c++
		* for now i'll just randomly pick some unit ids to check every N ticks
	It has these parts:
		* misc stuff (id lookup etc...)
		* the unit checker: checking if unit has wall/floor/ceiling of specific material
		* the vein grower
		* the unit spawner
		* vein control logic (i.e. how dwarves influence the vein)
--]]

config={
	material_name="LIFEVEIN",
	node_material_name="LIFENODULE",
	race_id="DWARF",
	max_num_unit_checked=10,
}
config_refs={}
function find_config_ids()
	--TODO: better errors (i.e more exact)
	local done=0
	for k,v in ipairs(df.global.world.raws.inorganics) do
		if v.id==config.material_name then
			config_refs.mat_id=k
			config_refs.mat=v
			done=done+1
		elseif v.id==config.node_material_name then
			config_refs.node_id=k
			config_refs.node=v
			done=done+1
		end
		if done==2 then
			break
		end
	end
	if done~=2 then
		qerror("Could not find one of (or both) material and node_material in raws")
	end
	for k,v in ipairs(df.global.world.raws.creatures.all) do
		if v.creature_id==config.race_id then
			config_refs.race_id=k
			config_refs.race=v
			break
		end
	end
	if config_refs.race==nil then
		qerror("Could not find race in raws")
	end
end
find_config_ids()


local attrs=df.tiletype.attrs

function findMineralEv(block,inorganic)
    for k,v in pairs(block.block_events) do
        if df.block_square_event_mineralst:is_instance(v) and v.inorganic_mat==inorganic then
            return v
        end
    end
end
function query_materials_around( unit_id,material_id1,material_name_id2 )
	--TODO: @PERF could cache all the vein locations into some sort of spacial lookup.
	-- could lookup more tiles
	-- could do something block based (i.e. group) and/or not worry about the exact positions
	--NOTE: this is for vein material only. all other things are probably way easier to lookup
	--local pos=copyall(df.global.cursor)

	local u=df.unit.find(unit_id)
	local pos=u.pos

	local dx={ 0, 0,-1, 0, 1,-1, 0, 1,-1, 0, 1}
	local dy={ 0, 0, 1, 1, 1,-1,-1,-1, 0, 0, 0}
	local dz={-1, 1}
	for i=1,#dx do
		local x=pos.x+dx[i]
		local y=pos.y+dy[i]
		local z=pos.z+(dz[i] or 0)

		local tile_type=dfhack.maps.getTileType(x,y,z)
		if attrs[tile_type].material==df.tiletype_material.MINERAL then
			--print("VEIN:",x,y,z)
			local tile_block=dfhack.maps.getTileBlock(x,y,z)
			if tile_block then --TODO: can this actually fail?
				--TODO: @PERF theses two lookups can be merged and then mask could be looked up'ed smarter?
				local mat_ev1=findMineralEv(tile_block,material_id1)
				local mat_ev2=findMineralEv(tile_block,material_id2)
				--print("Events:",mat_ev1,mat_ev2)
				if (mat_ev1 and dfhack.maps.getTileAssignment(mat_ev1.tile_bitmask,math.fmod(x,16),math.fmod(y,16))) or
				   (mat_ev2 and dfhack.maps.getTileAssignment(mat_ev2.tile_bitmask,math.fmod(x,16),math.fmod(y,16))) then
				   	return true
				end
			end
		end
	end
	return false
end

function set_vein(x,y,z,mat)
	--TODO: @PERF setting each per tile is slow because we do all those checks...

    local b=dfhack.maps.getTileBlock(x,y,z)
    local ev=findMineralEv(b,mat)
    if ev==nil then
        ev=df.block_square_event_mineralst:new()
        ev.inorganic_mat=mat
        ev.flags.vein=true
        b.block_events:insert("#",ev)
    end
    dfhack.maps.setTileAssignment(ev.tile_bitmask,math.fmod(x,16),math.fmod(y,16),true)
end

--Idea is that we convert one tiletype (e.g. soil or lava_stone or etc...) to mineral
function find_closest_mineral( tt )
	local ta=attrs[tt]
	for i,v in ipairs(df.tiletype) do
		if v and attrs[v].material==df.tiletype_material.MINERAL then
			local trg_ta=attrs[v]
			if ta.shape==trg_ta.shape and
			   ta.variant==trg_ta.variant and
			   ta.special==trg_ta.special and
			   ta.direction==trg_ta.direction then
			   	return v
			end
		end
	end
end
function generate_conversion_table()
	--TODO: add builtin table (or dont?)
	local ret={}
	local allowed_materials={
		[df.tiletype_material.SOIL]=true, --not sure, but maybe for outside forts?
		[df.tiletype_material.STONE]=true,
		[df.tiletype_material.LAVA_STONE]=true,
		--[df.tiletype_material.FROZEN_LIQUID]=true, not sure bout this one.... seems out of place
		--[df.tiletype_material.HFS]=true, --maybe?
		--[df.tiletype_material.PLANT]=true, --need more logic, too lazy
		--[df.tiletype_material.CONSTRUCTION]=true, --would be fun... needs more logic
	}
	--TODO: soil needs special handling afaik
	for i,v in ipairs(df.tiletype) do
		if v and allowed_materials[attrs[v].material] then
			--print(v,attrs[v].caption)
			ret[v]=find_closest_mineral(v)
		end
	end
	return ret
end
conversion_table=conversion_table or generate_conversion_table()

function convert_tile_to_mat(x,y,z,mat)
	local tt=df.tiletype
	local tile_type=dfhack.maps.getTileType(x,y,z)
	if attrs[tile_type].material==df.tiletype_material.MINERAL then
		--TODO: find all other veins and unset the value
		print("TODO")
	elseif conversion_table[tile_type] then
		set_vein(x,y,z,mat)
		local b=dfhack.maps.getTileBlock(x,y,z)
		b.tiletype[math.fmod(x,16)][math.fmod(y,16)]=conversion_table[tile_type]
		--print("Setting tiletype")
		return true
	else
		--not handled
		--printall(attrs[tile_type])
		--KNOWN: soil: i would want to handle that but needs more work
	end

end

vein_state=vein_state or  {heads={}}

function vein_state_tick(  )
	--TODO: limit propagation to "solid" shape?
	local steps_per_tick=3
	if #vein_state.heads==0 then
		table.insert(vein_state.heads,{pos=copyall(df.global.cursor)})
		--add new head somewhere TODO
	end

	local cur_head=vein_state.heads[math.random(1,#vein_state.heads)]
	for i=1,steps_per_tick do
		local trg=copyall(cur_head.pos)
		local dx={ 0, 0,-1, 0, 1,-1, 0, 1,-1, 1}
		local dy={ 0, 0, 1, 1, 1,-1,-1,-1, 0, 0}
		local dz={-1, 1}
		local rpos=math.random(1,#dx)
		trg.x=trg.x+dx[rpos]
		trg.y=trg.y+dy[rpos]
		trg.z=trg.z+(dz[rpos] or 0)
		
		if convert_tile_to_mat(trg.x,trg.y,trg.z,config_refs.mat_id) then
			cur_head.pos=trg
		end
		--TODO: too many fails remove, what happens on other minerals
		-- maybe add some width variation
	end
end
vein_state_tick()
--[[
for x=-10,10 do
	for y=-10,10 do
		convert_tile_to_mat(df.global.cursor.x+x,df.global.cursor.y+y,df.global.cursor.z,config_refs.mat_id)
	end
end
--]]

--[[
for k,v in pairs(conversion_table) do
	print(df.tiletype[k],df.tiletype[v])
end
--]]