local function createHistoryText(parentFrame, counter)
    local fontStringName = "historyText" .. (counter > 0 and tostring(math.floor((counter - 1) / 80)) or ""); -- Generate fontstring name
    local fontString = parentFrame:CreateFontString(fontStringName, "OVERLAY", "GameFontNormal");
    fontString:SetJustifyH("LEFT");

    if counter <= 80 then
        fontString:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 5, -2);
    else
        local previousFontStringName = "historyText" .. tostring(math.floor((counter - 81) / 80));
        local previousFontString = parentFrame[previousFontStringName]; -- Access by name
        if previousFontString then
            fontString:SetPoint("TOPLEFT", previousFontString, "BOTTOMLEFT", 0, 0);
        else
            -- Handle the case where the previous FontString doesn't exist.
            print("Error: Previous FontString not found for counter " .. counter);
            fontString:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 5, -2); --Fallback.
        end
    end

    return fontString;
end

-- Example usage:
local ManagerPlusHistory = CreateFrame("Frame", "ManagerPlusHistory", UIParent); --Example frame.
local historyFontStrings = {}; -- Keep track of created FontStrings

-- Loop to create multiple historyText FontStrings
for i = 1, 300, 80 do --Example loop.
    for j = i, math.min(i + 79, 300) do
        local newFontString = createHistoryText(ManagerPlusHistory, j);
        table.insert(historyFontStrings, newFontString);
    end
end

-- Example usage to add text to the fontstrings.
for i = 1, #historyFontStrings do
    historyFontStrings[i]:SetText("This is text for FontString " .. i);
}







function HistoryText()

    -- Make sure the table is made.
    if (not GUILD_INFO_HISTORY) or (not type(GUILD_INFO_HISTORY) == "table") then
        GUILD_INFO_HISTORY = {}
    end

    -- Count
    local HistoryLineCount = 0

    -- Local
    local NewHistoryText = nil
    local SetTextCount = 0

    -- Loop through the GUILD_INFO_HISTORY
    for i, playerData in ipairs(GUILD_INFO_HISTORY) do
        -- Check that it's info from current guild.
        if (playerData["Guild"] == strGuildName) then
            -- +1 to counter
            HistoryLineCount = HistoryLineCount + 1
            -- Check if NewHistoryText is nil or not.
            if (not NewHistoryText) and (SetTextCount == 0) then
                NewHistoryText = playerData["Message"] .. "\n"
            else
                NewHistoryText = NewHistoryText .. playerData["Message"] .. "\n"
            end

            -- Check that we don't get to many lines.
            if (HistoryLineCount >= 80) then
                -- 
                if (SetTextCount == 0) then
                    -- Set the text for the first.
                    historyText:SetText(NewHistoryText);
                elseif (SetTextCount = 1) then
                    -- 
                    historyText:SetText(NewHistoryText);
                    -- 
                    historyText[SetTextCount] = ManagerPlusHistory:CreateFontString(nil, "OVERLAY", "GameFontNormal");
                    historyText[SetTextCount]:SetPoint("TOPLEFT", historyText, "BOTTOMLEFT", 0, 0);
                    historyText[SetTextCount]:SetText(NewHistoryText);
                    historyText[SetTextCount]:SetJustifyH("LEFT");
                    NewHistoryText = nil
                -- 
                elseif (SetTextCount > 1) then
                    historyText[SetTextCount] = ManagerPlusHistory:CreateFontString(nil, "OVERLAY", "GameFontNormal");
                    historyText[SetTextCount]:SetPoint("TOPLEFT", historyText[SetTextCount], "BOTTOMLEFT", 0, 0);
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
        end
    end

    -- Did we find any history ?
    if (NewHistoryText) then
        historyText:SetText(NewHistoryText);
    else
        historyText:SetText("No \"History\" yet..");
    end

end






































