local wc=df.global.world.written_contents.all
local function alloc_wc_id()
    local ret=df.global.written_content_next_id
    df.global.written_content_next_id=df.global.written_content_next_id+1
    return ret
end
local function create_wc(hist_events)
    local ret=df.written_content:new()
    df.global.world.written_contents.all:insert("#",ret)
    for k,v in ipairs(hist_events) do
        ret.refs:insert("#",{new=df.general_ref_historical_eventst,event_id=v.id})
        ret.ref_aux:insert("#",0)
    end
    ret.styles:insert("#",0)
    ret.style_strength:insert("#",0)
    ret.id=alloc_wc_id() --on fail will not execute and mess up the ids
    return ret
end
local  function create_improvement( trg_item )
    local impr = df.itemimprovement_pagesst:new()
    trg_item.improvements:insert("#",impr)
    return impr
end
local function filter_events_entity(id)
    local ret={}
    for k,v in ipairs(df.global.world.history.events) do
        if v:isRelatedToHistfigID(id) then
            table.insert(ret,v);
            
        end
    end
    return ret
end
--[=[ other vmethods:
    virtual bool isRelatedToHistfigID(int32_t) { return bool(); /*17*/ };
    virtual bool isRelatedToSiteID(int32_t) { return bool(); /*18*/ };
    virtual bool isRelatedToSiteStructure(int32_t, int32_t) { return bool(); /*19*/ };
    virtual bool isRelatedToArtifactID(int32_t) { return bool(); /*20*/ };
    virtual bool isRelatedToRegionID(int32_t) { return bool(); /*21*/ };
    virtual bool isRelatedToLayerID(int32_t) { return bool(); /*22*/ };
    virtual bool isRelatedToEntityID(int32_t) { return bool(); /*24*/ };
]=]
local function fill_book( item ,fig_id)
    local impr= create_improvement(item)
    impr.count=math.random(1,100) -- meh...
    local events=filter_events_entity(fig_id)
    local wc=create_wc(events)
    impr.contents:insert("#",wc.id)
end

local book=dfhack.gui.getSelectedItem()
if book:getType()~= df.item_type.BOOK then
    qerror("Invalid item selected")
end
fill_book(book,0)