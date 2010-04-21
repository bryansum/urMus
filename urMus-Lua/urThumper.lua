-- urThumper
-- Concept by: Colin Zyskowski
-- Initial Hack by: Georg Essl 11/19/09

local function Shutdown()
	dac:RemovePullLink(0, utSinOscA1, 0)
	dac:RemovePullLink(0, utSinOscB1, 0)
end

local function ReInit(self)
	dac:SetPullLink(0, utSinOscA1, 0)
	dac:SetPullLink(0, utSinOscB1, 0)
end

thumperbackdropregion=Region('region', 'thumperbackdropregion', UIParent);
thumperbackdropregion:SetWidth(ScreenWidth());
thumperbackdropregion:SetHeight(ScreenHeight());
thumperbackdropregion:SetLayer("BACKGROUND");
thumperbackdropregion:SetAnchor('BOTTOMLEFT',0,0); 
--thumperbackdropregion:EnableClamping(true)
thumperbackdropregion.texture = thumperbackdropregion:Texture("thumper.png");
thumperbackdropregion.texture:SetGradientColor("TOP",255,255,255,255,255,255,255,255);
thumperbackdropregion.texture:SetGradientColor("BOTTOM",255,255,255,255,255,255,255,255);
--thumperbackdropregion.texture:SetBlendMode("BLEND")
thumperbackdropregion.texture:SetTexCoord(0,0.63,0.94,0.0);
--thumperbackdropregion:EnableInput(true);
thumperbackdropregion:Show();
thumperbackdropregion:Handle("OnPageEntered", ReInit)
thumperbackdropregion:Handle("OnPageLeft", Shutdown)

local log = math.log
local pitch = {}
pitch[13] = 12.0/96.0*log(261.6/55)/log(2) -- C
pitch[12] = 12.0/96.0*log(277.18/55)/log(2) -- #
pitch[11] = 12.0/96.0*log(293.67/55)/log(2)
pitch[10] = 12.0/96.0*log(311.13/55)/log(2) -- #
pitch[9] = 12.0/96.0*log(329.63/55)/log(2) -- E
pitch[8] = 12.0/96.0*log(349.23/55)/log(2)
pitch[7] = 12.0/96.0*log(369.99/55)/log(2) -- #
pitch[6] = 12.0/96.0*log(392.00/55)/log(2)
pitch[5] = 12.0/96.0*log(415.30/55)/log(2) -- #
pitch[4] = 12.0/96.0*log(440.0/55)/log(2)
pitch[3] = 12.0/96.0*log(466.16/55)/log(2) -- #
pitch[2] = 12.0/96.0*log(493.88/55)/log(2)
pitch[1] = 12.0/96.0*log(523.25/55)/log(2)
pitch[0] = 12.0/96.0*log(554.37/55)/log(2) -- #
--whitepitch[2] = 12.0/96.0*log(587.33/55)/log(2)
--whitepitch[1] = 12.0/96.0*log(659.26/55)/log(2)

-- Db F Gb Ab
-- Eb Gb Bb Db
-- F Ab Bb C
-- Eb Gb B Db
-- B Db E Ab
chordnote = {}
chordnote[1] = 12.0/96.0*log(415.3046975799/55)/log(2) -- Ab
chordnote[2] = 12.0/96.0*log(349.2282314330/55)/log(2) -- F
chordnote[3] = 12.0/96.0*log(277.1826309769/55)/log(2) -- Db
chordnote[4] = 12.0/96.0*log(369.9944227116/55)/log(2) -- Gb
chordnote[5] = 12.0/96.0*log(311.1269837221/55)/log(2) -- Eb
chordnote[6] = 12.0/96.0*log(466.1637615181/55)/log(2) -- Bb
chordnote[7] = 12.0/96.0*log(261.6255653006/55)/log(2) -- C
chordnote[8] = 12.0/96.0*log(349.2282314330/55)/log(2) -- F
chordnote[9] = 12.0/96.0*log(493.8833012561/55)/log(2) -- B
chordnote[10] = 12.0/96.0*log(311.1269837221/55)/log(2) -- Eb
chordnote[11] = 12.0/96.0*log(277.1826309769/55)/log(2) -- Db
chordnote[12] = 12.0/96.0*log(329.6275569129/55)/log(2) -- E

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

local gain = 0

function RampGainUp(self, time)
	if gain >= 1.0 then
		gain = 1.0
		self:Handle("OnUpdate", nil)
	else
		gain = gain + 0.005
	end

	utPushA3:Push(0.5) -- Gain of first partial
	utPushB3:Push(0.1) -- Gain of second partial
end

function RampGainDown(self, time)
	if gain <= 0.0 then
		gain = 0.0
		self:Handle("OnUpdate", nil)
	else
		gain = gain - 0.001
	end

	utPushA3:Push(0.0) -- Gain of first partial
	utPushB3:Push(0.0) -- Gain of second partial

--	utPushA3:Push(0.5*gain) -- Gain of first partial
--	utPushB3:Push(0.1*gain) -- Gain of second partial
end

function Playkey(self)
	local pushflowbox = _G["FBPush"]

	if pushflowbox.instances and pushflowbox.instances[1]  then
		pushflowbox.instances[1]:Push(pitch[self.key])
	end

	utPushA2:Push(chordnote[self.key])
	utPushB2:Push(chordnote[self.key]*2)
	
--	utPushA3:Push(0.5) -- Gain of first partial
--	utPushB3:Push(0.1) -- Gain of second partial

--	PushC2:Push(chordnote[self.key]*3)

	self:SetAlpha(0.5)
	utPushA3:Push(0.5) -- Gain of first partial
	utPushB3:Push(0.1) -- Gain of second partial
	gain = 0.0
	self:Handle("OnUpdate", RampGainUp)
	self:Show()
end

function Releasekey(self)
	self:Handle("OnUpdate", nil)
	self.staytime = 0.05
	self.fadetime = 0.25
	self.alpha = 0.5
	self.alphaslope = 2
--	self:Handle("OnUpdate", FadeRegion)
	utPushA3:Push(0.0) -- Gain of first partial
	utPushB3:Push(0.0) -- Gain of second partial
	gain = 1.0
	self:Handle("OnUpdate", RampGainDown)
	utPushA3:Push(0.0) -- Gain of first partial
	utPushB3:Push(0.0) -- Gain of second partial
--	utPushA3:Push(0.0) -- Gain of first partial
--	utPushB3:Push(0.0) -- Gain of second partial
end



key = {}
for k=1,6 do
	for j=1,2 do
		i = (3-j)+(k-1)*2
		key[i] = Region('region', 'keys', thumperbackdropregion);
		key[i]:SetWidth(59);
		key[i]:SetHeight(59);
		key[i]:SetLayer("LOW");
		key[i]:SetAnchor('BOTTOMLEFT',87+(j-1)*80,28+65*(k-1)); 
		key[i]:EnableClamping(true)
		key[i]:EnableInput(true)
		key[i].t = key[i]:Texture()
		key[i].t:SetTexture(255,255,255,255)
		key[i].t:SetBlendMode("MOD")
		key[i]:Handle("OnTouchDown", Playkey)
		key[i]:Handle("OnEnter", Playkey)
		key[i]:Handle("OnTouchUp", Releasekey)
		key[i]:Handle("OnLeave", Releasekey)
		key[i].key = i
	end
end



--[[function FlipPage(self)
	dac:RemovePullLink(0, utGainA, 0)
	dac:RemovePullLink(0, utGainB, 0)

	if not clockseqloaded then
		SetPage(9)
		dofile(SystemPath("urClockSeq.lua"))
		clockseqloaded = true
	else
		SetPage(9);
	end
end--]]

function ShutdownAndFlip(self)
	Shutdown()
	FlipPage(self)
end

pagebutton=Region('region', 'pagebutton', UIParent);
pagebutton:SetWidth(pagersize);
pagebutton:SetHeight(pagersize);
pagebutton:SetLayer("TOOLTIP");
pagebutton:SetAnchor('BOTTOMLEFT',ScreenWidth()-pagersize-4,ScreenHeight()-pagersize-4); 
pagebutton:EnableClamping(true)
--pagebutton:Handle("OnDoubleTap", FlipPage)
pagebutton:Handle("OnTouchDown", ShutdownAndFlip)
pagebutton.texture = pagebutton:Texture("circlebutton-16.png");
pagebutton.texture:SetGradientColor("TOP",255,255,255,255,255,255,255,255);
pagebutton.texture:SetGradientColor("BOTTOM",255,255,255,255,255,255,255,255);
pagebutton.texture:SetBlendMode("BLEND")
pagebutton.texture:SetTexCoord(0,1.0,0,1.0);
pagebutton:EnableInput(true);
pagebutton:Show();

if not utSinOscA1 then
--int("eek")
utSinOscA1 = FlowBox("object","utSinOscA1", _G["FBSinOsc"])
utSinOscA2 = FlowBox("object","utSinOscA2", _G["FBSinOsc"])
utSinOscB1 = FlowBox("object","utSinOscB1", _G["FBSinOsc"])
utSinOscB2 = FlowBox("object","utSinOscB2", _G["FBSinOsc"])
--SinOscC1 = FlowBox("object","SinOscC1", _G["FBSinOsc"])
--SinOscC2 = FlowBox("object","SinOscC2", _G["FBSinOsc"])

--utGainA = FlowBox("object","utGainA", _G["FBGain"])
utGainB = FlowBox("object","utGainB", _G["FBGain"])
--GainC = FlowBox("object","GainC", _G["FBGain"])

utPushA1 = FlowBox("object","utPushA1", _G["FBPush"])
utPushA2 = FlowBox("object","utPushA2", _G["FBPush"])
utPushA3 = FlowBox("object","utPushA3", _G["FBPush"])
utPushB1 = FlowBox("object","utPushB1", _G["FBPush"])
utPushB2 = FlowBox("object","utPushB2", _G["FBPush"])
utPushB3 = FlowBox("object","utPushB3", _G["FBPush"])

utPushS = FlowBox("object","utPushS", _G["FBPush"])

utAsympA = FlowBox("object", "upAsympA", _G["FBAsymp"])
utAsympB = FlowBox("object", "upAsympB", _G["FBAsymp"])

dac = _G["FBDac"]

--[[dac:SetPullLink(0, utSinOscA1, 0)
utSinOscA1:SetPullLink(1,utSinOscA2, 0)
utPushA1:SetPushLink(0,utSinOscA2, 0) 
utPushA1:Push(-0.3) -- AM wobble
utPushA2:SetPushLink(0,utSinOscA1, 0) -- Actual input
utPushA3:SetPushLink(0,utSinOscA2,1)
utPushA3:Push(0.0) -- Gain of first partial

dac:SetPullLink(0, utSinOscB1, 0)
utSinOscB1:SetPullLink(1,utSinOscB2, 0)
utPushB1:SetPushLink(0,utSinOscB2, 0) 
utPushB1:Push(-0.31) -- AM wobble
utPushB2:SetPushLink(0,utSinOscB1, 0) -- Actual input
utPushB3:SetPushLink(0,utSinOscB2, 1)
utPushB3:Push(0.0) -- Gain of second partial
--]]

dac:SetPullLink(0, utSinOscA1, 0)
utSinOscA1:SetPullLink(1,utSinOscA2, 0)
utPushA1:SetPushLink(0,utSinOscA2, 0) 
utPushA1:Push(-0.3) -- AM wobble
utPushA2:SetPushLink(0,utSinOscA1, 0) -- Actual input
utAsympA:SetPushLink(0,utSinOscA2, 1)
utPushA3:SetPushLink(0,utAsympA,0)
utPushA3:Push(0.0)
utPushS:SetPushLink(0,utAsympA,1)
utPushS:Push(2.0)
utPushS:RemovePushLink(0, utAsympA, 1)

dac:SetPullLink(0, utSinOscB1, 0)
utSinOscB1:SetPullLink(1,utSinOscB2, 0)
utPushB1:SetPushLink(0,utSinOscB2, 0) 
utPushB1:Push(-0.31) -- AM wobble
utPushB2:SetPushLink(0,utSinOscB1, 0) -- Actual input
--utAsympB:SetPushLink(0,utSinOscB2, 1)
utAsympB:SetPushLink(0,utSinOscB2, 1)
utPushB3:SetPushLink(0,utAsympB,0)
utPushB3:Push(0.0)
utPushS:SetPushLink(0,utAsympB,1)
utPushS:Push(2.0)
utPushS:RemovePushLink(0, utAsympB, 1)

else
dac:SetPullLink(0, utSinOscA1, 0)
dac:SetPullLink(0, utSinOscB1, 0)
end
