sql.Query "CREATE TABLE IF NOT EXISTS pluto_map_plays (mapname VARCHAR(32) NOT NULL PRIMARY KEY, last_played INT UNSIGNED NOT NULL)"
local last_played = sql.Query("SELECT * from pluto_map_plays ORDER BY last_played desc limit 6") or {}

sql.Query("INSERT INTO pluto_map_plays (mapname, last_played) VALUES (" .. sql.SQLStr(game.GetMap()) .. ", CAST(strftime('%s', 'now') AS INT UNSIGNED)) ON CONFLICT(mapname) DO UPDATE SET last_played = CAST(strftime('%s', 'now') AS INT UNSIGNED)")

pluto.mapvote = pluto.mapvote or {}
pluto.mapvote.blacklisted = pluto.mapvote.blacklisted or {}
for _, map in pairs(last_played) do
	pluto.mapvote.blacklisted[map.mapname] = true
end
pluto.mapvote.boosts = pluto.mapvote.boosts or {}
pluto.mapvote.history = {}
pluto.mapvote.popular = {}
pluto.mapvote.liked = {}
for _, map in pairs(sql.Query "SELECT mapname, CAST(strftime('%s', 'now') AS INT UNSIGNED) - last_played as ago FROM pluto_map_plays ORDER BY ago ASC") do
	table.insert(pluto.mapvote.history, {
		name = map.mapname,
		ago = map.ago
	})
end

function pluto.mapvote.boost(map, ply)
	if (ply.HasMapBoosted) then
		return false
	end

	if (#pluto.mapvote.boosts > 2) then
		return false
	end

	if (table.HasValue(pluto.mapvote.boosts, map)) then
		return false
	end

	table.insert(pluto.mapvote.boosts, map)
	ply.HasMapBoosted = true

	return true
end

local function init()
	pluto.db.instance(function(db)
		local data = {}
		pluto.mapvote.data = data
		
		for _, info in pairs(mysql_query(db, "SELECT COUNT(*) as votes, liked, info.mapname, played FROM pluto_map_vote vote INNER JOIN pluto_map_info info ON vote.mapname = info.mapname GROUP BY liked, vote.mapname")) do
			data[info.mapname] = {
				played = info.played,
				votes = info.votes,
				liked = info.liked,
				mapname = info.mapname
			}
		end

		for mapname, info in pairs(data) do
			table.insert(pluto.mapvote.popular, info)
			table.insert(pluto.mapvote.liked, info)
		end

		table.sort(pluto.mapvote.popular, function(a, b)
			return a.played > b.played
		end)

		table.sort(pluto.mapvote.liked, function(a, b)
			return a.liked > b.liked
		end)
	end)
end

hook.Add("Initialize", "pluto_mapvote_init", init)
if (gmod.GetGamemode()) then
	init()
end

function pluto.mapvote.broadcast()
	for _, ply in pairs(player.GetAll()) do
		pluto.inv.message(ply)
			:write "mapvote"
			:send()
	end

	
	round.SetState(ttt.ROUNDSTATE_ENDED, 15):_then(function()
		local votes = {}
		for map in pairs(pluto.mapvote.state.votable) do
			votes[map] = 0
		end
		for ply, map in pairs(pluto.mapvote.state.votes) do
			if (IsValid(ply)) then
				votes[map] = (votes[map] or 0) + 1
			end
		end

		local v = {}
		for map, votes in pairs(votes) do
			v[#v + 1] = {
				Map = map,
				Votes = votes + math.random()
			}
		end

		table.sort(v, function(a, b) 
			return a.Votes > b.Votes
		end)
		
		RunConsoleCommand("changelevel", v[1].Map)
	end)
end

function pluto.inv.writemapvote(cl)
	local state = pluto.mapvote.state
	net.WriteUInt(table.Count(state.votable), 8)

	for map in pairs(state.votable) do
		net.WriteString(map)

		local info = state.maps[map]
		net.WriteUInt(info.likes, 32)
		net.WriteUInt(info.dislikes, 32)
		net.WriteUInt(info.played, 32)
	end

	local info = state.maps[game.GetMap()]

	net.WriteUInt(info.likes, 32)
	net.WriteUInt(info.dislikes, 32)
	net.WriteUInt(info.played, 32)
end

function pluto.inv.readlikemap(cl)
	local liked = net.ReadBool()

	pluto.db.simplequery("INSERT INTO pluto_map_vote (voter, liked, mapname) VALUES(?, ?, ?) ON DUPLICATE KEY UPDATE liked = VALUE(liked)", {pluto.db.steamid64(cl), liked, game.GetMap()}, function() end)
end

function pluto.inv.readvotemap(cl)
	if (not pluto.mapvote.state) then
		return
	end

	local map = net.ReadString()

	if (not pluto.mapvote.state.votable[map]) then
		return
	end

	pluto.mapvote.state.votes[cl] = map

	local votes = {}

	for ply, map in pairs(pluto.mapvote.state.votes) do
		if (IsValid(ply)) then
			votes[map] = (votes[map] or 0) + 1
		end
	end

	for _, ply in pairs(player.GetAll()) do
		pluto.inv.message(ply)
			:write("mapvotes", votes)
			:send()
	end
end

function pluto.inv.writemapvotes(cl, votes)
	net.WriteUInt(table.Count(votes), 8)

	for map, vote in pairs(votes) do
		net.WriteString(map)
		net.WriteUInt(vote, 8)
	end
end

function pluto.mapvote.start()
	local valid = pluto.GetValidMaps()

	for i, map in pairs(valid) do
		if (map == game.GetMap()) then
			table.remove(valid, i)
			break
		end
	end

	for _, data in pairs(last_played) do
		if (#valid <= 8) then
			break
		end

		local maptoremove = data.mapname

		for i, map in pairs(valid) do
			if (map == maptoremove) then
				table.remove(valid, i)
				break
			end
		end
	end

	if (#valid < 8) then
		game.LoadNextMap()
		pwarnf("Cannot get enough valid maps: %s", table.concat(valid, ", "))
		return
	end

	for i, map in pairs(valid) do
		valid[i] = {map, math.random()}
	end

	table.sort(valid, function(a, b)
		return a[2] < b[2]
	end)

	for i in pairs(valid) do
		valid[i] = valid[i][1]
	end

	-- one popular map
	for i = 1, 8 do
		local chosen = pluto.mapvote.popular[math.random(8)]

		if (not chosen) then
			continue
		end

		local gotten = false
		
		for i, map in pairs(valid) do
			if (map == chosen.mapname) then
				table.remove(valid, i)
				table.insert(valid, 1, map)
				gotten = true
				break
			end
		end

		if (gotten) then
			break
		end
	end

	local mediums = 0
	-- two medium popular
	for i = 9, 20 do
		local chosen = pluto.mapvote.popular[math.random(12) + 8]

		if (not chosen) then
			continue
		end
		
		for i, map in pairs(valid) do
			if (map == chosen.mapname) then
				table.remove(valid, i)
				table.insert(valid, 1, map)
				mediums = mediums + 1
				break
			end
		end
		
		if (mediums >= 2) then
			break
		end
	end

	for i = 9, #valid do
		valid[i] = nil
	end

	for i, boost in pairs(pluto.mapvote.boosts) do
		if (table.HasValue(valid, boost)) then
			continue
		end

		valid[9 - i] = boost
	end


	local state = {
		maps = {},
		votes = {},
		votable = {},
		needed = {
			likes = true,
			played = true,
		}
	}

	pluto.mapvote.state = state

	for _, map in pairs(valid) do
		state.votable[map] = true
	end

	valid[#valid + 1] = game.GetMap()

	for _, map in pairs(valid) do
		state.maps[map] = {
			played = 0,
			likes = 0,
			dislikes = 0,
		}
	end

	local function checkdone(from)
		state.needed[from] = nil
		if (table.Count(state.needed) == 0) then
			pluto.mapvote.broadcast()
		end
	end

	pluto.db.simplequery("SELECT COUNT(*) as votes, liked, mapname FROM pluto_map_vote WHERE mapname IN (?, ?, ?, ?, ?, ?, ?, ?, ?) GROUP BY liked, mapname", valid, function(dat, err)
		if (not dat) then
			return
		end

		for _, d in ipairs(dat) do
			local cur = state.maps[d.mapname]
			if (d.liked == 1) then
				cur.likes = d.votes
			else
				cur.dislikes = d.votes
			end
		end

		checkdone "likes"
	end)

	pluto.db.simplequery("SELECT played, mapname FROM pluto_map_info WHERE mapname IN (?, ?, ?, ?, ?, ?, ?, ?, ?)", valid, function(dat, err)
		if (not dat) then
			return
		end

		for _, d in ipairs(dat) do
			local cur = state.maps[d.mapname]
			cur.played = d.played
		end

		checkdone "played"
	end)
end

hook.Add("Initialize", "pluto_map", function()
	pluto.db.simplequery("INSERT INTO pluto_map_info (mapname, played) VALUES(?, 1) ON DUPLICATE KEY UPDATE played = played + VALUE(played)", {game.GetMap()}, function(dat, err)
		if (not dat) then
			return
		end

		print "updated map played thing"
	end)
end)

hook.Add("ChangeMap", "pluto_mapvote", function(reason)
    for _, ply in pairs(player.GetAll()) do
        ply:ChatPrint("Server is changing map. Reason: " .. reason)
	end

	round.SetState(ttt.ROUNDSTATE_PREPARING, math.huge)


	timer.Simple(4, pluto.mapvote.start)

	return true
end)