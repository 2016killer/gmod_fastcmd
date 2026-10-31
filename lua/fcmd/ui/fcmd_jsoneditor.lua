local TextEditor = {}

function TextEditor:Save()
    local content = self.TextEntry:GetText() or ''
    if content == '' then return end

    if not isstring(self.SavePath) or self.SavePath == '' then
        Derma_StringRequest('保存文件','请输入文件名，将自动补全.json后缀','config',function(inputPath)
            if inputPath and inputPath ~= '' then
                if not string.EndsWith(string.lower(inputPath), '.json') then
                    inputPath = string.format('%s.json', inputPath)
                end
                self.SavePath = inputPath
                self:SetTitle(string.format('Fcmd JSON 编辑器 - %s', self.SavePath))
                self:RealSave(content)
            end
        end)
        return
    end
    self:RealSave(content)
end

function TextEditor:RealSave(content)
    if not self.SavePath then return end
    local saveState = file.Write(self.SavePath, content, 'DATA')
    if saveState then
        self.StatusLabel:SetText(string.format('[成功] 已保存至 DATA/%s',self.SavePath))
        self.StatusLabel:SetTextColor(Color(46, 170, 46))
    else
        self.StatusLabel:SetText(string.format('[错误] 文件写入失败: %s',self.SavePath))
        self.StatusLabel:SetTextColor(Color(204, 0, 0))
    end
end

function TextEditor:CheckJSONSyntax()
    local content = self.TextEntry:GetText() or ''
    if content == '' then
        self.StatusLabel:SetText('[提示] 请输入 JSON 格式文本')
        self.StatusLabel:SetTextColor(Color(192, 192, 192))
        return
    end

    local jsonResult, jsonErr = util.JSONToTable(content)
    if jsonResult then
        self.StatusLabel:SetText('[提示] JSON 语法格式正确')
        self.StatusLabel:SetTextColor(Color(46, 170, 46))
    else
        self.StatusLabel:SetText(string.format('[错误] JSON 解析失败: %s', jsonErr or '未知语法错误'))
        self.StatusLabel:SetTextColor(Color(204, 0, 0))
    end
end

function TextEditor:OnClose()
    timer.Remove(self.TimerID)
	self:Save()
end

function TextEditor:Open(fileName, gamePath)
    gamePath = gamePath or 'DATA'
	local content = file.Read(fileName, gamePath)
	if not content then
        self.StatusLabel:SetText(string.format('[错误] 文件读取失败: %s',fileName))
        self.StatusLabel:SetTextColor(Color(204, 0, 0))
        return
    end
	
	self.TextEntry:SetText(content)
	self.SavePath = fileName
    self:SetTitle('Fcmd JSON 编辑器 - ' .. self.SavePath)
    self:CheckJSONSyntax()
end

function TextEditor:Init()
    self.UUID = FcmdGenerateUUID()
    self.TimerID = string.format('%s-TIMER', self.UUID)

    self:SetSize(700, 550)
    self:Center()
    self:SetTitle('Fcmd JSON 编辑器')
    self:SetSizable(true)
    self:ShowCloseButton(true)
    self:MakePopup()
	self:SetDeleteOnClose(true)
    
    local textEntry = vgui.Create('DTextEntry', self)
    textEntry:Dock(FILL)
    textEntry:DockMargin(10, 10, 10, 30)
    textEntry:SetWrap(true)
    textEntry:SetMultiline(true)
    textEntry:SetVerticalScrollbarEnabled(true)
    self.TextEntry = textEntry

    local statusLabel = vgui.Create('DLabel', self)
    statusLabel:Dock(BOTTOM)
    statusLabel:DockMargin(10,0,10,5)
    statusLabel:SetHeight(25)
    statusLabel:SetText('[提示] 请输入 JSON 格式文本')
    statusLabel:SetTextColor(Color(192, 192, 192))
    self.StatusLabel = statusLabel

    textEntry.OnTextChanged = function()
        timer.Create(
            self.TimerID, 
            0.5, 
            1, 
            function() 
                self:CheckJSONSyntax() 
            end
        )
    end

	self.SavePath = nil
end

vgui.Register('FcmdJsonEditor', TextEditor, 'DFrame')
TextEditor = nil