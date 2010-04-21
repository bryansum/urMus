-- urRecorder
-- Concept by: All in the 09 mopho course
-- Related Concept: Devin Kerr & Justin Crowell
-- Initial Hack by: Georg Essl 12/1/09

local function Shutdown()
	dac:RemovePullLink(0, Looper, 0)
	urMic:RemovePushLink(0,Looper, 0) -- urMic in
	urAccel:RemovePushLink(0,Looper,2)
	urAccel:RemovePushLink(1,Looper,1)
end

local function ReInit(self)
	dac:SetPullLink(0, Looper, 0)
	urMic:SetPushLink(0,Looper, 0) -- urMic in
	urAccel:RemovePushLink(0,Looper,2)
	urAccel:RemovePushLink(1,Looper,1)
end

local backdrop = Region('region','backdrop',UIParent)
backdrop.t = backdrop:Texture()
backdrop.t:SetTexture(0,0,0,255)
backdrop:SetLayer("BACKGROUND")
backdrop:SetWidth(ScreenWidth())
backdrop:SetHeight(ScreenHeight())
backdrop:Show()
backdrop:Handle("OnPageEntered", ReInit)
backdrop:Handle("OnPageLeft", Shutdown)

local buttoncols = 2
local buttonrows = 2
buttons = {} -- Create rows
for i=1,buttonrows do
	buttons[i] = {} -- Create columns
end

local padlabels = {}
padlabels[1] = "Play"
padlabels[2] = "Record"
padlabels[3] = "Lock Rate"
padlabels[4] = "Lock Amp"
padlabels[5] = "Raymond"
padlabels[6] = "Cowe"
padlabels[7] = "ChuckiE"
padlabels[8] = "Hadron"
padlabels[9] = "dsound"
padlabels[10] = "dp"
padlabels[11] = "Sam/PSM"
padlabels[12] = "42"

local padcenterlabels = {}
padcenterlabels[1] = "PLAY"
padcenterlabels[2] = "REC"
padcenterlabels[3] = "Unlock\nRATE"
padcenterlabels[4] = "Unlock\nAMP"

local function SingleDown(self)
--	local pushflowbox = _G["FBPush"]
--	if pushflowbox.instances and pushflowbox.instances[self.index] and (not self.value or self.value == 0) then
--		pushflowbox.instances[self.index]:Push(1.0)
--	else
	if (not self.value or self.value == 0) then
		if self.index == 1 then
			urPushA1:Push(1.0)
		elseif self.index == 2 then
			urPushA2:Push(1.0)
		elseif self.index == 3 then
			urAccel:SetPushLink(0,Looper,2)
		elseif self.index == 4 then
			urAccel:SetPushLink(1,Looper,1)
		end
	self.t:SetGradientColor("TOP",0,255,0,255,0,255,0,255)
	self.t:SetGradientColor("BOTTOM",0,190,0,255,0,190,0,255)
	end
end

local function SingleUp(self)
--	local pushflowbox = _G["FBPush"]
--	if pushflowbox.instances and pushflowbox.instances[self.index] and (not self.value or self.value == 0) then
--		pushflowbox.instances[self.index]:Push(0.0)
--	else
    if (not self.value or self.value == 0) then
		if self.index == 1 then
			urPushA1:Push(0.0)
		elseif self.index == 2 then
			urPushA2:Push(0.0)
		elseif self.index == 3 then
			urAccel:RemovePushLink(0,Looper,2)
		elseif self.index == 4 then
			urAccel:RemovePushLink(1,Looper,1)
		end
	self.t:SetGradientColor("TOP",255,255,255,255,255,255,255,255)
	self.t:SetGradientColor("BOTTOM",255,255,255,255,255,255,255,255)
	end
end

local function DoubleTap(self)
--	local pushflowbox = _G["FBPush"]
	
	local index = self.index
--	if pushflowbox.instances and pushflowbox.instances[self.index+1] then
--		index = self.index + 1
--	elseif pushflowbox.instances and pushflowbox.instances[self.index-1] then
--		index = self.index - 1
--	end
	
	local value = self.value and 1-self.value or 1
	self.value = value
--	if pushflowbox.instances and pushflowbox.instances[index] then
--		pushflowbox.instances[index]:Push(value)
--	end
	if self.index == 1 then
		urPushA1:Push(value)
	elseif self.index == 2 then
		urPushA2:Push(value)
	end
	if value == 0 then
		self.t:SetGradientColor("TOP",255,255,255,255,255,255,255,255)
		self.t:SetGradientColor("BOTTOM",255,255,255,255,255,255,255,255)
		if self.index == 3 then
			urAccel:RemovePushLink(0,Looper,2)
			urPushA3:SetPushLink(0,Looper,2)
			urPushA3:Push(0.25)
			urPushA3:RemovePushLink(0,Looper,2)
		elseif self.index == 4 then
			urAccel:RemovePushLink(1,Looper,1)
			urPushA3:SetPushLink(0,Looper,1)
			urPushA3:Push(1.0)
			urPushA3:RemovePushLink(0,Looper,1)
		end
	else
		self.t:SetGradientColor("TOP",255,0,0,255,255,0,0,255)
		self.t:SetGradientColor("BOTTOM",255,0,0,255,255,0,0,255)
		if self.index == 3 then
			urAccel:SetPushLink(0,Looper,2)
		elseif self.index == 4 then
			urAccel:SetPushLink(1,Looper,1)
		end
	end
end

for ix = 1, buttoncols do
	for iy = 1, buttonrows do
		local newbutton
		newbutton = Region('region','button'..ix..":"..iy,UIParent)
		newbutton.t = newbutton:Texture("flatbutton-64.png")
		newbutton:SetHeight(ScreenHeight()/buttonrows-24)
		newbutton:SetWidth(ScreenWidth()/buttoncols-5)
		local x = 5+(ix-1)*(ScreenWidth()/buttoncols)
		local y = 12+(iy-1)*(ScreenHeight()/buttonrows)
		newbutton:SetAnchor("BOTTOMLEFT", x,y)
		newbutton:Show()
		newbutton:Handle("OnTouchDown", SingleDown)
		newbutton:Handle("OnTouchUp", SingleUp)
		newbutton:Handle("OnDoubleTap", DoubleTap)
		newbutton:EnableInput(true)
		newbutton.tl = newbutton:TextLabel()
		newbutton.tl:SetLabel(padcenterlabels[ix + (iy-1)*buttoncols])
		newbutton.tl:SetFont("Trebuchet MS")
		newbutton.tl:SetHorizontalAlign("CENTER")
		newbutton.tl:SetLabelHeight(24)
		newbutton.tl:SetColor(0,0,0,255)
		newbutton.index = ix + (iy-1)*buttoncols
		buttons[iy][ix] = newbutton
		newannotation1 = Region('region','annotation1'..ix..":"..iy,UIParent)
		newannotation1:SetWidth(ScreenWidth()/3)
		newannotation1:SetHeight(11)
		newannotation1.tl = newannotation1:TextLabel()
		newannotation1:SetAnchor("BOTTOMLEFT", newbutton, "TOPLEFT", 0,0)
		newannotation1.tl:SetLabel("Pad "..ix + (iy-1)*buttoncols)
		newannotation1.tl:SetFont("Trebuchet MS")
		newannotation1.tl:SetHorizontalAlign("LEFT")
		newannotation1.tl:SetLabelHeight(10)
		newannotation1.tl:SetColor(255,255,255,255)
		newannotation1:Show()
		newannotation2 = Region('region','annotation2'..ix..":"..iy,UIParent)
		newannotation2:SetWidth(ScreenWidth()/24)
		newannotation2:SetHeight(11)
		newannotation2.tl = newannotation2:TextLabel()
		newannotation2:SetAnchor("BOTTOMRIGHT", newbutton, "TOPRIGHT", 0,0)
		newannotation2.tl:SetLabel(""..ix + (iy-1)*buttoncols)
		newannotation2.tl:SetFont("Trebuchet MS")
		newannotation2.tl:SetHorizontalAlign("RIGHT")
		newannotation2.tl:SetLabelHeight(10)
		newannotation2.tl:SetColor(0,255,0,255)
		newannotation2:Show()
		newannotation3 = Region('region','annotation3'..ix..":"..iy,UIParent)
		newannotation3:SetWidth(ScreenWidth()/3)
		newannotation3:SetHeight(11)
		newannotation3.tl = newannotation3:TextLabel()
		newannotation3:SetAnchor("RIGHT", newannotation2, "LEFT", 0,0)
		newannotation3.tl:SetLabel(padlabels[ix + (iy-1)*buttoncols])
		newannotation3.tl:SetFont("Trebuchet MS")
		newannotation3.tl:SetHorizontalAlign("RIGHT")
		newannotation3.tl:SetLabelHeight(10)
		newannotation3.tl:SetColor(255,255,0,255)
		newannotation3:Show()
		
	end
end

--[[function FlipPage(self)
	dac:RemovePullLink(0, Looper, 0)
	urMic:RemovePushLink(0,Looper, 0) -- urMic in
	urAccel:RemovePushLink(0,Looper,2)
	urAccel:RemovePushLink(1,Looper,1)

	SetPage(page_urmus);
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



if not Looper then
Looper = FlowBox("object","Looper", _G["FBLooper"])

urPushA1 = FlowBox("object","urPushA1", _G["FBPush"]) -- Play
urPushA2 = FlowBox("object","urPushA2", _G["FBPush"]) -- Rec
urPushA3 = FlowBox("object","urPushA3", _G["FBPush"]) -- To set constants
--urPushA3 = FlowBox("object","urPushA3", _G["FBPush"]) -- Lock Unlock Volume
--urPushA4 = FlowBox("object","urPushA4", _G["FBPush"]) -- Lock Unlock Rate
urAccel = FlowBox("object","urAccel", _G["FBAccel"]) -- Using X rate Y vol
urMic = FlowBox("object", "urMic", _G["FBMic"])

dac = _G["FBDac"]

dac:SetPullLink(0, Looper, 0)
urPushA1:SetPushLink(0,Looper, 4)  -- Looper play
urPushA1:Push(0)
urPushA2:SetPushLink(0,Looper, 3)  -- Looper record
urPushA2:Push(0)
urMic:SetPushLink(0,Looper, 0) -- urMic in
else
dac:SetPullLink(0, Looper, 0)
urMic:SetPushLink(0,Looper, 0) -- urMic in
urAccel:RemovePushLink(0,Looper,2)
urAccel:RemovePushLink(1,Looper,1)
end

