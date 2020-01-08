-- Declare constants
local classRoles = {
    warrior = {"tank", "dps"},
    mage = {"dps"},
    shaman = {"dps, heal"},
    paladin = {"dps", "heal", "tank"},
    druid = {"dps", "heal", "tank"},
    priest = {"dps", "heal"},
    hunter = {"dps"},
    warlock = {"dps"},
    rogue = {"dps"}
};

-- Declare addon-scope variables
local roster = {};
local location = nil;
local minLevel = nil;
local roles = {
    enabled = false,
    heal = 0,
    dps = 0,
    tank = 0
};

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
        local nameWithServer, rank, rankIndex, level, class = GetGuildRosterInfo(i);
        local name = splitStr(nameWithServer, "-")[1];
        roster[name] = { level = level, class = class };
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
    roles.heal = tonumber(rolesPayload[1]);
    roles.dps = tonumber(rolesPayload[2]);
    roles.tank = tonumber(rolesPayload[3]);

    if roles.heal ~= nil and roles.dps ~= nil and roles.tank ~= nil then
        roles.enabled = true;
    end
end

local function tableHasValue (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

local reset = function()
    location = nil;
    minLevel = nil;
    roles.enabled = false;
    roles.heal = 0;
    roles.dps = 0;
    roles.tank = 0;
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
        local splitMsgLower = splitStr(msgLower, " ");
        local playerCommand = splitMsgLower[1];
		if (playerCommand == "inv" or playerCommand == "invite") then
            -- Validate player level
			if minLvl then
				updateRoster();
                local playerLevel = roster[senderGUID].level;
                if (playerLevel == nil or playerLevel < minLvl) then
                    do return end
                end
            end
            
            -- Validate role if needed
            if roles.enabled then
                local appliedRole = splitMsgLower[2];

                if appliedRole == nil then
                    SendChatMessage("INVITOMATIC: must specify role (heal/dps/tank)", "WHISPER", GetDefaultLanguage(unit), senderGUID);
                    do return end
                end

                local playerClass = roster[senderGUID].class;
                if tableHasValue(classRoles[playerClass]) == false then
                    SendChatMessage("INVITOMATIC: class-role mismatch", "WHISPER", GetDefaultLanguage(unit), senderGUID);
                    do return end
                end

                if roles[appliedRole] == 0 then
                    SendChatMessage("INVITOMATIC: full on role " .. appliedRole, "WHISPER", GetDefaultLanguage(unit), senderGUID);
                    do return end
                end
                roles[appliedRole] = roles[appliedRole] - 1;
            end

			convertIfNeeded();
            InviteUnit(senderGUID);
        end

    end)

    local affix = ". ";
    local rolesAffix = "";
    local minLvlAffix = "";
    local invAffix = "Type inv for auto invite";

    if roles.enabled then
        rolesAffix = "Need " .. roles.heal .. " heal, " .. roles.dps .. " dps and " .. roles.tank .. " tank. ";
        invAffix = "Type inv heal/dps/tank (PICK ONE) for auto invite";
    end

    if minLvl then
        minLvlAffix = "Min level " .. minLvl .. ". ";
    end
    print("INVITOMATIC: LFM for " .. location .. ". " .. rolesAffix .. minLvlAffix .. invAffix);
    --SendChatMessage("INVITOMATIC: LFM for " .. location .. affix .. "Type inv for auto invite", "GUILD");
end
