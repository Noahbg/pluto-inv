function pluto.isdevserver()
	return GetHostName():find "[DEV]" and true or false
end

pluto.files.load {
	Server = {
		"sv/config.lua",
		"sv/maxplayers.lua",

		"weapons/weapons.lua",
		"weapons/random_spawns.lua",
		"weapons/tracker/sv_tracker.lua",

		"mods/sv_mods.lua",
		"sv/hacks.lua",
		"db/init.lua",
		"inv/init.lua",
		"inv/sv_manager.lua",
		"inv/ttt.lua",
		"inv/sv_buffer.lua",
		"trades/sv.lua",
		"mapvote/mapvote.lua",
		"models/sv_models.lua",
		"craft/sv.lua",

		"inv/exp/sv_exp_provider.lua",
		"inv/exp/sv_model_exp.lua",
		"inv/exp/sv_player_exp.lua",

		"tiers/_init.lua",

		"discord/discord.lua",
		"nitro/sv_nitro.lua",

		"quests/sv_quests.lua",

		"inv/currency/sv_currency.lua",
		"inv/currency/sv_crossmap.lua",

		"events/sv_aprilfools.lua",

		"cheaters/sv_nocheats.lua",

		"hitreg/sv_hitreg.lua",
	},
	Client = {}, -- keep empty
	Shared = {}, -- keep empty
	Resources = {
		"materials/pluto/item_bg_real.png",
		"materials/pluto/trashcan_128.png",
		"materials/pluto/icons/bluevoted.png",
		"materials/pluto/icons/voted.png",
		"materials/pluto/icons/liked.png",
		"materials/pluto/icons/disliked.png",
		"materials/pluto/icons/likednotvoted.png",
		"materials/pluto/icons/dislikednotvoted.png",
		"materials/pluto/icons/likeanddislike.png",

		"materials/pluto/newshard.png",
		"materials/pluto/newshardbg.png",

		"materials/pluto/pluto-logo-header.png",
		"materials/pluto/item_bg_mech.png",

		"materials/pluto/bg_paint7.png",
		"materials/pluto/bg_bunny4.png",

		"resource/fonts/Niconne-Regular.ttf",
		"resource/fonts/Lateef-Regular.ttf",
		"resource/fonts/Aladin-Regular.ttf",
	},
	Workshop = {
		"2275087857",
		"2277399930",
		"2277451436",

		"1516699044", -- slvbase 2
		"1516711672", -- skyrim snpcs
	},
}

concommand.Add("pluto_reload", function(ply)
	if (IsValid(ply)) then
		return
	end

	include "autorun/pluto.lua"
	BroadcastLua [[include "autorun/pluto.lua"]]
end)