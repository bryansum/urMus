
local fingerposx, fingerposy = InputPosition()
local random = math.random
local dopaint = false
function Paint(self)
	if not dopaint then
		for i=1,10 do
			brush1.t:SetBrushSize(random(1,16));
			self.texture:SetBrushColor(random(0,255),random(0,255),random(0,255),random(1,60))
			self.texture:Point(random(0,ScreenWidth()),random(0,ScreenHeight()))
		end
		return
	end
	local x,y = InputPosition()
	x = x*320.0/ScreenWidth() -- Converting texture to screen coordinates (requires for iPad as they mismatch there)
	y = y*480.0/ScreenHeight()
	if x ~= fingerposx or y ~= fingerposy then
		brush1.t:SetBrushSize(32)
		y = y + 32
--		brush1.t:SetBrushSize(16)
--		self.texture:SetBrushColor(255,127,0,60)
--		self.texture:Point(x, y)
		self.texture:SetBrushColor(255,127,0,30)
		self.texture:Line(fingerposx, fingerposy, x, y)
		fingerposx, fingerposy = x,y
	end
end

function BrushDown(self)
	dopaint = true
	fingerposx, fingerposy = InputPosition()
	fingerposx = fingerposx*320.0/ScreenWidth() -- Converting texture to screen coordinates (requires for iPad as they mismatch there)
	fingerposy = fingerposy*480.0/ScreenHeight()
end

function BrushUp(self)
	dopaint = false
end

function Clear(self)
	smudgebackdropregion.texture:Clear(1,1,1);
end

smudgebackdropregion=Region('region', 'smudgebackdropregion', UIParent);
smudgebackdropregion:SetWidth(ScreenWidth());
smudgebackdropregion:SetHeight(ScreenHeight());
smudgebackdropregion:SetLayer("BACKGROUND");
smudgebackdropregion:SetAnchor('BOTTOMLEFT',0,0); 
--smudgebackdropregion:EnableClamping(true)
smudgebackdropregion.texture = smudgebackdropregion:Texture("Default.png");
smudgebackdropregion.texture:SetGradientColor("TOP",255,255,255,255,255,255,255,255);
smudgebackdropregion.texture:SetGradientColor("BOTTOM",255,255,255,255,255,255,255,255);
--smudgebackdropregion.texture:SetBlendMode("BLEND")
smudgebackdropregion.texture:SetTexCoord(0,0.63,0.94,0.0);
smudgebackdropregion:Handle("OnUpdate", Paint);
smudgebackdropregion:Handle("OnDoubleTap", Clear);
smudgebackdropregion:Handle("OnTouchDown", BrushDown)
smudgebackdropregion:Handle("OnTouchUp", BrushUp)
smudgebackdropregion:EnableInput(true);
smudgebackdropregion:Show();
--smudgebackdropregion.texture:Clear(0.8,0.8,0.8);

--smudgebackdropregion.texture:ClearBrush()
--smudgebackdropregion.texture:SetBrushSize(1)
smudgebackdropregion.texture:SetFill(true)
smudgebackdropregion.texture:SetBrushColor(0,0,255,30)
smudgebackdropregion.texture:Ellipse(160, 240, 120, 120)
smudgebackdropregion.texture:SetBrushColor(255,0,0,90)
smudgebackdropregion.texture:Rect(40,40,100,100)
smudgebackdropregion.texture:SetFill(false)
smudgebackdropregion.texture:SetBrushColor(0,255,0,60)
smudgebackdropregion.texture:Quad(320-20,480-20,320-300,480-40,320-40,480-400,320-290,480-390)

brush1=Region('region','brush',UIParent)
brush1.t=brush1:Texture()
brush1.t:SetTexture("circlebutton-16.png");
brush1.t:SetSolidColor(127,0,0,15)
brush1:UseAsBrush();

smudgebackdropregion.texture:SetBrushColor(0,0,255,30)
smudgebackdropregion.texture:Ellipse(320-160, 480-240, 120, 80)
smudgebackdropregion.texture:SetBrushColor(0,255,0,60)
smudgebackdropregion.texture:Quad(20,20,300,40,40,400,290,390)
smudgebackdropregion.texture:SetBrushColor(255,0,0,90)
smudgebackdropregion.texture:Rect(320-40-100,480-40-100,100,100)

smudgebackdropregion.texture:SetBrushColor(255,127,0,30)

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
