local a=df.global.world.armies.all
local trg_id=8142
--local trg_a=a[trg_id]

function find_player_group(  )
	local x=0
	local tt={}
	for i,v in ipairs(a) do
		--[[if #v.members==0 then
			printall(v)
			x=x+1
			print("========================")
		end
		if x>10 then
			return
		end]]
		if v.controller then
			--print(v.controller.type)
			if v.controller.type==12 then
				printall(v.controller.unk_64.t12)
			end
			tt[v.controller.type]=tt[v.controller.type] or 0
			tt[v.controller.type]=tt[v.controller.type]+1
		end
		--if v.flags.player then
			--return i,v
		--end
	end
	for k,v in pairs(tt) do
		print(k,v)
	end
end

local id,pl=find_player_group()
print("player:",id)
--[[if id==trg_id then
	return
end
trg_a.unk_pos_x:insert("#",pl.pos.x)
trg_a.unk_pos_y:insert("#",pl.pos.y)]]
