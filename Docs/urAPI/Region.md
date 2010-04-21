Region API
=========
These functions are members of any created region. Some aspects of urMus Regions are inspired by the concept of a frame in the WoW addon API. For example arguments to region creation or layering are compatible.

Region:Handle
---------
### Synopsis
    region:Handle("handler", function)
    region:Handle("handler", nil)
### Description
Sets the action handler callback function for this given region. The function called
should be of the function(region, ...), with extra arguments depending on the event
type. If nil is passed for the function parameter, the current handler will be removed. 
### Arguments
- `handler` (String)
    A string of the event type we're looking to handle events for. Should be an
    event string of the kind "OnDragStart", "OnDragEnd", etc. See Overview for 
    possible event handler types.
- `function` (Function)
    The function to call for the given handler. If nil, the current handler 
    will be removed. 

Region:SetHeight
---------------
### Synopsis
    region:SetHeight(heightInPx)
### Description
Sets the height of the region in pixels. Will reflow children if this affects
their positioning.
### Arguments
- `heightInPx` (Number)
    The desired height of the region in pixels.

Region:SetWidth
--------------
### Synopsis
    region:SetWidth(widthInPx)
### Description
Sets the width of the region in pixels. Will reflow children if this affects
their positioning.
### Arguments
- `widthInPx` (Number)
    The desired width of the region in pixels.

Region:Show
----------
### Synopsis
    region:Show()
### Description
Makes the given region visible. Note that this is still subject to its parent's 
visibility.

Region:Hide
----------
### Synopsis
    region:Hide()
### Description
Makes the given region hidden. 

Region:EnableInput
-----------------
### Synopsis
    region:EnableInput(doEnable)
### Description
Enables or disables OnInput events for the given region. This allows regions
which would normally receive events to in effect "bubble up" their events to 
parent regions. Defaults to no.
### Arguments
- `doEnable` (Boolean)
    Whether to enable OnInput events for this region.

Region:EnableHorizontalScroll
----------------------------
### Synopsis
    region:EnableHorizontalScroll(doEnable)
### Description
Enables or disables horizontal scrolling for the given region. If enabled and
triggered, the region will send out OnHorizontalScroll events its handlers and 
physically scroll itself on the page.
### Arguments
- `doEnable` (Boolean)
    Whether to enable OnHorizontalScroll events and the ability to 
    horizontally scroll for this region.

Region:EnableVerticalScroll
--------------------------
### Synopsis
    region:EnableVerticalScroll(doEnable)
### Description
Enables or disables vertical scrolling for the sgiven region. If enabled and triggered, the
region will send out OnVerticalScroll events its handlers and physically scroll
itself on the page. 
### Arguments
- `doEnable` (Boolean)
    Whether to enable OnVerticalScroll events and the ability to vertically 
    scroll for this region.

Region:EnableMoving
----------------
### Synopsis
    region:EnableMoving(doEnableMoving)
### Description
Set whether to enable/disable moving for this region. Defaults to no.

### Arguments
- `doEnableMoving` (Boolean)
    Set whether to enable or disable moving for this region.  

Region:EnableResizing
------------------
### Synopsis
    region:EnableResizing(doEnableResizing)
### Description
Set whether to enable or disable resizing for this region. Defaults to no. If enabled,
pinch zoom gestures will scale the object.
### Arguments
- `doEnableResizing` (Boolean)
    Set whether to enable or disable resizing for this region.


Region:SetAnchor
--------------
### Synopsis
    region:SetAnchor("anchorLocation")
    region:SetAnchor("anchorLocation", relativeRegion)
    region:SetAnchor("anchorLocation", relativeRegion, "relativeAnchorLocation")
    region:SetAnchor("anchorLocation", relativeRegion, "relativeAnchorLocation", offsetX, offsetY)
    region:SetAnchor("anchorLocation", offsetX, offsetY)
### Description
Allows the region object to "attach" itself to a given point location on a parent
or relative region. In this way, changing a parent object will move its children 
in a well-specified way. If offsetX is given, offsetY must also be given. Otherwise
they default to (0,0). 
### Arguments
- `anchorLocation` (String)
    The location in which this region will attach itself to the parent or relative
    object. There are nine valid values: 
    * "TOP", "RIGHT", "BOTTOM", "LEFT": attach to center points of each respective side.
    * "TOPRIGHT", "TOPLEFT", "BOTTOMLEFT", "BOTTOMRIGHT": attach to corners of 
      the parent region.
    * "CENTER": attach to the center point of the parent/relative region.
- `relativeRegion` (Region, optional)
    The region object to attach to. If nil is specified, this region will attach
    itself to its parent region by default.
- `relativeAnchorLocation` (String, optional)
    The location which this region's anchorLocation will attach itself to on the 
    relativeRegion's location. Think of this as where the "anchorLocation" will be
    placed on the relativeRegion. If nil, this defaults to `BOTTOMLEFT`. 
    There are ten valid values: 
    * "TOP", "RIGHT", "BOTTOM", "LEFT": attach to center points of each respective side.
    * "TOPRIGHT", "TOPLEFT", "BOTTOMLEFT", "BOTTOMRIGHT": attach to corners of 
      the parent region.
    * "CENTER": attach to the center point of the parent/relative region.
    * "ALL": the region will scale with its parent/relative region.
- `offsetX` (Number, optional)
    The X offset of anchorLocation from relativeAnchorLocation. Negative values mean
    to the left, positive means to the right. Defaults to 0. 
- `offsetY` (Number, optional)
    The Y offset of anchorLocation from relativeAnchorLocation. Negative values mean
    down, positive means up. Defaults to 0.
    
Region:Layer
--------------------
### Synopsis
    "layerName" = region:Layer()
### Returns
- `layerName` (String)
      Returns the human-readable name of the layer. Could be "PARENT",
      "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN", 
      "FULLSCREEN_DIALOG", or "TOOLTIP", in ascending order of visibility.

Region:SetLayer
---------------
### Synopsis
    region:SetLayer("layerName")
### Description
Changes the z-index of the region. 
### Arguments
- `strataName` (String)
    The layer name which this region should reside on. Could be "PARENT",
    "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN", 
    "FULLSCREEN_DIALOG", or "TOOLTIP", in ascending order of visibility. 
    
Region:Parent
---------------
### Synopsis
    parent = region:Parent()
### Description
Returns a reference to the parent region. 

Region:SetParent
---------------
### Synopsis
    region:SetParent(parent)
### Arguments
- `parent` (Region)
    Sets the parent of this region to `parent`.

Region:Children
-----------------
### Synopsis
    child1, child2, ... = region:Children()
### Returns
- child1, child2, ... childrenN (List<String>)
    A list of refrences to this region's children elements.

Region:Name
-------------
### Synopsis
    rName = region:Name()
### Returns
- `rName` (String)
    The name of this region.

Region:Bottom
---------------
### Synopsis
    bottomY = region:Bottom()
### Description
Gets the Y coordinate of bottom of the region, offset from the side of the screen.
### Returns
- `bottomY` (Number)
    The Y coordinate of the bottom of the region in pixels.

Region:Center
---------------
### Synopsis
    centerX, centerY = region:Center()
### Description
Gets the center X and Y coordinates for the region.
### Returns
- `centerX` (Number)
    The X coordinate of the center of the region in pixels offset from the top
    of the page. 

Region:Height
---------------
### Synopsis
    heightInPx = region:Height()
### Returns
- `heightInPx` (Number)
    The height of the region in pixels.

Region:Left
-------------
### Synopsis
    leftX = region:Left()
### Returns
- `leftX` (Number)
    The left X coordinate offset of the region in pixels with respect to the page.

Region:Right
--------------
### Synopsis
    rightX = region:Right()
### Returns
- `rightX` (Number)
    The right X coordinate offset of the region in pixels with respect to the page.

Region:Top
------------
### Synopsis
    topY = region:Top()
### Returns
- `topY` (Number)
    The top Y coordinate offset of the region in pixels with respect to the page.

Region:Width
--------------
### Synopsis
    widthInPx = region:Width()
### Returns
- `widthInPx` (Number)
    The width of the current region in pixels.

Region:Anchor
--------------
### Synopsis
    anchorLocation, relativeToRegion, relativeAnchorLocation, offsetX, offsetY = region:Anchor()
### Description
Returns information about the current anchor point settings for this region.
### Returns
- `anchorLocation` (String)
    The location in which this region has attached itself to the parent or relative
    object. There are nine valid values: 
    * "TOP", "RIGHT", "BOTTOM", "LEFT": attached to center points of each respective side.
    * "TOPRIGHT", "TOPLEFT", "BOTTOMLEFT", "BOTTOMRIGHT": attached to corners of 
      the parent region.
    * "CENTER": attached to the center point of the parent/relative region.
- `relativeToRegion` (Region)
    The region object this region is attached to.
- `relativeAnchorLocation` (String)
    The location which the region's anchorLocation is attached to on the `relativeToRegion`.
    There are ten valid values: 
    * "TOP", "RIGHT", "BOTTOM", "LEFT": attach to center points of each respective side.
    * "TOPRIGHT", "TOPLEFT", "BOTTOMLEFT", "BOTTOMRIGHT": attach to corners of 
      the parent region.
    * "CENTER": attach to the center point of the parent/relative region.
    * "ALL": the region will scale with its parent/relative region.
- `offsetX` (Number)
    The X offset of anchorLocation from relativeAnchorLocation. Negative values mean
    to the left, positive means to the right.
- `offsetY` (Number)
    The Y offset of anchorLocation from relativeAnchorLocation. Negative values mean
    down, positive means up.

Region:IsShown
-------------
### Synopsis
    isShown = region:IsShown()
### Returns
- isShown (Boolean)
    Whether the current region's shown property is true or false. Note that this
    doesn't necessarily guarantee that the object is visible (if the parent is
    hidden, this one will be as well).

Region:IsVisible
---------------
### Synopsis
    isVisible = region:IsVisible()
### Returns
- isVisible (Boolean)
    Whether the current region is visible on-screen. A region is only visible if all its parents are visible. This is separate from Show() which enables that a region becomes visible if all parents are visible.


Region:SortStrata
----------------

Region:Alpha
--------------
### Synopsis
    opacity = region:Alpha()
### Description
Gets the alpha opacity of this region. 
### Returns
- `opacity` (Number)
    Opacity [0,1], with 0 being transparent and 1 being opaque. 

Region:SetAlpha
--------------
### Synopsis
    region:SetAlpha(opacity)
### Description
Set the alpha opacity of this region. 
### Arguments
- `opacity` (Number)
    Opacity [0,1], with 0 being transparent and 1 being opaque. 

Region:Texture
-------------------
### Synopsis
    region:Texture()
    region:Texture("imageName.ext")
### Description
Instantiates and sets a new texture object which is tied to this region. 
### Arguments
- `imageName.ext` (String, optional)
    Optionally takes an image name of an image available in the system resources
    folder.

Region:TextLabel
----------------------
### Synopsis
    region:TextLabel()
### Description
Instantiates and sets a name text label object inside of this region.

Region:Lower
-----------
### Synopsis
    region:Lower()
### Description
Lower this region on the viewing hierarchy. This is useful if two regions have the 
same visibility and they should be higher / lower than another.

Region:Raise
-----------
### Synopsis
    region:Raise()
### Description
Raise this region in the viewing hierachy. See Lower()

Region:IsTopLevel
-----------------
### Synopsis
    isTopLevel = region:IsTopLevel()
### Returns
- `isTopLevel` (Boolean)
      True or false if the region is the highest for the given page.

Region:MoveToTop
-----------------
### Synopsis
    region:MoveToTop()
### Description
Moves this region to the top of the page viewing hierarchy.

Region:EnableClamping
---------------------
### Synopsis
    region:EnableClamping(doEnableClamping)
### Description
If enabled, the region can never be dragged outside of the screen boundaries. 
### Arguments
- `doEnableClamping` (Boolean)
    Whether to enable clamping or not.

Region:RegionOverlap
------------------
### Synopsis
    isOverlapping = region:RegionOverlap(otherRegion)
### Description
Helper function to check whether two regions are overlapping eachother. 
### Arguments
- `otherRegion` (Region)
    The region to compare against to see if the two are overlapping eachother.
  
### Returns
- `isOverlapping` (Boolean)
    Whether the regions are overlapping.

Region:UseAsBrush
----------------
### Synopsis
    region:UseAsBrush()
### Description
Given a region, use this as a draggable "brush" object to paint to. If a texture
hasn't been instantiated for this region already, it will give it a default one.

Region:EnableClipping
--------------------
### Synopsis
    region:EnableClipping(doEnable)
### Description
Enables or disables clipping for the region. In other words, clipping enabled
means that only parts of the region that are within the current clip region will
be viewable on screen
### Arguments
- `doEnable` (Boolean)
    Whether to enable clipping for this region.

Region:ClipRegion
-------------------
### Synopsis
    leftX, bottomY, width, height = region:ClipRegion
### Description
Gets the current clip region's bounding box.
### Returns
- `leftX` (Number)
    The left X pixel offset from the containing page.
- `bottomY` (Number)
    The bottom Y pixel offset from the containing page.
- `width` (Number)
    The width of the clipping region in pixels.
- `height` (Number)
    The height of the clipping region in pixels.

Region:SetClipRegion
-------------------
### Synopsis
    region:SetClipRegion(leftX, bottomY, width, height)
### Description
Sets the current clip region's bounding box.
### Arguments
- `leftX` (Number)
    The left X pixel offset from the containing page.
- `bottomY` (Number)
    The bottom Y pixel offset from the containing page.
- `width` (Number)
    The width of the clipping region in pixels.
- `height` (Number)
    The height of the clipping region in pixels.

Event handling
==============

OnDragStart
-----------
### Description
Fires when a region starts being dragged. This is requires that the region has been made movable via EnableMoving().

OnDragStop
----------
### Description
Fires when a region stops being dragged. 

OnEnter
-------
### Description
Fires when it has been detected that an input device has entered a given region.

OnLeave
-------
### Description
Fires when it has been detected that an input device has left a given region.

OnTouchDown
-----------
### Description
Fires when a touch event happens inside a region that takes input. This must be enabled via EnableInput(). This will only be triggered for the topmost region that takes input.

OnTouchUp
---------
### Description
Fires when a touch event is released while inside a region that takes input. THis must be enabled via EnableInput(). This will only be triggered for the topmost region that takes input.

OnDoubleTap
-----------
### Description
Fires when a double-tap touch event is performed while inside a region that takes input. This must be enabled via EnableInput(). This will only be triggered for the topmost region that takes input.

OnHide
------
### Description
Fires when an object has been hidden.

OnShow
------
### Description
Fires when an object is made to be shown. Note that this is different from being
visible; if the parent object is still invisible then this will still fire; however
the object itself will not be actually visible on screen.

OnAccelerate
------------
### Handler Synopsis
    function(region,x, y, z)
### Description
Fires when an acceleration event is detected. No guarantees are made about the frequency
of its updates. 

OnHeading
---------
### Handler Synopsis
    function(region,x,y, z, north)
### Description
Fires when the heading for the given device changes. Note that this is only possible
if the device supports compass directions.

OnLocation
----------
### Handler Synopsis
    function(region,latitude, longitude)
### Description
Fires when the location of the given device changes. Note this is only possible 
with a device which supports GPS coordinate finding.

OnHorizontalScroll
------------------
### Handler Synopsis
    function(region, scrollspeedX)
### Description
Fires when a given region is scrolled horizontally. This handler returns scrollspeedX,
the velocity of the current scroll.

OnVerticalScroll
------------------
### Handler Synopsis
    function(region, scrollspeedY)
### Description
Fires when a given region is scrolled vertically. This handler returns scrollspeedY,
the velocity of the current scroll.

OnPageEntered
-------
### Description
Fires when the page that the region belongs to has been entered into.

OnPageLeft
----------
### Description
Fires when the page that the region belongs to is left. 


[urMus API Overview](overview.html)
