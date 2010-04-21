
local random = math.random
function Paint(self)
	local x,y = InputPosition()
	local x2,y2
	
	x2 = x - self:Left()
	y2 = y - self:Bottom()
	x2 = 2*x2
	y2 = 2*y2

	if not self.moving and x >= self:Left() and x < self:Right() and y >= self:Bottom() and y < self:Top()  then
		if x2 ~= self.fingerposx or y2 ~= self.fingerposy then
--			brush1.t:SetBrushSize(32);
--			self.texture:SetBrushColor(255,127,0,30)
			self.texture:Line(self.fingerposx, self.fingerposy, x2, y2)
		end
	end

	self.fingerposx, self.fingerposy = x2, y2
end

function Clear(self)
	self.texture:Clear(1,1,1);
end

function ToggleMovable(self)
	if self.moving then
		self:EnableMoving(false)
		self.texture:SetBrushColor(random(0,255),random(0,255),random(0,255),random(5,50))
		self.moving = nil
	else
		self:EnableMoving(true)
		self.moving = true
	end
end

tilebackdropregion = {}
for y=1,2 do
	for x=1,2 do
		local i = (x-1)*2+y
		tilebackdropregion[i]=Region('region', 'tilebackdropregion[i]', UIParent)
		tilebackdropregion[i]:SetWidth(ScreenWidth()/2)
		tilebackdropregion[i]:SetHeight(ScreenHeight()/2)
		tilebackdropregion[i]:SetLayer("BACKGROUND")
		tilebackdropregion[i]:SetAnchor('BOTTOMLEFT',(x-1)*ScreenWidth()/2,(y-1)*ScreenHeight()/2)
		tilebackdropregion[i]:EnableClamping(true)
		tilebackdropregion[i]:EnableMoving(false)
		tilebackdropregion[i].texture = tilebackdropregion[i]:Texture("Default.png");
		tilebackdropregion[i].texture:SetGradientColor("TOP",255,255,255,255,255,255,255,255);
		tilebackdropregion[i].texture:SetGradientColor("BOTTOM",255,255,255,255,255,255,255,255);
		--tilebackdropregion[i].texture:SetBlendMode("BLEND")
		tilebackdropregion[i].texture:SetTexCoord(0,0.63,0.94,0.0);
		tilebackdropregion[i]:Handle("OnUpdate", Paint);
		tilebackdropregion[i]:Handle("OnDoubleTap", ToggleMovable);
		tilebackdropregion[i]:EnableInput(true);
		tilebackdropregion[i]:Show();
		tilebackdropregion[i].texture:SetBrushColor(255,127,0,30)
		tilebackdropregion[i].fingerposx, tilebackdropregion[i].fingerposy = InputPosition()
	end
end
--tilebackdropregion[i].texture:Clear(0.8,0.8,0.8);
--tilebackdropregion[i].texture:SetBrushColor(0,0,255,30)
--tilebackdropregion[i].texture:Ellipse(160, 240, 120, 120)
--tilebackdropregion[i].texture:SetBrushColor(0,255,0,60)
--tilebackdropregion[i].texture:Quad(20,20,300,40,40,400,290,390)
--tilebackdropregion[i].texture:SetBrushColor(255,0,0,90)
--tilebackdropregion[i].texture:Rect(40,40,100,100)

brush1=Region('region','brush',UIParent)
brush1.t=brush1:Texture()
brush1.t:SetTexture("circlebutton-16.png");
brush1.t:SetSolidColor(127,0,0,15)
brush1:UseAsBrush();

--tilebackdropregion[i].texture:SetBrushColor(0,0,255,30)
--tilebackdropregion[i].texture:Ellipse(320-160, 480-240, 120, 80)
--tilebackdropregion[i].texture:SetBrushColor(0,255,0,60)
--tilebackdropregion[i].texture:Quad(320-20,480-20,320-300,480-40,320-40,480-400,320-290,480-390)
--tilebackdropregion[i].texture:SetBrushColor(255,0,0,90)
--tilebackdropregion[i].texture:Rect(320-40-100,480-40-100,100,100)

--tilebackdropregion[i].texture:SetBrushColor(255,127,0,30)

brush1.t:SetBrushSize(32);

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
