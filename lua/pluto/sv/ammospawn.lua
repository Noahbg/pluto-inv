--[[ * This Source Code Form is subject to the terms of the Mozilla Public
     * License, v. 2.0. If a copy of the MPL was not distributed with this
     * file, You can obtain one at https://mozilla.org/MPL/2.0/. ]]

local Weapons

local function Regenerate()
    Weapons = {}
    for _, ent in ipairs(weapons.GetList()) do
        if (ent.AutoSpawnable and not ent.Duped) then
            table.insert(Weapons, ent.ClassName)
        end
    end
end

hook.Add("TTTBeginRound", "ammospawn", function()
	Regenerate()
	for i = #ents.FindByClass "ttt_random_ammo", 50 do
		
		local class = table.Random(ttt.ammo.getcache().entlookup)
		local e = ents.Create(class)

		if (not IsValid(e)) then
			warn("Class %s does not exist! Removing replacement entity.\n", class)
			self:Remove()
			return
		end

		e:SetAngles(angle_zero)
		e:SetPos(pluto.currency.randompos())

		e:Spawn()
	end
	for i = #ents.FindByClass "ttt_random_weapon", 50 do
		local class = table.Random(Weapons)
		local e = ents.Create(class)

		if (not IsValid(e)) then
			warn("Class %s does not exist! Removing replacement entity.\n", class)
			self:Remove()
			return
		end

		e:SetAngles(angle_zero)
		e:SetPos(pluto.currency.randompos())

		e:Spawn()
	end
end)
