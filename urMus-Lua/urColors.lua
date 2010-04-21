-- urColors
-- Concept by: Devin Kerr
-- Related concept by: Eric Lapointe
-- Initial Hack by: Georg Essl 11/19/09

local num_colors = 8

colorscreens = {}

-- Scroll functions
-- Scroll action ended, check if we need to align
local function ColorScrollEnds(self)
	local left = self:Left()
	local div
	div = left / (ScreenWidth())
	left = left % (ScreenWidth())
	
	if left < ScreenWidth()/2 then
		self:SetAnchor('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', self:Left()-left ,self:Bottom())
	else
		self:SetAnchor('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', self:Left()-left+ScreenWidth() ,self:Bottom())
	end
	
	local sample = math.abs(self:Left()/ScreenWidth()) + 1
	
	if sample ~= self.sample then
		
		local pushflowbox = _G["FBPush"]

		if pushflowbox.instances and pushflowbox.instances[sample]  then
			pushflowbox.instances[sample]:Push(1.0)
			if self.sample and pushflowbox.instances[self.sample] then
				pushflowbox.instances[self.sample]:Push(0.0)
			end
			self.sample = sample
		end
		ucPushA1:Push((sample)/7)
	end
end

local function ResetPos(self)
	ucPushA2:Push(0.0)
end

-- Scroll, protect against going out of bounds
local function ScrollColorBackdrop(self, diff)
	local left = self:Left()+diff
	
	if left < ScreenWidth() - self:Width() then
		left = ScreenWidth() - self:Width()
	end
	if left > 0 then
		left = 0
	end
	
	self:SetAnchor('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', left ,self:Bottom())
end

local function Shutdown()
	dac:RemovePullLink(0, ucSample, 0)
	ucAccelY:RemovePushLink(0,ucPosSqr, 0)
end

local function ReInit(self)
	dac:SetPullLink(0, ucSample, 0)
	ucAccelY:SetPushLink(0,ucPosSqr, 0)
end

colorbackdropanchor = Region('region', 'colorbackdropanchor', UIParent)
colorbackdropanchor:SetWidth(ScreenWidth()*num_colors)
colorbackdropanchor:SetHeight(ScreenHeight())
colorbackdropanchor:SetLayer("LOW")
colorbackdropanchor:SetAnchor('BOTTOMLEFT',UIParent,"BOTTOMLEFT",0,0)
colorbackdropanchor:Handle("OnLeave", ColorScrollEnds)
colorbackdropanchor:Handle("OnTouchUp", ColorScrollEnds)
colorbackdropanchor:Handle("OnHorizontalScroll", ScrollColorBackdrop)
colorbackdropanchor:Handle("OnDoubleTap", ResetPos)
colorbackdropanchor:EnableHorizontalScroll(true)
colorbackdropanchor:EnableInput(true)
colorbackdropanchor:Show()
colorbackdropanchor:Handle("OnPageEntered", ReInit)
colorbackdropanchor:Handle("OnPageLeft", Shutdown)

local screencolors = {{255,0,0,255},{255,128,0},{255,255,0,255},{0,255,0,255},{0,255,255,255},{0,0,255,255},{255,0,255},{255,255,255,255},{255,128,128,255},{128,255,128,255},{128,128,255,255}}


for i=1,num_colors do
	colorscreens[i] = Region('region', 'colorscreen'..i,UIParent) -- Bug here
	colorscreens[i]:SetWidth(ScreenWidth())
	colorscreens[i]:SetHeight(ScreenHeight())
	colorscreens[i]:SetLayer("MEDIUM")
	if i == 1 then
		colorscreens[i]:SetAnchor('TOPLEFT',colorbackdropanchor,'TOPLEFT',0,0)
	else
		colorscreens[i]:SetAnchor('LEFT', colorscreens[i-1],'RIGHT',0,0)
	end
	colorscreens[i].t = colorscreens[i]:Texture()
	colorscreens[i].t:SetTexture(screencolors[i][1],screencolors[i][2],screencolors[i][3],screencolors[i][4])
--	colorscreens[i].t:SetTexture("ship.png")
	colorscreens[i]:Show()
end


--[[function FlipPage(self)
	dac:RemovePullLink(0, ucSample, 0)
	ucAccelY:RemovePushLink(0,ucSample, 0)
	if not smudgeloaded then
		SetPage(12)
		dofile(SystemPath("urSmudge.lua"))
		smudgeloaded = true
	else
		SetPage(12);
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
--pagebutton:Handle("OnPageEntered", ReInit)
pagebutton:EnableInput(true);
pagebutton:Show();

if not ucSample then
ucSample = FlowBox("object","Sample", _G["FBSample"])

ucSample:AddFile("Red-Mono.wav")
ucSample:AddFile("Orange-Mono.wav")
ucSample:AddFile("Yellow-Mono.wav")
ucSample:AddFile("Green-Mono.wav")
ucSample:AddFile("Cyan-Mono.wav")
ucSample:AddFile("Blue-Mono.wav")
ucSample:AddFile("Pink-Mono.wav")
ucSample:AddFile("White-Mono.wav")

ucPushA1 = FlowBox("object","PushA1", _G["FBPush"])
ucPushA2 = FlowBox("object","PushA2", _G["FBPush"])
ucAccelY = FlowBox("object","AccelY", _G["FBAccel"])

ucPosSqr = FlowBox("object", "PosSqr", _G["FBPosSqr"])
--ucAsymp = FlowBox("object", "Asmpy", _G["FBAsymp"])

dac = _G["FBDac"]

dac:SetPullLink(0, ucSample, 0)
ucPushA1:SetPushLink(0,ucSample, 3)  -- Sample switcher
ucPushA1:Push(0) -- AM wobble
ucPushA2:SetPushLink(0,ucSample, 2) -- Reset pos
ucPosSqr:SetPushLink(0,ucSample, 0)
ucAccelY:SetPushLink(1,ucPosSqr, 0)


else
dac:SetPullLink(0, ucSample, 0)
ucAccelY:SetPushLink(0,ucPosSqr, 0)
end

