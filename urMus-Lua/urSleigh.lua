
local function Shutdown()
	dac:RemovePullLink(0, usJCRev, 0)
	usAccelX:RemovePushLink(0,usZPuls, 0)
end

local function ReInit(self)
	dac:SetPullLink(0, usJCRev, 0)
	usAccelX:SetPushLink(0,usZPuls, 0)
end

sleighbackdropregion=Region('region', 'sleighbackdropregion', UIParent);
sleighbackdropregion:SetWidth(ScreenWidth());
sleighbackdropregion:SetHeight(ScreenHeight());
sleighbackdropregion:SetLayer("BACKGROUND");
sleighbackdropregion:SetAnchor('BOTTOMLEFT',0,0); 
--sleighbackdropregion:EnableClamping(true)
sleighbackdropregion.texture = sleighbackdropregion:Texture("SleighBells.png");
sleighbackdropregion.texture:SetGradientColor("TOP",255,255,255,255,255,255,255,255);
sleighbackdropregion.texture:SetGradientColor("BOTTOM",255,255,255,255,255,255,255,255);
--sleighbackdropregion.texture:SetBlendMode("BLEND")
sleighbackdropregion.texture:SetTexCoord(0,0.63,0.94,0.0);
--sleighbackdropregion.texture:SetTexCoord(0,1.0,0.0,1.0);
--sleighbackdropregion:Handle("OnUpdate", Paint);
--sleighbackdropregion:Handle("OnDoubleTap", Clear);
--sleighbackdropregion:EnableInput(true);
sleighbackdropregion:Show();
--sleighbackdropregion.texture:Clear();
sleighbackdropregion:Handle("OnPageEntered", ReInit)
sleighbackdropregion:Handle("OnPageLeft", Shutdown)

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

if not usSleigh then
	usSleigh = FlowBox("object","Sleigh", _G["FBSleigh"])

	usAccelX = FlowBox("object","AccelX", _G["FBAccel"])

	usZPuls = FlowBox("object", "ZPuls", _G["FBZPuls"])
	usJCRev = FlowBox("object", "JCRev", _G["FBJCRev"])

	dac = _G["FBDac"]

--[[ This is equivalent to this if the name space is safe.
	usSleigh = FlowBox("object","Sleigh", FBSleigh)

	usAccelX = FlowBox("object","AccelX", FBAccel)

	usZPuls = FlowBox("object", "ZPuls", FBZPuls)
	usJCRev = FlowBox("object", "JCRev", FBJCRev)
	dac = FBDac
]]

	dac:SetPullLink(0, usJCRev, 0)
	usAccelX:SetPushLink(0,usZPuls, 0)
	usJCRev:SetPullLink(0,usSleigh, 0)
	usZPuls:SetPushLink(0,usSleigh, 4)

end

