local ev=require 'plugins.eventful'

function fcallback( reaction,reaction_product,unit,input_items,input_reagents,output_items,call_native )
	print("=================================")
	print("event callback",reaction,reaction_product)
	call_native.value=false
end

ev.registerReaction("TAN_A_HIDE",fcallback)