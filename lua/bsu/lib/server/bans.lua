-- lib/server/bans.lua
-- functions for managing bans

function BSU.RegisterBan(identity, reason, duration, admin) -- this is also used for logging kicks (when duration = null)
	BSU.SQLInsert(BSU.SQL_BANS, {
		identity = identity,
		reason = reason,
		duration = duration,
		time = BSU.UTCTime(),
		admin = admin and BSU.ID64(admin)
	})
end

function BSU.GetAllBans()
	return BSU.SQLSelectAll(BSU.SQL_BANS)
end

function BSU.GetBansByValues(values)
	return BSU.SQLSelectByValues(BSU.SQL_BANS, values)
end

-- returns data of the latest ban if they are still banned, otherwise nothing if they aren't currently banned (can take a steam id or ip address)
function BSU.GetBanStatus(identity)
	-- correct the argument (steam id to 64 bit) (removing port from ip address)
	identity = BSU.IsValidSteamID(identity) and BSU.ID64(identity) or BSU.IsValidIP(identity) and BSU.Address(identity)

	local bans = {}
	for _, v in ipairs(BSU.GetBansByValues({ identity = identity })) do -- exclude kicks since they're also logged
		if v.duration then table.insert(bans, v) end
	end

	if #bans > 0 then
		table.sort(bans, function(a, b) return a.time > b.time end) -- sort from latest to oldest

		local latestBan = bans[1]

		if not latestBan.unbanTime and (latestBan.duration == 0 or (latestBan.time + latestBan.duration * 60) > BSU.UTCTime()) then -- this guy is perma'd or still banned
			return latestBan
		end
	end
end

-- ban a player by steam id (this adds a new ban entry so it will be the new ban status for this player)
function BSU.BanSteamID(steamid, reason, duration, adminID)
	steamid = BSU.ID64(steamid)
	if adminID then adminID = BSU.ID64(adminID) end

	BSU.RegisterBan(steamid, reason, duration or 0, adminID and BSU.ID64(adminID) or nil)

	game.KickID(util.SteamIDFrom64(steamid), "(Banned) " .. (reason or "No reason given"))
end

-- ban a player by ip (this adds a new ban entry so it will be the new ban status for this player)
function BSU.BanIP(ip, reason, duration, adminID)
	ip = BSU.Address(ip)

	BSU.RegisterBan(ip, reason, duration or 0, adminID and BSU.ID64(adminID) or nil)

	for _, v in ipairs(player.GetHumans()) do -- try to kick all players with this ip
		if BSU.Address(v:IPAddress()) == ip then
			game.KickID(v:UserID(), "(Banned) " .. (reason or "No reason given"))
		end
	end
end

-- unban a player by steam id
function BSU.RevokeSteamIDBan(steamid, adminID)
	local lastBan = BSU.GetBanStatus(steamid)
	if not lastBan then return error("Steam ID is not currently banned") end

	BSU.SQLUpdateByValues(BSU.SQL_BANS, lastBan, { unbanTime = BSU.UTCTime(), unbanAdmin = adminID and BSU.ID64(adminID) or nil })
end

-- unban a player by ip
function BSU.RevokeIPBan(ip, adminID)
	local lastBan = BSU.GetBanStatus(ip)
	if not lastBan then return error("IP is not currently banned") end

	BSU.SQLUpdateByValues(BSU.SQL_BANS, lastBan, { unbanTime = BSU.UTCTime(), unbanAdmin = adminID and BSU.ID64(adminID) or nil })
end

function BSU.BanPlayer(ply, reason, duration, admin)
	if ply:IsBot() then return error("Unable to ban a bot, try kicking") end
	BSU.BanSteamID(ply:SteamID64(), reason, duration, IsValid(admin) and admin:SteamID64() or nil)
end

function BSU.SuperBanPlayer(ply, reason, duration, admin)
	BSU.BanPlayer(ply, reason, duration, admin)

	if ply:IsFullyAuthenticated() and ply:OwnerSteamID64() ~= ply:SteamID64() then
		BSU.BanSteamID(ply:OwnerSteamID64(), reason, duration, IsValid(admin) and admin:SteamID64() or nil)
	end
end

function BSU.SuperDuperBanPlayer(ply, reason, duration, admin)
	BSU.SuperBanPlayer(ply, reason, duration, admin)
	BSU.IPBanPlayer(ply, reason, duration, admin)
end

function BSU.IPBanPlayer(ply, reason, duration, admin)
	if ply:IsBot() then return error("Unable to ip ban a bot, try kicking") end
	BSU.BanIP(ply:IPAddress(), reason, duration, IsValid(admin) and admin:SteamID64() or nil)
end

function BSU.KickPlayer(ply, reason, admin)
	game.KickID(ply:UserID(), "(Kicked) " .. (reason or "No reason given"))
	BSU.RegisterBan(ply:SteamID64(), reason, nil, IsValid(admin) and admin:SteamID64() or nil) -- log it
end

-- formats a ban message that shows ban reason, duration, time left and the date of the ban
-- duration should be the ban length in mins and time should be the ban time in UTC secs
-- timezoneOffset is used for adjusting the time in different timezones (if it's not set UTC time is used)
function BSU.FormatBanMsg(reason, duration, time, timezoneOffset)
	return string.gsub(BSU.BAN_MSG, "%%([%w_]+)%%",
		{
			reason = reason or "(None given)",
			duration = duration == 0 and "(Permaban)" or BSU.StringTime(duration),
			remaining = duration == 0 and "(Permaban)" or BSU.StringTime(math.ceil(time / 60 + duration - BSU.UTCTime() / 60)),
			time = os.date("!%a, %b %d, %Y - %I:%M:%S %p", time + (timezoneOffset and timezoneOffset * 3600 or 0)) .. " (" .. (BSU.UTCTime() - time < 60 and "A few seconds ago" or BSU.StringTime(math.ceil(BSU.UTCTime() / 60 - time / 60 - 1)) .. " ago") .. ")"
		}
	)
end