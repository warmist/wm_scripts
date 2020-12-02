--assign jobs to companions/npcs in adventure mode
--[[
	* Try to be more general and have a list of jobs(??) and then dispatch them.
		That way we could reuse same code (or move to a lib) for e.g. zombie controling obelisks
	* Fix the "do detail wall over distance"
--]]

function smart_job_delete( job )
    local gref_types=df.general_ref_type
    --TODO: unmark items as in job
    for i,v in ipairs(job.general_refs) do
        if v:getType()==gref_types.BUILDING_HOLDER then
            local b=v:getBuilding()
            if b then
                --remove from building
                for i,v in ipairs(b.jobs) do
                    if v==job then
                        b.jobs:erase(i)
                        break
                    end
                end
            else
                print("Warning: building holder ref was invalid while deleting job")
            end
        elseif v:getType()==gref_types.UNIT_WORKER then
            local u=v:getUnit()
            if u then
                u.job.current_job =nil
            else
                print("Warning: unit worker ref was invalid while deleting job")
            end
        else
            print("Warning: failed to remove link from job with type:",gref_types[v:getType()])
        end
    end
    --unlink job
    local link=job.list_link
    if link.prev then
        link.prev.next=link.next
    end
    if link.next then
        link.next.prev=link.prev
    end
    link:delete()
    --finally delete the job
    job:delete()
end

function enum_workshops(  )
	local ret={}
	for i,v in ipairs(df.global.world.buildings.other[df.buildings_other_id.WORKSHOP_ANY]) do
		table.insert{ret,{v}}
	end
	return ret
	--todo: FURNACE_ANY?
end
function can_unit_work( u )
	local r=df.creature_raw.find(u.race)
	if r.flags.HAS_ANY_INTELLIGENT_LEARNS then
		return true
	end
end
function enum_companions(  )
	local adv=df.global.world.units.active[0]
    local t_nem=dfhack.units.getNemesis(adv)
    local ret={}
    for k,v in pairs(t_nem.companions) do
    	local u=df.nemesis_record.find(v).unit
    	if can_unit_work(u) then
    		table.insert(ret,{v,u})
    	end
    end
    return ret
end
function findAction(unit,ltype)
    ltype=ltype or df.unit_action_type.None
    for i,v in ipairs(unit.actions) do
        if v.type==ltype then
            return v
        end
    end
end
function add_action(unit,action_data)
    local action=findAction(unit) --find empty action
    if action then
        action:assign(action_data)
        action.id=unit.next_action_id
        unit.next_action_id=unit.next_action_id+1
    else
        local tbl=copyall(action_data)
        tbl.new=true
        tbl.id=unit.next_action_id
        unit.actions:insert("#",tbl)
        unit.next_action_id=unit.next_action_id+1
    end
end
function add_job_action(job,unit,trg_pos) --what about job2?
    if job==nil then
        error("invalid job")
    end
    if findAction(unit,df.unit_action_type.Job) or findAction(unit,df.unit_action_type.Job2) then
        print("Already has job action")
        return
    end
    local action=findAction(unit)
    --local pos=copyall(unit.pos)
    --local pos=copyall(job.pos)
    unit.path.dest:assign(trg_pos)
    --job
    local data={type=df.unit_action_type.Job,data={Job={x=trg_pos.x,y=trg_pos.y,z=trg_pos.z,timer=10}}}
    --job2:
    --local data={type=df.unit_action_type.Job2,data={job2={timer=10}}}
    add_action(unit,data)
    --add_action(unit,{type=df.unit_action_type.Unsteady,data={unsteady={timer=5}}})
end
function make_native_job(state)
    if state.job == nil then
        local newJob=df.job:new()
        newJob.id=df.global.job_next_id
        df.global.job_next_id=df.global.job_next_id+1
        newJob.flags.special=true
        newJob.job_type=state.job_type
        newJob.completion_timer=-1
        newJob.pos:assign(state.pos)
        state.job=newJob
        state.linked=false
    end
end
function assign_unit_to_job(job,unit,unit_pos)
    job.general_refs:insert("#",{new=df.general_ref_unit_workerst,unit_id=unit.id})
    unit.job.current_job=job
    --unit_pos=unit_pos or {x=job.pos.x,y=job.pos.y,z=job.pos.z}
    --unit.path.dest:assign(unit_pos)
    return true
end
function commit_job( state )
	local failed
	--TODO:pre-job calls
 	if failed==nil then
        assign_unit_to_job(state.job,state.unit,state.from_pos)
        if failed==nil then
            if not state.linked then
            	dfhack.job.linkIntoWorld(state.job,true)
        		add_job_action(state.job,state.unit,state.pos)
                state.linked=true
            end
        end
    end
end
local cursor=copyall(df.global.cursor)
local comps=enum_companions()
local u=comps[1][2]
local s={job_type=df.job_type.DetailFloor,pos=cursor,unit=u,from_pos=cursor}
make_native_job(s)
commit_job(s)
