-- urBounce bounce bounce
-- Hack by Edgar Bee Watson & Jong Wook Kim
-- Minor tweaks by Georg Essl
-- Created 5/28/2010

local damping = 0.9


local ball = {}
local amount = 25
local width = 100
local height = width
local velocity = 2

function UpdateBallPosition(self)
  self.x = self.x + self.vx
  self.y = self.y + self.vy
   --self.x = self.x % (ScreenWidth()-self.width)
   --self.y = self.y % (ScreenHeight()-self.height)
   if(self.x < 0) then
       self.vx = math.abs(self.vx)*damping
   end
   if(self.y < 0) then
       self.vy = math.abs(self.vy)*damping
   end
   if(self.x > ScreenWidth()-width) then
       self.vx = -math.abs(self.vx)*damping
   end
   if(self.y > ScreenHeight()-height) then
       self.vy = -math.abs(self.vy)*damping
   end
   self:SetAnchor('BOTTOMLEFT', self.x , self.y)

  r=math.random()*255
  g=math.random()*255
  b=math.random()*255
  a=255
  self.texture:SetGradientColor("TOP", r, g, b, a, r, g, b, a)
end

function AccelerateBall(self,x,y,z)
   self.vx = self.vx + x
   self.vy = self.vy + y
end


for x = 1, amount do
  ball[x] = Region('Region', 'ball', UIParent)
  ball[x]:SetLayer("HIGH")
  ball[x]:SetWidth(width)
  ball[x]:SetHeight(height)
  ball[x].x=0
  ball[x].y=0
   ball[x].width=ball[x]:Width()
   ball[x].height=ball[x]:Height()

  ball[x].x=math.random()*ScreenWidth()
  ball[x].y=math.random()*ScreenHeight()
  ball[x].vx=math.random(-velocity, velocity)
  ball[x].vy=math.random(-velocity, velocity)
  ball[x]:SetAnchor("CENTER",ball[x].x,ball[x].y)

  ball[x].texture = ball[x]:Texture("small-ball.png")
  ball[x].texture:SetBlendMode("BLEND")
  ball[x]:Handle("OnUpdate",UpdateBallPosition)
   ball[x]:Handle("OnAccelerate",AccelerateBall)
  ball[x]:Show()
end

local pagebutton=Region('region', 'pagebutton', UIParent);
pagebutton:SetWidth(pagersize);
pagebutton:SetHeight(pagersize);
pagebutton:SetLayer("TOOLTIP");
pagebutton:SetAnchor('BOTTOMLEFT',ScreenWidth()-pagersize-4,ScreenHeight()-pagersize-4); 
pagebutton:EnableClamping(true)
--pagebutton:Handle("OnDoubleTap", FlipPage)
pagebutton:Handle("OnTouchDown", FlipPage)
pagebutton.texture = pagebutton:Texture("circlebutton-16.png");
pagebutton.texture:SetGradientColor("TOP",255,255,255,255,255,255,255,255);
pagebutton.texture:SetGradientColor("BOTTOM",255,255,255,255,255,255,255,255);
pagebutton.texture:SetBlendMode("BLEND")
pagebutton.texture:SetTexCoord(0,1.0,0,1.0);
pagebutton:EnableInput(true);
pagebutton:Show();
