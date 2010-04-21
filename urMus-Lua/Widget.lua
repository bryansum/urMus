dofile(SystemPath("helpers.lua"))
req("Animate")

if not Widget then Widget = {} end

-- menu = Widget.ContextMenu({{'first',function()DPrint('first'); end}})
-- parent:EnableInput(true); parent:Handle("OnTouchDown",menu.OnTouchDown)
-- defaults to immediately below parent element. can be switched using x,y coordinates
Widget.ContextMenu = function(items,opts)
  opts = opts or {}
  local fs = opts['fsize'] or 12
  local spacing = opts['spacing'] or 0
  local width = opts['w'] or 100
  local el_height = fs*2
  local parent = opts['parent'] or UIParent
  local border = {size=0, color='grey'}
  if opts['border'] then for k,v in pairs(opts['border']) do border[k] = v end end
  local height = (#items*(el_height+spacing))+(2*border.size)
  local color = opts['color'] or 'darkgrey'
  local tcolor = opts['text_color'] or 'black'
  local rel_x = opts['x'] or 0
  local rel_y = opts['y'] or 0
  
  local m = make_region({w=width+(2*border.size), h=height,
                         x=0,y=-height,
                         color=parse_color(border.color),
                         parent=parent})

  for i,el in pairs(items) do
    local r = make_region({w=width, h=el_height, 
                           x=rel_x+border.size, y=(#items*(el_height+spacing))-((el_height+spacing)*i)+border.size+rel_y,
                           parent=m,
                           color=parse_color(color), 
                           label={text=el[1], size=fs, color=parse_color(tcolor), shadow={0,0,0,190,2,-3,6}}})
    add_event(r,"OnTouchDown",el[2])
    r:EnableInput(false)
  end
  
  -- set alpha to zero initially (for child elements too)
  rset_attrs(m,{alpha=0})
  -- add animation settings
  local anim = nil; local open = false
  local enterFn = function()
      if anim then anim:Cancel(); open = not open end
      anim = Animate.start({
        duration=0.5,
        cb=function(pos)
          local from = m:GetAlpha()
          local to = open and 0 or 1
          rset_attrs(m,{alpha=Animate.interpolate(from,to,pos)})
        end,
        after=function() 
          anim = nil; open = not open
          _.each({m:Children()},function(i)
            i:EnableInput(open and true or false)
          end)
        end})
  end
  add_event(parent,"OnTouchDown",enterFn)  

  function m:Cancel()
    if anim then anim:Cancel() end
    remove_event(parent,"OnTouchDown",enterFn)
  end

  return m
end

-- tt = Widget.Tooltip("test value", region)
-- tt:Cancel() to remove from scene
Widget.Tooltip= function(text, opts)
  opts = opts or {}
  local fs = opts['fsize'] or 12
  local height = opts['h'] or fs*2
  local parent = opts['parent'] or UIParent
  local tt = make_region({h=height,
                          color=opts['bg_color'] or 'white',
                          alpha=0,
                          label={text=text,color=opts['text_color'] or 'grey'}})  
  local anim = nil
  local enterFn = function(self) 
      -- get mouse input position and set anchor at
      -- BOTTOMLEFT UIParent inputx, inputy
      local x,y = InputPosition()
      tt:SetAnchor('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', x, y)

      if anim then anim:Cancel() end
      anim = Timer.start(0.25,function()
          anim = Animate.start({duration=0.2,cb=Animate.updateAlpha(tt,1)})
      end)
  end
  local removeFn = function(self)
      if anim then anim:Cancel() end
      anim = Timer.start(1.25, function()
        anim = Animate.start({duration=0.5,cb=Animate.updateAlpha(tt,0)})
      end)
  end
  
  -- enable input if it wasn't already in the parent, else no events
  parent:EnableInput(true)
  add_event(parent,"OnTouchDown",enterFn)
  add_event(parent,"OnEnter",enterFn)  
  add_event(parent,"OnLeave",removeFn)
  
  function tt:Cancel()
    if anim then anim:Cancel() end
    remove_event(parent,"OnTouchDown",enterFn)
    remove_event(parent,"OnEnter",enterFn)
    remove_event(parent,"OnLeave",removeFn)
  end
  
  return tt
end

