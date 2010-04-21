
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
		region = Region('region', 'backdrop', UIParent)
		region.t = region:Texture()
	end
	return region
end


-- Dropdown functions here (currently buggy/unused)

function CreateIconFan(parent, iconregionlist, radius, separation)
	local x, y = InputPosition()
	local pos = 0

	local max = #iconregionlist
	local startangle = 3*PI/2
	local orientation = 1
	
	local segments = 2*PI*radius/separation
	local hidden 
	if segments < max then
		hidden = max - segments
	end

	local fan = {}

	if x< ScreenWidth()/2 then -- Right arc vs left arc
	else
	end
	if y < ScreenWidth()/2 then -- Top arc vs bottom arc
	else
	end

	local newanchor
	for k,v in pairs(iconregionlist) do
		local xp = radius * cos(orientation*2*PI/segments*(k-1)+startangle)
		local yp = radius * sin(orientation*2*PI/segments*(k-1)+startangle)

		newanchor = Region("region","anchor "..k, parent)
		table.insert(fan, 	newanchor)
		newanchor:SetAnchor("CENTER", parent, "CENTER", xp, yp)
		v:SetAnchor("CENTER", newanchor, "CENTER", 0, 0)
		--v:Hide()
		v:EnableInput(false)
	end

	return fan
end

function OpenFanAnim(self, elapsed)
--	local mytime = Time()
	local dt = elapsed

	local child= self:Children()

	if self.animtime > 1.0 then
		child:Show()
		child:EnableInput(true)
		child:SetHeight(self.animheight)
		child:SetWidth(self.animwidth)
		self:Handle("OnUpdate", nil)
		return
	end
	self.animtime = self.animtime + dt
	if self.animlastupdate + self.animspeed < self.animtime and self.animtime <= 1.0 then
		self.animlastupdate = self.animlastupdate + self.animspeed
		if self.animdelay > 0 then
			self.animdelay = self.animdelay - dt
			return
		elseif not child:IsShown() then
			self:Show()
			child:Show()
			child:EnableInput(true)
		end
		self.animscale = self.animscale + self.animspeed
		child:SetHeight(self.animscale*self.animheight)
		child:SetWidth(self.animscale*self.animwidth)
	end
end

function OpenIconFan(self)
	for k,v in pairs(self) do
		local child = v:Children()
		v:Show()
		child:Show()
		child:EnableInput(true)
	
--		v.animdelay = 0 --(k-1)*0.1
--		v.animspeed = 0.1
--		v.animstart = Time()
--		v.animtime = 0
--		v.animlastupdate = 0
--		v.animscale = 0
--		v.animheight = v:Height()
--		v.animwidth = v:Width()
--		v:Handle("OnUpdate", OpenFanAnim)
	end
end

function CloseFanAnim(self, elapsed)
--	local mytime = Time()
	local dt = elapsed
	local child= self:Children()

	if self.animtime > 1.0 then
		self:Hide()
		child:Hide()
		child:EnableInput(false)
		self:Handle("OnUpdate", nil)
		return
	end
	self.animtime = self.animtime + dt
	if self.animlastupdate + self.animspeed < self.animtime and self.animtime <= 1.0 then
		self.animlastupdate = self.animlastupdate + self.animspeed
		if self.animdelay > 0 then
			self.animdelay = self.animdelay - dt
			return
		end
		self.animscale = self.animscale - self.animspeed
		child:SetHeight(self.animscale*self.animheight)
		child:SetWidth(self.animscale*self.animwidth)
	end
end

function CloseIconFan(self)
	for k,v in pairs(self) do
		local child = v:Children()
		v:Hide()
		child:Hide()
		child:EnableInput(false)
			
--		v.animdelay = k*0.1
--		v.animspeed = 0.1
--		v.animstart = Time()
--		v.animtime = 0
--		v.animlastupdate = 0
--		v.animscale = 1
--		v.animheight = v:Height()
--		v.animwidth = v:Width()
--		v:Handle("OnUpdate", CloseFanAnim)
	end
end

-- 

function TouchDown(self)
	local region = CreateorRecycleregion('region', 'backdrop', UIParent)
	region.t:SetTexture(255,255,255,255)
	region:Show()
	region:EnableMoving(true)
	region:EnableResizing(true)
	region:EnableInput(true)
	region:Handle("OnDoubleTap", RecycleSelf)
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

backdrop = Region('region', 'backdrop', UIParent)
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

--[[function FlipPage(self)
--	SetPage(1)
--	return
	if not recorderloaded then
		SetPage(14)
		dofile(SystemPath("urRecorder.lua"))
		Recorderloaded = true
	else
		SetPage(14);
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
--pagebutton:Handle("OnPageEntered", nil)

