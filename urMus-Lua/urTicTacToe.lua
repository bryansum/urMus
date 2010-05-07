-- urTicTacToe
-- Concept by: Georg Essl & Nate Derbinsky
-- Initial Hack by: Georg Essl 04/29/10

local backdrop = Region('region','backdrop',UIParent)
backdrop.t = backdrop:Texture()
backdrop.t:SetTexture("Default.png")
backdrop.t:SetTexCoord(0,0.63,0.94,0.0);
backdrop:SetLayer("BACKGROUND")
backdrop:SetWidth(ScreenWidth())
backdrop:SetHeight(ScreenHeight())
backdrop:Show()


function FreshBoard()
	backdrop.t:Clear(255,255,255)
	backdrop.t:SetBrushColor(255,0,0,192)
	backdrop.t:SetBrushSize(4)
	backdrop.t:Line(ScreenWidth()/3, 0, ScreenWidth()/3,ScreenHeight())
	backdrop.t:Line(2*ScreenWidth()/3, 0, 2*ScreenWidth()/3,ScreenHeight())
	backdrop.t:Line(0,ScreenHeight()/3,ScreenWidth(),ScreenHeight()/3)
	backdrop.t:Line(0,2*ScreenHeight()/3,ScreenWidth(),2*ScreenHeight()/3)
end

FreshBoard()

local buttoncols = 3
local buttonrows = 3
buttons = {} -- Create rows
for i=1,buttonrows do
	buttons[i] = {} -- Create columns
end

local turn = math.random(0,1)
local won
local move = 1

function TextureCol(t,r,g,b,a)
	t:SetGradientColor("TOP",r,g,b,a,r,g,b,a)
	t:SetGradientColor("BOTTOM",r,g,b,a,r,g,b,a)
end

function CheckWin()

	local win

	for c=1,buttoncols do
		if buttons[c][1].state and buttons[c][1].state == buttons[c][2].state and buttons[c][2].state == buttons[c][3].state then
			backdrop.t:Line(0,(2*c-1)*ScreenHeight()/6,ScreenWidth(),(2*c-1)*ScreenHeight()/6)
			win = true
		end
	end
	for r=1,buttonrows do
		if buttons[1][r].state and buttons[1][r].state == buttons[2][r].state and buttons[2][r].state == buttons[3][r].state then
			backdrop.t:Line((2* r-1)*ScreenWidth()/6, 0, (2*r-1)*ScreenWidth()/6,ScreenHeight())
			win = true
		end
	end
	
	if buttons[1][1].state and buttons[1][1].state == buttons[2][2].state and buttons[2][2].state == buttons[3][3].state then
			backdrop.t:Line(0, 0, ScreenWidth(),ScreenHeight())
			win = true
	end
	if buttons[3][1].state and buttons[3][1].state == buttons[2][2].state and buttons[2][2].state == buttons[1][3].state then
			backdrop.t:Line(0, ScreenHeight(), ScreenWidth(),0)
			win  = true
	end
	
	return win
end

function SingleDown(self)

	if won or move > 9 then -- New game
		turn = won and 1-won or turn
		move = 1
		FreshBoard()
		for ix = 1, buttoncols do
			for iy = 1, buttonrows do
				buttons[ix][iy].state = nil
				buttons[ix][iy].t:SetTexture(255,255,255,255)
			end
		end
		won = nil
	end

	if not self.state then
		if turn <0.5 then
			self.t:SetTexture("x-alpha.png")
			TextureCol(self.t,0,255,0,255)
			self.state = turn
			if CheckWin() then won = turn end
		else
			self.t:SetTexture("o-alpha.png")
			TextureCol(self.t,0,0,255,255)
			self.state = turn
			if CheckWin() then won = turn end
		end
		turn = 1 - turn
	end
	move = move + 1
end

function SingleUp(self)
end

function DoubleTap(self)
end

local rescalex = ScreenWidth()/320
local rescaley = ScreenHeight()/480

for ix = 1, buttoncols do
	for iy = 1, buttonrows do
		local newbutton
		newbutton = Region('region','button'..ix..":"..iy,UIParent)
		newbutton.t = newbutton:Texture()
		newbutton.t:SetBlendMode("BLEND")
		newbutton:SetHeight(96*rescaley)
		newbutton:SetWidth(96*rescalex)
		local x = 5+(ix-1)*(ScreenWidth()/3)
		local y = 12+(iy-1)*(ScreenHeight()/3)
		newbutton:SetAnchor("BOTTOMLEFT", x,y)
		newbutton:Show()
		newbutton:Handle("OnTouchDown", SingleDown)
		newbutton:Handle("OnTouchUp", SingleUp)
		newbutton:Handle("OnDoubleTap", DoubleTap)
		newbutton:EnableInput(true)
		newbutton.index = ix + (iy-1)*buttoncols
		buttons[iy][ix] = newbutton
	end
end

pagebutton=Region('region', 'pagebutton', UIParent);
pagebutton:SetWidth(pagersize);
pagebutton:SetHeight(pagersize);
pagebutton:SetLayer("TOOLTIP");
pagebutton:SetAnchor('BOTTOMLEFT',ScreenWidth()-pagersize-4,ScreenHeight()-pagersize-4); 
pagebutton:EnableClamping(true)
pagebutton:Handle("OnTouchDown", FlipPage)
pagebutton.texture = pagebutton:Texture("circlebutton-16.png");
pagebutton.texture:SetGradientColor("TOP",255,255,255,255,255,255,255,255);
pagebutton.texture:SetGradientColor("BOTTOM",255,255,255,255,255,255,255,255);
pagebutton.texture:SetBlendMode("BLEND")
pagebutton.texture:SetTexCoord(0,1.0,0,1.0);
pagebutton:EnableInput(true);
pagebutton:Show();

