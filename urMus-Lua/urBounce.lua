-- urBounce bounce bounce
-- Hack by Edgar Bee Watson & Jong Wook Kim
-- Minor tweaks by Georg Essl
-- Created 5/28/2010

local damping = 0.9



damping = 0.9
size = 48
amount = 50
active = 20
mode = 0
speed = 0.8
threshold = 0.02
visout = 0.0

ball = {}

function UpdateBounce(self)
    if(self.active==false) then
        return
    end
    self.x = self.x + self.vx
    self.y = self.y + self.vy
    
    if(self.x < 0) then
        self.x=0
        self.vx = math.abs(self.vx)*damping
    end
    if(self.y < 0) then
        self.y=0
        self.vy = math.abs(self.vy)*damping
    end
    if(self.x > ScreenWidth()-self.width) then
        self.x = ScreenWidth()-self.width
        self.vx = -math.abs(self.vx)*damping
    end
    if(self.y > ScreenHeight()-self.height) then
        self.y = ScreenHeight()-self.height
        self.vy = -math.abs(self.vy)*damping
    end
    self:SetAnchor('BOTTOMLEFT', self.x , self.y)
    
    r=math.random()*255
    g=math.random()*255
    b=math.random()*255
    a=255
    self.texture:SetGradientColor("TOP", r, g, b, a, r, g, b, a)
end

function UpdateSnake(self)
    x,y= InputPosition()
    if self.prev then
        self.x=self.x * speed + self.prev.x * (1-speed)
        self.y=self.y * speed + self.prev.y * (1-speed)
    else
        self.x=self.x * speed + x * (1-speed)
        self.y=self.y * speed + y * (1-speed)
    end
    
    self:SetAnchor('BOTTOMLEFT', self.x , self.y)
    
    r=math.random()*255
    g=math.random()*255
    b=math.random()*255
    a=255
    self.texture:SetGradientColor("TOP", r, g, b, a, r, g, b, a)
end

function UpdateBubble(self)
    if self.active==false then
		if math.random()<threshold*visout then
            self.active=true    
            self.x=ScreenWidth()/2
            self.y=0
            self.vx=0
            self.vy=visout*10
            self:Show()        
        end
    else
        self.x = self.x + self.vx
        self.vx = self.vx + (math.random()-0.5)
        self.y = self.y + self.vy
        self.vy = self.vy + 0.1
        if self.y >= ScreenHeight() then
            self.active=false
            self:Hide()
        end
    end
    
    self:SetAnchor('BOTTOMLEFT', self.x , self.y)
    
    r=math.random()*255
    g=math.random()*255
    b=math.random()*255
    a=255
    self.texture:SetGradientColor("TOP", r, g, b, a, r, g, b, a)
end

function UpdateMic(self)
    visout=_G["FBVis"]:Get()
end

function AccelerateBall(self,x,y,z) 
    self.vx = self.vx + x
    self.vy = self.vy + y
end

function DoubleTap(self)
    if mode==0 then
        mode=1
        for x = 1,amount do
			if x<active then
				ball[x].active=true
				ball[x]:Show()
			else
				ball[x].active=false
				ball[x]:Hide()
			end
			ball[x]:Handle("OnUpdate",UpdateSnake)
		end
    elseif mode==1 then
        mode=2
        for x = 1,amount do
			self.vx=0
			self.vy=0
			ball[x]:Handle("OnUpdate",UpdateBubble)
		end
    else
        mode=0
        for x = 1,amount do
			if x<active then
				ball[x].active=true
				ball[x]:Show()
			else
				ball[x].active=false
				ball[x]:Hide()
			end
			ball[x].x=math.random()*(ScreenWidth()-size)
			ball[x].y=math.random()*(ScreenHeight()-size)
			ball[x].vx=math.random(-2,2)
			ball[x].vy=math.random(-2,2)
			ball[x]:Handle("OnUpdate",UpdateBounce)
		end
    end
end

for x = 1,amount do
    ball[x] = Region('Region', 'ball', UIParent)
    ball[x]:SetLayer("TOOLTIP")
    ball[x]:SetWidth(size)
    ball[x]:SetHeight(size)
    ball[x].width=size
    ball[x].height=size
    if x <= active then
        ball[x].active=true
		ball[x]:Show()
    else
        ball[x].active=false
		ball[x]:Hide()
    end
    if x>1 then
        ball[x].prev=ball[x-1]
    end
    
    ball[x].x=math.random()*(ScreenWidth()-size)
    ball[x].y=math.random()*(ScreenHeight()-size)
    ball[x].vx=math.random(-2,2)
    ball[x].vy=math.random(-2,2)
    ball[x]:SetAnchor("BOTTOMLEFT",ball[x].x,ball[x].y)
    
    ball[x].texture = ball[x]:Texture("small-ball.png")
	ball[x].texture:SetTexCoord(0.0,0.64,0.0,0.64)
    ball[x].texture:SetBlendMode("BLEND")
    ball[x]:Handle("OnUpdate",UpdateBounce)
    ball[x]:Handle("OnAccelerate",AccelerateBall)
end


_G["FBMic"]:SetPushLink(0,_G["FBVis"],0)

backdrop = Region('Region','backdrop',UIParent)
backdrop:SetWidth(ScreenWidth());
backdrop:SetHeight(ScreenHeight());
backdrop:SetAnchor("BOTTOMLEFT",0,0)
backdrop:EnableInput(true)
backdrop:Handle("OnUpdate",UpdateMic)
backdrop:Handle("OnDoubleTap",DoubleTap)


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
