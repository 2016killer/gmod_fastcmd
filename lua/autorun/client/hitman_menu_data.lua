local filepath = 'fastcmd/wheel/hitman_menu.json'
local json = [[
{
	"centersize": 0.4276315789473684,
	"arrow": "hud/dishonored/menu_selector_fcmd.png",
	"cicon": "",
	"iconsize": 0.26973684210526316,
	"background": "",
	"backgroundsize": 1.5592105263157894,
	"autoclip": false,
	"backgroundrotate3d": 5,
	"background3d": true,
	"fade": 199.63815789473685,
	"metadata": [
		{
			"call": {
				"pexecute": "mightyfootengaged"
			},
			"icon": "trails/electric"
		},
		{
			"call": {
				"pexecute": "",
				"sexecute": "sixthsense"
			},
			"icon": "hitman/instinct.vmt"
		},
		{
			"call": {
				"pexecute": "",
				"sexecute": "+pointshoot"
			},
			"icon": "hitman/pointshooting.vmt"
		}
	],
	"icondistance": 0.7796052631578947,
	"edge": "",
	"style": "hitman_menu"
}
]]

if not file.Exists(filepath, 'DATA') then
    file.Append(filepath, json)
end

filepath = nil
json = nil

hook.Add('FcmdmPostDrawWheel2D', 'hitman_menu.drawpower', function(size, wdata, state)
	if wdata.style ~= 'hitman_menu' then return end

	local posx, posy = ScrW() * 0.5, ScrH() * 0.5

	surface.SetDrawColor(255, 255, 255, 255)
	local curpower = math.Round(LocalPlayer():GetNW2Float('psnw_power', 1) * 100)
	draw.SimpleText(tostring(curpower), 'HudDefault', posx, posy, Color(255, 255, 255, 255 * state), 
		TEXT_ALIGN_CENTER, 
		TEXT_ALIGN_CENTER 
	)
		

end)