--[[
  Name: ban
  Desc: Ban a player
  Arguments:
    1. Target   (player)
    2. Duration (number) (optional)
    3. Reason   (string) (optional)
]]
BSU.SetupCommand("ban", function(cmd)
  cmd:SetDescription("Ban a player")
  cmd:SetCategory("moderation")
  cmd:SetAccess(BSU.CMD_ADMIN)
  cmd:SetFunction(function(self, ply)
    local target = self:GetPlayerArg(1, true)
    self:CheckCanTarget(target, true) -- make sure ply is allowed to target this person
    local duration = self:GetNumberArg(2)
    local reason
    if duration then
      duration = math.max(duration, 0)
      reason = self:GetMultiStringArg(3, -1)
    else
      reason = self:GetMultiStringArg(2, -1)
    end

    BSU.BanPlayer(target, reason, duration, ply)

    self:BroadcastActionMsg("%user% banned %param%" .. (duration and duration ~= 0 and " for %param%" or " permanently") .. (reason and " (%param%)" or ""), {
      ply,
      target,
      duration and duration ~= 0 and BSU.StringTime(duration, 10000),
      reason
    })
  end)
end)

--[[
  Name: banid
  Desc: Ban a player by steamid
  Arguments:
    1. Steam ID (string)
    2. Duration (number) (optional)
    3. Reason   (string) (optional)
]]
BSU.SetupCommand("banid", function(cmd)
  cmd:SetDescription("Ban a player by steamid")
  cmd:SetCategory("moderation")
  cmd:SetAccess(BSU.CMD_ADMIN)
  cmd:SetFunction(function(self, ply)
    local steamid = BSU.ID64(self:GetStringArg(1, true))
    self:CheckCanTargetID(steamid, true) -- make sure ply is allowed to target this person
    local duration = self:GetNumberArg(2)
    local reason
    if duration then
      duration = math.max(duration, 0)
      reason = self:GetMultiStringArg(3, -1)
    else
      reason = self:GetMultiStringArg(2, -1)
    end
  
    BSU.BanSteamID(steamid, reason, duration, ply:IsValid() and ply:SteamID64())
  
    local name = BSU.GetPlayerDataBySteamID(steamid).name
    self:BroadcastActionMsg("%user% banned steamid %param%" .. (name and " (%param%)" or "") .. (duration and duration ~= 0 and " for %param%" or " permanently") .. (reason and " (%param%)" or ""), {
      ply,
      util.SteamIDFrom64(steamid),
      name,
      duration and duration ~= 0 and BSU.StringTime(duration, 10000),
      reason
    })
  end)
end)

--[[
  Name: ipban
  Desc: IP ban a player
  Arguments:
    1. Target   (player)
    2. Duration (number) (optional)
    3. Reason   (string) (optional)
]]
BSU.SetupCommand("ipban", function(cmd)
  cmd:SetDescription("IP ban a player")
  cmd:SetCategory("moderation")
  cmd:SetAccess(BSU.CMD_ADMIN)
  cmd:SetFunction(function(self, ply)
    local target = self:GetPlayerArg(1, true)
    self:CheckCanTarget(target, true) -- make sure ply is allowed to target this person
    local duration = self:GetNumberArg(2)
    local reason
    if duration then
      duration = math.max(duration, 0)
      reason = self:GetMultiStringArg(3, -1)
    else
      reason = self:GetMultiStringArg(2, -1)
    end
  
    BSU.IPBanPlayer(target, reason, duration, ply)
  
    self:BroadcastActionMsg("%user% ip banned %param%" .. (duration and duration ~= 0 and " for %param%" or " permanently") .. (reason and " (%param%)" or ""), {
      ply,
      target,
      duration and duration ~= 0 and BSU.StringTime(duration, 10000),
      reason
    })
  end)
end)

--[[
  Name: banip
  Desc: Ban a player by ip
  Arguments:
    1. IP Address (string)
    2. Duration   (number) (optional)
    3. Reason     (string) (optional)
]]
BSU.SetupCommand("banip", function(cmd)
  cmd:SetDescription("Ban a player by ip")
  cmd:SetCategory("moderation")
  cmd:SetAccess(BSU.CMD_ADMIN)
  cmd:SetFunction(function(self, ply)
    local address = BSU.Address(self:GetStringArg(1, true))
    local targetData = BSU.GetPlayerDataByIPAddress(address) -- find any players associated with this address
    for i = 1, #targetData do -- make sure ply is allowed to target all of these players
      self:CheckCanTargetID(targetData[i].steamid, true)
    end
    local duration = self:GetNumberArg(2)
    local reason
    if duration then
      duration = math.max(duration, 0)
      reason = self:GetMultiStringArg(3, -1)
    else
      reason = self:GetMultiStringArg(2, -1)
    end
  
    BSU.BanIP(address, reason, duration, ply:IsValid() and ply:SteamID64())
  
    local names = {}
    for i = 1, #targetData do
      table.insert(names, targetData[i].name)
    end
    self:BroadcastActionMsg("%user% banned an ip" .. (not table.IsEmpty(names) and " (%param%)" or "") .. (duration and duration ~= 0 and " for %param%" or " permanently") .. (reason and " (%param%)" or ""), {
      ply,
      not table.IsEmpty(names) and names,
      duration and duration ~= 0 and BSU.StringTime(duration, 10000),
      reason
    })
  end)
end)

--[[
  Name: unban
  Desc: Unban a player
  Arguments:
    1. Steam ID (string)
]]
BSU.SetupCommand("unban", function(cmd)
  cmd:SetDescription("Unban a player")
  cmd:SetCategory("moderation")
  cmd:SetAccess(BSU.CMD_ADMIN)
  cmd:SetFunction(function(self, ply)
    local steamid = self:GetStringArg(1, true)
    steamid = BSU.ID64(steamid)
  
    BSU.RevokeSteamIDBan(steamid, ply:IsValid() and ply:SteamID64()) -- this also checks if the steam id is actually banned
  
    local name = BSU.GetPlayerDataBySteamID(steamid).name
    self:BroadcastActionMsg("%user% unbanned %param%" .. (name and " (%param%)" or ""), {
      ply,
      util.SteamIDFrom64(steamid),
      name
    })
  end)
end)

--[[
  Name: unbanip
  Desc: Unban a player by ip
  Arguments:
    1. IP Address (string)
]]
BSU.SetupCommand("unbanip", function(cmd)
  cmd:SetDescription("Unban a player by ip")
  cmd:SetCategory("moderation")
  cmd:SetAccess(BSU.CMD_ADMIN)
  cmd:SetFunction(function(self, ply)
    local address = self:GetStringArg(1, true)
    address = BSU.Address(address)
  
    BSU.RevokeIPBan(address, ply:IsValid() and ply:SteamID64()) -- this also checks if the steam id is actually banned
  
    local targetData, names = BSU.GetPlayerDataByIPAddress(address), {}
    for i = 1, #targetData do -- get all the names of players associated with the address
      table.insert(names, targetData[i].name)
    end
    self:BroadcastActionMsg("%user% unbanned an ip" .. (not table.IsEmpty(names) and " (%param%)" or ""), {
      ply,
      not table.IsEmpty(names) and names
    })
  end)
end)

--[[
  Name: superban
  Desc: Equivalent to the ban command, except it will also ban the account that owns the game license if the player is using Steam Family Sharing
  Arguments:
    1. Target   (player)
    2. Duration (number) (optional)
    3. Reason   (string) (optional)
]]
BSU.SetupCommand("superban", function(cmd)
  cmd:SetDescription("Equivalent to the ban command, except it will also ban the account that owns the game license if the player is using Steam Family Sharing")
  cmd:SetCategory("moderation")
  cmd:SetAccess(BSU.CMD_SUPERADMIN)
  cmd:SetFunction(function(self, ply, _, argStr)
    local target = self:GetPlayerArg(1, true)
  
    BSU.RunCommand("ban", ply, argStr)
  
    local ownerID = target:OwnerSteamID64()
    if ownerID ~= target:SteamID64() then
      BSU.RunCommand("banid", ply, ownerID .. " " .. (self:GetRawMultiStringArg(2, -1) or ""))
    end
  end)
end)

--[[
  Name: superduperban
  Desc: Equivalent to the superban command, except it will also ip ban the player
  Arguments:
    1. Target   (player)
    2. Duration (number) (optional)
    3. Reason   (string) (optional)
]]
BSU.SetupCommand("superduperban", function(cmd)
  cmd:SetDescription("Equivalent to the superban command, except it will also ip ban the player")
  cmd:SetCategory("moderation")
  cmd:SetAccess(BSU.CMD_SUPERADMIN)
  cmd:SetFunction(function(self, ply, _, argStr)
    BSU.RunCommand("superban", ply, argStr)
    BSU.RunCommand("ipban", ply, argStr)
  end)
end)

--[[
  Name: kick
  Desc: Kick a player
  Arguments:
    1. Target (player)
    2. Reason (string) (optional)
]]
BSU.SetupCommand("kick", function(cmd)
  cmd:SetDescription("Kick a player")
  cmd:SetCategory("moderation")
  cmd:SetAccess(BSU.CMD_ADMIN)
  cmd:SetFunction(function(self, ply)
    local target = self:GetPlayerArg(1, true)
    self:CheckCanTarget(target, true)
    local reason = self:GetMultiStringArg(2, -1)
  
    BSU.KickPlayer(target, reason, ply)
  
    self:BroadcastActionMsg("%user% kicked %param%" .. (reason and " (%param%)" or ""), {
      ply,
      target,
      reason
    })
  end)
end)

--[[
  Name: setgroup
  Desc: set group by id
  Arguments:
    1. Target (player)
    2. Group ID (number)
]]
BSU.SetupCommand("setgroup", function(cmd)
  cmd:SetDescription("set group by id")
  cmd:SetCategory("moderation")
  cmd:SetAccess(BSU.CMD_ADMIN)
  cmd:SetFunction(function(self, ply)
    BSU.SetPlayerGroup(
      self:GetPlayerArg(1, true),
      self:GetNumberArg(2, true)
    )
  end)
end)

--[[
  Name: setgrouppriv
  Desc: set access to a command by group id
  Arguments:
    1. Target Group (string)
    2. Command (string)
    3. Restrict? Revoke = not 1, Grant = 1 (number)
]]
BSU.SetupCommand("setgrouppriv", function(cmd)
  cmd:SetDescription("grants access to a command")
  cmd:SetCategory("moderation")
  cmd:SetAccess(BSU.CMD_ADMIN)
  cmd:SetFunction(function(self, ply)
    BSU.AddGroupCommandAccess(
      self:GetNumberArg(1, true),
      self:GetStringArg(2, true),
      self:GetNumberArg(3, false) == 1
    )
  end)
end)