-- Some locals
local AddonName = "ManagerPlus"                        -- Addon name.
local LogInTime = GetTime()                         -- Used for the welcome message and when the frame has to be shown.
local RunFirstGuildCheck = true                     -- True so we know when to run first check.
local RunFirstGuildCheckTime = GetTime()            -- Used for running the first check of the guild.
local RunTime = GetTime()                           -- Used for how often we have to run the check to save new info.
local SayWelcome = true                             -- Do we want to show the welcome message and the frame with updates.
local strGuildName                                  -- To save our guild name.
local ShowPopUp = true                              -- Used for deciding if we show the popup or not.

local NewGuildAction                                -- Used to collect all new text about the guild.
local NewGuildActionLeft                            -- Used for the text about someone who left the guild.
local NewGuildActionJoin                            -- Used for the text about someone who joined the guild.
local NewGuildActionPromote                         -- Used for the text about someone who got promoted in the guild.
local NewGuildActionDemote                          -- Used for the text about someone who got demoted in the guild.
local NewGuildActionKick                            -- Used for the text about someone who have been offline for to long and have to be kicked.
local NewGuildActionOfficerNote                     -- Used for the text about someone who had Officer note changed.

local JoinCounter                                   -- Used for checking if we want a headline or not.
local LeaveCounter                                  -- Used for checking if we want a headline or not.
local PromoteCounter                                -- Used for checking if we want a headline or not.
local DemoteCounter                                 -- Used for checking if we want a headline or not.
local KickCounter                                   -- Used for checking if we want a headline or not.
local OfficerNoteCounter                            -- Used for checking if we want a headline or not.
local TotalCountedLines = 0                         -- Used in interface to see how big the scroll frame have to be.

local intKickRankIndex0 = intKickRankIndex0 or 90   -- Kick Guild Master after this amount of days.
local intKickRankIndex1 = intKickRankIndex1 or 30   -- Kick Officer after this amount of days.
local intKickRankIndex2 = intKickRankIndex2 or 30   -- Kick Officer Alt after this amount of days.
local intKickRankIndex3 = intKickRankIndex3 or 30   -- Kick Raid Leader after this amount of days.
local intKickRankIndex4 = intKickRankIndex4 or 30   -- Kick Raider after this amount of days.
local intKickRankIndex5 = intKickRankIndex5 or 30   -- Kick Social after this amount of days.
local intKickRankIndex6 = intKickRankIndex6 or 30   -- Kick Alt after this amount of days.
local intKickRankIndex7 = intKickRankIndex7 or 14   -- Kick Trial after this amount of days.
local intKickRankIndex8 = intKickRankIndex8 or 1    -- Kick Unknown after this amount of days.
local intKickRankIndex9 = intKickRankIndex9 or 1    -- Kick Unknown after this amount of days.

local TimeToPromote = TimeToPromote or 14           -- When someone should be promoted from the trial rank.

-- Create frames.
local f = CreateFrame("Frame")
-- Create the main frame
local myFrame = CreateFrame("Frame", "MySimpleFrame", UIParent);
local closeButton = CreateFrame("Button", "MySimpleFrameCloseButton", myFrame); -- The close button




--local frame = CreateFrame("Frame", "GuildMemberInfoFrame", UIParent);   -- The frame used for the interface.
--local testButton = CreateFrame("Button", "TestGuildInfoButton", UIParent);  -- The frame used for the test button.
--local closeButton = CreateFrame("Button", "GuildMemberInfoCloseButton", frame); -- The frame for close button.
--local scrollFrame = CreateFrame("ScrollFrame", "GuildMemberInfoScrollFrame", frame); -- Create a scroll frame
--local scrollChild = CreateFrame("Frame", "GuildMemberInfoScrollChild", scrollFrame) --Create the scroll child.
f:RegisterEvent("ADDON_LOADED");
f:RegisterEvent("GUILD_ROSTER_UPDATE");
f:RegisterEvent("PLAYER_GUILD_UPDATE");

-- ====================================================================================================
-- =                                          Event handler.                                          =
-- ====================================================================================================

f:SetScript("OnEvent", function(self, event, arg1, ...)
    if (event == "ADDON_LOADED") and (arg1 == AddonName) then
        --Update the guild roster.
        GuildRoster();
        -- Get the guild name of the guild we are in, if any.
        strGuildName = GetGuildInfo("player");
        -- Do we have the tables we need to save guild info, if not then we create them.
        if (not GUILD_INFO) or (not type(GUILD_INFO) == "table") then
            GUILD_INFO = {}
        end
        if (not BANNED_FROM_GUILD) or (not type(BANNED_FROM_GUILD) == "table") then
            BANNED_FROM_GUILD = {}
        end
        if (not GUILD_INFO_HISTORY) or (not type(GUILD_INFO_HISTORY) == "table") then
            GUILD_INFO_HISTORY = {}
        end
        -- Unregister the event as we don't need it anymore.
        f:UnregisterEvent("ADDON_LOADED");
    elseif event == "GUILD_ROSTER_UPDATE" then
        GTGuildUpdateRoster()
    elseif event == "PLAYER_GUILD_UPDATE" then
        GTGuildUpdateRoster()
    end
end);

-- ====================================================================================================
-- =                                     OnUpdate on every frame.                                     =
-- ====================================================================================================

f:SetScript("OnUpdate", function()

    -- Say hello to the user.
    if ((LogInTime + 4) < GetTime()) and (SayWelcome == true) then
        DEFAULT_CHAT_FRAME:AddMessage("|cff3333ff" .. AddonName .. " by " .. "|r" .. "|cFF06c51b" .. "Subby" .. "|r" .. "|cff3333ff" .. " is loaded." .. "|r");
        SayWelcome = false
        --Update the guild roster.
        GuildRoster();
        -- Get the guild name of the guild we are in, if any.
        strGuildName = GetGuildInfo("player");
        -- Do we have the tables we need to save guild info, if not then we create them.
        if (not GUILD_INFO) or (not type(GUILD_INFO) == "table") then
            GUILD_INFO = {}
        end
        if (not BANNED_FROM_GUILD) or (not type(BANNED_FROM_GUILD) == "table") then
            BANNED_FROM_GUILD = {}
        end
        if (not GUILD_INFO_HISTORY) or (not type(GUILD_INFO_HISTORY) == "table") then
            GUILD_INFO_HISTORY = {}
        end
    end

    -- Run the roster for the first time.
    if ((RunFirstGuildCheckTime + 20) < GetTime()) and (RunFirstGuildCheck == true) then
        GuildUpdateRoster()
        RunFirstGuildCheck = false
    end

    -- Update the roster every 5 min.
    if ((RunTime + 300) < GetTime()) then
        -- Check if we are in a raid as we don't want it to run there, maybe it will give us a little lag, who knows.
        if (GetNumRaidMembers() == 0) then
            GuildUpdateRoster()
        end
        -- Reset timer.
        RunTime = GetTime()
    end

end)

-- ====================================================================================================
-- =                                          Slash commands                                          =
-- ====================================================================================================
SLASH_MANAGERPLUS1 = "/m+", "/mp", "/managerplus";
SlashCmdList["MANAGERPLUS"] = function(msg)

    -- 
    local command, playerName, reason = string.match(msg, "^(ban)%s+(%S+)%s+(.+)$");

    if (command == "ban") and (playerName) and (reason) then

        -- Did we find the person in GUILD_INFO ?
        if (GUILD_INFO[playerName]) then

            -- Send a message to guild about it.
            SendChatMessage("Banning " .. playerName .. " from guild.", "GUILD");
            SendChatMessage("Reason: " .. reason, "GUILD");

            -- Save all the info we have about the person so we can stop him from coming back.
            BANNED_FROM_GUILD[playerName] = {
                ["LeftTheGuild"] = date(),
                ["Rank"] = GUILD_INFO[playerName]["Rank"],
                ["PublicNote"] = GUILD_INFO[playerName]["PublicNote"],
                ["OfficerNote"] = GUILD_INFO[playerName]["OfficerNote"],
                ["RankIndex"] = GUILD_INFO[playerName]["RankIndex"],
                ["BanReason"] = reason,
                ["Updated"] = date(),
                ["GuildName"] = GUILD_INFO[playerName]["GuildName"],
                ["SeenFirstTime"] = GUILD_INFO[playerName]["SeenFirstTime"],
                ["Level"] = GUILD_INFO[playerName]["Level"],
                ["Class"] = GUILD_INFO[playerName]["Class"],
            };

            -- Save it all in GUILD_INFO_HISTORY also.
            GUILD_INFO_HISTORY[playerName] = {
                ["Banned"] = true,
                ["BanReason"] = reason,
                ["GuildName"] = strGuildName,
                ["SeenFirstTime"] = GUILD_INFO[playerName]["SeenFirstTime"],
                ["Rank"] = GUILD_INFO[playerName]["Rank"],
                ["RankIndex"] = GUILD_INFO[playerName]["RankIndex"],
                ["Level"] = GUILD_INFO[playerName]["Level"],
                ["Class"] = GUILD_INFO[playerName]["Class"],
                ["Offline"] = GUILD_INFO[playerName]["Offline"],
                ["PublicNote"] = GUILD_INFO[playerName]["PublicNote"],
                ["OfficerNote"] = GUILD_INFO[playerName]["OfficerNote"],
                ["LeftTheGuild"] = date(),
                ["Updated"] = date(),
            };

            -- Delete the person from GUILD_INFO
            GUILD_INFO[playerName] = nil

            -- Kick the player (We can't kick a guild member from a addon, so we need new way.)
            -- SendChatMessage("/gkick " .. playerName, "GUILD");
        else
            DEFAULT_CHAT_FRAME:AddMessage("The player \"" .. playerName .. "\" was not found in guild.");
        end

    elseif (msg == "") then
        ShowPopUp = true
        GuildUpdateRoster();
    else
        DEFAULT_CHAT_FRAME:AddMessage("Usage: /m+ ban PlayerName Reason");
    end
end;

-- ====================================================================================================
-- =                                  Color the name by class color.                                  =
-- ====================================================================================================

function Manager_ColorTheName(Class, Name)

    -- Did we get a name and a class ?
    if (Name) and (Class) then
        if (string.lower(Class) == "druid") then
            return "|cffFF7C0A" .. Name .. "|r"
        elseif (string.lower(Class) == "hunter") then
            return "|cffAAD372" .. Name .. "|r"
        elseif (string.lower(Class) == "mage") then
            return "|cff3FC7EB" .. Name .. "|r"
        elseif (string.lower(Class) == "paladin") then
            return "|cffF48CBA" .. Name .. "|r"
        elseif (string.lower(Class) == "priest") then
            return "|cffFFFFFF" .. Name .. "|r"
        elseif (string.lower(Class) == "rogue") then
            return "|cffFFF468" .. Name .. "|r"
        elseif (string.lower(Class) == "shaman") then
            return "|cff0070DD" .. Name .. "|r"
        elseif (string.lower(Class) == "warlock") then
            return "|cff8788EE" .. Name .. "|r"
        elseif (string.lower(Class) == "warrior") then
            return "|cffC69B6D" .. Name .. "|r"
        end
    end

end

-- ====================================================================================================
-- =                         Gather info about the guild and look for changes                         =
-- ====================================================================================================

function GuildUpdateRoster()

    -- Check that we are in a guild, if not we stop everything.
    if (IsInGuild()) then
        --Update the guild roster.
        GuildRoster();
        -- Get the guild name of the guild we are in.
        strGuildName = GetGuildInfo("player");
    else
        -- Stop everything as we are not in a guild.
        return;
    end

    -- Make sure we have the name of the guild we are in, if no guild, then stop it all.
    if (strGuildName == nil) then
        return;
    end

    -- Empty the locals for old info.
    NewGuildActionJoin = nil
    NewGuildActionLeft = nil
    NewGuildActionPromote = nil
    NewGuildActionDemote = nil
    NewGuildActionKick = nil

    -- Make sure that TEMP_GUILD_INFO is empty so we don't get old info.
    TEMP_GUILD_INFO = {}

    -- Get the total numbers of guild members.
    local numGuildMembers = GetNumGuildMembers(true);
    -- If we got a number of guild members higher then 0
    if (numGuildMembers > 0) then
        -- Loop through all guild members.
        for i = 1, numGuildMembers do
            -- Get the info we need from current guild member.
            local name, rank, rankIndex, level, class, _, note, officernote = GetGuildRosterInfo(i);
            -- Did we find a name of a guild member ?
            if (name) then
                -- Get last online status.
                years, months, days, hours = GetGuildRosterLastOnline(i);
                -- Anoter way to write (if x then x else y end)
                years, months, days, hours = years and years or 0, months and months or 0, days and days or 0, hours and hours or 0;
                -- Get the total days offline.
                DaysOffline = (((((years * 12) + months) * 30.5 + days) * 24 + hours) / 24);
                -- Save all info to TEMP_GUILD_INFO
                TEMP_GUILD_INFO[name] = {
                    ["GuildName"] = strGuildName,
                    ["Rank"] = rank,
                    ["RankIndex"] = rankIndex,
                    ["Level"] = level,
                    ["Class"] = class,
                    ["PublicNote"] = note,
                    ["OfficerNote"] = officernote,
                    ["Offline"] = DaysOffline,
                    ["IsOnline"] = online,
                    ["Kick"] = DoKick,
                };
            end
        end
    end

-- =================================== Did someone leave the guild? ===================================

    -- Reset the counter
    LeaveCounter = 0
    PromoteCounter = 0
    DemoteCounter = 0
    KickCounter = 0
    OfficerNoteCounter = 0

    -- Iterate through all members in the saved variable GUILD_INFO.
    for playerName, playerData in pairs(GUILD_INFO) do
        -- Check if we have the same names in both tables and it's the correct guild.
        if (GUILD_INFO[playerName]) and (ShowPopUp == true) and (not TEMP_GUILD_INFO[playerName]) and (GUILD_INFO[playerName]["GuildName"] == strGuildName) then
            -- Save the info in GUILD_INFO_HISTORY about old members.
            GUILD_INFO_HISTORY[playerName] = {
                ["GuildName"] = strGuildName,
                ["SeenFirstTime"] = GUILD_INFO[playerName]["SeenFirstTime"],
                ["Rank"] = GUILD_INFO[playerName]["Rank"],
                ["RankIndex"] = GUILD_INFO[playerName]["RankIndex"],
                ["Level"] = GUILD_INFO[playerName]["Level"],
                ["Class"] = GUILD_INFO[playerName]["Class"],
                ["Offline"] = GUILD_INFO[playerName]["Offline"],
                ["PublicNote"] = GUILD_INFO[playerName]["PublicNote"],
                ["OfficerNote"] = GUILD_INFO[playerName]["OfficerNote"],
                ["LeftTheGuild"] = date(),
                ["Updated"] = date(),
            };

            -- Delete the person from GUILD_INFO.
            GUILD_INFO[playerName] = nil;

            -- Count
            LeaveCounter = LeaveCounter + 1

            -- Check if it's the first line
            if (LeaveCounter == 1) then
                NewGuildActionLeft = "----- LEFT THE GUILD -----\n"
            end
            NewGuildActionLeft = NewGuildActionLeft .. "The " .. playerData.Class .. " " .. Manager_ColorTheName(playerData.Class, playerName) .. " (" .. playerData.Level .. ") (" .. playerData.Rank .. ") has left the guild.\n"
        end

-- =============================== Did someone get promoted or demoted? ===============================

        -- Did the rank change and is it someone in current guild ?
        if ((GUILD_INFO[playerName]) and (TEMP_GUILD_INFO[playerName])) and (ShowPopUp == true) and ((GUILD_INFO[playerName]["RankIndex"] ~= TEMP_GUILD_INFO[playerName]["RankIndex"]) and (GUILD_INFO[playerName]["GuildName"] == strGuildName)) then
            -- Is the new RankIndex from TEMP_GUILD_INFO smaller than the RankIndex in GUILD_INFO ? (Smaller is promote, Guild Master is RankIndex 0)
            if (TEMP_GUILD_INFO[playerName]["RankIndex"] < GUILD_INFO[playerName]["RankIndex"]) then
                -- Count.
                PromoteCounter = PromoteCounter + 1
                -- Make the headline and the text.
                if (PromoteCounter == 1) then
                    NewGuildActionPromote = "----- PROMOTED -----\n"
                end
                -- Write the text.
                NewGuildActionPromote = NewGuildActionPromote .. "The " .. playerData.Class .. " " .. Manager_ColorTheName(playerData.Class, playerName) .. " (" .. playerData.Level .. ") has been promoted from " .. playerData.Rank .. " to " .. TEMP_GUILD_INFO[playerName]["Rank"] .. ".\n"
                -- Update GUILD_INFO
                GUILD_INFO[playerName].Rank = TEMP_GUILD_INFO[playerName]["Rank"]
                GUILD_INFO[playerName].RankIndex = TEMP_GUILD_INFO[playerName]["RankIndex"]
                GUILD_INFO[playerName].Updated = date()

            -- Is the new RankIndex from TEMP_GUILD_INFO higher than the RankIndex in GUILD_INFO ? (Higher is demote, Guild Master is RankIndex 0)
            elseif (TEMP_GUILD_INFO[playerName]["RankIndex"] > GUILD_INFO[playerName]["RankIndex"]) then
                -- Count
                DemoteCounter = DemoteCounter + 1
                -- Make the headline.
                if (DemoteCounter == 1) then
                    NewGuildActionDemote = "----- DEMOTED -----\n"
                end
                -- Write the text
                NewGuildActionDemote = NewGuildActionDemote .. "The " .. playerData.Class .. " " .. Manager_ColorTheName(playerData.Class, playerName) .. " (" .. playerData.Level .. ") has been demoted from " .. playerData.Rank .. " to " .. TEMP_GUILD_INFO[playerName]["Rank"] .. ".\n"
                -- Update GUILD_INFO
                GUILD_INFO[playerName].Rank = TEMP_GUILD_INFO[playerName]["Rank"]
                GUILD_INFO[playerName].RankIndex = TEMP_GUILD_INFO[playerName]["RankIndex"]
                GUILD_INFO[playerName].Updated = date()

            end
        end

-- ================================== Is it time to promote someone? ==================================

        -- Has someone been in the guild for the amount of days there is requred to be promoted ?
        if (GUILD_INFO[playerName]) and (ShowPopUp == true) and (TimeToPromote) and (GUILD_INFO[playerName]["GuildName"] == strGuildName) then
            
        end

-- ====================================== Did someone level up ? ======================================

        -- Did player level change and is it someone from this guild ?
        if ((GUILD_INFO[playerName]) and (TEMP_GUILD_INFO[playerName])) and (ShowPopUp == true) and (GUILD_INFO[playerName]["Level"] ~= TEMP_GUILD_INFO[playerName]["Level"]) and (GUILD_INFO[playerName]["GuildName"] == strGuildName) then
            -- Update GUILD_INFO
            GUILD_INFO[playerName].Level = TEMP_GUILD_INFO[playerName]["Level"]
            GUILD_INFO[playerName].Updated = date()
        end

-- ===================================== Did public note change ? =====================================

        -- Did the Public note change and is it someone from this guild ?
        if ((GUILD_INFO[playerName]) and (TEMP_GUILD_INFO[playerName])) and (ShowPopUp == true) and (GUILD_INFO[playerName]["PublicNote"] ~= TEMP_GUILD_INFO[playerName]["PublicNote"]) and  (GUILD_INFO[playerName]["GuildName"] == strGuildName) then
            -- Update GUILD_INFO
            GUILD_INFO[playerName].PublicNote = TEMP_GUILD_INFO[playerName]["PublicNote"]
            GUILD_INFO[playerName].Updated = date()
        end

-- ===================================== Did officer note change? =====================================

        -- Did officer note change and is it someone from this guild ?
        if ((GUILD_INFO[playerName]) and (TEMP_GUILD_INFO[playerName])) and (GUILD_INFO[playerName]["OfficerNote"] ~= TEMP_GUILD_INFO[playerName]["OfficerNote"]) and (GUILD_INFO[playerName]["GuildName"] == strGuildName) then
            -- Count
            OfficerNoteCounter = OfficerNoteCounter + 1

            -- Make the headline.
            if (OfficerNoteCounter == 1) then
                NewGuildActionOfficerNote = "----- OFFICER NOTE CHANGED -----\n"
            end
            -- Write the text.
            NewGuildActionOfficerNote = NewGuildActionOfficerNote .. "The Officer note for " .. Manager_ColorTheName(playerData.Class, playerName) .. " has been changed from \"" .. GUILD_INFO[playerName]["OfficerNote"] .. "\" to \"" .. TEMP_GUILD_INFO[playerName]["OfficerNote"] .. "\".\n"
            -- Update GUILD_INFO
            GUILD_INFO[playerName].OfficerNote = TEMP_GUILD_INFO[playerName]["OfficerNote"]
            GUILD_INFO[playerName].Updated = date()
        end

-- ============================== Has someone been offline for to long ? ==============================

        -- We need to check everyone in the guild, so we start with checking that it is someone from the guild.
        if ((GUILD_INFO[playerName]) and (TEMP_GUILD_INFO[playerName])) and (ShowPopUp == true) and (GUILD_INFO[playerName]["GuildName"] == strGuildName) then
            -- A local
            local FoundSomeone = false
            -- 
            if (GUILD_INFO[playerName]) and (GUILD_INFO[playerName]["RankIndex"] == 0) and (TEMP_GUILD_INFO[playerName]["Offline"] >= intKickRankIndex0) then
                FoundSomeone = true
            elseif (GUILD_INFO[playerName]) and (GUILD_INFO[playerName]["RankIndex"] == 1) and (TEMP_GUILD_INFO[playerName]["Offline"] >= intKickRankIndex1) then
                FoundSomeone = true
            elseif (GUILD_INFO[playerName]) and (GUILD_INFO[playerName]["RankIndex"] == 2) and (TEMP_GUILD_INFO[playerName]["Offline"] >= intKickRankIndex2) then
                FoundSomeone = true
            elseif (GUILD_INFO[playerName]) and (GUILD_INFO[playerName]["RankIndex"] == 3) and (TEMP_GUILD_INFO[playerName]["Offline"] >= intKickRankIndex3) then
                FoundSomeone = true
            elseif (GUILD_INFO[playerName]) and (GUILD_INFO[playerName]["RankIndex"] == 4) and (TEMP_GUILD_INFO[playerName]["Offline"] >= intKickRankIndex4) then
                FoundSomeone = true
            elseif (GUILD_INFO[playerName]) and (GUILD_INFO[playerName]["RankIndex"] == 5) and (TEMP_GUILD_INFO[playerName]["Offline"] >= intKickRankIndex5) then
                FoundSomeone = true
            elseif (GUILD_INFO[playerName]) and (GUILD_INFO[playerName]["RankIndex"] == 6) and (TEMP_GUILD_INFO[playerName]["Offline"] >= intKickRankIndex6) then
                FoundSomeone = true
            elseif (GUILD_INFO[playerName]) and (GUILD_INFO[playerName]["RankIndex"] == 7) and (TEMP_GUILD_INFO[playerName]["Offline"] >= intKickRankIndex7) then
                FoundSomeone = true
            elseif (GUILD_INFO[playerName]) and (GUILD_INFO[playerName]["RankIndex"] == 8) and (TEMP_GUILD_INFO[playerName]["Offline"] >= intKickRankIndex8) then
                FoundSomeone = true
            elseif (GUILD_INFO[playerName]) and (GUILD_INFO[playerName]["RankIndex"] == 9) and (TEMP_GUILD_INFO[playerName]["Offline"] >= intKickRankIndex9) then
                FoundSomeone = true
            else
                -- Update everything in GUILD_INFOthere is not updated anyware else.
                -- Might seems stupid, but in Turtle WoW you can change class for example.
                GUILD_INFO[playerName].GuildName = strGuildName
                GUILD_INFO[playerName].Class = TEMP_GUILD_INFO[playerName]["Class"]
                GUILD_INFO[playerName].Updated = date()
            end

            -- Did we find someone ?
            if (FoundSomeone == true) then
                -- Count
                KickCounter = KickCounter + 1

                -- Make the headline.
                if (KickCounter == 1) then
                    NewGuildActionKick = "----- TIME TO KICK -----\n"
                end
                -- Write the text.
                NewGuildActionKick = NewGuildActionKick .. "The " .. playerData.Class .. " " .. Manager_ColorTheName(playerData.Class, playerName) .. " (" .. playerData.Level .. ") (" .. playerData.Rank .. ") has been offline for " .. math.floor(TEMP_GUILD_INFO[playerName]["Offline"]) .. " days.\n"
                -- Update GUILD_INFO
                GUILD_INFO[playerName].Offline = TEMP_GUILD_INFO[playerName]["Offline"]
                GUILD_INFO[playerName].Updated = date()
            end

        end

    end

-- ====================================================================================================
-- =                                Loop check through TEMP_GUILD_INFO                                =
-- ====================================================================================================

    -- Reset the counter
    JoinCounter = 0

    -- Iterate through all members in the saved variable TEMP_GUILD_INFO.
    for playerName, playerData in pairs(TEMP_GUILD_INFO) do

-- =================================== Did someone join the guild ? ===================================

        -- Check if we have the same names in both tables and it's the correct guild.
        if (not GUILD_INFO[playerName]) and (TEMP_GUILD_INFO[playerName]["GuildName"] == strGuildName) then
            -- Check if it a person there is banned from the guild, if so, then inform and kick.
            if (BANNED_FROM_GUILD[playerName]) then
                -- Get a date people understand.
                local TimeStamp = BANNED_FROM_GUILD[playerName]["LeftTheGuild"]
                local FormatedTimeStamp
                if TimeStamp then
                    FormatedTimeStamp = date("%d-%B-%Y", TimeStamp)
                end

                -- Send a message to guild about it.
                SendChatMessage(playerName .. " was banned from the guild on " .. FormatedTimeStamp, "GUILD");
                SendChatMessage("Reason: " .. BANNED_FROM_GUILD[playerName]["BanReason"], "GUILD");
                SendChatMessage("That is why " .. playerName .. " is kicked again.", "GUILD");

            -- The person was not banned, add to GUILD_INFO.
            else
                -- Only do it if we want to show it.
                if (ShowPopUp == true) then
                    -- 
                    GUILD_INFO[playerName] = {
                        ["GuildName"] = strGuildName,
                        ["SeenFirstTime"] = date(),
                        ["Rank"] = TEMP_GUILD_INFO[playerName]["Rank"],
                        ["RankIndex"] = TEMP_GUILD_INFO[playerName]["RankIndex"],
                        ["Level"] = TEMP_GUILD_INFO[playerName]["Level"],
                        ["Class"] = TEMP_GUILD_INFO[playerName]["Class"],
                        ["PublicNote"] = TEMP_GUILD_INFO[playerName]["PublicNote"],
                        ["OfficerNote"] = TEMP_GUILD_INFO[playerName]["OfficerNote"],
                        ["Offline"] = TEMP_GUILD_INFO[playerName]["Offline"],
                        ["Updated"] = date(),
                    };

                    -- Count
                    JoinCounter = JoinCounter + 1

                    -- Check if it's the first line
                    if (JoinCounter == 1) then
                        NewGuildActionJoin = "----- JOINED THE GUILD -----\n"
                    end
                    NewGuildActionJoin = NewGuildActionJoin .. "The " .. playerData.Class .. " " .. Manager_ColorTheName(playerData.Class, playerName) .. " (" .. playerData.Level .. ") (" .. playerData.Rank .. ") has joined the guild.\n"
                end
            end
        end
    end

    -- Count all the line we have, we use it in interface to see how big we want the scroll frame.
    TotalCountedLines = LeaveCounter + PromoteCounter + DemoteCounter + KickCounter + OfficerNoteCounter + JoinCounter
    -- Check that we don't have to few.
    if (TotalCountedLines <= frame:GetHeight()) then
        TotalCountedLines = frame:GetHeight()
    else
        TotalCountedLines = (TotalCountedLines * 8)
    end
    -- DEFAULT_CHAT_FRAME:AddMessage(TotalCountedLines);
    -- Make the text, if there is something to make.
    MakeTheText()

end

-- ====================================================================================================
-- =                                      Put all text together.                                      =
-- ====================================================================================================

function MakeTheText(LinesTotal)

    -- Make sure old info is deleted
    NewGuildAction = nil

    -- Did we get any text about someone left the guild ?
    if (NewGuildActionLeft) then
        if (NewGuildAction) then
            NewGuildAction = NewGuildAction .. NewGuildActionLeft
        else
            NewGuildAction = NewGuildActionLeft
        end
    end
    -- Did we get any text about someone joined the guild ?
    if (NewGuildActionJoin) then
        if (NewGuildAction) then
            NewGuildAction = NewGuildAction .. NewGuildActionJoin
        else
            NewGuildAction = NewGuildActionJoin
        end
    end
    -- Did we get any text about someone have been promoted ?
    if (NewGuildActionPromote) then
        if (NewGuildAction) then
            NewGuildAction = NewGuildAction .. NewGuildActionPromote
        else
            NewGuildAction = NewGuildActionPromote
        end
    end
    -- Did we get any text about someone have been demoted ?
    if (NewGuildActionDemote) then
        if (NewGuildAction) then
            NewGuildAction = NewGuildAction .. NewGuildActionDemote
        else
            NewGuildAction = NewGuildActionDemote
        end
    end
    -- Did we get any text about someone need to be kicked from the guild ?
    if (NewGuildActionKick) then
        if (NewGuildAction) then
            NewGuildAction = NewGuildAction .. NewGuildActionKick
        else
            NewGuildAction = NewGuildActionKick
        end
    end
    -- Did we get any text about a officer note there have been changed ?
    if (NewGuildActionOfficerNote) then
        if (NewGuildAction) then
            NewGuildAction = NewGuildAction .. NewGuildActionOfficerNote
        else
            NewGuildAction = NewGuildActionOfficerNote
        end
    end

    -- Check if it's only the Officer note there is changed.
    -- The reason we do this is that we want to know as fast as possible.
    if (ShowPopUp == false) and (NewGuildActionOfficerNote) and (NewGuildActionLeft == nil) and (NewGuildActionJoin == nil) and (NewGuildActionPromote == nil) and (NewGuildActionDemote == nil) and (NewGuildActionKick == nil) then
        -- Print in chat that the info about Officer note changed.
        DEFAULT_CHAT_FRAME:AddMessage(NewGuildAction);
        ManagerPlusText:SetText(NewGuildAction);
        ManagerPlusScrollbar:SetMinMaxValues(0, TotalCountedLines); -- Normalize scroll value
        ManagerPlusContent:SetHeight(TotalCountedLines); -- Make it taller than the scrollframe for scrolling
        frame:Hide();
    elseif (ShowPopUp == true) and (NewGuildAction) then
        -- 
        ManagerPlusText:SetText(NewGuildAction);
        ManagerPlusScrollbar:SetMinMaxValues(0, TotalCountedLines); -- Normalize scroll value
        ManagerPlusContent:SetHeight(TotalCountedLines); -- Make it taller than the scrollframe for scrolling
        frame:Show();
        -- 
        ShowPopUp = false
    end

    -- Clear all data so we don't use old info.
    NewGuildActionLeft = nil
    NewGuildActionJoin = nil
    NewGuildActionPromote = nil
    NewGuildActionDemote = nil
    NewGuildActionKick = nil
    NewGuildActionOfficerNote = nil

end

-- ====================================================================================================
-- =                                          The interface.                                          =
-- ====================================================================================================


-- Some locals
local NewScrollValue = 0

-- Create the main frame
frame = CreateFrame("Frame", "ManagerPlus", UIParent);
frame:SetWidth(400);
frame:SetHeight(250);
frame:SetPoint("CENTER", 0, 0);
frame:SetFrameStrata("DIALOG");
frame:SetClampedToScreen(true);
frame:SetMovable(true);
frame:EnableMouse(true);
frame:RegisterForDrag("LeftButton");
frame:SetScript("OnDragStart", function()
    this:StartMoving();
end);
frame:SetScript("OnDragStop", function()
    this:StopMovingOrSizing();
end);
frame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = {
        left = 4,
        right = 4,
        top = 4,
        bottom = 4
    }
});
frame:SetBackdropColor(0, 0, 0, 0.9);
frame:Hide();

-- Close button.
local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton");
closeButton:SetWidth(32);
closeButton:SetHeight(32);
closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 2, 0);
closeButton:SetScript("OnClick", function()
    frame:Hide();
end);
closeButton:Show();

-- Create the scroll frame
local scrollframe = CreateFrame("ScrollFrame", nil, frame);
scrollframe:SetPoint("TOPLEFT", 10, -10);
scrollframe:SetPoint("BOTTOMRIGHT", -26, 10); -- Adjusted to make room for ManagerPlusScrollbar
scrollframe:EnableMouseWheel(true)
scrollframe:Show();

-- Create the ManagerPlusScrollbar
ManagerPlusScrollbar = CreateFrame("Slider", nil, scrollframe, "UIPanelScrollBarTemplate");
ManagerPlusScrollbar:SetPoint("TOPLEFT", scrollframe, "TOPRIGHT", 4, -40);
ManagerPlusScrollbar:SetPoint("BOTTOMLEFT", scrollframe, "BOTTOMRIGHT", 4, 16);
ManagerPlusScrollbar:SetHeight(frame:GetHeight());
ManagerPlusScrollbar:SetValueStep(20);
ManagerPlusScrollbar:SetValue(0);
ManagerPlusScrollbar:SetWidth(16);
ManagerPlusScrollbar:Show();

-- Create the ManagerPlusContent frame
ManagerPlusContent = CreateFrame("Frame", nil, scrollframe);
ManagerPlusContent:SetWidth(frame:GetWidth() - 20); -- Adjust as needed
scrollframe:SetScrollChild(ManagerPlusContent);

-- Mouse scrolling
scrollframe:SetScript("OnMouseWheel", function()
    -- Check how much we max scroll
    local maxScrollOffset = ManagerPlusContent:GetHeight();

    -- Check if NewScrollValue is 0
    if (NewScrollValue == nil) then
        NewScrollValue = 0
    end

    -- Check if we scroll up or down
    if (arg1 == 1) then
        NewScrollValue = NewScrollValue - 20
    else
        NewScrollValue = NewScrollValue + 20
    end

    -- Check that NewScrollValue is not below 0 or above maxScrollOffset
    if (NewScrollValue <= 0) then
        NewScrollValue = 0
    elseif (NewScrollValue >= maxScrollOffset) then
        NewScrollValue = maxScrollOffset
    end

    if (ManagerPlusContent:GetHeight() >= frame:GetHeight()) then
        ManagerPlusScrollbar:SetValue(NewScrollValue);
    else
        ManagerPlusScrollbar:SetValue(0);
        ManagerPlusScrollbar:Hide();
    end
end)

-- Add some text to the ManagerPlusContent frame (for testing)
ManagerPlusText = ManagerPlusContent:CreateFontString(nil, "OVERLAY", "GameFontNormal");
ManagerPlusText:SetPoint("TOPLEFT", ManagerPlusContent, "TOPLEFT", 5, -2);
-- ManagerPlusText:SetText("This is some text.\n\nLine 1\nLine 2\nLine 3\nLine 4\nLine 5\nLine 6\nLine 7\nLine 8\nLine 9\nLine 10\nLine 11\nLine 12\nLine 13\nLine 14\nLine 15\nLine 16\nLine 17\nLine 18\nLine 19\nLine 20\nLine 21\nLine 22\nLine 23\nLine 24\nLine 25\nLine 26\nLine 27\nLine 28\nLine 29\nLine 30\nLine 31\nLine 32\nLine 33\nLine 34\nLine 35\nLine 36\nLine 37\nLine 38\nLine 39\nLine 40\nLine 41\nLine 42\nLine 43\nLine 44\nLine 45\nLine 46\nLine 47\nLine 48\nLine 49\nLine 50");
ManagerPlusText:SetJustifyH("LEFT");

