
tonehole = {}

backdrop = Region('region', 'toneholes', UIParent)
backdrop:SetWidth(ScreenWidth())
backdrop:SetHeight(ScreenHeight())
backdrop:SetAnchor('BOTTOMLEFT', 0,0)
backdrop.t=backdrop:Texture()
backdrop.t:SetTexture(0,0,0,255)
backdrop:Show()

local log = math.log

local whitepitch = {}
whitepitch[1] = 12.0/96.0*log(261.6/55)/log(2) -- C
whitepitch[2] = 12.0/96.0*log(293.67/55)/log(2)
whitepitch[3] = 12.0/96.0*log(329.63/55)/log(2) -- E
whitepitch[4] = 12.0/96.0*log(349.23/55)/log(2)
whitepitch[5] = 12.0/96.0*log(392.00/55)/log(2)
whitepitch[6] = 12.0/96.0*log(440.0/55)/log(2)
whitepitch[7] = 12.0/96.0*log(493.88/55)/log(2)
whitepitch[8] = 12.0/96.0*log(523.25/55)/log(2)

local toneholestate = {}
toneholestate[1] = 0
toneholestate[2] = 0
toneholestate[3] = 0

function ChangePitch()
	local pushflowbox = _G["FBPush"]
	local index = toneholestate[1] + 2*toneholestate[2] + 4*toneholestate[3]
	if pushflowbox.instances and pushflowbox.instances[1] then
		pushflowbox.instances[1]:Push(whitepitch[index+1])
		if pushflowbox.instances[2] then
			pushflowbox.instances[2]:Push(1.0)
		end
	end
end

function Playtonehole(self)
	toneholestate[self.key] = 1 -- Could do partial holing here
	ChangePitch()
end

function Releasetonehole(self)
	toneholestate[self.key] = 0 -- Could do partial holing here
	ChangePitch()
end

for i = 1,3 do
	tonehole[i] = Region('region', 'toneholes', UIParent)
	tonehole[i]:SetWidth(128)
	tonehole[i]:SetHeight(128)
	tonehole[i]:SetLayer("HIGH")
	tonehole[i]:SetAnchor('BOTTOMLEFT',ScreenWidth()/2-64,(128+24)*(i-1)+24)
	tonehole[i]:EnableClamping(true)
	tonehole[i]:EnableInput(true)
	tonehole[i].t = tonehole[i]:Texture()
	tonehole[i].t:SetTexture("Button-128-blurred.png")
	tonehole[i].t:SetBlendMode("ADD")
	tonehole[i]:Handle("OnTouchDown", Playtonehole)
--	tonehole[i]:Handle("OnEnter", Playtonehole)
	tonehole[i]:Handle("OnTouchUp", Releasetonehole)
--	tonehole[i]:Handle("OnLeave", Releasetonehole)
	tonehole[i].key = i
	tonehole[i]:Show()
end

--[[function FlipPage(self)
	if not padsloaded then
		SetPage(5)
		dofile(SystemPath("urPads.lua"))
		padsloaded = true
	else
		SetPage(5);
	end
end--]]

pagebutton=Region('region', 'pagebutton', UIParent);
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

