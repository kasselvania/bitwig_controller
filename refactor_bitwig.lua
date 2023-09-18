-- test of grid controller

-- BitWig Controller Beta/Early
local util = require "util"
local lattice = require "lattice"

local Track = include "lib/Track"
local tracks = Track:initTracks()


g = grid.connect()

dest = {"192.168.5.33", 10101}

clipDrawArray = {}

playPulseValue = 0

transporton = false

function init()

   solo_tracks = {}
   for x = 1,16 do
    solo_tracks[x] = {}
   end


  grid_connected = g.device~= nil and true or false -- ternary operator, eg. http://lua-users.org/wiki/TernaryOperator
  columns = grid_connected and g.device.cols or 16 -- keep track of device columns
  rows = grid_connected and g.device.rows or 16

  print(columns, rows)

    transporton = false
    arrangementView = true

    globalRecordArm = false

    mute_screen = false
    mute_counter = {}
    mute_held = false
    muted_track = {}

    solo_screen = false
    solo_counter = {}
    solo_held = false
    solod_track = {}

    for x = 1,16 do
      solod_track[x] = false
    end

    altLaunch_screen = false
    altLaunch_counter = {}
    altLaunch_held = false

for x = 1,16 do
  clipDrawArray[x] = {}
    for y = 1,16 do
      clipDrawArray[x][y] = 0
    end
  end

    globalClock = lattice:new() -- lattice for quarter note based patterns
    globalClock:stop()
    playAnimation = globalClock:new_sprocket()
    playAnimation:set_division(1/64)
    playAnimation:set_action(function ()
      pulseLed(1, 16, globalClock.ppqn, true)
    end)
    playAnimation:stop()
    globalClock:start()
  
    gridDirty = true -- state that runs a grid.redraw()

    
  
  
    Grid_Redraw_Metro = metro.init() -- grid redraw instructions
    Grid_Redraw_Metro.event = function()
      if gridDirty then
        grid_redraw()
        gridDirty = false
      end
    end
    Grid_Redraw_Metro:start(1/60)

    osc.send(dest, "/stop", {0})

    osc.send(dest, "/refresh",{0})

    gridDirty = true

    transporton = false
  end

  function grid.remove(oldGrid)
    print(g.name.. "says goodbye")
    grid_connected = false
    gridDirty = true
  end

  function grid.add(newGrid)
    g = grid.connect(newGrid.port)
    columns = newGrid.cols
    rows = newGrid.rows
    print("New grid: " .. newGrid.name .. " plugged in.")
    print("Columns: " .. nedwGri.cols .. " Rows: " .. newGrid.rows)
    gridDirty = true
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

  playPulseValue = ledBrightness
  gridDirty = true
end


function launch_scene(sceneNumber) -- this is the function that launches scenes. This may need to be updated dependent on how scene scrolling assigns numbers.
  -- if scenes[sceneNumber] == false then
    osc.send(dest, "/scene/" ..sceneNumber.. "/launch",{})
-- end
gridDirty = true
end


function clipLaunch(clip, track) -- clip launching function
print("I'm sending clip info:")
osc.send(dest, "/track/" ..track.. "/clip/" ..clip.. "/launch", {1})
-- print(clip,track)
end

function altClipLaunch(clip, track) -- clip launching function
osc.send(dest, "/track/" ..track.. "/clip/" ..clip.. "/launchAlt", {1})
-- print(clip,track)
end

function altClipRelease(clip, track) -- clip launching function
osc.send(dest, "/track/" ..track.. "/clip/" ..clip.. "/launchAlt", {0})
-- print(clip,track)
end

  function osc_in(path, args, from)

    local playmsg = string.find(path, "/play")
    if playmsg then
        if args[1] == 1 then
            transporton = true
            playAnimation:start()
            gridDirty = true
                elseif args[1] == 0 then
                    transporton = false
                    playAnimation:stop()
                    gridDirty = true
                end
              end
              girdDirty = true

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
     local currentView  = string.find(path, "/layout")
    --print("received layout message")
             if currentView then
            if args[1] == "arrange" then
                      print("arrangement mode")
                      arrangementView = true
            end
            if args[1] == "mix" then
              print("mix mode")
              arrangementView = false
            end
            gridDirty = true
         end


local trackRecordState = string.find(path, "/record") -- pulls state of global reecord from OSC
if trackRecordState then
  if args[1] == 1 then
    globalRecordArm = true
  elseif args[1] == 0 then
    globalRecordArm = false
  end
end

      collectClipData(path, args)
      processTrackOSCMessage(path, args)
    end

  function collectClipData(path, args)
    local track, clip = path:match("/track/(%d+)/clip/(%d+)/hasContent")
    local trackNumber = tonumber(track)
    local clipNumber = tonumber(clip)

    if trackNumber and clipNumber then
      processClipStates(trackNumber, clipNumber, args)
  end
end

function processClipStates(trackNumber, clipNumber, args)
  if trackNumber <= 16 and clipNumber <= 16 then
    local clipState = args[1] == 1 and 1 or 0
    tracks[trackNumber]:setClipState(clipNumber, args[1])
end
    gridDirty = true
end
  
  
  function processTrackOSCMessage(path, args)

    local trackplay, clipplay = path:match("/track/(%d+)/clip/(%d+)/isPlaying")
    local queuedPattern = path:match("/track/(%d+)/clip/(%d+)/isPlayingQueued")
    local folder = path:match("/track/(%d+)/type")
    local selected = path:match("/track/(%d+)/selected")
    local isArmed = path:match("/track/(%d+)/recarm")
    local muted = path:match("/track/(%d+)/mute")
    local solod = path:match("/track/(%d+)/solo")


    local trackgroup = tonumber(folder)
    local trackselectNumber = tonumber(selected)
    local armedTrackNumber = tonumber(isArmed)
    local trackplayNumber = tonumber(trackplay)
    local clipplayNumber = tonumber(clipplay)
    local mutedTrack = tonumber(muted)
    local solodTrack = tonumber(solod)

    

    if trackgroup then
      local convertedValue = args[1] == "group" and 1 or 0
        processTrackStates(trackgroup, {convertedValue}, "folder")
    end

    if trackselectNumber then
        processTrackStates(trackselectNumber, args, "selected")
    end 

    if armedTrackNumber then
        processTrackStates(armedTrackNumber, args, "track_arm")
    end

    if mutedTrack then
        processTrackStates(mutedTrack, args, "mute")
    end

    if solodTrack then
        processTrackStates(solodTrack, args, "solo")
        updateGlobalSoloState(solodTrack, args)
        updateOtherSolo ()
    end

    if trackplayNumber and clipplayNumber then
      if queuedPattern then
      else processPlayStates(trackplayNumber, clipplayNumber, args)
      end
    end
  end

  osc.event = osc_in

local globalSoloState = false



-- Function to update the global solo state based on any soloed track
function updateGlobalSoloState(trackplayNumber, args)
globalSoloState = false
  if trackplayNumber <= 16 and args[1] <=1 then
  local value = args[1]
    solo_tracks[trackplayNumber] = value
  end
  for i = 1,16 do
    if solo_tracks[i] == 1 then
      globalSoloState = true
      return
  end
end
if not globalSoloState then
  globalSoloState = false
end
end

function updateOtherSolo ()
  for i = 1, 16 do
    tracks[i]:setOtherSolo(globalSoloState)
  end
end

local statusFunctionNames = {
  track_arm = "setTrackArm",
  selected = "setSelected",
  solo = "setSolo",
  mute = "setMute",
  folder = "setFolder",
  alt_launch = "setAltLaunch",
  other_solo = "setOtherSolo"

}


function processTrackStates(trackNumber, args, stateKey)
  if trackNumber <= 16 and args[1] ~= nil then
    local track = tracks[trackNumber]
    local value = args[1] ~= 0
    track[stateKey] = value
    local methodName = statusFunctionNames[stateKey] -- Get the methodName from the predefined table
    if methodName and track[methodName] then
        track[methodName](track, value)
    end
end
gridDirty = true
end

function processPlayStates(trackplayNumber, clipplayNumber, args)
  if trackplayNumber <= 16 and clipplayNumber <= 16 then
    local clipState = args[1] == 1 and 1 or 0
    --print(clipState)
      tracks[trackplayNumber]:setPlayingClip(clipplayNumber, clipState)
  end
  gridDirty = true
end

function alternateView(x,y,z) -- alt view button function. Currently only toggles variable
  if x == 12 and y == rows or x == 13 and y == rows then
    -- if x == 12 and y == 16 or x == 13 and y == 16 then
    if z == 1 then
        print(x,y)
        arrangementView = not arrangementView
        if arrangementView == true then
          osc.send(dest, "/layout", {"arrange"})
        elseif arrangementView == false then
          osc.send(dest, "/layout", {"mix"})
        end
        end
      end
    -- end

    gridDirty = true
end


-- Mute State Logic

muteTapped = false


function mute_hold(x,y,z)
  -- if x == 6 and y == 16 and z == 1 then
  mute_screen = true
  clock.sleep(0.75)
      mute_held = true
      --print("mute was held")
         mute_setup()
        clock.cancel(mute_counter)
        mute_counter = 0
        print("mute: I am held, in mute screen until you let go!")
    end
  -- end


function mute_tap()
  -- if x == 6 and y == 16 then
  --print("I was tapped")
    mute_held = false
      mute_counter = 0
           mute_setup()
 end
-- end

function mute_setup()
  if mute_held == false then
  mute_screen = true 
  muteTapped = true
  print("mute: I was tapped, I'm locked in mute screen")
  end
  gridDirty = true
  end

-- Solo State Logic

soloTapped = false

  function solo_hold()
    solo_screen = true
    clock.sleep(0.75)
        solo_held = true
        --print("mute was held")
           solo_setup()
          clock.cancel(solo_counter)
          solo_counter = 0
          print("solo: I am held, in solo screen until you let go!")
      end
  
  function solo_tap()
    -- if x == 8 and y == 16 then
    --print("I was tapped")
      solo_held = false
        solo_counter = 0
             solo_setup()
   end
  -- end
  
  function solo_setup()
    if solo_held == false then
    solo_screen = true 
    soloTapped = true
    print("solo: I was tapped, I'm locked in solo screen")
    end
    gridDirty = true
    end

-- AltLaunch State Logic

altLaunchTapped = false

  function altLaunch_hold()
    altLaunch_screen = true
    clock.sleep(0.75)
        altLaunch_held = true
        --print("mute was held")
           altLaunch_setup()
          clock.cancel(altLaunch_counter)
          altLaunch_counter = 0
          print("altLaunch: I am held, in solo screen until you let go!")
      end
  
  function altLaunch_tap()
    -- if x == 8 and y == 16 then
    --print("I was tapped")
      altLaunch_held = false
        altLaunch_counter = 0
             altLaunch_setup()
   end
  -- end
  
  function altLaunch_setup()
    if altLaunch_held == false then
    altLaunch_screen = true 
    altLaunchTapped = true
    print("altLaunch: I was tapped, I'm locked in solo screen")
    end
    gridDirty = true
    end


  
function g.key(x,y,z)

  -- Mute Key Logic

  if x == 6 and y == rows and z == 1 and mute_screen == false and solo_screen == false then -- if a grid key is pressed...
    mute_counter = clock.run(mute_hold) -- start the long press counter for that coordinate!
    elseif x==6 and y == 16 and z == 0 and solo_screen == false then -- otherwise, if a grid key is released...
      if mute_counter ~=0 then -- and the long press is still waiting...
        clock.cancel(mute_counter) -- then cancel the long press clock,
        if mute_held == true then
      else
      mute_tap() -- and execute a short press instead.
      -- end
     end
  end
  gridDirty = true
end

if x == 6 and y == rows and z == 1 and mute_screen == true and muteTapped == true then
  mute_screen = false
  muteTapped = false
  print("I've left mute screen")
end

if x == 6 and y == rows and z == 0 and mute_held == true and mute_screen == true then
  mute_screen = false
  print("I was held, and now I'm not")
  mute_held = false
end

-- -- solo key logic

if x == 8 and y == rows and z == 1 and solo_screen == false and mute_screen == false then -- if a grid key is pressed...
  solo_counter = clock.run(solo_hold) -- start the long press counter for that coordinate!
  elseif x==8 and y == rows and z == 0 and mute_screen == false then -- otherwise, if a grid key is released...
    if solo_counter ~=0 then -- and the long press is still waiting...
      clock.cancel(solo_counter) -- then cancel the long press clock,
      if solo_held == true then
    else
    solo_tap() -- and execute a short press instead.
    -- end
   end
end
gridDirty = true
end

if x == 8 and y == rows and z == 1 and solo_screen == true and soloTapped == true then
solo_screen = false
soloTapped = false
print("I've left solo screen")
end

if x == 8 and y == rows and z == 0 and solo_held == true and solo_screen == true then
solo_screen = false
print("I was held, and now I'm not")
solo_held = false
end

-- altLaunch clip logic

if x == 10 and y == rows and z == 1 and altLaunch_screen == false and mute_screen == false and solo_screen == false then -- if a grid key is pressed...
  altLaunch_counter = clock.run(altLaunch_hold) -- start the long press counter for that coordinate!
  elseif x==10 and y == rows and z == 0 and mute_screen == false and solo_screen == false then -- otherwise, if a grid key is released...
    if altLaunch_counter ~=0 then -- and the long press is still waiting...
      clock.cancel(altLaunch_counter) -- then cancel the long press clock,
      if altLaunch_held == true then
    else
    altLaunch_tap() -- and execute a short press instead.
    -- end
   end
end
gridDirty = true
end

if x == 10 and y == rows and z == 1 and altLaunch_screen == true and altLaunchTapped == true then
altLaunch_screen = false
altLaunchTapped = false
print("I've left altLaunch screen")
end

if x == 10 and y == rows and z == 0 and altLaunch_held == true and altLaunch_screen == true then
altLaunch_screen = false
print("I was held, and now I'm not")
altLaunch_held = false
end


  if x == 1 and y == rows and z == 1 then -- this function is the play key
    playbutton()
    gridDirty = true
  end

  if x == 4 and y == rows and z == 1 then -- key to arm and unarm tracks. Also displays state of track.
    if trackarmed == true then
      osc.send(dest, "/track/selected/recarm", {0})
    else osc.send(dest, "/track/selected/recarm", {1})
    end
    gridDirty = true
  end

  if x == 3 and y == rows and z == 1 then -- key to arm and disarm global record
    if globalRecordArm == true then
      osc.send(dest, "/record", {})
    else osc.send(dest, "/record",{})
    end
    gridDirty = true
  end

 alternateView(x,y,z)

 stateScreenKeys(x,y,z)

 processArrowKeys(x,y,z)
 
end

function processArrowKeys(x, y, z)
  if arrangementView == false then
  if x == 16 and y == rows and z == 1 then --scene scroll increase
    osc.send(dest, "/track/+",{})
  end

  if x == 14 and y == rows and z == 1 then -- scene scroll decrease
      osc.send(dest, "/track/-",{})
  end

  if x == 15 and y == rows and z == 1 then -- scene scroll increase
      osc.send(dest, "/scene/+",{})
  end

  if x == 15 and y == rows-1 and z == 1 then -- scene scroll decrease
      osc.send(dest, "/scene/-",{})
  end
else
  if x == 16 and y == rows and z == 1 then --scene scroll increase
    osc.send(dest, "/scene/+",{})
  end

  if x == 14 and y == rows and z == 1 then -- scene scroll decrease
      osc.send(dest, "/scene/-",{})
  end

  if x == 15 and y == rows and z == 1 then -- scene scroll increase
      osc.send(dest, "/track/+",{})
  end

  if x == 15 and y == rows-1 and z == 1 then -- scene scroll decrease
      osc.send(dest, "/track/-",{})
  end


end
end

function playbutton() -- play button and transporton function
  if transporton == false then
    osc.send(dest, "/play/1",{})
    print("I've set play")
  else
    osc.send(dest, "/stop",{})
    print("i've sent stop")
  end
  transporton = not transporton
end

function stateScreenKeys(col,row,z)
  local scene, track
  if row >= 1 and row <= rows-2 then
    if arrangementView == true then
   scene = col
   track = row
    else
       scene = row
       track = col
    end
  if scene <= 16 and track >= 2 and z == 1 and mute_screen == true then -- system for muting tracks
    --print(scene, track)
    osc.send(dest, "/track/"..(track-1).."/mute/-",{})
  if scene>=2 and track <=rows-2 and z==0 and mute_screen == true then
    gridDirty = true
  end
end

  if scene <= 16 and track == 1 and z == 1 and mute_screen == true then -- scene buttons unmute all tracks
   -- print(scene, track)
    for i = 1,16 do
      --print(i)
    osc.send(dest, "/track/"..i.."/mute/0",{0})
    
  end
  gridDirty = true
end
  

if scene <= 16 and track >= 2 and z == 1 and solo_screen == true then -- system for soloing track
  osc.send(dest, "/track/"..(track-1).."/solo/-",{})
if scene>=2 and track <=14 and z==0 and solo_screen == true then
  gridDirty = true
end
end

if scene <= 16 and track == 1 and z == 1 and solo_screen == true then -- scene buttons unmute all tracks
for i = 1,16 do
osc.send(dest, "/track/"..i.."/solo/0",{0})
end
gridDirty = true
end

if track == 1 and scene <= rows and z==1 and mute_screen == false and solo_screen == false then -- This is the trigger for the scenes.
  launch_scene(scene)
  -- scenes[scene] = z
  gridDirty = true
      -- else
      --   scenes[scene] = false
end




if z == 1 and scene <= 16 and track > 1 and mute_screen==false and solo_screen == false and altLaunch_screen == false then -- clip launch, may need alternate view factored
clipLaunch(scene,track-1)
print(scene, track-1)
--print(x-1,y)
gridDirty = true
elseif z == 1 and scene <= 16 and track > 1 and mute_screen==false and solo_screen == false and altLaunch_screen == true then
altClipLaunch(scene,track-1)
elseif z == 0 and scene <= 16 and track > 1 and altLaunch_screen == true then
altClipRelease(scene,track-1)
end

end
end

  

function clipViewScreen()
  local track_numbers
  local scene_numbers
  for scene_numbers = 1,16 do
    for track_numbers = 1,16 do
      local brightness = clipDrawArray[track_numbers][scene_numbers]
    end
  end
    if arrangementView == true then
        for scene_draw = 1, 16 do
            for track_draw = 1, rows-2 do
              local brightness = clipDrawArray[scene_draw][track_draw]
              if brightness == "pulse" then
                g:led(scene_draw,track_draw+1,playPulseValue)
              else g:led(scene_draw, track_draw+1, brightness)
                g:led(scene_draw,1, 15)
              end
            end
        end
      end
      if arrangementView == false then
      for track_draw = 1, 16 do
        for scene_draw = 1, rows-2 do
          local brightness = clipDrawArray[scene_draw][track_draw]
          if brightness == "pulse" then
            g:led(track_draw+1,scene_draw,playPulseValue)
          else g:led(track_draw+1,scene_draw, brightness)
            g:led(1,scene_draw, 15)
          end
        end
    end
end
for i = 1,14 do
  g:led(i,rows-1,0)
end
  gridDirty = true
  end

  function muteLEDToggle()
    if mute_screen == false then
      g:led(6,rows,4)
    else g:led (6,rows,9)
    end
  end
  
  function soloLEDToggle()
    if solo_screen == false then
      g:led(8,rows,4)
    else g:led (8,rows,9)
  end
  end
  
  function altLaunchLEDToggle()
    if altLaunch_screen == false then
      g:led(10,rows,4)
    else g:led (10,rows,9)
  end
  end

  function drawNavigationArrows() -- current navigation arrows
    g:led(14,rows,10)
    g:led(15,rows,10)
    g:led(16,rows,10)
    g:led(15,rows-1,10)
  end

function grid_redraw()

  if transporton == true then -- play button
    g:led(1,rows,playPulseValue)
      else
          g:led(1,rows,3)  -- if true, use 15. if false, use 3.
  end

  if globalRecordArm == true then -- record button
    g:led(3,rows,playPulseValue)
  else
    g:led(3,rows,4)
  end

  if trackarmed == false then -- track arm key
    g:led(4,rows,4)
  else
    g:led(4,rows,9)
  end
    
  for x = 12, 13 do -- altView toggle button
      g:led(x,rows, arrangementView and 15 or 2)
  end

  muteLEDToggle()

  soloLEDToggle()

  altLaunchLEDToggle()

clipViewScreen()

drawNavigationArrows()
for x = 12, 13 do -- altView toggle button
  g:led(x,rows, arrangementView and 15 or 2)
end
    g:refresh()
 end
