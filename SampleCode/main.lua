
------------------------------------------------------------------------
--
-- FaceDetector plugin for Corona SDK sample code
-- Created by Jacob Nielsen 2016
--
------------------------------------------------------------------------

local fd = require "plugin.faceDetector"
local widget = require "widget"
local inspect = require "inspect"

local group
local markStrokeWidth = 8
local markRadius = 10

display.setStatusBar( display.HiddenStatusBar )

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

-- Track and mark faces
local function detectFaces(fileName, baseDir)

    local baseDir = baseDir or system.DocumentsDirectory

    -- Load image
    local img = display.newImage( fileName, baseDir )
    img.anchorX, img.anchorY = 0,0
    group:insert(img)

    -- Scale image to screen
    local factor = display.contentWidth/(img.width+250)
    group:scale(factor, factor)
    group.x, group.y = display.contentCenterX-((img.width/2)*factor)+100, display.contentCenterY-((img.height/2)*factor)

    -- FaceDetector callback listener
    local function listener(event)

        print ( inspect(event))

        for i=1, #event.faces do
            
            -- Bounding boundingBox for face
            local bounds = event.faces[i].bounds
            local boundingBox = display.newRect(bounds.x, bounds.y, bounds.width, bounds.height)
            group:insert(boundingBox)
            boundingBox:setFillColor(1,1,1,0)
            boundingBox:setStrokeColor(.6,0,.6,1)
            boundingBox.strokeWidth = markStrokeWidth
            table.insert(marks, boundingBox)
            
            -- Left eye position
            local leftEyePos = event.faces[i].leftEyePosition
            local leftEyeMark = display.newCircle(leftEyePos.x, leftEyePos.y, markRadius)
            group:insert(leftEyeMark)
            leftEyeMark:setFillColor(.6,.6,0,0)
            leftEyeMark:setStrokeColor(.6,.6,0,1)
            leftEyeMark.strokeWidth = markStrokeWidth
            table.insert(marks, leftEyeMark)
            
            -- Right eye position
            local rightEyePos = event.faces[i].rightEyePosition
            local rightEyeMark = display.newCircle(rightEyePos.x, rightEyePos.y, markRadius)
            group:insert(rightEyeMark)
            rightEyeMark:setFillColor(.6,.6,0,0)
            rightEyeMark:setStrokeColor(.6,.6,0,1)
            rightEyeMark.strokeWidth = markStrokeWidth
            table.insert(marks, rightEyeMark)
            
            -- Mouth position
            local mouthPos = event.faces[i].mouthPosition
            local mouthMark = display.newCircle(mouthPos.x, mouthPos.y, markRadius)
            group:insert(mouthMark)
            mouthMark:setFillColor(.6,.6,0,0)
            mouthMark:setStrokeColor(0,.6,.6,1)
            mouthMark.strokeWidth = markStrokeWidth
            table.insert(marks, mouthMark)
            
            local angle = calculateAngle(leftEyePos, rightEyePos)
            boundingBox.rotation = angle-90
            
            -- Apply silly overlays
            local overlay = display.newImage("overlay.png")
            overlay.x, overlay.y = bounds.x, bounds.y
            group:insert(overlay)
            table.insert(overlays, overlay)

            overlay.rotation = angle-90
            
            local factor = bounds.width/(overlay.width-280)
            overlay:scale(factor, factor)
        end
        
        toggleVisibility(overlays, false)
        toggleVisibility(marks, false)
    end

    -- Track image
    local path = system.pathForFile( fileName, baseDir )
    --local accuracy = "low" -- optional: default is "high"
    fd.track(path, accuracy, listener )
end

-- Pick photo event handler
local function onComplete(event)

    if event.target then
        local img = event.target
        local fileName = "photo.png"
        local factor = display.contentWidth/img.width
        img:scale(factor, factor)
        img.x, img.y = display.contentCenterX, display.contentCenterY
        display.save( img, { filename=fileName, baseDir=system.DocumentsDirectory, captureOffscreenArea=false } )
        display.remove(img)
        img=nil

        detectFaces(fileName)
    end
end

-- Button event handler
local function handleButtonEvent(event)

    if event.target.id == "pick" then
        
        -- Clean previous image group
        if group then
            display.remove(group)
            group=nil
        end
        group = display.newGroup()
        group:toBack()
    
        -- Pick a photo
        if media.hasSource( media.PhotoLibrary ) then
           media.selectPhoto( { mediaSource=media.PhotoLibrary, listener=onComplete } )
        else
           native.showAlert( "Notice", "This device does not have a photo library.", { "OK" } )
        end
        
    elseif event.target.id == "track" then
        toggleVisibility(marks)
    elseif event.target.id == "overlay" then
        toggleVisibility(overlays )
    end
end

-- Buttons
local options = {"pick", "track", "overlay"}
for i=1, #options do
    local button = widget.newButton(
    {
        label = options[i],
        fontSize = 40,
        id = options[i],
        onRelease = handleButtonEvent,
        shape = "roundedRect",
        width = 150,
        height = 70,
        cornerRadius = 10,
        fillColor = { default={.4,.7,1,1}, over={.4,.7,1,.8} },
        labelColor = { default={1,1,1,1}, over={1,1,1,1} }
        
    })
    button.x, button.y = 110 , (i*120)-50
end


