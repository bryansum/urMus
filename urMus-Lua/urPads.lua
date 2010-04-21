-- urPads
-- Concept by: Devin Kerr
-- Related Concept: Justin Crowell
-- Initial Hack by: Georg Essl 11/19/09

local backdrop = Region('region','backdrop',UIParent)
backdrop.t = backdrop:Texture()
backdrop.t:SetTexture(0,0,0,255)
backdrop:SetLayer("BACKGROUND")
backdrop:SetWidth(ScreenWidth())
backdrop:SetHeight(ScreenHeight())
backdrop:Show()

local buttoncols = 3
local buttonrows = 4
buttons = {} -- Create rows
for i=1,buttonrows do
	buttons[i] = {} -- Create columns
end

local padlabels = {}
padlabels[1] = "Play"
padlabels[2] = "Record"
padlabels[3] = "Chicken"
padlabels[4] = "Eggs"
padlabels[5] = "Raymond"
padlabels[6] = "Cowe"
padlabels[7] = "ChuckiE"
padlabels[8] = "Hadron"
padlabels[9] = "dsound"
padlabels[10] = "dp"
padlabels[11] = "Sam/PSM"
padlabels[12] = "42"

function SingleDown(self)
	local pushflowbox = _G["FBPush"]
	if pushflowbox.instances and pushflowbox.instances[self.index] and (not self.value or self.value == 0) then
		pushflowbox.instances[self.index]:Push(1.0)
		self.t:SetGradientColor("TOP",0,255,0,255,0,255,0,255)
		self.t:SetGradientColor("BOTTOM",0,190,0,255,0,190,0,255)
	end
end

function SingleUp(self)
	local pushflowbox = _G["FBPush"]
	if pushflowbox.instances and pushflowbox.instances[self.index] and (not self.value or self.value == 0) then
		pushflowbox.instances[self.index]:Push(0.0)
		self.t:SetGradientColor("TOP",255,255,255,255,255,255,255,255)
		self.t:SetGradientColor("BOTTOM",255,255,255,255,255,255,255,255)
	end
end

function DoubleTap(self)
	local pushflowbox = _G["FBPush"]
	
	local index = self.index
--	if pushflowbox.instances and pushflowbox.instances[self.index+1] then
--		index = self.index + 1
--	elseif pushflowbox.instances and pushflowbox.instances[self.index-1] then
--		index = self.index - 1
--	end
	
	if pushflowbox.instances and pushflowbox.instances[index] then
		local value = self.value and 1-self.value or 1
		self.value = value
		pushflowbox.instances[index]:Push(value)
		if value == 0 then
			self.t:SetGradientColor("TOP",255,255,255,255,255,255,255,255)
			self.t:SetGradientColor("BOTTOM",255,255,255,255,255,255,255,255)
		else
			self.t:SetGradientColor("TOP",255,0,0,255,255,0,0,255)
			self.t:SetGradientColor("BOTTOM",255,0,0,255,255,0,0,255)
		end
	end
end

for ix = 1, buttoncols do
	for iy = 1, buttonrows do
		local newbutton
		newbutton = Region('region','button'..ix..":"..iy,UIParent)
		newbutton.t = newbutton:Texture("flatbutton-64.png")
		newbutton:SetHeight(96)
		newbutton:SetWidth(96)
		local x = 5+(ix-1)*(ScreenWidth()/3)
		local y = 12+(iy-1)*(ScreenHeight()/4)
		newbutton:SetAnchor("BOTTOMLEFT", x,y)
		newbutton:Show()
		newbutton:Handle("OnTouchDown", SingleDown)
		newbutton:Handle("OnTouchUp", SingleUp)
		newbutton:Handle("OnDoubleTap", DoubleTap)
		newbutton:EnableInput(true)
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
	if not pitchwheelloaded then
		SetPage(6)
		dofile(SystemPath("urPitchWheel.lua"))
		pitchwheelloaded = true
	else
		SetPage(6);
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

