ROUND.PrintName = "Vital Sign"
ROUND.Author = "add___123"
ROUND.Type = "Random"

function ROUND:TTTPrepareRoles(Team, Role)
	--[[Team "hemogoblin"
		:SetColor(Color(0, 102, 17))
		:SeenBy {"vamplasma", "hemogoblin"}
		:SetDeathIcon "materials/pluto/roles/hemogoblin.png"
		
	Team "vamplasma"
		:SetColor(Color(128, 21, 0))
		:SeenBy {"vamplasma", "hemogoblin"}
		:SetDeathIcon "materials/pluto/roles/vamplasma.png"--]]

	Role("Hemogoblin", "traitor")
		:SetColor(Color(0, 102, 17))
		:SetCalculateAmountFunc(function(total_players)
			return 0
		end)
		:SeenByAll()
		:SetCanSeeThroughWalls(true)

	Role("Vamplasma", "traitor")
		:SetColor(Color(128, 21, 0))
		:SetCalculateAmountFunc(function(total_players)
			return 0
		end)
		:SeenByAll()
		:SetCanSeeThroughWalls(true)
end

function ROUND:OtherRole(name)
	return (name == "Hemogoblin" and "Vamplasma" or name == "Hemogoblin" and "Vamplasma" or name)
end

ROUND.Classes = {
	{
		Name = "Reaper",
		Desc = "Quick but low health with an axe and revolver",
		Loadout = {"tfa_cso_skull9", "tfa_cso_skull1", "weapon_ttt_unarmed"},
		Model = "death_paint",
		Speed = 1.3,
		Health = 80,
	},
	{
		Name = "Wraith",
		Desc = "Slow but tanky with a revolver and rifle",
		Loadout = {"tfa_cso_skull1", "tfa_cso_skull5", "weapon_ttt_unarmed"},
		Model = "darkwraith",
		Speed = 0.75,
		Health = 120,
	},
	{
		Name = "Ghost",
		Desc = "Average stats wth an axe and rifle",
		Loadout = {"tfa_cso_skull5", "tfa_cso_skull9", "weapon_ttt_unarmed"},
		Model = "ghostface",
		Speed = 1.05,
		Health = 100,
	},
}

ROUND:Hook("TTTUpdatePlayerSpeed", function(self, state, ply, data)
	if (not state or not state.class or (SERVER and not state.class[ply])) then
		return
	end

	data.vital = self.Classes[(SERVER and state.class[ply]) or state.class].Speed or 1
end)
