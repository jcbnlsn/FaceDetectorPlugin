
Documentation and samplecode for:
###**FaceDetector Plugin for Corona SDK**

The FaceDetector plugin analyzes images and detects if there are human faces in in it.  The plugin returns position data for bounding boxes, eyes and mouths of the faces detected in the image.

Here is a small video demo: http://shakebrowser.net/fdvideo.html 

This plugin is available for: iOS, Mac OS and the Corona Simulator on Mac OS.

###**Syntax**
```lua
faceDetector.track ( filename[, accuracy], listener )
```

**filename**
Path to the image file to track. 

**accuracy**
(optional) Tracking accuracy. Can have the values "high" and "low". Default value is "high".  Low accuracy is fast. High accuracy is slower but more accurate.

**listener**
The event dispatched to the listener will be a completion event with the position data of face(s) features. The position data is relative to the images 0,0 anchor point.

Example face tracking data returned:
```lua
  event.faces = 
  { 
    { -- 1st face detected
      bounds = {
        height = 354, width = 354,
        x = 272, y = 269
      },
      leftEyePosition = { x = 216, y = 187 },
      mouthPosition = { x = 272, y = 357 },
      rightEyePosition = { x = 341, y = 187 }
    },
    { -- 2nd face detected
      bounds = { 
        height = 246, width = 246,
        x = 782, y = 197
      },
      leftEyePosition = { x = 717, y = 155 },
      mouthPosition = { x = 787, y = 258 },
      rightEyePosition = { x = 833, y = 140 }
    }
  }
```
###**Example**
```lua
  local fd = require "plugin.faceDetector"

  local function listener(event)
  	local faces = event.faces
	print ( "Number of faces detected: "..#faces )
	
	for i=1, #faces do
	  -- Simply printing mouth positions for this example
	  print("Face "..i.." mouth position "..faces[i].mouthPosition.x..", "..faces[i].mouthPosition.y
	end
  end

  local imagepath = system.pathForFile( "selfie.jpg", system.DocumentsDirectory )
  fd.track(imagepath, listener)
```
