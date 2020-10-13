local MAX_LENGTH = 128

function pluto.chat.Send(ply, ...)
	local args = {...}

	pluto.inv.message(ply)
		:write("chatmessage", args)
	:send()
end

function pluto.inv.readchat(from)
	local teamchat = net.ReadBool()
	local texts = net.ReadString()
	local content = {
		from,
	}

	local replace = hook.Run("PlayerSay", from, texts, teamchat)

	if replace == "" or not replace then return end

	local last_pos = 1
	local length = 0

	for pos, match, next_pos in replace:gmatch "(){([^%}]+)}()" do
		if (pos ~= last_pos) then
			if (length + pos - last_pos > MAX_LENGTH) then
				table.insert(content, replace:sub(last_pos, last_pos + MAX_LENGTH - length))
				break
			end
			length = length + last_pos - pos
			table.insert(content, replace:sub(last_pos, pos - 1))
		end

		local what, id = match:match "^([^:]+):(.+)$"

		local done = false

		local item
		local eq = pluto.inv.invs[from].tabs.equip

		if (what == "item") then
			local slot = pluto.itemids[tonumber(id)]
			if (item and item.Owner == from:SteamID64()) then
				item = slot
			end
		elseif (match == "primary") then
			item = eq.Items[1]
		elseif (match == "secondary") then
			item = eq.Items[2]
		elseif (match == "model") then
			item = eq.Items[3]
		elseif (match == "melee") then
			item = eq.Items[4]
		elseif (match == "grenade") then
			item = eq.Items[5]
		elseif (match == "other" or match == "holster") then
			item = eq.Items[6]
		elseif (match == "pickup") then
			item = eq.Items[7]
		elseif (match == "loadout") then
			
			local eq = pluto.inv.invs[from].tabs.equip

			for i = 1, 14 do
				local slot = eq.Items[i]
				
				if (slot) then
					table.insert(content, slot)
					table.insert(content, " ")
					length = length + slot:GetPrintName():len() + 1
				end
			end

			done = true
		end

		if (item) then
			table.insert(content, item)
			length = length + item:GetPrintName():len()
			done = true
		end

		if (not done) then
			table.insert(content, "{" .. match .. "}")
		end

		if (length > MAX_LENGTH) then
			break
		end

		last_pos = next_pos
	end

	if (pos ~= #replace) then
		table.insert(content, replace:sub(last_pos, last_pos + math.max(0, MAX_LENGTH - length)))
	end

	for _,ply in pairs(player.GetAll()) do
		local canSee = hook.Run("PlayerCanSeePlayersChat", texts, teamchat, ply, from)
		if canSee then
			pluto.inv.message(ply)
				:write("chatmessage", content, "server", teamchat)
			:send()
		end
	end
end

function pluto.inv.writechatmessage(ply, content, channel, teamchat)
	channel = channel or "server"

	net.WriteBool(teamchat)
	net.WriteString(channel)

	for _, data in ipairs(content) do
		local tpid = TypeID(data)

		if (tpid == TYPE_ENTITY) then
			net.WriteUInt(pluto.chat.type.PLAYER, 4)
			net.WriteEntity(data)
		elseif (IsColor(data)) then
			net.WriteUInt(pluto.chat.type.COLOR, 4)
			net.WriteColor(data)
		elseif (tpid == TYPE_STRING) then
			net.WriteUInt(pluto.chat.type.TEXT, 4)
			net.WriteString(data)
		elseif (tpid == TYPE_TABLE) then
			if (pluto.iscurrency(data)) then
				net.WriteUInt(pluto.chat.type.CURRENCY, 4)
				net.WriteString(data.InternalName)
			elseif (pluto.isitem(data)) then
				if (not data.RowID) then
					net.WriteUInt(pluto.chat.type.COLOR, 4)
					net.WriteColor(data.Tier.Color)
					net.WriteUInt(pluto.chat.type.TEXT, 4)
					net.WriteString(data:GetPrintName())
				else
					net.WriteUInt(pluto.chat.type.ITEM, 4)
					pluto.inv.writeitem(ply, data)
				end
			else
				net.WriteUInt(pluto.chat.type.TEXT, 4)
				net.WriteString(tostring(data))
			end
		else
			net.WriteUInt(pluto.chat.type.TEXT, 4)
			net.WriteString(tostring(data))
		end
	end
	net.WriteUInt(pluto.chat.type.NONE, 4)
end