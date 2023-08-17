-- BitWig Controller Beta/Early
local util = require "util"
local lattice = require "lattice"

function rerun()
  norns.script.load(norns.state.script)
end

g = grid.connect()
dest = {"192.168.5.33", 10101}
clipGrid = {}
projectTempo = {}
clipID = {}
trackID = {}
clip = {}
bpm = {}
altView = {}
Brightness = 0

function init()
  --toggleState = false -- this is for any key that toggles on or off
  trackClip = {}
  oscinfo = {}
  clipState = {} -- this will track the state of if a clip is playing or not This is potentially obsolete.
  scenes = {} -- this holds a table of the available scenes, and assigns them to the appropriate key for launching. It currently does not track the play state
  transporton = false -- This tracks the projects transport state, and will apply a LED state dependant on the incoming OSC messages
  altView = false -- This starts the script in Session View
  
  for i = 1,16 do
      clipState[i] = false -- creates a table for the current state of the clips.
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
  
  globalClock = lattice:new()
  globalClock:stop()
  playAnimation = globalClock:new_sprocket()
  playAnimation:set_division(1/64)
  playAnimation:set_action(function ()
    pulseLed(1, 16, globalClock.ppqn / 2, true)
  end)
  playAnimation:stop()
  globalClock:start()

  gridDirty = true -- state that runs a grid.redraw()

  playAnimation:start()
  
  
  -- hardware_redraw_clock = clock.run( -- not sure about this clock redraw function. I believe this was provided by DDerks and creates the refresh issues when pressing the keys
  --   function()
  --     while true do
  --       clock.sleep(1/60)
  --       if gridDirty then
  --         grid_redraw()
  --         gridDirty = false
  --       end
  --     end 
  --   end
  -- )

  Grid_Redraw_Metro = metro.init()
  Grid_Redraw_Metro.event = function()
    if gridDirty then
      grid_redraw()
      gridDirty = false
    end
  end
  Grid_Redraw_Metro:start(1/60)

  



  osc.send(dest, "/refresh")
end

function pulseLed(x, y, scale, direction)
  local phase = globalClock.transport % scale
  startValue = 0
  endValue = 16

  if direction then
    startValue = 16
    endValue = 0
  end

  ledBrightness = util.round(util.linlin(0, scale, startValue, endValue, phase), 1)

  Brightness = ledBrightness
  --print(Brightness)
  gridDirty = true
end

function alternateView(x,y,z)
  if x == 11 or x == 12 and y == 16 then
      if z ==1 then
        print(x,y)
        altView = not altView
          else
      end
  end
  gridDirty = true
end

function g.key(x,y,z)
  if x == 1 and y == 16 and z == 1 then -- this function is the play key, currently, the play state does not update dependent on the OSC data. Only the light.
    --toggleState = not toggleState -- this idiom flips a boolean to the opposite state
    toggleState = transporton
    playbutton()
  end
  
 alternateView(x,y,z)
 
  if x == 1 then -- This is the trigger for the scenes. grid.redraw() is missing a function to drive a two way LED communication
    if y <= 14 then
      if z == 1 then
        transporton = true
        playbutton()
          launch_scene(y)
          scenes[y] = z
          gridDirty = true
              else
                scenes[y] = false
      end
    end
  end
  
  
  if z == 1 and x > 1 and y <= 14 then -- clip launch, may need alternate view factored
      clipLaunch(x-1,y)
      print(x-1,y)
      gridDirty = true
        else
  end


  if altView then
    processArrowKeysalt(x, y, z)
  else
    processArrowKeys(x, y, z)
  end
end

function processArrowKeysalt(x, y, z)
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

function processArrowKeys(x, y, z)
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
  if transporton == false then
    -- playAnimation:start()
    osc.send(dest, "/play/1")
  else
    -- playAnimation:stop()
    osc.send(dest, "/stop")
  end
end


function osc_in(path, args, from)
  local playmsg = string.find(path, "/play") -- this is the function that runs the transport button and updates its state
      if playmsg then
          if args[1] == 1 then
              transporton = true
             -- playAnimation:start()
              
                  elseif args[1] == 0 then
                      transporton = false
                      -- playAnimation:stop()
                  end
  end
  
-- local currentBPM = string.find(path, "/tempo/raw")
--     if currentBPM then
--         local bpmarg = tonumber(args[1])
--         bpm = bpmarg
--     end
  
local pattern = "/track/(%d+)/clip/(%d+)/hasContent"    -- Extract track and clip numbers from the path using pattern matching
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
    -- g:refresh()
end


osc.event = osc_in

function drawNavigationArrows()
  g:led(14,16,10)
  g:led(15,16,10)
  g:led(16,16,10)
  g:led(15,15,10)
end

function grid_init()
  g:all(0)
  g:refresh()
end

function grid_redraw()
  drawNavigationArrows() -- arrow keys
   --this idiom makes a compact if/then by checking the boolean state:
   if transporton == true then
    g:led(1,16,Brightness)
   else
    g:led(1,16,3)  -- if true, use 15. if false, use 3.
     end
  for i = 1,14 do
  if g:led(1,i,scenes[i] and 15 or 7) then
  end
  end
 for x = 2, 16 do
       for y = 1, 14 do
          if g:led(x, y, clipGrid[x][y] and 15 or 1) then
            else
            end
            -- print(clipGrid[x][y])
       end
 end
 for x = 11, 12 do
   if g:led(x,16, altView and 15 or 2) then
   end
 end
 g:refresh()
end
