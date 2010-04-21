TextLabel API
==============
These functions are member functions of a TextLabel.

TextLabel:Font
-------
### Synopsis
    fontFace = textlabel:Font()
### Description
Returns the name of the typeface for the given font. Defaults to "Helvetica".
### Returns
- fontFace (String)
    The face name of the current textlabel's font.

TextLabel:SetFont
-------
### Synopsis
    textlabel:SetFont("fontName")
### Description
Changes the given font for a textlabel.
### Arguments
- fontName (String)
    A valid system font to change the textlabel's font to.

TextLabel:HorizontalAlign
-----------
### Synopsis
    hJustificationStatus = textlabel:HorizontalAlign()
### Description
Returns the horizontal justification of a given textlabel.
### Returns
- hJustificationStatus (String)
    The horizontal justification of the the textlabel. One of "LEFT", "CENTER",
    "RIGHT".

TextLabel:SetHorizontalAlign
-----------
### Synopsis
    textlabel:SetHorizontalAlign("justifyH")
### Description
Set the horizontal justification of a given textlabel.
### Arguments
- justifyH (String)
    The desired horizontal justification for the textlabel. One of "LEFT",
    "CENTER", "RIGHT".

TextLabel:VerticalAlign
-----------
### Synopsis
    vJustificationStatus = textlabel:VerticalAlign()
### Description
Returns the vertical justification of a given textlabel.
### Returns
- vJustificationStatus (String)
    The vertical justification of the the textlabel. One of "TOP", "MIDDLE", 
    "BOTTOM".

TextLabel:SetVerticalAlign
-----------
### Synopsis
    textlabel:SetVerticalAlign("vAlign")
### Description
Set the horizontal justification of a given textlabel.
### Arguments
- vAlign (String)
    The desired horizontal justification for the textlabel. The string must be 
    one of "TOP", "MIDDLE", or "BOTTOM" to have any effect.

TextLabel:ShadowColor
--------------
### Synopsis
    r, g, b, a = textlabel:ShadowColor()
### Description
Returns the RGBA values for the given textlabel's shadow. Defaults to (0,0,0,128)
### Returns
- r (Number)
    A number [0,255] describing the intensity of red in the shadow color. 
- g (Number)
    A number [0,255] describing the intensity of green in the shadow color. 
- b (Number)
    A number [0,255] describing the intensity of blue in the shadow color. 
- a (Number)
    A number [0,255] describing the alpha transparency of the shadow. 0 is fully
    transparent, 255 is opaque.

TextLabel:SetShadowColor
--------------
### Synopsis
    textlabel:SetShadowColor()
    textlabel:SetShadowColor(r,g,b,a)
### Description
Sets the RGBA values for the given textlabel shadow. If no argument is provided, this disables the shadow.
### Arguments
- r (Number)
    A number [0,255] describing the intensity of red in the shadow color. 
- g (Number)
    A number [0,255] describing the intensity of green in the shadow color. 
- b (Number)
    A number [0,255] describing the intensity of blue in the shadow color. 
- a (Number)
    A number [0,255] describing the alpha transparency of the shadow. 0 is fully
    transparent, 255 is opaque.

TextLabel:ShadowOffset
---------------
### Synopsis
    x, y = textlabel:ShadowOffset()
### Description
Returns the distance in pixels the textlabel's shadow deviates from the main 
textlabel body. Positive x is the to right of the textlabel while positive y 
is below. A textlabel defaults to a value is 0,0.
### Returns
- x (Number)
    Horizontal shadow offset in pixels from the main textlabel. 
- y (Number)
    Vertical shadow offset in pixels from the main textlabel. 

TextLabel:SetShadowOffset
---------------
### Synopsis
    textlabel:SetShadowOffset(x,y)
### Description
Sets the distance in pixels the textlabel's shadow deviates from the main 
textlabel body. Positive x is the to right of the textlabel while positive y 
is below.
### Arguments
- x (Number)
    Horizontal shadow offset in pixels from the main textlabel. 
- y (Number)
    Vertical shadow offset in pixels from the main textlabel. 

TextLabel:ShadowBlur
----------------
### Synopsis
    blur = textlabel:ShadowBlur()
### Description
Return the blur factor used for the text shadow.
### Returns
- blur (Number)
  Blur of the shadow in pixels.

TextLabel:SetShadowBlur
-------------------
### Synopsis
    textlabel:SetShadowBlur(blur)
### Arguments
Sets the blur factor to be used with the shadow. 0.0 means no blur, and the blur increases with size, roughly corresponding to pixel range.

TextLabel:Spacing
----------
### Synopsis
    lineSpacing = textlabel:Spacing()
### Description
Returns the line spacing in pixels between each successive line in a paragraph. 
of text. 
### Returns
- lineSpacing (Number)
    Returns the distance between each successive line in a paragraph of text. 

TextLabel:SetSpacing
----------
### Synopsis
    textlabel:SetSpacing()
### Description
Sets the line spacing distance in pixels between successive lines in a paragraph.
### Arguments
- lineSpacing (Number)
    Returns the distance in pixels between each successive line in a paragraph of text. 

TextLabel:Color
------------
### Synopsis
    r, g, b, a = textlabel:Color()
### Description
Returns the RGBA values for the given textlabel text color. Defaults to (255,255,255,255).
### Returns
- r (Number)
    A number [0,255] describing the intensity of red in the textlabel. 
- g (Number)
    A number [0,255] describing the intensity of green in the textlabel. 
- b (Number)
    A number [0,255] describing the intensity of blue in the textlabel. 
- a (Number)
    A number [0,255] describing the alpha transparency of the textlabel. 0 is fully
    transparent, 255 is opaque.

TextLabel:SetColor
--------------
### Description
See TextLabel:SetTextColor

TextLabel:SetTextColor
------------
### Synopsis
    textlabel:SetTextColor(r,g,b,a)
### Description
Sets the RGBA values for the given textlabel.
### Arguments
- r (Number)
    A number [0,255] describing the intensity of red in the textlabel. 
- g (Number)
    A number [0,255] describing the intensity of green in the textlabel. 
- b (Number)
    A number [0,255] describing the intensity of blue in the textlabel. 
- a (Number)
    A number [0,255] describing the alpha transparency of the textlabel. 0 is fully
    transparent, 255 is opaque.

TextLabel:Wrap
----------
### Synopsis
    wrap = textlabel:Wrap()
### Description
Describes how textlabel that exceeds the width of a region will be line-broken. Can be WORD, CHAR, or CLIP.
### Returns
- wrap (String)
    Returns the current line breaking mode.

TextLabel:SetWrap
---------------
### Synopsis
    textlabel:SetWrap(wrap)
### Description
Set the current line breaking mode for text lines that exceed the width of the region.
### Arguments
- wrap (String)
    String describing how lines will be broken. One of "WORD",
    "CHAR", "CLIP". "WORD" will break at spaces only. "CHAR" will break after any character. "CLIP" will clip.

TextLabel:Height
---------------
### Synopsis
    heightInPx = textlabel:Height()
### Description
Returns the height of the given textlabel in pixels. 
### Returns
- heightInPx (Number)
    Returns the height of the given font in px.

TextLabel:SetLabelHeight
-------------

TextLabel:Width
--------------
### Synopsis
    widthInPx = textlabel:Width()
### Returns
- widthInPx (Number)
    The width of a given textlabel in px.

TextLabel:Label
-------
### Synopsis
    text = textlabel:Label()
### Description
Returns the current text value for this given textlabel.
### Returns
- text (String)
    The value of the current text string.

TextLabel:SetLabel
-------
### Synopsis
    textlabel:SetLabel("text")
### Description
Sets the current text value for the given textlabel.
### Arguments
- text (String)
    The desired text value for the label.

[urMus API Overview](overview.html)
