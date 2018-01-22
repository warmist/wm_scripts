local u=dfhack.gui.getSelectedUnit()
local state={}
function compare()
	if state.id~=u.next_action_id then
		state.id=u.next_action_id
		print("New id:",state.id)
		
		if #u.actions then
			printall(u.actions[0])
		end
	end
	if not u.flags1.dead then
		dfhack.timeout(1,'ticks',compare)
	end
end
dfhack.timeout(1,'ticks',compare)