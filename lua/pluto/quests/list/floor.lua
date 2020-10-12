QUEST.Name = "Floor Licker"
QUEST.Description = "Rightfully kill players with weapons found on the floor"
QUEST.Credits = "Mia Fey"
QUEST.Color = Color(24, 125, 216)
QUEST.RewardPool = "hourly"

function QUEST:Init(data)
	data:Hook("PlayerDeath", function(data, vic, inf, atk)
		if (ttt.GetRoundState() == ttt.ROUNDSTATE_ACTIVE and atk == data.Player and atk:GetRoleTeam() ~= vic:GetRoleTeam() and inf.FloorWeapon) then
			data:UpdateProgress(1)
		end
	end)
end

function QUEST:IsType(type)
	return type == 1
end

function QUEST:GetProgressNeeded(type)
	return math.random(10, 15)
end
