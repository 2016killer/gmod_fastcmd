include('fcmd/core/fcmd_wheel.lua')
include('fcmd/core/fcmd_execute.lua')
include('fcmd/core/fcmd_file.lua')
include('fcmd/core/fcmd_filter.lua')

-----------------------------
local cl_fcmdm_wheel_size = CreateClientConVar('cl_fcmdm_wheel_size', '500', true, false)
local cl_fcmdm_expand_key = CreateClientConVar('cl_fcmdm_expand_key', '0', true, false)
local cl_fcmdm_call_key = CreateClientConVar('cl_fcmdm_call_key', '0', true, false)
local cl_fcmdm_break_key = CreateClientConVar('cl_fcmdm_break_key', '0', true, false)
local cl_fcmdm_wfile = CreateClientConVar('cl_fcmdm_wfile', 'fastcmd/wheel/chat.json', true, false)
-----------------------------
local curcall
local curwdata
local expand = false

function FcmdmExecuteCurBreak()
	-- 执行中断命令
	if not istable(curcall) then return end
	hook.Run('FcmdmExecuteBreak', curcall, FcmdGetCmdFilter())
	FcmdExecuteBreak(curcall, FcmdGetCmdFilter())
end

function FcmdmGetCurCall() return curcall end
function FcmdmSetCurCall(target)
	-- 切换当前调用指令
	-- target: 可以是表或nil, 如果是表, 则必须包含合理的pexecute和rexecute字段

	if curcall ~= target then 
		if istable(target) then
			if (not isstring(target.pexecute) or target.pexecute == '') and (not isstring(target.rexecute) or target.rexecute == '') then 
				return 
			end
			
			target.press = nil -- 重置按下状态, 防止切换后第一次是弹起
		end 
		FcmdmExecuteCurBreak()
		hook.Run('FcmdmCurCallChange', curcall, target)
		curcall = target 
	end
end

function FcmdmGetCurWData() return curwdata end
function FcmdmSetCurWData(target)
	if curwdata ~= target then
		hook.Run('FcmdmCurWDataChange', curwdata, target)
		curwdata = target 
		FcmdmSetCurCall(nil)
	end
end

function FcmdmExpandWheel(state)
	-- 展开UI
	if not istable(curwdata) then
		expand = false
		return 
	end
	
	hook.Run('FcmdmExpandWheel', state)
	gui.EnableScreenClicker(state)
	expand = state
	
	if state then
		if isstring(curwdata.soundexpand) then
			surface.PlaySound(curwdata.soundexpand)
		end
	else
		if isstring(curwdata.soundclose) then
			surface.PlaySound(curwdata.soundclose)
		end

		-- 关闭时更改选中
		local selectIdx = curwdata.cache.selectIdx
		if selectIdx ~= nil and selectIdx ~= 0 then
			curwdata.cache.selectedIdx = selectIdx

			local target = curwdata.metadata[selectIdx].call
			FcmdmSetCurCall(target)
			if istable(target) then 
				FcmdExecuteCmd(target.sexecute)
			end
		end
		curwdata.cache.selectIdx = nil
		hook.Run('FcmdmWheelSelectChange', curwdata, nil, nil)
	end
end

function FcmdmGetExpand() return expand end
function FcmdmSetExpand(target) FcmdmExpandWheel(target) end

function FcmdmExecuteCurCall(state)
	-- 执行选中
	-- 展开ui时不执行
	if expand or not istable(curcall) then return end
	// PrintTable(curcall)
	hook.Run('FcmdmExecuteCall', curcall, state, FcmdGetCmdFilter())
	FcmdExecuteCall(curcall, state, FcmdGetCmdFilter())
end

function FcmdmLoadCurWData(filename)
	LocalPlayer():ConCommand('cl_fcmdm_wfile ""')
	LocalPlayer():ConCommand(string.format('cl_fcmdm_wfile "%s"', filename))
end

function FcmdmReloadCurWData()
	local filename = cl_fcmdm_wfile:GetString()
	LocalPlayer():ConCommand('cl_fcmdm_wfile ""')
	LocalPlayer():ConCommand(string.format('cl_fcmdm_wfile "%s"', filename))
end

function FcmdmClearCurWData()
	LocalPlayer():ConCommand('cl_fcmdm_wfile ""')
end

table.Merge(FcmdGetCmdFilter(), {
	['+fcmdm_expand'] = true,
	['-fcmdm_expand'] = true,
	['+fcmdm_call'] = true,
	['-fcmdm_call'] = true,
	['fcmdm_break'] = true
})

cvars.AddChangeCallback('cl_fcmdm_wfile', function(name, old, new) 
	local newdata
	if new ~= '' then
		newdata = FcmdLoadWheelData(new)
		if istable(newdata) then 
			local loadsound = newdata.loadsound
			if isstring(loadsound) and loadsound ~= '' then
				surface.PlaySound(loadsound)
			else
				surface.PlaySound('Weapon_AR2.Reload_Push')
			end
		end
	end

	FcmdmSetCurWData(newdata)
end, 'aaa')

concommand.Add('+fcmdm_expand', function(ply) FcmdmExpandWheel(true) end)
concommand.Add('-fcmdm_expand', function(ply) FcmdmExpandWheel(false) end)
concommand.Add('+fcmdm_call', function(ply) FcmdmExecuteCurCall(true) end)
concommand.Add('-fcmdm_call', function(ply) FcmdmExecuteCurCall(false) end)

concommand.Add('fcmdm_break', function(ply) FcmdmExecuteCurBreak() end)

local radunit = 180 / math.pi
local zerovec, zeroang = Vector(), Angle()
local startmartix = Matrix()
startmartix:SetTranslation(Vector())
startmartix:SetAngles(Angle(90, 0, -90))

local function StartWheel3D(angle, cx, cy, selectIdx)
	if angle <= 0 then return false end

	local cammartix = startmartix
	if selectIdx ~= nil then
		local dx, dy = gui.MouseX() - cx, gui.MouseY() - cy
		local dis = math.sqrt(dx * dx + dy * dy)
		local sina, cosa = math.sin(angle), math.cos(angle)
		local pitch = math.atan2(dx / dis * sina, cosa) * radunit
		local roll = math.asin(dy / dis * sina) * radunit
		local rotate = Matrix()
		rotate:SetAngles(Angle(pitch, 0, roll))
		cammartix = rotate * startmartix
	end

	local campos = Vector(cx, -cy, 0) - cammartix:GetForward() * 1200
	local camang = cammartix:GetAngles()
	local old = DisableClipping(true)

	cam.Start3D(campos, camang, 60)
	render.ClearDepth()
	cam.Start3D2D(zerovec, zeroang, 1)

	return true, old
end

local function EndWheel3D(old)
	cam.End3D2D()
	cam.End3D()
	DisableClipping(old)
end

function FcmdmDrawWheel(size, wdata, state)
	-- 绘制轮盘 并 运行Hook
	local rootcache = wdata.cache
	state = math.max(state, 0)

	local w, h = ScrW(), ScrH()
	local cx, cy = w * 0.5, h * 0.5
	local selectIdx = rootcache.selectIdx

	if rootcache.background then
		local started, old = StartWheel3D(rootcache.backgroundrotate3d, cx, cy, selectIdx)
		FcmdDrawWheelBackground(size, wdata, state)
		if started then
			EndWheel3D(old)
		end
	end

	FcmdDrawWheelFade(wdata, state)

	local started, old = StartWheel3D(rootcache.rotate3d, cx, cy, selectIdx)
	hook.Run('FcmdmPreDrawWheel2D', size, wdata, state)
	FcmdDrawWheel2D(size, wdata, state, nil, false, false)
	hook.Run('FcmdmPostDrawWheel2D', size, wdata, state)
	if started then
		EndWheel3D(old)
	end
end

-----------------------------
local expandKey = false
local function ExpandKeyEvent()
	-- 展开键事件 (有绑定时边沿触发)
	local key = cl_fcmdm_expand_key:GetInt()
	if key == 0 then return end
	local current = input.IsKeyDown(key) or input.IsMouseDown(key)
	if expandKey ~= current then 
		FcmdmExpandWheel(current)
	end
	expandKey = current
end

local callKey = false
local function CallKeyEvent()
	-- 执行键事件 (有绑定时边沿触发)
	local key = cl_fcmdm_call_key:GetInt()
	if key == 0 then return end
	local current = input.IsKeyDown(key) or input.IsMouseDown(key)
	if callKey ~= current then 
		FcmdmExecuteCurCall(current)
	end
	callKey = current
end

local breakKey = false
local function BreakKeyEvent()
	-- 中断键事件 (有绑定时上升沿触发)
	local key = cl_fcmdm_break_key:GetInt()
	if key == 0 then return end
	local current = input.IsKeyDown(key) or input.IsMouseDown(key)
	if current and breakKey ~= current then 
		FcmdmExecuteCurBreak()
	end
	breakKey = current
end


concommand.Add('fcmdm_add_hook', function(ply, cmd, args)
	hook.Add('Think', 'fcmdm_think', function()
		if not istable(curwdata) then return end

		-- 按键事件
		ExpandKeyEvent()
		CallKeyEvent()
		BreakKeyEvent()

		if not istable(curwdata) then return end -- 防止动态切换
		if not expand then return end 

		-- 检查选中
		local rootcache = curwdata.cache
		local selectIdx = FcmdCheckSelect(
			rootcache.centersize * cl_fcmdm_wheel_size:GetInt(), 
			curwdata
		)

		-- 选中变化 (播放音效并触发事件)
		if rootcache.selectIdx ~= selectIdx then
			if selectIdx == nil or selectIdx == 0 then
				if isstring(curwdata.soundgiveup) and curwdata.soundgiveup ~= '' then
					surface.PlaySound(curwdata.soundgiveup)
				else
					surface.PlaySound('fastcmd/zoomout.wav')
				end
			else
				if isstring(curwdata.soundselect) and curwdata.soundselect ~= '' then
					surface.PlaySound(curwdata.soundselect)
				else
					surface.PlaySound('fastcmd/zoomin.wav')
				end
			end
			hook.Run('FcmdmWheelSelectChange', curwdata, selectIdx, curwdata.metadata[selectIdx])
		end
		rootcache.selectIdx = selectIdx
	end)

	local expandstate = 0
	hook.Add('DrawOverlay', 'fcmdm_draw', function() 
		
		if not istable(curwdata) then return end
		if expand then
			expandstate = math.Clamp(expandstate + 5 * RealFrameTime(), 0, 1)
		else
			expandstate = math.Clamp(expandstate - 5 * RealFrameTime(), 0, 1)
		end
		if expandstate == 0 then 
			return 
		end
		
		-- 使用多个全局渲染设置, 异常时必须着重处理
		local succ, err = pcall(FcmdmDrawWheel, cl_fcmdm_wheel_size:GetInt(), curwdata, expandstate)
		
		if not succ then	
			render.ClearStencil()
			render.SetStencilEnable(false)
			render.OverrideColorWriteEnable(false)
			gui.EnableScreenClicker(false)
			
			hook.Remove('Think', 'fcmdm_think')
			hook.Remove('HUDPaint', 'fcmdm_draw')

			ErrorNoHaltWithStack(err)
			FcmdError('#fcmdm.err.fatal', '#fcmdm.err.hook_die')
			FcmdmExpandWheel(false)
		end
	end)
end)

hook.Add('KeyPress', 'fcmdm_init', function(ply, key)
	if key == IN_FORWARD or key == IN_BACK then
		LocalPlayer():ConCommand('fcmdm_add_hook')
		FcmdmReloadCurWData()
		FcmdHelp('#fcmdm.help.use')
		hook.Remove('KeyPress', 'fcmdm_init')
	end
end)
