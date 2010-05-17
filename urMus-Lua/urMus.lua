-- urMus default interface
-- by Georg Essl
-- Started a long time ago as a first test case, still best and most complex test case!
-- Last modified: 04/04/2010
-- Copyright (c) 2010 Georg Essl. All Rights Reserved. See LICENSE.txt for license conditions.

dofile(SystemPath("urHelpers.lua"))
Req("urWidget")

local sqrt = math.sqrt
local PI = math.pi
local min = math.min
local sin = math.sin
local cos = math.cos
local ceil = math.ceil

pagefile = {
"urMus",
"urPiano.lua",
"urFlute.lua",
"urPitcher.lua",
"urBlank.lua",
"urPlayground.lua",
"urRecorder.lua",
"urPads.lua",
"urCloud.lua",
--"urClockSeq.lua",
"urSleigh.lua",
"urThumper.lua",
"urPitchWheel.lua",
"urColors.lua",
"urSmudge.lua",
"urPong.lua",
"urVisDemo.lua",
"urTiles.lua",
"urVisGraph.lua",
"urTicTacToe.lua",
"urOsman.lua"
}

scrollpage = 29

pageloaded = {}
pageloaded["urMus"] = 1

num_linked_pages = 13
next_linked_page = 1
next_free_page = 2

-- Make pager bigger for large finger people
pagersize = 32
--pagersize = 24

-- Load utility and library functions here
dofile(SystemPath("urScrollList.lua"))

local titlebar = 28
local menubottonheight = titlebar
local selectorheight = 122
local editheightmargins = titlebar + selectorheight
local editwidthmargins = 0
local editselwidthmargins = 68

local minrow = ceil((ScreenHeight() - editheightmargins)/110)

local mincol = ceil(ScreenWidth()/(320.0/3.0))
local mineditcol = 3

local maxselrows = minrow

local rowheight = (ScreenHeight()-editheightmargins)/minrow -- 110 -- aka rawhide
local protocellheight = 80 --ScreenHeight()/6
local colwidth = (ScreenWidth()-editwidthmargins)/mincol
local colselwidth = (ScreenWidth()-editselwidthmargins)/mincol
local protocellwidth = 64 -- 78 --ScreenWidth()/5

local maxrow = 0
local currentrow = 1

-- Notification Information Overlay

function FadeNotification(self, elapsed)
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

function ShowNotification(note)
	notificationregion.textlabel:SetLabel(note)
	notificationregion.staytime = 1.5
	notificationregion.fadetime = 2.0
	notificationregion.alpha = 1
	notificationregion.alphaslope = 2
	notificationregion:Handle("OnUpdate", FadeNotification)
	notificationregion:SetAlpha(1.0)
	notificationregion:Show()
end

-- This is straight from PIL
function basicSerialize (o)
	if type(o) == "number" then
		return tostring(o)
	else   -- assume it is a string
		return string.format("%q", o)
	end
end

function save (name, value, saved)
	saved = saved or {}       -- initial value
	io.write(name, " = ")
	if type(value) == "number" or type(value) == "string" then
		io.write(basicSerialize(value), "\n")
	elseif type(value) == "table" then
		if saved[value] then    -- value already saved?
			io.write(saved[value], "\n")  -- use its previous name
		else
			saved[value] = name   -- save name for next time
			io.write("{}\n")     -- create a new table
			for k,v in pairs(value) do      -- save its fields
				local fieldname = string.format("%s[%s]", name, basicSerialize(k))
				save(fieldname, v, saved)
			end
		end
	else
		error("cannot save a " .. type(value))
	end
end

-- Loading, saving, settings

settingdata = {}
settingdata.grid = {} -- rows
for row = 1, minrow do
	settingdata.grid[row] = {}
end

function DumpSettings()
	local str = ""
	for row = 1, maxrow do
		for k,v in pairs(settingdata.grid[row]) do
			if v then
				str = str .. (v.name or "nil").." "..(v.pushlink or "nil").." "..(v.pulllink or "nil").." - "
			end
		end
		str = str .. "\n"
	end
	DPrint("Settings: "..str)
end

function CreateSaveName()
	local sources = {}
	local filters = {}
	local sinks = {}
	
	local name
	
	for row = 1, maxrow do
		for col = 1,backdropanchor[row].count do
			local region = rowregions[row][col]
			if region then
				name =  region.flowbox:Name()
				if col == 1 then
					sources[name] = sources[name] or 0
					sources[name] = sources[name] + 1
				elseif col == backdropanchor[row].count then
					sinks[name] = sinks[name] or 0
					sinks[name] = sinks[name] + 1
				else
					filters[name] = filters[name] or 0
					filters[name] = filters[name] + 1
				end
			end
		end
	end
	
	local outstr = ""
	for k,v in pairs(sources) do
		outstr = outstr .. k
	end
	outstr =outstr .. "-"
	for k,v in pairs(filters) do
		outstr = outstr .. k
	end
	outstr =outstr .. "-"
	for k,v in pairs(sinks) do
		outstr = outstr .. k
	end
	return outstr
end


function CreateSettings()

	-- Create clean slate
	for row = 1,maxrow do
		if not settingdata.grid[row] then
			settingdata.grid[row] = {}
		else
			for col, v in pairs(settingdata.grid[row]) do
				v = nil
				if col > minrow then
					settingdata.grid[row] = nil
				end
			end
		end
	end

	for row = #settingdata.grid,maxrow+1,-1  do
		table.remove(settingdata.grid, row)
	end

	for row = 1, maxrow do
		for col = 1,backdropanchor[row].count do
			local region = rowregions[row][col]
			settingdata.grid[row] = settingdata.grid[row] or {}
			settingdata.grid[row][col] = settingdata.grid[row][col] or {}
			if region then
				settingdata.grid[row][col].name = region.flowbox:Name()
				settingdata.grid[row][col].instancenumber = region.flowbox:InstanceNumber()
				settingdata.grid[row][col].fbtype = region.fbtype
				settingdata.grid[row][col].innr = region.innr
				settingdata.grid[row][col].outnr = region.outnr
			else
				settingdata.grid[row][col] = nil
			end
		end
	end

	for row = 1, maxrow do
		for col = 2,backdropanchor[row].count do
			local thisregion = rowregions[row][col]
			local inregion = rowregions[row][col-1]
			if inregion and thisregion then
				if inregion.flowbox:IsPushed(inregion.outnr,thisregion.flowbox,thisregion.innr) then
					settingdata.grid[row][col].pushlink = 1
				else
					settingdata.grid[row][col].pushlink = nil
				end
				if thisregion.flowbox:IsPulled(0,inregion.flowbox,0) then
					settingdata.grid[row][col].pulllink = 1
				else
					settingdata.grid[row][col].pulllink = nil					
				end
			else
				settingdata.grid[row][col] = settingdata.grid[row][col] or {}
				settingdata.grid[row][col].pulllink = nil					
				settingdata.grid[row][col].pushlink = nil
			end
		end
	end
end

function SaveSettingFile(file)
	CreateSettings()
	local nfile = CreateSaveName()
	os.rename(DocumentPath(file),DocumentPath(nfile))
	file = nfile
	io.open(DocumentPath(file), "w")
	io.output(DocumentPath(file))
	save("settingdata", settingdata)
	io.output():close()
	ShowNotification("Saved")
end

function SaveSettings()
	local scrollentries = {}

	for v in lfs.dir(DocumentPath("")) do
		if v ~= "." and v ~= ".." then
			local entry = { v, lfs.attributes(v,"size"), lfs.attributes(v,"modification"), SaveSettingFile, {84,84,84,255}}
			table.insert(scrollentries, entry)
		end
	end

	local entry = { CreateSaveName(), "Empty", "New File", SaveSettingFile, {150,84,84,255}}
	table.insert(scrollentries, entry)

	urScrollList:OpenScrollListPage(scrollpage, "Save", nil, nil, scrollentries)
end

function LoadSettingFile(file)
	-- This loads data
	_, error = io.open(DocumentPath(file), "r")
	if not error then
		dofile(DocumentPath(file))
		ShowNotification("Loading")
		return true
	else
		ShowNotification(error)
		return nil
	end
end

function LoadAndActivateSettings(file)
	ClearSetup()
	if LoadSettingFile(file) then
		ActivateSettings()
	end
end


function LoadSettings()

	local scrollentries = {}

	for v in lfs.dir(DocumentPath("")) do
		if v ~= "." and v ~= ".." then
			local entry = { v, lfs.attributes(v,"size"), lfs.attributes(v,"modification"), LoadAndActivateSettings, {84,84,84,255}}
			table.insert(scrollentries, entry)
		end
	end

	urScrollList:OpenScrollListPage(scrollpage, "Load", nil, nil, scrollentries)
end

function ActivateSettings()

	local oldmaxrow = maxrow
	
	for row=oldmaxrow, #settingdata.grid-1 do
		AddRow(row)
	end

	maxrow = #settingdata.grid

	for row = 1, maxrow do
		for col = 4,#settingdata.grid[row] do
			SplitArrow(fbconnect[row][2])
		end
		
		for col, v in pairs(settingdata.grid[row]) do
			if v and v.name then
				
				local x = 0
				local y = 0
				local fbtype = v.fbtype
				local innr = v.innr
				local outnr = v.outnr
				local instancenumber = v.instancenumber
				local flowbox = _G["FB"..v.name]
				local object = v.name
				local lets
				
				if fbtype == 1 then
					lets = {flowbox:Outs()}
				else
					lets = {flowbox:Ins()}
				end
				local inidx
				if fbtype == 1 then
					inidx = outnr
				else
					inidx = innr
				end
				
				local activelock = celllock[row][col]
				activelock.locked = true

				local thisregion = CreateButton(x,y,col,fbtype, object, flowbox, inidx, instancenumber)
				local label = object
				if thisregion.flowbox:IsInstantiable() then
					label = label .." ("..thisregion.flowbox:InstanceNumber()..")"
				end
				label = label .."\n"..lets[inidx+1]
				thisregion.textlabel:SetLabel(label)
				thisregion.row = row
				thisregion.column = col
				thisregion.fbtype = fbtype
				thisregion:SetAnchor('CENTER',activelock, 'CENTER', 0,0) 

				thisregion:SetClipRegion(0,selectorheight,ScreenWidth(),rowheight*minrow)
				thisregion:EnableClipping(true)

				rowregions[row][col] = thisregion
			end
		end
	end

	for row = 1, maxrow do
		for col, v in pairs(settingdata.grid[row]) do
			if v then
				local thisregion = rowregions[row][col]
				local inregion = rowregions[row][col-1]
				if v.pushlink then
					inregion.flowbox:SetPushLink(inregion.outnr,thisregion.flowbox,thisregion.innr)
					fbconnect[row][col-1]:Show()
				end
				if v.pulllink then
					thisregion.flowbox:SetPullLink(thisregion.innr,inregion.flowbox,inregion.outnr)
					fbconnect[row][col-1]:Show()
				end
			end
		end
	end
	
	RefreshRowIndices(1)

    ShowNotification("Loaded")
end

-- Clear current setup

function ClearSetup()
	for row = 1, maxrow do
		for col, v in pairs(rowregions[row]) do
			if col > 1  and v and rowregions[row][col-1] then
				local thisregion = rowregions[row][col]
				local inregion = rowregions[row][col-1]
				inregion.flowbox:RemovePushLink(inregion.outnr,thisregion.flowbox,thisregion.innr)
				thisregion.flowbox:RemovePullLink(thisregion.innr,inregion.flowbox,inregion.outnr)
			end
		end
	end
	for row = 1, maxrow do
		for col= 1, backdropanchor[row].count do
			local activelock = celllock[row][col]
			activelock.locked = nil
			if rowregions[row][col] then
				FreeButton(rowregions[row][col])
			end
			if rowregions[row][col] then
				rowregions[row][col]:SetParent(UIParent)
			end
			rowregions[row][col] = nil
			if col > 1 then
				fbconnect[row][col-1]:Hide()
			end	
		end
	end
	for row = 1,maxrow do
		local count = backdropanchor[row].count
		for i=4, count do
			MergeArrow(celllock[row][2])
		end
	end
	
	for row = maxrow,4,-1 do
		RemoveRow(row)
	end
	maxrow = minrow
	ShowNotification("Cleared")
end

-- Main setup of flowboxes and layouting

local sin = math.sin

local fbobjs = {}
fbobjs[1] = {SourceNames()}
fbobjs[2] = {ManipulatorNames()}
fbobjs[3] = {SinkNames()}
local fblabels = {}
fblabels[1] = {}
fblabels[2] = {}
fblabels[3] = {}
local fbboxes = {}
fbboxes[1] = {}
fbboxes[2] = {}
fbboxes[3] = {}
local fblets = {}
fblets[1] = {}
fblets[2] = {}
fblets[3] = {}
local fbpos = {}
fbpos[1] = 1
fbpos[2] = 1
fbpos[3] = 1

-- Set the flowbox color of an entity
function SetFlowboxColor(texture, fbtype)
	if fbtype == 1 then
		texture:SetGradientColor("TOP",255,0,0,255,255,0,0,255)
		texture:SetGradientColor("BOTTOM",255,0,0,255,255,0,0,255)
	elseif fbtype == 2 then
		texture:SetGradientColor("TOP",0,255,0,255,0,255,0,255)
		texture:SetGradientColor("BOTTOM",0,255,0,255,0,255,0,255)
	elseif fbtype == 3 then
		texture:SetGradientColor("TOP",0,0,255,255,0,0,255,255)
		texture:SetGradientColor("BOTTOM",0,0,255,255,0,0,255,255)
	end
end

-- Set a lock flowbox color
function SetFlowboxLockColor(texture, fbtype)
	if fbtype == 1 then
		texture:SetTexture(140,0,0,255)
	elseif fbtype == 2 then
		texture:SetTexture(0,140,0,255)
	elseif fbtype == 3 then
		texture:SetTexture(0,0,140,255)
	end
end

-- Set a backdrop flowbox color
function SetFlowboxBackdropColor(texture, fbtype)
	if fbtype == 1 then
		texture:SetTexture(160,0,0,128)
	elseif fbtype == 2 then
		texture:SetTexture(0,160,0,128)
	elseif fbtype == 3 then
		texture:SetTexture(0,0,160,128)
	end		
end

-- Set a backdrop flowbox color
function SetTexturedFlowboxBackdropColor(texture, fbtype)
	if fbtype == 1 then
		texture:SetGradientColor("TOP",160,0,0,255,160,0,0,255)
		texture:SetGradientColor("BOTTOM",160,0,0,255,160,0,0,255)
	elseif fbtype == 2 then
		texture:SetGradientColor("TOP",0,160,0,255,0,160,0,255)
		texture:SetGradientColor("BOTTOM",0,160,0,255,0,160,0,255)
	elseif fbtype == 3 then
		texture:SetGradientColor("TOP",0,0,160,255,0,0,160,255)
		texture:SetGradientColor("BOTTOM",0,0,160,255,0,0,160,255)
	end		
end

-- Set an nav arrow color
function SetNavigationArrowColor(texture, fbtype)
	if fbtype == 1 then
		texture:SetGradientColor("TOP",160,0,0,255,160,0,0,255)
		texture:SetGradientColor("BOTTOM",255,0,0,255,255,0,0,255)
	elseif fbtype == 2 then
		texture:SetGradientColor("TOP",0,160,0,255,0,160,0,255)
		texture:SetGradientColor("BOTTOM",0,225,0,255,0,225,0,255)
	elseif fbtype == 3 then
		texture:SetGradientColor("TOP",0,0,160,255,0,0,160,255)
		texture:SetGradientColor("BOTTOM",0,0,225,255,0,0,225,255)
	end
end

-- Set an nav arrow select color
function SetNavigationArrowSelectColor(texture, fbtype)
	if fbtype == 1 then
		texture:SetGradientColor("TOP",160,0,0,255,160,0,0,255)
		texture:SetGradientColor("BOTTOM",160,0,0,255,160,0,0,255)
	elseif fbtype == 2 then
		texture:SetGradientColor("TOP",0,160,0,255,0,160,0,255)
		texture:SetGradientColor("BOTTOM",0,160,0,255,0,160,0,255)
	elseif fbtype == 3 then
		texture:SetGradientColor("TOP",0,0,160,255,0,0,160,255)
		texture:SetGradientColor("BOTTOM",0,0,160,255,0,0,160,255)
	end
end

local recyclebuttons = {}
local recycleflowboxes = {}

function PrintInstanceLocks(flowbox, let, prefix)
	local bflowbox = _G["FB"..flowbox:Name()]
	local instances = bflowbox.instances
	local str = prefix..": "
	for k,v in ipairs (instances) do
		if v.let[let] then
			str = str .. "1 "
		else
			str = str .. "0 "
		end
	end
	DPrint(str.."-")
end

function PrintRowRegions(row, prefix)
	local str = ""..(prefix or "")
	for k,v in pairs (rowregions[row]) do
		str = str .. k
		if not v then
			str = str.."n"
		end
		str = str .. " "
	end
	DPrint(str .. "!")
	return str
end

function FreeButton(button)
	button:EnableInput(false)
	button:EnableMoving(false)
	button:Hide()
	button:SetParent(UIParent)
	local bflowbox = _G["FB"..button.flowbox:Name()]
	
	local instances = bflowbox.instances
	
	if instances and not instances[button.flowbox:InstanceNumber()] then
		table.insert(instances,button.flowbox)
		instances[button.flowbox:InstanceNumber()].let = {}
	end
	if instances then
		local let = instances[button.flowbox:InstanceNumber()].let
		
		local inidx
		if button.fbtype == 1 then
			inidx = button.outnr
		else
			inidx = button.innr
		end
		if button.flowbox:InstanceNumber() > 0 and let then
			let[inidx] = nil
		end
	end

	if bflowbox ~= button.flowbox then
			table.insert(recycleflowboxes, button.flowbox)
	end
	
	button.flowbox = nil
	table.insert(recyclebuttons,button)
	
end

function FindFreeInstance(flowbox, inidx)

	for k,v in ipairs(_G["FB"..flowbox:Name()].instances) do
		if not v.let[inidx] then return k end
	end
	
	return _G["FB"..flowbox:Name()]:NumberInstances()+1
end

function FindRecycledorActiveFlowbox(name, idx, instance, instances)

	if instance == -1 then
		instance = FindFreeInstance(_G["FB"..name],idx)
	end

	for k, v in ipairs(recycleflowboxes) do
		if v:Name() == name and v:InstanceNumber() == instance and not _G["FB"..v:Name()].instances[instance].let[idx] then
			table.remove(recycleflowboxes,k)
			_G["FB"..v:Name()].instances[instance].let[idx] = true
			local let = _G["FB"..v:Name()].instances[instance].let
			local str=""
			for k,v in pairs(let) do
				if v then
					str = str .. "1 "
				else
					str = str .. "0 "
				end
			end
			return v
		end
	end
	for k,v in ipairs(instances) do
		if v:InstanceNumber() == instance and not v.let[idx] then
			_G["FB"..v:Name()].instances[instance].let[idx] = true
			local let = _G["FB"..v:Name()].instances[instance].let
			return v
		end
	end
	return nil
end

function CreateButton(x,y,col,fbtype,label,flowbox,inidx, instance)
	local returnbutton
	if #recyclebuttons > 0 then
		returnbutton = recyclebuttons[#recyclebuttons]
		table.remove(recyclebuttons)
		SetFlowboxColor(returnbutton.texture, fbtype)
		returnbutton.textlabel:SetLabel(label)
		returnbutton:EnableInput(true)
		returnbutton:EnableMoving(true)
		returnbutton:Show()
	else
		returnbutton=Region('region', 'sourcesel', UIParent)
		returnbutton:SetWidth(protocellwidth)
		returnbutton:SetHeight(protocellheight)
		returnbutton:SetLayer("DIALOG")
		returnbutton:SetAnchor('BOTTOMLEFT',switchbackdrop,'BOTTOMLEFT',x,y) 
--		returnbutton:EnableClamping(true)
		returnbutton.lockposx = x
		returnbutton.lockposy = y
		returnbutton.column = col
		returnbutton.fbtype = fbtype
		returnbutton:Handle("OnTouchDown", UnlockCursor)
--		returnbutton:Handle("OnDragStart", UnlockCursor)
--		returnbutton:Handle("OnTouchUp", LockCursor)
		returnbutton:Handle("OnDragStop", LockCursor)
		returnbutton.textlabel=returnbutton:TextLabel()
		returnbutton.textlabel:SetFont("Trebuchet MS")
		returnbutton.textlabel:SetHorizontalAlign("CENTER")
		returnbutton.textlabel:SetLabel(label)
		returnbutton.textlabel:SetLabelHeight(16)
		returnbutton.textlabel:SetColor(255,255,255,255)
		returnbutton.textlabel:SetShadowColor(0,0,0,190)
		returnbutton.textlabel:SetShadowBlur(2.0)
		returnbutton.texture = returnbutton:Texture("button.png")
		SetFlowboxColor(returnbutton.texture, fbtype)
		returnbutton.texture:SetTexCoord(0,1.0,0,0.625)
		returnbutton:EnableInput(true)
		returnbutton:EnableMoving(true)
		returnbutton:Show()
		returnbutton.docked = false
		returnbutton.floater = true
	end
	
	if flowbox:IsInstantiable() and flowbox:InstanceNumber()==0 then
	
		local rflowbox = FindRecycledorActiveFlowbox(flowbox:Name(),inidx,instance, flowbox.instances)

		if not rflowbox then
			local cflowbox
			local object = flowbox:Name()
			cflowbox = FlowBox("object", object.." ("..(#flowbox.instances+1)..")", flowbox)
			cflowbox.let = cflowbox.let or {}
			cflowbox.let[inidx] = false
			table.insert(flowbox.instances,cflowbox)
			while flowbox:NumberInstances() <= instance do
				cflowbox = FlowBox("object", object.." ("..(#flowbox.instances+1)..")", flowbox)
				cflowbox.let = cflowbox.let or {}
				cflowbox.let[inidx] = false
				table.insert(flowbox.instances,cflowbox)
			end
			cflowbox.let[inidx] = true

			local pos = fbpos[fbtype]
			local lets
			if fbtype == 1 then
				lets = {flowbox:Outs()}
			else
				lets = {flowbox:Ins()}
			end
			for k,letstr in pairs(lets) do
				if letstr then
					local label = object.." ("..#flowbox.instances..")".."\n"..letstr--.."("..(k-1)..")"
					if k-1 == inidx then
						returnbutton.textlabel:SetLabel(label)
					end
				end
			end
			flowbox = cflowbox
		else
			local object = rflowbox:Name()
			local lets
			if fbtype == 1 then
				lets = {rflowbox:Outs()}
			else
				lets = {rflowbox:Ins()}
			end
			local letstr = lets[inidx+1]
			local label = object.." ("..rflowbox:InstanceNumber()..")".."\n"..letstr--.."("..inidx..")"
			returnbutton.textlabel:SetLabel(label)
			flowbox = rflowbox
			flowbox.let[inidx] = true
		end
	end

	returnbutton.flowbox = flowbox
	if fbtype == 1 then
		returnbutton.outnr = inidx
	elseif fbtype == 2 then
		returnbutton.outnr = 0
		returnbutton.innr = inidx
	else
		returnbutton.innr = inidx
	end
	return returnbutton
end

-- Unlinks at a canonical connector position (+1)
function UnlinkFlowboxes(row,col)
	if col > 1 and  col <= backdropanchor[row].count then
		local thisregion = rowregions[row][col]
		local inregion = rowregions[row][col-1]
		if inregion and thisregion then
			local fbtype = thisregion.fbtype
			inregion.flowbox:RemovePushLink(inregion.outnr,thisregion.flowbox,thisregion.innr)
			thisregion.flowbox:RemovePullLink(thisregion.innr,inregion.flowbox,inregion.outnr)
			fbconnect[row][col-1]:Hide()
		end
	end
end

function FindEffectiveFlowblockType(row, col)
	
	local downstream = backdropanchor[row].count - 1
	local downstreamtype = 2
	while downstream > col and rowregions[row][downstream] and rowregions[row][downstream].flowbox:IsCoupled() do
		downstream = downstream - 1
	end
	if downstream > col then
		downstreamtype = nil
	end
	
	local upstream = 2
	local upstreamtype = 1
	while upstream < col and rowregions[row][upstream] and rowregions[row][upstream].flowbox:IsCoupled() do
		upstream = upstream + 1
	end
	if upstream < col then
		upstreamtype = nil
	end
	return upstreamtype, downstreamtype
end

-- Lins at a canonical connector position (+1)
function LinkFlowboxes(row, col)
	if col > 1 and  col <= backdropanchor[row].count then
		local thisregion = rowregions[row][col]
		local inregion = rowregions[row][col-1]
		if inregion and thisregion then
			local fbtype = thisregion.fbtype
			local us,ds = FindEffectiveFlowblockType(row, col)
			if us then
				inregion.flowbox:SetPushLink(inregion.outnr,thisregion.flowbox,thisregion.innr)
			elseif ds then
				thisregion.flowbox:SetPullLink(thisregion.innr,inregion.flowbox,inregion.outnr)
			else
--			-- Two streams collide. The new node is a stream merger. Current convention is that we Pull converters take preference
--				inregion.flowbox:SetPushLink(inregion.outnr,thisregion.flowbox,thisregion.innr)
--				thisregion.flowbox:SetPullLink(0,inregion.flowbox,0)
			end
			fbconnect[row][col-1]:Show()
		end
	end
end

function UnlockCursor(self)
	if self:IsShown() and self.row then
		local parent = self:Parent()
		if parent then
			parent.locked = nil
			RegisterLock(parent)
		end
	
		local col =  parent.column -- Need to grab col from anchor because we may have had an insert
		local row = self.row
		
		UnlinkFlowboxes(row, col)
		UnlinkFlowboxes(row, col+1)

		if rowregions[row][col] then
			rowregions[row][col]:EnableClipping(false)
		end
		rowregions[row][col] = nil
	end
end

function LockCursor(self)
	if not self:IsShown() then
		return
	end

	local activelock = FindActiveLock(self)

	local x,y = InputPosition()
	local fbtype = self.fbtype
	if not self.floater then
		self:SetAnchor('BOTTOMLEFT',switchbackdrop,'BOTTOMLEFT',self.lockposx, self.lockposy)
		if fbtype ~= activefbtype then
			self:EnableInput(false)
			self:EnableMoving(false)
			self:Hide()
		end
		self.row = nil
		self.docked = true
	end
	
	if activelock and activelock.fbtype == fbtype and not activelock.locked then
		activelock.locked = true
		local col = activelock.column

		local inidx
		if fbtype == 1 then
			inidx = self.outnr
		else
			inidx = self.innr
		end

		local thisregion
		
		if not self.floater then
			thisregion = CreateButton(x,y,col,fbtype,self.textlabel:Label(),self.flowbox,inidx, -1)
		else
			thisregion = self
		end
		local row = activelock.row
		thisregion.row = row
		thisregion.column = col
		thisregion.fbtype = fbtype
		thisregion:SetAnchor('CENTER',activelock, 'CENTER', 0,0) 
		
		
		thisregion:SetClipRegion(0,selectorheight,ScreenWidth(),rowheight*minrow)
		thisregion:EnableClipping(true)
		rowregions[row][col] = thisregion

		LinkFlowboxes(row,col)
		LinkFlowboxes(row, col+1)

		return
	end
	
	if self.floater then
		FreeButton(self)
	end
end

-- This stored activates flowbox regions in each row. If nil no flowbox is set. Else the content is the region attached to the flowbox.
rowregions = {}


-- This is the scroll backdrop for each row
backdropanchor = {}

-- This contains the backdrop information for each cell.
cellbackdrop = {}

-- Set up lock regions.

celllock = {}

-- Setup connector arrows

fbconnect = {}

activelocks = {}

-- Use hovering ("touch-overs") to register potential lock regions
-- Register on Enter
function RegisterLock(self)
	if not self.locked then
		table.insert(activelocks,self)
	end
end

-- Unregister on Leave
function UnRegisterLock(self)
	for k,activelock in pairs(activelocks) do
		if activelock == self then
			table.remove(activelocks, k)
			activelock = nil
		end
	end
end

function FindActiveLock(self)
	local cutoff = switchbackdrop:Top();
	local _,y = InputPosition();
	if y < cutoff then
		return nil
	end
	for k, activelock in pairs(activelocks) do
		if activelock:RegionOverlap(self) then
			return activelock
		end
	end
end

-- Scroll functions
-- Scroll action ended, check if we need to align
function ScrollEnds(self)
	local left = self:Left()
	local div
	div = left / (colwidth)
	left = left % (colwidth)
	
	if left < ScreenWidth()/6 then
		self:SetAnchor('BOTTOMLEFT', rowbackdropanchor, 'BOTTOMLEFT', self:Left()-left ,self:Bottom()-rowbackdropanchor:Bottom())
	else
		self:SetAnchor('BOTTOMLEFT', rowbackdropanchor, 'BOTTOMLEFT', self:Left()-left+colwidth ,self:Bottom()-rowbackdropanchor:Bottom())
	end
end

-- Scroll, protect against going out of bounds
function ScrollBackdrop(self, diff)
	local left = self:Left()+diff
	
	if left < ScreenWidth() - self:Width() then
		left = ScreenWidth() - self:Width()
	end
	if left > 0 then
		left = 0
	end
	
	self:SetAnchor('BOTTOMLEFT', rowbackdropanchor, 'BOTTOMLEFT', left ,self:Bottom()-rowbackdropanchor:Bottom())
end

-- When tapping an empty filter lock we may merge

local recyclecellbackdrop = {}
local recyclecelllock = {}
local recyclefbconnect = {}

function RecycleCell(row, col)
	celllock[row][col]:SetParent(UIParent)
	celllock[row][col]:Handle("OnEnter",nil)
	celllock[row][col]:Handle("OnLeave",nil)
	celllock[row][col]:Hide()
	celllock[row][col]:EnableInput(false)
	cellbackdrop[row][col]:SetParent(UIParent)
	cellbackdrop[row][col]:Hide()
	cellbackdrop[row][col]:EnableInput(false)
	table.insert(recyclecellbackdrop, cellbackdrop[row][col])
	table.remove(cellbackdrop[row], col)
	table.insert(recyclecelllock, celllock[row][col])
	table.remove(celllock[row], col, newcelllock)
	if col > 1 then
		fbconnect[row][col-1]:SetParent(UIParent)
		fbconnect[row][col-1]:Hide()
		fbconnect[row][col-1]:EnableInput(false)
		table.insert(recyclefbconnect, fbconnect[row][col-1])
		table.remove(fbconnect[row], col-1)
	end
end

function MergeArrow(self)

	local backdrop = self.backdrop
	local row = self.row
	local col = self.column
	local fbtype = 2

	if backdrop.count > mineditcol then
		backdrop:SetWidth(backdrop:Width()-colwidth)
		backdrop.count = backdrop.count - 1

		RecycleCell(row, col)

		for ncol = col-1,backdrop.count-1 do
			fbconnect[row][ncol].column = ncol
		end

		for ncol = col+1, backdrop.count+1 do
			rowregions[row][ncol-1] = rowregions[row][ncol]
		end
		rowregions[row][backdrop.count+1] = nil

		for ncol = col, backdrop.count do
			celllock[row][ncol].column = ncol 
		end

		LinkFlowboxes(row,col)
		
		cellbackdrop[row][col]:SetAnchor('LEFT', cellbackdrop[row][col-1], 'RIGHT', 0, 0)
		ScrollBackdrop(backdrop, 0)
		RefreshRowIndices(1)
	else
		RemoveRow(self.row)
	end
end

-- Set up scroll/backdrop regions as well as associated lock regions

function EnableRow(row)
	backdropanchor[row]:EnableInput(true)
	for col = 1,backdropanchor[row].count do
		cellbackdrop[row][col]:Show()
		celllock[row][col]:EnableInput(true)
		celllock[row][col]:Show()
		if rowregions[row][col] then
			rowregions[row][col]:EnableInput(true)
			rowregions[row][col]:Show()
		end
	end
	
	for col = 1,backdropanchor[row].count-1 do
		fbconnect[row][col]:EnableInput(true)
		local thisregion = rowregions[row][col+1]
		local inregion = rowregions[row][col]
		if thisregion and inregion then
			fbconnect[row][col]:Show()
		end
	end
end

function DisableRow(row)
	backdropanchor[row]:EnableInput(false)
	for col = 1,backdropanchor[row].count do
		celllock[row][col]:EnableInput(false)
		if rowregions[row][col] then
			rowregions[row][col]:EnableInput(false)
		end
	end

	for col = 1,backdropanchor[row].count-1 do
		fbconnect[row][col]:EnableInput(false)
		local thisregion = rowregions[row][col+1]
		local inregion = rowregions[row][col]
		if thisregion and inregion then
		end
	end
end

local maxcellpos = maxselrows*mincol -- 3 for one row
local cellrows = 1

local scrollposy = 0
local abs = math.abs
function ScrollRowBackdrop(self, diff)

	local bottom = self:Bottom()+diff
	
	if bottom < (selectorheight + minrow*rowheight) - self:Height() then
		bottom = (selectorheight + minrow*rowheight) - self:Height()
	end
	
	if bottom > switchbackdrop:Top() then
		bottom = switchbackdrop:Top()
	end
	
	self:SetAnchor('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', self:Left() ,bottom)
end

-- Scroll action ended, check if we need to align
function ScrollRowEnds(self)
	local bottom = self:Bottom() - selectorheight
	local div
	div = bottom / rowheight
	bottom = bottom % rowheight
	 
	if bottom < rowheight/2 then
		self:SetAnchor('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', self:Left() ,self:Bottom()-bottom)
	else
		self:SetAnchor('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', self:Left() ,self:Bottom()-bottom+rowheight)
	end

	if self:Bottom() > switchbackdrop:Top() then
		self:SetAnchor('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', self:Left(), switchbackdrop:Top())
	end

	top = self:Top() - selectorheight
	div = top / rowheight
	currentrow = div-(minrow-1)
	RefreshRowIndices(1)
end


rowbackdropanchor = Region('region', 'rowbackdrop', UIParent)
rowbackdropanchor:SetWidth(ScreenWidth())
rowbackdropanchor:SetHeight(1 --[[ 3*rowheight --]]) -- Hacky, current engine doesn't allow regions of height 0 without issues
rowbackdropanchor:SetLayer("LOW")
rowbackdropanchor:SetAnchor('TOPLEFT',UIParent,'TOPLEFT',0,-titlebar+rowheight) 
rowbackdropanchor:Handle("OnLeave", ScrollRowEnds)
rowbackdropanchor:Handle("OnTouchUp", ScrollRowEnds)
rowbackdropanchor:Handle("OnVerticalScroll",ScrollRowBackdrop)
rowbackdropanchor:EnableVerticalScroll(true)
rowbackdropanchor:SetClipRegion(0,selectorheight,ScreenWidth(),rowheight*minrow)
rowbackdropanchor:EnableClipping(true)
rowbackdropanchor:EnableInput(true)
rowbackdropanchor.row = row
rowbackdropanchor.count = mincol
rowbackdropanchor:Show()

function ColumnToFBType(col)
	if col == 1 then
		return 1
	elseif col == mineditcol then
		return 3
	else
		return 2
	end
end

function RefreshRowIndices(row)
	for r = row, maxrow do
		backdropanchor[r]:SetAnchor('TOPLEFT',rowbackdropanchor,'TOPLEFT',backdropanchor[r]:Left(),-rowheight*(r-1))
		backdropanchor[r].row = r
		for col = 1, backdropanchor[r].count do
			cellbackdrop[r][col].row = r
			celllock[r][col].row = r
			if rowregions[r][col] then
				rowregions[r][col].row = r
			end
		end
		for col = 1, backdropanchor[r].count-1 do
			fbconnect[r][col].row = r
		end
	end
	
	for r = 1, maxrow do
		if r >= currentrow and r <= currentrow + minrow-1 then
			EnableRow(r)
		else
			DisableRow(r)
		end
	end
end

function AddRow(row)

	rowbackdropanchor:SetHeight(rowbackdropanchor:Height() + rowheight)
	rowbackdropanchor:SetAnchor("BOTTOMLEFT", rowbackdropanchor:Left(), rowbackdropanchor:Bottom() - rowheight)

	local newbackdropanchor
	newbackdropanchor = Region('region', 'backdroprow'..row, UIParent)
	newbackdropanchor:SetWidth(mineditcol*colwidth --[[ScreenWidth()--]])
	newbackdropanchor:SetHeight(rowheight)
	newbackdropanchor:SetLayer("LOW")
	newbackdropanchor:SetAnchor('TOPLEFT',rowbackdropanchor,'TOPLEFT',0,-rowheight*(row-1))
	newbackdropanchor:Handle("OnLeave", ScrollEnds)
	newbackdropanchor:Handle("OnTouchUp", ScrollEnds)
	newbackdropanchor:Handle("OnHorizontalScroll",ScrollBackdrop)
	newbackdropanchor:EnableHorizontalScroll(true)
	newbackdropanchor:EnableInput(true)
	newbackdropanchor.row = row
	newbackdropanchor.column = col
	newbackdropanchor.count = mineditcol
	newbackdropanchor:Show()

	local newcellbackdrop = {}
	local newcelllock = {}

	for col = 1,mineditcol do
		newcellbackdrop[col] = Region('region', 'cellbackdrop'..row.."."..col, UIParent)
		newcellbackdrop[col]:SetWidth(colwidth)
		newcellbackdrop[col]:SetHeight(rowheight)
		newcellbackdrop[col]:SetLayer("LOW")
		if col == 1 then
			newcellbackdrop[col]:SetAnchor('TOPLEFT',newbackdropanchor,'TOPLEFT',0,0)
		else
			newcellbackdrop[col]:SetAnchor('LEFT',newcellbackdrop[col-1],'RIGHT', 0,0)
		end
		newcellbackdrop[col]:Show()
		newcellbackdrop[col].t = newcellbackdrop[col]:Texture("backdrop-edge-brighter-128.png")
		SetTexturedFlowboxBackdropColor(newcellbackdrop[col].t, ColumnToFBType(col))
		newcellbackdrop[col].row = row
		newcellbackdrop[col].column = col
		newcellbackdrop[col].fbtype = ColumnToFBType(col)
		newcellbackdrop[col]:SetClipRegion(0,selectorheight,ScreenWidth(),rowheight*minrow)
		newcellbackdrop[col]:EnableClipping(true)

		newcelllock[col]=Region('region', 'celllock'..row.."."..col, UIParent)
		newcelllock[col]:SetWidth(protocellwidth)
		newcelllock[col]:SetHeight(protocellheight)
		newcelllock[col]:SetLayer("MEDIUM")
		newcelllock[col]:SetAnchor('CENTER',newcellbackdrop[col],'CENTER',0,0)
		newcelllock[col]:Show()
		newcelllock[col].texture = newcelllock[col]:Texture()
		SetFlowboxLockColor(newcelllock[col].texture,ColumnToFBType(col))
		newcelllock[col]:Handle("OnEnter", RegisterLock)
		newcelllock[col]:Handle("OnLeave", UnRegisterLock)
		if col > 1 and col < mincol then
			newcelllock[col]:Handle("OnDoubleTap", MergeArrow)
			newcelllock[col].backdrop = newbackdropanchor
			newcelllock[col].collapsable = true
		else
			newcelllock[col]:Handle("OnDoubleTap", DeleteRow)
		end
		newcelllock[col]:EnableInput(true)
		newcelllock[col].row = row
		newcelllock[col].column = col
		newcelllock[col].fbtype = ColumnToFBType(col)
		newcelllock[col]:SetClipRegion(0,selectorheight,ScreenWidth(),rowheight*minrow)
		newcelllock[col]:EnableClipping(true)
	end

	local newfbconnect = {}

	for col=1,mineditcol-1 do
		newfbconnect[col] = Region('region', 'fbconnect'..row.."."..col, UIParent)
		newfbconnect[col]:SetWidth(65)
		newfbconnect[col]:SetHeight(24)
		newfbconnect[col]:SetAnchor('CENTER',newcellbackdrop[col+1],"LEFT", 11, 0) 
		newfbconnect[col]:SetLayer("MEDIUM")
		newfbconnect[col]:Hide()
		newfbconnect[col].t = newfbconnect[col]:Texture("connectarrow2.png")
		newfbconnect[col].t:SetBlendMode("BLEND")
		newfbconnect[col].t:SetTexCoord(0,1.0,0,1.0)
		newfbconnect[col].t:SetGradientColor("TOP",180,180,180,255,180,180,180,255)
		newfbconnect[col].t:SetGradientColor("BOTTOM",180,180,180,255,180,180,180,255)
		newfbconnect[col].row = row
		newfbconnect[col].column = col
		newfbconnect[col].backdrop = newbackdropanchor
		newfbconnect[col]:Handle("OnDoubleTap",SplitArrow)
		newfbconnect[col]:EnableInput(true)
		newfbconnect[col]:SetClipRegion(0,selectorheight,ScreenWidth(),rowheight*minrow)
		newfbconnect[col]:EnableClipping(true)
	end

	
	table.insert(backdropanchor, row, newbackdropanchor)
	table.insert(celllock, row, newcelllock)
	table.insert(cellbackdrop, row, newcellbackdrop)
	table.insert(rowregions, row, {})
	table.insert(fbconnect, row, newfbconnect)

	maxrow = maxrow + 1
	
	RefreshRowIndices(1)--row+1)
end

function ClearRow(row)
	for col, v in pairs(rowregions[row]) do
		if col > 1  and v and rowregions[row][col-1] then
			local thisregion = rowregions[row][col]
			local inregion = rowregions[row][col-1]
			inregion.flowbox:RemovePushLink(inregion.outnr,thisregion.flowbox,thisregion.innr)
			thisregion.flowbox:RemovePullLink(thisregion.innr,inregion.flowbox,inregion.outnr)
		end
	end
	
	for col= 1, backdropanchor[row].count do
		local activelock = celllock[row][col]
		activelock.locked = nil
		if rowregions[row][col] then
			FreeButton(rowregions[row][col])
		end
		if rowregions[row][col] then
			rowregions[row][col]:SetParent(UIParent)
		end
		rowregions[row][col] = nil
		if col > 1 then
			fbconnect[row][col-1]:Hide()
		end	
	end

	local count = backdropanchor[row].count
	for i=4, count do
			MergeArrow(celllock[row][2])
	end
end

function DeleteRow(self)
	RemoveRow(self.row)
end

function RemoveRow(row)
	if maxrow <= minrow then
		return
	end

	ClearRow(row)
	
	backdropanchor[row]:Hide()
	backdropanchor[row]:EnableInput(false)
	for col=1,mincol do
		celllock[row][col]:Hide()
		celllock[row][col]:EnableInput(false)
		cellbackdrop[row][col]:Hide()
		cellbackdrop[row][col]:EnableInput(false)
	end

	for col = mincol,1,-1 do
		RecycleCell(row, col)
	end

	table.remove(backdropanchor, row)
	table.remove(celllock, row)
	table.remove(cellbackdrop, row)
	table.remove(rowregions, row)
	table.remove(fbconnect, row)
	
	maxrow = maxrow - 1
	
	rowbackdropanchor:SetHeight(rowbackdropanchor:Height()-rowheight)
	rowbackdropanchor:SetAnchor("BOTTOMLEFT", rowbackdropanchor:Left(), rowbackdropanchor:Bottom()+rowheight) 
	
	RefreshRowIndices(1) --row)
	
	local bottom = rowbackdropanchor:Bottom()
	
	if bottom < (selectorheight + minrow*rowheight) - rowbackdropanchor:Height() then
		bottom = (selectorheight + minrow*rowheight) - rowbackdropanchor:Height()
	end
	if bottom > selectorheight then
		bottom = selectorheight
	end
	
	rowbackdropanchor:SetAnchor('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', rowbackdropanchor:Left() ,bottom)
end

-- When tapping arrows we insert a new cell.

function SplitArrow(self)

	local backdrop = self.backdrop
	local row = self.row
	local col = self.column+1
	local fbtype = 2
	
	backdrop:SetWidth(backdrop:Width()+colwidth)
	backdrop.count = backdrop.count + 1

	UnlinkFlowboxes(row,col)

	local newcellbackdrop = {}
	
	newcellbackdrop = Region('region', 'newcellbackdrop'..row.."."..col, UIParent)
	newcellbackdrop:SetWidth(colwidth)
	newcellbackdrop:SetHeight(rowheight)
	newcellbackdrop:SetLayer("LOW")
	newcellbackdrop:SetAnchor('LEFT',cellbackdrop[row][col-1],'RIGHT', 0,0)
	newcellbackdrop:Show()
	newcellbackdrop.t = newcellbackdrop:Texture("backdrop-edge-brighter-128.png")
	SetTexturedFlowboxBackdropColor(newcellbackdrop.t, fbtype)
	newcellbackdrop:SetClipRegion(0,selectorheight,ScreenWidth(),rowheight*minrow)
	newcellbackdrop:EnableClipping(true)

	local newcelllock = {}

	newcelllock = {}
	newcelllock=Region('region', 'filterlock'..row.."."..col, UIParent)
	newcelllock:SetWidth(protocellwidth)
	newcelllock:SetHeight(protocellheight)
	newcelllock:SetLayer("MEDIUM")
	newcelllock:SetAnchor('CENTER',newcellbackdrop,'CENTER',0,0) 
	newcelllock:Show()
	newcelllock.texture = newcelllock:Texture()
	SetFlowboxLockColor(newcelllock.texture, fbtype)
	newcelllock:Handle("OnEnter", RegisterLock)
	newcelllock:Handle("OnLeave", UnRegisterLock)
	newcelllock:Handle("OnDoubleTap", MergeArrow)
	newcelllock.collapsable = true
	newcelllock.backdrop = backdropanchor[row]
	newcelllock:EnableInput(true)
	newcelllock.row = row 
	newcelllock.column = col
	newcelllock.fbtype = 2
	newcelllock:SetClipRegion(0,selectorheight,ScreenWidth(),rowheight*minrow)
	newcelllock:EnableClipping(true)

	local newfbconnect = {}

	newfbconnect = Region('region', 'fbconnect'..row.."."..col, UIParent)
	newfbconnect:SetWidth(65)
	newfbconnect:SetHeight(24)
	newfbconnect:SetAnchor('CENTER',newcellbackdrop,"LEFT", 11, 0) 
	newfbconnect:SetLayer("MEDIUM")
	newfbconnect:Hide()
	newfbconnect.t = newfbconnect:Texture("connectarrow2.png")
	newfbconnect.t:SetBlendMode("BLEND")
	newfbconnect.t:SetTexCoord(0,1.0,0,1.0)
	newfbconnect.t:SetGradientColor("TOP",180,180,180,255,180,180,180,255)
	newfbconnect.t:SetGradientColor("BOTTOM",180,180,180,255,180,180,180,255)
	newfbconnect.row = row
	newfbconnect.column = col-1
	newfbconnect.backdrop = backdropanchor[row]
	newfbconnect:Handle("OnDoubleTap",SplitArrow)
	newfbconnect:EnableInput(true)
	newfbconnect.fbtype = 2
	newfbconnect:SetClipRegion(0,selectorheight,ScreenWidth(),rowheight*minrow)
	newfbconnect:EnableClipping(true)

	table.insert(cellbackdrop[row], col, newcellbackdrop)
	table.insert(celllock[row], col, newcelllock)
	table.insert(fbconnect[row], col-1, newfbconnect)

	for ncol = backdrop.count, col+1, -1 do
		rowregions[row][ncol] = rowregions[row][ncol-1]
	end
	rowregions[row][col] = nil
	
	for ncol = col,backdrop.count-1 do
		fbconnect[row][ncol].column = ncol
	end

	for ncol = col+1, backdrop.count do
		celllock[row][ncol].column = ncol 
		if rowregions[row][ncol] then
			rowregions[row][ncol].column = ncol
		end
	end
	
	cellbackdrop[row][col+1]:SetAnchor('LEFT', newcellbackdrop, 'RIGHT', 0, 0)

end

-- Setup instance joint indicators

function InsertRow(self)
	AddRow(self.row+currentrow-1)
end

for row = 1, minrow do
	AddRow(row)
end

rowbackdropanchor:SetHeight(rowbackdropanchor:Height() - 1) -- Hacky, currently 0 height regions have troubles layouting

rowconnect = {}

for row = 1,maxrow-1 do
	rowconnect[row] = Region('region', 'rowconnect'..row, UIParent)
	rowconnect[row]:SetWidth(ScreenWidth())
	rowconnect[row]:SetHeight(30)
	rowconnect[row]:SetLayer("HIGH")
	rowconnect[row]:SetAnchor('BOTTOMLEFT', 0,ScreenHeight()-42-16-rowheight*(row)+15)
	rowconnect[row]:EnableInput(true)
	rowconnect[row]:Handle("OnDoubleTap", InsertRow)
	rowconnect[row].row = row+1
end

-- Startup with sources as active type

activefbtype = 1

-- Horizontal scrolling of FB selector backdrop

local scrollpos = 0
local abs = math.abs
function ScrollSelector(self, diff)
	scrollpos = scrollpos + diff
	if abs(scrollpos) > ScreenWidth()/4 then
		if diff > 0 then
			scrollpos = scrollpos - ScreenWidth()/6
			NarrowPageLeft(sourceselscrollleft)
		else
			scrollpos = scrollpos + ScreenWidth()/6
			NarrowPageRight(sourceselscrollright)
		end
	end
end

-- Set up selector backdrop

switchbackdrop = Region('region', 'switchbackdrop', UIParent)
switchbackdrop:SetWidth(ScreenWidth())
switchbackdrop:SetHeight(90+32+(maxselrows-1)*rowheight)
switchbackdrop:SetAnchor("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, -(maxselrows-1)*rowheight)
switchbackdrop:SetLayer("LOW")
switchbackdrop:Show()
switchbackdrop:Handle("OnHorizontalScroll", ScrollSelector)
switchbackdrop:EnableHorizontalScroll(true)
switchbackdrop:EnableInput(true)
switchbackdrop.t = switchbackdrop:Texture()
SetFlowboxBackdropColor(switchbackdrop.t,activefbtype) -- Start of with sources

local fbprotoselectionswitcher = {}

-- Setup buttom switchboard

for fbtype=1,3 do
	fbprotoselectionswitcher[fbtype] = Region('region', 'fbprotoselectionswitcher[fbtype]', UIParent)
	fbprotoselectionswitcher[fbtype]:SetWidth(64)
	fbprotoselectionswitcher[fbtype]:SetHeight(64)
	fbprotoselectionswitcher[fbtype]:SetLayer("HIGH")
--	fbprotoselectionswitcher[fbtype]:SetAnchor('CENTER', switchbackdrop, 'TOP', (fbtype-2)*ScreenWidth()/3, 0)
	if fbtype == 1 then
		fbprotoselectionswitcher[fbtype]:SetAnchor('CENTER', switchbackdrop, 'TOPLEFT', colwidth/2, -4)
	elseif fbtype == 2 then
		fbprotoselectionswitcher[fbtype]:SetAnchor('CENTER', switchbackdrop, 'TOP', 0, -4)
	else
		fbprotoselectionswitcher[fbtype]:SetAnchor('CENTER', switchbackdrop, 'TOPRIGHT', -colwidth/2, -4)
	end
	if fbtype == activefbtype then
		fbprotoselectionswitcher[fbtype].texture = fbprotoselectionswitcher[fbtype]:Texture("doublearrow.png")
		SetNavigationArrowSelectColor(fbprotoselectionswitcher[fbtype].texture,fbtype)
	else
		fbprotoselectionswitcher[fbtype].texture = fbprotoselectionswitcher[fbtype]:Texture("downarrow.png")
		SetNavigationArrowColor(fbprotoselectionswitcher[fbtype].texture,fbtype)
	end
	fbprotoselectionswitcher[fbtype].texture:SetBlendMode("BLEND")
	fbprotoselectionswitcher[fbtype]:Show()
	fbprotoselectionswitcher[fbtype].fbtype = fbtype
end

local pagepos = {1,1,1}
function NarrowPageUpdate()
	local sel = protofbcells[activefbtype]
	local nrlabels = #fblabels[activefbtype]
	local labels = fblabels[activefbtype]
	local labelsperrow = ceil(nrlabels / cellrows)
	if labelsperrow < mincol then
		labelsperrow = mincol
	end
	for i=1,mincol do
		for j=1,cellrows do
			local cell = i+mincol*(j-1)
			if pagepos[activefbtype]+i-1+(j-1)*labelsperrow <= nrlabels then
				sel[cell].textlabel:SetLabel(labels[pagepos[activefbtype]+i-1+(j-1)*labelsperrow])
				if activefbtype == 1 then
					sel[cell].flowbox = fbboxes[activefbtype][pagepos[activefbtype]+i-1+(j-1)*labelsperrow]
					sel[cell].outnr = fblets[activefbtype][pagepos[activefbtype]+i-1+(j-1)*labelsperrow]
				elseif activefbtype == 2 then
					sel[cell].flowbox = fbboxes[activefbtype][pagepos[activefbtype]+i-1+(j-1)*labelsperrow]
					sel[cell].innr = fblets[activefbtype][pagepos[activefbtype]+i-1+(j-1)*labelsperrow]
					sel[cell].outnr = 0
				else
					sel[cell].flowbox = fbboxes[activefbtype][pagepos[activefbtype]+i-1+(j-1)*labelsperrow]
					sel[cell].innr = fblets[activefbtype][pagepos[activefbtype]+i-1+(j-1)*labelsperrow]
				end
				sel[cell]:Show()
			else
				sel[cell]:Hide()
			end
		end
	end
end

function NarrowPageLeft(self)
	if pagepos[activefbtype] > 1 then
		pagepos[activefbtype] = pagepos[activefbtype] - 1
		if pagepos[activefbtype] < 1 then
			pagepos[activefbtype] = 1
		end
		NarrowPageUpdate()
	end
end

function NarrowPageRight(self)
	local nrlabels = #fblabels[activefbtype]
	local labelsperrow = ceil(nrlabels / cellrows)
	if pagepos[activefbtype] < labelsperrow-2 then
		pagepos[activefbtype] = pagepos[activefbtype] + 1
		if pagepos[activefbtype] > nrlabels-(3*cellrows-1) then
			pagepos[activefbtype] = nrlabels-(3*cellrows-1)
		end
		NarrowPageUpdate()
	end
end

local popupfan
local popupbuttons
local fanup = false
function ToggleIconFan(self)
	if not fanup then
		fanup = true
		if not popupfan then
			local x,y  = InputPosition()
			local col = activefbtype
			local fbtype = activefbtype
			local object = self.flowbox:Name()
			local lets
			local width = self:Width()
			local height = self:Height()
			local diag = sqrt(width*width + height*height)
			local separation = diag
			local radius = diag*1.5
			
			local flowbox = self.flowbox
			if fbtype == 1 then
				lets = {flowbox:Outs()}
			else
				lets = {flowbox:Ins()}
			end
			popupbuttons = {}
			
			local instancelabel
			if self.flowbox.instances then
				instancelabel = "("..#self.flowbox.instances..")"
			else
				instancelabel = ""
			end
			
			for k,letstr in pairs(lets) do
				if letstr then
					local label = object..instancelabel.."\n"..letstr--.."("..(k-1)..")"
					button = CreateButton(x,y,col,fbtype,self.textlabel:Label(),self.flowbox,k-1)
					button.textlabel:SetLabel(label)
					table.insert(popupbuttons, button)
				end
			end
			popupfan = CreateIconFan(self, popupbuttons,radius, separation)
		end
		OpenIconFan(popupfan)
	else
		fanup = nil
		CloseIconFan(popupfan)
	end
end


sourcesel = {}
filtersel = {}
sinksel = {}

-- Set up prototype flowbox elements

protofbcells = {}
protofbcells[1] = {} -- sources
protofbcells[2] = {} -- filters
protofbcells[3] = {} -- sinks

for fbtype=1,3 do
	for col = 1,mincol do
		for row = 1,maxselrows do
			cell = col+mincol*(row-1)
			protofbcells[fbtype][cell]=Region('region', 'protofbcells'..fbtype.."."..cell, UIParent)
			protofbcells[fbtype][cell]:SetWidth(protocellwidth)
			protofbcells[fbtype][cell]:SetHeight(protocellheight)
			protofbcells[fbtype][cell]:SetLayer("DIALOG")
			protofbcells[fbtype][cell]:SetAnchor('BOTTOMLEFT',switchbackdrop,'BOTTOMLEFT',(col-1)*colselwidth+34+18,10+(maxselrows-row)*rowheight) 
			protofbcells[fbtype][cell]:EnableClamping(true)
			protofbcells[fbtype][cell].lockposx = (col-1)*colselwidth+34+18
			protofbcells[fbtype][cell].lockposy = 10+(maxselrows-row)*rowheight
			protofbcells[fbtype][cell].fbtype = fbtype	
			protofbcells[fbtype][cell]:Handle("OnTouchDown", UnlockCursor)
	--		protofbcells[fbtype][cell]:Handle("OnDragStart", UnlockCursor)
	--		protofbcells[fbtype][cell]:Handle("OnTouchUp", LockCursor)
			protofbcells[fbtype][cell]:Handle("OnDragStop", LockCursor)
			protofbcells[fbtype][cell].textlabel=protofbcells[fbtype][cell]:TextLabel()
			protofbcells[fbtype][cell].textlabel:SetFont("Trebuchet MS")
			protofbcells[fbtype][cell].textlabel:SetHorizontalAlign("CENTER")
			protofbcells[fbtype][cell].textlabel:SetLabel("Source")
			protofbcells[fbtype][cell].textlabel:SetLabelHeight(16)
			protofbcells[fbtype][cell].textlabel:SetColor(255,255,255,255)
			protofbcells[fbtype][cell].textlabel:SetShadowColor(0,0,0,190)
			protofbcells[fbtype][cell].textlabel:SetShadowBlur(2.0)
			protofbcells[fbtype][cell].texture = protofbcells[fbtype][cell]:Texture("button.png")
			SetFlowboxColor(protofbcells[fbtype][cell].texture, fbtype)
			protofbcells[fbtype][cell].texture:SetTexCoord(0,1.0,0,0.625)
			if fbtype == activefbtype then
				protofbcells[fbtype][cell]:Show()
				protofbcells[fbtype][cell]:EnableInput(true)
				protofbcells[fbtype][cell]:EnableMoving(true)
			else
				protofbcells[fbtype][cell]:Hide()
				protofbcells[fbtype][cell]:EnableInput(false)
				protofbcells[fbtype][cell]:EnableMoving(false)
			end
			protofbcells[fbtype][cell].docked = true
		end
	end
end

for fbtype=1,3 do
	for _,object in ipairs(fbobjs[fbtype]) do
		local cflowbox = _G["FB"..object]
		if cflowbox:IsInstantiable() then
			cflowbox.instances = {}
		end
		local pos = fbpos[fbtype]
		local lets
		if fbtype == 1 then
			lets = {cflowbox:Outs()}
		else
			lets = {cflowbox:Ins()}
		end
		for k,letstr in pairs(lets) do
			if letstr then
				fblabels[fbtype][pos] = object.."\n"..letstr--.."("..(k-1)..")"
				fbboxes[fbtype][pos] = cflowbox
				fblets[fbtype][pos] = k-1
				if pos <= maxcellpos then
					protofbcells[fbtype][pos].flowbox = cflowbox
					if fbtype == 1 then
						protofbcells[fbtype][pos].outnr = k-1
					end
					if fbtype == 2 then
						protofbcells[fbtype][pos].innr = k-1
						protofbcells[fbtype][pos].outnr = 0
					end
					if fbtype == 3 then
						protofbcells[fbtype][pos].innr = k-1
					end
					protofbcells[fbtype][pos].textlabel:SetLabel(fblabels[fbtype][pos])
					protofbcells[fbtype][pos].instance = 0
				end
				pos = pos + 1
			end
		end
		fbpos[fbtype] = pos
	end
end

-- Switch to Source

function SwitchFBType(self)
	activefbtype = self.fbtype

	SetFlowboxBackdropColor(switchbackdrop.t, activefbtype)

	SetNavigationArrowColor(sourceselscrollleft.texture, activefbtype)
	SetNavigationArrowColor(sourceselscrollright.texture, activefbtype)
	
	for fbtype = 1,3 do
		if fbtype == activefbtype then
			fbprotoselectionswitcher[fbtype].texture:SetTexture("doublearrow.png")
			SetNavigationArrowSelectColor(fbprotoselectionswitcher[fbtype].texture, fbtype)
		else
			fbprotoselectionswitcher[fbtype].texture:SetTexture("downarrow.png")
			SetNavigationArrowColor(fbprotoselectionswitcher[fbtype].texture, fbtype)
		end
		for cell = 1,maxcellpos do
			if fbtype == activefbtype and cell <= #fblabels[activefbtype] then
				if protofbcells[fbtype][cell].docked then
					protofbcells[fbtype][cell]:Show()
					protofbcells[fbtype][cell]:EnableInput(true)
					protofbcells[fbtype][cell]:EnableMoving(true)
				end
			else
				if protofbcells[fbtype][cell].docked then
					protofbcells[fbtype][cell]:Hide()
					protofbcells[fbtype][cell]:EnableInput(false)
					protofbcells[fbtype][cell]:EnableMoving(false)
				end
			end
		end
	end
end

function UpdateClipRegionHeights(bottom)
	rowbackdropanchor:SetClipRegion(0,bottom,ScreenWidth(),rowheight*minrow-bottom+selectorheight)
	for row = 1, maxrow do
		for col = 1,backdropanchor[row].count do
			local region = rowregions[row][col]
			if region then
				region:SetClipRegion(0,bottom,ScreenWidth(),rowheight*minrow-bottom+selectorheight)
			end
			celllock[row][col]:SetClipRegion(0,bottom,ScreenWidth(),rowheight*minrow-bottom+selectorheight)
			cellbackdrop[row][col]:SetClipRegion(0,bottom,ScreenWidth(),rowheight*minrow-bottom+selectorheight)
			if col > 1 then
				fbconnect[row][col-1]:SetClipRegion(0,bottom,ScreenWidth(),rowheight*minrow-bottom+selectorheight)
			end
		end
	end
end

local abs = math.abs
function MoveSelector(self, diff)

	sourceselscrollleft:Handle("OnTouchUp", nil)
	sourceselscrollright:Handle("OnTouchUp", nil)
	sourceselscrollleft:EnableInput(false)
	sourceselscrollright:EnableInput(false)

	local bottom = self:Bottom()+diff

	if bottom > 0 then
		bottom = 0
	end
	if bottom < -rowheight*(maxselrows-1) then
		bottom = -rowheight*(maxselrows-1)
	end

	local div = bottom / rowheight

	cellrows = ceil(maxselrows+div)
	NarrowPageUpdate()

	self:SetAnchor('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', self:Left() ,bottom)
	if rowbackdropanchor:Bottom() > self:Top() then
		rowbackdropanchor:SetAnchor('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', rowbackdropanchor:Left(), self:Top());
	end
	UpdateClipRegionHeights(self:Top())
end

-- Scroll action ended, check if we need to align
function MoveSelectorEnds(self)

	local bottom = self:Bottom()
	local div
	div = bottom / rowheight
	bottom = bottom % rowheight

	if bottom < rowheight/2 then
		self:SetAnchor('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', 0 ,switchbackdrop:Bottom()-bottom)
	else
		self:SetAnchor('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', 0 ,switchbackdrop:Bottom()-bottom+rowheight)
	end

	if rowbackdropanchor:Bottom() > self:Top() then
		rowbackdropanchor:SetAnchor('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', rowbackdropanchor:Left(), self:Top());
	end

	UpdateClipRegionHeights(self:Top())

	sourceselscrollleft:Handle("OnTouchUp", NarrowPageLeft)
	sourceselscrollright:Handle("OnTouchUp", NarrowPageRight)
	sourceselscrollleft:EnableInput(true)
	sourceselscrollright:EnableInput(true)

	bottom = self:Bottom()

	div = bottom / rowheight

	cellrows = maxselrows+div

	local nrlabels = #fblabels[activefbtype]
	local labelsperrow = ceil(nrlabels / cellrows)

	if pagepos[activefbtype] > labelsperrow-2 then
		pagepos[activefbtype] = labelsperrow-2
		if pagepos[activefbtype] < 1 then
			pagepos[activefbtype] = 1
		end
		NarrowPageUpdate()
	end
end


for fbtype = 1,3 do
	fbprotoselectionswitcher[fbtype]:Handle("OnTouchDown", SwitchFBType)
	fbprotoselectionswitcher[fbtype]:EnableInput(true)
end

switchbackdrop:Handle("OnVerticalScroll", MoveSelector)
switchbackdrop:EnableVerticalScroll(true)
switchbackdrop:Handle("OnTouchUp", MoveSelectorEnds)

sourceselscrollleft = Region('region', 'sourceselscrollleft', UIParent)
sourceselscrollleft:SetWidth(40)
sourceselscrollleft:SetHeight(80)
sourceselscrollleft:SetLayer("MEDIUM")
sourceselscrollleft:SetAnchor('BOTTOMLEFT',4,0)
sourceselscrollleft.texture = sourceselscrollleft:Texture("leftarrow.png")
SetNavigationArrowColor(sourceselscrollleft.texture, activefbtype)
sourceselscrollleft.texture:SetBlendMode("BLEND")
sourceselscrollleft:Handle("OnTouchUp", NarrowPageLeft)
sourceselscrollleft:EnableInput(true)
sourceselscrollleft:Show()

sourceselscrollright = Region('region', 'sourceselscrollright', UIParent)
sourceselscrollright:SetWidth(40)
sourceselscrollright:SetHeight(80)
sourceselscrollright:SetLayer("MEDIUM")
sourceselscrollright:SetAnchor('BOTTOMLEFT',ScreenWidth()-24-4,0)
sourceselscrollright.texture = sourceselscrollright:Texture("rightarrow.png")
SetNavigationArrowColor(sourceselscrollright.texture, activefbtype)
sourceselscrollright.texture:SetBlendMode("BLEND")
sourceselscrollright:Handle("OnTouchUp", NarrowPageRight)
sourceselscrollright:EnableInput(true)
sourceselscrollright:Show()

SetFrameRate(1.0/50.0)

local phase = 1

-- If this wasn't horrifyingly slow one could render into the sound buffer in lua. Disabled for now due to speed issues.
--local sinbuff = {}
--for i=1,44100 do
--	sinbuff[i] = sin(3.1415926535*2*i/44100.0)
--end

-- Same for microphone... too slow currently to do in pure lua.
--function HandleMic()
--	local avg = 0
--	for i=1,256 do
--		avg = avg + abs(urMicData[i])
--	end

--	avg = avg / 256
--  for i=1,256 do
--  	urSoundData[1][i]=2147483647/16*sin(3.1415926535*2*i*440./44100.0) -- sinbuff[phase*100]
--  	phase = phase + 1
--  end
--	DPrint("avg: "..avg)
--end

--musregion = Region('region', 'musregion', UIParent)
--musregion:Handle("OnMicrophone", HandleMic)

function LoadAndActivateInterface(file)
	if not pageloaded[file] then
		SetPage(next_free_page)
		dofile(SystemPath(file))
		pageloaded[file] = next_free_page
		next_free_page = next_free_page + 1
	elseif Page() ~= pageloaded[file] then
		SetPage(pageloaded[file])
	end
end

function OldFlipPage(self)
	if next_linked_page > num_linked_pages then
		next_linked_page = 1
		SetPage(1)
		return
	end
	
	if not pageloaded[next_linked_page] then
		SetPage(next_linked_page+1)
		dofile(SystemPath(pagefile[next_linked_page]))
		pageloaded[next_linked_page] = true
		next_linked_page = next_linked_page + 1
	else
		SetPage(next_linked_page+1)
		next_linked_page = next_linked_page + 1
	end
end

function FlipPage(self)

	local scrollentries = {}

	for k,v in pairs(pagefile) do
		local entry = { v, nil, nil, LoadAndActivateInterface, {84,84,84,255}}
		table.insert(scrollentries, entry)
	end
	urScrollList:OpenScrollListPage(scrollpage, "Interface", nil, nil, scrollentries)
end

sourcetitlelabel=Region('region', 'sourcetitlelabel', UIParent)
sourcetitlelabel:SetWidth(ScreenWidth())
sourcetitlelabel:SetHeight(16)
sourcetitlelabel:SetLayer("TOOLTIP")
sourcetitlelabel:SetAnchor('CENTER', backdropanchor[1], 'TOPLEFT', colwidth/2, -4)
sourcetitlelabel:Show()
sourcetitlelabel.textlabel=sourcetitlelabel:TextLabel()
sourcetitlelabel.textlabel:SetFont("Trebuchet MS")
sourcetitlelabel.textlabel:SetHorizontalAlign("CENTER")
sourcetitlelabel.textlabel:SetVerticalAlign("TOP")
sourcetitlelabel.textlabel:SetLabel("Source")
sourcetitlelabel.textlabel:SetLabelHeight(16)
sourcetitlelabel.textlabel:SetColor(255,255,255,255)
sourcetitlelabel.textlabel:SetShadowColor(0,0,0,190)
sourcetitlelabel.textlabel:SetShadowBlur(2.0)
sourcetitlelabel:SetClipRegion(0,selectorheight,ScreenWidth(),rowheight*minrow)
sourcetitlelabel:EnableClipping(true)

filtertitlelabel=Region('region', 'filtertitlelabel', UIParent)
filtertitlelabel:SetWidth(ScreenWidth())
filtertitlelabel:SetHeight(16)
filtertitlelabel:SetLayer("TOOLTIP")
filtertitlelabel:SetAnchor('CENTER', backdropanchor[1], 'TOP', 0, -4)
filtertitlelabel:Show()
filtertitlelabel.textlabel=filtertitlelabel:TextLabel()
filtertitlelabel.textlabel:SetFont("Trebuchet MS")
filtertitlelabel.textlabel:SetHorizontalAlign("CENTER")
filtertitlelabel.textlabel:SetVerticalAlign("TOP")
filtertitlelabel.textlabel:SetLabel("Filter")
filtertitlelabel.textlabel:SetLabelHeight(16)
filtertitlelabel.textlabel:SetColor(255,255,255,255)
filtertitlelabel.textlabel:SetShadowColor(0,0,0,190)
filtertitlelabel.textlabel:SetShadowBlur(2.0)
filtertitlelabel:SetClipRegion(0,selectorheight,ScreenWidth(),rowheight*minrow)
filtertitlelabel:EnableClipping(true)

sinktitlelabel=Region('region', 'sinktitlelabel', UIParent)
sinktitlelabel:SetWidth(ScreenWidth())
sinktitlelabel:SetHeight(16)
sinktitlelabel:SetLayer("TOOLTIP")
sinktitlelabel:SetAnchor('CENTER', backdropanchor[1], 'TOPRIGHT', -colwidth/2, -4)
sinktitlelabel:Show()
sinktitlelabel.textlabel=sinktitlelabel:TextLabel()
sinktitlelabel.textlabel:SetFont("Trebuchet MS")
sinktitlelabel.textlabel:SetHorizontalAlign("CENTER")
sinktitlelabel.textlabel:SetVerticalAlign("TOP")
sinktitlelabel.textlabel:SetLabel("Sink")
sinktitlelabel.textlabel:SetLabelHeight(16)
sinktitlelabel.textlabel:SetColor(255,255,255,255)
sinktitlelabel.textlabel:SetShadowColor(0,0,0,190)
sinktitlelabel.textlabel:SetShadowBlur(2.0)
sinktitlelabel:SetClipRegion(0,selectorheight,ScreenWidth(),rowheight*minrow)
sinktitlelabel:EnableClipping(true)


clearbutton=Region('region', 'clearbutton', UIParent)
clearbutton:SetWidth(ScreenWidth()/4)
clearbutton:SetHeight(menubottonheight)
clearbutton:SetLayer("TOOLTIP")
clearbutton:SetAnchor('BOTTOMLEFT',0,ScreenHeight()-menubottonheight) 
clearbutton:EnableClamping(true)
clearbutton:Handle("OnDoubleTap", ClearSetup)
clearbutton.texture = clearbutton:Texture("button.png")
clearbutton.texture:SetGradientColor("TOP",128,128,128,255,128,128,128,255)
clearbutton.texture:SetGradientColor("BOTTOM",128,128,128,255,128,128,128,255)
clearbutton.texture:SetBlendMode("BLEND")
clearbutton.texture:SetTexCoord(0,1.0,0,0.625)
clearbutton:EnableInput(true)
clearbutton:Show()
clearbutton.textlabel=clearbutton:TextLabel()
clearbutton.textlabel:SetFont("Trebuchet MS")
clearbutton.textlabel:SetHorizontalAlign("CENTER")
clearbutton.textlabel:SetLabel("Clear")
clearbutton.textlabel:SetLabelHeight(16)
clearbutton.textlabel:SetColor(255,255,255,255)
clearbutton.textlabel:SetShadowColor(0,0,0,190)
clearbutton.textlabel:SetShadowBlur(2.0)

loadbutton=Region('region', 'loadbutton', UIParent)
loadbutton:SetWidth(ScreenWidth()/4)
loadbutton:SetHeight(menubottonheight)
loadbutton:SetLayer("TOOLTIP")
loadbutton:SetAnchor('BOTTOMLEFT',ScreenWidth()/4,ScreenHeight()-menubottonheight) 
loadbutton:EnableClamping(true)
loadbutton:Handle("OnDoubleTap", LoadSettings)
loadbutton.texture = loadbutton:Texture("button.png")
loadbutton.texture:SetGradientColor("TOP",128,128,128,255,128,128,128,255)
loadbutton.texture:SetGradientColor("BOTTOM",128,128,128,255,128,128,128,255)
loadbutton.texture:SetBlendMode("BLEND")
loadbutton.texture:SetTexCoord(0,1.0,0,0.625)
loadbutton:EnableInput(true)
loadbutton:Show()
loadbutton.textlabel=loadbutton:TextLabel()
loadbutton.textlabel:SetFont("Trebuchet MS")
loadbutton.textlabel:SetHorizontalAlign("CENTER")
loadbutton.textlabel:SetLabel("Load")
loadbutton.textlabel:SetLabelHeight(16)
loadbutton.textlabel:SetColor(255,255,255,255)
loadbutton.textlabel:SetShadowColor(0,0,0,190)
loadbutton.textlabel:SetShadowBlur(2.0)

savebutton=Region('region', 'savebutton', UIParent)
savebutton:SetWidth(ScreenWidth()/4)
savebutton:SetHeight(menubottonheight)
savebutton:SetLayer("TOOLTIP")
savebutton:SetAnchor('BOTTOMLEFT',2*ScreenWidth()/4,ScreenHeight()-menubottonheight) 
savebutton:EnableClamping(true)
savebutton:Handle("OnDoubleTap", SaveSettings)
savebutton.texture = savebutton:Texture("button.png")
savebutton.texture:SetGradientColor("TOP",128,128,128,255,128,128,128,255)
savebutton.texture:SetGradientColor("BOTTOM",128,128,128,255,128,128,128,255)
savebutton.texture:SetBlendMode("BLEND")
savebutton.texture:SetTexCoord(0,1.0,0,0.625)
savebutton:EnableInput(true)
savebutton:Show()
savebutton.textlabel=savebutton:TextLabel()
savebutton.textlabel:SetFont("Trebuchet MS")
savebutton.textlabel:SetHorizontalAlign("CENTER")
savebutton.textlabel:SetLabel("Save")
savebutton.textlabel:SetLabelHeight(16)
savebutton.textlabel:SetColor(255,255,255,255)
savebutton.textlabel:SetShadowColor(0,0,0,190)
savebutton.textlabel:SetShadowBlur(2.0)

facebutton=Region('region', 'facebutton', UIParent)
facebutton:SetWidth(ScreenWidth()/4)
facebutton:SetHeight(menubottonheight)
facebutton:SetLayer("TOOLTIP")
facebutton:SetAnchor('BOTTOMLEFT',3*ScreenWidth()/4,ScreenHeight()-menubottonheight) 
facebutton:EnableClamping(true)
facebutton:Handle("OnDoubleTap", FlipPage)
facebutton.texture = facebutton:Texture("button.png")
facebutton.texture:SetGradientColor("TOP",128,128,128,255,128,128,128,255)
facebutton.texture:SetGradientColor("BOTTOM",128,128,128,255,128,128,128,255)
facebutton.texture:SetBlendMode("BLEND")
facebutton.texture:SetTexCoord(0,1.0,0,0.625)
facebutton:EnableInput(true)
facebutton:Show()
facebutton.textlabel=facebutton:TextLabel()
facebutton.textlabel:SetFont("Trebuchet MS")
facebutton.textlabel:SetHorizontalAlign("CENTER")
facebutton.textlabel:SetLabel("Face")
facebutton.textlabel:SetLabelHeight(16)
facebutton.textlabel:SetColor(255,255,255,255)
facebutton.textlabel:SetShadowColor(0,0,0,190)
facebutton.textlabel:SetShadowBlur(2.0)


notificationregion=Region('region', 'notificationregion', UIParent)
notificationregion:SetWidth(ScreenWidth())
notificationregion:SetHeight(48*2)
notificationregion:SetLayer("TOOLTIP")
notificationregion:SetAnchor('BOTTOMLEFT',0,ScreenHeight()/2-24) 
notificationregion:EnableClamping(true)
notificationregion:Show()
notificationregion.textlabel=notificationregion:TextLabel()
notificationregion.textlabel:SetFont("Trebuchet MS")
notificationregion.textlabel:SetHorizontalAlign("CENTER")
notificationregion.textlabel:SetLabel("Notifications")
notificationregion.textlabel:SetLabelHeight(48)
notificationregion.textlabel:SetColor(255,255,255,190)

StartAudio()
ShowNotification("urMus") -- Shame on me, pointless eye candy.

--Widget.Tooltip("Double-Tap to Clear", {parent=clearbutton})
--Widget.Tooltip("Double-Tap to Load", {parent=loadbutton})
--Widget.Tooltip("Double-Tap to Save", {parent=savebutton})
--Widget.Tooltip("Double-Tap for Faces", {parent=facebutton})

local host,port = HTTPServer()
DPrint("http://"..host..":"..port.."/")
