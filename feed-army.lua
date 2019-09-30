
local a=df.global.world.armies.all
for i,v in ipairs(a) do
	if v.flags.player then
		for i,v in ipairs(v.members) do
			v.hunger_timer=0
			v.thirst_timer=0
			v.sleepiness_timer=0
		end
		return
	end
end
