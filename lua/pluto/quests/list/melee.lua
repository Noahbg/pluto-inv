QUEST.Name = "Clubber"
QUEST.Description = "Hit people rightfully with a melee in one round"
QUEST.Credits = "Phrot"
QUEST.Color = Color(204, 61, 5)

function QUEST:GetRewardText(seed)
	return seed < 0.5 and "Acidic Droplet" or "Plutonic Droplet"
end

function QUEST:Init(data)
	local current = {}
	data:Hook("TTTBeginRound", function(data, gren)
		current = {}
	end)

	data:Hook("EntityTakeDamage", function(data, vic, dmg)
		local inf, atk = dmg:GetInflictor(), dmg:GetAttacker()

		if (IsValid(inf) and atk == data.Player and inf.Slot == 0 and atk:GetRoleTeam() ~= vic:GetRoleTeam()) then
			current[vic] = true

			if (table.Count(current) == data.ProgressLeft) then
				data:UpdateProgress(data.ProgressLeft)
			end
		end
	end)
end

function QUEST:Reward(data)
	pluto.inv.addcurrency(e, seed < 0.5 and "aciddrop" or "pdrop", 1, function(succ)
		data.Player:ChatPrint("You have received a ", seed < 0.5 and "Acidic Droplet" or "Plutonic Droplet", white_text, " for completing ", self.Color, self.Name, white_text, "! Check your inventory.")
	end)
end

function QUEST:IsType(type)
	return type == 1
end

function QUEST:GetProgressNeeded(type)
	return math.random(3, 4)
end