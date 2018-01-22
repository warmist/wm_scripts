local m=df.global.world.map

for _,block in ipairs(m.map_blocks) do
    local targetType
    if block.map_pos.z==0 then
        targetType=df.tiletype.StoneWall
    elseif block.map_pos.z==1 then
        targetType=df.tiletype.StoneFloorSmooth
    else
        targetType=df.tiletype.OpenSpace
    end

    for _,tt in ipairs(block.tiletype) do
    for id,tile in ipairs(tt) do
        tt[id]=targetType
    end
    end
    for _,tt in ipairs(block.designation) do
    for id,tile in ipairs(tt) do
        tt[id].flow_size=0
        tt[id].hidden=false
        tt[id].outside=true
        tt[id].subterranean=false
        tt[id].light=true
    end
    end
end
for _,u in ipairs(df.global.world.units.active) do
    if _~=0 then
        u.flags1.dead=true
    end
end