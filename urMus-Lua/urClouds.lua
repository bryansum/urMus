cloudsbackdropregion=Region('region', 'cloudsbackdropregion', UIParent);
cloudsbackdropregion:SetWidth(ScreenWidth());
cloudsbackdropregion:SetHeight(ScreenHeight());
cloudsbackdropregion:SetLayer("BACKGROUND");
cloudsbackdropregion:SetAnchor('BOTTOMLEFT',0,0); 
--cloudsbackdropregion:EnableClamping(true)
cloudsbackdropregion.texture = cloudsbackdropregion:Texture("cloud_sequencer.png");
cloudsbackdropregion.texture:SetGradientColor("TOP",255,255,255,255,255,255,255,255);
cloudsbackdropregion.texture:SetGradientColor("BOTTOM",255,255,255,255,255,255,255,255);
--cloudsbackdropregion.texture:SetBlendMode("BLEND")
cloudsbackdropregion.texture:SetTexCoord(0,0.63,0.94,0.0);
--cloudsbackdropregion:EnableInput(true);
cloudsbackdropregion:Show();


--[[function FlipPage(self)
	if not colorsloaded then
		SetPage(11)
		dofile(SystemPath("urColors.lua"))
		colorsloaded = true
	else
		SetPage(11);
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
