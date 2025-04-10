-- Stuff I need to fix.
-- A variable can be no longer then 8192 (from 0 to 8191) letters, that is not enough.
-- That is only around 80 lines with the text I set for each action, far from enough.
-- https://www.hiveworkshop.com/threads/is-there-a-max-number-of-variables.40945/

-- Some locals
local AddonName = "ManagerPlus"                                 -- Addon name.
local AddonVersion = GetAddOnMetadata(AddonName, "Version")     -- The version of the addon.
local LogInTime = GetTime()                                     -- Used for the welcome message and when the frame has to be shown.
local RunFirstGuildCheck = true                                 -- True so we know when to run first check.
local RunFirstGuildCheckTime = GetTime()                        -- Used for running the first check of the guild.
local RunTime = GetTime()                                       -- Used for how often we have to run the check to save new info.
local SayWelcome = true                                         -- Do we want to show the welcome message and the frame with updates.
local strGuildName                                              -- To save our guild name.
local ShowPopUp = true                                          -- Used for deciding if we show the popup or not.

local NewGuildAction                                            -- Used to collect all new text about the guild.
local NewGuildActionLeft                                        -- Used for the text about someone who left the guild.
local NewGuildActionJoin                                        -- Used for the text about someone who joined the guild.
local NewGuildActionPromote                                     -- Used for the text about someone who got promoted in the guild.
local NewGuildActionTimeToPromote                               -- Used for the text about if it's time to promote someone.
local NewGuildActionDemote                                      -- Used for the text about someone who got demoted in the guild.
local NewGuildActionKick                                        -- Used for the text about someone who have been offline for to long and have to be kicked.
local NewGuildActionOfficerNote                                 -- Used for the text about someone who had Officer note changed.

local JoinCounter                                               -- Used for checking if we making a headline or not.
local LeaveCounter                                              -- Used for checking if we making a headline or not.
local PromoteCounter                                            -- Used for checking if we making a headline or not.
local DemoteCounter                                             -- Used for checking if we making a headline or not.
local KickCounter                                               -- Used for checking if we making a headline or not.
local OfficerNoteCounter                                        -- Used for checking if we making a headline or not.
local TimeToPromoteCounter                                      -- Used for checking if we making a headline or not.
local TotalCountedLines = 0                                     -- Used in interface to see how big the scroll frame have to be.

local intKickRankIndex0 = 90                                    -- Ask a Game Master for the Guild Master rank, only Officers can ask that.
local intKickRankIndex1 = intKickRankIndex1 or 30               -- Kick Officer after this amount of days.
local intKickRankIndex2 = intKickRankIndex2 or 30               -- Kick Officer Alt after this amount of days.
local intKickRankIndex3 = intKickRankIndex3 or 30               -- Kick Raid Leader after this amount of days.
local intKickRankIndex4 = intKickRankIndex4 or 30               -- Kick Raider after this amount of days.
local intKickRankIndex5 = intKickRankIndex5 or 30               -- Kick Social after this amount of days.
local intKickRankIndex6 = intKickRankIndex6 or 30               -- Kick Alt after this amount of days.
local intKickRankIndex7 = intKickRankIndex7 or 14               -- Kick Trial after this amount of days.
local intKickRankIndex8 = intKickRankIndex8 or 1                -- Kick Unknown after this amount of days.
local intKickRankIndex9 = intKickRankIndex9 or 1                -- Kick Unknown after this amount of days.

local TimeToPromote = TimeToPromote or 14                       -- When someone should be promoted from the trial rank (Lowest rank in the guild).

local highestRankIndex = -10                                    -- Used to find the highest Guild RankIndex (Lowest rank) in the guild.

-- ====================================================================================================
-- =                                Create frame(s) and Register event                                =
-- ====================================================================================================

local f = CreateFrame("Frame")

f:RegisterEvent("ADDON_LOADED");
f:RegisterEvent("GUILD_ROSTER_UPDATE");
f:RegisterEvent("PLAYER_GUILD_UPDATE");

-- ====================================================================================================
-- =                                          Event handler.                                          =
-- ====================================================================================================

f:SetScript("OnEvent", function()
    if (event == "ADDON_LOADED") and (arg1 == AddonName) then
        --Update the guild roster.
        GuildRoster();
        -- Get the guild name of the guild we are in, if any.
        strGuildName = GetGuildInfo("player");
        -- Unregister the event as we don't need it anymore.
        f:UnregisterEvent("ADDON_LOADED");
    elseif event == "GUILD_ROSTER_UPDATE" then
        -- DEFAULT_CHAT_FRAME:AddMessage("Run");
        -- GuildUpdateRoster()
    elseif event == "PLAYER_GUILD_UPDATE" then
        -- DEFAULT_CHAT_FRAME:AddMessage("Run again");
        -- GuildUpdateRoster()
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
        -- Update old date format to new date format.
        ConvertOldFormatToNewFormal()
        -- Get the guild name of the guild we are in, if any.
        strGuildName = GetGuildInfo("player");
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
    --local command, playerName, reason = string.match(msg, "^(ban)%s+(%S+)%s+(.+)$");

    if (command == "ban") and (playerName) and (reason) then

        -- Did we find the person in GUILD_INFO ?
        if (GUILD_INFO[playerName]) and (canGuildAction(playerName, "KICK")) then

            -- Send a message to guild about it.
            SendChatMessage("Banning " .. playerName .. " from guild.", "GUILD");
            SendChatMessage("Reason: " .. reason, "GUILD");

            -- Make sure the table is made.
            if (not GUILD_INFO_HISTORY) or (not type(GUILD_INFO_HISTORY) == "table") then
                GUILD_INFO_HISTORY = {}
            end

            -- Insert into GUILD_INFO_HISTORY
            table.insert(GUILD_INFO_HISTORY, {
                ["Message"] = date("%d-%m-%Y") .. " - The " .. GUILD_INFO[playerName]["Class"] .. " " .. Manager_ColorTheName(GUILD_INFO[playerName]["Class"], playerName) .. " (" .. GUILD_INFO[playerName]["Level"] .. ") (" .. GUILD_INFO[playerName]["Rank"] .. ") has been banned from the guild.\n    Reason: " .. reason,
                ["Who"] = playerName,
                ["Action"] = "Banned",
                ["Reason"] = reason,
                ["Class"] = GUILD_INFO[playerName]["Class"],
                ["Rank"] = GUILD_INFO[playerName]["Rank"],
                ["Guild"] = strGuildName,
                ["Date"] = date("%d-%m-%Y %H:%M:%S"),
            })

            -- Delete the person from GUILD_INFO
            -- GUILD_INFO[playerName] = nil

            -- Kick the player from the guild.
            GuildUninviteByName(playerName)
        else
            DEFAULT_CHAT_FRAME:AddMessage("The player \"" .. playerName .. "\" was not found in guild.");
        end

    elseif (msg == "") then
        ShowPopUp = true
        GuildUpdateRoster();
        frame:Show();
    else
        DEFAULT_CHAT_FRAME:AddMessage("Usage: /m+ ban PlayerName Reason");
    end
end;

-- ====================================================================================================
-- =                                  Find higheste Guild RankIndex.                                  =
-- ====================================================================================================

function FindHighestGuildRankIndex()

    local numGuildMembers = GetNumGuildMembers()

    if numGuildMembers then
        for i = 1, numGuildMembers do
            local _, _, rankIndex = GetGuildRosterInfo(i)
            if rankIndex then
                local CheckRankIndex = rankIndex
                if CheckRankIndex > highestRankIndex then
                    highestRankIndex = CheckRankIndex
                end
            end
        end
    else
        return
    end

end

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
-- =                     Check if we can do the action. (kick, demote or promote)                     =
-- ====================================================================================================

function canGuildAction(playerName, action)

    -- Set GuildControlSetRank so we can get the info from "GuildControlGetRankFlags".
    local _, _, playerRankIndex = GetGuildInfo("player")
    GuildControlSetRank(playerRankIndex + 1) -- index of the rank to select, between 1 and GuildControlGetNumRanks().

    -- Set the locals we need.
    local guildchat_listen, guildchat_speak, officerchat_listen, officerchat_speak, promote, demote, invite_member, remove_member, set_motd, edit_public_note, view_officer_note, edit_officer_note, modify_guild_info, withdraw_repair, withdraw_gold, create_guild_event, authenticator, modify_bank_tabs, remove_guild_event = GuildControlGetRankFlags();

    -- Check if we can do the action we are asked to do.
    if (action == "KICK") and (remove_member == nil) then
        return false
    elseif (action == "PROMOTE") and (promote == nil) then
        return false
    elseif (action == "DEMOTE") and (demote == nil) then
        return false
    -- We can't find what we are asked to do, so just stop here.
    elseif (action ~= "KICK") and (action ~= "PROMOTE") and (action ~= "DEMOTE") then
        DEFAULT_CHAT_FRAME:AddMessage("Error in \"canGuildAction\": " .. action or "None" .. " was called.")
        return false
    end

    local numGuildMembers = GetNumGuildMembers()
    local TargetRankIndex = nil
    local OwnName = UnitName("player")

    for i = 1, numGuildMembers do
        local name = GetGuildRosterInfo(i)
        if (name == playerName) then
            -- Get the player's guild rankIndex.
            _, _, TargetRankIndex = GetGuildRosterInfo(i);
        end
    end

    -- Check if we have both ranks and that the rank is lower then own rank.
    if ((TargetRankIndex) and (playerRankIndex)) and (playerRankIndex < TargetRankIndex) then
        -- We can kick that rank, so return true.
        return true
    else
        -- We can not kick that rank, so return false.
        return false
    end
end

-- ====================================================================================================
-- =                                     Check if it a leap year.                                     =
-- ====================================================================================================

local function isLeapYear(year)
    local dividedBy4 = (year / 4)
    local dividedBy100 = (year / 100)
    local dividedBy400 = (year / 400)

    if dividedBy4 == math.floor(dividedBy4) then
        if dividedBy100 == math.floor(dividedBy100) then
            if dividedBy400 == math.floor(dividedBy400) then
                return true
            else
                return false
            end
        else
            return true
        end
    else
        return false
    end
end

-- ====================================================================================================
-- =                             Check how many days there is in a month.                             =
-- ====================================================================================================

local function daysInMonth(month, year)
    local days = {31, isLeapYear(year) and 29 or 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
    return days[month]
end

-- ====================================================================================================
-- =                                Get the number of days in a month.                                =
-- ====================================================================================================


local function getYearMonthDay(timestamp)

    local daysSinceEpoch = math.floor(timestamp / 86400)
    local year = 1970
    local month = 1
    local day = 1

    while daysSinceEpoch >= (isLeapYear(year) and 366 or 365) do
        daysSinceEpoch = daysSinceEpoch - (isLeapYear(year) and 366 or 365)
        year = year + 1
    end

    while daysSinceEpoch >= daysInMonth(month, year) do
        daysSinceEpoch = daysSinceEpoch - daysInMonth(month, year)
        month = month + 1
    end

    day = daysSinceEpoch + 1

    return year, month, day

end

-- ====================================================================================================
-- =                                   Convert from date to seconds                                   =
-- ====================================================================================================

function getTimeDifferenceFromSeenFirst(playerName)
    -- Get the info we need.
    local dateTimeString = GUILD_INFO[playerName]["SeenFirstTime"] -- Retrieve the "SeenFirstTime" string for the player from GUILD_INFO.

    -- Check if the dateTimeString is nil (player data or SeenFirstTime not found).
    if not dateTimeString then
        -- Return nil and an error message if the data is missing.
        return nil, "Player data or SeenFirstTime not found."
    end

    -- Extract day, month, year, hour, minute, and second from the player's "SeenFirstTime" string.
    local playerDay = tonumber(string.sub(dateTimeString, 1, 2)) -- Extract the day (first two characters) and convert it to a number.
    local playerMonth = tonumber(string.sub(dateTimeString, 4, 5)) -- Extract the month (characters 4 and 5) and convert it to a number.
    local playerYear = tonumber(string.sub(dateTimeString, 7, 10)) -- Extract the year (characters 7 to 10) and convert it to a number.
    local playerHour = tonumber(string.sub(dateTimeString, 12, 13)) -- Extract the hour (characters 12 and 13) and convert it to a number.
    local playerMinute = tonumber(string.sub(dateTimeString, 15, 16)) -- Extract the minute (characters 15 and 16) and convert it to a number.
    local playerSecond = tonumber(string.sub(dateTimeString, 18, 19)) -- Extract the second (characters 18 and 19) and convert it to a number.

    -- Get the current date and time as a formatted string.
    local currentTime = date("%d-%m-%Y %H:%M:%S");

    -- Extract day, month, year, hour, minute, and second from the current time string.
    local day = tonumber(string.sub(currentTime, 1, 2)) -- Extract the current day and convert it to a number.
    local month = tonumber(string.sub(currentTime, 4, 5)) -- Extract the current month and convert it to a number.
    local year = tonumber(string.sub(currentTime, 7, 10)) -- Extract the current year and convert it to a number.
    local hour = tonumber(string.sub(currentTime, 12, 13)) -- Extract the current hour and convert it to a number.
    local minute = tonumber(string.sub(currentTime, 15, 16)) -- Extract the current minute and convert it to a number.
    local second = tonumber(string.sub(currentTime, 18, 19)) -- Extract the current second and convert it to a number.

    -- Function to calculate the total seconds from a given date and time.
    local function calculateTotalSeconds(day, month, year, hour, minute, second)
        -- Calculate seconds from hours, minutes, and seconds.
        local totalSeconds = second + minute * 60 + hour * 3600

        -- Add seconds for all days in the months before the given month.
        for i = 1, month - 1 do
            -- Add seconds for each month.
            totalSeconds = totalSeconds + daysInMonth(i, year) * 86400
        end

        -- Add seconds for the days before the given day.
        totalSeconds = totalSeconds + (day - 1) * 86400

        -- Add seconds for all years between the player's year and the current year.
        for y = playerYear, year - 1 do
            -- Add seconds for each year (leap year or not).
            totalSeconds = totalSeconds + (isLeapYear(y) and 366 or 365) * 86400
        end

        -- Return the total calculated seconds.
        return totalSeconds
    end

    -- Calculate the total seconds for the player's "SeenFirstTime".
    local playerSeconds = calculateTotalSeconds(playerDay, playerMonth, playerYear, playerHour, playerMinute, playerSecond)

    -- Calculate the total seconds for the current time.
    local currentSeconds = calculateTotalSeconds(day, month, year, hour, minute, second)

    -- Calculate the difference in seconds between the current time and the player's "SeenFirstTime".
    local secondsInGuild = currentSeconds - playerSeconds

    -- Return the calculated secondsInGuild.
    return secondsInGuild
end

-- ====================================================================================================
-- =                             Convert from seconds to a readable time.                             =
-- ====================================================================================================

local function formatTimeDifference(seconds)

    -- Check if the input seconds are negative (invalid)
    if seconds < 0 then
        return "Invalid input (seconds must be non-negative)"
    end

    -- Calculate years by dividing total seconds by seconds in a year (365 days)
    local years = math.floor(seconds / (365 * 86400))
    -- Subtract seconds consumed by years from the total
    seconds = seconds - (years * (365 * 86400))

    -- Calculate months by dividing remaining seconds by seconds in a month (30 days)
    local months = math.floor(seconds / (30 * 86400))
    -- Subtract seconds consumed by months from the remaining seconds
    seconds = seconds - (months * (30 * 86400))

    -- Calculate days by dividing remaining seconds by seconds in a day
    local days = math.floor(seconds / 86400)
    -- Subtract seconds consumed by days from the remaining seconds
    seconds = seconds - (days * 86400)

    -- Calculate hours by dividing remaining seconds by seconds in an hour
    local hours = math.floor(seconds / 3600)
    -- Subtract seconds consumed by hours from the remaining seconds
    seconds = seconds - (hours * 3600)

    -- Calculate minutes by dividing remaining seconds by seconds in a minute
    local minutes = math.floor(seconds / 60)
    -- Subtract seconds consumed by minutes from the remaining seconds
    seconds = seconds - (minutes * 60)

    -- Create a table to store the formatted time parts
    local timeParts = {}

    -- If years are greater than 0, add them to the timeParts table
    if (years > 0) then
        table.insert(timeParts, years .. " year" .. (years > 1 and "s" or ""))
    end

    -- If months are greater than 0, add them to the timeParts table
    if (months > 0) then
        table.insert(timeParts, months .. " month" .. (months > 1 and "s" or ""))
    end

    -- If days are greater than 0, add them to the timeParts table
    if (days > 0) then
        table.insert(timeParts, days .. " day" .. (days > 1 and "s" or ""))
    end

    -- If hours are greater than 0, add them to the timeParts table
    if (hours > 0) then
        table.insert(timeParts, hours .. " hour" .. (hours > 1 and "s" or ""))
    end

    -- If minutes are greater than 0, and years, months, and days are 0, add minutes to the timeParts table
    if (minutes > 0) and (years == 0) and (months == 0) and (days == 0) then
        table.insert(timeParts, minutes .. " minute" .. (minutes > 1 and "s" or ""))
    end

    -- If seconds are greater than 0, and all other time parts are 0, add seconds to the timeParts table
    if seconds > 0 and years == 0 and months == 0 and days == 0 and hours == 0 and minutes == 0 then
        table.insert(timeParts, seconds .. " second" .. (seconds > 1 and "s" or ""))
    end

    -- Return "Just now" if timeParts is empty, otherwise return the concatenated time parts with " ago"
    return next(timeParts) == nil and "Just now" or table.concat(timeParts, ", ") .. " ago"

end

-- ====================================================================================================
-- =                              Convert old date format to new format.                              =
-- =           One day this will be removed, but we have to make sure everyone have updated           =
-- ====================================================================================================

function ConvertOldFormatToNewFormal()

    -- Make sure the table is made.
    if (not GUILD_INFO) or (not type(GUILD_INFO) == "table") then
        GUILD_INFO = {}
    end

    for playerName, playerData in pairs(GUILD_INFO) do

        if (GUILD_INFO[playerName]["SeenFirstTime"]) then
            -- Get the date.
            dateTimeString = GUILD_INFO[playerName]["SeenFirstTime"]
            -- Convert the dates I startet to use to the dates I use now by checking if year is in the right place.
            -- Old date: 07/25/25 08:47:07  New date: 25-07-2025 08:47:07
            local ConvertYearCheck = string.sub(dateTimeString, 7, 10)
            -- Did we get a number ?
            if (not tonumber(ConvertYearCheck)) then
                -- Get the numbers we want to reuse.
                local OldDay = string.sub(dateTimeString, 4, 5)
                local OldMonth = string.sub(dateTimeString, 1, 2)
                local OldYear = "20" .. string.sub(dateTimeString, 7, 8) -- We put in 20 as no one is older then that as the addon is made in 2025
                local OldHour = string.sub(dateTimeString, 10, 11)
                local OldMin = string.sub(dateTimeString, 13, 14)
                local OldSec = string.sub(dateTimeString, 16, 17)
                -- Creat the new date string
                local NewDateString = OldDay .. "-" .. OldMonth .. "-" .. OldYear .. " " .. OldHour .. ":" .. OldMin .. ":" .. OldSec
                -- Update to new date.
                GUILD_INFO[playerName].SeenFirstTime = NewDateString
            end
        end
        -- 
        if (GUILD_INFO[playerName]["Updated"]) then
            -- Get the date.
            dateTimeString = GUILD_INFO[playerName]["Updated"]
            -- Convert the dates I startet to use to the dates I use now by checking if year is in the right place.
            -- Old date: 07/25/25 18:47:07  New date: 25-07-2025 18:47:07
            local ConvertYearCheck = string.sub(dateTimeString, 7, 10)
            -- Did we get a number ?
            if (not tonumber(ConvertYearCheck)) then
                -- Get the numbers we want to reuse.
                local OldDay = string.sub(dateTimeString, 4, 5)
                local OldMonth = string.sub(dateTimeString, 1, 2)
                local OldYear = "20" .. string.sub(dateTimeString, 7, 8) -- We put in 20 as no one is older then that as the addon is made in 2025
                local OldHour = string.sub(dateTimeString, 10, 11)
                local OldMin = string.sub(dateTimeString, 13, 14)
                local OldSec = string.sub(dateTimeString, 16, 17)
                -- Creat the new date string
                local NewDateString = OldDay .. "-" .. OldMonth .. "-" .. OldYear .. " " .. OldHour .. ":" .. OldMin .. ":" .. OldSec
                -- Update to new date.
                GUILD_INFO[playerName].Updated = NewDateString
            end
        end
        
    end

-- ====================================================================================================

    -- Make sure the table is made.
    if (not GUILD_INFO_HISTORY) or (not type(GUILD_INFO_HISTORY) == "table") then
        GUILD_INFO_HISTORY = {}
    end

    for playerName, playerData in pairs(GUILD_INFO_HISTORY) do

        if (GUILD_INFO_HISTORY[playerName]["OfficerNote"]) then
            -- Delete the old data.
            GUILD_INFO_HISTORY[playerName] = nil
        end
    end

-- ====================================================================================================

    -- Make sure the table is made.
    if (not BANNED_FROM_GUILD) or (not type(BANNED_FROM_GUILD) == "table") then
        BANNED_FROM_GUILD = {}
    end

    for playerName, playerData in pairs(BANNED_FROM_GUILD) do

        if (BANNED_FROM_GUILD[playerName]["SeenFirstTime"]) then
            -- Get the date.
            dateTimeString = BANNED_FROM_GUILD[playerName]["SeenFirstTime"]
            -- Convert the dates I startet to use to the dates I use now by checking if year is in the right place.
            -- Old date: 07/25/25 08:47:07  New date: 25-07-2025 08:47:07
            local ConvertYearCheck = string.sub(dateTimeString, 7, 10)
            -- Did we get a number ?
            if (not tonumber(ConvertYearCheck)) then
                -- Get the numbers we want to reuse.
                local OldDay = string.sub(dateTimeString, 4, 5)
                local OldMonth = string.sub(dateTimeString, 1, 2)
                local OldYear = "20" .. string.sub(dateTimeString, 7, 8) -- We put in 20 as no one is older then that as the addon is made in 2025
                local OldHour = string.sub(dateTimeString, 10, 11)
                local OldMin = string.sub(dateTimeString, 13, 14)
                local OldSec = string.sub(dateTimeString, 16, 17)
                -- Creat the new date string
                local NewDateString = OldDay .. "-" .. OldMonth .. "-" .. OldYear .. " " .. OldHour .. ":" .. OldMin .. ":" .. OldSec
                -- Update to new date.
                BANNED_FROM_GUILD[playerName].SeenFirstTime = NewDateString
            end
        end
        -- 
        if (BANNED_FROM_GUILD[playerName]["LeftTheGuild"]) then
            -- Get the date.
            dateTimeString = BANNED_FROM_GUILD[playerName]["LeftTheGuild"]
            -- Convert the dates I startet to use to the dates I use now by checking if year is in the right place.
            -- Old date: 07/25/25 08:47:07  New date: 25-07-2025 08:47:07
            local ConvertYearCheck = string.sub(dateTimeString, 7, 10)
            -- Did we get a number ?
            if (not tonumber(ConvertYearCheck)) then
                -- Get the numbers we want to reuse.
                local OldDay = string.sub(dateTimeString, 4, 5)
                local OldMonth = string.sub(dateTimeString, 1, 2)
                local OldYear = "20" .. string.sub(dateTimeString, 7, 8) -- We put in 20 as no one is older then that as the addon is made in 2025
                local OldHour = string.sub(dateTimeString, 10, 11)
                local OldMin = string.sub(dateTimeString, 13, 14)
                local OldSec = string.sub(dateTimeString, 16, 17)
                -- Creat the new date string
                local NewDateString = OldDay .. "-" .. OldMonth .. "-" .. OldYear .. " " .. OldHour .. ":" .. OldMin .. ":" .. OldSec
                -- Update to new date.
                BANNED_FROM_GUILD[playerName].LeftTheGuild = NewDateString
            end
        end
        -- 
        if (BANNED_FROM_GUILD[playerName]["Updated"]) then
            -- Get the date.
            dateTimeString = BANNED_FROM_GUILD[playerName]["Updated"]
            -- Convert the dates I startet to use to the dates I use now by checking if year is in the right place.
            -- Old date: 07/25/25 08:47:07  New date: 25-07-2025 08:47:07
            local ConvertYearCheck = string.sub(dateTimeString, 7, 10)
            -- Did we get a number ?
            if (not tonumber(ConvertYearCheck)) then
                -- Get the numbers we want to reuse.
                local OldDay = string.sub(dateTimeString, 4, 5)
                local OldMonth = string.sub(dateTimeString, 1, 2)
                local OldYear = "20" .. string.sub(dateTimeString, 7, 8) -- We put in 20 as no one is older then that as the addon is made in 2025
                local OldHour = string.sub(dateTimeString, 10, 11)
                local OldMin = string.sub(dateTimeString, 13, 14)
                local OldSec = string.sub(dateTimeString, 16, 17)
                -- Creat the new date string
                local NewDateString = OldDay .. "-" .. OldMonth .. "-" .. OldYear .. " " .. OldHour .. ":" .. OldMin .. ":" .. OldSec
                -- Update to new date.
                BANNED_FROM_GUILD[playerName].Updated = NewDateString
            end
        end
    end

end

-- ====================================================================================================
-- ====================================================================================================
-- =                         Gather info about the guild and look for changes                         =
-- ====================================================================================================
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
    TimeToPromoteCounter = 0

    -- Iterate through all members in the saved variable GUILD_INFO.
    for playerName, playerData in pairs(GUILD_INFO) do

        -- Check if we have the same names in both tables and it's the correct guild.
        if (GUILD_INFO[playerName]) and (ShowPopUp == true) and (not TEMP_GUILD_INFO[playerName]) and (GUILD_INFO[playerName]["GuildName"] == strGuildName) then
            -- Make sure the table is made.
            if (not GUILD_INFO_HISTORY) or (not type(GUILD_INFO_HISTORY) == "table") then
                GUILD_INFO_HISTORY = {}
            end

            -- Insert into GUILD_INFO_HISTORY
            table.insert(GUILD_INFO_HISTORY, {
                ["Message"] = date("%d-%m-%Y") .. " - The " .. playerData.Class .. " " .. Manager_ColorTheName(playerData.Class, playerName) .. " (" .. playerData.Level .. ") (" .. playerData.Rank .. ") has left the guild.",
                ["Who"] = playerName,
                ["Action"] = "Left",
                ["Reason"] = "Not set",
                ["Class"] = playerData.Class,
                ["Rank"] = playerData.Rank,
                ["Guild"] = strGuildName,
                ["Date"] = date("%d-%m-%Y %H:%M:%S"),
            })


            -- Delete the person from GUILD_INFO.
            GUILD_INFO[playerName] = nil;

            -- Count
            LeaveCounter = LeaveCounter + 1

            -- Check if it's the first line
            if (LeaveCounter == 1) then
                NewGuildActionLeft = "|cffff0000----- LEFT THE GUILD -----|r\n"
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
                    NewGuildActionPromote = "|cffff0000----- PROMOTED -----|r\n"
                end
                -- Write the text.
                NewGuildActionPromote = NewGuildActionPromote .. "The " .. playerData.Class .. " " .. Manager_ColorTheName(playerData.Class, playerName) .. " (" .. playerData.Level .. ") has been promoted from " .. playerData.Rank .. " to " .. TEMP_GUILD_INFO[playerName]["Rank"] .. ".\n"

                -- Make sure the table is made.
                if (not GUILD_INFO_HISTORY) or (not type(GUILD_INFO_HISTORY) == "table") then
                    GUILD_INFO_HISTORY = {}
                end

                -- Insert into GUILD_INFO_HISTORY
                table.insert(GUILD_INFO_HISTORY, {
                    ["Message"] = date("%d-%m-%Y") .. " - The " .. playerData.Class .. " " .. Manager_ColorTheName(playerData.Class, playerName) .. " (" .. playerData.Level .. ") has been promoted from " .. GUILD_INFO[playerName]["Rank"] .. " to " .. TEMP_GUILD_INFO[playerName]["Rank"] .. ".",
                    ["Who"] = playerName,
                    ["Action"] = "Promote",
                    ["Reason"] = "Not set",
                    ["Class"] = playerData.Class,
                    ["Rank"] = TEMP_GUILD_INFO[playerName]["Rank"],
                    ["Guild"] = strGuildName,
                    ["Date"] = date("%d-%m-%Y %H:%M:%S"),
                })

                -- Update GUILD_INFO
                GUILD_INFO[playerName].Rank = TEMP_GUILD_INFO[playerName]["Rank"]
                GUILD_INFO[playerName].RankIndex = TEMP_GUILD_INFO[playerName]["RankIndex"]
                GUILD_INFO[playerName].Updated = date("%d-%m-%Y %H:%M:%S")

            -- Is the new RankIndex from TEMP_GUILD_INFO higher than the RankIndex in GUILD_INFO ? (Higher is demote, Guild Master is RankIndex 0)
            elseif (TEMP_GUILD_INFO[playerName]["RankIndex"] > GUILD_INFO[playerName]["RankIndex"]) then
                -- Count
                DemoteCounter = DemoteCounter + 1
                -- Make the headline.
                if (DemoteCounter == 1) then
                    NewGuildActionDemote = "|cffff0000----- DEMOTED -----|r\n"
                end
                -- Write the text
                NewGuildActionDemote = NewGuildActionDemote .. "The " .. playerData.Class .. " " .. Manager_ColorTheName(playerData.Class, playerName) .. " (" .. playerData.Level .. ") has been demoted from " .. playerData.Rank .. " to " .. TEMP_GUILD_INFO[playerName]["Rank"] .. ".\n"

                -- Make sure the table is made.
                if (not GUILD_INFO_HISTORY) or (not type(GUILD_INFO_HISTORY) == "table") then
                    GUILD_INFO_HISTORY = {}
                end

                -- Insert into GUILD_INFO_HISTORY
                table.insert(GUILD_INFO_HISTORY, {
                    ["Message"] = date("%d-%m-%Y") .. " - The " .. playerData.Class .. " " .. Manager_ColorTheName(playerData.Class, playerName) .. " (" .. playerData.Level .. ") has been demoted from " .. GUILD_INFO[playerName]["Rank"] .. " to " .. TEMP_GUILD_INFO[playerName]["Rank"] .. ".",
                    ["Who"] = playerName,
                    ["Action"] = "Demote",
                    ["Reason"] = "Not set",
                    ["Class"] = playerData.Class,
                    ["Rank"] = TEMP_GUILD_INFO[playerName]["Rank"],
                    ["Guild"] = strGuildName,
                    ["Date"] = date("%d-%m-%Y %H:%M:%S"),
                })

                -- Update GUILD_INFO
                GUILD_INFO[playerName].Rank = TEMP_GUILD_INFO[playerName]["Rank"]
                GUILD_INFO[playerName].RankIndex = TEMP_GUILD_INFO[playerName]["RankIndex"]
                GUILD_INFO[playerName].Updated = date("%d-%m-%Y %H:%M:%S")

            end
        end

-- ================================== Is it time to promote someone? ==================================

        -- Has someone been in the guild for the amount of days there is requred to be promoted ?
        if (ShowPopUp == true) and (canGuildAction(playerName, "PROMOTE")) and (GUILD_INFO[playerName]) and (GUILD_INFO[playerName]["GuildName"] == strGuildName) then
            -- Get the seconds the person has been in guild
            SecondsJoin = tonumber(getTimeDifferenceFromSeenFirst(playerName))
            -- Set highest Guild RankIndex (Lowest rank) in the guild.
            if (highestRankIndex < 0) then
                FindHighestGuildRankIndex()
            end
            -- Check if it's lowest rank and that the person has been offline less the 4 days.
            if (GUILD_INFO[playerName]["RankIndex"] == highestRankIndex) and (TEMP_GUILD_INFO[playerName]["Offline"] <= 4) then
                -- Calculate if it's someone there have been in the guild long enough time.
                if ((SecondsJoin / 86400) >= TimeToPromote) then
                    -- Count
                    TimeToPromoteCounter = TimeToPromoteCounter + 1
                    -- Mahe headline.
                    if (TimeToPromoteCounter == 1) then
                        NewGuildActionTimeToPromote = "|cffff0000----- TIME TO PROMOTE -----|r\n"
                    end
                    -- Write the text.
                    NewGuildActionTimeToPromote = NewGuildActionTimeToPromote .. "The " .. playerData.Class .. " " .. Manager_ColorTheName(playerData.Class, playerName) .. " (" .. playerData.Level .. ") joined the guild " .. formatTimeDifference(SecondsJoin).. ".\n"
                    SecondsJoin = nil
                end
            end
        end

-- ====================================== Did someone level up ? ======================================

        -- Did player level change and is it someone from this guild ?
        if ((GUILD_INFO[playerName]) and (TEMP_GUILD_INFO[playerName])) and (ShowPopUp == true) and (GUILD_INFO[playerName]["Level"] ~= TEMP_GUILD_INFO[playerName]["Level"]) and (GUILD_INFO[playerName]["GuildName"] == strGuildName) then
            -- Update GUILD_INFO
            GUILD_INFO[playerName].Level = TEMP_GUILD_INFO[playerName]["Level"]
            GUILD_INFO[playerName].Updated = date("%d-%m-%Y %H:%M:%S")
        end

-- ===================================== Did public note change ? =====================================

        -- Did the Public note change and is it someone from this guild ?
        if ((GUILD_INFO[playerName]) and (TEMP_GUILD_INFO[playerName])) and (ShowPopUp == true) and (GUILD_INFO[playerName]["PublicNote"] ~= TEMP_GUILD_INFO[playerName]["PublicNote"]) and  (GUILD_INFO[playerName]["GuildName"] == strGuildName) then
            -- Update GUILD_INFO
            GUILD_INFO[playerName].PublicNote = TEMP_GUILD_INFO[playerName]["PublicNote"]
            GUILD_INFO[playerName].Updated = date("%d-%m-%Y %H:%M:%S")
        end

-- ===================================== Did officer note change? =====================================

        -- Did officer note change and is it someone from this guild ?
        if ((GUILD_INFO[playerName]) and (TEMP_GUILD_INFO[playerName])) and (GUILD_INFO[playerName]["OfficerNote"] ~= TEMP_GUILD_INFO[playerName]["OfficerNote"]) and (GUILD_INFO[playerName]["GuildName"] == strGuildName) then
            -- Count
            OfficerNoteCounter = OfficerNoteCounter + 1

            -- Make the headline.
            if (OfficerNoteCounter == 1) then
                NewGuildActionOfficerNote = "|cffff0000----- OFFICER NOTE CHANGED -----|r\n"
            end
            -- Write the text.
            NewGuildActionOfficerNote = NewGuildActionOfficerNote .. "The Officer note for " .. Manager_ColorTheName(playerData.Class, playerName) .. " has been changed.\n      From: \"" .. GUILD_INFO[playerName]["OfficerNote"] .. "\"\n      To: \"" .. TEMP_GUILD_INFO[playerName]["OfficerNote"] .. "\".\n"
            -- Update GUILD_INFO
            GUILD_INFO[playerName].OfficerNote = TEMP_GUILD_INFO[playerName]["OfficerNote"]
            GUILD_INFO[playerName].Updated = date("%d-%m-%Y %H:%M:%S")
        end

-- ============================== Has someone been offline for to long ? ==============================

        -- We need to check everyone in the guild, so we start with checking that it is someone from the guild.
        if (canGuildAction(playerName, "KICK")) and ((GUILD_INFO[playerName]) and (TEMP_GUILD_INFO[playerName])) and (ShowPopUp == true) and (GUILD_INFO[playerName]["GuildName"] == strGuildName) then
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
                -- Update everything in GUILD_INFO there is not updated anyware else.
                -- Might seems stupid, but in Turtle WoW you can change class for example.
                GUILD_INFO[playerName].GuildName = strGuildName
                GUILD_INFO[playerName].Class = TEMP_GUILD_INFO[playerName]["Class"]
                GUILD_INFO[playerName].Updated = date("%d-%m-%Y %H:%M:%S")
            end

            -- Did we find someone ?
            if (FoundSomeone == true) then
                -- Count
                KickCounter = KickCounter + 1

                -- Make the headline.
                if (KickCounter == 1) then
                    NewGuildActionKick = "|cffff0000----- TIME TO KICK -----|r\n"
                end
                -- Write the text.
                NewGuildActionKick = NewGuildActionKick .. "The " .. playerData.Class .. " " .. Manager_ColorTheName(playerData.Class, playerName) .. " (" .. playerData.Level .. ") (" .. playerData.Rank .. ") has been offline for " .. math.floor(TEMP_GUILD_INFO[playerName]["Offline"]) .. " days.\n"
                -- Update GUILD_INFO
                GUILD_INFO[playerName].Offline = TEMP_GUILD_INFO[playerName]["Offline"]
                GUILD_INFO[playerName].Updated = date("%d-%m-%Y %H:%M:%S")
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
            -- Make sure the table is made.
            if (not BANNED_FROM_GUILD) or (not type(BANNED_FROM_GUILD) == "table") then
                BANNED_FROM_GUILD = {}
            end
            -- Check if it a person there is banned from the guild, if so, then inform and kick.
            if (BANNED_FROM_GUILD[playerName]) and (canGuildAction(BANNED_FROM_GUILD[playerName], "KICK")) then
                -- Get a date people understand.
                local TimeStamp = BANNED_FROM_GUILD[playerName]["LeftTheGuild"]
                local FormatedTimeStamp
                -- if TimeStamp then
                    -- FormatedTimeStamp = date("%d-%B-%Y", TimeStamp)
                -- end

                -- Send a message to guild about it.
                SendChatMessage(playerName .. " was banned from the guild on " .. TimeStamp, "GUILD");
                SendChatMessage("Reason: " .. BANNED_FROM_GUILD[playerName]["BanReason"], "GUILD");
                SendChatMessage("That is why " .. playerName .. " is kicked again.", "GUILD");
                GuildUninviteByName(playerName)

            -- The person was not banned, add to GUILD_INFO.
            else
                -- Only do it if we want to show it.
                if (ShowPopUp == true) then
                    -- 
                    GUILD_INFO[playerName] = {
                        ["GuildName"] = strGuildName,
                        ["SeenFirstTime"] = date("%d-%m-%Y %H:%M:%S"),
                        ["Rank"] = TEMP_GUILD_INFO[playerName]["Rank"],
                        ["RankIndex"] = TEMP_GUILD_INFO[playerName]["RankIndex"],
                        ["Level"] = TEMP_GUILD_INFO[playerName]["Level"],
                        ["Class"] = TEMP_GUILD_INFO[playerName]["Class"],
                        ["PublicNote"] = TEMP_GUILD_INFO[playerName]["PublicNote"],
                        ["OfficerNote"] = TEMP_GUILD_INFO[playerName]["OfficerNote"],
                        ["Offline"] = TEMP_GUILD_INFO[playerName]["Offline"],
                        ["Updated"] = date("%d-%m-%Y %H:%M:%S"),
                    };

                    -- Make sure the table is made.
                    if (not GUILD_INFO_HISTORY) or (not type(GUILD_INFO_HISTORY) == "table") then
                        GUILD_INFO_HISTORY = {}
                    end

                    -- Insert into GUILD_INFO_HISTORY
                    table.insert(GUILD_INFO_HISTORY, {
                        ["Message"] = date("%d-%m-%Y") .. " - The " .. TEMP_GUILD_INFO[playerName]["Class"] .. " " .. Manager_ColorTheName(TEMP_GUILD_INFO[playerName]["Class"], playerName) .. " (" .. TEMP_GUILD_INFO[playerName]["Level"] .. ") (" .. TEMP_GUILD_INFO[playerName]["Rank"] .. ") has joined the guild.",
                        ["Who"] = playerName,
                        ["Action"] = "Joined",
                        ["Reason"] = "Not set",
                        ["Class"] = TEMP_GUILD_INFO[playerName]["Class"],
                        ["Rank"] = TEMP_GUILD_INFO[playerName]["Rank"],
                        ["Guild"] = strGuildName,
                        ["Date"] = date("%d-%m-%Y %H:%M:%S"),
                    })

                    -- Check that join date have been added to Officer note.
                    -- if (TEMP_GUILD_INFO[playerName]["OfficerNote"] == nil) then
                        -- GuildRosterSetOfficerNote(i, date("%d-%m-%Y"));
                    -- end

                    -- Count
                    JoinCounter = JoinCounter + 1

                    -- Check if it's the first line
                    if (JoinCounter == 1) then
                        NewGuildActionJoin = "|cffff0000----- JOINED THE GUILD -----|r\n"
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

    -- Make the text, if there is something to make.
    MakeTheNewsText()

    -- Make the history text.
    MakeTheHistoryText()

end

-- ====================================================================================================
-- =                                    Put all news text together                                    =
-- ====================================================================================================

function MakeTheNewsText(LinesTotal)

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
    -- Is it time to promote some from Trial (Lowest rank ?
    if (NewGuildActionTimeToPromote) then
        if (NewGuildAction) then
            NewGuildAction = NewGuildAction .. NewGuildActionTimeToPromote
        else
            NewGuildAction = NewGuildActionTimeToPromote
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
    if (ShowPopUp == false) and (NewGuildActionOfficerNote) and (NewGuildActionLeft == nil) and (NewGuildActionJoin == nil) and (NewGuildActionPromote == nil) and (NewGuildActionDemote == nil) and (NewGuildActionKick == nil) and (NewGuildActionTimeToPromote == nil) then
        -- Print in chat that the info about Officer note changed.
        DEFAULT_CHAT_FRAME:AddMessage(NewGuildAction);
    elseif (ShowPopUp == true) and (NewGuildAction) then
        -- Set the text and the size of the scroll frame.
        newsText:SetText(NewGuildAction);
        ManagerPlusNews:SetHeight(TotalCountedLines); -- Make it taller than the scrollframe for scrolling
        frame:Show();
        -- Don't show the popup anymore this login unless we do a /m+
        ShowPopUp = false
    end

    -- Clear all data so we don't use old info.
    NewGuildActionLeft = nil
    NewGuildActionJoin = nil
    NewGuildActionPromote = nil
    NewGuildActionDemote = nil
    NewGuildActionKick = nil
    NewGuildActionOfficerNote = nil
    NewGuildActionTimeToPromote = nil

end

-- ====================================================================================================
-- =                                  Put the history text together.                                  =
-- ====================================================================================================

function MakeTheHistoryText()

    -- Make sure the table is made.
    if (not GUILD_INFO_HISTORY) or (not type(GUILD_INFO_HISTORY) == "table") then
        GUILD_INFO_HISTORY = {}
    end

    -- Count
    local HistoryLineCount = 0

    -- Local
    local NewHistoryText = nil
    local SetTextCount = 0

    -- Get the length of the table.
    local tableLength = 0

    for _, _ in pairs(GUILD_INFO_HISTORY) do
        tableLength = tableLength + 1
    end

    -- Loop through the GUILD_INFO_HISTORY in reversed order so we get new first.
    for i = tableLength, 1, -1 do
        local playerData = GUILD_INFO_HISTORY[i];
        -- Check that it's info from current guild.
        if (playerData["Guild"] == strGuildName) then
            -- +1 to counter
            HistoryLineCount = HistoryLineCount + 1
            -- Check if NewHistoryText is nil and SetTextCount = 0, then we set a headline and the text.
            if (not NewHistoryText) and (SetTextCount == 0) then
                NewHistoryText = "----- GUILD HISTORY -----\n" .. playerData["Message"] .. "\n"
            -- Check if NewHistoryText is nil and SetTextCount ~ 0, then we set the text.
            elseif (not NewHistoryText) and (SetTextCount ~= 0) then
                NewHistoryText = playerData["Message"] .. "\n"
            -- Else we just add text to NewHistoryText
            else
                NewHistoryText = NewHistoryText .. playerData["Message"] .. "\n"
            end

            -- Check that we don't get to many lines. (Maybe 80 have to be less, but now we try with 80 first)
            if (HistoryLineCount >= 80) then
                -- 
                if (SetTextCount == 0) then
                    -- Set the text for the first FontString.
                    historyText:SetText(NewHistoryText);
                elseif (SetTextCount == 1) then
                    -- Check is the FontString is already made, we don't wan't to create to many if we don't need.
                    if not historyText[SetTextCount] then
                        historyText[SetTextCount] = ManagerPlusHistory:CreateFontString(nil, "OVERLAY", "GameFontNormal");
                    end
                    historyText[SetTextCount]:SetPoint("TOPLEFT", historyText, "BOTTOMLEFT", 0, 0);
                    historyText[SetTextCount]:SetText(NewHistoryText);
                    historyText[SetTextCount]:SetJustifyH("LEFT");
                -- 
                else
                    -- Check is the FontString is already made, we don't wan't to create to many if we don't need.
                    if not historyText[SetTextCount] then
                        historyText[SetTextCount] = ManagerPlusHistory:CreateFontString(nil, "OVERLAY", "GameFontNormal");
                    end
                    historyText[SetTextCount]:SetPoint("TOPLEFT", historyText[SetTextCount - 1], "BOTTOMLEFT", 0, 0);
                    historyText[SetTextCount]:SetText(NewHistoryText);
                    historyText[SetTextCount]:SetJustifyH("LEFT");
                end
                -- Set HistoryLineCount to 1, not 0, else we just get another headline.
                HistoryLineCount = 1
                -- Empty the NewHistoryText so we can add more.
                NewHistoryText = nil
                -- Add 1 to the counter
                SetTextCount = SetTextCount + 1
            end

            -- TotalCountedLines
            TotalCountedLines = TotalCountedLines + 1
    
        end
    end

    -- Did we find any history ?
    if (NewHistoryText) and (SetTextCount == 0) then
        historyText:SetText(NewHistoryText);
    elseif (not NewHistoryText) and (SetTextCount == 0) then
        historyText:SetText("No \"History\" yet.");
    end

    -- As history will be the biggest we set the scroll value here.
    ManagerPlusScrollbar:SetMinMaxValues(0, (TotalCountedLines * 10));
    ManagerPlusHistory:SetHeight(TotalCountedLines * 10);

end

-- ====================================================================================================
-- =                                          The interface.                                          =
-- ====================================================================================================

-- Some locals
local NewScrollValue = 0
local lastClickedButton = nil -- Track the last clicked button

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
frame:Hide()


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
scrollframe:SetPoint("BOTTOMRIGHT", -26, 10);
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
-- ManagerPlusScrollbar:SetMinMaxValues(0, 1000);
ManagerPlusScrollbar:Show();

-- Create the content frames
ManagerPlusNews = CreateFrame("Frame", nil, scrollframe);
ManagerPlusNews:SetWidth(frame:GetWidth() - 20); -- Adjust as needed
ManagerPlusNews:SetPoint("TOPLEFT", scrollframe, "TOPLEFT", 0, 0)
ManagerPlusNews:SetPoint("BOTTOMRIGHT", scrollframe, "BOTTOMRIGHT", 0, 0)
scrollframe:SetScrollChild(ManagerPlusNews);
scrollframe:SetVerticalScroll(0);
NewScrollValue = 0;

ManagerPlusHistory = CreateFrame("Frame", nil, scrollframe);
ManagerPlusHistory:SetWidth(frame:GetWidth() - 20); -- Adjust as needed
ManagerPlusHistory:SetPoint("TOPLEFT", scrollframe, "TOPLEFT", 0, 0)
ManagerPlusHistory:SetPoint("BOTTOMRIGHT", scrollframe, "BOTTOMRIGHT", 0, 0)
ManagerPlusHistory:Hide();

ManagerPlusRaid = CreateFrame("Frame", nil, scrollframe);
ManagerPlusRaid:SetWidth(frame:GetWidth() - 20); -- Adjust as needed
ManagerPlusRaid:SetHeight(1000);
ManagerPlusRaid:SetPoint("TOPLEFT", scrollframe, "TOPLEFT", 0, 0)
ManagerPlusRaid:SetPoint("BOTTOMRIGHT", scrollframe, "BOTTOMRIGHT", 0, 0)
ManagerPlusRaid:Hide();

ManagerPlusSettings = CreateFrame("Frame", nil, scrollframe);
ManagerPlusSettings:SetWidth(frame:GetWidth() - 20); -- Adjust as needed
ManagerPlusSettings:SetHeight(1000);
ManagerPlusSettings:SetPoint("TOPLEFT", scrollframe, "TOPLEFT", 0, 0)
ManagerPlusSettings:SetPoint("BOTTOMRIGHT", scrollframe, "BOTTOMRIGHT", 0, 0)
ManagerPlusSettings:Hide();

ManagerPlusAbout = CreateFrame("Frame", nil, scrollframe);
ManagerPlusAbout:SetWidth(frame:GetWidth() - 20); -- Adjust as needed
ManagerPlusAbout:SetHeight(1000);
ManagerPlusAbout:SetPoint("TOPLEFT", scrollframe, "TOPLEFT", 0, 0)
ManagerPlusAbout:SetPoint("BOTTOMRIGHT", scrollframe, "BOTTOMRIGHT", 0, 0)
ManagerPlusAbout:Hide();

-- Mouse scrolling
scrollframe:SetScript("OnMouseWheel", function()
    local maxScrollOffset = scrollframe:GetVerticalScrollRange();
    if (NewScrollValue == nil) then
        NewScrollValue = 0
    end
    if (arg1 == 1) then
        NewScrollValue = NewScrollValue - 20
    else
        NewScrollValue = NewScrollValue + 20
    end
    if (NewScrollValue <= 0) then
        NewScrollValue = 0
    elseif (NewScrollValue >= maxScrollOffset) then
        NewScrollValue = maxScrollOffset
    end
    if (maxScrollOffset > 0) then
        ManagerPlusScrollbar:SetValue(NewScrollValue);
    else
        ManagerPlusScrollbar:SetValue(0);
        ManagerPlusScrollbar:Hide();
    end
end)

-- Create a button-like frame below the main frame
local buttonWidth = 80;
local buttonHeight = 30;
local buttonSpacing = 5;

-- Function to create a button
local function createButton(name, xOffset, contentFrame)
    local button = CreateFrame("Frame", name, frame);
    button:SetWidth(buttonWidth);
    button:SetHeight(buttonHeight);
    button:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", xOffset, buttonSpacing);

    button:SetBackdrop({
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
    button:SetBackdropColor(0, 0, 0, 0.9);
    button:EnableMouse(true);

    local buttonText = button:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    buttonText:SetText(name);
    buttonText:SetPoint("CENTER", 0, 0);

    button:SetScript("OnEnter", function()
        if lastClickedButton ~= button then
            button:SetBackdropColor(0.3, 0.3, 0.3);
        end
    end);

    button:SetScript("OnLeave", function()
        if lastClickedButton ~= button then
            button:SetBackdropColor(0, 0, 0, 0.9);
        end
    end);

    button:SetScript("OnMouseDown", function()
        if (lastClickedButton) and (lastClickedButton ~= button) then
            lastClickedButton:SetBackdropColor(0, 0, 0, 0.9);
        end
        button:SetBackdropColor(0.3, 0.3, 0.3);
        lastClickedButton = button;

        -- Show the associated content frame and hide others
        ManagerPlusNews:Hide();
        ManagerPlusHistory:Hide();
        ManagerPlusRaid:Hide();
        ManagerPlusSettings:Hide();
        ManagerPlusAbout:Hide();

        if (contentFrame) then
            contentFrame:ClearAllPoints()
            contentFrame:SetPoint("TOPLEFT", scrollframe, "TOPLEFT", 0, 0)
            contentFrame:SetPoint("BOTTOMRIGHT", scrollframe, "BOTTOMRIGHT", 0, 0)
            scrollframe:SetScrollChild(contentFrame);
            scrollframe:SetVerticalScroll(0);
            NewScrollValue = 0;
            ManagerPlusScrollbar:SetValue(0);
            contentFrame:Show();
        end

    end);

    button:SetScript("OnMouseUp", function()
        
    end);

    return button;
end

-- Create the buttons with different content
local button1 = createButton("News", 0, ManagerPlusNews);
local button2 = createButton("History", buttonWidth - 4, ManagerPlusHistory);
local button3 = createButton("Raid", (buttonWidth * 2) - 8, ManagerPlusRaid);
local button4 = createButton("Settings", (buttonWidth * 3) - 12, ManagerPlusSettings);
local button5 = createButton("About", (buttonWidth * 4) - 16, ManagerPlusAbout);

-- Give first button a color so it looks like it has been clicked.
if (not lastClickedButton) then
    lastClickedButton = button1
    if (button1) then
        lastClickedButton:SetBackdropColor(0.3, 0.3, 0.3);
    end
end

-- ====================================================================================================
-- =                                             News tab                                             =
-- ====================================================================================================

newsText = ManagerPlusNews:CreateFontString(nil, "OVERLAY", "GameFontNormal");
newsText:SetPoint("TOPLEFT", ManagerPlusNews, "TOPLEFT", 5, -2);
newsText:SetJustifyH("LEFT");

-- ====================================================================================================
-- =                                           History tab.                                           =
-- ====================================================================================================

historyText = ManagerPlusHistory:CreateFontString(nil, "OVERLAY", "GameFontNormal");
historyText:SetPoint("TOPLEFT", ManagerPlusHistory, "TOPLEFT", 5, -2);
historyText:SetJustifyH("LEFT");

-- ====================================================================================================
-- =                                             Raid tab                                             =
-- ====================================================================================================

local raidText = ManagerPlusRaid:CreateFontString(nil, "OVERLAY", "GameFontNormal");
raidText:SetPoint("TOP", ManagerPlusRaid, "TOP", 5, -2);
raidText:SetText("GUILD RAID SETTINGS");
raidText:SetJustifyH("CENTER");

-- ====================================================================================================
-- =                                           Settings tab                                           =
-- ====================================================================================================

local settingsText = ManagerPlusSettings:CreateFontString(nil, "OVERLAY", "GameFontNormal");
settingsText:SetPoint("TOPLEFT", ManagerPlusSettings, "TOPLEFT", 5, -2);
settingsText:SetText("No \"Settings\" yet, but will come.");
settingsText:SetJustifyH("LEFT");

-- ====================================================================================================
-- =                                            About tab.                                            =
-- ====================================================================================================

local aboutText = ManagerPlusAbout:CreateFontString(nil, "OVERLAY", "GameFontNormal");
aboutText:SetPoint("TOPLEFT", ManagerPlusAbout, "TOPLEFT", 5, -2);
aboutText:SetText("Manager+ by Sybby - Version " .. AddonVersion .. ".");
aboutText:SetJustifyH("LEFT");



-- ====================================================================================================
-- ====================================================================================================
-- =                                            TEST AREA                                             =
-- =                             DON'T EXPECT ANYTHING TO WORK BELOW HERE                             =
-- ====================================================================================================
-- ====================================================================================================
























