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
clipPlay = {}
bpm = {}
altView = {}
tracktype = {}
selectedtrack = {}
armedtracktable = {}
Brightness = 0

function init()
  --toggleState = false -- this is for any key that toggles on or off
  trackClip = {}
  oscinfo = {}
  clipState = {} -- this will track the state of if a clip is playing or not This is potentially obsolete.
  scenes = {} -- this holds a table of the available scenes, and assigns them to the appropriate key for launching. It currently does not track the play state
  transporton = false -- This tracks the projects transport state, and will apply a LED state dependant on the incoming OSC messages
  altView = false -- This starts the script in Session View
  trackarmed = false -- toggle for checking if selected track is armed
  globalRecordArm = false -- toggles global record for project
  
  for i = 1,16 do
      clipState[i] = false -- creates a table for the current state of the clips.
  end
      for i = 1,14 do
         scenes[i] = false -- assigns a value to the scenes. This table is aligned to [1,14]
      end
  
  
    -- this initalizes the clipGrid variable to be a 2d array of size 16,8 with each value in the array being [0, 0]
  for x = 1,16 do -- for each x-column (16 on a 128-sized grid)...
    selectedtrack[x] = {}
      tracktype[x] = {}
      clipGrid[x] = {}
      clipPlay [x] = {}
      armedtracktable[x] = {}
          for y = 1,16 do -- for each y-row (8 on a 128-sized grid)...
              selectedtrack[x][y] = false
              tracktype[x][y] = false
              clipGrid[x][y] = false
              clipPlay[x][y] = false
              armedtracktable[x][y] = false
          end
  end
  
  globalClock = lattice:new() -- lattice for quarter note based patterns
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

  Grid_Redraw_Metro = metro.init() -- grid redraw instructions
  Grid_Redraw_Metro.event = function()
    if gridDirty then
      grid_redraw()
      gridDirty = false
    end
  end
  Grid_Redraw_Metro:start(1/60)
  osc.send(dest, "/refresh") -- flushes all OSC data to script on start.
end

function pulseLed(x, y, scale, direction) -- animation sprocket fun by lattice for identifying playing clips and play button
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

function alternateView(x,y,z) -- alt view button function. Currently only toggles variable
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

  if x == 1 and y == 16 and z == 1 then -- this function is the play key
    toggleState = transporton
    playbutton()
  end

  if x == 4 and y == 16 and z == 1 then -- key to arm and unarm tracks. Also displays state of track.
    if trackarmed == true then
      osc.send(dest, "/track/selected/recarm", {0})
    else osc.send(dest, "/track/selected/recarm", {1})
    end
    gridDirty = true
  end

  if x == 3 and y == 16 and z == 1 then -- key to arm and disarm global record
    if globalRecordArm == true then
      osc.send(dest, "/record")
    else osc.send(dest, "/record")
    end
    gridDirty = true
  end

  
  -- if x == 2 and y == 16 and z == 1 then -- stops all
  --         osc.send(dest,"/clip/stopall")
  --     end
  

  
 alternateView(x,y,z)
 
  if x == 1 then -- This is the trigger for the scenes.
    if y <= 14 then
      if z == 1 then
        -- transporton = true
        --playbutton()
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


  if altView then -- currently, alt arrows bellow are the same.
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
    gridDirty = true
end

 function clipLaunch(track, clip) -- clip launching function
            osc.send(dest, "/track/" ..track.. "/clip/" ..clip.. "/launch", {1})
            -- print(clip,track)
  end

  

function playbutton() -- play button and transporton function
  if transporton == false then
    osc.send(dest, "/play/1")
  else
    osc.send(dest, "/stop")
  end
end


function osc_in(path, args, from)
  local playmsg = string.find(path, "/play") -- this is the function that runs the transport button and updates its state
      if playmsg then
          if args[1] == 1 then
              transporton = true
                  elseif args[1] == 0 then
                      transporton = false
                  end
  end
  local trackselectedArmed = string.find(path, "/track/selected/recarm") -- pulls state of track arm from OSC
      if trackselectedArmed then
        if args[1] == 1 then
          trackarmed = true
          --print("armed")
        elseif args[1] == 0 then
          trackarmed = false
          --print("unarmed")
        end
      end

  local trackRecordState = string.find(path, "/record") -- pulls state of global reecord from OSC
      if trackRecordState then
        if args[1] == 1 then
          globalRecordArm = true
        elseif args[1] == 0 then
          globalRecordArm = false
        end
      end

  
-- local currentBPM = string.find(path, "/tempo/raw")
--     if currentBPM then
--         local bpmarg = tonumber(args[1])
--         bpm = bpmarg
--     end
  
local pattern = "/track/(%d+)/clip/(%d+)/hasContent"    -- Extract track and clip number for existing clips
    local track, clip = path:match(pattern)

local patternplay = "/track/(%d+)/clip/(%d+)/isPlaying"  -- Extract track and clip numbers for playing clips
    local trackplay, clipplay = path:match(patternplay)

local groupid = "/track/(%d+)/type"
    local folder = path:match(groupid)

local trackselected = "/track/(%d+)/selected"
    local selected = path:match(trackselected)

local trackarmed = "/track/(%d+)/recarm"
    local isArmed = path:match(trackarmed)

    
    -- Convert the extracted strings to numbers

    local trackNumber = tonumber(track)
    local clipNumber = tonumber(clip)
    local trackplayNumber = tonumber(trackplay)
    local clipplayNumber = tonumber(clipplay)
    local trackgroup = tonumber(folder)
    local trackselectNumber  = tonumber(selected)
    local armedTrackNumber = tonumber(isArmed)

    if trackgroup then
      --print("Received OSC message for track:", folder, "type ", args[1])
      processOSCMessageGroup(trackgroup, args, groupIndex) -- Process any tracks that are folders
    end

    if trackselectNumber then
       --print("Received OSC message for selected track:", selected, "number ", args[1])
      processOSCMessageSelectedTrack(trackselectNumber, args, trackselect)
    end
    
     if trackNumber and clipNumber then -- pulls track/clip/arguments for existing clips and passes them to function
          -- Call your processing function with the extracted numbers
          --print("Received OSC message for track:", track, "and clip:", clip, "and trackplay", trackplay, "and clipplay", clipplay, "and args:", args [1])
        processOSCMessageClip(trackNumber, clipNumber, args)
     end
     if trackplayNumber and clipplayNumber then -- pulls track/clip/arguments for playing clips, passes them to function
     processOSCMessagePlay(trackplayNumber, clipplayNumber, args)
     end

     if armedTrackNumber then
      processOSCMessageTrackArm(armedTrackNumber, args, armedscene)
      -- print("I see armed track:", armedTrackNumber, args[1])
     end
end

function processOSCMessageSelectedTrack(selectedTrack, args, scene)
  selectedTrack = selectedTrack + 1
    if selectedTrack <= 16 then
      for scene = 1,16 do
        if args[1] == 1 then
        selectedtrack[selectedTrack][scene] = true
      elseif args[1] == 0 then
        selectedtrack[selectedTrack][scene] = false
      end

      end
    end
    gridDirty = true
  end

  function processOSCMessageTrackArm(armedTrackNumber, args, armedscene)
    armedTrackNumber = armedTrackNumber + 1
    if armedTrackNumber <= 16 then
      for armedscene = 1,16 do
        if args[1] == 1 then
          armedtracktable[armedTrackNumber][armedscene] = true
         --print("Received OSC message for track:", armedTrackNumber)
        elseif args[1] == 0 then
          armedtracktable[armedTrackNumber][armedscene] = false
        end
      end
    end
    gridDirty = true
  end

function processOSCMessageGroup(folder, args, scenes) -- tags whether or not a track is a folder/group or not
  --print("got it")
  folder = folder + 1
      if folder <= 16 then
        for scenes = 1,16 do
          if args[1] == "group" then
             tracktype[folder][scenes] = true
              -- print(folder)
          elseif args[1] ~= "group" then
             tracktype[folder][scenes] = false
          end
          -- print(i)
        end
    end
  --print(tracktype)
  gridDirty = true
end

-- Function to process the extracted track and clip numbers
function processOSCMessageClip(track, clip, args) -- applies OSC info for identifying existing clips

     --if track and clip and args [1] then
      --print("Received OSC message for track:", track, "and clip:", clip, "and args:", args [1])
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

function processOSCMessagePlay(trackplay, clipplay, args) -- applies OSC info for identifying playing clips
-- if trackplay and clipplay and args[1] then
  --print("Received OSC message for trackplay", trackplay, "and clipplay", clipplay, "and args:", args [1])
  trackplay = trackplay + 1
  if clipplay <= 16 and trackplay <= 16 then
      if args[1] == 1 then
          clipPlay[trackplay][clipplay] = true
      elseif args[1] == 0 then
          clipPlay[trackplay][clipplay] = false
      end
  end
  gridDirty = true
end



osc.event = osc_in

function drawNavigationArrows() -- current navigation arrows
  g:led(14,16,10)
  g:led(15,16,10)
  g:led(16,16,10)
  g:led(15,15,10)
end

function grid_init() -- initial grid initiation. Should be envoked when swapping between altviews
  g:all(0)
  g:refresh()
end

-- function trackselected()
--   for x = 2,16 do
--     for y = 1,14 do
--       if selectedtrack [x][y] = true then
--         if clipGrid[x][y] = true then
--           g:led(x,y,10)
--         else
--           g:led(x,y,1)
--         end
--       end
--     end
--   end
-- end

function clipdraw ()

    for x = 2,16 do
      for y= 1,14 do 
        if tracktype[x][y] == true then
        g:led(x,y,7)
        end
      end
    end

    if transporton == true then -- clip playing drawing/animation
        for x = 2,16 do
            for y = 1,14 do
                if clipPlay[x][y] == true then
                    g:led(x,y,Brightness)
                end
            end
        end
        gridDirty = true
    end

    for x = 2, 16 do -- clip exist drawing/population
          for y = 1, 14 do
            if selectedtrack[x][y] == true then -- populated clip brightness when track is selected
              if clipGrid[x][y] == true then
                  if clipPlay[x][y] == false then
                     if tracktype[x][y] == false then
                      if armedtracktable[x][y] == false then
                      g:led(x,y,15)
                      end
                  end
              end
            end
          end
            if selectedtrack[x][y] == false then -- populated clips when NOT selected
              if clipGrid[x][y] == true then
                  if clipPlay[x][y] == false then
                     if tracktype[x][y] == false then
                      if armedtracktable[x][y] == false then
                      g:led(x,y,10)
                      end
                  end
              end
            end
          end
                if selectedtrack[x][y] == true then -- unpopulated/unarmed clip when selected
                  if clipGrid[x][y] == false then
                      if clipPlay[x][y] == false then
                         if tracktype[x][y] == false then
                          if armedtracktable[x][y] == false then
                          g:led(x,y,4)
                          end
                        end
                      end
                    end
                  end

                  if selectedtrack[x][y] == true then -- unpopulated/armed clip when selected
                    if clipGrid[x][y] == false then
                        if clipPlay[x][y] == false then
                           if tracktype[x][y] == false then
                            if armedtracktable[x][y] == true then
                            g:led(x,y,6)
                            end
                          end
                        end
                      end
                    end
                  if selectedtrack[x][y] == false then -- unpopulated/unarmed clip brightness when unselected
                    if clipGrid[x][y] == false then
                        if clipPlay[x][y] == false then
                           if tracktype[x][y] == false then
                            if armedtracktable[x][y] == false then
                            g:led(x,y,0)
                            end
                          end
                        end
                      end
                    end

                    if selectedtrack[x][y] == false then -- unpopulated/armed clip brightness when unselected
                      if clipGrid[x][y] == false then
                          if clipPlay[x][y] == false then
                             if tracktype[x][y] == false then
                              if armedtracktable[x][y] == true then
                              g:led(x,y,2)
                              end
                            end
                          end
                        end
                      end
            --print(clipGrid[x][y])
          end
      end
    end

function grid_redraw()
  drawNavigationArrows() -- arrow keys


   if transporton == true then -- play button
      g:led(1,16,Brightness)
        else
            g:led(1,16,3)  -- if true, use 15. if false, use 3.
    end

    if globalRecordArm == true then -- record button
      g:led(3,16,Brightness)
    else
      g:led(3,16,4)
    end


  clipdraw()

    for i = 1,14 do -- scene drawing
        g:led(1,i,scenes[i] and 15 or 15)
    end

    if trackarmed == false then -- track arm key
      g:led(4,16,4)
    else
      g:led(4,16,9)
    end
      
    for x = 11, 12 do -- altView toggle button
        g:led(x,16, altView and 15 or 2)
    end
      g:refresh()
end