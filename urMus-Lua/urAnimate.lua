-- Animation.lua
-- Simple animation framework
-- Created by Bryan Summersett on 2/24/2010
-- large credit to Thomas Fuchs's émile: http://github.com/madrobby/emile

-- timer = Timer.create(5, callbackfn)
-- timer:Start()
-- or timer = Timer.start(5,callbackfn)

if not Timer then Timer = {
  create = function(dur,callback)
    local el = Region('region', 'timer', UIParent)
    local remaining = dur
    local function interval(el, elapsed)
      remaining = remaining - elapsed
      if remaining < 0 then el:Cancel(); callback() end
    end
    function el:Start() remaining = dur; el:Handle("OnUpdate", interval) end
    function el:Cancel() el:Handle("OnUpdate", nil) end
    return el
  end,

  start = function(dur,callback)
    local timer = Timer.create(dur,callback); timer:Start(); return timer
  end

} end

-- ani = Animate.create({duration=1, cb=callbackfn, after=afterfn})
-- ani:Start()
-- ani:Cancel()

if not Animate then Animate = {

    updateSolidColor = function(el,to,from)
      from = from or el.texture:SolidColor()
      return function(p)el:SetSolidColor(unpack(Animate.interpolate(from,to,p))) end
    end,

    updateAlpha = function(el,to,from)
      from = from or el:Alpha()
      return function(p)el:SetAlpha(Animate.interpolate(from,to,p)) end
    end,
    
    round = function(val, digits)
        local precision = digits or 0
        shift = 10^precision
        return math.floor(val*shift + 0.5) / shift
    end,

    interpolate = function(source, target, pos, precision)
        local function interp(s,t,p) return Animate.round(s+(t-s)*p,precision or 3) end
        if type(source) == 'number' then return interp(source,target,pos)
        elseif type(source) == 'table' then  -- if color, do interpolation for each number
            t = {}
            for i,v in pairs(source) do
                t[i] = interp(source[i],target[i],pos)
            end
            return t
        end
    end,
    
    create = function(opts)
      local dur = opts.duration or 0.2 -- secs
      local easing = opts.easing or function(pos) return (-math.cos(pos*math.pi)/2 + 0.5); end--sigmoid
      local cb = opts.cb or nil -- function callback
      local after = opts.after or nil
      local remaining = dur
      local el = Region('region', 'timer', UIParent)
      local function interval(el, elapsed)
          remaining = remaining - elapsed
          local pos = (dur-remaining)/dur; if pos > 1 then pos = 1 end
          if cb then cb(pos) end
          if pos >= 1 then
              el:Cancel()
              if after then after(el) end
          end
      end
      
      function el:Cancel() el:Handle("OnUpdate", nil) end
      function el:Start() remaining = dur; el:Handle("OnUpdate", interval) end
      
      return el
    end,
    
    start = function(opts)
      local anim = Animate.create(opts); anim:Start(); return anim
    end
    
} end
