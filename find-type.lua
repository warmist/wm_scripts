local args={...}

for k,v in pairs(df) do if string.find(k,args[1]) then print(k) end end