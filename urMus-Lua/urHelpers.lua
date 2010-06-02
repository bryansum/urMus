-- urHelpers.lua
-- Set of helper functions and commonly used functions wrapped into single calls
-- Created by Bryan Summersett on 3/28/2010

function table.copy(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end

-- recursively updates an attribute on every element involved
function RSetAttrs(r,opts)
  for i,v in pairs({r:Children()}) do
    RSetAttrs(v,opts)
  end
  SetAttrs(r,opts)
end

-- require a file using urMus-style. If includes 'var', then 
-- the file's content will be assigned to that global var and not required again. 
-- Req('underscore','_')
function Req(name,var)
  if not var then return dofile(SystemPath(name..".lua")) end
  if not _G[var] then _G[var] = dofile(SystemPath(name..".lua")); return _G[var]; end
end

Req('underscore','us')

-- use shorthand notation to set a number of attributes in the urMus api. 
-- supported attributes include: input, layer, width, height,
-- x,y, img, color, gradient, alpha, rotate
function SetAttrs(r,opts)
  local set = function(r)
    for k,fn in pairs({
        input='EnableInput',
        layer='SetLayer',
        w='SetWidth',h='SetHeight',
        width='SetWidth',height='SetHeight',
        alpha='SetAlpha'
    }) do
      if opts[k] then r[fn](r,opts[k]) end
    end
  
    if opts.x or opts.y then
      local cur = {r:Anchor()}
        r:SetAnchor(cur[1] or 'BOTTOMLEFT',
        cur[2] or r:Parent(),
        cur[3] or 'BOTTOMLEFT',
        opts.x or cur[4] or 0,
        opts.y or cur[5] or 0)
    end
    
    local make_texture = function(r) if not r.t then r.t = r:Texture() end end
    
    if opts.img then
      local next_power_two = function(n) 
        if n == 0 then return 0 end
        local i = 0
        repeat i=i+1 until 2^i >= n
        return 2^i
      end
      local w_tex = next_power_two(opts.width)
      local h_tex = next_power_two(opts.height)
      make_texture(r)
      -- urMus textures are openGL textures, so they're resized to the nearest 
      -- power of 2. We need to set the texCoords to compensate
      r.t:SetTexture(opts.img)
      r.t:SetTexCoord(0,opts.width/w_tex,opts.height/h_tex,0.0)
      r.tc = {r.t:TexCoord()}
    end
    if opts.color then 
      make_texture(r)
      r.t:SetTexture(unpack(ParseColor(opts['color']))) 
    end
    if opts.gradient then
      local g = {opts.gradient[1]}
      g[2] = ParseColor(opts.gradient[2]); g[2][4] = g[2][4] or 255; -- add alpha 
      g[3] = ParseColor(opts.gradient[3]); g[3][4] = g[3][4] or 255
      make_texture(r)
      r.t:SetGradientColor(unpack(us.flatten(g)))
    end
    
    -- texture attributes
    for k,fn in pairs({
      rotate='SetRotation',
      blend='SetBlendMode'
    }) do
      if opts[k] then r.t[fn](r.t,opts[k]) end
    end
  end

  if r.Parent then
    set(r)
  else
    for i,v in pairs(r) do set(v) end
  end
end
-- Make an image:
-- r = MakeRegion({w=100, h=200, img='thing.jpg'})
-- Make a black box:
-- r = MakeRegion({w=100, h=100, color={0,0,0}})
-- Make a label attached to a :
-- r = MakeRegion({w=300, h=100, 
--                  color={255,255,255}, 
--                  label={text="Test",
--                         color={0,0,0},
--                         shadow={0,0,0,190,2,-3,6}}})
function MakeRegion(opts)
  opts = opts or {}
  local parent = opts['parent'] or UIParent
  local r = Region('region','MakeRegion region',parent)
  r:SetParent(parent)
  opts['input'] = opts['input'] or true
  opts['layer'] = opts['layer'] or 'MEDIUM'
  opts['width'] = opts['width'] or opts['w'] or 100
  opts['height'] = opts['height'] or opts['h'] or 100
  opts['color'] = opts['color'] or 'white'
  opts['blend'] = opts['blend'] or 'BLEND'
  -- do a bunch of attribute setting
  SetAttrs(r,opts)

  if opts['label'] then
    local l = opts['label']
    local fsize = l['size'] or 12
    local text = l['text'] or ""
    r.tl = r:TextLabel();
    r.tl:SetFont(l['font'] or "Trebuchet MS")
    r.tl:SetHorizontalAlign(l['align'] or "LEFT"); 
    r.tl:SetLabelHeight(fsize)
    r.tl:SetWrap(l['wrap'] or 'WORD')
    r.tl:SetLabel(text) 
    
    -- first four (r,g,b,a)
    local color = {255,255,255,255}
    if l['color'] then 
      if type(l['color']) == 'table' then
        for i,v in pairs(l['color']) do color[i] = v end -- copy our colors over
      elseif type(l['color']) == 'string' then 
        color = ParseColor(l['color'])
        color[4] = 255
      end
    end  
    r.tl:SetColor(unpack(color))
    
    -- shadow settings. first four (r,g,b,a); then offset (x,y); then blur radius (px)
    local shadow = {0,0,0,190,2,-3,6}
    if l['shadow'] then
      for i,v in pairs(l['shadow']) do shadow[i] = v end -- copy our shadow params over
    end
    r.tl:SetShadowColor(unpack(us.first(shadow,4)))
    r.tl:SetShadowOffset(unpack(us.first(shadow,5)))
    r.tl:SetShadowBlur(shadow[7])
    
    -- if the width isn't specified for this region and we have a label,
    -- set its width to be the width of the text label's width
    if not opts.width then 
      r:SetWidth(string.len(text)*(fsize/2)) 
    end
  end
  
  -- if position arguments, do 
  r:Show()
  return r  
end

-- adds or updates an event for a given object
-- Operates similarly to addEventListener() in JS
function AddEvent(obj,e_name,fn)
  if not obj.events then obj.events = {} end
  local e = obj.events
  if not e[e_name] then e[e_name] = {} end
  local q = e[e_name]
  if not q[fn] then table.insert(q,fn) end
  
  obj:Handle(e_name,function(...) 
    for i,v in pairs(q) do fn(unpack({...})) end
  end)
end

-- removes a given event handler for an obj.
-- Operates similarly to removeEventListener() in JS
function RemoveEvent(obj,e_name,fn)
  if not obj.events then return end
  local e = obj.events
  if not e[e_name] then return end
  local q = e[e_name]; 
  -- reject fns equal to fn
  local temp = {}
  for i,v in pairs(q) do if v ~= fn then temp[i] = v end end; 
  obj.events[e_name] = temp
  if #obj.events[e_name] == 0 then obj:Handle(e_name,nil) end -- remove handler if none left
end

-- uses a table to find color values; this fn can be called as {r,g,b} or {'colorname'}
-- and is based on CSS color table values
function ParseColor(c)
  local colors = {aliceblue={240,248,255},
    antiquewhite={250,235,215},
    aqua={0,255,255},
    aquamarine={127,255,212},
    azure={240,255,255},
    beige={245,245,220},
    bisque={255,228,196},
    black={0,0,0},
    blanchedalmond={255,235,205},
    blue={0,0,255},
    blueviolet={138,43,226},
    brown={165,42,42},
    burlywood={222,184,135},
    cadetblue={95,158,160},
    chartreuse={127,255,0},
    chocolate={210,105,30},
    coral={255,127,80},
    cornflowerblue={100,149,237},
    cornsilk={255,248,220},
    crimson={220,20,60},
    cyan={0,255,255},
    darkblue={0,0,139},
    darkcyan={0,139,139},
    darkgoldenrod={184,134,11},
    darkgray={169,169,169},
    darkgreen={0,100,0},
    darkgrey={169,169,169},
    darkkhaki={189,183,107},
    darkmagenta={139,0,139},
    darkolivegreen={85,107,47},
    darkorange={255,140,0},
    darkorchid={153,50,204},
    darkred={139,0,0},
    darksalmon={233,150,122},
    darkseagreen={143,188,143},
    darkslateblue={72,61,139},
    darkslategray={47,79,79},
    darkslategrey={47,79,79},
    darkturquoise={0,206,209},
    darkviolet={148,0,211},
    deeppink={255,20,147},
    deepskyblue={0,191,255},
    dimgray={105,105,105},
    dimgrey={105,105,105},
    dodgerblue={30,144,255},
    firebrick={178,34,34},
    floralwhite={255,250,240},
    forestgreen={34,139,34},
    fuchsia={255,0,255},
    gainsboro={220,220,220},
    ghostwhite={248,248,255},
    gold={255,215,0},
    goldenrod={218,165,32},
    gray={128,128,128},
    green={0,128,0},
    greenyellow={173,255,47},
    grey={128,128,128},
    honeydew={240,255,240},
    hotpink={255,105,180},
    indianred={205,92,92},
    indigo={75,0,130},
    ivory={255,255,240},
    khaki={240,230,140},
    lavender={230,230,250},
    lavenderblush={255,240,245},
    lawngreen={124,252,0},
    lemonchiffon={255,250,205},
    lightblue={173,216,230},
    lightcoral={240,128,128},
    lightcyan={224,255,255},
    lightgoldenrodyellow={250,250,210},
    lightgray={211,211,211},
    lightgreen={144,238,144},
    lightgrey={211,211,211},
    lightpink={255,182,193},
    lightsalmon={255,160,122},
    lightseagreen={32,178,170},
    lightskyblue={135,206,250},
    lightslategray={119,136,153},
    lightslategrey={119,136,153},
    lightsteelblue={176,196,222},
    lightyellow={255,255,224},
    lime={0,255,0},
    limegreen={50,205,50},
    linen={250,240,230},
    magenta={255,0,255},
    maroon={128,0,0},
    mediumaquamarine={102,205,170},
    mediumblue={0,0,205},
    mediumorchid={186,85,211},
    mediumpurple={147,112,219},
    mediumseagreen={60,179,113},
    mediumslateblue={123,104,238},
    mediumspringgreen={0,250,154},
    mediumturquoise={72,209,204},
    mediumvioletred={199,21,133},
    midnightblue={25,25,112},
    mintcream={245,255,250},
    mistyrose={255,228,225},
    moccasin={255,228,181},
    navajowhite={255,222,173},
    navy={0,0,128},
    oldlace={253,245,230},
    olive={128,128,0},
    olivedrab={107,142,35},
    orange={255,165,0},
    orangered={255,69,0},
    orchid={218,112,214},
    palegoldenrod={238,232,170},
    palegreen={152,251,152},
    paleturquoise={175,238,238},
    palevioletred={219,112,147},
    papayawhip={255,239,213},
    peachpuff={255,218,185},
    peru={205,133,63},
    pink={255,192,203},
    plum={221,160,221},
    powderblue={176,224,230},
    purple={128,0,128},
    red={255,0,0},
    rosybrown={188,143,143},
    royalblue={65,105,225},
    saddlebrown={139,69,19},
    salmon={250,128,114},
    sandybrown={244,164,96},
    seagreen={46,139,87},
    seashell={255,245,238},
    sienna={160,82,45},
    silver={192,192,192},
    skyblue={135,206,235},
    slateblue={106,90,205},
    slategray={112,128,144},
    slategrey={112,128,144},
    snow={255,250,250},
    springgreen={0,255,127},
    steelblue={70,130,180},
    tan={210,180,140},
    teal={0,128,128},
    thistle={216,191,216},
    tomato={255,99,71},
    turquoise={64,224,208},
    violet={238,130,238},
    wheat={245,222,179},
    white={255,255,255},
    whitesmoke={245,245,245},
    yellow={255,255,0},
    yellowgreen={154,205,50}
  }
  if type(c) == 'table' then return c
  elseif type(c) == 'string' and colors[c] then return colors[c]
  else return nil end
end

