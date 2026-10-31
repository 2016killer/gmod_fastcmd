concommand.Add('fcmd_version', function() print('1.1.0') end)

local convars = {
	cl_fcmdm_wheel_size = 500,
	cl_fcmdm_expand_key = 0,
	cl_fcmdm_call_key = 0,
	cl_fcmdm_break_key = 0,
	cl_fcmdm_wfile = 'fastcmd/wheel/chat.json',
	cl_fcmd_notify = 1
}

for k, v in pairs(convars) do
	CreateClientConVar(k, tostring(v), true, false)
end


-------------------------菜单
hook.Add('PopulateToolMenu', 'fcmd_menu', function()
	spawnmenu.AddToolMenuOption(
		'Utilities', 
		language.GetPhrase('#fcmdu.menu.category'),
		'fcmd_menu',
		language.GetPhrase('#fcmdu.menu.name'), '', '',
		function(panel)
			panel:Clear()

			-- 预设下拉框
			local ctrl = vgui.Create('ControlPresets', panel)
				ctrl:SetPreset('fcmd_menu')
				for k, v in pairs(convars) do ctrl:AddConVar(k) end
				ctrl:AddOption('#preset.default', convars)
				panel:AddPanel(ctrl)

			panel:NumSlider(language.GetPhrase('#fcmdu.wheel_size'), 'cl_fcmdm_wheel_size', 0, 1000, 0)

			-- 按键绑定
			panel:KeyBinder(
				language.GetPhrase('#fcmdu.expand_key'),
				'cl_fcmdm_expand_key', 
				language.GetPhrase('#fcmdu.call_key'),
				'cl_fcmdm_call_key'
			)
			panel:KeyBinder(
				language.GetPhrase('#fcmdu.break_key'),
				'cl_fcmdm_break_key'
			)


			panel:TextEntry(language.GetPhrase('#fcmdu.wfile'), 'cl_fcmdm_wfile')

			-- 轮盘数据浏览器
			local body = vgui.Create('DPanel', panel)
			local WheelDataBrowser = FcmduCreateWheelDataBrowser(body)
			body:SetHeight(250)
			panel:AddItem(body)
			
			cvars.AddChangeCallback('cl_fcmdm_wfile', function(name, old, new) 
				WheelDataBrowser:Refresh()
			end, 'bbb')
			

			-- 编辑器按钮
			local EditorBtn = panel:Button(language.GetPhrase('#fcmdu.editor'), '')
			EditorBtn.DoClick = function()
				if WheelDataBrowser.selectFile then
					LocalPlayer():ConCommand(string.format('fcmdu_open_editor "%s"', WheelDataBrowser.selectFile))
				else
					LocalPlayer():ConCommand(string.format('fcmdu_open_editor "%s"', GetConVar('cl_fcmdm_wfile'):GetString()))
				end
			end

			panel:Button(language.GetPhrase('#fcmdu.add_hook'), 'fcmdm_add_hook')
			panel:CheckBox(language.GetPhrase('#fcmdu.notify'), 'cl_fcmd_notify')
		end
	)
end)






