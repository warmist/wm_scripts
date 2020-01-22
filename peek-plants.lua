local function find_plant( p )
	local ps=df.global.world.plants.all
	for i,v in ipairs(ps) do
		if v.pos.x==p.x and v.pos.y==p.y and v.pos.z==p.z then
			return i,v
		end
	end
end
function peek_gathering(  )
	print("=-=-=-=-=-=-=-=-=-")
	for i,v in ipairs(df.global.world.units.active) do
		local jb=v.job.current_job
		if  jb and jb.job_type==df.job_type.GatherPlants then
			local _,pp
			if jb.completion_timer~=-1 then
				_,pp=find_plant(v.pos)
			end
			print(i,"===========",dfhack.TranslateName(v.name),"ct:",jb.completion_timer,pp)
			if jb.completion_timer>2 then
				jb.completion_timer=2
			end
		end
	end
	peeker=dfhack.timeout(1,'ticks',peek_gathering)
end

args={...}

if peeker and args[1]=="off" then
	dfhack.timeout_active(peeker,nil)
	peeker=nil
else
	dfhack.timeout_active(peeker,nil)
	peeker=dfhack.timeout(1,'ticks',peek_gathering)
end