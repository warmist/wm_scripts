--[[
for i,v in ipairs(df.global.world.world_data.sites) do
 	if dfhack.TranslateName(v.name,true)=='Columnbarb' then
 		print(i,v.id)
 		printall(v.pos)
 		return
 	end
end
if true then return end
--]]
local a=df.global.world.armies.all
--[[for i,v in ipairs(a) do
	if v.controller and v.controller.type==12 then
		print(i)
		printall(v.controller.unk_64.t12)
	end
end
]]
function find_player_group(  )
	for i,v in ipairs(a) do
		if v.flags.player then
			return i,v
		end
	end
end
local args={...}
local id,pa=find_player_group()
local myset={[-1]=true,[2]=true,[7]=true,[3]=true,[1]=true,[8]=true}
local no=0
for i,v in ipairs(a) do
	if v.controller and v.controller.type==tonumber(args[1]) then
		print(no,i)
		--if no==tonumber(args[2]) then
		if myset[v.controller.unk_64.t12.anon_7]==nil then
			printall(v)
			print("===========",v.pos.x,v.pos.y)
			printall(v.controller)
			print("===========")
			printall(v.controller.unk_64.t12)

			--NOTE: tp to pos
			--pa.pos={x=v.pos.x,y=v.pos.y,z=v.pos.z}
			--NOTE: tp to target
			pa.pos={x=v.controller.pos_y,y=v.controller.unk_14}


			--[[print("===========")
			print("===========")
			printall(v.unk_70)
			print("===========")
			printall(v.unk_80)]]
			
			return
		end
		no=no+1
	end
end

--1 looked like a patrol? (friendly)
--2 army?
--3 ??? none
--4 (lots) refugees (said was escaping home)? (elf ringleeder) (camp)
--5 (3) invading army? (was goblins) (camp)
--6 (lots) single unit enemies (zombie polar bear, yeti,...)
--7 (29) single crossgoblinman, golbin party (x3 at goblin pits?)
--8 (0)
--9 (0)
--10 (0)
--11 (0)
--12 (384) tribute? returning home, (bowelf,bard) going somewhere in search of work,

--[[
3: 0
7: 3 
8: 54

islandazure
]]
--[[ ropejade
anon_1                   = -1
anon_2                   = -1
anon_3                   = 0
anon_4                   = <vector<army_controller_sub12.T_anon_4*>[0]: 00000294CCB3D640>
anon_5                   = -1
anon_6                   = -1
anon_7                   = 13
anon_8                   = 54 (reason?) (or -1)

id                       = 2031003
entity_id                = -1
site_id                  = 200
pos_x                    = -1
pos_y                    = 406
unk_14                   = 5734
]]

--[[
anon_7: -1 returning home
2,7,3: search of adventure
8 (adventure and drink?)
13,1: search of work

]]