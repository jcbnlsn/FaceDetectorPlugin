-- -------------------------------------------------------------------------------
--
--  main.lua - FaceDetectorExample
--  Created by jcb on 06/11/2016.
--
-- -------------------------------------------------------------------------------

local faceDetector = require "plugin.faceDetector"
local widget = require "widget"
local inspect = require "inspect"

display.setStatusBar( display.HiddenStatusBar )

local group = display.newGroup()

-- Load image
local filename = "photos/bob.jpg"
--local filename = "photos/jenny.jpg"
local baseDir = system.ResourceDirectory -- system.DocumentsDirectory

local image = display.newImage( filename, baseDir )
image.anchorX, image.anchorY = 0,0
group:insert(image)

local f = display.contentWidth/image.width
group:scale(f,f)
group.x, group.y = 0,0

-- Marks and overlays visibility toggle
local marks, overlays = {}, {}
local function toggleVisibility(t, bool)
    for i=1, #t do
        if bool then t[i].isVisible = bool
        else t[i].isVisible = not t[i].isVisible end
    end
end

-- Calculate angle between two points
local function calculateAngle ( obj1, obj2 )
		
	local xDist = obj2.x-obj1.x
	local yDist = obj2.y-obj1.y
	local a = math.deg (math.atan( yDist/xDist ))
	if ( obj1.x < obj2.x ) then a = a+90 else a = a+270 end
	
	return a
end

-- Mark up tracked face data
local function markFeatures(faces)

    local markStrokeWidth = 4
    local markRadius = 10

    for i=1, #faces do
            
        -- Bounding boundingBox for face
        local bounds = faces[i].bounds
        local boundingBox = display.newRect(group, bounds.x, bounds.y, bounds.width, bounds.height)
        boundingBox:setFillColor(1,1,1,0)
        boundingBox:setStrokeColor(.6,0,.6,1)
        boundingBox.strokeWidth = markStrokeWidth
        table.insert(marks, boundingBox)
        
        -- Left eye position
        local leftEyePos = faces[i].leftEyePosition
        local leftEyeMark = display.newCircle(group, leftEyePos.x, leftEyePos.y, markRadius)
        leftEyeMark:setFillColor(.6,.6,0,0)
        leftEyeMark:setStrokeColor(.6,.6,0,1)
        leftEyeMark.strokeWidth = markStrokeWidth
        table.insert(marks, leftEyeMark)
        
        -- Right eye position
        local rightEyePos = faces[i].rightEyePosition
        local rightEyeMark = display.newCircle(group, rightEyePos.x, rightEyePos.y, markRadius)
        rightEyeMark:setFillColor(.6,.6,0,0)
        rightEyeMark:setStrokeColor(.6,.6,0,1)
        rightEyeMark.strokeWidth = markStrokeWidth
        table.insert(marks, rightEyeMark)
        
        -- Mouth position
        local mouthPos = faces[i].mouthPosition
        local mouthMark = display.newCircle(group, mouthPos.x, mouthPos.y, markRadius)
        mouthMark:setFillColor(.6,.6,0,0)
        mouthMark:setStrokeColor(0,.6,.6,1)
        mouthMark.strokeWidth = markStrokeWidth
        table.insert(marks, mouthMark)
        
        local angle = calculateAngle(leftEyePos, rightEyePos)
        boundingBox.rotation = angle-90
    end
end

-- Example usage: apply silly overlay
local function applyOverlay(faces)

    for i=1, #faces do
        
        local bounds = faces[i].bounds

        local overlay = display.newImage("overlay.png")
        overlay.x, overlay.y = bounds.x, bounds.y
        group:insert(overlay)
        table.insert(overlays, overlay)

        local angle = calculateAngle(faces[i].leftEyePosition, faces[i].rightEyePosition)
        overlay.rotation = angle-90
        
        local factor = bounds.width/(overlay.width-280)
        overlay:scale(factor, factor)
    end
end

-- Face Detector callback listener
local function listener(event)

    print("Number of faces found: "..#event.faces)
    print (inspect(event))

    markFeatures(event.faces)
    applyOverlay(event.faces)

    toggleVisibility(overlays, false)
end

-- Face detector track image
local path = system.pathForFile( filename, baseDir )
--local accuracy = "low" -- optional: default is "high"
faceDetector.track(path, accuracy, listener )

-- Button event handler
local function handleButtonEvent(event)
    if event.target.id == "Marks" then
        toggleVisibility(marks)
    elseif event.target.id == "Overlay" then
        toggleVisibility(overlays)
    end
end

-- Buttons
local options = {"Marks", "Overlay"}
for i=1, #options do
    local button = widget.newButton(
    {
        label = options[i],
        fontSize = 30,
        id = options[i],
        onRelease = handleButtonEvent,
        shape = "roundedRect",
        width = 150,
        height = 70,
        cornerRadius = 10,
        fillColor = { default={.3,.6,.9,1}, over={.4,.7,1,1} },
        labelColor = { default={1,1,1,1}, over={1,1,1,1} }
        
    })
    button.x, button.y = 150 , (i*100)
end