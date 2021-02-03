local PANEL = {}

local item_size = 56
local inner_area = 5
local outer_area = 10

function PANEL:Init()
	self:SetWide(item_size * 6 + inner_area * 5 + outer_area * 2)
	self.UpperArea = self:Add "EditablePanel"
	self.UpperArea:Dock(TOP)
	self.UpperArea:SetTall(22)

	self.SearchyBoiText = self.UpperArea:Add "DTextEntry"
	self.SearchyBoiText:Dock(RIGHT)
	self.SearchyBoiText:SetWide(100)
	self.SearchyBoiText:SetFont "pluto_inventory_font"
	self.SearchyBoiText:SetKeyboardInputEnabled(true)

	function self.SearchyBoiText:OnMousePressed(m)
		if (m == MOUSE_LEFT) then
			pluto.ui.pnl:SetKeyboardInputEnabled(true)
		end
	end

	function self.SearchyBoiText.OnFocusChanged(s, gained)
		if (not gained) then
			pluto.ui.pnl:SetKeyboardInputEnabled(false)
		end
	end

	function self.SearchyBoiText.OnChange(s)
		self:SearchItems(s:GetValue())
	end

	self.SearchyBoiText:DockMargin(0, 4, 0, 3)

	self.SearchyBoi = self.UpperArea:Add "pluto_label"
	self.SearchyBoi:Dock(RIGHT)
	self.SearchyBoi:SetTextColor(Color(255, 255, 255))
	self.SearchyBoi:SetRenderSystem(pluto.fonts.systems.shadow)
	self.SearchyBoi:SetFont "pluto_inventory_font"
	self.SearchyBoi:SetText "Search"
	self.SearchyBoi:DockMargin(0, 4, 5, 3)
	self.SearchyBoi:SizeToContentsX()


	self.Upper = self.UpperArea:Add "ttt_curved_panel"
	self.Upper:Dock(LEFT)
	self.Upper:SetWide(100)
	self.Upper:DockPadding(0, 4, 0, 3)

	self.UpperLabel = self.Upper:Add "pluto_label"
	self.UpperLabel:SetContentAlignment(5)
	self.UpperLabel:SetFont "pluto_inventory_font"
	self.UpperLabel:SetTextColor(Color(255, 255, 255))
	self.UpperLabel:SetRenderSystem(pluto.fonts.systems.shadow)
	self.UpperLabel:Dock(FILL)

	self.Container = self:Add "pluto_inventory_component"
	DEFINE_BASECLASS "pluto_inventory_component"
	self.Container:Dock(FILL)
	self.ItemContainer = self.Container:Add "EditablePanel"
	self.ItemContainer:SetSize(item_size * 6 + inner_area * 5, item_size * 6 + inner_area * 5)

	function self.Container.PerformLayout(s, w, h)
		BaseClass.PerformLayout(s, w, h)
		self.ItemContainer:Center()
	end

	self.ItemRows = {}
	self.Items = {}
	self.ItemHighlights = {}

	for i = 1, 6 do
		local row = self.ItemContainer:Add "EditablePanel"
		self.ItemRows[i] = row

		for j = 1, 6 do
			local item = row:Add "pluto_inventory_item"
			item:SetCanPickup(true)
			table.insert(self.Items, item)
			item:Dock(LEFT)
			if (j ~= 6) then
				item:DockMargin(0, 0, inner_area, 0)
			end

			function item.OnLeftClick(s)
				-- this is claiming a buffer item (for now)
				local p = pluto.ui.pickupitem(s)
				if (not IsValid(p)) then
					return
				end

				function p.ClickedOn(_, other)
					timer.Simple(0, function()
						table.remove(pluto.buffer, s.TabIndex)
						hook.Run "PlutoBufferChanged"
						self:SwapToBuffer(true)
					end)
				end

				self:SwapToBuffer(false)
			end
		end

		row:Dock(TOP)
		row:SetTall(56)
		if (i ~= 6) then
			row:DockMargin(0, 0, 0, inner_area)
		end
	end


	self.Container:SetCurveTopLeft(false)
	self.Upper:SetCurveBottomLeft(false)
	self.Upper:SetCurveBottomRight(false)

	self:SetText "Inventory"
end

function PANEL:AddTab(tab)
	if (not self.ActiveTab) then
		self:PopulateFromTab(tab)
		self.ActiveTab = tab
	end
end

function PANEL:SetText(t)
	self.UpperLabel:SetText(t)
	
	local surface = self.UpperLabel:GetRenderSystem() or surface
	surface.SetFont(self.UpperLabel:GetFont())
	local tw, th = surface.GetTextSize(t)

	self.Upper:SetWide(tw + 24)
end

function PANEL:PopulateFromTab(tab)
	if (self.BufferActive and tab.Type ~= "buffer") then
		return
	elseif (tab.Type ~= "buffer") then
		self.ActiveTab = tab
	end

	self.ItemHighlights = {}
	local tabtype = pluto.tabs[tab.Type]
	if (not tabtype) then
		ErrorNoHalt("unknown how to handle tab type " .. tab.Type)
		return
	end

	for i = 1, 36 do
		local item = tab.Items[i]
		self.Items[i]:SetUpdateFrom(tab.ID, i)
		self.Items[i]:SetItem(item)

		self.Items[i].CanClickWith = function(s, other)
			return tabtype.canaccept(i, other.Item)
		end
	end
	pluto.ui.realpickedupitem = nil
	if (IsValid(pluto.ui.pickedupitem)) then
		local p = pluto.ui.pickedupitem
		if (p.TabID  == tab.ID) then
			pluto.ui.realpickedupitem = self.Items[p.TabIndex]
		end
	end

	if (self.SearchText) then
		self:SearchItems(self.SearchText)
	end
end

function PANEL:SetCurve(curve)
	self.Container:SetCurve(curve)
	self.Upper:SetCurve(curve)
end

function PANEL:SetColor(col)
	self.Container:SetColor(col)
	self.Upper:SetColor(col)
end

function PANEL:SetStorageHandler(pnl)
	self.Handler = pnl
end

function PANEL:OnMouseWheeled(wheel)
	if (IsValid(self.Handler)) then
		self.Handler:HandleStorageScroll(wheel)
	end
end

function PANEL:HighlightItem(item, lifetime)
	table.insert(self.ItemHighlights, {
		StartTime = CurTime(),
		TabIndex = item,
		Lifetime = lifetime or 2,
	})
end

function PANEL:PaintOver()
	for i = #self.ItemHighlights, 1, -1 do
		local item = self.ItemHighlights[i]
		if (item.StartTime + item.Lifetime < CurTime()) then
			table.remove(self.ItemHighlights, i)
			continue
		end
		
		local pnl = self.Items[item.TabIndex]
		local frac = (CurTime() - item.StartTime) / item.Lifetime

		local x, y = self:ScreenToLocal(pnl:LocalToScreen(0, 0))
		local w, h = pnl:GetSize()
		surface.SetDrawColor(255, 255, 255, (1 - frac) * 255)
		surface.DrawOutlinedRect(x, y, w, h, 4)
	end
end

PANEL.FilterTypes = {
	type = function(item, text)
		text = text:sub(1, 1):upper() .. text:sub(2):lower()
		return item.Type == text
	end,
	name = function(item, text)
		return item:GetPrintName():lower():find(text, nil, true)
	end,
	slot = function(item, text)
		text = (tonumber(text) or -1) - 1
		if (item.Type ~= "Weapon") then
			return false
		end

		local class = baseclass.Get(item.ClassName)
		return class and class.Slot == text
	end,
	class = function(item, text)
		if (item.Type ~= "Weapon") then
			return false
		end

		if (item.ClassName == text) then
			return
		end

		local class = baseclass.Get(item.ClassName)
		return class and class.PrintName:lower():find(text, nil, true)
	end
}

function PANEL:SearchItems(text)
	self.ItemHighlights = {}
	self.SearchText = text
	if (text == "") then
		return
	end

	local removals = {}

	local filters = {}

	for pos1, typ, txt, pos2 in text:gmatch "%s*()([^%s:]+):(%S*)%s*()" do
		filters[typ] = txt
		table.insert(removals, {pos1, pos2})
	end

	for i = #removals, 1, -1 do
		local positions = removals[i]

		text = text:sub(1, positions[1] - 1) .. text:sub(positions[2])
	end

	text = text:Trim()
	if (text ~= "") then
		filters.name = text
	end

	for i, pnl in pairs(self.Items) do
		local item = pnl.Item
		if (not item) then
			continue
		end

		local good = true

		for filtername, filterdata in pairs(filters) do
			local filter = self.FilterTypes[filtername]
			if (not filter) then
				continue
			end

			if (not filter(item, filterdata)) then
				good = false
				break
			end
		end

		if (good) then
			self:HighlightItem(i, math.huge)
		end
	end
end

function PANEL:SwapToBuffer(enable)
	if (not not self.BufferActive == enable) then
		return
	end

	self.BufferActive = not self.BufferActive
	if (self.BufferActive) then
		for _, tab in pairs(pluto.cl_inv) do
			if (tab.Type == "buffer") then
				self:PopulateFromTab(tab, true)
			end
		end

		self:SetText "Buffer"
		hook.Add("PlutoBufferChanged", self, self.PlutoBufferChanged)

		for _, item in pairs(self.Items) do
			item:SetCanPickup(false)
		end
	else
		self:PopulateFromTab(self.ActiveTab)
		self:SetText "Inventory"
		for _, item in pairs(self.Items) do
			item:SetCanPickup(true)
		end
	end
end

function PANEL:PlutoBufferChanged()
	if (self.BufferActive) then
		for _, tab in pairs(pluto.cl_inv) do
			if (tab.Type == "buffer") then
				self:PopulateFromTab(tab)
			end
		end
	end
end

vgui.Register("pluto_storage_area", PANEL, "EditablePanel")
