local PANEL = {}

function PANEL:Init()
	self.Rotation = 0
end

function PANEL:Paint(w, h)
	local x, y = 0, 0
	self.Rotation = (self.Rotation - FrameTime() * 30) % 360
	
	draw.NoTexture()
	local polys = pluto.loading_polys(x, y, size, self.Rotation)
	for i, poly in ipairs(polys) do
		local col = ColorLerp((i - 1) / (#polys), Color(255, 0, 0), Color(0, 255, 0), Color(0, 0, 255), Color(255, 0, 0))
		surface.SetDrawColor(col)
		poly()
	end
end

vgui.Register("pluto_inventory_loading", PANEL, "EditablePanel")
