local last_active_tab = CreateConVar("pluto_last_quest_tab", "", FCVAR_ARCHIVE)

local PANEL = {}

function PANEL:Init()
	for _, quest in ipairs(pluto.quests.types) do
		self:AddTab(quest.Name, function()
			last_active_tab:SetString(quest.Name)
		end, quest.Color)
	end

	self:SelectTab(last_active_tab:GetString())

	hook.Add("PlutoUpdateQuests", self, self.UpdateQuests)
	self:UpdateQuests()

	self.QuestList = {}
end

function PANEL:AddQuest(quest)
	local tabname = pluto.quests.bypool[quest.Tier].Name
	local tab = self:GetTab(tabname)
	if (not IsValid(tab)) then
		error("no tab " .. tabname)
	end
	
	local questpnl = tab:Add "pluto_inventory_quest"
	questpnl:Dock(TOP)
	questpnl:DockMargin(0, 0, 0, 4)
	questpnl:SetQuestOnLayout(quest)
end

function PANEL:UpdateQuests()
	for _, quest in ipairs(pluto.quests.current) do
		self:AddQuest(quest)
	end
end

vgui.Register("pluto_inventory_quests", PANEL, "pluto_inventory_component_tabbed")

local PANEL = {}

function PANEL:Init()
	self:SetTall(100)
	self:SetCurve(4)
	self:SetColor(Color(95, 96, 102))
	self.Inner = self:Add "ttt_curved_panel"
	self.Inner:Dock(FILL)
	self:DockPadding(1, 1, 1, 1)
	self.Inner:SetColor(Color(53, 53, 60))
	self.Inner:SetCurve(2)
	self.Inner:DockPadding(4, 3, 4, 3)


	self.TopLine = self.Inner:Add "EditablePanel"
	self.TopLine:Dock(TOP)

	self.Name = self.TopLine:Add "pluto_label"
	self.Name:Dock(FILL)
	self.Name:SetText "HI"
	self.Name:SetTextColor(Color(255, 255, 255))
	self.Name:SetRenderSystem(pluto.fonts.systems.shadow)
	self.Name:SetFont "pluto_inventory_font_xlg"
	self.Name:SetContentAlignment(4)

	self.Name:SizeToContentsY()

	self.TopLine:SetTall(self.Name:GetTall())

	self.Description = self.Inner:Add "pluto_text_inner"
	self.Description:Dock(TOP)
	self.Description:SetDefaultTextColor(Color(255, 255, 255))
	self.Description:SetDefaultRenderSystem(pluto.fonts.systems.shadow)
	self.Description:SetDefaultFont "pluto_inventory_font"
	self.Description:SetTall(100)
	self.Description:SetMouseInputEnabled(false)
	self.Description:DockMargin(0, 0, 0, 9)

	self.Progression = self.Inner:Add "ttt_curved_panel"
	self.Progression:Dock(TOP)
	self.Progression:SetTall(13)
	self.Progression:SetCurve(4)
	self.Progression:SetColor(Color(87, 88, 94))
	self.Progression:DockPadding(1, 1, 1, 1)
	self.Progression:DockMargin(0, 0, 0, 9)

	local inner = self.Progression:Add "ttt_curved_panel"
	inner:Dock(FILL)
	inner:SetCurve(self.Progression:GetCurve() / 2)
	inner:SetColor(Color(38, 38, 38))


	self.BottomLine = self.Inner:Add "EditablePanel"
	self.BottomLine:Dock(TOP)

	self.RewardText = self.BottomLine:Add "pluto_label"
	self.RewardText:Dock(RIGHT)
	self.RewardText:SetText "Reward text"
	self.RewardText:SetTextColor(Color(255, 255, 255))
	self.RewardText:SetRenderSystem(pluto.fonts.systems.shadow)
	self.RewardText:SetFont "pluto_inventory_font"
	self.RewardText:SetContentAlignment(5)
	self.RewardText:SizeToContents()

	self.TimeRemaining = self.BottomLine:Add "pluto_label"
	self.TimeRemaining:Dock(FILL)
	self.TimeRemaining:SetText ""
	self.TimeRemaining:SetTextColor(Color(128, 128, 128))
	self.TimeRemaining:SetRenderSystem(pluto.fonts.systems.shadow)
	self.TimeRemaining:SetFont "pluto_inventory_font"
	self.TimeRemaining:SetContentAlignment(4)
	self.TimeRemaining:SizeToContents()

	self.BottomLine:SetTall(self.RewardText:GetTall())
end

function PANEL:SetQuestOnLayout(quest)
	self.LayoutQuest = quest
end

function PANEL:PerformLayout(w, h)
	-- HACK(meep): why??
	timer.Simple(0, function()
		if (not IsValid(self)) then
			return
		end
		if (not self.LayoutQuest) then
			return
		end
		local q = self.LayoutQuest
		self.LayoutQuest = nil
		self:SetQuest(q)
	end)
end

function PANEL:SetQuest(quest)
	self.Quest = quest
	self.Name:SetText(quest.Name)
	self.Name:SetTextColor(quest.Color)

	if (not self.HasSet) then
		self.Description:AppendText(quest.Description .. "\n")
		self.Description:SizeToContentsY()
		self.HasSet = true
	end

	self.RewardText:SetText("Reward: " .. quest.Reward)
	self.RewardText:SizeToContentsX()
	self:SetTall(3 + self.TopLine:GetTall() + self.Description:GetTall() + 9 + self.Progression:GetTall() + 9 + self.BottomLine:GetTall() + 6)
end

function PANEL:Think()
	if (not self.Quest) then
		return
	end

	local time_remaining = self.Quest.EndTime - os.time()

	self.TimeRemaining:SetText(admin.nicetimeshort(time_remaining))
end

vgui.Register("pluto_inventory_quest", PANEL, "ttt_curved_panel")