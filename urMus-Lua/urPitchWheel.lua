-- urPitchWheel
-- Concept by: Owen Campbell & Colin Neville
-- Initial Hack by: Georg Essl 11/19/09

local atan2 = math.atan2
local log = math.log
local abs = math.abs
local floor = math.floor

local octavestretch = 4

local pitch = {}
pitch[25] = 12.0/96.0*log(261.6/55)/log(2) -- C
pitch[13] = 12.0/96.0*log(277.18/55/2)/log(2) -- #
pitch[14] = 12.0/96.0*log(293.67/55/2)/log(2)
pitch[15] = 12.0/96.0*log(311.13/55/2)/log(2) -- #
pitch[16] = 12.0/96.0*log(329.63/55/2)/log(2) -- E
pitch[17] = 12.0/96.0*log(349.23/55/2)/log(2)
pitch[18] = 12.0/96.0*log(369.99/55/2)/log(2) -- #
pitch[19] = 12.0/96.0*log(392.00/55/2)/log(2)
pitch[20] = 12.0/96.0*log(415.30/55/2)/log(2) -- #
pitch[21] = 12.0/96.0*log(440.0/55/2)/log(2)
pitch[22] = 12.0/96.0*log(466.16/55/2)/log(2) -- #
pitch[23] = 12.0/96.0*log(493.88/55/2)/log(2)
pitch[24] = 12.0/96.0*log(523.25/55/2)/log(2)
pitch[1] = 12.0/96.0*log(277.18/55)/log(2) -- #
pitch[2] = 12.0/96.0*log(293.67/55)/log(2)
pitch[3] = 12.0/96.0*log(311.13/55)/log(2) -- #
pitch[4] = 12.0/96.0*log(329.63/55)/log(2) -- E
pitch[5] = 12.0/96.0*log(349.23/55)/log(2)
pitch[6] = 12.0/96.0*log(369.99/55)/log(2) -- #
pitch[7] = 12.0/96.0*log(392.00/55)/log(2)
pitch[8] = 12.0/96.0*log(415.30/55)/log(2) -- #
pitch[9] = 12.0/96.0*log(440.0/55)/log(2)
pitch[10] = 12.0/96.0*log(466.16/55)/log(2) -- #
pitch[11] = 12.0/96.0*log(493.88/55)/log(2)
pitch[12] = 12.0/96.0*log(523.25/55)/log(2)
pitch[0] = 12.0/96.0*log(554.37/55)/log(2) -- #

function smoothAmp(amp)
	local res = math.cos(math.pi*amp/2.0)
	return res * res 
end

local continuous = true

function CheckWheel(self)
	local x,y = InputPosition()
	x = x-ScreenWidth()/2
	y = y-ScreenHeight()/2
	local angle = atan2(x,y)/math.pi

	local pushflowbox = _G["FBPush"]
	local freq
	local freq2
	local amp
	local amp2
	local amp3
	local amp4
		if not continuous then
			freq = pitch[floor((angle+1.0)/2.0*23.0+0.5)+1]
			amp = abs(angle)
		else
			freq = 12.0/96.0*log(277.18/4.0*(((angle/2.0+0.5)*8.0+1.0)*1.0)/55)/log(2)
			amp = abs(smoothAmp(angle))
			amp3 = amp
		end
		upPushA1:Push(freq)
		upPushA2:Push(amp)

		if not continuous then
			freq2 = pitch[floor(((angle+2.0)%2.0)/2.0*23.0+0.5)+1]
			amp2 = 1.0-abs(angle)
		else
			freq2 = 12.0/96.0*log(277.18/4.0*((((angle+2.0)%2.0)/2.0)*8.0+1.0)*1.0/55)/log(2)
			amp2 = 1.0-abs(smoothAmp(angle))
			amp4 = amp2
		end

--		upPushB1:Push(freq2)
--		upPushB2:Push(amp2)
		
	if pushflowbox.instances and pushflowbox.instances[1] then
		pushflowbox.instances[1]:Push(freq)
		if pushflowbox.instances[2] then
			pushflowbox.instances[2]:Push(amp)
		end
		if pushflowbox.instances and pushflowbox.instances[3]  then
			pushflowbox.instances[3]:Push(freq2)
			if pushflowbox.instances[4] then
				pushflowbox.instances[4]:Push(amp2)
			end
		end
	end
end

function ActivateWheel(self)
	pwbackdropregion:Handle("OnUpdate", CheckWheel)
end

function DeactivateWheel(self)
	pwbackdropregion:Handle("OnUpdate", nil)
end

local function Shutdown()
	dac:RemovePullLink(0, upSinOscA1, 0)
end

local function ReInit(self)
	dac:SetPullLink(0, upSinOscA1, 0)
end

pwbackdropregion=Region('region', 'pwbackdropregion', UIParent);
pwbackdropregion:SetWidth(ScreenWidth());
pwbackdropregion:SetHeight(ScreenHeight());
pwbackdropregion:SetLayer("BACKGROUND");
pwbackdropregion:SetAnchor('BOTTOMLEFT',0,0); 
--pwbackdropregion:EnableClamping(true)
pwbackdropregion.texture = pwbackdropregion:Texture("pitchwheel.png");
pwbackdropregion.texture:SetGradientColor("TOP",255,255,255,255,255,255,255,255);
pwbackdropregion.texture:SetGradientColor("BOTTOM",255,255,255,255,255,255,255,255);
--pwbackdropregion.texture:SetBlendMode("BLEND")
pwbackdropregion.texture:SetTexCoord(0,0.63,0.94,0.0);
pwbackdropregion:Handle("OnTouchDown", ActivateWheel)
pwbackdropregion:Handle("OnTouchUp", DeactivateWheel)
pwbackdropregion:EnableInput(true);
pwbackdropregion:Show();
pwbackdropregion:Handle("OnPageEntered", ReInit)
pwbackdropregion:Handle("OnPageLeft", Shutdown)

function ToggleFx(self)
	if not self.toggle then
		local myvariable 
		self.toggle = true
		self:SetAlpha(0.25)
	else
		self.toggle = nil
		self:SetAlpha(0.0)
	end
	
	if self.fx == 1 then
		if self.toggle then
			dac:RemovePullLink(0, upSinOscA1, 0)
		else
			dac:SetPullLink(0, upSinOscA1, 0)
		end
	elseif self.fx == 2 then
		if self.toggle then
--			dac:RemovePullLink(0, upSinOscB1, 0)
		else
--			dac:SetPullLink(0, upSinOscB1, 0)
		end
	end
end

fx = {}
fx[1] = Region('region','fx[1]',UIParent)
fx[1]:SetWidth(56)
fx[1]:SetHeight(53)
fx[1]:SetAnchor("BOTTOMLEFT", 13, 480-15-53)
fx[1]:SetLayer("LOW");
fx[1]:EnableInput(true)
fx[1]:Handle("OnTouchUp", ToggleFx)
fx[1].t = fx[1]:Texture()
fx[1].t:SetTexture(255,0,0,255)
fx[1]:SetAlpha(0.0);
fx[1].t:SetBlendMode("BLEND")
fx[1]:Show()
fx[1].fx = 1

fx[2] = Region('region','fx[2]',UIParent)
fx[2]:SetWidth(56)
fx[2]:SetHeight(53)
fx[2]:SetAnchor("BOTTOMLEFT", 93, 480-15-53)
fx[2]:EnableInput(true)
fx[2]:Handle("OnTouchUp", ToggleFx)
fx[2].t = fx[2]:Texture()
fx[2].t:SetTexture(255,0,0,255);
fx[2]:SetAlpha(0.0);
fx[2].t:SetBlendMode("BLEND")
fx[2]:Show()
fx[2].fx = 2

fx[3] = Region('region','fx[3]',UIParent)
fx[3]:SetWidth(56)
fx[3]:SetHeight(53)
fx[3]:SetAnchor("BOTTOMLEFT", 168, 480-15-53)
fx[3]:EnableInput(true)
fx[3]:Handle("OnTouchUp", ToggleFx)
fx[3].t = fx[3]:Texture()
fx[3].t:SetTexture(255,0,0,255);
fx[3]:SetAlpha(0.0);
fx[3].t:SetBlendMode("BLEND")
fx[3]:Show()

fx[4] = Region('region','fx[4]',UIParent)
fx[4]:SetWidth(56)
fx[4]:SetHeight(53)
fx[4]:SetAnchor("BOTTOMLEFT", 247, 480-15-53)
fx[4]:EnableInput(true)
fx[4]:Handle("OnTouchUp", ToggleFx)
fx[4].t = fx[4]:Texture()
fx[4].t:SetTexture(255,0,0,255);
fx[4]:SetAlpha(0.0);
fx[4].t:SetBlendMode("BLEND")
fx[4]:Show()



--[[function FlipPage(self)
	if not pitcherloaded then
		SetPage(7)
		dofile(SystemPath("urPitcher.lua"))
		pitcherloaded = true
	else
		SetPage(7);
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

upSinOscA1 = FlowBox("object","utSinOscA1", _G["FBSinOsc"])

upPushA1 = FlowBox("object","utPushA1", _G["FBPush"])
upPushA2 = FlowBox("object","utPushA2", _G["FBPush"])
upAsympA = FlowBox("object", "upAsympA", _G["FBAsymp"])

--[[upSinOscB1 = FlowBox("object","utSinOscB1", _G["FBSinOsc"])

upPushB1 = FlowBox("object","utPushB1", _G["FBPush"])
upPushB2 = FlowBox("object","utPushB2", _G["FBPush"])
upAsympB = FlowBox("object", "upAsympB", _G["FBAsymp"])

--]]
upPushS = FlowBox("object","utPushS", _G["FBPush"])



dac = _G["FBDac"]

--[[dac:SetPullLink(0, upSinOscA1, 0)
upPushA1:SetPushLink(0,upSinOscA1, 0) 
upPushA2:SetPushLink(0,upSinOscA1, 1)
upPushA2:Push(0.0)
dac:SetPullLink(0, upSinOscB1, 0)
upPushB1:SetPushLink(0,upSinOscB1, 0) 
upPushB2:SetPushLink(0,upSinOscB1, 1)
upPushB2:Push(0.0)--]]

dac:SetPullLink(0, upSinOscA1, 0)
upPushA1:SetPushLink(0,upSinOscA1, 0) 
upAsympA:SetPushLink(0,upSinOscA1, 1)
upPushA2:SetPushLink(0,upAsympA,0)
upPushA2:Push(0.0)
upPushS:SetPushLink(0,upAsympA,1)
upPushS:Push(5.0)
upPushS:RemovePushLink(0, upAsympA, 1)

--[[dac:SetPullLink(0, upSinOscB1, 0)
upPushB1:SetPushLink(0,upSinOscB1, 0) 
upAsympB:SetPushLink(0,upSinOscB1, 1)
upPushB2:SetPushLink(0,upAsympB,0)
upPushB2:Push(0.0)
upPushS:SetPushLink(0,upAsympB,1)
upPushS:Push(5.0)
upPushS:RemovePushLink(0, upAsympB, 1)
--]]