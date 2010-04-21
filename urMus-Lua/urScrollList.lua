-- Name urScrollList.lua
-- Description: Provides a full page vertical scroll list of text items that can be fed by a data set containing of three text labels
-- and two optional textures (one for a small icon, one for background)
--
-- Author: Georg Essl
-- Created: 11/23/09
-- Copyright (c) 2010 Georg Essl. All Rights Reserved. See LICENSE.txt for license conditions.

-- Constants

-- Height to reserve for title
local titleHeight = 40
local titleFont = "Trebuchet MS"
local titleColor = { 255 ,255, 255, 255}
local maxVisiblescrollRegions = 8
local scrollRegionGap = 1
local scrollRegionHeight = (ScreenHeight() - titleHeight - maxVisiblescrollRegions*scrollRegionGap)/maxVisiblescrollRegions
local text1Font = "Trebuchet MS"
local text1Width = ScreenWidth()*2/3
local text1Size = 20
local text1Color = { 255, 255, 255, 255 }
local text2Font = "Trebuchet MS"
local text2Width = ScreenWidth()/2
local text2Size = 14
local text2Color = { 255, 255, 0, 255 }
local text3Font = "Trebuchet MS"
local text3Width = ScreenWidth()/2
local text3Size = 16
local text3Color = { 255, 0, 0, 255 }


-- Create local name-space
if not urScrollList then
	urScrollList = {}
	urScrollList.scrollRegions = {}
end

-- Functions to support the scrolling action itself
-- To be used with OnVerticalScroll, currently assumes a bottom boundary at 0.
local abs = math.abs
function urScrollList.ScrollBackdrop(self,diff)

	local bottom = self:Bottom()+diff
	
	if bottom < (0 + maxVisiblescrollRegions*(scrollRegionHeight+scrollRegionGap)) - self:Height() then
		bottom = (0 + maxVisiblescrollRegions*(scrollRegionHeight+scrollRegionGap)) - self:Height()
	end
	if bottom > 0 then
		bottom = 0
	end
	
	self:SetAnchor('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', self:Left() ,bottom)
	for k,v in ipairs(urScrollList.scrollRegions) do
		v.highlit = nil
		v.t:SetTexture(unpack(v.color))
	end
end

-- Scroll action ended, check if we need to align
function urScrollList.ScrollEnds(self)
	local bottom = self:Bottom() - 0
	local div
	div = bottom / (scrollRegionHeight+scrollRegionGap)
	bottom = bottom % (scrollRegionHeight+scrollRegionGap)

	if bottom < (scrollRegionHeight+scrollRegionGap)/2 then
		self:SetAnchor('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', self:Left() ,self:Bottom()-bottom)
	else
		self:SetAnchor('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', self:Left() ,self:Bottom()-bottom+(scrollRegionHeight+scrollRegionGap))
	end
end

-- Initialize the ScrollList from an entries table
-- Format for the entries table is {{"text1","text2","text3",icontexture, backdroptexture}}
function urScrollList:InitScrollList(title, titleicontexture, titlebackdroptextre, entries)

	-- Create Backdrop
	if not urScrollList.BackdropRegion then
		urScrollList.BackdropRegion = Region('region', 'backdrop', UIParent)
		urScrollList.BackdropRegion:SetWidth(ScreenWidth())
		urScrollList.BackdropRegion:SetLayer("LOW")
		urScrollList.BackdropRegion:Handle("OnLeave", urScrollList.ScrollEnds)
		urScrollList.BackdropRegion:Handle("OnTouchUp", urScrollList.ScrollEnds)
		urScrollList.BackdropRegion:Handle("OnVerticalScroll",urScrollList.ScrollBackdrop)
		urScrollList.BackdropRegion:EnableVerticalScroll(true)
		urScrollList.BackdropRegion:EnableInput(true)
		urScrollList.BackdropRegion:Show()
	end
	urScrollList.BackdropRegion:SetHeight(1) -- Hacky
	urScrollList.BackdropRegion:SetAnchor('TOPLEFT',UIParent,'TOPLEFT',0,-titleHeight)--+scrollRegionHeight) 

	if #self.scrollRegions > 0 then
		self:FreeScrollList()
	end
	
	if not self.titleregion then
		local region = Region('region','ScrollListTitle', UIParent)
		region:SetWidth(ScreenWidth())
		region:SetHeight(titleHeight)
		region:SetLayer("MEDIUM")
		region:SetAnchor('TOPLEFT', UIParent, 'TOPLEFT', 0, 0)
		region.tl = region:TextLabel()
		region.tl:SetHorizontalAlign("CENTER")
		region.tl:SetLabelHeight(titleHeight-16)
		region.tl:SetFont(titleFont)
		region.tl:SetColor(unpack(titleColor))
		region.tl:SetShadowColor(0,0,0,80)
		region.tl:SetShadowBlur(2.0)
		region.tl:SetShadowOffset(2,-3)
		region:Handle("OnDoubleTap", urScrollList.LeaveScrollList)
		region:EnableInput(true)
		region:Show()
		
		self.titleregion = region
	end
	self.titleregion.tl:SetLabel(title)
	
	for k, v in pairs(entries) do
		self:CreatescrollRegion(unpack(v))
	end
end

urScrollList.recycledRegions = {}

-- Free and recycle an existing scroll list
function urScrollList:FreeScrollList()

	for k, v in pairs(self.scrollRegions) do
		table.insert(urScrollList.recycledRegions, v)
		v:SetParent(UIParent)
		v:EnableInput(false)
		v:Hide()
		v = nil
	end
	urScrollList.scrollRegions = {}
end

-- Create a single scroll region and insert at given position (or end if nil)
function urScrollList:CreatescrollRegion(text1, text2, text3, callback, color, icontexture, backdroptexture, position)
	local region
	if not position then
		position = #self.scrollRegions + 1
	end
	
	height = urScrollList.BackdropRegion:Height()
	if height == 1 then
		height = 0
	end
	urScrollList.BackdropRegion:SetHeight(height + scrollRegionHeight + scrollRegionGap)
	
	if #self.recycledRegions > 0 then
		region = table.remove(urScrollList.recycledRegions,1) -- Bug hunt: If we remove last from table this bugs, that shouldn't be. NYI flagging it for checking.
	else
		region = Region('region', 'scrollregion'..text1,UIParent)
		region:SetWidth(ScreenWidth())
		region:SetHeight(scrollRegionHeight)
		region:SetLayer("MEDIUM")
		region.t = region:Texture()
		region:Handle("OnTouchDown", urScrollList.HighlightscrollRegion)
		region:Handle("OnTouchUp",urScrollList.SelectscrollRegion)
		region:SetClipRegion(0,0,ScreenWidth(),(scrollRegionHeight+scrollRegionGap)*maxVisiblescrollRegions)
		region:EnableClipping(true)
	end
	if backdroptexture then
		region.t:SetTexture(backdroptexture)
	else
		region.t:SetTexture(unpack(color))
	end
	region:EnableInput(true)
	
	region.callback = callback
	region.data = text1
	region.color = color
	if position == 1 then
		region:SetAnchor("TOP", self.BackdropRegion, "TOP", 0, -scrollRegionGap) -- Anchor first one with backdrop
	else
		region:SetAnchor("TOP", self.scrollRegions[position-1], "BOTTOM", 0, -scrollRegionGap) -- Rest honor their predecessors (they might be giants!)
	end
	if not region.text1region then
		region.text1region = urScrollList:CreateTextRegion(text1, text1Width, text1Font, text1Size, text1Color, "LEFT")
		region.text2region = urScrollList:CreateTextRegion(text2, text2Width, text2Font, text2Size, text2Color, "RIGHT")
		region.text3region = urScrollList:CreateTextRegion(text3, text3Width, text3Font, text3Size, text3Color, "RIGHT")
		region.text1region:SetAnchor("TOPLEFT", region, "TOPLEFT", 0,0)
		region.text2region:SetAnchor("TOPRIGHT", region, "TOPRIGHT", 0, 0)
		region.text3region:SetAnchor("BOTTOMRIGHT", region, "BOTTOMRIGHT", 0,0)
	else
		urScrollList:SetLabelRegion(region.text1region, text1, text1Font, text1Color)
		urScrollList:SetLabelRegion(region.text2region, text2, text2Font, text2Color)
		urScrollList:SetLabelRegion(region.text3region, text3, text3Font, text3Color)
	end
	region:Show()
	
	table.insert(self.scrollRegions, position, region)
end

-- Sets attributes of text regions
function urScrollList:SetLabelRegion(region, label, font, color)
	region.tl:SetLabel(label or "")
	region.tl:SetColor(unpack(color))
	region.tl:SetShadowColor(0,0,0,190)
	region.tl:SetShadowBlur(2.0)
	region.tl:SetShadowOffset(2,-3)
	region.tl:SetFont(font)
end

-- Creates a text-carrying region without texture
function urScrollList:CreateTextRegion(label, width, font, size, color, justify)
	local region
	region = Region('region', 'label'..(label or ""), UIParent)
	region:SetHeight(size+2)
	region:SetWidth(width)
	region:SetLayer("HIGH")
	region.tl = region:TextLabel()
	urScrollList:SetLabelRegion(region, label, font, color)
	region.tl:SetLabelHeight(size)
	region.tl:SetHorizontalAlign(justify)
	region.tl:SetVerticalAlign("TOP")
	region:Show()
	region:SetClipRegion(0,0,ScreenWidth(),(scrollRegionHeight+scrollRegionGap)*maxVisiblescrollRegions)

	region:EnableClipping(true)
	return region
end

function urScrollList:OpenScrollListPage(page, ...)
	self:ReopenScrollListPage(page)
	self:InitScrollList(...)
end

function urScrollList:ReopenScrollListPage(page)
	urScrollList.returnPage = Page()
	SetPage(page)
end

function urScrollList.HighlightscrollRegion(self)
	local r,g,b = unpack(self.color)
	self.t:SetTexture(r+50,g+50,b+50,255)
	self.highlit = true
end

function urScrollList.UnhighlightscrollRegion(self)
	self.t:SetTexture(unpack(self.color))
	self.highlit = nil
end

function urScrollList.LeaveScrollList(self)
	SetPage(urScrollList.returnPage)
end

function urScrollList.SelectscrollRegion(self)
	if self.highlit then
		SetPage(urScrollList.returnPage)
		self.callback(self.data)
	end
end
