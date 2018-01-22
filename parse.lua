--[[
another idea:
    define what tokens create new items (e.g. ITEM, CREATURE, etc...)
    and then parse into objects
]]
function tokenize(path)
    local f = io.open(path)
    local str=f:read("*a")
    local tokens={}
    for t in str:gmatch("%[([^%]]+)%]") do
       table.insert(tokens,t)
    end
    return tokens
end
function split_objects(tokens,object_type)
    local ret={}
    local cur_entry
    for _,v in ipairs(tokens) do
        local capture=v:match(object_type..":(.+)")
        if capture then
            ret[capture]={}
            cur_entry=ret[capture]
        elseif cur_entry then
            table.insert(cur_entry,v)
        end
    end
    return ret
end
function get_tiles(obj,token)
    local ret={}
    for k,v in pairs(obj) do
        if v:find(token) then
            for q_char,tile in v:gmatch(":('?)([^:']+)'?") do
                if q_char=="'" and tile then
                    table.insert(ret,string.byte(tile,1))
                elseif tile then
                    table.insert(ret,tonumber(tile))
                end
            end
            return ret
        end
    end
end
local obj_defs={
    PLANT={"PLANT","GRASS_TILES"},
    ITEM_TOOL={"ITEM[^:]*","TILE"},
    INORGANIC={"INORGANIC","TILE"},
}
local T=split_objects(tokenize(dfhack.getDFPath().."/raw/objects/plant_grasses.txt"),"OBJECT") -- could just dump all the stuff in one file, graphics packs ahoy
printall(T)
for obj_type,tokens in pairs(T) do
    for k,v in pairs(split_objects(tokens,obj_defs[obj_type][1])) do
        local t=get_tiles(v,obj_defs[obj_type][2])
        print("===",k,"===")
        printall(t)
    end        
end
