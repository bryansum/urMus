-- Design: Alexander Mueller
-- Hacked: Georg Essl

clockseqbackdropregion=Region('region', 'clockseqbackdropregion', UIParent);
clockseqbackdropregion:SetWidth(ScreenWidth());
clockseqbackdropregion:SetHeight(ScreenHeight());
clockseqbackdropregion:SetLayer("BACKGROUND");
clockseqbackdropregion:SetAnchor('BOTTOMLEFT',0,0); 
--clockseqbackdropregion:EnableClamping(true)
clockseqbackdropregion.texture = clockseqbackdropregion:Texture("clock_sequencer.jpg");
clockseqbackdropregion.texture:SetGradientColor("TOP",255,255,255,255,255,255,255,255);
clockseqbackdropregion.texture:SetGradientColor("BOTTOM",255,255,255,255,255,255,255,255);
--clockseqbackdropregion.texture:SetBlendMode("BLEND")
clockseqbackdropregion.texture:SetTexCoord(0,0.63,0.94,0.0);
--clockseqbackdropregion:EnableInput(true);
clockseqbackdropregion:Show();


--[[function FlipPage(self)
	if not cloudsloaded then
		SetPage(10)
		dofile(SystemPath("urClouds.lua"))
		cloudsloaded = true
	else
		SetPage(10);
	end
end]]

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
