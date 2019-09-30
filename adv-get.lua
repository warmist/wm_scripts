--An advanced get window inspired by "Cataclysm: Dark days ahead"
--[[
	TODO:
		* figure out "blocked tiles"
		* better "tile name print"
		* make keys not be CUSTOM_
]]
local gui = require 'gui'
local dlg = require 'gui.dialogs'
local widgets = require 'gui.widgets'
local tile_attrs=df.tiletype.attrs

local args={...}
--local cursor=xyz2pos(df.global.cursor.x,df.global.cursor.y,df.global.cursor.z)
local target_pos=copyall(df.global.world.units.active[0].pos)
function get_player_backpack(  )
	local adv=df.global.world.units.active[0]
	for i,v in ipairs(adv.inventory) do
		if df.item_backpackst:is_instance(v.item) then
			return v.item
		end
	end
end
local FIX_IS_APPLIED=false
multikey_table=defclass(multikey_table)
--[[
	TODO:
		* weak-ref keys
		* maybe make index work?
		* companion inventory transfers
		* pressing blocked (red) swap selections
]]
function multikey_table:init( args )
	self.data={}
	self.keys={}
end
function multikey_table:set(value, ... )
	local k=self.keys
	for _, v in ipairs{...} do
		if k[v] then
			k=k[v]
		else
			k[v]={}
			k=k[v]
		end
	end
	self.data[k]=value
end
function multikey_table:get( ... )
	local k=self.keys
	for _, v in ipairs{...} do
		if k[v] then
			k=k[v]
		else
			return nil
		end
	end
	return self.data[k]
end

SplitView=defclass(SplitView,gui.View)
function SplitView:init(args)
    self:addviews(args.subviews)
end
function SplitView:updateSubviewLayout(frame_body)
	if #self.subviews==0 then
		return
	end
	local sub_w=math.floor(frame_body.width/#self.subviews)
    for i,child in ipairs(self.subviews) do
        child:updateLayout(frame_body:viewport((i-1)*sub_w,0,sub_w,frame_body.height))
    end
end

--[[
	Dragged: i.e. minecart
	Container: (which one? there could be many per tile)
	Inventory: (probably backpack but could be other "worn" containers)
	Worn
	Area
	Numbers
]]

LocationButtons=defclass(LocationButtons,widgets.Widget)
LocationButtons.ATTRS{
	current_loc="C",
	blocked_loc="",
	on_loc_change=DEFAULT_NIL,
}
function LocationButtons:get_token( id )
	local labels={"bottom","center","top"}
	for i,v in ipairs(labels) do
		local tok=self.subviews[v]:itemById(id)
		if tok then return tok end
	end
end
function LocationButtons:update_keys()
	--local buttons={{"NW","N","NE"},{"W","C","E"},{"SW","S","SE"}}
	for n,l in ipairs(self.subviews) do
		for id,token in pairs(l.text_ids) do
			if id==self.current_loc then
				token.key_pen=COLOR_LIGHTBLUE
			elseif id~=self.blocked_loc then
				token.key_pen=COLOR_LIGHTGREEN
			end
		end
	end
end
function LocationButtons:enable( value )
	for _,l in ipairs(self.subviews) do
		l.enabled=value
	end
end
function LocationButtons:key_press( k )
	self.current_loc=k
	self:update_keys()
	if self.on_loc_change then
		self:on_loc_change()
	end
end
function LocationButtons:set_blocked( new_block )
	if self.blocked_loc~="" then
		local tkn=self:get_token(self.blocked_loc)
		tkn.enabled=true
		tkn.key_pen=COLOR_LIGHTGREEN
	end
	self.blocked_loc=new_block
	if new_block~="" then
		local tkn=self:get_token(self.blocked_loc)
		tkn.enabled=false
		tkn.key_pen=COLOR_LIGHTRED
	end
end
function LocationButtons:init( args )
	self:addviews{
		widgets.Label{view_id="bottom",frame = { t=0,l=0}, text={
			{key_sep='()',key="CUSTOM_B",id="B",on_activate=self:callback("key_press","B")},
			{key_sep='()',key="A_MOVE_NW",id="NW",on_activate=self:callback("key_press","NW")},
			{key_sep='()',key="A_MOVE_N",id="N",on_activate=self:callback("key_press","N")},
			{key_sep='()',key="A_MOVE_NE",id="NE",on_activate=self:callback("key_press","NE")}
		} },
		widgets.Label{view_id="center",frame = { t=1,l=0}, text={
			{key_sep='()',key="CUSTOM_A",id="A",on_activate=self:callback("key_press","A")},
			{key_sep='()',key="A_MOVE_W",id="W",on_activate=self:callback("key_press","W")},
			{key_sep='()',key="A_MOVE_SAME_SQUARE",id="C",on_activate=self:callback("key_press","C")},
			{key_sep='()',key="A_MOVE_E",id="E",on_activate=self:callback("key_press","E")}
		} },
		widgets.Label{view_id="top",frame = { t=2,l=4}, text={
			{key_sep='()',key="A_MOVE_SW",id="SW",on_activate=self:callback("key_press","SW")},
			{key_sep='()',key="A_MOVE_S",id="S",on_activate=self:callback("key_press","S")},
			{key_sep='()',key="A_MOVE_SE",id="SE",on_activate=self:callback("key_press","SE")}
		} },
	}
	self:update_keys()
end
local LOC_dx={
			S=0,N=0,C=0,
			W=-1,NW=-1,SW=-1,
			E=1,NE=1,SE=1,
		}
local LOC_dy={
	W=0,E=0,C=0,
	N=-1,NW=-1,NE=-1,
	S=1,SW=1,SE=1,
}
ItemColumn=defclass(ItemColumn,widgets.Panel)
ItemColumn.ATTRS={
	start_location="A",
	other_location="",
	on_loc_change=DEFAULT_NIL,
}
function enum_items( positions )
	local blocks=multikey_table{}
	--deduplicate blocks
	for k,v in pairs(positions.data) do
		local block=dfhack.maps.getTileBlock(v.x,v.y,v.z)
		blocks:set(block,block.map_pos.x,block.map_pos.y)
	end
	local ret={}
	for k,v in pairs(blocks.data) do
		for i,v in ipairs(v.items) do
			local it=df.item.find(v)
			local p=it.pos
			if positions:get(p.x,p.y,p.z) then
			   	table.insert(ret,it)
			end
	 	end
	end
	return ret
end
function list_items_at( loc )
	local its
	if loc=="A" then
		local positions=multikey_table{}
		for x=target_pos.x-1,target_pos.x+1 do
		for y=target_pos.y-1,target_pos.y+1 do
			--TODO: add skip here (i.e. around except the other part)
			positions:set({x=x,y=y,z=target_pos.z},x,y,target_pos.z)
		end
		end
		--or here
		its=enum_items(positions)
	else
		local positions=multikey_table{}
		local x=target_pos.x+LOC_dx[loc]
		local y=target_pos.y+LOC_dy[loc]
		positions:set({x=x,y=y,z=target_pos.z},x,y,target_pos.z)
		its=enum_items(positions)
	end
	local ret={}
	for i,v in ipairs(its) do
		table.insert(ret,{item=v,text=dfhack.items.getDescription(v,0,true)})
	end
	return ret
end

function ItemColumn:update_items( loc )
	if loc~="B" then
		self.subviews.items:setChoices(list_items_at(loc))
	else
		--TODO: FIXME tidy up this
		local items=dfhack.items.getContainedItems(get_player_backpack())
		local ret={}
		for i,v in ipairs(items) do
			table.insert(ret,{item=v,text=dfhack.items.getDescription(v,0,true)})
		end
		self.subviews.items:setChoices(ret)
	end
end
function ItemColumn:update_location( no_callback )
	local subname=""
	local ctrl=self.subviews.buttons
	local new_loc=ctrl.current_loc
	local names={
		S="South",
		N="North",
		E="East",
		W="West",
		NE="North-east",
		NW="North-west",
		SE="South-east",
		SW="South-west",
		A="Around",
		C="Center",
		B="Backpack",
	}
	if new_loc=="A" then
		subname=" " --bug of some sort? this needs to be non-empty string
	elseif new_loc=="B" then
		local backpack=get_player_backpack()
		subname=dfhack.items.getDescription(backpack,0,true)
	else
		local tt=dfhack.maps.getTileType(target_pos.x+LOC_dx[new_loc],target_pos.y+LOC_dy[new_loc],target_pos.z)
		subname=tile_attrs[tt].caption
	end
	self.subviews.location:setText(names[new_loc])
	self.subviews.loc_detail:setText(subname)
	self:update_items(ctrl.current_loc)
	ctrl:set_blocked(self.other_location)
	if not no_callback and self.on_loc_change then
		self.on_loc_change(new_loc)
	end
end
function ItemColumn:enable(value )
	self.subviews.buttons:enable(value)
	self.active=value
end
function ItemColumn:init(args)
    self:addviews{
		LocationButtons{view_id="buttons",frame={r=0,t=0,w=16},current_loc=self.start_location,on_loc_change=self:callback("update_location",false)},
    	widgets.Label{view_id="location",frame = { t=0,l=1}, text="Around"},
    	widgets.Label{view_id="loc_detail",frame = { t=1,l=1}, text="",text_pen=COLOR_GREY},
    	widgets.FilteredList{view_id="items",frame={t=3,l=1},edit_key="CUSTOM_S",scroll_keys=widgets.SECONDSCROLL}
    	--widgets.Label{view_id="key_drag",frame = { t=1,r=1,w=3}, text="[D]"},
	}
	--TODO: block "B"ackpack here if you dont have one
	self:update_location(true)
end

function ItemColumn:onInput( keys )
	--NOTE: even with fix this is needed because one key triggers multiple keybindings (e.g. numpad7 is "7" and move NW)
	if self.subviews.items.edit.active then
		return self.subviews.items:onInput(keys)
	else
		return self:inputToSubviews(keys)
	end
end

ItemTransferUi=defclass(ItemTransferUi,gui.FramedScreen)
ItemTransferUi.ATTRS{
    frame_title = "Item transfer",
    frame_style=gui.GREY_LINE_FRAME,
    enabled_tab=true,
}
function ItemTransferUi:set_enabled_tab( is_right, value)
	if is_right then
		self.subviews.right:enable(value)
	else
		self.subviews.left:enable(value)
	end
end
function ItemTransferUi:switch_tab(  )
	self:set_enabled_tab(self.enabled_tab,false)
	self.enabled_tab=not self.enabled_tab
	self:set_enabled_tab(self.enabled_tab,true)
end
function ItemTransferUi:location_change( side,loc )
	local trg
	if side=="left" then
		trg=self.subviews.right
	else
		trg=self.subviews.left
	end
	trg.other_location=loc
	trg:update_location(true)
end
function ItemTransferUi:init(args)
    self:addviews{
    	widgets.Label{view_id="change_tab",frame = { t=0,l=1}, text={{text="Change tab",key_sep="()",key="CHANGETAB",on_activate=self:callback("switch_tab")}} },
    	widgets.Label{frame = { t=0,l=25}, text={{text="Exit screen",key_sep="()",key="LEAVESCREEN",on_activate=self:callback("dismiss")}} },
    	SplitView{
    		subviews={
	    	ItemColumn{frame = { t=2,l=0},view_id="right",start_location="B",on_loc_change=self:callback("location_change","right")},
	    	ItemColumn{frame = { t=2,l=0},view_id="left",start_location="A",on_loc_change=self:callback("location_change","left")}
    		}
    	}
	}
	self:switch_tab()
	self:location_change("left",self.subviews.left.start_location)
	self:location_change("right",self.subviews.right.start_location)
end
if FIX_IS_APPLIED then
	ItemTransferUi.onInput=nil
else

function ItemTransferUi:onInput(keys)


    if keys.LEAVESCREEN then
    	--ugh... an ugly hack...
    	if self.subviews.left.subviews.items.edit.active or
    		self.subviews.right.subviews.items.edit.active then --basically check if edit is active before exiting screen
    		self:inputToSubviews(keys)
    	else
        	self:dismiss()
        end
    else
    	self:inputToSubviews(keys)
    end
end

end
--[=[function ItemTransferUi:onRenderBody( dc)
    --list widget goes here...
    --[[
    local char_a=string.byte('a')-1
    dc:newline(1):string("*. All")
    for k,v in ipairs(self.unit_list) do
        if self.selected[k] then
            dc:pen(COLOR_GREEN)
        else
            dc:pen(COLOR_GREY)
        end
        dc:newline(1):string(string.char(k+char_a)..". "):string(dfhack.TranslateName(v.name));
    end
    dc:pen(COLOR_GREY)
    local w,h=self:getWindowSize()
    local w2=math.floor(w/2)
    local char_A=string.byte('A')-1
    for k,v in ipairs(orders) do
        dc:seek(w2,k):string(string.char(k+char_A)..". "):string(v.name);
    end
    if is_cheat then
        for k,v in ipairs(cheats) do
            dc:seek(w2,k+#orders):string(string.char(k+#orders+char_A)..". "):string(v.name);
        end
    end]]
end]=]
local screen=ItemTransferUi{}
screen:show()