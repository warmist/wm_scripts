
function find_player_group(  )
	local a=df.global.world.armies.all
	for i,v in ipairs(a) do
		if v.flags.player then
			return i,v
		end
	end
end
local army_contents={
	--fill out this
	count=15,
	race=572,
	civ_id=246,
	population_id=229,
	cultural_identity=937,

	new=true,
	--- unknown stuff
	unk_10=-1,
	unk_18=-1,
	unk_1c=-1,
	unk_20=-1,
	unk_24=-1,
	unk_28=-1,
}
local _,pa=find_player_group()
if pa==nil then
	qerror("player army not found")
end
--df.global.army_next_id
local armies=df.global.world.armies.all
local army=df.army:new()
army.id=df.global.army_next_id
--trying to "trick" game into moving army into player square
--this should also work for migrants?
army.pos={x=pa.pos.x-1,y=pa.pos.y,z=0}
army.unk_pos_x:insert("#",pa.pos.x)
army.unk_pos_y:insert("#",pa.pos.y)
army.unk_2c:insert("#",army_contents)
--who knows?
army.unk_90=-1
army.unk_94=-1
army.unk_98=-1
army.unk_9c=100
army.anon_1=10000

armies:insert("#",army)
df.global.army_next_id=df.global.army_next_id+1
