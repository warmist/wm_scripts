ITEM = defclass(ITEM)
function ITEM:__index(key)
	if rawget(self,key) then return rawget(self,key) end
	if rawget(ITEM,key) then return rawget(ITEM,key) end
	local item = df.item.find(self.id)
	return item[key]
end
function ITEM:init(item)
	--??
	if tonumber(item) then item = df.item.find(tonumber(item)) end
	self.id = item.id
end

function ITEM:getRandomAttack()
	local item = df.item.find(self.id)
	local rand = dfhack.random.new()
	local weights = {}
	weights[0] = 0
	local n = 0
	for _,attacks in pairs(item.subtype.attacks) do
		if attacks.edged then x = 100 else x = 1 end
		n = n + 1
		weights[n] = weights[n-1] + x
	end
	local pick = rand:random(weights[n])
	for i = 1,n do
		if pick >= weights[i-1] and pick < weights[i] then attack = i-1 break end
	end
	if not attack then attack = n end
	return item.subtype.attacks[attack]
end

local it=ITEM(0)
printall(it:getRandomAttack())