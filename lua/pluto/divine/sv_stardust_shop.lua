-- starchaser weapons
-- shards
-- starseeker
-- sapientia, acr, scar

local function buildoptions()
	local options = {
		ow_shard = {
			Shares = 20,
			Buy = function(ply, item)
				pluto.db.transact(function(db)
					if (not pluto.inv.addcurrency(db, ply, "stardust", -item.Price)) then
						mysql_rollback(db)
						return
					end
					pluto.inv.generatebuffershard(db, ply, "BOUGHT", "otherworldly")
					mysql_stmt_run(db, "UPDATE pluto_stardust_shop SET endtime = endtime - INTERVAL 1 HOUR WHERE id = ?", item.rowid)
					item.EndTime = item.EndTime - 60 * 60
					mysql_commit(db)
				end)
			end,
			PreviewItem = {
				ClassName = "shard",
				Tier = pluto.tiers.byname.otherworldly,
			},
			Price = {5000, 7000},
		},
		conf_shard = {
			Shares = 20,
			Buy = function(ply, item)
				pluto.db.transact(function(db)
					if (not pluto.inv.addcurrency(db, ply, "stardust", -item.Price)) then
						mysql_rollback(db)
						return
					end
					pluto.inv.generatebuffershard(db, ply, "BOUGHT", "confused")
					mysql_stmt_run(db, "UPDATE pluto_stardust_shop SET endtime = endtime - INTERVAL 1 HOUR WHERE id = ?", item.rowid)
					item.EndTime = item.EndTime - 60 * 60
					mysql_commit(db)
				end)
			end,
			PreviewItem = {
				ClassName = "shard",
				Tier = pluto.tiers.byname.confused,
			},
			Price = {2000, 3000}
		},
		starar = {
			Shares = 1,
			Buy = function(ply, item)
				pluto.db.transact(function(db)
					if (not pluto.inv.addcurrency(db, ply, "stardust", -item.Price)) then
						mysql_rollback(db)
						return
					end
					pluto.inv.generatebufferweapon(db, ply, "BOUGHT", "unusual", "tfa_cso_starchaserar")
					mysql_stmt_run(db, "UPDATE pluto_stardust_shop SET endtime = endtime - INTERVAL 1 HOUR WHERE id = ?", item.rowid)
					item.EndTime = item.EndTime - 60 * 60
					mysql_commit(db)
				end)
			end,
			PreviewItem = {
				ClassName = "tfa_cso_starchaserar",
				Tier = pluto.tiers.byname.unusual,
				Mods = {
					implicit = {},
					prefix = {},
					suffix = {},
				}
			},
			Price = {25000, 35000},
		},
		starsr = {
			Shares = 1,
			Buy = function(ply, item)
				pluto.db.transact(function(db)
					if (not pluto.inv.addcurrency(db, ply, "stardust", -item.Price)) then
						mysql_rollback(db)
						return
					end
					local new_item = pluto.weapons.generatetier("unique", "tfa_cso_starchasersr")
		
					pluto.weapons.addmod(new_item, "starseeker")
					new_item.CreationMethod = "BOUGHT"
				
					pluto.inv.savebufferitem(db, ply, new_item)
					mysql_stmt_run(db, "UPDATE pluto_stardust_shop SET endtime = endtime - INTERVAL 1 HOUR WHERE id = ?", item.rowid)
					item.EndTime = item.EndTime - 60 * 60
					mysql_commit(db)
				end)
			end,
			PreviewItem = {
				ClassName = "tfa_cso_starchasersr",
				Tier = pluto.tiers.byname.unique,
				Mods = {
					implicit = {
						{
							Tier = 1,
							Roll = {},
							Mod = "starseeker"
						},
					},
					prefix = {},
					suffix = {},
				}
			},
			Price = {25000, 35000},
		}
	}


	local promised_shares = 300
	for _, wep in ipairs(pluto.weapons.guns) do
		options["promised_" .. wep] = {
			Shares = promised_shares / #pluto.weapons.guns,
			Buy = function(ply, item)
				pluto.db.transact(function(db)
					if (not pluto.inv.addcurrency(db, ply, "stardust", -item.Price)) then
						mysql_rollback(db)
						return
					end
					pluto.inv.generatebufferweapon(db, ply, "BOUGHT", "promised", wep)
					mysql_stmt_run(db, "UPDATE pluto_stardust_shop SET endtime = endtime - INTERVAL 1 HOUR WHERE id = ?", item.rowid)
					item.EndTime = item.EndTime - 60 * 60
					mysql_commit(db)
				end)
			end,
			PreviewItem = {
				ClassName = wep,
				Tier = pluto.tiers.byname.promised,
				Mods = {
					implicit = {},
					prefix = {},
					suffix = {},
				}
			},
			Price = {2500, 3000}
		}
	end

	local seeker_shares = 50
	for _, wep in ipairs(pluto.weapons.guns) do
		options["seeker_" .. wep] = {
			Shares = seeker_shares / #pluto.weapons.guns,
			Buy = function(ply, item)
				pluto.db.transact(function(db)
					if (not pluto.inv.addcurrency(db, ply, "stardust", -item.Price)) then
						mysql_rollback(db)
						return
					end

					local new_item = pluto.weapons.generatetier("mystical", wep)
		
					pluto.weapons.addmod(new_item, "starseeker")
					new_item.CreationMethod = "BOUGHT"
				
					pluto.inv.savebufferitem(db, ply, new_item)
					
					mysql_stmt_run(db, "UPDATE pluto_stardust_shop SET endtime = endtime - INTERVAL 1 HOUR WHERE id = ?", item.rowid)
					item.EndTime = item.EndTime - 60 * 60
					mysql_commit(db)
				end)
			end,
			PreviewItem = {
				ClassName = wep,
				Tier = pluto.tiers.byname.mystical,
				Mods = {
					implicit = {
						{
							Tier = 1,
							Roll = {},
							Mod = "starseeker"
						}
					},
					prefix = {},
					suffix = {},
				}
			},
			Price = {6000, 7000}
		}
	end

	return options
end

pluto.divine = pluto.divine or {}
pluto.divine.stardust_shop = {}


function pluto.inv.writestardustshop(p)
	net.WriteUInt(#pluto.divine.stardust_shop.available, 32)
	for _, item in pairs(pluto.divine.stardust_shop.available) do
		pluto.inv.writebaseitem(p, item.PreviewItem)
		net.WriteUInt(item.Price, 32)
		net.WriteUInt(item.EndTime - os.time(), 32)
	end
end

concommand.Add("pluto_buy_stardust_shop", function(p, c, a)
	if (not pluto.divine.stardust_shop.available) then
		return
	end

	local item = pluto.divine.stardust_shop.available[tonumber(a[1])]

	if (not item) then
		return
	end

	if (item.EndTime < os.time()) then
		pluto.divine.stardust_shop = {}
		p:ChatPrint("That item is no longer available. Reopen the shop.")
		return
	end
	
	item.Buy(p, item)
end)

concommand.Add("pluto_send_stardust_shop", function(p)
	local function finish()
		pluto.inv.message(p)
			:write "stardustshop"
			:send()
	end
	
	if (pluto.divine.stardust_shop.available) then
		finish()
		return
	end

	local options = buildoptions()

	local available = {}
	pluto.divine.stardust_shop.available = available

	pluto.db.transact(function(db)
		mysql_query(db, "LOCK TABLES pluto_stardust_shop WRITE")
		mysql_query(db, "DELETE FROM pluto_stardust_shop WHERE endtime < CURRENT_TIMESTAMP")
		local items = mysql_query(db, "SELECT id, item, price, TIMESTAMPDIFF(SECOND, CURRENT_TIMESTAMP, endtime) as remaining FROM pluto_stardust_shop")

		for _, item in ipairs(items) do
			local data = table.Copy(options[item.item])
			data.id = item.item
			data.Price = item.price
			data.EndTime = os.time() + item.remaining
			data.rowid = item.id
			setmetatable(data.PreviewItem, pluto.inv.item_mt)
			table.insert(available, data)
		end
	
		for i = #available + 1, 8 do
			local id, data = pluto.inv.roll(options)
			data = table.Copy(data)
			data.id = id
			available[i] = data
			setmetatable(data.PreviewItem, pluto.inv.item_mt)
			if (istable(data.Price)) then
				data.Price = math.random(data.Price[1], data.Price[2])
			end
			data.EndTime = os.time() + 60 * 60 * 24
			data.rowid = mysql_stmt_run(db, "INSERT INTO pluto_stardust_shop (item, price, endtime) VALUES(?, ?, TIMESTAMPADD(HOUR, 5, CURRENT_TIMESTAMP))", id, data.Price).LAST_INSERT_ID
		end

		mysql_query(db, "UNLOCK TABLES")
		finish()
	end)
end)