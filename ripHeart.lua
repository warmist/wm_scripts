--removes heart
function findBodyPart(caste_raw,token)
    for id,bp in ipairs(caste_raw.body_info.body_parts) do
        if bp.token==token then
            return id,bp
        end
    end
end
local trg=dfhack.gui.getSelectedUnit()
local heart_id=findBodyPart(df.creature_raw.find(trg.race).caste[trg.caste],"HEART")
print("heart_id",heart_id)
--ripping part
-- [[
local body=trg.body
body.components.body_part_status[heart_id].missing=true
local wid=body.wound_next_id
body.wound_next_id=wid+1
body.wounds:insert("#",{new=true,id=wid,flags={severed_part=true,mortal_wound=true},
    parts={
    {new=true,body_part_id=heart_id,bleeding=1000,pain=250,surface_perc=100}
    }})
--]]
--placing heart part
local hItem=df.item_corpsepiecest:new()
hItem:assign{
id=df.global.item_next_id,
flags={removed=true},
race=trg.race,
hist_figure_id=trg.hist_figure_id,
hist_figure_id2=trg.hist_figure_id,
unit_id=trg.id,
caste=trg.caste,
sex=trg.sex,
race2=trg.race,
caste2=trg.caste,

}
function copyVector(a,b)
    a:resize(#b)
    for i=0,#b-1 do
        a[i]=b[i]
    end
end
function assignBody(item,unit,id_missing)
    local body=item.body
    local uBody=unit.body
    local uComp=uBody.components
    --wounds skipped
    --unkns
    
    body.components.body_part_status:resize(#uComp.body_part_status)
    for k,v in ipairs(body.components.body_part_status) do
        body.components.body_part_status[k].missing= k~=id_missing
    end
    body.components.layer_status:resize(#uComp.layer_status)
    local names={"numbered_masks","nonsolid_remaining","layer_wound_area","layer_cut_fraction",
        "layer_dent_fraction","layer_effect_fraction"}
    for _,n in ipairs(names) do
        copyVector(body.components[n],uComp[n])
    end
    for id,v in ipairs(uBody.physical_attrs) do
        body.physical_attr_value[id]=v.value
    end
    body.size_info:assign(copyall(uBody.size_info))
  --[[
  df::body_size_info size_info;]]
  --[[
  int32_t size_cur;
    int32_t size_base;
    int32_t area_cur; /*!< size_cur^0.666 */
    int32_t area_base; /*!< size_base^0.666 */
    int32_t length_cur; /*!< (size_cur*10000)^0.333 */
    int32_t length_base; /*!< (size_base*10000)^0.333 */
  ]]
    copyVector(body.body_modifiers,unit.appearance.body_modifiers)
    copyVector(body.bp_modifiers,unit.appearance.bp_modifiers)
    body.unk_18c=unit.appearance.size_modifier
    body.unk_194:resize(#uBody.body_plan.body_parts) 
    for i=0,#uBody.body_plan.body_parts-1 do
        body.unk_194[i]=uBody.body_plan.body_parts[i].relsize --or from enemy...
    end
  --[[std::vector<int32_t > unk_194; bp rel size --TODO submit to xmls
  std::vector<int32_t > body_modifiers;
  std::vector<int32_t > bp_modifiers;
  int32_t unk_18c; /*!< =unit.appearance.unk_4c8 */]] --TODO submit to xmls
end
assignBody(hItem,trg,heart_id)
if dfhack.items.moveToGround(hItem,copyall(trg.pos)) then
    df.global.item_next_id=df.global.item_next_id+1
    df.global.world.items.all:insert("#",hItem)
    hItem:categorize(true)
else
    print("Place failed!")
    hItem:delete()
end