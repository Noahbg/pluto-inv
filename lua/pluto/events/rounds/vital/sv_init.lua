--resource.AddFile("sound/pluto/vitalsong.ogg")

ROUND.Name = "Vital Sign"
ROUND.CollisionGroup = COLLISION_GROUP_DEBRIS_TRIGGER

util.AddNetworkString "vital_data"
util.AddNetworkString "vital_prompt"

ROUND.Boss = true

function ROUND:GetLives(state)
	if (not state or not state.lives) then
		return 0, 0
	end

	local vamplives, hemolives = 0, 0
	for ply, lives in pairs(state.lives) do
		if (not IsValid(ply)) then
			continue
		end
		if (ply:GetRole() == "Vamplasma") then
			vamplives = vamplives + lives
		elseif (ply:GetRole() == "Hemogoblin") then
			hemolives = hemolives + lives
		end
	end

	return vamplives, hemolives
end

function ROUND:Prepare(state)
	net.Start "vital_prompt"
	net.Broadcast()

	state.nextclass = {}

	state.vampspawns = {}
	state.hemospawns = {}

	local positions = {}
	for i = 1, 50 do
		local pos, _ = pluto.currency.randompos(hull_mins, hull_maxs)
		table.insert(positions, pos)
	end

	local vamppos = positions[1]
	local hemopos = positions[2]
	local max = 0
	for k, pos in ipairs(positions) do
		for i = k + 1, #positions do
			if (pos:DistToSqr(positions[i]) > max) then
				vamppos = pos
				hemopos = positions[i]
				max = vamppos:DistToSqr(hemopos)
			end
		end
	end

	local vamppositions = {}
	local hemopositions = {}

	for k, pos in ipairs(positions) do
		table.insert(vamppositions, {pos, pos:DistToSqr(vamppos)})
		table.insert(hemopositions, {pos, pos:DistToSqr(hemopos)})
	end

	table.sort(vamppositions, function(a, b)
		return a[2] < b[2]
	end)

	table.sort(hemopositions, function(a, b)
		return a[2] < b[2]
	end)

	for i = 1, 3 do
		table.insert(state.vampspawns, vamppositions[i][1])
		table.insert(state.hemospawns, hemopositions[i][1])
	end

	timer.Create("pluto_event_timer", 5, 0, function()
		if (not state.lives) then
			return
		end
		for ply, lives in pairs(state.lives) do
			if (IsValid(ply) and not ply:Alive() and lives > 0) then
				ttt.ForcePlayerSpawn(ply)
			end
		end
	end)

	timer.Pause "tttrw_afk"
end

function ROUND:UpdateLives(state)
	local vamplives, hemolives = self:GetLives(state)

	net.Start "vital_data"
		net.WriteString "vamplives"
		net.WriteUInt(vamplives, 32)
	net.Broadcast()

	net.Start "vital_data"
		net.WriteString "hemolives"
		net.WriteUInt(hemolives, 32)
	net.Broadcast()
end

function ROUND:Finish()
	timer.Remove "pluto_event_timer"
end

function ROUND:Loadout(ply)
	ply:StripWeapons()

	local state = pluto.rounds.state

	if (state and state.class and state.class[ply] and self.Classes[state.class[ply]]) then
		for k, wep in ipairs(self.Classes[state.class[ply]].Loadout) do
			pluto.NextWeaponSpawn = false
			ply:Give(wep)
		end
	end
end

ROUND:Hook("TTTSelectRoles", function(self, state, plys)
	for i, ply in ipairs(plys) do
		round.Players[i] = {
			Player = ply,
			SteamID = ply:SteamID(),
			Nick = ply:Nick(),
			Role = (i % 2 == 0 and ttt.roles.Vamplasma or ttt.roles.Hemogoblin)
		}
	end

	return true
end)

local Doors = {
	"func_door", "func_door_rotating", "prop_door_rotating", "func_breakable", "func_breakable_surf"
}

for _, v in pairs(Doors) do
	Doors[v] = true
end

ROUND:Hook("TTTBeginRound", function(self, state)
	for _, ent in pairs(ents.GetAll()) do
		if (Doors[ent:GetClass()]) then
			ent:Remove()
		end
	end

	state.Vamplasma = round.GetActivePlayersByRole "Vamplasma"
	state.Hemogoblin = round.GetActivePlayersByRole "Hemogoblin"

	state.lives = {}

	for k, ply in ipairs(state.Vamplasma) do
		state.lives[ply] = 3
	end
	for k, ply in ipairs(state.Hemogoblin) do
		state.lives[ply] = 3
	end

	net.Start "vital_data"
		net.WriteString "lives"
		net.WriteUInt(3, 32)
	net.Broadcast()

	state.class = {}

	for ply, lives in pairs(state.lives) do
		if (not IsValid(ply)) then
			continue 
		end

		state.class[ply] = state.nextclass[ply] or math.random(1, 3)
		state.nextclass[ply] = state.class[ply]

		net.Start "vital_data"
			net.WriteString "class"
			net.WriteUInt(state.class[ply], 32)
		net.Send(ply)

		net.Start "vital_data"
			net.WriteString "nextclass"
			net.WriteUInt(state.nextclass[ply], 32)
		net.Send(ply)

		ply:StripWeapons()

		if (self.Classes[state.class[ply]]) then
			for k, wep in ipairs(self.Classes[state.class[ply]].Loadout) do
				pluto.NextWeaponSpawn = false
				ply:Give(wep)
			end
		end
		
		self:PlayerSetModel(state, ply)

		local pos = self:ResetPosition(state, ply)
		if (pos) then
			ply.ForcePos = pos
		end
	end

	self:UpdateLives(state)

	GetConVar("ttt_karma"):SetBool(false)

	timer.Simple(1, function()
		round.SetRoundEndTime(CurTime() + 215)
		ttt.SetVisibleRoundEndTime(CurTime() + 215)
	end)
end)

ROUND:Hook("PostPlayerDeath", function(self, state, ply)
	if (not state.lives) then
		return
	end

	if (state.lives[ply] and state.lives[ply] > 0) then
		state.lives[ply] = state.lives[ply] - 1
	end

	net.Start "vital_data"
		net.WriteString "lives"
		net.WriteUInt(state.lives[ply], 32)
	net.Send(ply)

	state.class[ply] = state.nextclass[ply]

	net.Start "vital_data"
		net.WriteString "class"
		net.WriteUInt(state.class[ply], 32)
	net.Send(ply)

	self:UpdateLives(state)
	ttt.CheckTeamWin()

	ply:Extinguish()
	return true
end)

local hull_mins, hull_maxs = Vector(-22, -22, 0), Vector(22, 22, 90)

ROUND:Hook("SetupMove", function(self, state, ply, mv)
	if (ply.ForcePos) then
		mv:SetOrigin(ply.ForcePos)
		ply.ForcePos = nil
	end
end)

function ROUND:Spawn(state, ply)
	ply:SetCollisionGroup(self.CollisionGroup)
	if (state.class and state.class[ply] and self.Classes[state.class[ply]]) then
		ply:SetHealth(self.Classes[state.class[ply]].Health)
		ply:SetMaxHealth(self.Classes[state.class[ply]].Health)
	end
end

ROUND:Hook("PlayerSpawn", ROUND.Spawn)

function ROUND:ResetPosition(state, ply)
	if (ply:GetRole() == "Vamplasma" and state.vampspawns) then
		return table.Random(state.vampspawns)
	end
	
	if (ply:GetRole() == "Hemogoblin" and state.hemospawns) then
		return table.Random(state.hemospawns)
	end

	local pos, _ = pluto.currency.randompos(hull_mins, hull_maxs)
	return pos
end

ROUND:Hook("PlayerSelectSpawnPosition", ROUND.ResetPosition)

function ROUND:TTTEndRound(state)
	local vamplives, hemolives = self:GetLives(state)

	local winrole = (vamplives < 1 and hemolives > 0 and "Hemogoblin") or (hemolives < 1 and vamplives > 1 and "Vamplasma") or nil

	if (winrole) then
		for k, ply in ipairs(state[winrole]) do
			ply:ChatPrint("Congratulations, you win! The ", ttt.roles[winrole].Color, winrole, " family has proven their excellence!")
		end
		for k, ply in ipairs(state[self:OtherRole(winrole)]) do
			ply:ChatPrint("Ouch, you lose! The ", ttt.roles[self:OtherRole(winrole)].Color, self:OtherRole(winrole), " family has been disgraced!")
		end
	else
		for ply, lives in pairs(state.lives) do
			ply:ChatPrint("Neither family won? Looks like both are unworthy!")
		end
	end

	GetConVar("ttt_karma"):Revert()
	timer.UnPause("tttrw_afk")
end

ROUND:Hook("PlayerCanPickupWeapon", function(self, state, ply, wep)
	if (state and state.class and state.class[ply] and self.Classes[state.class[ply]]) then
		for k, name in ipairs(self.Classes[state.class[ply]].Loadout) do
			if wep:GetClass() == name then
				return true
			end
		end
	end

	return wep:GetClass() == "weapon_ttt_unarmed"
end)

ROUND:Hook("TTTHasRoundBeenWon", function(self, state)
	local vamplives, hemolives = self:GetLives(state)

	if (vamplives <= 0 and hemolives <= 0) then
		return true, "innocent", false
	elseif (vamplives <= 0) then
		return true, "vamplasma", false
	elseif (hemolives <= 0) then
		return true, "hemogoblin", false
	end

	return false
end)

ROUND:Hook("PlayerDisconnected", function(self, state, ply)
	if table.HasValue(state.Vamplasma, ply) then
		table.RemoveByValue(state.Vamplasma, ply)
	elseif table.HasValue(state.Hemogoblin, ply) then
		table.RemoveByValue(state.Hemogoblin, ply)
	end

	if (state.lives) then
		state.lives[ply] = nil
	end

	self:UpdateLives(state)

	ttt.CheckTeamWin()
end)

ROUND:Hook("PlayerDeath", function(self, state, vic, inf, atk)
	if (not IsValid(vic) or not IsValid(atk)) then
		return 
	end

	if (not state.lives or not state.lives[atk]) then
		return 
	end

	if (not state.class or not state.class[vic] or not state.class[atk]) then
		return 
	end

	if (state.class[atk] == state.class[vic]) then
		state.lives[atk] = state.lives[atk] + 1
	end
end)

ROUND:Hook("PlayerRagdollCreated", function(self, state, ply, rag, atk, dmg)
	timer.Simple(5, function()
		if (IsValid(rag)) then
			rag:Remove()
		end
	end)
end)

function ROUND:PlayerSetModel(state, ply)
	if (state.class and state.class[ply] and self.Classes[state.class[ply]]) then
		ply:SetModel(pluto.models[self.Classes[state.class[ply]].Model].Model)

		return true
	end
end

net.Receive("vital_data", function(len, ply)
	local class = net.ReadUInt(32) or 1
	local state = pluto.rounds.state

	if (not state or not state.nextclass) then
		return
	end

	state.nextclass[ply] = math.Clamp(class, 1, 3)

	net.Start "vital_data"
		net.WriteString "nextclass"
		net.WriteUInt(state.nextclass[ply], 32)
	net.Send(ply)
end)