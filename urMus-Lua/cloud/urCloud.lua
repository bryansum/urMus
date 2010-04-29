dofile(SystemPath("urHelpers.lua"))
Req('urAnimate')

local bg = MakeRegion({w=320,h=480,img='cloud_bg.jpg',layer='MEDIUM',input=false})

-- where the drops should stop and start, respectively
local bottom_x = 62
local top_x = 230

dac = _G["FBDac"]

function MakeFB(wav)
  local plick = FlowBox("object","plick", FBSample)
  plick:AddFile(wav..".wav")

  local pusher = FlowBox("object", "mypush", FBPush)

  pusher:SetPushLink(0,plick, 4)  
  pusher:Push(-1.0); -- Turn looping off
  pusher:RemovePushLink(0,plick, 4)  
  pusher:SetPushLink(0,plick, 2)
  pusher:Push(1.0); -- Set position to end so nothing plays.
  dac:SetPullLink(0, plick, 0)
  
  function pusher:Play()
    self:Push(0.0)
  end
  return pusher
end

function MakeSample(wav, pusher)
  local plick = FlowBox("object","plick", FBSample)
  plick:AddFile(wav..".wav")

  pusher:SetPushLink(0,plick, 4)  
  pusher:Push(-1.0); -- Turn looping off
  pusher:RemovePushLink(0,plick, 4)  
  pusher:SetPushLink(0,plick, 2)
  pusher:Push(1.0); -- Set position to end so nothing plays.
  
  return plick
end

sound1 = MakeFB("Plick")

function MakeDrop(y)
  local r = math.random(3)
  local dim = {{33,27},{34,19},{26,19}} -- dimensions of the three cloud images
  return MakeRegion({w=dim[r][1],h=dim[r][2],img='cloud-drop'..r..'.png',x=top_x,y=y})
end

looper = _G["FBLoopRhythm"]

bpmPush = FlowBox("object","mypush",FBPush)
bpmPush:SetPushLink(0,looper,0) -- BPM settings

nowPush = FlowBox("object","mypush",FBPush)
nowPush:SetPushLink(0,looper,0) -- BPM settings

sound1 = MakeFB("Plick")

    
-- for i=1,50 do
--   local d = MakeDrop(math.random(480))
--   d:SetAlpha(0)
--   Timer.start(math.random()*25,function()
--     d:SetAlpha(1)
--     local anim = Animate.start({
--       duration=2,
--       cb=function(pos) SetAttrs(d,{x=Animate.interpolate(top_x,bottom_x,pos)}) end,
--       after=function() 
--         d:SetAlpha(0) 
--         sound1:Play() -- Play
--       end
--     })
--   end)
-- end

SetFrameRate(1.0/50.0)
StartAudio()
