
local random = math.random

local vis = _G["FBVis"]

local lastx = 320/2
local lasty = 480

function Paint(self)
	local visout = vis:Get()
	local x = 320/2 + vis:Get()*320/2
--	visgraphbackdropregion.tl:SetLabel(vis:Get())
	self.texture:SetBrushColor(0,0,0,255)
	self.texture:Line(lastx, lasty, x, lasty+1)
	lasty = lasty + 1
	if lasty > 480 then
		self.texture:Clear(1,1,1)
		lasty = 0
	end
end

function Clear(self)
	visgraphbackdropregion.texture:Clear(1,1,1)
end

visgraphbackdropregion=Region('region', 'visgraphbackdropregion', UIParent)
visgraphbackdropregion:SetWidth(ScreenWidth())
visgraphbackdropregion:SetHeight(ScreenHeight())
visgraphbackdropregion:SetLayer("BACKGROUND")
visgraphbackdropregion:SetAnchor('BOTTOMLEFT',0,0)
--visgraphbackdropregion:EnableClamping(true)
visgraphbackdropregion.texture = visgraphbackdropregion:Texture("Default.png")
visgraphbackdropregion.texture:SetGradientColor("TOP",255,255,255,255,255,255,255,255)
visgraphbackdropregion.texture:SetGradientColor("BOTTOM",255,255,255,255,255,255,255,255)
--visgraphbackdropregion.texture:SetBlendMode("BLEND")
visgraphbackdropregion.texture:SetTexCoord(0,0.63,0.94,0.0)
visgraphbackdropregion:Handle("OnUpdate", Paint)
visgraphbackdropregion:Handle("OnDoubleTap", Clear)
visgraphbackdropregion:EnableInput(true)
visgraphbackdropregion:Show()
--visgraphbackdropregion.tl = visgraphbackdropregion:TextLabel()
--visgraphbackdropregion.tl:SetFont("Trebuchet MS")
--visgraphbackdropregion.tl:SetHorizontalAlign("LEFT")
--visgraphbackdropregion.tl:SetLabelHeight(30)
--visgraphbackdropregion.tl:SetColor(0,0,255,255)

visgraphbackdropregion.texture:Clear(1,1,1)
visgraphbackdropregion.texture:ClearBrush()

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
