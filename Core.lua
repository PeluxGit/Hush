local _, Hush = ...
Hush = Hush or {}

local SOUND_PATH = "Interface\\AddOns\\Hush\\Sounds\\"
local DEFAULT_CHANNEL = "Master"
local DEFAULT_VOLUME = 75
local CHANNELS = { "Master", "SFX", "Music", "Ambience", "Dialog" }
local VOLUMES = { 100, 75, 50, 25 }

local SOUND_LIST = {
    "READY_CHECK",
    "PVP_THROUGH_QUEUE",
    "PVP_ENTER_QUEUE",
    "LFG_DENIED",
}

local SOUND_FILE_BASE = {
    READY_CHECK       = "READY_CHECK",
    PVP_THROUGH_QUEUE = "PVP_THROUGH_QUEUE",
    PVP_ENTER_QUEUE   = "PVP_ENTER_QUEUE",
    LFG_DENIED        = "LFG_DENIED",
}

local SOUNDKIT_MAP = {
    [8960]  = "READY_CHECK",
    [8459]  = "PVP_THROUGH_QUEUE",
    [8458]  = "PVP_ENTER_QUEUE",
    [17341] = "LFG_DENIED",
}

local SOUND_FILE_IDS = {
    READY_CHECK       = 567478,
    PVP_THROUGH_QUEUE = 568011,
    PVP_ENTER_QUEUE   = 568587,
    LFG_DENIED        = 567420,
}

local UI_INFO_SOUND_MAP = {
    [833] = "PVP_ENTER_QUEUE",
    [835] = "PVP_ENTER_QUEUE",
    [841] = "LFG_DENIED",
}

HushDB = HushDB or {}
HushDB.volume = HushDB.volume or {
    READY_CHECK       = DEFAULT_VOLUME,
    PVP_THROUGH_QUEUE = DEFAULT_VOLUME,
    PVP_ENTER_QUEUE   = DEFAULT_VOLUME,
    LFG_DENIED        = DEFAULT_VOLUME,
}
HushDB.enabled = HushDB.enabled or {
    READY_CHECK       = true,
    PVP_THROUGH_QUEUE = true,
    PVP_ENTER_QUEUE   = true,
    LFG_DENIED        = true,
}
HushDB.channel = HushDB.channel or {
    READY_CHECK       = DEFAULT_CHANNEL,
    PVP_THROUGH_QUEUE = DEFAULT_CHANNEL,
    PVP_ENTER_QUEUE   = DEFAULT_CHANNEL,
    LFG_DENIED        = DEFAULT_CHANNEL,
}

local function GetVolume(key)
    if HushDB.volume == nil then
        return DEFAULT_VOLUME
    end
    return HushDB.volume[key] or DEFAULT_VOLUME
end

local function EnsureVolumeTable()
    if HushDB.volume == nil then
        HushDB.volume = {
            READY_CHECK       = DEFAULT_VOLUME,
            PVP_THROUGH_QUEUE = DEFAULT_VOLUME,
            PVP_ENTER_QUEUE   = DEFAULT_VOLUME,
            LFG_DENIED        = DEFAULT_VOLUME,
        }
    end
end

local function GetChannel(key)
    if HushDB.channel == nil then
        return DEFAULT_CHANNEL
    end
    return HushDB.channel[key] or DEFAULT_CHANNEL
end

local function IsEnabled(key)
    if HushDB.enabled == nil then
        return true
    end
    return HushDB.enabled[key] ~= false
end

local function EnsureEnabledTable()
    if HushDB.enabled == nil then
        HushDB.enabled = {
            READY_CHECK       = true,
            PVP_THROUGH_QUEUE = true,
            PVP_ENTER_QUEUE   = true,
            LFG_DENIED        = true,
        }
    end
end

local function EnsureChannelTable()
    if HushDB.channel == nil then
        HushDB.channel = {
            READY_CHECK       = DEFAULT_CHANNEL,
            PVP_THROUGH_QUEUE = DEFAULT_CHANNEL,
            PVP_ENTER_QUEUE   = DEFAULT_CHANNEL,
            LFG_DENIED        = DEFAULT_CHANNEL,
        }
    end
end

local function BuildSoundPath(key)
    local base = SOUND_FILE_BASE[key]
    if not base then
        return nil
    end
    local volume = GetVolume(key)
    return SOUND_PATH .. base .. "_" .. tostring(volume) .. ".ogg"
end

local function UpdateMuteForKey(key)
    local fileID = SOUND_FILE_IDS[key]
    if not fileID then
        return
    end
    if IsEnabled(key) then
        MuteSoundFile(fileID)
    else
        UnmuteSoundFile(fileID)
    end
end

for _, key in ipairs(SOUND_LIST) do
    UpdateMuteForKey(key)
end

local function PlayReplacement(key)
    if not IsEnabled(key) then
        return
    end
    local sound = BuildSoundPath(key)
    if not sound then
        return
    end
    PlaySoundFile(sound, GetChannel(key))
end

hooksecurefunc("PlaySound", function(soundKitID)
    local key = SOUNDKIT_MAP[soundKitID]
    if key then
        PlayReplacement(key)
    end
end)

local f = CreateFrame("Frame")
f:RegisterEvent("UI_INFO_MESSAGE")

f:SetScript("OnEvent", function(_, _, msgID)
    local key = UI_INFO_SOUND_MAP[msgID]
    if key then
        PlayReplacement(key)
    end
end)

Hush.CHANNELS = CHANNELS
Hush.VOLUMES = VOLUMES
Hush.SOUND_LIST = SOUND_LIST
Hush.GetVolume = GetVolume
Hush.EnsureVolumeTable = EnsureVolumeTable
Hush.GetChannel = GetChannel
Hush.EnsureChannelTable = EnsureChannelTable
Hush.IsEnabled = IsEnabled
Hush.EnsureEnabledTable = EnsureEnabledTable
Hush.UpdateMuteForKey = UpdateMuteForKey
Hush.BuildSoundPath = BuildSoundPath
Hush.PlayReplacement = PlayReplacement