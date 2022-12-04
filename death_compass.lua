local overlay = require('plugins.overlay')
local widgets = require('gui.widgets')
local dialog = require 'gui.dialogs'

DeathRadarWidget = defclass(DeathRadarWidget, overlay.OverlayWidget)
DeathRadarWidget.ATTRS{
    viewscreens={'dungeonmode'},
    overlay_onupdate_max_freq_seconds=10,
    frame={w=10,h=10},
    long_dist=true,
}

function DeathRadarWidget:overlay_onupdate()

    if df.global.ui_advmode.menu==df.ui_advmode_menu.Travel then
        --we are traveling?
        --TODO: this is not enough to check if traveling
        long_dist=true
        local army_id=df.global.ui_advmode.player_army_id
        local army=df.army.find(army_id)
    else
        --non traveling
        
        --target is in the same site?
        --non-same site
    end
end

function DeathRadarWidget:onRenderFrame(dc)
    dc:string("Hello world!")
    for _,pos in ipairs(self.visible_artifacts_coords or {}) do
        -- highlight tile at given coordinates
    end
end

OVERLAY_WIDGETS = {radar=DeathRadarWidget}
--TODO add a choice?
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
--title, text, tcolor, choices, on_select, on_cancel, min_width, filter
dialog.showListPrompt("Choose adventurer","Select adventurer to find",nil,choice_list,function (entry)
    DeathRadarWidget{target=entry.nem}
end)

-- region: {333,152,-13}
--army pos: {1006,460,0}
--[[    site
    region: 14-18 x 8-10 x -13x144
    global: 334-335 x 152-154
    pos: 20 x 9
--]]