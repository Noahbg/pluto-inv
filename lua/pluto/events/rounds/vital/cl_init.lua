surface.CreateFont("vital_header", {
	font = "Lato",
	size = math.max(24, ScrH() * 0.05),
})
surface.CreateFont("vital_medium", {
	font = "Roboto",
	size = math.max(20, ScrH() * 0.0375),
})
surface.CreateFont("vital_small", {
	font = "Roboto",
	size = math.max(16, ScrH() * 0.025),
})
surface.CreateFont("vital_button", {
	font = "Lato",
	weight = 250,
	size = 30,
})

local PANEL = {}
local FillColor = Color(140, 25, 0)
local SelectedColor = Color(210, 25, 0)
local BorderColor = Color(0, 0, 0)

function PANEL:Init()
	self:SetSize(150, 50)
	self:SetFont("vital_button")
	self:SetContentAlignment(5)
	self:SetTextColor(BorderColor)
	self:SetText("Click Me")

	hook.Add("TTTEndRound", self, function()
		self:Remove()
	end)
end

function PANEL:SetClass(nextclass)
	self.nextclass = nextclass
	if (pluto.rounds.byname and pluto.rounds.byname.vital) then
		self:SetText(pluto.rounds.byname.vital.Classes[nextclass].Name)
	end
	self:SetPos((ScrW() + 150) / 2 + (nextclass - 3) * 200, ScrH() - 100)
end

function PANEL:DoClick()
	net.Start("vital_data")
		net.WriteUInt(self.nextclass, 32)
	net.SendToServer()
end

function PANEL:Paint(w, h)
	draw.RoundedBox(20, 0, 0, w, h, BorderColor)
	local color = FillColor
	if (pluto.rounds.state and pluto.rounds.state.nextclass and pluto.rounds.state.nextclass == self.nextclass) then
		color = SelectedColor
	end
	draw.RoundedBox(20, 2, 2, w - 4, h - 4, color)
end

vgui.Register("pluto_vital_button", PANEL, "DButton")

local outline_text = Color(12, 13, 15)

local function RenderIntro(self, state)
	local y = ScrH() / 10
	local _, h = draw.SimpleTextOutlined("The Hemogoblin and Vamplasma families are competing for dominance.", "vital_header", ScrW() / 2, y, ttt.roles.Vamplasma.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, outline_text)
	y = y + h

	_, h = draw.SimpleTextOutlined("Eliminate your enemies to show your superiority!", "vital_medium", ScrW() / 2, y, ttt.roles.Hemogoblin.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, outline_text)
end

local function RenderHeader(self, state)
	local y = ScrH() / 10
	local x = ScrW() / 2

	local _, h = draw.SimpleTextOutlined("Eliminate your enemies, but watch your health!", "vital_header", x, y, white_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, outline_text)
	y = y + h

	_, h = draw.SimpleTextOutlined("You are a " .. LocalPlayer():GetRole() .. "! Fight for your family!", "vital_small", x, y, ttt.roles[LocalPlayer():GetRole()].Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, outline_text)
	y = y + h

	if (state.vamplives and state.hemolives) then
		_, h = draw.SimpleTextOutlined(string.format("Eliminate %i more of the " .. (self:OtherRole(LocalPlayer():GetRole())) .. " family to win!", LocalPlayer():GetRole() == "Hemogoblin" and state.vamplives or state.hemolives), "vital_small", x, y, ttt.roles[self:OtherRole(LocalPlayer():GetRole())].Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(12, 13, 15))
		y = y + h
	end
end

local function RenderStats(self, state)
	local y = ScrH() / 5
	local x = 4
	local _, h
	if (state.lives) then
		_, h = draw.SimpleTextOutlined(string.format("Vitals: %i lives left!", state.lives), "vital_small", x, y, ttt.roles[LocalPlayer():GetRole()].Color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, outline_text)
		y = y + h
	end

	if (state.class) then
		_, h = draw.SimpleTextOutlined("Eliminate another " .. self.Classes[state.class].Name .. " to regain a life!", "vital_small", x, y, ttt.roles[self:OtherRole(LocalPlayer():GetRole())].Color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, outline_text)
		y = y + h
	end
end

net.Receive("vital_data", function()
	if (not pluto.rounds.state) then
		return
	end

	pluto.rounds.state[net.ReadString()] = net.ReadUInt(32)
end)

function ROUND:Prepare(state)
	state.buttons = {}

	for i = 1, 3 do
		state.buttons[i] = vgui.Create "pluto_vital_button"
		state.buttons[i]:SetClass(i)
	end
end

ROUND:Hook("TTTBeginRound", function(self, state)
	if (not timer.Exists("vital_song")) then
		EmitSound("music/hl2_song12_long.mp3", vector_origin, -2, CHAN_STATIC, 0.8)
		timer.Create("vital_song", 75, 1, function()
			if (ttt.GetCurrentRoundEvent() == "vital" and ttt.GetRoundState() == ttt.ROUNDSTATE_ACTIVE) then
				EmitSound("music/HL1_song17.mp3", vector_origin, -2, CHAN_STATIC, 0.8)
			end
		end)
	end
end)

ROUND:Hook("HUDPaint", function(self, state)
	if (not pluto.rounds.state) then
		print("SOMETHING IS WRONG HERE")
		return
	end

	if (ttt.GetRoundState() == ttt.ROUNDSTATE_PREPARING) then
		RenderIntro(self, state)
	elseif (ttt.GetRoundState() == ttt.ROUNDSTATE_ACTIVE) then
		RenderHeader(self, state)
		RenderStats(self, state)
	end

	if (state.nextclass and self.Classes[state.nextclass]) then
		local desc = self.Classes[state.nextclass].Desc
		draw.SimpleTextOutlined(desc, "vital_button", ScrW() / 2, ScrH() - 25, FillColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, BorderColor)
	end
end)

ROUND:Hook("PreventRDMManagerPopup", function()
	return true
end)

function ROUND:NotifyPrepare()
	chat.AddText(white_text, "Your ", ttt.roles.Vamplasma.Color, "heart ", white_text, "begins to beat ", ttt.roles.Hemogoblin.Color, " faster...")
end