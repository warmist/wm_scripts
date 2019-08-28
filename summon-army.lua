
function find_player_group(  )
	local a=df.global.world.armies.all
	for i,v in ipairs(a) do
		if v.flags.player then
			return i,v
		end
	end
end

local _,pa=find_player_group()
if pa==nil then
	qerror("player army not found")
end
local nr=df.nemesis_record.find(pa.members[0].nemesis_id)
local pfig=nr.figure

local army_contents={
	count=15,
	race=pfig.race,
	civ_id=pfig.civ_id,
	population_id=pfig.population_id,
	cultural_identity=pfig.cultural_identity,

	new=true,
	--- unknown stuff
	unk_10=-1,
	unk_18=-1,
	unk_1c=-1,
	unk_20=-1,
	unk_24=-1,
	unk_28=-1,
}

local armies=df.global.world.armies.all
local army={
	new=true,
	id=df.global.army_next_id,
--trying to "trick" game into moving army into player square
--this should also work for migrants?
	pos={x=pa.pos.x-1,y=pa.pos.y,z=0},
	unk_pos_x={pa.pos.x},
	unk_pos_y={pa.pos.y},
	unk_2c=army_contents,
--who knows?
unk_90=-1,
unk_94=-1,
unk_98=-1,
unk_9c=100,
anon_1=10000,
}
armies:insert("#",army)
df.global.army_next_id=df.global.army_next_id+1
