local _, Hush = ...
if not Hush then
    return
end

local SOUND_DESCRIPTIONS = {
    READY_CHECK = "Used for Ready Check prompts and Dungeon Finder or Raid Finder ready prompts.",
    PVP_THROUGH_QUEUE = "Used when a Battleground or Arena queue is ready to join.",
    PVP_ENTER_QUEUE = "Used when joining a Battleground or Arena queue.",
    LFG_DENIED = "Used when someone declines a Dungeon Finder or Raid Finder prompt.",
}

local function AttachTooltip(frame, text)
    if not frame or not text or text == "" then
        return
    end

    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(text, 1, 1, 1, true)
        GameTooltip:Show()
    end)

    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function CreateEnableCheckbox(panel, label, key)
    local checkbox = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    checkbox:SetPoint("LEFT", label, "RIGHT", -8, 0)
    checkbox:SetChecked(Hush.IsEnabled(key))
    checkbox:SetScript("OnClick", function(self)
        Hush.EnsureEnabledTable()
        HushDB.enabled[key] = self:GetChecked() and true or false
        Hush.UpdateMuteForKey(key)
    end)
    return checkbox
end

local function CreateVolumeDropdown(panel, anchor, key)
    local dropdown = CreateFrame("Frame", nil, panel, "UIDropDownMenuTemplate")
    dropdown:SetPoint("LEFT", anchor, "RIGHT", -6, -2)
    UIDropDownMenu_SetWidth(dropdown, 70)

    UIDropDownMenu_Initialize(dropdown, function(self, level)
        for _, volume in ipairs(Hush.VOLUMES) do
            local v = volume
            local info = UIDropDownMenu_CreateInfo()
            info.text = tostring(v) .. "%"
            info.value = v
            info.checked = (v == Hush.GetVolume(key))
            info.func = function()
                Hush.EnsureVolumeTable()
                HushDB.volume[key] = v
                UIDropDownMenu_SetSelectedValue(dropdown, v)
                UIDropDownMenu_SetText(dropdown, tostring(v) .. "%")
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    UIDropDownMenu_SetSelectedValue(dropdown, Hush.GetVolume(key))
    UIDropDownMenu_SetText(dropdown, tostring(Hush.GetVolume(key)) .. "%")
    return dropdown
end

local function CreateChannelDropdown(panel, anchor, key)
    local dropdown = CreateFrame("Frame", nil, panel, "UIDropDownMenuTemplate")
    dropdown:SetPoint("LEFT", anchor, "RIGHT", -6, -2)
    UIDropDownMenu_SetWidth(dropdown, 90)

    UIDropDownMenu_Initialize(dropdown, function(self, level)
        for _, channel in ipairs(Hush.CHANNELS) do
            local c = channel
            local info = UIDropDownMenu_CreateInfo()
            info.text = c
            info.value = c
            info.checked = (c == Hush.GetChannel(key))
            info.func = function()
                Hush.EnsureChannelTable()
                HushDB.channel[key] = c
                UIDropDownMenu_SetSelectedValue(dropdown, c)
                UIDropDownMenu_SetText(dropdown, c)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    UIDropDownMenu_SetSelectedValue(dropdown, Hush.GetChannel(key))
    UIDropDownMenu_SetText(dropdown, Hush.GetChannel(key))
    return dropdown
end

local function CreateTestButton(panel, dropdown, key)
    local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    button:SetSize(60, 22)
    button:SetPoint("LEFT", dropdown, "RIGHT", -10, 3)
    button:SetText("Test")
    button:SetScript("OnClick", function()
        local sound = Hush.BuildSoundPath(key)
        if sound then
            PlaySoundFile(sound, Hush.GetChannel(key))
        end
    end)
end

local function CreateRow(panel, labelText, key, yOffset)
    local label = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", 16, yOffset)
    label:SetText(labelText)
    label:SetWidth(160)
    label:SetJustifyH("LEFT")
    AttachTooltip(label, SOUND_DESCRIPTIONS[key])

    local checkbox = CreateEnableCheckbox(panel, label, key)
    local volumeDropdown = CreateVolumeDropdown(panel, checkbox, key)
    local channelDropdown = CreateChannelDropdown(panel, volumeDropdown, key)
    CreateTestButton(panel, channelDropdown, key)

    local description = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    description:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2)
    description:SetWidth(520)
    description:SetJustifyH("LEFT")
    description:SetText(SOUND_DESCRIPTIONS[key] or "")
end

local options = CreateFrame("Frame", "HushOptions", InterfaceOptionsFramePanelContainer)
options.name = "Hush"

local title = options:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Hush")

local subtitle = options:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
subtitle:SetText("Choose the replacement volume and channel for each sound.")

CreateRow(options, "Ready Check", "READY_CHECK", -66)
CreateRow(options, "PvP Through Queue", "PVP_THROUGH_QUEUE", -130)
CreateRow(options, "PvP Enter Queue", "PVP_ENTER_QUEUE", -194)
CreateRow(options, "LFG Denied", "LFG_DENIED", -258)

if Settings and Settings.RegisterCanvasLayoutCategory then
    local category = Settings.RegisterCanvasLayoutCategory(options, options.name)
    Settings.RegisterAddOnCategory(category)
else
    InterfaceOptions_AddCategory(options)
end
