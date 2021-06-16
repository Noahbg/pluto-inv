ROUND.Reward = "tp"
ROUND.WinnerEarnings = 25
ROUND.WinnerBonus = 20
ROUND.EachDecrease = 5

ROUND.Boss = true

local WriteRoundData = pluto.rounds.WriteRoundData

function ROUND:Prepare(state)
	timer.Create("pluto_event_timer", 5, 0, function()
		if (not state.scores) then
			return
		end
		for ply, count in pairs(state.scores) do
			if (IsValid(ply) and not ply:Alive()) then
				ttt.ForcePlayerSpawn(ply)
			end
		end
	end)

	timer.Pause "tttrw_afk"
end

function ROUND:Finish()
	timer.Remove "pluto_event_timer"
end

function ROUND:Loadout(ply)
	ply:StripWeapons()
	pluto.NextWeaponSpawn = false
	ply:Give "weapon_ttt_deagle_hs"
	ply:SetAmmo(1000, "AlyxGun")
	pluto.NextWeaponSpawn = false
	ply:Give "weapon_ttt_crowbar"
end

ROUND:Hook("TTTSelectRoles", function(self, state, plys)
	plys = table.shuffle(plys)

	local roles_needed = {
		Hotshot = 1,
	}

	for i, ply in ipairs(plys) do
		local role, amt = next(roles_needed)
		if (role) then
			if (amt == 1) then
				roles_needed[role] = nil
			else
				roles_needed[role] = amt - 1
			end
		else
			role = "Innocent"
		end

		ply:StripWeapons()
		pluto.NextWeaponSpawn = false
		ply:Give "weapon_ttt_deagle_hs"
		ply:SetAmmo(1000, "AlyxGun")
		pluto.NextWeaponSpawn = false
		ply:Give "weapon_ttt_crowbar"

		round.Players[i] = {
			Player = ply,
			SteamID = ply:SteamID(),
			Nick = ply:Nick(),
			Role = ttt.roles[role]
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

	local innos = round.GetActivePlayersByRole "Innocent"
	local hotshot = round.GetActivePlayersByRole "Hotshot"
	state.scores = {}

	for k, ply in pairs(innos) do
		state.scores[ply] = 0
		self:UpdateScore(state, ply, 0)
		if (ply:Alive()) then
			self:Initialize(state, ply)
		end
		ply:SetMaxHealth(10)
		ply:SetHealth(10)
	end

	for k, ply in pairs(hotshot) do
		state.scores[ply] = 0
		self:UpdateScore(state, ply, 0)
		if (ply:Alive()) then
			self:Initialize(state, ply)
		end
		ply:SetMaxHealth(10)
		ply:SetHealth(10)
	end

	self:ChooseLeader(state)

	GetConVar("ttt_karma"):SetBool(false)
	
	timer.Simple(1, function()
		round.SetRoundEndTime(CurTime() + 150)
		ttt.SetVisibleRoundEndTime(CurTime() + 150)
	end)
end)

ROUND:Hook("PostPlayerDeath", function(self, state, ply)
	ply:Extinguish()
	return true
end)

function ROUND:Initialize(state, ply)
	self:Spawn(state, ply)
end

local last_notification = 0

function ROUND:ChooseLeader(state)
	local new = table.SortByKey(state.scores)[1]

	if (not IsValid(new)) then
		return
	end

	if (IsValid(state.leader) and new ~= state.leader) then
		state.leader:SetRole("Innocent")
		if (CurTime() - last_notification >= 0.25) then
			last_notification = CurTime()
			pluto.rounds.Notify(new:Nick() .. " has become the Hotshot! Kill them for double points!", ttt.roles.Hotshot.Color, nil, true)
		end
	end
	
	state.leader = new
	new:SetRole("Hotshot")
	WriteRoundData("leader", new:Nick())
	WriteRoundData("leaderscore", state.scores[new])
end

function ROUND:UpdateScore(state, ply, amt)
	state.scores[ply] = math.max(0, (state.scores[ply] or 0) + amt)

	WriteRoundData("score", state.scores[ply], ply)

	self:ChooseLeader(state)
end

ROUND:Hook("SetupMove", function(self, state, ply, mv)
	if (ply.ForcePos) then
		mv:SetOrigin(ply.ForcePos)
		ply.ForcePos = nil
	end
end)

function ROUND:Spawn(state, ply)
	ply:SetMaxHealth(10)
	ply:SetHealth(10)
end

ROUND:Hook("PlayerSpawn", ROUND.Spawn)

local hull_mins, hull_maxs = Vector(-22, -22, 0), Vector(22, 22, 90)

function ROUND:ResetPosition(state, ply)
	return pluto.currency.randompos(hull_mins, hull_maxs)
end

ROUND:Hook("PlayerSelectSpawnPosition", ROUND.ResetPosition)

function ROUND:TTTEndRound(state)
	self:ChooseLeader(state)

	local sorted = {}

	for ply, score in pairs(state.scores) do
		table.insert(sorted, {
			Player = ply,
			Score = score,
		})
	end

	table.SortByMember(sorted, "Score")

	for k, entry in ipairs(sorted) do
		local amt = self.WinnerEarnings - (k * self.EachDecrease)

		if (not IsValid(entry.Player) or amt <= 0) then
			break 
		end

		pluto.db.instance(function(db)
			pluto.inv.addcurrency(db, entry.Player, self.Reward, amt)
			pluto.rounds.Notify(string.format("You earned %i Refinium Vials for achieving place #%i!", amt, k), pluto.currency.byname[self.Reward].Color, entry.Player)
		end)
	end

	if (IsValid(state.leader)) then
		pluto.rounds.Notify(state.leader:Nick() .. " is the true Hotshot!", ttt.roles.Hotshot.Color)
		pluto.db.instance(function(db)
			pluto.inv.addcurrency(db, state.leader, self.Reward, self.WinnerBonus)
			pluto.rounds.Notify(string.format("You get %i extra Refinium Vials claiming the title of Hotshot!", self.WinnerBonus), pluto.currency.byname[self.Reward].Color, state.leader)
		end)
	else
		pluto.rounds.Notify("No Hotshot here...")
	end

	GetConVar("ttt_karma"):Revert()

	timer.UnPause("tttrw_afk")
end

ROUND:Hook("PlayerCanPickupWeapon", function(self, state, ply, wep)
	return wep:GetClass() == "weapon_ttt_deagle_hs" or wep:GetClass() == "weapon_ttt_crowbar"
end)

ROUND:Hook("TTTHasRoundBeenWon", function(self, state)
	if (#round.GetActivePlayersByRole "Innocent" == 0) then
		return true, "traitor", false
	end

	return false
end)

ROUND:Hook("PlayerDisconnected", function(self, state, ply)
	if (not state.scores or not state.scores[ply]) then
		return
	end

	state.scores[ply] = nil
end)

ROUND:Hook("PlayerDeath", function(self, state, vic, inf, atk)
	if (not IsValid(vic) or not state.scores) then
		return
	end

	self:UpdateScore(state, vic, -1)

	if (not IsValid(atk) or not atk:IsPlayer() or vic == atk) then
		return
	end

	self:UpdateScore(state, atk, atk:GetActiveWeapon():GetClass() == "weapon_ttt_crowbar" and 5 or 2)
end)

ROUND:Hook("PlayerRagdollCreated", function(self, state, ply, rag, atk, dmg)
	timer.Simple(5, function()
		if (IsValid(rag)) then
			rag:Remove()
		end
	end)
end)

--[[function ROUND:PlayerSetModel(state, ply)

end--]]