--An advanced get window inspired by "Cataclysm: Dark days ahead"
--[[
	TODO:
		* figure out "blocked tiles"
		* better "tile name print"
		* make keys not be CUSTOM_
		* block "full" tiles
		* three modes:
			- cheat -> no volume checks
			- vanilla -> no checks only for players backpack
			- strict -> ALL THE CHECKS
		* companion inventory transfers
		* pressing direction that is used in other tab, should swap (??)
		* check for worn backpack
		* quiver?
		* handle doors /other constructions?
		* FIXME: block container move into container!
]]
--[[
	Dragged: i.e. minecart -- not possible (not easily at least) only set when doing a job with wheelbarrow
	Container: (which one? there could be many per tile)
	Inventory: (probably backpack but could be other "worn" containers)
	Worn
	Area
	Numbers
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
		if df.item_backpackst:is_instance(v.item) and v.mode==df.unit_inventory_item.T_mode.Worn then
			return v.item
		end
	end
end
function tile_is_blocked( x,y,z )
	local tt=dfhack.maps.getTileType(x,y,z)
	--not sure if that covers everything but pretty much?
	return df.tiletype_shape.attrs[tile_attrs[tt].shape].basic_shape==df.tiletype_shape_basic.Wall
end
local FIX_IS_APPLIED=false

---Get item capacity. Returns 0 if not a container. Reversed from df. ANCIENT TODO: verify
function get_capacity(item) --TODO move to items in dfhack
	local t=item:getType()
	if t==df.item_type.TOOL then
		local st=item.subtype
		return st.container_capacity
	end
	local arr={
		[df.item_type.GOBLET]=180,
		[df.item_type.FLASK]=180,

		[df.item_type.CAGE]=6000,
		[df.item_type.BARREL]=6000,
		[df.item_type.COFFIN]=6000,
		[df.item_type.BOX]=6000,
		[df.item_type.BIN]=6000,
		[df.item_type.ARMORSTAND]=6000,
		[df.item_type.WEAPONRACK]=6000,
		[df.item_type.CABINET]=6000,

		[df.item_type.ANIMALTRAP]=3000,
		[df.item_type.BACKPACK]=3000,

		[df.item_type.QUIVER]=1200,

		[df.item_type.BUCKET]=600,
	}
	return arr[t] or 0
end

multikey_table=defclass(multikey_table)
--[[
	TODO:
		* weak-ref keys
		* maybe make index work?
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



LocationButtons=defclass(LocationButtons,widgets.Widget)
LocationButtons.ATTRS{
	current_loc="C",
	on_loc_change=DEFAULT_NIL,
}
function LocationButtons:get_token( id )
	local labels={"bottom","center","top"}
	for i,v in ipairs(labels) do
		local tok=self.subviews[v]:itemById(id)
		if tok then return tok end
	end
end
function LocationButtons:set_blocked( key,value )
	local tkn=self:get_token(key)

	if value then
		tkn.enabled=false
		tkn.key_pen=COLOR_LIGHTRED
	else
		tkn.enabled=true
		tkn.key_pen=COLOR_LIGHTGREEN
	end
end
function LocationButtons:enable( value )
	for _,l in ipairs(self.subviews) do
		l.enabled=value
	end
end
function LocationButtons:change_current( new_key )
	local tkn=self:get_token(self.current_loc)
	tkn.key_pen=COLOR_LIGHTGREEN

	self.current_loc=new_key

	tkn=self:get_token(self.current_loc)
	tkn.key_pen=COLOR_LIGHTBLUE
end
function LocationButtons:key_press( k )
	self:change_current(k)

	if self.on_loc_change then
		self:on_loc_change()
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
		widgets.Label{view_id="top",frame = { t=2,l=0}, text={
			{key_sep='()',key="CUSTOM_C",id="CONTAINER",on_activate=self:callback("key_press","CONTAINER")},
			{key_sep='()',key="A_MOVE_SW",id="SW",on_activate=self:callback("key_press","SW")},
			{key_sep='()',key="A_MOVE_S",id="S",on_activate=self:callback("key_press","S")},
			{key_sep='()',key="A_MOVE_SE",id="SE",on_activate=self:callback("key_press","SE")}
		} },
	}
	self:change_current(self.current_loc)
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
function format_volume( v )
	if v>1000 then
		return string.format("%.1gk",v/1000)
	else
		return string.format("%d",v)
	end
end
function list_items_at( loc,skip_loc )
	local its
	if loc=="A" then
		local positions=multikey_table{}
		for x=target_pos.x-1,target_pos.x+1 do
		for y=target_pos.y-1,target_pos.y+1 do
			positions:set({x=x,y=y,z=target_pos.z},x,y,target_pos.z)
		end
		end
		if skip_loc then
			positions:set(nil,skip_loc.x,skip_loc.y,skip_loc.z)
		end
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
		table.insert(ret,{item=v,text={{text=format_volume(v:getVolume()),width=4},dfhack.items.getDescription(v,0,true)}})
	end
	return ret
end
function ItemColumn:update_volume( cur_v,max_v )
	self.subviews.volume_detail:setText(string.format("Volume %d/%d",cur_v,max_v))
end
function list_container( cont )
	local ret_items={}
	local volume_sum=0
	local max_volume=0
	if cont then
		local items=dfhack.items.getContainedItems(cont)
		for i,v in ipairs(items) do
			local vol=v:getVolume()
			volume_sum=volume_sum+vol
			table.insert(ret_items,{item=v,text={{text=format_volume(vol),width=4},dfhack.items.getDescription(v,0,true)}})
		end
	end
	return ret_items,volume_sum,get_capacity(cont)
end
function ItemColumn:update_items( loc )

	if loc=="B" then
		--TODO: FIXME tidy up this
		local ret,volume_sum,volume_max=list_container(get_player_backpack())
		self:update_volume(volume_sum,volume_max)
		self.subviews.items:setChoices(ret)
	elseif loc=="CONTAINER" then
		local it=self.container_item
		if it and get_capacity(it) then
			local ret,volume_sum,volume_max=list_container(it)
			self:update_volume(volume_sum,volume_max)
			self.subviews.items:setChoices(ret)
		else
			self.subviews.items:setChoices()
		end
	else
		local other_loc
		if self.other_location and LOC_dx[self.other_location]~=nil  then
			other_loc={x=target_pos.x+LOC_dx[self.other_location],y=target_pos.y+LOC_dy[self.other_location],z=target_pos.z}
		end
		self.subviews.items:setChoices(list_items_at(loc,other_loc))
		self:update_volume(0,0)
	end
end
function ItemColumn:set_other_loc( ol )
	local ctrl=self.subviews.buttons
	if self.other_location~="CONTAINER" and self.other_location~=nil then
		ctrl:set_blocked(self.other_location,false)
	end

	self.other_location=ol

	if self.other_location~="CONTAINER" and self.other_location~=nil then
		ctrl:set_blocked(self.other_location,true)
	end

	self:update_location(true)
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
		CONTAINER="Container",
	}
	if new_loc=="A" then
		subname=" " --bug of some sort? this needs to be non-empty string
	elseif new_loc=="B" then
		local backpack=get_player_backpack()
		if backpack then
			subname=dfhack.items.getDescription(backpack,0,true)
		else
			subname=""
		end
	elseif new_loc=="CONTAINER" then
		local _,it=self.subviews.items.list:getSelected()
		if it and get_capacity(it.item) then
			subname=dfhack.items.getDescription(it.item,0,true)
			self.container_item=it.item
		else
			subname=""
		end
	else
		local tt=dfhack.maps.getTileType(target_pos.x+LOC_dx[new_loc],target_pos.y+LOC_dy[new_loc],target_pos.z)
		subname=tile_attrs[tt].caption
	end
	self.subviews.location:setText(names[new_loc])
	self.subviews.loc_detail:setText(subname)

	self:update_items(ctrl.current_loc)

	--NOTE: so in init we don't have frame calculated yet (i.e. no layout happened yet)
	--  but next time we call this to update label with auto size (volume)
	if self.frame_parent_rect then
		self:updateLayout(self.frame_parent_rect)
	end

	if not no_callback and self.on_loc_change then
		self.on_loc_change(new_loc)
	end
end
function ItemColumn:enable(value )
	self.subviews.buttons:enable(value)
	self.active=value
	self.subviews.items.list.active=value
	if value then
		self.subviews.items.list.text_pen=COLOR_CYAN
	else
		self.subviews.items.list.text_pen=COLOR_GREY
	end
end
function ItemColumn:update_selected( id,list_item )
	local is_container=false
	if list_item and list_item.item then
		is_container=get_capacity(list_item.item)~=0
	end
	--block non containers
	self.subviews.buttons:set_blocked("CONTAINER",not is_container)
end
function ItemColumn:init(args)
    self:addviews{
		LocationButtons{view_id="buttons",frame={r=0,t=0,w=16},current_loc=self.start_location,on_loc_change=self:callback("update_location",false)},
    	widgets.Label{view_id="location",frame = { t=0,l=1}, text="Around"},
    	widgets.Label{view_id="loc_detail",frame = { t=1,l=1}, text="",text_pen=COLOR_GREY},
    	widgets.Label{view_id="volume_detail",frame={t=3,r=1},auto_width=true, text="Volume 0/0"},
    	widgets.Label{view_id="cols",frame={t=3,l=1}, text="Vol "},
    	widgets.FilteredList{
    			view_id="items",
    			frame={t=5,l=1},
    			edit_key="CUSTOM_S",
    			edit_below=true,
    			scroll_keys=widgets.SECONDSCROLL,
    			inactive_pen=COLOR_GREY,
    			on_select=self:callback("update_selected")
    		}
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
	trg:set_other_loc(loc)
end
function ItemTransferUi:init(args)
	local no_backpack= get_player_backpack()==nil
	local start_right="B"
	if no_backpack then
		start_right="C"
	end
    self:addviews{
    	widgets.Label{view_id="change_tab",frame = { t=0,l=1}, text={{text="Change tab",key_sep="()",key="CHANGETAB",on_activate=self:callback("switch_tab")}} },
    	widgets.Label{frame = { t=0,l=25}, text={{text="Exit screen",key_sep="()",key="LEAVESCREEN",on_activate=self:callback("dismiss")}} },
    	SplitView{
    		subviews={
	    	ItemColumn{frame = { t=2,l=0},view_id="right",start_location=start_right,on_loc_change=self:callback("location_change","right")},
	    	ItemColumn{frame = { t=2,l=0},view_id="left",start_location="A",on_loc_change=self:callback("location_change","left")}
    		}
    	}
	}
	if get_player_backpack()==nil then
		self.subviews.left.subviews.buttons:set_blocked("B",true)
		self.subviews.right.subviews.buttons:set_blocked("B",true)
	end
	--NOTE: skipping 0,0 (C) because if we have center blocked we are DOOMED
	local check_sides={
		S=true,N=true,
		W=true,NW=true,SW=true,
		E=true,NE=true,SE=true
	}
	for k,v in pairs(check_sides) do
		local x=target_pos.x+LOC_dx[k]
		local y=target_pos.y+LOC_dy[k]

		local is_blocked=tile_is_blocked(x,y,target_pos.z)
		self.subviews.left.subviews.buttons:set_blocked(k,is_blocked)
		self.subviews.right.subviews.buttons:set_blocked(k,is_blocked)
	end

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

local screen=ItemTransferUi{}
screen:show()