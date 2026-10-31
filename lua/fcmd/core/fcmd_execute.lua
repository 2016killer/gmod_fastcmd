function FcmdAutoParseRexecute(cmd)
    -- 自动解析释放指令：保留+开头的子串，并将+替换为-
    local result = {}

    -- 以;分割所有子串
    for _, part in ipairs(string.Split(cmd, ';')) do
		part = string.Trim(part)
        if string.sub(part, 1, 1) == '+' then
            table.insert(result, '-'..string.sub(part, 2))
        end
    end
    return table.concat(result, ';')
end

function FcmdExecuteCmd(cmd, filter)
	if not isstring(cmd) or cmd == '' then return end
	-- 过滤指定指令, 防止无限递归
	local result = {}

    -- 以;分割所有子串
	if istable(filter) then
		for _, part in ipairs(string.Split(cmd, ';')) do
			part = string.Trim(part)
			if not filter[part] then
				table.insert(result, part)
			end
		end
		cmd = table.concat(result, ';')
	end

	LocalPlayer():ConCommand(cmd)
end

function FcmdExecuteCall(call, press, filter)
	-- 执行指令
	// PrintTable(call)
	if press then
		FcmdExecuteCmd(call.pexecute, filter)
		call.press = true -- 记录按下状态, 同时也可用于判断是否执行过按下
	elseif call.press ~= nil then
		if isstring(call.rexecute) then
			FcmdExecuteCmd(call.rexecute, filter)
		elseif isstring(call.pexecute) then
			FcmdExecuteCmd(FcmdAutoParseRexecute(call.pexecute), filter)
		end
		call.press = false
	end
end

function FcmdExecuteBreak(call, filter)
	-- 执行中断指令
	if not call.press then return end
	call.press = false
	if isstring(call.bexecute) then
		FcmdExecuteCmd(call.bexecute, filter)
	elseif isstring(call.rexecute) then
		FcmdExecuteCmd(call.rexecute, filter)
	elseif isstring(call.pexecute) then
		FcmdExecuteCmd(FcmdAutoParseRexecute(call.pexecute), filter)
	end
end
