
QUEST.Name = "Jedi Training"
QUEST.Description = "Kill players with a lightsaber (>5 players on)"
QUEST.Color = Color(7, 162, 247)
QUEST.RewardPool = "unique"

function QUEST:GetRewardText()
	return "Lightsaber"
end

function QUEST:Init(data)
	data:Hook("DoPlayerDeath", function(data, ply, atk, dmg)
		if (player.GetCount() < 5) then
			return
		end

		local wep = dmg:GetInflictor()
		if (IsValid(atk) and IsValid(ply) and atk:IsPlayer() and ply:GetRoleTeam() ~= atk:GetRoleTeam() and atk == data.Player and IsValid(wep) and wep:IsWeapon() and rb655_IsLightsaber(wep)) then
			local gun = wep.PlutoGun
			if (not gun) then
				data:UpdateProgress(1)
			end
		end
	end)
end

function QUEST:Reward(data)
	pluto.db.transact(function(db)
		local new_item = pluto.inv.generatebufferweapon(db, data.Player, "unique", "weapon_rb566_lightsaber")
		if (not new_item) then
			mysql_rollback(db)
			return
		end
		mysql_commit(db)

		data.Player:ChatPrint(white_text, "You have received ", startswithvowel(new_item.Tier.Name) and "an " or "a ", new_item, white_text, " for completing ", self.Color, self.Name, white_text, "!")
	end)
	
	pluto.db.transact(function(db)
		local quest = pluto.quests.give(data.Player, "light3", db)
		if (quest) then
			pluto.inv.message(data.Player)
				:write("quest", quest)
				:send()
		end
		mysql_commit(db)
	end)
end

function QUEST:GetProgressNeeded()
	return 10
end
