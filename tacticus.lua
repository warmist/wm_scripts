-- the only TACTICUS. Two modes: free/rulebound
local gui=require 'gui'
local wid=require 'gui.widgets'
--[=[
	rules supported:
		if_ - e.g. if you have 0 units, this spell costs 0
		when_ - like if but for instant/optional/triggers, gets called with some action if returns true triggers:
			when other player puts an creature do 1 dmg to it
		may_ - optional action, ask player: player may sacrifice his creature to gain 1 life
		target_ - accepts filter, ask player for target returns target(s) e.g.:  remove up-to 5 units from hand
			filters:
				friendly
				enemy - !friendly
				my 
				unit
				item
				--other objects?
				count-- somehow add up-to
				in_hand -- only ones you have in hand?(pocket does it exist at all?)
	play pieces:
		units -> from raws
		items -> random stuff maybe from raws
		cards -> ?
		trinkets->?
		spells->
		spellets
		knickknacks
		tokens
		blood drops
		coins
		souls
		books of rules-> main thing that holds rules really...
		excerpts from books (same thing but more small)
		and all other named in rules
	play pieces must(can?) have:
		valid locations (e.g. field,hand, pocket, void dimension, though, soul, other pieces,...)
		events (move/do/activate/hold/break...)
		actions (or events are same?)
	locations:
		positions or not (e.g. field vs hand vs deck)
		size
		dimensions (2/3 field vs deck,box,hand 0d ?)
		access to all objects: yes/no (hand yes, deck no)
	play:
		stages
			start turn
			end turn
]=]

--[=[
	default book of rules:
		game start:
			all players get 20 souls in hand
		on end of turn:
			if current player has <=0 souls then he loses
		soul:
			creation:
				soul.type=pick random from creatures
				icon = 'o'|'O'|'0'
				color= pick random
			display:
				show name of type
			events:
				created
				destroyed
				used
				moved
			actions:
				materialize(used) - creates a unit on field (any race/caste), triggers `used`, move to created unit. if in hand
				give(moved) to player
		unit:
			destroyed:
				move soul back to owning player
			end of turn:
				unit is destroyed if it does not have at least 1 soul
	excerpt from urist the 3rd edition:
		soul:
			actions:
				discard(destroyed) - player gains 1 soul if discarded from field
		unit->shaman:
			actions:
				move soul
			end of turn:
				<remove rule about destroy without soul>

--]=]
screen=defclass(screen,gui.FramedScreen)
screen.ATTRS={
	
}
function screen:init( args )
	self:addviews{
		wid.Panel{
			view_id="playArea",
			frame={l=0,t=0,r=20,b=0}
		},
		wid.Panel{
			view_id="sidebar",
			frame={t=0,w=20,b=0,xalign=1},
			subviews={
				wid.Label{text="TACTICUS",frame={xalign=0.5,t=1}},
				wid.Label{text={{key='CUSTOM_E',key_sep=": ",text="End turn"}},frame={t=2} },
				wid.Label{text={{key='CUSTOM_A',key_sep=": ",text="Add unit"}},frame={t=3} },
				wid.Label{text={{key='CUSTOM_R',key_sep=": ",text="View/edit rules"}},frame={t=4} },
				wid.Label{text={{key='SELECT',key_sep=": ",text="Select Unit"}},frame={t=5} },
				
				wid.Label{text={{key='LEAVESCREEN',key_sep=": ",text="Exit TACTICUS"}},frame={b=1} },
			}
		}	
	}
end
function screen:onInput(keys)
    if keys.LEAVESCREEN then
        self:dismiss()
    else
        self:inputToSubviews(keys)    
    end
end
local sc=screen{}
sc:show()