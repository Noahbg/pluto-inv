
local function IsTTC()
	if (CLIENT) then
		return util.NetworkStringToID "pluto_ttc" ~= 0
	else
		return CreateConVar("pluto_ttc", "0", {FCVAR_REPLICATED, FCVAR_ARCHIVE}):GetBool()
	end
end

if (SERVER) then
	if (not IsTTC()) then
		return
	end
	
	util.AddNetworkString "pluto_ttc"
end


print "TTC"

pluto.files.load {
	Client = {
	},
	Shared = {
		"roles/regenerative/sh_regenerative.lua",
		"roles/jester/sh_jester.lua",
	},
	Server = {
		"roles/regenerative/sv_regenerative.lua",
		"roles/jester/sv_jester.lua",
	},
	Resources = {},
}