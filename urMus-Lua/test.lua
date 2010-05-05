
-- module("test")
require "xavante"
require "xavante.redirecthandler"
require "xavante.filehandler"
require "xavante.cgiluahandler"
require "wsapi.xavante"

package.path = SystemPath('http/?.lua')..';'..package.path;

local webDir = SystemPath("http")

local simplerules = {
    { -- URI remapping example
      match = "^[^%./]*/$",
      with = xavante.redirecthandler,
      params = {"index.html"}
    },
    {
        match = { "%.lua$", "%.lua/" },
        with = wsapi.xavante.makeHandler("eval","",webDir)
    },
    { -- filehandler example
        match = ".",
        with = xavante.filehandler,
        params = {baseDir = webDir}
    },
} 

xavante.HTTP {
    server = {host = "*", port = 8080},
    
    defaultHost = {
    	rules = simplerules
    },
}

local times = 0
HTTPServer = Region('region', 'test', UIParent)
HTTPServer:Handle("OnUpdate",function(el,elapsed) 
    times = times + 1
    DPrint(times)
	copas.step(0.01)
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


