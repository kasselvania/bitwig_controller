-- track object
-- contains grid draw functions

local Track = {}

function Track:new()
    local newObj = {
        track_arm = false,
        arm_received = false,
        arm_update = true,
        selected = false,
        selected_received = false,
        selected_update = true,
        solo = false,
        solo_received = false,
        solo_update = true,
        other_solo = false,
        other_solo_received = false,
        other_solo_update = true,
        mute = false,
        mute_received = false,
        mute_update = true,
        folder = false,
        folder_received = false,
        folder_update = true,
        clips = {},
        clips_received = false,
        clips_update = false,
        playing_clip = {},
        playing_clip_recieved = false,
        playing_clip_update = true,
        alt_launch = false,
        firstBoot = true,
    }

    for i = 1, 16 do
        newObj.clips[i] = {
            state = false -- Initialize each clip as empty, haveContent set to false, nil is empty, 1 is exists, 2 is playing
        }
        newObj.playing_clip[i] = {
            state = false
        }
    end

    setmetatable(newObj, self)
    self.__index = self
    return newObj
end

function Track:firstBootDraw()
    if self.firstBoot and self.arm_received and self.clips_received and self.selected_received and self.mute_received and self.solo_received and self.other_solo_received then
        -- print("I have run the firstbootDraw")
        self:setTrackState()
        self.firstBoot = false
    end
end

-- Initialize 16 track instances and return them in a table
function Track:initTracks()
    local tracks = {}
    for i = 1, 16 do
        local trackInstance = self:new(tracks)
        trackInstance.trackNumber = i
        tracks[i] = trackInstance
    end
    gridDirty = true
    return tracks
end

function Track:setClipState(clipIndex, value)
    if clipIndex >= 1 and clipIndex <=16 then
        self.clips[clipIndex].state = value
    end
    self.clips_received = true
    if self.firstBoot == true then
        self:firstBootDraw()
    else self:setTrackState()
    end
end

function Track:clipsToDraw()
    for i = 1,16 do
            local clipLedValue = self.clips[i].state == 1 and 10 or 0
        clipDrawArray[i][self.trackNumber] = clipLedValue
        end
    gridDirty = true
    self.clips_update = true
    self.clips_received = false
end

function Track:setTrackState ()
        self:clipsToDraw()
    -- if self.clips_update == true and self.folder_update == false then
    if self.clips_update == true then
            if self.folder == true then
                    self:folderTrackDraw(6)
            end
        if self.track_arm == true and self.arm_update == false then
            local change = "plus"
            self:adaptiveDrawUpdate(3, change)
        end
        if self.mute == true and self.mute_update == false then
            local change = "minus"
            self:adaptiveDrawUpdate(6, change)
        end
        if self.selected == true and self.selected_update == false then
            local change = "all plus"
            self:adaptiveDrawUpdate(3, change)
        end
        if self.solo == false and self.other_solo == true then
            local change = "all minus"
            self:adaptiveDrawUpdate(6, change)
        end
        if transporton == true then
        for i = 1,16 do
        if self.playing_clip[i] == 1 then
            --print("there's a playing clip")
            clipDrawArray[i][self.trackNumber] = "pulse"
        end
    end
    end
    end
    self.solo_update = false
    self.other_solo = false
    self.other_solo_update = false
    self.mute_update = false
    self.clips_update = false
    self.arm_update = false
    self.folder_update = false
    self.selected_update = false
    self.playing_clip_update = false
gridDirty = true
end

function Track:folderTrackDraw(value)
        for i = 1,16 do
                clipDrawArray[i][self.trackNumber] = value
         end
gridDirty = true
end




function Track:adaptiveDrawUpdate(value, calc)
    if calc == "plus" then
        for i = 1,16 do
            if self.clips[i].state == 0 then
                clipDrawArray[i][self.trackNumber] = self:addition(clipDrawArray[i][self.trackNumber], value)
                end
            end
        end
       if calc == "all plus" then
        for i = 1,16 do
            clipDrawArray[i][self.trackNumber] = self:addition(clipDrawArray[i][self.trackNumber], value)
        end
       end
       if calc == "minus" then
        for i = 1,16 do
            if self.clips[i].state == 1 then
                clipDrawArray[i][self.trackNumber] = self:subtraction(clipDrawArray[i][self.trackNumber], value)
            end
        end
       end
       if calc == "all minus" then
        for i = 1,16 do
            clipDrawArray[i][self.trackNumber] = self:subtraction(clipDrawArray[i][self.trackNumber], value)
        end
       end
end


-- -- Method to mark if track is armed
function Track:setTrackArm(value)
    self.arm_received = true
    self.track_arm_update = false
    self.track_arm = value
   if self.firstBoot == true then
    self:firstBootDraw()
   else 
    self:setTrackState()
   end
end

-- -- Method to mark if track is selected
function Track:setSelected(value)
    self.selected_received = true
    self.selected_update = false
    self.select = value
   if self.firstBoot == true then
    self:firstBootDraw()
   else 
    self:setTrackState()
   end
end


-- -- Method to mark if track is muted
function Track:setMute(value)
    self.mute_received = true
    self.mute_update = false
    self.mute = value
   if self.firstBoot == true then
    self:firstBootDraw()
   else 
    self:setTrackState()
   end
end

-- -- Method to mark if track is a folder
function Track:setFolder(value)
    -- print(self.trackNumber, value)
    self.folder_update = false
    self.folder = value
    if self.firstBoot == true then
        self:firstBootDraw()
       else 
        self:setTrackState()
       end
end

-- -- Method to mark if track is solo'd
function Track:setSolo(value)
    self.solo_received = true
    self.solo__update = false
    self.solo = value
    if self.firstBoot == true then
        self:firstBootDraw()
       else 
        self:setTrackState()
       end
end

-- -- Method to mark if other tracks are solo'd
function Track:setOtherSolo(value)
        self.other_solo_received = true
        self.other_solo_update = false
        self.other_solo = value
        if self.firstBoot == true then
            self:firstBootDraw()
           else 
            self:setTrackState()
           end
end

-- -- Method to change the value of if clip is playing
function Track:setPlayingClip(clipplayNumber, value)
    if clipplayNumber >= 1 and clipplayNumber <=16 then
        self.playing_clip[clipplayNumber] = value
    end
    self.playing_clip_recieved = true
    self.playing_clip_update = false
   if self.firstBoot == true then
    self:firstBootDraw()
   else 
    self:setTrackState()
   end
end







-- -- Method to change the value of clip launch
function Track:setAltLaunch(value)
--     self.alt_launch = value
end

-- -- Mathematical Equations for brightness logic
function Track:addition(a,b)
    --print(a,b)
    return math.min(a + b,15)
end

function Track:subtraction(a,b)
    --print(a,b)
    return math.max(a - b,0)
end

return Track
