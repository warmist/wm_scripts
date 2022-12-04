--@module = true
local overlay = require('plugins.overlay')
local widgets = require('gui.widgets')
local dialog = require 'gui.dialogs'

local target_info
DeathRadarWidget = defclass(DeathRadarWidget, overlay.OverlayWidget)
DeathRadarWidget.ATTRS{
    viewscreens={'dungeonmode'},
    overlay_onupdate_max_freq_seconds=10,
    frame={w=10,h=10},
    long_dist=true,
}

function is_site_loaded( id )
    for i,v in ipairs(df.global.world.world_data.active_site) do
        if v.id==id then
            return true
        end
    end
end
function find_local_corpse( hist_id )
    for i,v in ipairs(df.global.world.items.other[CORPSE]) do
        if v.hist_figure_id==hist_id then
            return v,i
        end
    end
end
function DeathRadarWidget:update_target_info( trg )
    local whereabouts=trg.figure.info.whereabouts
    printall(whereabouts)
    local location={}
    self.location=location

    location.gpos={whereabouts.pos_x,whereabouts.pos_y}
    location.site=whereabouts.site
end
function DeathRadarWidget:overlay_onupdate()
    if target_info~=self.target then
        self.target=target_info
        update_target_info(self.target)
    end
    local source={}
    self.source=source
    if df.global.ui_advmode.menu==df.ui_advmode_menu.Travel
        and not df.global.ui_advmode.travel_not_moved then
        --we are traveling?
        long_dist=true
        local army_id=df.global.ui_advmode.player_army_id
        local army=df.army.find(army_id)
        source.gpos=copyall(army.pos)
    elseif df.global.ui_advmode.menu==df.ui_advmode_menu.Travel then

    else
        --non traveling
        if is_site_loaded(self.location.site) then
            --target is in the same site?
            long_dist=false
            local corpse_item=find_local_corpse(self.target.figure.id)
            if corpse_item==nil then
                self.local_pos={-1,-1,-1}
            else
                self.local_pos=copyall(corpse_item.pos)
            end
        else
            long_dist=true
            --non-same site
        end
    end
end

function DeathRadarWidget:onRenderFrame(dc)
    print("Hello")
    dc:string("Hello world!")
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