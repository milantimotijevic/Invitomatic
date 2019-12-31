-- Declare addon-scope variables
local roster = {};
local location = nil;
local minLevel = nil;

-- Util methods
local splitStr = function (inputstr, sep)
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

local updateRoster = function()
    local numMembers = GetNumGuildMembers();

    for i = 1, numMembers, 1 do
        local nameWithServer, rank, rankIndex, level = GetGuildRosterInfo(i);
        local name = splitStr(nameWithServer, "-")[1]
        roster[name] = level;
    end
end

local convertIfNeeded = function()
	if IsInRaid("LE_PARTY_CATEGORY_HOME") then
		do return end
	end

	if (string.match(string.lower(location), "raid") and IsInGroup("LE_PARTY_CATEGORY_HOME")) then
		ConvertToRaid();
	end
end

-- Declare frame
local f = CreateFrame("Frame");
-- Declare slash command
SLASH_INVITOMATIC1 = "/invitomatic"
-- Declare slash handler
SlashCmdList["INVITOMATIC"] = function(inp)
    local payload = splitStr(inp, " ");

    if payload[1] == nil then
		if location ~= nil then
			--f:UnregisterEvent("CHAT_MSG_WHISPER");
            f:UnregisterEvent("CHAT_MSG_GUILD");
			f:SetScript("OnEvent", nil);
            SendChatMessage("INVITOMATIC: disabled auto invites for " .. location, "GUILD");
            location = nil;
            minLevel = nil;
        end
        do return end
    end

    location = payload[1];
    minLvl = tonumber(payload[2]);

    if (minLvl ~= nil and minLvl < 1) then
        minLvl = 1;
    end

    if (minLvl ~= nil and minLvl > 60) then
        minLvl = 60;
    end


	--f:RegisterEvent("CHAT_MSG_WHISPER");
    f:RegisterEvent("CHAT_MSG_GUILD");
    f:SetScript("OnEvent", function(self, event, msg, author, language, lineId, senderGUID)
		local msgLower = string.lower(msg);
		if (msgLower == "inv" or msgLower == "invite") then
            -- Validate player level
			if minLvl then
				updateRoster();
                local playerLevel = roster[senderGUID];
                if (playerLevel == nil or playerLevel < minLvl) then
                    do return end
                end
			end
			convertIfNeeded();
            InviteUnit(senderGUID);
        end

    end)

    local affix = ". ";
    if minLvl then
        affix = affix .. "Min level " .. minLvl .. ". ";
	end
    SendChatMessage("INVITOMATIC: LFM for " .. location .. affix .. "Type inv for auto invite", "GUILD");
end
