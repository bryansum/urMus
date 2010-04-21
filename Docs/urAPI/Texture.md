Texture API
===========
These functions are member functions of a created texture.

Texture:SetTexture
------------------
### Synopsis
    texture:SetTexture("imageName.ext")
    texture:SetTexture(r,g,b,a)
### Description
Sets the texture style for a given texture. If colors are specified a plain color empty texture will be assumed and existing textures will be removed.
### Arguments
- `imageName.ext` (String)
    Sets the texture to the specified image. This should be present within the 
    system's images folder.
- r (Number)
    A number [0,255] describing the intensity of red in the texture color. 
- g (Number)
    A number [0,255] describing the intensity of green in the texture color. 
- b (Number)
    A number [0,255] describing the intensity of blue in the texture color. 
- a (Number)
    A number [0,255] describing the alpha transparency of the texture. 0 is fully
    transparent, 255 is opaque.

Texture:SetGradientColor
------------------------
### Synopsis
    texture:SetGradientColor("orientation", minR, minG, minB, minA, maxR, maxG, maxB, maxA)
### Description
Sets the texture to be a linear gradient in the given orientation. The texture
will start at minRGBA and end at maxRGBA, with the linear interpolation between.
### Arguments
- `orientation` (String)
    The orientation of the linear gradient. This should be one of "HORIZONTAL",
    "VERTICAL", "TOP", "BOTTOM"
- minR (Number)
    A number [0,255] describing the intensity of red in the minimum texture color. 
- minG (Number)
    A number [0,255] describing the intensity of green in the minimum texture color. 
- minB (Number)
    A number [0,255] describing the intensity of blue in the minimum texture color. 
- minA (Number)
    A number [0,255] describing the alpha transparency of the minimum texture color. 0 is fully
    transparent, 255 is opaque.
- maxR (Number)
    A number [0,255] describing the intensity of red in the maximum texture color. 
- maxG (Number)
    A number [0,255] describing the intensity of green in the maximum texture color. 
- maxB (Number)
    A number [0,255] describing the intensity of blue in the maximum texture color. 
- maxA (Number)
    A number [0,255] describing the alpha transparency of the maximum texture color. 0 is fully
    transparent, 255 is opaque.

Texture:SetSolidColor
----------------------
### Synopsis
    texture:SetSolidColor(r,g,b[,a])
### Description
Sets the color of a texture to a solid color specified by the RGBA values. 
### Arguments
- r (Number)
    A number [0,255] describing the intensity of red in the texture color. 
- g (Number)
    A number [0,255] describing the intensity of green in the texture color. 
- b (Number)
    A number [0,255] describing the intensity of blue in the texture color. 
- a (Number)
    A number [0,255] describing the alpha transparency of the texture. 0 is fully
    transparent, 255 is opaque.

Texture:SolidColor
----------------------
### Synopsis
    r, g, b, a = texture:SolidColor()
### Returns
- r (Number)
    A number [0,255] describing the intensity of red in the texture color. 
- g (Number)
    A number [0,255] describing the intensity of green in the texture color. 
- b (Number)
    A number [0,255] describing the intensity of blue in the texture color. 
- a (Number)
    A number [0,255] describing the alpha transparency of the texture. 0 is fully
    transparent, 255 is opaque.

Texture:SetTexCoord
-------------------
### Synopsis
    texture:SetTexCoord(left%,right%,top%,bottom%)
    texture:SetTexCoord(ULx%, ULy%, URx%, URy%, BLx%, BLy%, BRx%, BRy%)
### Description
Sets the texture coordinates for a given shape. If the first form is specified,
the texture will be place in a rectangular space specified by [left%, right%, top%, bottom%].
Otherwise it will be placed within a polygon give by the second form.
### Arguments
- `left%, right%, top%, bottom%` (Number) 
    The percentage of the page [0..1] from either the left, right, top, or bottom, 
    respectively, to put that side of the texture. 
- `ULx%, ULy%, URx%, URy%, BLx%, BLy%, BRx%, BRy%` (Number)
    The percentage [0..1] of from its respective corner of the page to its respective edge
    of the texture.

Texture:TexCoord
-------------------
### Synopsis
    ULx%, ULy%, URx%, URy%, BLx%, BLy%, BRx%, BRy% = texture:TexCoord()
### Description
The coordinates of the texture. Defaults to (0,1,1,1,0,0,1,0)
### Returns
- `ULx%, ULy%, URx%, URy%, BLx%, BLy%, BRx%, BRy%` (Number)
    The percentage [0..1] of from its respective corner of the page to its respective edge
    of the texture.

Texture:SetRotation
-------------------
### Synopsis
  texture:SetRotation(angle)
### Description
Rotates the texture. This modifies the texture coordinates.
### Arguments
- `angle` (Number)
    Set the angle of rotation in radians.

Texture:BlendMode
-----------------
### Synopsis
    mode = texture:BlendMode()
### Returns
- `mode` (String)
    Returns the blend mode for this texture. Defaults to "DISABLED" 

Texture:SetBlendMode
--------------------
### Synopsis
    texture:SetBlendMode(mode)
### Description
Sets the blend mode for this texture. Defaults to "DISABLED". 
### Arguments
- `mode` (String)
    Sets the blend mode for this texture. Can be "DISABLED", "BLEND", "ALPHAKEY",
    "ADD", "MOD", or "SUB".

Texture:Point
-------------
### Synopsis
    texture:Point(x,y)
### Description
Draws a point at [x,y]. If Region:UseAsBrush() is enabled, it uses the texture of that region as brush, else it draws a point of width set by Texture:SetBrushSize().
### Arguments
- `x, y` (Number)
    Draws a point at coordinates x,y. 

Texture:Line
------------
### Synopsis
    texture:Line(startX, startY, endX, endY)
### Description
Draws a line of width set by SetBrushSize() from 
[startX,startY] to [endX,endY].
### Arguments
- `startX, startY, endX, endY` (Number)
    The starting and ending coordinates of the line to be drawn on this texture. 

Texture:Ellipse
---------------
### Synopsis
	texture:Ellipse(centerX, centerY. width, height)
### Description
Draws an ellipse at position [centerX,centerY] with a [width] and [height] into the current texture. If Region:UseAsBrush() is enabled, it uses the texture of that region as brush, else it draws a line of width set by Texture:SetBrushSize().
### Arguments
- `centerX, centerY, width, height` (Number)
	The center, width and height of the ellipse to draw.

Texture:Quad
------------
### Synopsis
	texture:Quad(x1,y1,x2,y2,x3,y3,x4,y4)
### Description
Draws a closed quadrangle with corners [x1,y1], [x2,y2], [x3,y3], [x4,y4] into the current texture. If Region:UseASBrush() is enabled, it uses the teture of that region as brush, else it draws a line of width set by Texture:SertBrushSize().
### Arguments
- `x1, y1, x2, y2, x3, y3, x4, y4` (Number)
	The coordiates of corners of a quadrangle to be drawn.

Texture:Rect
------------
### Synopsis
	texture:Rect(x,y,width ,height)
### Description
Draws a closed rectangle at position [x,y], with [width] and [height] into the current texture. If Region:UseASBrush() is enabled, it uses the teture of that region as brush, else it draws a line of width set by Texture:SertBrushSize().
### Arguments
- `x, y, width, height` (Number)
	The coordiates and size of a rectangle to draw.

Texture:SetFill
---------------
### Synopsis
	texture:SetFill(fill)
### Description
Set if a close line drawing such as Quad, Rect or Ellipse is filled or not.
### Arguments
- `fill` (Boolean)

Texture:Clear
-------------
### Synopsis
    texture:Clear()
### Description
If the region is enabled with Region:UseAsBrush(), clears any brush strokes currently
on the texture.

Texture:BrushSize
-----------------
### Synopsis
    brushSizePx = texture:BrushSize()
### Description
Returns the current width of the brush used to draw with drawing functions such as Point, Line, Ellipse, Quad and Rect.
### Returns
- `brushSizePx` (Number)
    Size of the brush in pixels. Defaults to 1

Texture:SetBrushSize
--------------------
### Synopsis
    texture:SetBrushSize(brushSizePx)
### Description
Sets the width of the brush to be used by drawing functions such as Point, Line, Ellipse, Quad and Rect. Affects both texture brushes set with region:UseAsBrush() and pixel brushes.
### Arguments
- `brushSizePx` (Number)
    Size of the brush in pixels. Defaults to 1

Texture:SetBrushColor
---------------------
### Synopsis
    texture:SetBrushColor(r,g,b,a)
### Description
Sets the color of the brush used for drawing functions such as Point, Line, Ellipse, Quad and Rect. Affects both texture brushes set with region:UseAsBrush() and pixel brushes.
### Arguments
- `r,g,b,a` (Number)
    Color rgb components and alpha to be used by the brush.


[urMus API Overview](overview.html)
