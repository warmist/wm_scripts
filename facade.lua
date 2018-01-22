local start=0
local structure={
    { type="uint32_t", offset=0},
    { type="uint32_t", offset=4},
    { type="uint32_t", offset=8},
    { type="uint32_t", offset=},
}
setmetatable(structure,{__index=function(t,k)
    if type(t[k])=="table" then
        return t[k]
    else
        return df.reinterpret_cast(t[k].type,start+t[k].offset)
end
    })
return s