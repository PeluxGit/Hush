local ADDON_NAME, Hush = ...
Hush = Hush or {}

local SOUND_PATH = "Interface\\AddOns\\Hush\\Sounds\\"
local DEFAULT_CHANNEL = "Master"
local DEFAULT_VOLUME = 75
local CHANNELS = { "Master", "SFX", "Music", "Ambience", "Dialog" }
local VOLUMES = { 100, 75, 50, 25 }

local SOUNDS = {
    {
        key         = "READY_CHECK",
        label       = "Ready Check",
        description = "Used for Ready Check prompts and Dungeon Finder or Raid Finder ready prompts.",
        soundKits   = { 8960 },
        fileIDs     = { 567478 },
    },
    {
        key         = "PVP_THROUGH_QUEUE",
        label       = "PvP Through Queue",
        description = "Used when a Battleground or Arena queue is ready to join.",
        soundKits   = { 8459 },
        fileIDs     = { 568011 },
    },
    {
        key         = "PVP_ENTER_QUEUE",
        label       = "PvP Enter Queue",
        description = "Used when joining a Battleground or Arena queue.",
        soundKits   = { 8458 },
        fileIDs     = { 568587 },
        uiInfoMsgs  = { 833, 835 },
    },
    {
        key         = "LFG_DENIED",
        label       = "LFG Denied",
        description = "Used when someone declines a Dungeon Finder or Raid Finder prompt.",
        soundKits   = { 17341 },
        fileIDs     = { 567420 },
        uiInfoMsgs  = { 841 },
    },
}

local SOUND_BY_KEY = {}
local SOUNDKIT_MAP = {}
local UI_INFO_SOUND_MAP = {}

for _, sound in ipairs(SOUNDS) do
    SOUND_BY_KEY[sound.key] = sound
    for _, id in ipairs(sound.soundKits) do
        SOUNDKIT_MAP[id] = sound.key
    end
    for _, id in ipairs(sound.uiInfoMsgs or {}) do
        UI_INFO_SOUND_MAP[id] = sound.key
    end
end

-- Missing keys fall back to defaults in the getters, so the tables only need to exist.
local function InitDB()
    HushDB = HushDB or {}
    HushDB.volume = HushDB.volume or {}
    HushDB.enabled = HushDB.enabled or {}
    HushDB.channel = HushDB.channel or {}
end

-- SavedVariables are loaded after this file runs and replace HushDB; InitDB runs again on ADDON_LOADED.
InitDB()

local function GetVolume(key)
    return HushDB.volume[key] or DEFAULT_VOLUME
end

local function GetChannel(key)
    return HushDB.channel[key] or DEFAULT_CHANNEL
end

local function IsEnabled(key)
    return HushDB.enabled[key] ~= false
end

local function BuildSoundPath(key)
    if not SOUND_BY_KEY[key] then
        return nil
    end
    return SOUND_PATH .. key .. "_" .. tostring(GetVolume(key)) .. ".ogg"
end

local function UpdateMuteForKey(key)
    local sound = SOUND_BY_KEY[key]
    if not sound then
        return
    end
    local setMuted = IsEnabled(key) and MuteSoundFile or UnmuteSoundFile
    for _, fileID in ipairs(sound.fileIDs) do
        setMuted(fileID)
    end
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
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("UI_INFO_MESSAGE")

f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON_NAME then
            return
        end
        self:UnregisterEvent("ADDON_LOADED")
        InitDB()
        for _, sound in ipairs(SOUNDS) do
            UpdateMuteForKey(sound.key)
        end
        if Hush.BuildOptions then
            Hush.BuildOptions()
        end
        return
    end

    local key = UI_INFO_SOUND_MAP[arg1]
    if key then
        PlayReplacement(key)
    end
end)

Hush.CHANNELS = CHANNELS
Hush.VOLUMES = VOLUMES
Hush.SOUNDS = SOUNDS
Hush.GetVolume = GetVolume
Hush.GetChannel = GetChannel
Hush.IsEnabled = IsEnabled
Hush.UpdateMuteForKey = UpdateMuteForKey
Hush.BuildSoundPath = BuildSoundPath
Hush.PlayReplacement = PlayReplacement
