-- urPong, homage to the beginning of it all... again
-- Hack by Bryan Summersett
-- Minor tweaks by Georg Essl
-- Created 2/11/2010

dofile(SystemPath("urHelpers.lua"))
Req("urWidget")

local function Shutdown()
    dac:RemovePullLink(0, upSample, 0)
    dac:RemovePullLink(0, upSample2, 0)
end

local function ReInit(self)
    dac:SetPullLink(0, upSample, 0)
    dac:SetPullLink(0, upSample2, 0)
end

-- Instantiating our pong background
pongBGRegion = MakeRegion({
    w=ScreenWidth(), 
    h=ScreenHeight(), 
    layer='BACKGROUND', 
    x=0,y=0, img="PongBG.png"
})
-- SetAttrs(pongBGRegion, {w=514,h=514,x=0,y=-31})
pongBGRegion:Handle("OnPageEntered", ReInit)
pongBGRegion:Handle("OnPageLeft", Shutdown)

MAXSCORE = 10
DEFAULT_VELOCITY = 3

-- Notification Information Overlay

function FadePopup(self, elapsed)
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

function ShowPopup(note)
    popuptextregion.tl:SetLabel(note)
    popuptextregion.staytime = 1.5
    popuptextregion.fadetime = 2.0
    popuptextregion.alpha = 1
    popuptextregion.alphaslope = 2
    popuptextregion:Handle("OnUpdate", FadePopup)
    popuptextregion:SetAlpha(1.0)
    popuptextregion:Show()
end

popuptextregion = MakeRegion({
    w=ScreenWidth(), 
    h=48*2, 
    layer='TOOLTIP',
    x=0,
    y=ScreenHeight()/2-24,
    label={color={0,0,60,190},size=48}
})
popuptextregion.tl:SetHorizontalAlign("CENTER")
popuptextregion.tl:SetVerticalAlign("TOP")
popuptextregion:EnableClamping(true)
popuptextregion:Show()

ShowPopup("urPong!")

function FlashNumber(self,elapsed)
    self.flashtime = self.flashtime + elapsed
    if self.flashtime > self.holdtime then
        self.flashtime = 0
        self:Handle("OnUpdate",nil)
        self.textlabel:SetColor(255,0,0,255)
    end
end

function MakeScoreLabel(x, y)
    local score=Region('Region', "score"..x, UIParent)
    score:SetWidth(ScreenWidth()/3)
    score:SetHeight(44)
    score:SetLayer("TOOLTIP")
    score:SetAnchor("BOTTOMLEFT", x-ScreenWidth()/3/2, y)
    score.textlabel=score:TextLabel()
    score.textlabel:SetFont("Trebuchet MS")
    score.textlabel:SetHorizontalAlign("CENTER")
    score.textlabel:SetVerticalAlign("TOP")
    score.textlabel:SetLabel("0")
    score.textlabel:SetLabelHeight(40)
    score.textlabel:SetColor(255,0,0,255)
    score.textlabel:SetShadowColor(255,190,190,190)
    score.textlabel:SetShadowOffset(2,-3)
    score.textlabel:SetShadowBlur(4.0)
    score.score = 0

    function score:IncrementScore()
        score.textlabel:SetColor(255,255,255,255)
        score.flashtime = 0
        score.holdtime = 1
        score:Handle("OnUpdate", FlashNumber)
        self.score = self.score + 1
        self:SetLabel()
        
        if self.score == MAXSCORE then -- finished, someone won
            myScore:Reset()
            opponentScore:Reset()
            if self == myScore then
                ShowPopup("You Win!!!")
            else
                ShowPopup("You lose...") -- This line has the potential to inflict severe mental anguish and suffering
            end
        else
            if self == myScore then
                ShowPopup("You Score!!")
            else
                ShowPopup("Missed it.")
            end 
        end

        ball:Reset()
    end
    
    function score:Reset()
        self.score = 0
        self:SetLabel()
    end
    
    function score:SetLabel()
        self.textlabel:SetLabel(self.score)
    end

    score:Show()
    return score
end

myScore = MakeScoreLabel(160, 80)
opponentScore = MakeScoreLabel(160, 400)

function MakePaddle(x, y, OnUpdate)
    local paddle = MakeRegion({layer='MEDIUM',w=120,h=20,x=x,y=y,img="paddle.png"})
    
    function paddle:MoveTo(xCoord, yCoord)
        self:SetAnchor('BOTTOMLEFT', xCoord, yCoord)
    end

    paddle:Handle("OnUpdate",OnUpdate)
    return paddle
end

function Clamp(x)
    if x < 0 then
        x = 0
    elseif x >= 200 then
        x = 200
    end
    return x
end

function UserInputUpdatePosition(self)
    local x,_ = InputPosition()
    self:MoveTo(Clamp(x - self:Width()/2), 10)
end

local tiltspeed = 40.0

function UserTilt(self,x,y,z)
    self:MoveTo(Clamp(self:Left()+tiltspeed*x),10)
end

function AIUpdatePosition(self)
    local centerX,_ = self:Center()
    if ball.x > centerX then
        self.direction = 1
    else
        self.direction = -1
    end
        
    self:MoveTo(Clamp(self:Left() + self.direction * self.velocity), 450)
end
    
myPaddle = MakePaddle(0, 10, UserInputUpdatePosition)
opponentPaddle = MakePaddle(0, 450, AIUpdatePosition)
opponentPaddle.velocity = 3

local accelerate

function ToggleControl(self)
    accelerate = not accelerate
    if accelerate then
            myPaddle:Handle("OnAccelerate", UserTilt)
            myPaddle:Handle("OnUpdate",nil)
    else
            myPaddle:Handle("OnAccelerate", nil)
            myPaddle:Handle("OnUpdate",UserInputUpdatePosition)
    end
end

pongBGRegion:Handle("OnDoubleTap", ToggleControl)
pongBGRegion:EnableInput(true)

---- Ball initialization

ball = Region('Region', 'ball', UIParent)
ball:SetLayer("HIGH")
ball:SetWidth(20)
ball:SetHeight(20)

function ball:MoveTo(xCoord, yCoord)
    self:SetAnchor('BOTTOMLEFT', xCoord, yCoord)
end

function ball:Reset()
    self.x = 0
    self.y = 460
    self.directionX = 1 -- to the right
    self.directionY = -1 -- down
    self.velocity = DEFAULT_VELOCITY
    self:MoveTo(self.x, self.y)
end

function ball:UpdateBallPosition()
    -- side detection
    if self.x <= 0 then
        self.directionX = 1
        upPush:Push(0.0); -- Play
    elseif self.x >= 300 then
        self.directionX = -1
        upPush:Push(0.0); -- Play
    end
    
    -- paddle detection
    if myPaddle:Top() >= self.y and 
        self.x >= (myPaddle:Left() - self:Width()) and 
        self.x <= myPaddle:Right() then
            self.directionY = 1 -- go up
            self.velocity = self.velocity + 0.5
            upPush:Push(0.0); -- Play
    end    
    if opponentPaddle:Bottom() <= self.y and 
        self.x >= (opponentPaddle:Left() - self:Width()) and 
        self.x <= opponentPaddle:Right() then
            self.directionY = -1 -- go down
            self.velocity = self.velocity + 0.5
            upPush:Push(0.0); -- Play
    end
    
    
    -- score detection
    if self.y < 0 then
        opponentScore:IncrementScore()
    elseif self.y > 460 then
        myScore:IncrementScore()
    end

    self.x = self.x + self.directionX * self.velocity
    self.y = self.y + self.directionY * self.velocity
    self:MoveTo(self.x, self.y)

end

ball.texture = ball:Texture("small-ball.png")
ball.texture:SetBlendMode("BLEND")
ball:Reset()
ball:Handle("OnUpdate",ball.UpdateBallPosition)
ball:Show()

pagebutton = MakeRegion({w=24,h=24,
    layer='TOOLTIP',
    x=ScreenWidth()-28, y=ScreenHeight()-28,
    img="circlebutton-16.png",
    input=true
})
pagebutton.t:SetTexCoord(0,1.0,0,1.0)
pagebutton:EnableClamping(true)
pagebutton:Handle("OnTouchDown", FlipPage)

upSample = FlowBox("object","mysample", FBSample)
upSample:AddFile("Blue-Mono.wav")
dac = _G["FBDac"]
upSample2 = FlowBox("object","mysample2", FBSample)
upSample2:AddFile("Plick.wav")

upPush = FlowBox("object", "mypush", FBPush)

dac:SetPullLink(0, upSample, 0)

upPush:SetPushLink(0,upSample2, 4)  
upPush:Push(-1.0); -- Turn looping off
upPush:RemovePushLink(0,upSample2, 4)  
upPush:SetPushLink(0,upSample2, 2)
upPush:Push(1.0); -- Set position to end so nothing plays.

dac:SetPullLink(0, upSample2, 0)
