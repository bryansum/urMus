-- simple urMus Piano
-- example of separation of flow semantics and interface
-- also example of pseudo-force input via accelerometer and optional external FSR input
--
-- Create a really long time ago
-- Hacked by Georg Essl
-- Last modified: 02/11/2010

local accelerates = {}
local accelpos = 1
local accelregions = 5
for i=1,accelregions do
	accelerates[i] = 0
end
local averageaccel = 0
local absaverageaccel = 0
local daccel = 0

local abs = math.abs
local sqrt = math.sqrt
local findmax = false
local findcnt = 0

function CollectAveragePressure(self, p)
--	DPrint(p)
	daccel = (1024.0-p)/1024.0/50.0
	return
end

function CollectAverageAccel(self,x,y,z)
	accelerates[accelpos] = z -- sqrt(x*x+y*y+z*z)-1.0
	accelpos = accelpos + 1
	if accelpos > accelregions then
		accelpos = 1
	end
	local tmp = 0
	local tmp2 = 0
	for i=1,accelregions do
		tmp = tmp + accelerates[i]
	end
	daccel = abs(tmp/accelregions - averageaccel)
	if findmax and tmp/accelregions - averageaccel < 0 then
--		DPrint("max: ".. averageaccel.." "..findcnt.." "..daccel)
		findmax = false
		findcnt = 0
	elseif findmax then
		findcnt = findcnt + 1
--		DPrint(findcnt.." "..tmp/accelregions - averageaccel)
	end
	averageaccel = tmp/accelregions
end

pianoregion=Region('region', 'pianoregion', UIParent);
pianoregion:SetWidth(ScreenWidth());
pianoregion:SetHeight(ScreenHeight());
pianoregion:SetLayer("FULLSCREEN");
pianoregion:SetAnchor('BOTTOMLEFT',0,0); 
pianoregion.texture = pianoregion:Texture("piano.png");
pianoregion.texture:SetGradientColor("TOP",255,255,255,255,255,255,255,255);
pianoregion.texture:SetGradientColor("BOTTOM",255,255,255,255,255,255,255,255);
pianoregion.texture:SetTexCoord(0,0.63,0.94,0.0);
pianoregion:Handle("OnAccelerate", CollectAverageAccel)
--pianoregion:Handle("OnPressure", CollectAveragePressure)
pianoregion:Show();

local log = math.log

local whitepitch = {}
whitepitch[8] = 12.0/96.0*log(261.6/55)/log(2) -- C
whitepitch[7] = 12.0/96.0*log(293.67/55)/log(2)
whitepitch[6] = 12.0/96.0*log(329.63/55)/log(2) -- E
whitepitch[5] = 12.0/96.0*log(349.23/55)/log(2)
whitepitch[4] = 12.0/96.0*log(392.00/55)/log(2)
whitepitch[3] = 12.0/96.0*log(440.0/55)/log(2)
whitepitch[2] = 12.0/96.0*log(493.88/55)/log(2)
whitepitch[1] = 12.0/96.0*log(523.25/55)/log(2)

local blackpitch = {}
blackpitch[6] = 12.0/96.0*log(277.18/55)/log(2)
blackpitch[5] = 12.0/96.0*log(311.13/55)/log(2)
blackpitch[4] = 12.0/96.0*log(369.99/55)/log(2)
blackpitch[3] = 12.0/96.0*log(415.30/55)/log(2)
blackpitch[2] = 12.0/96.0*log(466.16/55)/log(2)
blackpitch[1] = 12.0/96.0*log(554.37/55)/log(2)

function FadeRegion(self, elapsed)
	if self.staytime > 0 then
		self.staytime = self.staytime - elapsed
		return
	end
	if self.fadetime > 0 then
		self.fadetime = self.fadetime - elapsed
		self.alpha = self.alpha - self.alphaslope * elapsed
		self:SetAlpha(self.alpha)
	else
		self:Hide()
		self:Handle("OnUpdate", nil)
	end
end

function PlayWhiteKey(self)
	local pushflowbox = _G["FBPush"]
	
--	DPrint(daccel*50.0)
	findcnt = 0
	findmax = true

	if pushflowbox.instances and pushflowbox.instances[1]  then
		pushflowbox.instances[1]:Push(whitepitch[self.key])
		if pushflowbox.instances[2] then
			pushflowbox.instances[2]:Push(daccel*50.0+0.2)
		end
	end
	self:SetAlpha(0.5)
	self:Handle("OnUpdate", nil)
	self:Show()
end

function ReleaseWhiteKey(self)
	self:Handle("OnUpdate", nil)
	self.staytime = 0.05
	self.fadetime = 0.25
	self.alpha = 0.5
	self.alphaslope = 2
	self:Handle("OnUpdate", FadeRegion)
end

function PlayBlackKey(self)
	local pushflowbox = _G["FBPush"]

--	DPrint(daccel)
	if pushflowbox.instances and pushflowbox.instances[1] then
		pushflowbox.instances[1]:Push(blackpitch[self.key])
		if pushflowbox.instances[2] then
			pushflowbox.instances[2]:Push(daccel*50.0+0.2)
		end
	end
	self:SetAlpha(0.5)
	self:Handle("OnUpdate", nil)
	self:Show()
end

function ReleaseBlackKey(self)
	self:Handle("OnUpdate", nil)
	self.staytime = 0.05
	self.fadetime = 0.25
	self.alpha = 0.5
	self.alphaslope = 2
	self:Handle("OnUpdate", FadeRegion)
end

whitekey = {}
for i=1,8 do
	whitekey[i] = Region('region', 'whitekeys', pianoregion);
	whitekey[i]:SetWidth(ScreenWidth());
	whitekey[i]:SetHeight((ScreenHeight()-32)/8);
	whitekey[i]:SetLayer("FULLSCREEN_DIALOG");
	whitekey[i]:SetAnchor('BOTTOMLEFT',0,(ScreenHeight()-32)/8*(i-1)+32); 
	whitekey[i]:EnableClamping(true)
	whitekey[i]:EnableInput(true)
	whitekey[i].t = whitekey[i]:Texture()
	whitekey[i].t:SetTexture(255,255,128,190)
	whitekey[i].t:SetBlendMode("BLEND")
	whitekey[i]:Handle("OnTouchDown", PlayWhiteKey)
	whitekey[i]:Handle("OnEnter", PlayWhiteKey)
	whitekey[i]:Handle("OnTouchUp", ReleaseWhiteKey)
	whitekey[i]:Handle("OnLeave", ReleaseWhiteKey)
	whitekey[i].key = i
end

blackkeyindex = {1.1,2.9,4.05,5.1,6.95,8.15}
blackkey = {}
for i=1,6 do
	blackkey[i] = Region('region', 'blackkeys', pianoregion)
	blackkey[i]:SetWidth(ScreenWidth()/2.7*2)
	blackkey[i]:SetHeight((ScreenHeight()-32)/8/2)
	blackkey[i]:SetLayer("FULLSCREEN_DIALOG")
	blackkey[i]:SetAnchor('BOTTOMLEFT',ScreenWidth()/2.7,(ScreenHeight()-32)/8*(blackkeyindex[i]-1)+32-16)
	blackkey[i]:EnableClamping(true)
	blackkey[i]:EnableInput(true)
	blackkey[i].t = blackkey[i]:Texture()
	blackkey[i].t:SetTexture(255,255,128,190)
	blackkey[i].t:SetBlendMode("BLEND")
	blackkey[i]:Handle("OnTouchDown", PlayBlackKey)
	blackkey[i]:Handle("OnEnter", PlayBlackKey)
	blackkey[i]:Handle("OnTouchUp", ReleaseBlackKey)
	blackkey[i]:Handle("OnLeave", ReleaseBlackKey)
	blackkey[i].key = i
end

pagebutton=Region('region', 'pagebutton', UIParent);
pagebutton:SetWidth(pagersize);
pagebutton:SetHeight(pagersize);
pagebutton:SetLayer("TOOLTIP");
pagebutton:SetAnchor('BOTTOMLEFT',ScreenWidth()-pagersize-4,ScreenHeight()-pagersize-4); 
pagebutton:EnableClamping(true)
pagebutton:Handle("OnTouchDown", FlipPage)
pagebutton.texture = pagebutton:Texture("circlebutton-16.png");
pagebutton.texture:SetGradientColor("TOP",255,255,255,255,255,255,255,255);
pagebutton.texture:SetGradientColor("BOTTOM",255,255,255,255,255,255,255,255);
pagebutton.texture:SetBlendMode("BLEND")
pagebutton.texture:SetTexCoord(0,1.0,0,1.0);
pagebutton:EnableInput(true);
pagebutton:Show();
