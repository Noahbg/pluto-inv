-- Author: add___123

if (SERVER) then
    util.AddNetworkString "pluto_mini_dash"
    resource.AddFile "materials/pluto/roles/dasher.png"

    local dasher
    local time = 0

    hook.Add("TTTEndRound", "pluto_mini_dash", function()
        hook.Remove("PlayerCanPickupWeapon", "pluto_mini_dash")
        hook.Remove("DoPlayerDeath", "pluto_mini_dash")

        dasher = nil
    end)

    hook.Add("TTTBeginRound", "pluto_mini_dash", function()
        if (ttt.GetCurrentRoundEvent() ~= "") then
            return
        end

        if (not pluto.rounds or not pluto.rounds.minis) then
            return
        end

        if (not pluto.rounds.minis.dash and math.random(50) ~= 1) then
            return
        end
        
        pluto.rounds.minis.dash = nil

        if (pluto.rounds.args and pluto.rounds.args[2]) then
            for k, ply in ipairs(player.GetHumans()) do
                if (ply:SteamID64() == pluto.rounds.args[2]) then
                    dasher = ply
                    break
                end
            end
        else
            for k, ply in ipairs(table.shuffle(round.GetActivePlayersByRole "Innocent")) do
                if (not IsValid(ply) or not ply:Alive() or ply:IsBot()) then
                    continue
                end
                dasher = ply
                break
            end
        end

        if (not IsValid(dasher)) then
            return
        end

        net.Start "pluto_mini_dash"
        net.Send(dasher)
        time = CurTime() + 15

        pluto.rounds.args = {}
    end)

    net.Receive("pluto_mini_dash", function(len, ply)
        if (not IsValid(ply) or not IsValid(dasher) or not dasher:Alive() or ply ~= dasher or time < CurTime()) then
            return 
        end

        dasher:SetRole "Dasher"
        dasher:SetMaxHealth(250)
        dasher:SetHealth(250)
        dasher:SetJumpPower(dasher:GetJumpPower() + 100)
        dasher:StripWeapons()
        pluto.NextWeaponSpawn = false
        dasher:Give "weapon_ttt_unarmed"

        pluto.rounds.speeds[dasher] = (pluto.rounds.speeds[dasher] or 1) + 0.75
        net.Start "mini_speed"
            net.WriteFloat(pluto.rounds.speeds[dasher])
        net.Send(dasher)

        pluto.rounds.Notify(dasher:Nick() .. " has stolen your models! Kill them to get back your look!", Color(255, 128, 0))

        local models = {}

        for _, ply in pairs(player.GetAll()) do
            if (not ply:Alive() or ply == dasher) then
                continue
            end

            models[ply] = ply:GetModel()
            ply:SetModel(dasher:GetModel())
        end

        hook.Add("PlayerCanPickupWeapon", "pluto_mini_dash", function(ply, wep)
            if (ply == dasher) then
                return wep:GetClass() == "weapon_ttt_unarmed"
            end
        end)

        hook.Add("DoPlayerDeath", "pluto_mini_dash", function(vic, att, dmg)
            if (not IsValid(vic) or vic ~= dasher) then
                return
            end

            for _, ply in ipairs(player.GetAll()) do
                if (IsValid(ply) and ply:Alive() and models[ply]) then
                    ply:SetModel(models[ply])
                    pluto.rounds.Notify(dasher:Nick() .. " has been killed! Your model has been returned.", Color(255, 128, 0), ply)
                else
                    pluto.rounds.Notify(dasher:Nick() .. " has been killed!", Color(255, 128, 0), ply)
                end
            end

            hook.Remove("DoPlayerDeath", "pluto_mini_dash")
        end)
    end)
else
    net.Receive("pluto_mini_dash", function()
        local dashbutton = vgui.Create "pluto_mini_button"
        dashbutton:ChangeText "Click to steal all models! (KOSable)"
        dashbutton:ChangeMini "dash"
        dashbutton.FillColor = Color(255, 128, 0)

        timer.Simple(14, function()
            if (IsValid(dashbutton)) then
                dashbutton:Remove()
            end
        end)
    end)
end

hook.Add("TTTPrepareRoles", "dasher", function(Team, Role)
	Team "dasher"
		:SetColor(Color(255, 128, 0))
		:SeenBy {"traitor", "innocent"}
		:SetDeathIcon "materials/pluto/roles/dasher.png"

	Role("Dasher", "dasher")
		:SetCalculateAmountFunc(function(total_players)
			return 0
		end)
end)