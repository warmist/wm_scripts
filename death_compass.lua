--@module = true
local overlay = require('plugins.overlay')
local widgets = require('gui.widgets')
local dialog = require 'gui.dialogs'

local target_info
DeathRadarWidget = defclass(DeathRadarWidget, overlay.OverlayWidget)
DeathRadarWidget.ATTRS{
    viewscreens={'dungeonmode'},
    overlay_onupdate_max_freq_seconds=10,
    frame={w=3,h=3},
    long_dist=true,

}
--[=[
    General todo:
        * what todo when corpse is not found?
        * region coords are bit finicky and maybe the compass should be more "fluid"
        * how to quickly "complete" and remove the compass?
--]=]
function is_site_loaded( id )
    for i,v in ipairs(df.global.world.world_data.active_site) do
        if v.id==id then
            return true
        end
    end
end
function find_local_corpse( hist_id )
    for i,v in ipairs(df.global.world.items.other.CORPSE) do
        if v.hist_figure_id==hist_id and v.flags.on_ground then
            return v,i
        end
    end
end
function DeathRadarWidget:update_target_info( trg )
    local whereabouts=trg.figure.info.whereabouts

    self.global_pos={x=whereabouts.pos_x,y=whereabouts.pos_y}
    self.site=whereabouts.site
end
function DeathRadarWidget:overlay_onupdate()
    if target_info~=self.target then
        self.target=target_info
    end
    self.local_pos=nil
    self.global_pos=nil

    if self.target==nil then
        return
    end

    self:update_target_info(self.target)
    if df.global.ui_advmode.menu==df.ui_advmode_menu.Travel
        and not df.global.ui_advmode.travel_not_moved then
        --we are traveling?

    else
        --non traveling
        if is_site_loaded(self.location.site) then
            --target is in the same site?
            local corpse_item=find_local_corpse(self.target.figure.id)
            if corpse_item==nil then
                --TODO: this bugs stuff out (e.g. picking up the corpse)
                self.local_pos=nil
            else
                self.local_pos=copyall(corpse_item.pos)
            end
        else
            --non-same site
            self.local_pos=nil
        end
    end
end

function get_adv_pos( )
    local adv=df.global.world.units.active[0]
    return copyall(adv.pos)
end
function get_adv_pos_region(  )
    return {x=df.global.world.map.region_x*3,y=df.global.world.map.region_y*3,z=df.global.world.map.region_z}
end
function calc_delta_pos(pos,trg)
    local dx
    local dy
    local dz

    if pos.x>trg.x then
        dx=-1
    elseif pos.x<trg.x then
        dx=1
    else
        dx=0
    end

    if pos.y>trg.y then
        dy=-1
    elseif pos.y<trg.y then
        dy=1
    else
        dy=0
    end
    if trg.z then
        if pos.z>trg.z then
            dz='>'
        elseif pos.z<trg.z then
            dz='<'
        else
            dz='O'
        end
    else
        dz='O'
    end

    return dx,dy,dz
end
function DeathRadarWidget:onRenderBody(dc)
    local dx
    local dy
    local dz
    local p
    if self.local_pos==nil and self.global_pos==nil then
        dc:seek(1,1):string("?")
        return
    end
    if df.global.ui_advmode.menu==df.ui_advmode_menu.Travel then
        if self.local_pos then
            dc:seek(1,1):string('L')
            return
        end
        if not df.global.ui_advmode.travel_not_moved then
            local army_id=df.global.ui_advmode.player_army_id
            local army=df.army.find(army_id)
            p=copyall(army.pos)
            dx,dy,dz=calc_delta_pos(p,self.global_pos)
        else
            p=get_adv_pos_region()
            dx,dy,dz=calc_delta_pos(p,self.global_pos)
        end
    else
        if self.local_pos==nil then
            --TODO need better coord here... something is fishy
            p=get_adv_pos_region()
            dx,dy,dz=calc_delta_pos(p,self.global_pos)
        else
            p=get_adv_pos()
            dx,dy,dz=calc_delta_pos(p,self.local_pos)
        end
    end


    dc:seek(1,1):string(dz)
    if dx then
        dc:seek(dx+1,dy+1):string('*')
    end
end

OVERLAY_WIDGETS = {radar=DeathRadarWidget}

if dfhack_flags.module then
    return
end

function get_last_dead_adv()
    local ret={}
    local nm=df.global.world.nemesis.all
    for i=#nm-1,0,-1 do
        local v=nm[i]
        if v.flags.ADVENTURER and v.figure.died_year~=-1 then
            --print(i)
            --printall(v.figure)
            --printall(v.figure.info.whereabouts)
            table.insert(ret,v)
            --return v,i
        end
    end
    return ret
end
function nice_print_nemesis(i, nem )
    local cur_year=dfhack.world.ReadCurrentYear()
    local cur_tick=dfhack.world.ReadCurrentTick()

    local died_year=nem.figure.died_year
    local died_tick=nem.figure.died_seconds

    local died_ago_days=math.floor((cur_year-died_year)*12*28+(cur_tick-died_tick)/1200)
    local name=dfhack.TranslateName(nem.figure.name)

    return string.format("%d. %s (%d):died %d day(s) ago",i,name,nem.id,died_ago_days)
end



local choice_list={}
local all_dead_adv=get_last_dead_adv()
for i,v in ipairs(all_dead_adv) do
    table.insert(choice_list,{text=nice_print_nemesis(i,v),nem=v})
end

dialog.showListPrompt("Choose adventurer","Select adventurer to find",nil,choice_list,function (id,entry)
    target_info=entry.nem
end)

-- region: {333,152,-13}
--army pos: {1006,460,0}
--[[    site
    region: 14-18 x 8-10 x -13x144
    global: 334-335 x 152-154
    pos: 20 x 9
--]]