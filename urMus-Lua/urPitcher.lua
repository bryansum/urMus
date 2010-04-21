-- urPitcher
-- Concept by: Rishi & Raphael
-- Initial Hack by: Georg Essl 11/19/09

pitcherbackdropregion=Region('region', 'pitcherbackdropregion', UIParent);
pitcherbackdropregion:SetWidth(ScreenWidth());
pitcherbackdropregion:SetHeight(ScreenHeight());
pitcherbackdropregion:SetLayer("BACKGROUND");
pitcherbackdropregion:SetAnchor('BOTTOMLEFT',0,0); 
--pitcherbackdropregion:EnableClamping(true)
pitcherbackdropregion.texture = pitcherbackdropregion:Texture("pitcher.png");
pitcherbackdropregion.texture:SetGradientColor("TOP",255,255,255,255,255,255,255,255);
pitcherbackdropregion.texture:SetGradientColor("BOTTOM",255,255,255,255,255,255,255,255);
--pitcherbackdropregion.texture:SetBlendMode("BLEND")
pitcherbackdropregion.texture:SetTexCoord(0,0.63,0.94,0.0);
--pitcherbackdropregion:EnableInput(true);
pitcherbackdropregion:Show();

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

function Playkey(self)
	local pushflowbox = _G["FBPush"]

	if pushflowbox.instances and pushflowbox.instances[1]  then
		pushflowbox.instances[1]:Push(pitch[self.key])
	end
	self:SetAlpha(0.5)
	self:Handle("OnUpdate", nil)
	self:Show()
end

function Releasekey(self)
	self:Handle("OnUpdate", nil)
	self.staytime = 0.05
	self.fadetime = 0.25
	self.alpha = 0.5
	self.alphaslope = 2
	self:Handle("OnUpdate", FadeRegion)
end



key = {}
for i=1,12 do
	key[i] = Region('region', 'keys', pitcherbackdropregion);
	key[i]:SetWidth(ScreenWidth());
	key[i]:SetHeight(32);
	key[i]:SetLayer("LOW");
	key[i]:SetAnchor('BOTTOMLEFT',0 --[[194--]],82+31*(i-1)); 
	key[i]:EnableClamping(true)
	key[i]:EnableInput(true)
	key[i].t = key[i]:Texture()
	key[i].t:SetTexture(255,255,128,190)
	key[i].t:SetBlendMode("BLEND")
	key[i]:Handle("OnTouchDown", Playkey)
	key[i]:Handle("OnEnter", Playkey)
	key[i]:Handle("OnTouchUp", Releasekey)
	key[i]:Handle("OnLeave", Releasekey)
	key[i].key = i
end

--[[function FlipPage(self)
	if not thumperloaded then
		SetPage(8)
		dofile(SystemPath("urThumper.lua"))
		thumperloaded = true
	else
		SetPage(8);
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
