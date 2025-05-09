
-- ====================================================================================================
-- =                                   All the locals we need here.                                   =
-- ====================================================================================================

local AddonName = "ManagerPlus"
local PromoteAllInRaid                          -- Used to see if everyone in raid need to be promoted.
local ConvertPartyToRaid                        -- Used to check if we auto convert to raid.
local InviteKeyWord                             -- 
local AutoInviteOutOfGuild                      -- 

local LogInTimeRaidTab = GetTime()              -- Used for a extra check if the dropdown is made.
local SettingsSet                               -- 
local SettingsTwoSet                            -- 

-- ====================================================================================================
-- =                                Create frame(s) and Register event                                =
-- ====================================================================================================

local frame = CreateFrame("Frame");

frame:RegisterEvent("ADDON_LOADED");
frame:RegisterEvent("PARTY_MEMBERS_CHANGED");
frame:RegisterEvent("RAID_ROSTER_UPDATE");
frame:RegisterEvent("CHAT_MSG_WHISPER");
frame:RegisterEvent("GUILD_RANKS_UPDATE");

-- ====================================================================================================
-- =                                          Event handler.                                          =
-- ====================================================================================================

frame:SetScript("OnEvent", function()
    if (event == "ADDON_LOADED") and (arg1 == AddonName) then
        -- Make sure the tables is made.
        if (not SETTINGS) or (not type(SETTINGS) == "table") then
            SETTINGS = {}
        end
        if (not GUILD_INFO) or (not type(GUILD_INFO) == "table") then
            GUILD_INFO = {}
        end
        if (not RAID_PROMOTE) or (not type(RAID_PROMOTE) == "table") then
            RAID_PROMOTE = {}
        end

        -- Update the settings.
        -- Settings()

        --Update the guild roster.
        GuildRoster();

        -- Make the checkbox in the RaidFrame.
        PromoteEveryoneBox()

        -- Unregister "ADDON_LOADED" as we don't need it anymore.
        frame:UnregisterEvent("ADDON_LOADED");
-- ====================================================================================================
    elseif (event == "GUILD_RANKS_UPDATE") then
        DEFAULT_CHAT_FRAME:AddMessage("Run")
        Settings()
-- ====================================================================================================
    elseif (event == "RAID_ROSTER_UPDATE") then
        -- Update the roster to see if we have to change something.
        ManagerRaidRosterChanged()
-- ====================================================================================================
    elseif (event == "PARTY_MEMBERS_CHANGED") then
        -- DEFAULT_CHAT_FRAME:AddMessage("Party changed");
-- ====================================================================================================
    elseif (event == "CHAT_MSG_WHISPER") then
        InviteOnWhisper(arg1, arg2);
    end
end);

-- ====================================================================================================
-- =                                     OnUpdate on every frame.                                     =
-- ====================================================================================================

frame:SetScript("OnUpdate", function()

    -- Make sure that the settings is loaded. (It will take around 10 sec for the GuildRoster() to take effect)
    if (SettingsSet == nil) and ((LogInTimeRaidTab + 12) < GetTime()) then
        Settings()
        SettingsSet = true;
    end

end)

-- ====================================================================================================
-- =                                   Get all the settings we need                                   =
-- ====================================================================================================

function Settings()

    -- Again make sure the tables is made.
    if (not SETTINGS) or (not type(SETTINGS) == "table") then
        SETTINGS = {}
    end

    GuildRoster()                                                       -- Run the GuildRoster() again.
    PromoteAllInRaid = SETTINGS["PromoteAllInRaid"] or false            -- Used to check if the checkbox in the raid frame is checked or not.
    InviteKeyWord = SETTINGS["AutoInviteKeyWord"] or "Inv"              -- 
    ConvertPartyToRaid = SETTINGS["ConvertPartyToRaid"] or false        -- 
    AutoInviteOutOfGuild = SETTINGS["AutoInviteOutOfGuild"] or false    -- 

    MakeTheDropDown()                                                   -- Make the dropdown in raid settings on what rank to promote.

end

-- ====================================================================================================
-- =                                Promote all with chosen guild rank                                =
-- ====================================================================================================

function ManagerRaidRosterChanged()

    -- Make sure the tables are made.
    if (not GUILD_INFO) or (not type(GUILD_INFO) == "table") then
        GUILD_INFO = {}
    end
    if (not RAID_PROMOTE) or (not type(RAID_PROMOTE) == "table") then
        RAID_PROMOTE = {}
    end
    if (not RAID_BAN) or (not type(RAID_BAN) == "table") then
        RAID_BAN = {}
    end

    -- Are we in a raid and are we the leader ?
    if (GetNumRaidMembers() > 0) and (IsRaidLeader()) then
        --Do we promote everyone in the raid ?
        if (PromoteAllInRaid == true) then
            -- Loop through all raid members.
            for i = 1, GetNumRaidMembers() do
                -- Get the info we need about the raid member.
                local playerName, raidRank, subgroup, level, class, fileName, zone, online, isDead, role, isML, combatRole = GetRaidRosterInfo(i) -- raidRank returns 2 if the raid member is the leader of the raid, 1 if the raid member is promoted to assistant, and 0 otherwise.
                -- Did we find someone ?
                if (playerName) then
                    -- Is it a person there is banned from the raids ?
                    if (RAID_BAN[playerName]) then
                        SendChatMessage(playerName .. " has been banned from raiding with us.", "RAID");
                        UninviteByName(playerName);
                    -- Is it a person we can promote ?
                    elseif (raidRank == 0) then
                        PromoteToAssistant(playerName);
                    end
                end
            end
        -- We only promote the people and rank we have chosen.
        else
            -- Loop through all raid members.
            for i = 1, GetNumRaidMembers() do
                -- Get the info we need about the raid member.
                local playerName, raidRank, subgroup, level, class, fileName, zone, online, isDead, role, isML, combatRole = GetRaidRosterInfo(i) -- raidRank returns 2 if the raid member is the leader of the raid, 1 if the raid member is promoted to assistant, and 0 otherwise.
                -- Did we find someone ?
                if (playerName) then
                    -- Is it a person there is banned from the raids ?
                    if (RAID_BAN[playerName]) then
                        SendChatMessage(playerName .. " has been banned from raiding with us.", "RAID");
                        UninviteByName(playerName);
                    -- Is it someone we have chosen to promote by guild rank ? If so, then we promote them, if they are not already promoted.
                    elseif (SETTINGS["PromoteGuildRank"]) and (GUILD_INFO[playerName]) and (GUILD_INFO[playerName]["RankIndex"] <= SETTINGS["PromoteGuildRank"]) and (raidRank == 0) then
                        PromoteToAssistant(playerName);
                    -- Is it a name of a person we would like to promote ?
                    elseif (RAID_PROMOTE[playerName]) and (raidRank == 0) then
                        PromoteToAssistant(playerName);
                    end
                end
            end
        end
    end

end

-- ====================================================================================================
-- =                      Demote everyone in raid when checkbos is set to false.                      =
-- ====================================================================================================

function DemoteEveryoneInRaid()

    -- Are we in a raid ?
    if (GetNumRaidMembers() > 0) then
        -- Are we the raid leader ?
        if (IsRaidLeader()) then
            -- Loop through all raid members.
            for i = 1, GetNumRaidMembers() do
                -- Get the info we need about the raid member.
                local playerName, raidRank, subgroup, level, class, fileName, zone, online, isDead, role, isML, combatRole = GetRaidRosterInfo(i) -- raidRank returns 2 if the raid member is the leader of the raid, 1 if the raid member is promoted to assistant, and 0 otherwise.
                -- Did we find someone ?
                if (playerName) then
                    -- Is it someone there is promoted ?
                    if (raidRank == 1) then
                        -- Demote
                        DemoteAssistant(playerName);
                        -- DEFAULT_CHAT_FRAME:AddMessage("Demoting " .. playerName .. " from raid assistant.");
                    end
                end
            end
        end
    end

end

-- ====================================================================================================
-- =                      Promote everyone in raid when checkbos is set to true.                      =
-- ====================================================================================================

function PromoteEveryoneInRaid()

    -- Are we in a raid ?
    if (GetNumRaidMembers() > 0) then
        -- Are we the raid leader ?
        if (IsRaidLeader()) then
            -- Loop through all raid members.
            for i = 1, GetNumRaidMembers() do
                -- Get the info we need about the raid member.
                local playerName, raidRank, subgroup, level, class, fileName, zone, online, isDead, role, isML, combatRole = GetRaidRosterInfo(i) -- raidRank returns 2 if the raid member is the leader of the raid, 1 if the raid member is promoted to assistant, and 0 otherwise.
                -- Did we find someone ?
                if (playerName) then
                    -- Is it someone there is promoted ?
                    if (raidRank < 1) then
                        -- Promote
                        PromoteToAssistant(playerName);
                        -- DEFAULT_CHAT_FRAME:AddMessage("Promoting " .. playerName .. " to raid assistant.");
                    end
                end
            end
        end
    end

end

-- ====================================================================================================
-- =                                Auto invite to group when whisper.                                =
-- ====================================================================================================

function InviteOnWhisper(message, sender)

    -- Make the message case-insensitive
    local message = string.lower(message)

    -- Check that we have a message and it's the key word.
    if (message) and (InviteKeyWord) and (message == string.lower(InviteKeyWord)) then

        -- Are we in a group ?
        if (GetNumPartyMembers() > 0) then
            -- Stop if we are not the leader ?
            if (not IsPartyLeader()) and (not IsRaidLeader()) and (not IsRaidOfficer()) then
                return;
            end
            -- Is it someone from guild and do we want to invite from out side the guild ?
            if (not GUILD_INFO[sender]) and (AutoInviteOutOfGuild == false) then
                return;
            end
            -- Is the party full so we need to convert to raid ?
            if (GetNumPartyMembers() == 4) and (GetNumRaidMembers() == 0) and (ConvertPartyToRaid == true) then
                -- Corvert the party to a raid.
                ConvertToRaid()
                -- Message that it's converted.
                DEFAULT_CHAT_FRAME:AddMessage("|cffffa500" .. "Party converted to raid." .. "|r");
                -- Invite the person
                InviteByName(sender)
            -- If we don't want to convert.
            elseif (ConvertPartyToRaid == false) then
                DEFAULT_CHAT_FRAME:AddMessage("Party is full.");
                return;
            -- If raid group is full.
            elseif (GetNumRaidMembers() == 40) then
                DEFAULT_CHAT_FRAME:AddMessage("Raid is full.");
                return;
            end
            -- Invite the person.
            InviteByName(sender)
        else
            -- Is it someone from guild and do we want to invite from out side the guild ?
            if (not GUILD_INFO[sender]) and (AutoInviteOutOfGuild == false) then
                return;
            end
            -- Invite the person.
            InviteByName(sender)
        end
    end

end

-- ====================================================================================================
-- ====================================================================================================
-- ====================================================================================================
-- =                    Make the checkbox in the raid frame to promote all in raid                    =
-- ====================================================================================================
-- ====================================================================================================
-- ====================================================================================================

function PromoteEveryoneBox()

    local checkButton = CreateFrame("CheckButton", nil, RaidFrame, "UICheckButtonTemplate");
        checkButton:SetWidth(20);
        checkButton:SetHeight(20);
        checkButton:SetPoint("TOPLEFT", "RaidFrame", "TOPLEFT", 70, -15);
        -- 
        if (PromoteAllInRaid == true) then
            checkButton:SetChecked(1);
        else
            checkButton:SetChecked(0);
        end

        checkButton:SetScript("OnClick", function()
            -- Set "Promote all" to true.
            if (checkButton:GetChecked()) then
                checkButton:SetChecked(1);
                SETTINGS.PromoteAllInRaid = true
                PromoteAllInRaid = true
                PromoteEveryoneInRaid()
            -- Set "Promote all" to false
            else
                checkButton:SetChecked(0);
                SETTINGS.PromoteAllInRaid = false
                PromoteAllInRaid = false
                DemoteEveryoneInRaid()
            end
        end)

    local PromoteAllText = checkButton:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        PromoteAllText:SetPoint("LEFT", checkButton, "RIGHT", 0, 0);
        PromoteAllText:SetText("Promote all.");
        PromoteAllText:SetJustifyH("LEFT");

end

-- ====================================================================================================
-- =                  The dropdown to chose what guild rank to auto promote in raid.                  =
-- ====================================================================================================

function MakeTheDropDown()

    -- Create the dropdown
    local dropDown = CreateFrame("Frame", "GuildRankPromoteDropdown", ManagerPlusRaid, "UIDropDownMenuTemplate");
        dropDown:SetPoint("TOPLEFT", ManagerPlusRaid, "TOPLEFT", 0, -30);
        dropDown:Show();

    -- Create the headline for the Dropdown
    local dropText = ManagerPlusRaid:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        dropText:SetPoint("BOTTOMLEFT", dropDown, "TOPLEFT", 20, 0);
        dropText:SetText("Guild rank to auto promote.");

    local function DoWeCheckIt(i)
        if (not SETTINGS["PromoteGuildRank"]) then
            return false;
        elseif (SETTINGS["PromoteGuildRank"] == (i - 1)) then
            return true;
        else
            return false;
        end
    end

    -- Get all the info we need for the dropdown menu.
    UIDropDownMenu_Initialize(dropDown, function()

        -- Loop to get all guild rank names.
        for i = 1, 10 do
            rankName = GuildControlGetRankName(i)
            -- Check that we found a rank name.
            if (rankName) then
                local info = {};
                local localI = i;
                info.text = rankName;
                info.value = localI;
                info.func = function()
                    -- Update the settings about what rank to auto update.
                    SETTINGS.PromoteGuildRank = (localI - 1);
                    -- Set the selected rank in the dropdown menu.
                    UIDropDownMenu_SetSelectedValue(dropDown, localI);
                    UIDropDownMenu_Refresh(dropDown);
                end;
                info.checked = DoWeCheckIt(i);
                UIDropDownMenu_AddButton(info);
            end
        end

        -- Set the selected value on initialization.
        if (SETTINGS["PromoteGuildRank"]) then
            rankName = GuildControlGetRankName(SETTINGS["PromoteGuildRank"] + 1);
            if (rankName) then
                UIDropDownMenu_SetSelectedValue(dropDown, SETTINGS["PromoteGuildRank"] + 1);
                UIDropDownMenu_Refresh(dropDown);
            end
        else
            UIDropDownMenu_SetText("Select rank", dropDown);
            UIDropDownMenu_Refresh(dropDown);
        end

    end)

    -- 
    AutoInviteKeyWordFrame()

end

-- ====================================================================================================
-- =                             The box for the key word for auto invite                             =
-- ====================================================================================================

function AutoInviteKeyWordFrame()

    -- Create the main frame for the keyword.
    local frameInvite = CreateFrame("Frame", "InviteKeyWordFrame", ManagerPlusRaid);
        frameInvite:SetWidth(120);
        frameInvite:SetHeight(20);
        frameInvite:SetPoint("TOPLEFT", ManagerPlusRaid, "TOPLEFT", 24, -80);
        frameInvite:Show();

    -- Create the textbox for the keyword.
    local invKeyWordBox = CreateFrame("EditBox", "InviteKeyWordEdit", InviteKeyWordFrame, "InputBoxTemplate");
        invKeyWordBox:SetWidth(InviteKeyWordFrame:GetWidth());
        invKeyWordBox:SetHeight(InviteKeyWordFrame:GetHeight());
        invKeyWordBox:SetAutoFocus(false)
        invKeyWordBox:SetMultiLine(false);
        invKeyWordBox:SetMaxLetters(80)
        invKeyWordBox:SetPoint("TOPLEFT", InviteKeyWordFrame, "TOPLEFT", 0, 0);
        invKeyWordBox:SetText(InviteKeyWord);
        invKeyWordBox:SetScript("OnEscapePressed", function()
            invKeyWordBox:ClearFocus()
        end)

    -- Create the text for the key word.
    local KeyWordText = ManagerPlusRaid:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        KeyWordText:SetPoint("BOTTOMLEFT", InviteKeyWordEdit, "TOPLEFT", -5, 0);
        KeyWordText:SetText("Keyword for auto invite.");

    -- Create the save button.
    local saveButton = CreateFrame("Button", nil, InviteKeyWordFrame, "UIPanelButtonTemplate");
        saveButton:SetWidth(60);
        saveButton:SetHeight(18);
        saveButton:SetPoint("TOPLEFT", InviteKeyWordEdit, "BOTTOMLEFT", -6, -2);
        saveButton:SetText("Save");
        saveButton:SetScript("OnClick", function()
            SETTINGS.AutoInviteKeyWord = invKeyWordBox:GetText()
            InviteKeyWord = invKeyWordBox:GetText()
            invKeyWordBox:ClearFocus()
        end);

    -- 
    AutoConvertToRaid()

end

-- ====================================================================================================
-- =                        The box where we chose if we auto convert to raid.                        =
-- ====================================================================================================

function AutoConvertToRaid()

    local ConvertToRaidCheckButton = CreateFrame("CheckButton", nil, ManagerPlusRaid, "UICheckButtonTemplate");
        ConvertToRaidCheckButton:SetWidth(20);
        ConvertToRaidCheckButton:SetHeight(20);
        ConvertToRaidCheckButton:SetPoint("TOPLEFT", "ManagerPlusRaid", "TOPLEFT", 19, -140);
        -- 
        if (ConvertPartyToRaid == true) then
            ConvertToRaidCheckButton:SetChecked(1);
        else
            ConvertToRaidCheckButton:SetChecked(0);
        end

        ConvertToRaidCheckButton:SetScript("OnClick", function()
            -- Set "convert to raid" to true.
            if (ConvertToRaidCheckButton:GetChecked()) then
                ConvertToRaidCheckButton:SetChecked(1);
                SETTINGS.ConvertPartyToRaid = true
                ConvertPartyToRaid = true
            -- Set "convert to raid" to false.
            else
                ConvertToRaidCheckButton:SetChecked(0);
                SETTINGS.ConvertPartyToRaid = false
                ConvertPartyToRaid = false
            end
        end)
        ConvertToRaidCheckButton:Show()

    local PromoteAllText = ConvertToRaidCheckButton:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        PromoteAllText:SetPoint("BOTTOMLEFT", ConvertToRaidCheckButton, "TOPLEFT", 0, 0);
        PromoteAllText:SetText("Auto convert party to raid.");
        PromoteAllText:SetJustifyH("LEFT");

    -- 
    OnlyAutoInviteGuildMembers()

end

-- ====================================================================================================
-- =                                  Invite guild members olny box.                                  =
-- ====================================================================================================

function OnlyAutoInviteGuildMembers()

    local GuildOnlyCheckButton = CreateFrame("CheckButton", nil, ManagerPlusRaid, "UICheckButtonTemplate");
        GuildOnlyCheckButton:SetWidth(20);
        GuildOnlyCheckButton:SetHeight(20);
        GuildOnlyCheckButton:SetPoint("TOPLEFT", "ManagerPlusRaid", "TOPLEFT", 19, -180);
        -- 
        if (AutoInviteOutOfGuild == false) then
            GuildOnlyCheckButton:SetChecked(1);
        else
            GuildOnlyCheckButton:SetChecked(0);
        end

        GuildOnlyCheckButton:SetScript("OnClick", function()
            -- 
            if (GuildOnlyCheckButton:GetChecked()) then
                GuildOnlyCheckButton:SetChecked(1);
                SETTINGS.AutoInviteOutOfGuild = false
                AutoInviteOutOfGuild = false
            -- 
            else
                GuildOnlyCheckButton:SetChecked(0);
                SETTINGS.AutoInviteOutOfGuild = true
                AutoInviteOutOfGuild = true
            end
        end)
        GuildOnlyCheckButton:Show()

    local GuildOnlyText = GuildOnlyCheckButton:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        GuildOnlyText:SetPoint("BOTTOMLEFT", GuildOnlyCheckButton, "TOPLEFT", 0, 0);
        GuildOnlyText:SetText("Only auto invite guild members.");
        GuildOnlyText:SetJustifyH("LEFT");

    -- 
    PromoteChosenPeopleFrame()

end

-- ====================================================================================================
-- =                       The box where we add single people to always promote                       =
-- ====================================================================================================

function PromoteChosenPeopleFrame()

    local frame = CreateFrame("Frame", "PromotePeopleBox", ManagerPlusRaid);
        frame:SetWidth(170);
        frame:SetHeight(120);
        frame:SetPoint("TOPRIGHT", ManagerPlusRaid, "TOPRIGHT", -20, -30);
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false,
            tileSize = 16,
            edgeSize = 16,
            insets = {
                left = 4,
                right = 4,
                top = 4,
                bottom = 4
            }
        });
        frame:Show();

    -- Create the text.
    local singleText = ManagerPlusRaid:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        singleText:SetPoint("BOTTOMLEFT", PromotePeopleBox, "TOPLEFT", 0, 0);
        singleText:SetText("People to auto promote.");

    local editBox = CreateFrame("EditBox", "PromotePeopleEditBox", PromotePeopleBox);
        editBox:SetTextInsets( 6, 6, 6, 6)
        editBox:SetWidth(PromotePeopleBox:GetWidth());
        editBox:SetHeight(PromotePeopleBox:GetHeight());
        editBox:SetPoint("TOPRIGHT", PromotePeopleBox, "TOPRIGHT", 0, 0); 
        editBox:SetPoint("BOTTOMRIGHT", PromotePeopleBox, "BOTTOMRIGHT", 0, 0); 
        editBox:SetAutoFocus(false)
        editBox:SetMultiLine(true);
        editBox:SetMaxLetters(280)
        editBox:SetFontObject("ChatFontNormal")

        -- Make sure the table is made.
        if (not RAID_PROMOTE) or (not type(RAID_PROMOTE) == "table") then
            RAID_PROMOTE = {}
        end

        -- 
        local TempNames
        -- 
        for playerName, _ in pairs(RAID_PROMOTE) do
            -- 
            if (not TempNames) then
                TempNames = playerName
            else
                TempNames = TempNames .. ", " .. playerName
            end
        end
        -- 
        if (TempNames) then
            editBox:SetText(TempNames);
        else
            editBox:SetText("Example:\nCrazytank, Lovelife, Smalldagger\n\n");
        end

        -- What will happen ehen escape is pressed.
        editBox:SetScript("OnEscapePressed", function()
            editBox:ClearFocus()
        end)
        editBox:SetScript("OnEnterPressed", function()
            -- Not used, just here so I know I have the option if I ever need.
        end)
        editBox:SetScript("OnMouseDown", function()
            -- Not used, just here so I know I have the option if I ever need.
        end)
        editBox:SetScript("OnEditFocusGained", function()
            -- Not used, just here so I know I have the option if I ever need.
        end)
        editBox:SetScript("OnEditFocusLost", function()
            -- Not used, just here so I know I have the option if I ever need.
        end)
        editBox:SetScript("OnTextChanged", function()
            -- Not used, just here so I know I have the option if I ever need.
        end)

    -- Button to save the people we have added.
    local saveButton = CreateFrame("Button", nil, PromotePeopleBox, "UIPanelButtonTemplate");
        saveButton:SetWidth(60);
        saveButton:SetHeight(18);
        saveButton:SetPoint("TOPLEFT", editBox, "BOTTOMLEFT", 0, 0);
        saveButton:SetText("Save");
        saveButton:SetScript("OnClick", function()

            local text = editBox:GetText();
            -- Check that we got some test.
            if (text) and (text ~= "") then
                -- Make sure it's not just our example.
                if (not string.find(text, "Crazytank")) and (not string.find(text, "Lovelife")) and (not string.find(text, "Smalldagger")) then
                    -- Empty the table, easy way "cheat" if we only delete 1 person. ;)
                    RAID_PROMOTE = {}
                    -- Split the string by commas.
                    for name in string.gmatch(text, "([^,]+)") do
                        -- Trim whitespace from each name.
                        local trimmedName = string.gsub(name, "^%s*(.-)%s*$", "%1");
                        -- Insert to the RAID_PROMOTE table.
                        RAID_PROMOTE[trimmedName] = {true,}
                    end
                -- It was our example.
                else
                    RAID_PROMOTE = nil
                end
            -- We got no text.
            else
                -- Delete the table as it's empty.
                RAID_PROMOTE = nil
            end

            -- Clear focus from editBox.
            editBox:ClearFocus()

        end);

end








