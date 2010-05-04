
-- module("test")

require "xavante"
require "xavante.cgiluahandler"
require "wsapi.xavante"

local webDir = SystemPath("")

local simplerules = {
    { -- WSAPI application will be mounted under /app
      match = { "%.lua$", "%.lua/" },
      with = wsapi.xavante.makeHandler("hello","",webDir)
    },
} 

xavante.HTTP {
    server = {host = "*", port = 8080},
    
    defaultHost = {
    	rules = simplerules
    },
}

local el = Region('region', 'test', UIParent)
el:Handle("OnUpdate",function(el,elapsed) 
	copas.step(0.1)
end)

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
