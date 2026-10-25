local _, Hush = ...
if not Hush then
    return
end

local ROW_TOP = -92
local ROW_HEIGHT = 66
local HEADER_OFFSET_Y = 10
local SCROLLBAR_WIDTH = 26

local function CreateEnableCheckbox(panel, label, key)
    local checkbox = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    checkbox:SetPoint("LEFT", label, "RIGHT", -8, 0)
    checkbox:SetChecked(Hush.IsEnabled(key))
    checkbox:SetScript("OnClick", function(self)
        HushDB.enabled[key] = self:GetChecked() and true or false
        Hush.UpdateMuteForKey(key)
    end)
    return checkbox
end

local function CreateVolumeDropdown(panel, anchor, key)
    local dropdown = CreateFrame("Frame", nil, panel, "UIDropDownMenuTemplate")
    dropdown:SetPoint("LEFT", anchor, "RIGHT", 2, 0)
    UIDropDownMenu_SetWidth(dropdown, 70)

    UIDropDownMenu_Initialize(dropdown, function(self, level)
        for _, volume in ipairs(Hush.VOLUMES) do
            local v = volume
            local info = UIDropDownMenu_CreateInfo()
            info.text = tostring(v) .. "%"
            info.value = v
            info.checked = (v == Hush.GetVolume(key))
            info.func = function()
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
    dropdown:SetPoint("LEFT", anchor, "RIGHT", -6, 0)
    UIDropDownMenu_SetWidth(dropdown, 90)

    UIDropDownMenu_Initialize(dropdown, function(self, level)
        for _, channel in ipairs(Hush.CHANNELS) do
            local c = channel
            local info = UIDropDownMenu_CreateInfo()
            info.text = c
            info.value = c
            info.checked = (c == Hush.GetChannel(key))
            info.func = function()
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
    button:SetPoint("LEFT", dropdown, "RIGHT", -10, 0)
    button:SetText("Test")
    button:SetScript("OnClick", function()
        local sound = Hush.BuildSoundPath(key)
        if sound then
            PlaySoundFile(sound, Hush.GetChannel(key))
        end
    end)
    return button
end

local function CreateRow(panel, sound, yOffset, addSeparator)
    local key = sound.key

    local label = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", 16, yOffset)
    label:SetText(sound.label)
    label:SetWidth(160)
    label:SetJustifyH("LEFT")

    local checkbox = CreateEnableCheckbox(panel, label, key)
    local volumeDropdown = CreateVolumeDropdown(panel, checkbox, key)
    local channelDropdown = CreateChannelDropdown(panel, volumeDropdown, key)
    local testButton = CreateTestButton(panel, channelDropdown, key)

    local description = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    description:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -14)
    description:SetWidth(520)
    description:SetJustifyH("LEFT")
    description:SetText(sound.description or "")

    if addSeparator then
        local separator = panel:CreateTexture(nil, "BORDER")
        separator:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -34)
        separator:SetPoint("RIGHT", panel, "RIGHT", -16, 0)
        separator:SetHeight(1)
        separator:SetColorTexture(1, 1, 1, 0.18)
    end

    return checkbox, volumeDropdown, channelDropdown, testButton
end

-- Scrollable area filling the panel; the scroll bar only shows when the content overflows.
local function CreateScrollContent(panel)
    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 0, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", -SCROLLBAR_WIDTH, 4)
    scrollFrame.scrollBarHideable = true

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(1, 1)
    scrollFrame:SetScrollChild(content)

    scrollFrame:HookScript("OnSizeChanged", function(self, width)
        content:SetWidth(width)
    end)
    scrollFrame:HookScript("OnShow", function(self)
        ScrollFrame_OnScrollRangeChanged(self)
    end)

    return content
end

-- Called by Core.lua on ADDON_LOADED, once HushDB holds the saved settings.
function Hush.BuildOptions()
    local options = CreateFrame("Frame", "HushOptions", InterfaceOptionsFramePanelContainer)
    options.name = "Hush"

    local content = CreateScrollContent(options)
    content:SetHeight(-ROW_TOP + #Hush.SOUNDS * ROW_HEIGHT)

    local title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Hush")

    local subtitle = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    subtitle:SetText("Choose the replacement volume and channel for each sound.")

    local firstCheckbox, firstVolumeDropdown, firstChannelDropdown
    for i, sound in ipairs(Hush.SOUNDS) do
        local yOffset = ROW_TOP - (i - 1) * ROW_HEIGHT
        local checkbox, volumeDropdown, channelDropdown = CreateRow(content, sound, yOffset, i < #Hush.SOUNDS)
        if i == 1 then
            firstCheckbox, firstVolumeDropdown, firstChannelDropdown = checkbox, volumeDropdown, channelDropdown
        end
    end

    local headerEnable = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    headerEnable:SetPoint("BOTTOM", firstCheckbox, "TOP", 0, HEADER_OFFSET_Y)
    headerEnable:SetText("Enable")

    local headerVolume = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    headerVolume:SetPoint("BOTTOM", firstVolumeDropdown, "TOP", 0, HEADER_OFFSET_Y)
    headerVolume:SetText("Volume")

    local headerChannel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    headerChannel:SetPoint("BOTTOM", firstChannelDropdown, "TOP", 0, HEADER_OFFSET_Y)
    headerChannel:SetText("Channel")

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(options, options.name)
        Settings.RegisterAddOnCategory(category)
    else
        InterfaceOptions_AddCategory(options)
    end
end
