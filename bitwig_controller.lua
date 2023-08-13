-- BitWig Controller Beta/Early

g = grid.connect()
dest = {"192.168.5.33", 10101}
clipGrid = {}
projectTempo = {}
clipID = {}
trackID = {}
clip = {}
bpm = {}

function init()
  --toggleState = false -- this is for any key that toggles on or off
  trackClip = {}
  oscinfo = {}
  clipState = {} -- this will track the state of if a clip is playing or not This is potentially obsolete.
  scenes = {} -- this holds a table of the available scenes, and assigns them to the appropriate key for launching. It currently does not track the play state
  transporton = false -- This tracks the projects transport state, and will apply a LED state dependant on the incoming OSC messages
  for i = 1,16 do
    clipState[i] = falase -- creates a table for the current state of the clips. This is potentially obsolete and was a test for the first row
  end
  for i = 1,14 do
    scenes[i] = false -- assigns a value to the scenes. This table is aligned to [1,14]
  end
    -- this initalizes the clipGrid variable to be a 2d array of size 16,8 with each value in the array being [0, 0]
  for x = 1,16 do -- for each x-column (16 on a 128-sized grid)...
    clipGrid[x] = {}
    clip [x] = {}
    for y = 1,16 do -- for each y-row (8 on a 128-sized grid)...
      clipGrid[x][y] = false
      clip[x][y] = false
    end
  end
  gridDirty = true -- state that runs a grid.redraw()
  hardware_redraw_clock = clock.run( -- not sure about this clock redraw function. I believe this was provided by DDerks and creates the refresh issues when pressing the keys
    function()
      while true do
        clock.sleep(1/60)
        if gridDirty then
          grid_redraw()
          gridDirty = false
        end
      end
    end
  )
  osc.send(dest, "/refresh")
end

function g.key(x,y,z)
  if x == 1 and y == 16 and z == 1 then -- this function is the play key, currently, the play state does not update dependent on the OSC data. Only the light.
    --toggleState = not toggleState -- this idiom flips a boolean to the opposite state
    toggleState = transporton
    playbutton()
  end
    -- if x == 2 and z == 1 then -- this is the clip state for x2 row. This needs to be then aapplied to the grid from [1,0] to [16,14]
    -- clipState[y] = not clipState[y]
    -- end
    if x == 1 then -- This is the trigger for the scenes. Currently, the grid.redraw() is missing a function to drive a two way LED communication between grid and BitWig OSC
        if z == 1 then
          launch_scene(y)
          scenes[y] = z
          gridDirty = true
          else
            scenes[y] = false
        end
    end
if z == 1 and x > 1 and y <= 14 then
  clipLaunch(x-1,y)
  print(x-1,y)
  gridDirty = true
  else
    end
        
  if x == 16 and y == 16 and z == 1 then --scene scroll increase
    osc.send(dest, "/track/+")
  end
  if x == 14 and y == 16 and z == 1 then -- scene scroll decrease
    osc.send(dest, "/track/-")
  end
  if x == 15 and y == 16 and z == 1 then -- scene scroll increase
    osc.send(dest, "/scene/+")
  end
  if x == 15 and y == 15 and z == 1 then -- scene scroll decrease
    osc.send(dest, "/scene/-")
  end
end

function launch_scene(sceneNumber) -- this is the function that launches scenes. This may need to be updated dependent on how scene scrolling assigns numbers.
      if scenes[sceneNumber] == false then
        osc.send(dest, "/scene/" ..sceneNumber.. "/launch")
    end
end

 function clipLaunch(track, clip)
            osc.send(dest, "/track/" ..track.. "/clip/" ..clip.. "/launch", {1})
            -- print(clip,track)
  end

  

function playbutton()
   if transporton == false 
    then
     osc.send(dest, "/play/1")
    else
     osc.send(dest, "/stop")
    end
end

function osc_in(path, args, from)
local playmsg = string.find(path, "/play") -- this is the function that runs the transport button and updates its state dependant on BitWig's OSC messaging
  if playmsg then
    if args[1] == 1 then
      transporton = true
      elseif args[1] == 0 then
        transporton = false
      end
      gridDirty = true
  end
  
local currentBPM = string.find(path, "/tempo/raw")
  if currentBPM then
    local bpmarg = tonumber(args[1])
    bpm = bpmarg
    end
  
   local pattern = "/track/(%d+)/clip/(%d+)/hasContent"
    -- Extract track and clip numbers from the path using pattern matching
    local track, clip = path:match(pattern)
    
    -- Convert the extracted strings to numbers

    local trackNumber = tonumber(track)
    local clipNumber = tonumber(clip)
    
    -- Check if numbers were extracted successfully
    if trackNumber and clipNumber then
        -- Call your processing function with the extracted numbers
        processOSCMessage(trackNumber, clipNumber, args)
          -- print("Received OSC message for track:", track, "and clip:", clip, "and args:", args)
    else
        -- print("Could not extract track and clip numbers from:", path)
    end
end


-- Function to process the extracted track and clip numbers
function processOSCMessage(track, clip, args)
    -- Perform your processing here
     --print("Received OSC message for track:", track, "and clip:", clip, "and args", args[1])
     track = track + 1
    if clip <= 16 and track <= 16 then
        if args[1] == 1 then
            clipGrid[track][clip] = true
        elseif args[1] == 0 then
            clipGrid[track][clip] = false
        end
    end
    gridDirty = true
end


osc.event = osc_in

function navigationArrow()
  if g:led(14,16,10) then
    else
  end
  if g:led(15,16,10) then
    else
  end
  if g:led(16,16,10) then
    else
  end
  if g:led(15,15,10) then
    else
  end
end
  
      


 function grid_redraw()
  g:all(0)
  navigationArrow() -- arrow keys
   --this idiom makes a compact if/then by checking the boolean state:
  if g:led(1,16,transporton and 15 or 3) then -- if true, use 15. if false, use 3.
    else
      end
  g:refresh()
   for i = 1,14 do
  g:led(1,i,scenes[i] and 15 or 7)
   end
  for x = 2, 16 do
        for y = 1, 14 do
            g:led(x, y, clipGrid[x][y] and 15 or 1)
             -- print(clipGrid[x][y])
        end
  end
  
g:refresh()
end
