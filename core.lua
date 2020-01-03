-- Declare addon-scope variables
local roster = {};
local location = nil;
local minLevel = nil;
local roles = false;
local heal = nil;
local dps = nil;
local tank = nil;

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
        local name = splitStr(nameWithServer, "-")[1];
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

local extractRoles = function(rolesArg)
    if rolesArg == nil then return end

    local rolesPayload = splitStr(rolesArg, "/");
    heal = tonumber(rolesPayload[1]);
    dps = tonumber(rolesPayload[2]);
    tank = tonumber(rolesPayload[3]);

    if heal ~= nil and dps ~= nil and tank ~= nil then
        roles = true;
    end
end


local reset = function()
    location = nil;
    minLevel = nil;
    roles = false;
    heal = nil;
    dps = nil;
    tank = nil;
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
			f:UnregisterEvent("CHAT_MSG_WHISPER");
            --f:UnregisterEvent("CHAT_MSG_GUILD");
            f:SetScript("OnEvent", nil);
            print("INVITOMATIC: disabled auto invites for " .. location);
            --SendChatMessage("INVITOMATIC: disabled auto invites for " .. location, "GUILD");
            reset();
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

    extractRoles(payload[3]);

	f:RegisterEvent("CHAT_MSG_WHISPER");
    --f:RegisterEvent("CHAT_MSG_GUILD");
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
    local rolesAffix = "";
    local minLvlAffix = "";
    local invAffix = "Type inv for auto invite";

    if roles then
        rolesAffix = "Need " .. heal .. " heal, " .. dps .. " dps and " .. tank .. " tank. ";
        invAffix = "Type inv heal/dps/tank (PICK ONE) for auto invite";
    end

    if minLvl then
        minLvlAffix = "Min level " .. minLvl .. ". ";
    end
    print("INVITOMATIC: LFM for " .. location .. ". " .. rolesAffix .. minLvlAffix .. invAffix);
    --SendChatMessage("INVITOMATIC: LFM for " .. location .. affix .. "Type inv for auto invite", "GUILD");
end
