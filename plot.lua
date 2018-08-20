local gui=require 'gui'
local wid=require 'gui.widgets'

--[[
    A widget to plot some lines
]]

line_plot=defclass(line_plot,wid.Widget)

line_plot.ATTRS={
    data=DEFAULT_NIL,
    axis_x=DEFAULT_NIL,
    axis_y=DEFAULT_NIL,
}

function line_plot:init( args )

end
--next two functions handle two different ways to input data: either one series shorthand, or table of series
function line_plot:count_series(  )
    if type(self.data)=='table' then
        if self.data[1] and type(self.data[1]) == 'table' then
            return #self.data
        else
            return 1
        end
    else
        return 0
    end
end
function line_plot:get_series( id )
    if type(self.data)=='table' then
        if self.data[1] and type(self.data[1]) == 'table' then
            return self.data[id]
        else
            return self.data
        end
    else
        return {}
    end
end


function line_plot:calc_axis(  )
    local min_x=math.huge
    local max_x=-math.huge

    local min_y=math.huge
    local max_y=-math.huge

    for i=1,self:count_series() do
        local s=self:get_series(i)
        local is_scatter=type(s[1])=='table'

        for i,v in ipairs(s) do
            local x,y
            if is_scatter then
                x=v[1]
                y=v[2]
            else
                x=i
                y=v
            end
            if min_x>x then min_x=x end
            if min_y>y then min_y=y end
            if max_x<x then max_x=x end
            if max_y<y then max_y=y end
        end
    end
    return {min_x,max_x},{min_y,max_y}
end
local function step_line(x0,y0,x1,y1, f )
    local sign_x,sign_y
    local delta_x,delta_y

    delta_x=x1-x0
    if delta_x<0 then
        sign_x=-1
    else
        sign_x=1
    end

    delta_y=y1-y0
    if delta_y<0 then
        sign_y=-1
    else
        sign_y=1
    end
    delta_x=math.abs(delta_x)
    delta_y=math.abs(delta_y)

    local err = delta_x-delta_y
    f(x0,y0,0,0)

    while x0 ~= x1 or y0 ~= y1 do
        local dbl_err=err+err
        local step_x=0
        local step_y=0
        if dbl_err > -delta_y then
            err = err - delta_y
            x0  = x0 + sign_x
            step_x=sign_x
        end
        if dbl_err < delta_x then
            err = err + delta_x
            y0  = y0 + sign_y
            step_y=sign_y
        end
        f(x0,y0,step_x,step_y)
    end
end
function line_plot:onRenderBody( dc )
    if self.data == nil then
        return
    end

    local axis_x=self.axis_x
    local axis_y=self.axis_y

    if axis_x==nil or axis_y==nil then
        local naxis_x,naxis_y=self:calc_axis()

        axis_x=axis_x or naxis_x
        axis_y=axis_y or naxis_y
    end
    local axis_x_size = axis_x[2]-axis_x[1]
    local axis_y_size = axis_y[2]-axis_y[1]
    --print("Screen:",dc.width,dc.height)
    --actual plotting
    for i=1,self:count_series() do
        local s=self:get_series(i)
        local is_scatter=type(s[1])=='table'

        local pen=dfhack.pen.make({ch='x'},s.pen)
        local do_pts=true
        if s.do_point~=nil and not s.do_point then
            do_pts=false
        end
        local do_line=true
        if s.do_line~=nil and not s.do_line then
            do_line=false
        end
        local old_x,old_y
        local line_pen=dfhack.pen.make(pen,s.line_pen)

        local line_fun=function ( nx,ny,sx,sy )
            --[[ A sloped line, looks ugly :|
            if sx~=0 or sy~=0 then

                local n=(sx+1)+(-sy+1)*3+1 --maps -1,0,1 to 0,1,2 and makes 3x3 array
                local ch_array={
                    -- -1,-1 0,-1 1,-1
                        '/', '|', '\\',
                    -- -1,0 0,0 1,0
                        '-', '?', '-',
                    -- -1,1 0,1 1,1
                        '\\', '|', '/'
                }
                --TODO: we need a better way of handling slope here. Maybe more ascii for better lines?
                dc:seek(nx,ny):char(ch_array[n])
            end
            ]]
            dc:seek(nx,ny):char()
        end
       
        for i,v in ipairs(s) do
            local x,y
            if is_scatter then
                x=v[1]
                y=v[2]
            else
                x=i
                y=v
            end

            local wx=(x-axis_x[1])/(axis_x_size)
            local wy=(y-axis_y[1])/(axis_y_size)
            wx=math.floor(wx*(dc.width-2))+1
            wy=math.floor((1-wy)*(dc.height-2))+1

            if do_line then
                dc:pen(line_pen)
                if old_x~=nil then
                    step_line(old_x,old_y,wx,wy,line_fun)
                end
                old_x=wx
                old_y=wy
            end
            if x>=axis_x[1] and x<=axis_x[2] and
                y>=axis_y[1] and y<=axis_y[2] then
                dc:pen(pen)
                --else out of bounds
                if do_pts then
                    dc:seek(wx,wy):char()
                end
                --print(x,y,wx,wy)
            end
        end
    end
    --print("====")
end



test_plot = defclass(test_plot, gui.FramedScreen)
test_plot.ATTRS = {
    frame_style = gui.GREY_LINE_FRAME,
    frame_title = "Test plots",
}


function test_plot:init(args)
    self:addviews{
        line_plot{
           frame = { t=0,l=0,b=1},
           data=args.data,
        },
        wid.Label{
            frame = { b=0,l=1},
            text = {{
                text = ": exit plot",
                key = "LEAVESCREEN",
                on_activate = self:callback("dismiss")
            }},
        }
    }
end
local sin_table={}
for i=1,100 do
    table.insert(sin_table,{i/25,math.sin(i/2)+1})
end

local data={
    sin_table,
    {1,2,3,1,2,3,5,pen={fg=3,bg=4,ch='+'}},
    {{1,2.4},{2,4},{1,6},{3,4},pen={ch='*'}}
}

test_plot{data=data}:show()