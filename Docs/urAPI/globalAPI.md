Global API functions
====================

This page documents functions and variables that can be found in the global name space.


Debug Printing API
==================

DPrint 
-------
### Synopsis
    DPrint("output")
### Description
Debug print a give string in the center of the screen. This will also be used
for system errors and should not be used for normal user interactions.
### Arguments
- output (String)
    The string to print to the debug console.

RunScript
---------
### Synopsis
    RunScript("script")
### Description
Execute a string as Lua code.
### Arguments
- script (String)
    The lua code which is to be executed.

Timing API
==========

GetTime
-------
### Synopsis
    seconds = GetTime()
### Description
Returns the system uptime of the host machine in seconds, with millisecond precision.
### Returns
- seconds (Number)
    The current system uptime in seconds. 



urSound FlowBox API
===================

StartAudio
----------
### Synopsis
    StartAudio()
### Description
Starts the audio engine. Audio-related events will start working.

PauseAudio
----------
### Synopsis
    PauseAudio()
### Description
Pauses the audio engine. Audio-related events will not work while paused.

FlowBox
-------------
### Synopsis
    flowbox = FlowBox("type", "name", inheritedFlowbox)
### Description
Creates a new instance of a specified flowbox. To seed cloning use global
instances of flowboxes via `_G["FB"..objectname]`.
### Arguments
- type (String) [unused]
    String identifying the opject type.
- name (String) [unused]
	  User-specified name of the object.
- inheritedFlowbox (Flowbox)
	  The parent flowbox to inherit from. If specified, this creates a deep-copy of the 
    parent.

### Returns
- flowbox (Flowbox)
  A new instance of the given flowbox.
  
SourceNames
----------------
### Synopsis
    source1, source2, ... = SourceNames()
### Description
Returns the names of all source objects offered by the urSound engine. Related
flowbox variables can be accessed via _G["FB"..object1].
### Returns
- source1, source2, ... (String list)
	  A list of the names describing all urSound sources.

ManipulatorNames
---------------------
### Synopsis
    manipName1, manipName2, ... = ManipulatorNames()
### Description
Returns the names of all manipulator objects offered by the urSound engine.
Related flowbox variables can be accessed via `_G["FB"..manipName]`.
### Returns
- manipName1, manipName2, ... (List<String>)
    A list of names describing all urSound manipulators.

SinkNames
--------------
### Synopsis
    sinkName1, sinkName2, ... = SinkNames()
### Description
Returns the names of all sink objects offered by the urSound engine. Related
flowbox variables can be accessed via `_G["FB"..sinkName]`.
### Returns
- sinkName1, sinkName2, ... (List<String>)
    Names describing all urSound sinks.

File system helper API
======================

DocumentPath
------------
### Synopsis
    documentPath = DocumentPath("filename")
### Description
If the file exists in the document path, returns the absolute path to the given file.
If the file doesn't exist, throws an error.
### Arguments
- filename (String)
    Name of the file in the system's Documents folder.

### Returns
- documentPath (String)
    Absolute path of the found file.

SystemPath
----------
### Synopsis
    systemfilename = SystemPath("filename")
### Description
Converts a relative filename to include an iPhone-project's resource path.
### Arguments
- filename (String)
    File linked with the urMus project.

### Returns
- systemfilename (String)
    Absolute path of the file in the resources folder.

2D Interface and Interaction API (aka urLook)
=============================================

SetFrameRate
------------
### Synopsis
    SetFrameRate(fps)
### Description
Sets the maximum frames per second. Effective FPS may be lower if load is high.
### Arguments
- fps (Number)
    Desired target frames per second.
    
Page
-------
### Synopsis
    page = Page()
### Description
Returns the number index of the currently active page.
### Returns
- page (Number)
    Index of currently active page.

SetPage
-------
### Synopsis
    SetPage(pageIndex)
### Description
Sets the currently active page. Only frames created within an active page will
be rendered. This allows for multiple mutually exclusive pages to be prepared
and selectively rendered. Mouse events and other interface actions and events
will only work for the currently active page.
### Arguments
- pageIndex (Number)
    Index of the page to be made active. Side-effects: Deactivates all other pages.

NumMaxPages
-----------
### Synopsis
    maxpages = NumMaxPages()
### Description
Maximum number of pages supported by the current urMus built.
### Returns
- maxpages (Number)
    Maximum number of pages supported.

Region
-----------
### Synopsis
    newFrame = Region("frameType"[, "frameName"[, parentFrame[, "inheritsFrame"]]])
### Description
Creates a rectangular region.
### Arguments
- frameType (String)
    Type of the frame to be created (XML tag name): "Frame", "Button", etc. 
- frameName (String)
    Name of the newly created frame. If nil, no frame name is assigned. 
    The function will also set a global variable of this name to point to newly created frame. 
- parentFrame (Frame)
    The frame object that will be used as the created Frame's parent
    (cannot be a string!) Does not default to UIParent if given nil.
- inheritsFrame (String)
    A comma-delimited list of names of virtual frames to inherit
    from (the same as in XML). If nil, no frames will be inherited. These
    frames cannot be frames that were created using this function, they must
    be created using XML with virtual="true" in the tag. 

### Returns
  - newFrame (Frame)
    A reference to the newly created frame. 

NumRegions
------------
### Synopsis
    num = NumRegions()
### Description
Returns the current number of regions inside of the current page. 

InputFocus
-------------
### Synopsis
    region = InputFocus()
### Description
Returns the region that is currently receiving input events. The frame must have EnableInput(true).

HasInput
-----------
### Synopsis
    isOver = HasInput(frame, [topOffset, bottomOffset, leftOffset, rightOffset])
### Description
Determines whether or not the input is over the specified region. 
### Arguments
- frame (Frame)
    The frame (or frame-derived object such as Buttons, etc) to test with 
- topOffset (Number, optional)
    The distance from the top to include in calculations 
- bottomOffset (Number, optional) 
    The distance from the bottom to include in calculations 
- leftOffset (Number, optional) 
    The distance from the left to include in calculations 
- rightOffset (Number, optional) 
    The distance from the right to include in calculations.

### Returns
- isOver (Boolean) 
    True if mouse is over the frame (with optional offsets), false otherwise. 

InputPosition
-----------------
### Synopsis
    x, y = InputPosition()
### Description
Returns the input device's position on the screen.
### Returns
- x (Number)
    The input device's x-position on the screen. 
- y (Number)
    The input device's y-position on the screen. 

ScreenHeight
---------------
### Synopsis
    screenHeight = ScreenHeight()
### Description
Returns the height of the window in pixels. For an iPhone this is 480.
### Returns
- screenHeight (Number)
    Height of window in pixels. 

ScreenWidth
--------------
### Synopsis
    screenWidth = ScreenWidth()
### Description
Returns the width of the window in pixels. For an iPhone this is 320.
### Returns
- screenWidth (Number)
    Width of window in pixels

[urMus API Overview](overview.html)

 