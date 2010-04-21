-- A quick demo to show off what Vis does.
-- Hacked by Georg Essl
-- Created: 2/8/2010

local regions = {}

recycledregions = {}

function RecycleSelf(self)
	self:EnableInput(false)
	self:EnableMoving(false)
	self:EnableResizing(false)
	self:Hide()
	table.insert(recycledregions, self)
	for k,v in pairs(regions) do
		if v == self then
			table.remove(regions,k)
		end
	end
end

function CreateorRecycleregion(ftype, name, parent)
	local region
	if #recycledregions > 0 then
		region = recycledregions[#recycledregions]
		table.remove(recycledregions)
	else
		region = Region()
--		region = Region('region', 'backdrop', UIParent)
		region.t = region:Texture("Ornament1.png")
		region.t:SetBlendMode("BLEND")
	end
	return region
end

local pi = math.pi

function RotateTexture(self,x,y,z,north)
	self.t:SetRotation(pi*north)
end

function TextureCol(t,r,g,b,a)
	t:SetGradientColor("TOP",r,g,b,a,r,g,b,a)
	t:SetGradientColor("BOTTOM",r,g,b,a,r,g,b,a)
end

local vis = _G["FBVis"]
local function GatherVis(self, elapsed)

	local visout = vis:Get()
	local color = (visout+1.0)*127

	if self.mode == 0 then
		self.t:SetGradientColor("TOP",color,255,255,255,255,255-color,255,255)
		self.t:SetGradientColor("BOTTOM",255,255,color,255,255,255,255,color)
--		TextureCol(self.t,color,255,255,255)
	elseif self.mode == 1 then
		self.t:SetGradientColor("TOP",255-color,255,255,255,255,color,255,255)
		self.t:SetGradientColor("BOTTOM",255,255,255-color,255,255,255,255,255-color)
--		TextureCol(self.t,255,255-color,255,255)
	elseif self.mode == 2 then
		self.t:SetGradientColor("TOP",255,255,color,255,255,255,255,color)
		self.t:SetGradientColor("BOTTOM",color,255,255,255,255,color,255,255)
--		TextureCol(self.t,255,255,color,255)
	elseif self.mode == 3 then
		self.t:SetGradientColor("TOP",255,255,255-color,255,255,255,255,255-color)
		self.t:SetGradientColor("BOTTOM",255-color,255,255,255,255,255-color,255,255)
--		TextureCol(self.t,255,255,255,color)
	elseif self.mode == 4 then
		self.t:SetRotation(pi*visout)
--		self:SetWidth(color+50)
--	elseif self.mode == 5 then
--		self:SetHeight(color+50)
	end
end

local random = math.random

local rotatemode = 4

function TouchDown(self)
	local region = CreateorRecycleregion('region', 'backdrop', UIParent)
	TextureCol(region.t,255,255,255,255)
	region:Show()
	region:EnableMoving(true)
	region:EnableResizing(true)
	region:EnableInput(true)
	region:Handle("OnDoubleTap", RecycleSelf)
	region.mode = rotatemode
	region:Handle("OnUpdate", GatherVis)
	rotatemode = rotatemode + 1
	if rotatemode > 4 then
		rotatemode = 0
	end
	if region.mode ~= 4 then
		region:Handle("OnHeading", RotateTexture)
	end
	local x,y = InputPosition()
	region:SetAnchor("CENTER",x,y)
	table.insert(regions, region)
end

function TouchUp(self)
--	DPrint("MU")
end

function DoubleTap(self)
--	DPrint("DT")
end

function Enter(self)
--	DPrint("EN")
end

function Leave(self)
--	DPrint("LV")
end

local backdrop = Region()
--local backdrop = Region('region', 'backdrop', UIParent)
backdrop:SetWidth(ScreenWidth())
backdrop:SetHeight(ScreenHeight())
backdrop:SetLayer("BACKGROUND")
backdrop:SetAnchor('BOTTOMLEFT',0,0)
backdrop:Handle("OnTouchDown", TouchDown)
backdrop:Handle("OnMosueUp", TouchUp)
backdrop:Handle("OnDoubleTap", DoubleTap)
backdrop:Handle("OnEnter", Enter)
backdrop:Handle("OnLeave", Leave)
backdrop:EnableInput(true)

local pagebutton=Region()
--local pagebutton=Region('region', 'pagebutton', UIParent)
pagebutton:SetWidth(pagersize)
pagebutton:SetHeight(pagersize)
pagebutton:SetLayer("TOOLTIP")
pagebutton:SetAnchor('BOTTOMLEFT',ScreenWidth()-pagersize-4,ScreenHeight()-pagersize-4) 
pagebutton:EnableClamping(true)
--pagebutton:Handle("OnDoubleTap", FlipPage)
pagebutton:Handle("OnTouchDown", FlipPage)
pagebutton.texture = pagebutton:Texture("circlebutton-16.png")
pagebutton.texture:SetGradientColor("TOP",255,255,255,255,255,255,255,255)
pagebutton.texture:SetGradientColor("BOTTOM",255,255,255,255,255,255,255,255)
pagebutton.texture:SetBlendMode("BLEND")
pagebutton.texture:SetTexCoord(0,1.0,0,1.0)
pagebutton:EnableInput(true)
pagebutton:Show()
--pagebutton:Handle("OnPageEntered", nil)

