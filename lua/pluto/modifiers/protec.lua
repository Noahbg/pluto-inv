MOD.Type = "suffix"
MOD.Name = "Protection"
MOD.Tags = {
	"healing",
}

function MOD:IsNegative(roll)
	return false
end

function MOD:FormatModifier(index, roll)
	return string.format("%i", math.Round(roll))
end

MOD.Description = "After a righteous kill, gain %s suit armor"

MOD.Tiers = {
	{ 10, 15 },
	{ 5, 10 },
	{ 2,  5 },
}

function MOD:OnKill(wep, rolls, atk, vic)
	if (atk:GetRoleTeam() ~= vic:GetRoleTeam()) then
		if (atk:Armor() > 25) then
			return
		end

		atk:SetArmor(math.min(25, atk:Armor() + math.Round(rolls[1])))
	end
end

return MOD