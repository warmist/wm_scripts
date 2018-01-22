local map={[[
XXXXX
XZZZX
XZXZX
XZZZX
XXXXX
]],
[[
     
 YYY 
 Y Y 
 YYY 
     
]],
[[
     
 YYY 
 Y Y 
 YYY 
     
]],
[[
     
 YYY 
 Y Y 
 YYY 
     
]],
[[
     
 YYY 
 Y Y 
 YYY 
     
]]
}
local types={
    X={"MineralFloorSmooth","INORGANIC:SLADE","VEIN"},
    Z={"MineralPillar","INORGANIC:SLADE","VEIN"},
    Y={"MineralPillar","INORGANIC:GOLD","VEIN"},
    [" "]="OpenSpace"
}
function draw_tile(x,y,z,tiletype)
    --TODO: add auto connecting types
    local tt=df.tiletype[tiletype]
    local b=dfhack.maps.getTileBlock(x,y,z)
    b.tiletype[math.fmod(x,16)][math.fmod(y,16)]=tt
end

function findMineralEv(block,inorganic)
    for k,v in pairs(block.block_events) do
        if df.block_square_event_mineralst:is_instance(v) and v.inorganic_mat==inorganic then
            return v
        end
    end
end

function set_vein(x,y,z,mat)
    local b=dfhack.maps.getTileBlock(x,y,z)
    local ev=findMineralEv(b,mat.index)
    if ev==nil then
        ev=df.block_square_event_mineralst:new()
        ev.inorganic_mat=mat.index
        ev.flags.vein=true
        b.block_events:insert("#",ev)
    end
    dfhack.maps.setTileAssignment(ev.tile_bitmask,math.fmod(x,16),math.fmod(y,16),true)
end
function draw_slice(offset,slice,legend)
    
    local x=offset.x
    local y=offset.y
    for i=1,#slice do
        local b=slice:byte(i)
        local tile=legend[string.char(b)]
        local material
        
        
        if b~=10 then
            if type(tile)=="table" then
                material=tile[2]
                tile=tile[1]
            end
            if tile ~= nil then
                draw_tile(x,y,offset.z,tile)
                if material then
                    set_vein(x,y,offset.z,material)
                end
            end
            x=x+1
        else
            y=y+1
            x=offset.x
        end

    end
end
function draw_map(offset,input,legend)
    for i,v in pairs(legend) do
        if v[2] then
            local mat=dfhack.matinfo.find(v[2])
            if mat==nil then
                qerror("Not found material:"..tostring(v[2]))
            end
            v[2]=dfhack.matinfo.find(v[2])
        end
    end
    if type(input)=="table" then
        for i=1,#input do
            draw_slice({x=offset.x,y=offset.y,z=offset.z+i-1},input[i],legend)
        end
    else
        draw_slice(offset,input,legend)
    end
    
end
draw_map(copyall(df.global.cursor),map,types)