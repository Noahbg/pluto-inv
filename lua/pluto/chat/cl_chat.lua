--[[ * This Source Code Form is subject to the terms of the Mozilla Public
     * License, v. 2.0. If a copy of the MPL was not distributed with this
     * file, You can obtain one at https://mozilla.org/MPL/2.0/. ]]
local pluto_chatbox_x = CreateConVar("pluto_chatbox_x", 0.05, FCVAR_ARCHIVE, "Pluto chatbox x position", 0, 1)
local pluto_chatbox_y = CreateConVar("pluto_chatbox_y", 0.15, FCVAR_ARCHIVE, "Pluto chatbox y position", 0, 1)
local pluto_chat_fade_enable = CreateConVar("pluto_chat_fade_enable", "1", FCVAR_ARCHIVE, "enable", 0, 1)
local pluto_chat_fade_sustain = CreateConVar("pluto_chat_fade_sustain", "5", FCVAR_ARCHIVE, "sustain", 0, 10)
local pluto_chat_fade_length = CreateConVar("pluto_chat_fade_length", "0.5", FCVAR_ARCHIVE, "length", 0, 10)
local pluto_chat_closed_alpha = CreateConVar("pluto_chat_closed_alpha", "0", FCVAR_ARCHIVE, "alpha", 0, 0.75)

local function reposition()
	if (IsValid(pluto.chat.Box)) then
		pluto.chat.Box:SetPos(pluto_chatbox_x:GetFloat() * ScrW(), ScrH() * (1 - pluto_chatbox_y:GetFloat()) - pluto.chat.Box:GetTall())
	end
end

pluto.chat.cl_commands = {
	{
		aliases = {
			"screenshot",
			"ss",
			"scr",
			"srnsht",
			"capture",
		},
		Run = function(channel)
			local ScreenshotRequested = true
			hook.Add("PostRender", "pluto_screenshot", function()
				if (not ScreenshotRequested) then
					return
				end
				ScreenshotRequested = false
			
				local data = render.Capture {
					format = "png",
					x = 0,
					y = 0,
					w = ScrW(),
					h = ScrH(),
					alpha = false,
				}
				imgur.image(data):next(function(data)
					SetClipboardText(data.data.link)
					chat.AddText("Screenshot link made! Paste from your clipboard.")
				end):catch(function()
					chat.AddText("Couldn't upload your screenshot. Sorry!")
				end)
			end)
		end
	},
	{
		aliases = {
			"inv",
			"inventory",
			"ps",
			"pointshop",
		},
		Run = function(channel)
			pluto.ui.toggle()
		end
	},
	{
		aliases = {
			"mapvote",
			"mv",
		},
		Run = function(channel)
			if (pluto.mapvote) then
				pluto.mapvote_create()
			end
		end
	},
	{
		aliases = {
			"commands",
			"help",
		},
		Run = function(channel)
			local commands = {}

			for _, cmd in ipairs(pluto.chat.cl_commands) do
				if (cmd.aliases[1]) then
					table.insert(commands, ttt.roles.Innocent.Color)
					table.insert(commands, cmd.aliases[1])
					table.insert(commands, white_text)
					table.insert(commands, ", ")
				end
			end

			table.remove(commands)

			chat.AddText("Here is a list of all ", ttt.roles.Innocent.Color, "chat ", white_text, "commands:")
			chat.AddText(unpack(commands))
		end
	},
}

pluto.chat.cl_commands.byname = {}
for _, cmd in ipairs(pluto.chat.cl_commands) do
	for _, alias in pairs(cmd.aliases) do
		pluto.chat.cl_commands.byname[alias] = cmd
	end
end

local chatAddText = chat.AddText
function chat.AddText(...)
	hook.Run("PlutoChatMessageReceived", "Server", {...}, false)
end

function pluto.inv.reademojis()
	local unlocked = {}
	for i = 1, net.ReadUInt(16) do
		unlocked[i] = net.ReadString()
	end
	
	pluto.cl_emojis = unlocked
end

function pluto.inv.readchatmessage()
	local teamchat = net.ReadBool()
	local channel = net.ReadString()
	local content = {}

	while (1) do
		local data
		local type = net.ReadUInt(4)

		if type == pluto.chat.type.TEXT then
			data = net.ReadString()
		elseif type == pluto.chat.type.COLOR then
			data = net.ReadColor()
		elseif type == pluto.chat.type.PLAYER then
			data = net.ReadEntity()
		elseif type == pluto.chat.type.ITEM then
			data = pluto.inv.readitem()
		elseif type == pluto.chat.type.CURRENCY then
			data = pluto.currency.byname[net.ReadString()]
		elseif (type == pluto.chat.type.IMAGE) then
			data = table.Copy(pluto.emoji.byname[net.ReadString()])
			data.Size = Vector(net.ReadUInt(8), net.ReadUInt(8))
		elseif (type == pluto.chat.type.NONE) then
			break
		end

		table.insert(content, data)
	end

	hook.Run("PlutoChatMessageReceived", channel, content, teamchat)
end

function pluto.inv.writechat(teamchat, data)
	net.WriteBool(teamchat)

	net.WriteString(table.concat(data, " "))
end

function pluto.inv.writechatopen(b)
	net.WriteBool(b)
end


local _chat = pluto.newchat or {}
pluto.newchat = _chat

local PANEL = {}

function PANEL:Init()
	self:SetSize(math.max(450, ScrW()/4),math.max(300, ScrH()/4))
	self:SetPos(0, 0)
	self:MakePopup()

	self.Input = self.EmptyContainerContainer:Add "pluto_inventory_textentry"
	self.Input:SetFont "pluto_chat_font"
	self.Input:Dock(BOTTOM)
	function self.Input:OnKeyCode(key)
		if (key == KEY_UP) then
			self:SetText(self.LastMessage or "")
			self:SetCaretPos(#self:GetText())
			return true
		elseif (key == KEY_TAB) then
			local pos = self:GetCaretPos()
			local text = self:GetText()
			local last_space = text:sub(1, pos):match("[^ ]+$")
			if (last_space) then
				for _, ply in ipairs(player.GetAll()) do
					local nick = ply:Nick()
					if (nick:lower():StartWith(last_space:lower())) then
						self:SetText(text:sub(1, pos - last_space:len()) .. nick .. text:sub(pos + 1))
						self:SetCaretPos(pos - last_space:len() + nick:len())
					end
				end
			end

			return true
		end
	end
	function self.Input.OnEnter(_, text)
		self:OnInput(text)
	end
	function self.Input.OnChange(s)
		local t = s:GetText()
		for _, channel in ipairs(pluto.chat.channels) do
			if (t:StartWith(channel.Prefix)) then
				s:SetText(t:sub(channel.Prefix:len() + 1))
				self:ChangeToTab(channel.Name)
			end
		end
	end
	self.Input:DockMargin(0, 4, 0, 0)

	self.Emojis = self.Input:Add "DImage"
	self.Emojis:SetCursor "hand"
	self.Emojis:Dock(RIGHT)
	self.Emojis:SetMouseInputEnabled(true)
	self.Emojis:DockMargin(4, 2, 4, 2)
	self.Emojis:SetImage "icon16/emoticon_evilgrin.png"
	function self.Emojis:PerformLayout(w, h)
		self:SetWide(h)
	end
	function self.Emojis.OnMousePressed()
		self:OpenEmojis()
	end

	self.ChatLabel = self.Input:Add "pluto_label"
	self.ChatLabel:Dock(LEFT)
	self.ChatLabel:DockMargin(4, 2, 4, 2)
	self.ChatLabel:SetFont "pluto_chat_font_s"
	self.ChatLabel:SetContentAlignment(5)
	self.ChatLabel:SetTextColor(Color(255, 255, 255))
	self.ChatLabel:SetText "ALL"
	self.ChatLabel:SizeToContentsX()

	self.TextHistories = {}

	for _, channel in ipairs(pluto.chat.channels) do
		self:AddTab(channel.Name, function(p)
			local container = p:Add "pluto_inventory_component"
			container:Dock(FILL)
			container:SetColor(Color(0, 0, 0, 0))
			container:SetCurve(4)

			
			local text = container:Add "pluto_text"
			text:DockMargin(4, 4, 4, 9)
			text:Dock(FILL)
			text:SetDefaultRenderSystem "shadow"
			text:SetDefaultFont "pluto_chat_font"
			text:SetDefaultTextColor(Color(255, 255, 255))
			text.Channel = channel
			text.Container = container
			self.TextHistories[channel.Name] = text
		end, true)
		self:ChangeToTab(channel.Name) -- cache it NOW or else
	end
	self:ChangeToTab(pluto.chat.channels[1].Name)

	hook.Add("PlayerBindPress", self, function(self, ply, bind, pressed)
		if (bind == "messagemode") then
			self:OpenForInput()
			return true
		elseif (bind == "messagemode2") then
			self:OpenForInput(true)
			return true
		end
	end)

	hook.Add("HUDShouldDraw", self, function(self, name) 
		if (name == "CHudChat") then
			return false
		end
	end)

	hook.Add("PlutoChatMessageReceived", self, self.PlutoChatMessageReceived)

	self.PlayerColor = ttt.roles.Innocent.Color
	self.ChatLinkColor = Color(128, 128, 200)
	self.DeadColor = Color(200, 20, 60)
	local x, y = pluto_chatbox_x:GetFloat(), pluto_chatbox_y:GetFloat()
	self:SetPos(ScrW() * x, ScrH() * (1 - y))
	self:OnPositionUpdated()

	self:EnableInput(false)
end

function PANEL:OnRemove()
	if (IsValid(self.EmojiWindow)) then
		self.EmojiWindow:Remove()
	end
end

function PANEL:OpenEmojis()
	if (IsValid(self.EmojiWindow)) then
		self.EmojiWindow:Remove()
		return
	end

	local image_size = 24
	local pad = 4
	local perline = 10

	self.EmojiWindow = self:Add "ttt_curved_panel"
	self.EmojiWindow:SetCurve(4)
	self.EmojiWindow:SetColor(self.Container:GetColor())
	self.EmojiWindow:SetCurveBottomLeft(false)
	self.EmojiWindow:SetCurveTopLeft(false)
	self.EmojiWindow:MakePopup()
	self.EmojiWindow:DockPadding(9, 14, 9, 14)
	self.EmojiWindow:SetSize(image_size * (perline + 1) + pad * perline + pad * 2, 200)
	function self.EmojiWindow.UpdatePosition()
		local x, y = self:LocalToScreen(self:GetSize(), 0)
		self.EmojiWindow:SetPos(x, y + self:GetTall() / 2 - self.EmojiWindow:GetTall() / 2)
	end
	self.EmojiWindow:UpdatePosition()

	self.EmojiScroller = self.EmojiWindow:Add "DScrollPanel"
	self.EmojiScroller:Dock(FILL)

	local last_line
	local function getline(forcenew)
		if (IsValid(last_line) and not forcenew) then
			return last_line
		end

		local pnl = self.EmojiScroller:Add "EditablePanel"
		pnl:DockMargin(0, 0, 0, pad)
		pnl:Dock(TOP)
		last_line = pnl
		return pnl
	end

	local function getimage()
		local pnl = getline()
		local img = pnl:Add "pluto_image"
		img:DockMargin(0, 0, 4, 0)
		img:Dock(LEFT)
		if (#pnl:GetChildren() >= perline) then
			last_line = nil
		end

		return img
	end

	local done = {}

	local seperator = getline(true)
	local curve = seperator:Add "ttt_curved_panel"
	curve:SetCurve(4)
	curve:SetColor(pluto.ui.theme "InnerColor")
	curve:Dock(FILL)
	curve.Text = curve:Add "pluto_label"
	curve.Text:Dock(FILL)
	curve.Text:SetContentAlignment(4)
	curve.Text:SetTextColor(Color(255, 255, 255))
	curve.Text:SetFont "pluto_inventory_font"
	curve.Text:SetText "Unlocked Emotes"
	curve.Text:DockMargin(4, 4, 4, 4)

	getline(true)

	for _, emoji in ipairs(pluto.cl_emojis) do
		local data = pluto.emoji.byname[emoji]
		done[emoji] = true
		local pnl = getimage()
		pnl:SetFromURL(data.URL)
		pnl:SetImageSize(image_size, image_size)
		pnl:SetClickable {
			Run = function()
				self:AddInput(":" .. emoji .. ":")
			end,
			Cursor = "hand"
		}
		pnl:SetTextColor(Color(0, 0, 0))
		pnl:SetTall(32)
		pnl:SetTooltip(":" .. emoji .. ":")
	end

	seperator = getline(true)
	local curve = seperator:Add "ttt_curved_panel"
	curve:SetCurve(4)
	curve:SetColor(pluto.ui.theme "InnerColor")
	curve:Dock(FILL)
	curve.Text = curve:Add "pluto_label"
	curve.Text:Dock(FILL)
	curve.Text:SetContentAlignment(4)
	curve.Text:SetTextColor(Color(255, 255, 255))
	curve.Text:SetFont "pluto_inventory_font"
	curve.Text:SetText "Locked Emotes"
	curve.Text:DockMargin(4, 4, 4, 4)
	getline(true)

	for emoji, data in pairs(pluto.emoji.byname) do
		if (done[emoji]) then
			continue
		end

		local pnl = getimage()
		pnl:SetFromURL(data.URL)
		pnl:SetImageSize(image_size, image_size)
		pnl:SetClickable {
			Run = function()
				self:AddInput(":" .. emoji .. ":")
			end,
			Cursor = "hand"
		}
		pnl:SetTextColor(Color(0, 0, 0))
		pnl:SetTall(32)
		pnl:SetTooltip(":" .. emoji .. ":")
	end

end

function PANEL:OnPositionUpdated()
	local x, y = self:GetPos()
	
	x = math.Round(math.Clamp(x, 0, ScrW() - self:GetWide()))
	y = math.Round(math.Clamp(y, 0, ScrH() - self:GetTall()))

	pluto_chatbox_x:SetFloat(x / ScrW())
	pluto_chatbox_y:SetFloat((ScrH() - y) / ScrH())

	self:SetPos(x, y)
	if (IsValid(self.EmojiWindow)) then
		self.EmojiWindow:UpdatePosition()
	end
end

function PANEL:AddInput(what)
	local t = self.Input:GetText()
	local caret = self.Input:GetCaretPos()
	self.Input:SetText(t:sub(1, caret) .. what .. t:sub(caret + 1))
	self.Input:SetCaretPos(caret + what:len())
end

function PANEL:PlutoChatMessageReceived(channel, content, teamonly)
	local text = self.TextHistories[channel]
	if (IsValid(text)) then
		self:AddTextLine(text, content, teamonly)
		local channel = pluto.chat.channels.byname[channel]
		if (channel and channel.Relay) then
			for _, relay in pairs(channel.Relay) do
				text = self.TextHistories[relay]
				if (IsValid(text)) then
					self:AddTextLine(text, content, teamonly)
				end
			end
		end
	end
end

function PANEL:AddToText(text, what, index)
	local found = false
	if (IsColor(what) or what == nil) then
		text:SetCurrentTextColor(what)
		found = true
	elseif (IsEntity(what) and what:IsPlayer()) then
		local old = text:GetCurrentTextColor()

		if (not what:Alive() and (not LocalPlayer():Alive() or ttt.GetRoundState() ~= ttt.ROUNDSTATE_ACTIVE)) then
			text:SetCurrentTextColor(self.DeadColor)
			self:AddToText(text, "*DEAD* ")
		end

		text:SetCurrentTextColor(self.PlayerColor)
		--self:AddToText(text, what:Nick(), index)
		text:InsertPlayer(what)
		text:SetCurrentTextColor(old)

		if (index == 1) then
			self:AddToText(text, ": ", index)
		end
		found = true
	elseif (istable(what)) then
		local old = text:SetCurrentTextColor()
		if (pluto.isitem(what)) then
			found = true
			text:InsertShowcaseItem(what)
		elseif (what.Type == "emoji") then
			found = true
			text:AddImageFromURL(what.URL, what.Size.x, what.Size.y)
		elseif (what.Type == "Currency") then
			found = true
			text:InsertShowcaseItem(what)
		end
		if (found) then
			text:SetCurrentTextColor(old)
		end
	end

	if (not found) then
		local function append(t)
			MsgC(text:GetCurrentTextColor(), t)
			text:AppendText(t)
		end
		local t = tostring(what)
		local last = 1
		for before, url, after in t:gmatch "()(https?://[a-zA-Z0-9%.]+/?%S+)()" do
			if (last ~= before) then
				append(t:sub(last, before - 1))
			end
			text:InsertClickableTextStart(function()
				self:OnLinkClicked(url)
			end)
			local col = text:GetCurrentTextColor()
			text:SetCurrentTextColor(self.ChatLinkColor)
			append(url)
			text:SetCurrentTextColor(col)
			text:InsertClickableTextEnd()
			last = after
		end
		if (last <= t:len()) then
			append(t:sub(last))
		end
	end
end

function PANEL:OnLinkClicked(url)
end

function PANEL:AddTextLine(text, content, teamonly)
	self:InsertFade(text)
	text:SetCurrentTextColor()
	if (teamonly) then
		self:AddToText(text, LocalPlayer():GetRoleData().Color)
		self:AddToText(text, "[TEAM] ")
		self:AddToText(text)
	end
	for i, what in ipairs(content) do
		self:AddToText(text, what, i)
	end
	self:AddToText(text, "\n", i)
end

function PANEL:EnableInput(on)
	self:SetKeyboardInputEnabled(on)
	self:SetMouseInputEnabled(on)
	self.TabContainer:SetVisible(on)
	self.BorderContainer:SetVisible(on)
	self.Input:SetAlpha(on and 255 or 1)

	local text = self.TextHistories[self.ActiveTab]
	if (IsValid(text)) then
		if (IsValid(text.Scrollbar)) then
			text.Scrollbar:SetAlpha(on and 255 or 0)
		end

		if (IsValid(text.Container)) then
			text.Container:SetInvisible(not on)
		end

		if (not on) then
			text:SignalClose()
		end
	end

	if (on) then
		self.Input:Focus()
		self.Container:SetColor(ColorAlpha(self.Container:GetColor(), 255))
		self.Main:SetColor(ColorAlpha(self.Main:GetColor(), 255))

		if (IsValid(text)) then
			text:ResetAllFades(true, false, -1 or pluto_chat_fade_sustain:GetFloat())
		end
	else
		if (IsValid(self.EmojiWindow)) then
			self.EmojiWindow:Remove()
		end
		self:SetTeamChat(false)
		self.Input:SetText ""
		self.Container:SetColor(ColorAlpha(self.Container:GetColor(), 0))
		self.Main:SetColor(ColorAlpha(self.Main:GetColor(), 0))
		
		if (IsValid(text)) then
			text:ResetAllFades(false, false, pluto_chat_fade_sustain:GetFloat())
		end
	end
end

function PANEL:SetTeamChat(teamchat)
	self.TeamChat = teamchat
	self.ChatLabel:SetText(teamchat and "TEAM" or "ALL")
	self.ChatLabel:SizeToContentsX()
end

function PANEL:GetTeamChat()
	return self.TeamChat
end

function PANEL:OpenForInput(teamchat)
	self:SetTeamChat(teamchat)
	self:EnableInput(true)
end

function PANEL:DoClose(menu)
	local r
	if (menu) then
		r = self:IsMouseInputEnabled()
	end
	self:EnableInput(false)
	return r
end

function PANEL:InsertFade(text)
	text:InsertFade(self:IsMouseInputEnabled() and -1 or pluto_chat_fade_enable:GetBool() and pluto_chat_fade_sustain:GetFloat() or -1, pluto_chat_fade_length:GetFloat())
end

function PANEL:OnInput(text)
	local ran_command = false
	if (text:StartWith "!" or text:StartWith "/") then
		local found
		for cmd, data in pairs(pluto.chat.cl_commands.byname) do
			if (text:sub(2):StartWith(cmd)) then
				found = data
				break
			end
		end
		if (not found) then
			found = hook.Run("PlutoGetChatCommand", text:sub(2))
		end

		if (found) then
			if (istable(found)) then
				found.Run(self.ActiveTab)
			end
			ran_command = true
		end
	end

	if (not ran_command and text:Trim() ~= "") then
		self.Input.LastMessage = text
		pluto.inv.message()
			:write("chat", self:GetTeamChat(), {pluto.chat.channels.byname[self.ActiveTab].Prefix .. text})
			:send()
	end
	self.Input:SetText ""
	self:EnableInput(false)
end

function PANEL:ChangeToTab(...)
	if (IsValid(pluto.opened_showcase)) then
		pluto.opened_showcase:Remove()
	end

	if (IsValid(pluto.opened_chat_player)) then
		pluto.opened_chat_player:Remove()
		print("yes")
	end

	DEFINE_BASECLASS("pluto_window")

	BaseClass.ChangeToTab(self, unpack({...}))
end

vgui.Register("pluto_chatbox_new", PANEL, "pluto_window")

local function init_chat()
	if (IsValid(_chat.panel)) then
		_chat.panel:Remove()
	end

	_chat.panel = vgui.Create "pluto_chatbox_new"
end

hook.Add("HUDPaint", "pluto_chat_init", function()
	init_chat()
	hook.Remove("HUDPaint", "pluto_chat_init")
end)

hook.Add("OnScreenSizeChanged", "pluto_chat_init", init_chat)