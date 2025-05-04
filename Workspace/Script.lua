local Toolbar = plugin:CreateToolbar("GitTools")
local SelectionService = game:GetService("Selection")
local HttpService = game:GetService("HttpService")

-- Base64 encode
function to_base64(data)
	local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
	return ((data:gsub('.', function(x) 
		local r,b='',x:byte()
		for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
		return r;
	end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
		if (#x < 6) then return '' end
		local c=0
		for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
		return b:sub(c+1,c+1)
	end)..({ '', '==', '=' })[#data%3+1])
end

-- Split function
local function split(str, sep)
	local result = {}
	for part in string.gmatch(str, "[^" .. sep .. "]+") do
		table.insert(result, part)
	end
	return result
end

-- Auto path mapping
local function getScriptPath(instance)
	local path = ""
	local current = instance
	while current and current ~= game do
		path = current.Name .. "/" .. path
		current = current.Parent
	end
	path = path:sub(1, -2) -- Remove trailing "/"
	if path:match("^ServerScriptService") or path:match("^ReplicatedStorage") then
		path = "src/" .. path
	end
	return path .. ".lua"
end

-- Tree building for copyable hierarchy
local function buildTree(instance, indent, isLast, includeNonScripts)
	local prefix = indent == "" and "" or (indent .. (isLast and "└─ " or "├─ "))
	local isService = false
	for _, serviceName in ipairs({
		"Workspace", "Players", "Lighting", "MaterialService", "NetworkClient",
		"ReplicatedFirst", "ReplicatedStorage", "ServerScriptService", "ServerStorage",
		"StarterGui", "StarterPack", "StarterPlayer", "StarterCharacterScripts",
		"StarterPlayerScripts", "Teams", "SoundService", "TextChatService"
		}) do
		if instance.ClassName == serviceName then
			isService = true
			break
		end
	end
	local typeDisplay = isService and "Service" or instance.ClassName
	local tree = prefix .. instance.Name .. " (" .. typeDisplay .. ")\n"
	local children = instance:GetChildren()
	local validChildren = {}
	for _, child in ipairs(children) do
		if includeNonScripts or child:IsA("Script") or child:IsA("ModuleScript") then
			table.insert(validChildren, child)
		end
	end
	table.sort(validChildren, function(a, b) return a.Name < b.Name end)
	for i, child in ipairs(validChildren) do
		local isLastChild = i == #validChildren
		local newIndent = indent .. (isLast and "   " or "│  ")
		tree = tree .. buildTree(child, newIndent, isLastChild, includeNonScripts)
	end
	return tree
end

-- Settings GUI
local settingsInfo = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, true, true, 300, 200, 200, 150)
local settingsWidget = plugin:CreateDockWidgetPluginGui("GitToolsSettings", settingsInfo)
settingsWidget.Title = "GitTools Settings"
settingsWidget.Enabled = false

local settingsFrame = Instance.new("Frame", settingsWidget)
settingsFrame.Size = UDim2.new(1, 0, 1, 0)
settingsFrame.BackgroundTransparency = 1

local tokenLabel = Instance.new("TextLabel", settingsFrame)
tokenLabel.Text = "GitHub Token:"; tokenLabel.Position = UDim2.new(0,10,0,10); tokenLabel.Size = UDim2.new(0,100,0,20)
local tokenBox = Instance.new("TextBox", settingsFrame)
tokenBox.PlaceholderText = "token (optional for public repos)"; tokenBox.Position = UDim2.new(0,120,0,10); tokenBox.Size = UDim2.new(0,160,0,20)

local repoLabel = Instance.new("TextLabel", settingsFrame)
repoLabel.Text = "Owner/Repo:"; repoLabel.Position = UDim2.new(0,10,0,40); repoLabel.Size = UDim2.new(0,100,0,20)
local repoBox = Instance.new("TextBox", settingsFrame)
repoBox.PlaceholderText = "user/repo"; repoBox.Position = UDim2.new(0,120,0,40); repoBox.Size = UDim2.new(0,160,0,20)

local includeNonScriptsLabel = Instance.new("TextLabel", settingsFrame)
includeNonScriptsLabel.Text = "Include Non-Scripts in Tree:"; includeNonScriptsLabel.Position = UDim2.new(0,10,0,70); includeNonScriptsLabel.Size = UDim2.new(0,150,0,20)
local includeNonScriptsBox = Instance.new("TextBox", settingsFrame)
includeNonScriptsBox.Text = "false"; includeNonScriptsBox.Position = UDim2.new(0,160,0,70); includeNonScriptsBox.Size = UDim2.new(0,50,0,20)

local saveBtn = Instance.new("TextButton", settingsFrame)
saveBtn.Text = "Save"
saveBtn.Position = UDim2.new(0,10,0,100)
saveBtn.Size = UDim2.new(0,80,0,30)
saveBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
saveBtn.AutoButtonColor = false
saveBtn.MouseButton1Click:Connect(function()
	local repoText = repoBox.Text:gsub("%s+", "") -- Trim whitespace
	if repoText == "" or not repoText:match("([^/]+)/([^/]+)") then
		statusBar.Text = "❌ Invalid repo format (use owner/repo)"
		print("saveBtn - Invalid repo format:", repoText)
		return
	end
	local tokenText = tokenBox.Text:gsub("%s+", "")
	local settings = {
		token = tokenText ~= "" and tokenText or nil,
		repo = repoText,
		includeNonScripts = includeNonScriptsBox.Text:lower() == "true"
	}
	print("saveBtn - Saving settings:", settings)
	plugin:SetSetting("GitToolsSettings", settings)
	settingsWidget.Enabled = false
	statusBar.Text = "✅ Settings saved"
	print("[GitTools] Settings saved successfully!")
end)

local clearSettingsBtn = Instance.new("TextButton", settingsFrame)
clearSettingsBtn.Text = "Clear Settings"
clearSettingsBtn.Position = UDim2.new(0,100,0,100)
clearSettingsBtn.Size = UDim2.new(0,80,0,30)
clearSettingsBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
clearSettingsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearSettingsBtn.AutoButtonColor = false
clearSettingsBtn.MouseButton1Click:Connect(function()
	plugin:SetSetting("GitToolsSettings", nil)
	tokenBox.Text = ""
	repoBox.Text = ""
	includeNonScriptsBox.Text = "false"
	statusBar.Text = "✅ Settings cleared"
	print("[GitTools] Settings cleared!")
end)

local configureServicesBtn = Instance.new("TextButton", settingsFrame)
configureServicesBtn.Text = "Tree Services"
configureServicesBtn.Position = UDim2.new(0,190,0,100)
configureServicesBtn.Size = UDim2.new(0,80,0,30)
configureServicesBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
configureServicesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
configureServicesBtn.AutoButtonColor = false

-- Tree Services Checklist GUI
local servicesInfo = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, true, true, 300, 400, 200, 300)
local servicesWidget = plugin:CreateDockWidgetPluginGui("GitToolsTreeServices", servicesInfo)
servicesWidget.Title = "Tree Services"
servicesWidget.Enabled = false

local servicesFrame = Instance.new("Frame", servicesWidget)
servicesFrame.Size = UDim2.new(1, 0, 1, 0)
servicesFrame.BackgroundTransparency = 1

local serviceList = {
	"Workspace", "Players", "Lighting", "MaterialService", "NetworkClient",
	"ReplicatedFirst", "ReplicatedStorage", "ServerScriptService", "ServerStorage",
	"StarterGui", "StarterPack", "StarterPlayer", "Teams", "SoundService", "TextChatService"
}

local serviceToggles = {}
local function createServiceToggle(serviceName, index)
	local toggleFrame = Instance.new("Frame", servicesFrame)
	toggleFrame.Position = UDim2.new(0, 10, 0, 10 + (index - 1) * 25)
	toggleFrame.Size = UDim2.new(1, -20, 0, 20)
	toggleFrame.BackgroundTransparency = 1

	local checkBtn = Instance.new("TextButton", toggleFrame)
	checkBtn.Text = ""
	checkBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	checkBtn.Position = UDim2.new(0, 0, 0, 0)
	checkBtn.Size = UDim2.new(0, 20, 0, 20)
	checkBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	checkBtn.BorderSizePixel = 1

	local label = Instance.new("TextLabel", toggleFrame)
	label.Text = serviceName
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Position = UDim2.new(0, 25, 0, 0)
	label.Size = UDim2.new(1, -25, 1, 0)
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left

	checkBtn.MouseButton1Click:Connect(function()
		local settings = plugin:GetSetting("GitToolsTreeServices") or {}
		settings[serviceName] = not settings[serviceName]
		checkBtn.Text = settings[serviceName] and "•" or ""
		plugin:SetSetting("GitToolsTreeServices", settings)
	end)

	serviceToggles[serviceName] = { button = checkBtn }
end

for i, serviceName in ipairs(serviceList) do
	createServiceToggle(serviceName, i)
end

local savedServiceSettings = plugin:GetSetting("GitToolsTreeServices") or {}
for serviceName, toggle in pairs(serviceToggles) do
	if savedServiceSettings[serviceName] then
		toggle.button.Text = "•"
	end
end

local servicesCloseBtn = Instance.new("TextButton", servicesFrame)
servicesCloseBtn.Text = "Close"
servicesCloseBtn.Position = UDim2.new(0, 10, 1, -40)
servicesCloseBtn.Size = UDim2.new(0, 80, 0, 30)
servicesCloseBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
servicesCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
servicesCloseBtn.AutoButtonColor = false
servicesCloseBtn.MouseButton1Click:Connect(function()
	servicesWidget.Enabled = false
	print("[GitTools] Tree services configuration saved!")
end)

configureServicesBtn.MouseButton1Click:Connect(function()
	servicesWidget.Enabled = true
end)

-- Load saved settings
local settings = plugin:GetSetting("GitToolsSettings") or {}
print("loadSettings - Loaded settings:", settings)
if settings.token then tokenBox.Text = settings.token end
if settings.repo then repoBox.Text = settings.repo end
if settings.includeNonScripts ~= nil then includeNonScriptsBox.Text = tostring(settings.includeNonScripts) end

-- Main UI setup
local widget = plugin:CreateDockWidgetPluginGui(
	"GitTools",
	DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, 200, 150, 150, 100)
)
widget.Title = "GitTools"
local frame = Instance.new("Frame", widget)
frame.Size = UDim2.new(1, 0, 1, 0)
frame.BackgroundTransparency = 1

local uiListLayout = Instance.new("UIListLayout", frame)
uiListLayout.Padding = UDim.new(0, 5)
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local statusBar = Instance.new("TextLabel", frame)
statusBar.Size = UDim2.new(1, 0, 0, 20)
statusBar.LayoutOrder = 4
statusBar.Text = "Ready"
statusBar.TextScaled = true
statusBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
statusBar.TextColor3 = Color3.fromRGB(255, 255, 255)

local pushButton = Instance.new("TextButton", frame)
pushButton.Size = UDim2.new(1, 0, 0, 30)
pushButton.LayoutOrder = 1
pushButton.Text = "Push Selected"
pushButton.TextColor3 = Color3.fromRGB(255, 255, 255)
pushButton.BorderSizePixel = 1
pushButton.BorderColor3 = Color3.fromRGB(100, 100, 100)

local showRepoButton = Instance.new("TextButton", frame)
showRepoButton.Size = UDim2.new(1, 0, 0, 30)
showRepoButton.LayoutOrder = 2
showRepoButton.Text = "Show Repo"
showRepoButton.TextColor3 = Color3.fromRGB(255, 255, 255)
showRepoButton.BorderSizePixel = 1
showRepoButton.BorderColor3 = Color3.fromRGB(100, 100, 100)

local copyTreeButton = Instance.new("TextButton", frame)
copyTreeButton.Size = UDim2.new(1, 0, 0, 30)
copyTreeButton.LayoutOrder = 3
copyTreeButton.Text = "Copy Tree"
copyTreeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
copyTreeButton.BorderSizePixel = 1
copyTreeButton.BorderColor3 = Color3.fromRGB(100, 100, 100)

-- Function to setup button colors and hover effect
local function setupButton(button, normalColor)
	button.BackgroundColor3 = normalColor
	local hoverColor = Color3.new(
		math.min(normalColor.R + 0.08, 1),
		math.min(normalColor.G + 0.08, 1),
		math.min(normalColor.B + 0.08, 1)
	)
	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = hoverColor
	end)
	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = normalColor
	end)
end

-- Apply to buttons
setupButton(pushButton, Color3.fromRGB(60, 120, 60))
setupButton(showRepoButton, Color3.fromRGB(60, 60, 120))
setupButton(copyTreeButton, Color3.fromRGB(120, 60, 60))

-- Repo Viewer GUI
local repoViewerInfo = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, true, true, 400, 600, 300, 400)
local repoViewerWidget = plugin:CreateDockWidgetPluginGui("GitToolsRepoViewer", repoViewerInfo)
repoViewerWidget.Title = "Repository Viewer"
repoViewerWidget.Enabled = false

local repoViewerFrame = Instance.new("Frame", repoViewerWidget)
repoViewerFrame.Size = UDim2.new(1, 0, 1, 0)
repoViewerFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
repoViewerFrame.BackgroundTransparency = 0

-- Lua Code Viewer GUI
local codeViewerInfo = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, true, true, 500, 600, 400, 400)
local codeViewerWidget = plugin:CreateDockWidgetPluginGui("GitToolsCodeViewer", codeViewerInfo)
codeViewerWidget.Title = "Lua Code Viewer"
codeViewerWidget.Enabled = false

local codeViewerFrame = Instance.new("Frame", codeViewerWidget)
codeViewerFrame.Size = UDim2.new(1, 0, 1, 0)
codeViewerFrame.BackgroundTransparency = 1

local codeScrollingFrame = Instance.new("ScrollingFrame", codeViewerFrame)
codeScrollingFrame.Size = UDim2.new(1, -20, 1, -60)
codeScrollingFrame.Position = UDim2.new(0, 10, 0, 10)
codeScrollingFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
codeScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
codeScrollingFrame.ScrollBarThickness = 10

local contentFrame = Instance.new("Frame", codeScrollingFrame)
contentFrame.Size = UDim2.new(1, 0, 0, 0) -- Height will be set dynamically
contentFrame.BackgroundTransparency = 1

local codeLabel = Instance.new("TextLabel", contentFrame)
codeLabel.Size = UDim2.new(1, 0, 1, 0)
codeLabel.BackgroundTransparency = 1
codeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
codeLabel.Font = Enum.Font.Code
codeLabel.TextSize = 14
codeLabel.TextXAlignment = Enum.TextXAlignment.Left
codeLabel.TextYAlignment = Enum.TextYAlignment.Top
codeLabel.TextWrapped = true
codeLabel.RichText = true

local codeTextBox = Instance.new("TextBox", contentFrame)
codeTextBox.Size = UDim2.new(1, 0, 1, 0)
codeTextBox.BackgroundTransparency = 1
codeTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
codeTextBox.Font = Enum.Font.Code
codeTextBox.TextSize = 14
codeTextBox.TextXAlignment = Enum.TextXAlignment.Left
codeTextBox.TextYAlignment = Enum.TextYAlignment.Top
codeTextBox.MultiLine = true
codeTextBox.TextWrapped = true
codeTextBox.TextEditable = false
codeTextBox.ClearTextOnFocus = false
codeTextBox.Text = ""
codeTextBox.ZIndex = 2
codeTextBox.TextTransparency = 1

local codeCloseBtn = Instance.new("TextButton", codeViewerFrame)
codeCloseBtn.Text = "Close"
codeCloseBtn.Position = UDim2.new(0, 10, 1, -40)
codeCloseBtn.Size = UDim2.new(0, 80, 0, 30)
codeCloseBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
codeCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
codeCloseBtn.AutoButtonColor = false
codeCloseBtn.MouseButton1Click:Connect(function()
	codeViewerWidget.Enabled = false
end)

-- Simple Lua lexer for syntax highlighting
local function tokenizeLua(code)
	local tokens = {}
	local keywords = {
		["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true, ["elseif"] = true,
		["end"] = true, ["false"] = true, ["for"] = true, ["function"] = true, ["if"] = true,
		["in"] = true, ["local"] = true, ["nil"] = true, ["not"] = true, ["or"] = true,
		["repeat"] = true, ["return"] = true, ["then"] = true, ["true"] = true, ["until"] = true,
		["while"] = true
	}
	local i = 1
	while i <= #code do
		local char = code:sub(i, i)
		-- Comments
		if char == "-" and code:sub(i, i+1) == "--" then
			local start = i
			i = i + 2
			if code:sub(i, i+1) == "[[" then
				i = i + 2
				local endPos = code:find("]]", i, true) or #code + 1
				table.insert(tokens, { type = "comment", value = code:sub(start, endPos - 1) })
				i = endPos
			else
				local endPos = code:find("\n", i, true) or #code + 1
				table.insert(tokens, { type = "comment", value = code:sub(start, endPos - 1) })
				i = endPos
			end
			-- Strings
		elseif char == "\"" or char == "'" then
			local start = i
			local quote = char
			i = i + 1
			while i <= #code and code:sub(i, i) ~= quote do
				if code:sub(i, i) == "\\" then i = i + 1 end
				i = i + 1
			end
			i = i + 1
			table.insert(tokens, { type = "string", value = code:sub(start, i - 1) })
			-- Numbers
		elseif char:match("%d") or (char == "-" and code:sub(i+1, i+1):match("%d")) then
			local start = i
			i = i + 1
			while i <= #code and code:sub(i, i):match("[0-9%.eE%-%+]") do
				i = i + 1
			end
			table.insert(tokens, { type = "number", value = code:sub(start, i - 1) })
			-- Identifiers and keywords
		elseif char:match("[%a_]")
		then
			local start = i
			i = i + 1
			while i <= #code and code:sub(i, i):match("[%w_]") do
				i = i + 1
			end
			local value = code:sub(start, i - 1)
			if keywords[value] then
				table.insert(tokens, { type = "keyword", value = value })
			else
				table.insert(tokens, { type = "identifier", value = value })
			end
			-- Operators and punctuation
		elseif char:match("[+%-*/=<>~!&|%^%(%)%[%]%{%},;:.#]") then
			local start = i
			i = i + 1
			while i <= #code and code:sub(i, i):match("[=<>~!&|%.]") do
				i = i + 1
			end
			table.insert(tokens, { type = "operator", value = code:sub(start, i - 1) })
			-- Whitespace
		elseif char:match("%s") then
			local start = i
			i = i + 1
			while i <= #code and code:sub(i, i):match("%s") do
				i = i + 1
			end
			table.insert(tokens, { type = "whitespace", value = code:sub(start, i - 1) })
		else
			i = i + 1
			table.insert(tokens, { type = "unknown", value = char })
		end
	end
	return tokens
end

-- Display code with syntax highlighting and enable text selection with scrolling
local function displayCode(code, path)
	local tokens = tokenizeLua(code)
	local richText = ""
	local plainText = ""
	for _, token in ipairs(tokens) do
		local color
		if token.type == "keyword" then
			color = "#569cd6"
		elseif token.type == "string" then
			color = "#d69d85"
		elseif token.type == "comment" then
			color = "#6a995e"
		elseif token.type == "number" then
			color = "#b5cea8"
		elseif token.type == "identifier" or token.type == "operator" then
			color = "#ffffff"
		else
			color = "#ffffff"
		end
		local escapedValue = token.value:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
		richText = richText .. string.format('<font color="%s">%s</font>', color, escapedValue)
		plainText = plainText .. token.value
	end
	codeLabel.Text = richText
	codeTextBox.Text = plainText
	wait() -- Wait for TextBounds to update
	local height = codeLabel.TextBounds.Y
	contentFrame.Size = UDim2.new(1, 0, 0, height)
	codeScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, height)
	codeViewerWidget.Title = "Lua Code: " .. path
	codeViewerWidget.Enabled = true
end

-- Validate settings for repo viewing
local function validateSettings(s)
	print("validateSettings - Checking settings:", s)
	if not s or not s.repo or type(s.repo) ~= "string" or s.repo:match("^%s*$") then
		print("validateSettings - Invalid settings: repo missing")
		return false
	end
	local owner, repo = s.repo:match("([^/]+)/([^/]+)")
	if not owner or not repo then
		print("validateSettings - Invalid repo format:", s.repo)
		return false
	end
	print("validateSettings - Settings valid:", s)
	return true, owner, repo
end

-- Build hierarchical repo tree view
local function buildRepoTreeView(tree)
	for _, child in ipairs(repoViewerFrame:GetChildren()) do
		child:Destroy()
	end
	local scrollingFrame = Instance.new("ScrollingFrame", repoViewerFrame)
	scrollingFrame.Size = UDim2.new(1, 0, 1, -50)
	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollingFrame.ScrollBarThickness = 10
	scrollingFrame.BackgroundTransparency = 1

	local uiListLayout = Instance.new("UIListLayout", scrollingFrame)
	uiListLayout.Padding = UDim.new(0, 2)

	local itemCount = 0
	local folderStates = {} -- Tracks expanded/collapsed state

	-- Build the tree structure
	local root = {}
	for _, item in ipairs(tree) do
		local parts = split(item.path, "/")
		local current = root
		for i = 1, #parts - 1 do
			local part = parts[i]
			if not current[part] then
				current[part] = { name = part, children = {}, isFile = false }
			end
			current = current[part].children
		end
		local lastPart = parts[#parts]
		if item.type == "blob" then
			current[lastPart] = { name = lastPart, path = item.path, isFile = true }
		else
			if not current[lastPart] then
				current[lastPart] = { name = lastPart, children = {}, isFile = false }
			end
		end
	end

	-- Recursive function to render nodes
	local function renderNode(node, parentFrame, indentLevel)
		local indent = indentLevel * 20
		for name, data in pairs(node) do
			itemCount = itemCount + 1
			local frame = Instance.new("Frame", parentFrame)
			frame.Size = UDim2.new(1, 0, 0, 20)
			frame.BackgroundTransparency = 1

			local button = Instance.new("TextButton", frame)
			button.Text = (data.isFile and "📄 " or "📁 ") .. data.name
			button.TextColor3 = data.isFile and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 255)
			button.Position = UDim2.new(0, indent + 10, 0, 0)
			button.Size = UDim2.new(1, -indent - 10, 1, 0)
			button.BackgroundTransparency = 1
			button.TextXAlignment = Enum.TextXAlignment.Left
			button.TextSize = 14

			if data.isFile then
				button.MouseButton1Click:Connect(function()
					local s = plugin:GetSetting("GitToolsSettings") or {}
					local isValid, owner, repo = validateSettings(s)
					if not isValid then
						statusBar.Text = "❌ Configure repo in Settings"
						settingsWidget.Enabled = true
						return
					end
					local url = string.format("https://raw.githubusercontent.com/%s/%s/main/%s", owner, repo, data.path)
					print("buildRepoTreeView - Fetching file content:", url)
					local success, response = pcall(function()
						return HttpService:GetAsync(url, true)
					end)
					if success then
						displayCode(response, data.path)
						statusBar.Text = "✅ Showing code for " .. data.path
						print("buildRepoTreeView - Content fetched for:", data.path)
					else
						statusBar.Text = "❌ Failed to fetch " .. data.path .. ": " .. tostring(response)
						print("buildRepoTreeView - Failed:", response)
					end
				end)
			else
				local childFrame = Instance.new("Frame", parentFrame)
				childFrame.Size = UDim2.new(1, 0, 0, 0)
				childFrame.BackgroundTransparency = 1
				local childLayout = Instance.new("UIListLayout", childFrame)
				childLayout.Padding = UDim.new(0, 2)

				folderStates[name] = folderStates[name] or true -- Default to expanded
				button.Text = (folderStates[name] and "▼ " or "▶ ") .. "📁 " .. data.name

				button.MouseButton1Click:Connect(function()
					folderStates[name] = not folderStates[name]
					button.Text = (folderStates[name] and "▼ " or "▶ ") .. "📁 " .. data.name
					childFrame.Visible = folderStates[name]
					local childHeight = folderStates[name] and childLayout.AbsoluteContentSize.Y or 0
					childFrame.Size = UDim2.new(1, 0, 0, childHeight)
					local totalHeight = uiListLayout.AbsoluteContentSize.Y
					scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
				end)

				for childName, childData in pairs(data.children) do
					renderNode({ [childName] = childData }, childFrame, indentLevel + 1)
				end

				local childHeight = folderStates[name] and childLayout.AbsoluteContentSize.Y or 0
				childFrame.Size = UDim2.new(1, 0, 0, childHeight)
				childFrame.Visible = folderStates[name]
			end
		end
	end

	-- Render root nodes
	for name, data in pairs(root) do
		renderNode({ [name] = data }, scrollingFrame, 0)
	end

	local totalHeight = uiListLayout.AbsoluteContentSize.Y
	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)

	local closeBtn = Instance.new("TextButton", repoViewerFrame)
	closeBtn.Text = "Close"
	closeBtn.Position = UDim2.new(0, 10, 1, -40)
	closeBtn.Size = UDim2.new(0, 80, 0, 30)
	closeBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.MouseButton1Click:Connect(function()
		repoViewerWidget.Enabled = false
	end)
end

-- Fetch repo structure
local function fetchRepoStructure()
	local s = plugin:GetSetting("GitToolsSettings") or {}
	print("fetchRepoStructure - Settings:", s)
	print("fetchRepoStructure - s.repo:", s.repo, "type:", type(s.repo))
	local isValid, owner, repo = validateSettings(s)
	if not isValid then
		statusBar.Text = "❌ Configure repo in Settings"
		settingsWidget.Enabled = true
		return
	end
	local url = string.format("https://api.github.com/repos/%s/%s/git/trees/main?recursive=1", owner, repo)
	print("fetchRepoStructure - Fetching URL:", url)
	local headers = {
		Accept = "application/vnd.github+json"
	}
	if s.token then
		headers.Authorization = "token " .. s.token
	end
	local success, response = pcall(function()
		return HttpService:GetAsync(url, true, headers)
	end)
	if not success then
		statusBar.Text = "❌ Failed to fetch repo: " .. tostring(response)
		print("fetchRepoStructure - HTTP request failed:", response)
		return
	end
	print("fetchRepoStructure - Response:", response)
	local successParse, data = pcall(function()
		return HttpService:JSONDecode(response)
	end)
	if not successParse or not data.tree then
		statusBar.Text = "❌ Invalid repo data"
		print("fetchRepoStructure - Failed to parse response or no tree data:", data)
		return
	end
	buildRepoTreeView(data.tree)
	statusBar.Text = "✅ Repo structure loaded"
end

-- Commit message dialog
local function showCommitMessageDialog(defaultMessage, callback)
	local screenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
	local dialogFrame = Instance.new("Frame", screenGui)
	dialogFrame.Size = UDim2.new(0, 300, 0, 100)
	dialogFrame.Position = UDim2.new(0.5, -150, 0.5, -50)
	dialogFrame.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	local textBox = Instance.new("TextBox", dialogFrame)
	textBox.Size = UDim2.new(1, -20, 0, 30)
	textBox.Position = UDim2.new(0, 10, 0, 10)
	textBox.Text = defaultMessage
	local confirmButton = Instance.new("TextButton", dialogFrame)
	confirmButton.Size = UDim2.new(0, 80, 0, 30)
	confirmButton.Position = UDim2.new(0.5, -40, 0, 60)
	confirmButton.Text = "Push"
	confirmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	confirmButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	confirmButton.MouseButton1Click:Connect(function()
		callback(textBox.Text)
		screenGui:Destroy()
	end)
end

-- Push selected scripts
local function pushSelected()
	local s = plugin:GetSetting("GitToolsSettings") or {}
	print("pushSelected - Settings:", s)
	print("pushSelected - s.token:", s.token, "type:", type(s.token))
	print("pushSelected - s.repo:", s.repo, "type:", type(s.repo))
	local isValid, owner, repo = validateSettings(s)
	if not isValid or not s.token then
		statusBar.Text = "❌ Configure token/repo in Settings"
		settingsWidget.Enabled = true
		return
	end
	local selection = SelectionService:Get()
	if #selection == 0 then
		statusBar.Text = "❌ Select scripts to push"
		return
	end
	local count = 0
	for _, inst in ipairs(selection) do
		if inst:IsA("Script") or inst:IsA("ModuleScript") then
			local path = getScriptPath(inst)
			local content = inst.Source
			local success, err = loadstring(content)
			if not success then
				statusBar.Text = "❌ Syntax error in " .. path
				print("pushSelected - Syntax error:", err)
				return
			end
			local url = string.format("https://api.github.com/repos/%s/%s/contents/%s", owner, repo, path)
			local sha = nil
			local checkSuccess, checkResponse = pcall(function()
				return HttpService:RequestAsync({
					Url = url,
					Method = "GET",
					Headers = {
						Authorization = "token " .. s.token,
						Accept = "application/vnd.github+json"
					}
				})
			end)
			if checkSuccess and checkResponse.StatusCode == 200 then
				local body = HttpService:JSONDecode(checkResponse.Body)
				sha = body.sha
			end
			local defaultMessage = "Updated " .. path
			showCommitMessageDialog(defaultMessage, function(message)
				local payload = {
					message = message,
					content = to_base64(content),
					branch = "main"
				}
				if sha then payload.sha = sha end
				local success, response = pcall(function()
					return HttpService:RequestAsync({
						Url = url,
						Method = "PUT",
						Headers = {
							Authorization = "token " .. s.token,
							Accept = "application/vnd.github+json"
						},
						Body = HttpService:JSONEncode(payload)
					})
				end)
				if success and (response.StatusCode == 200 or response.StatusCode == 201) then
					count = count + 1
					statusBar.Text = "✅ Pushed " .. count .. " scripts"
				else
					statusBar.Text = "❌ Failed to push " .. path .. ": " .. (response and response.StatusCode or "Request failed")
					print("pushSelected - Failed:", response and response.StatusCode or response)
				end
			end)
			break -- Process one script at a time to avoid dialog overlap
		end
	end
end

-- Copy tree
local function copyTree()
	local s = plugin:GetSetting("GitToolsSettings") or {}
	local treeServices = plugin:GetSetting("GitToolsTreeServices") or {}
	local includeNonScripts = s.includeNonScripts or false

	local validObjects = {}
	for _, serviceName in ipairs(serviceList) do
		if treeServices[serviceName] then
			local obj = game:FindFirstChild(serviceName)
			if obj then
				table.insert(validObjects, obj)
			end
		end
	end

	table.sort(validObjects, function(a, b) return a.Name < b.Name end)

	local tree = ""
	local lines = 0

	for i, obj in ipairs(validObjects) do
		local isLast = i == #validObjects
		tree = tree .. buildTree(obj, "", isLast, includeNonScripts)
		lines = lines + #obj:GetDescendants() + 1
	end
	if tree == "" then
		statusBar.Text = "❌ No services selected or found"
		return
	end
	print("copyTree - Tree copied:\n" .. tree)
	statusBar.Text = "📋 Tree copied (" .. lines .. " lines)"
end

-- Connect buttons
pushButton.MouseButton1Click:Connect(pushSelected)
showRepoButton.MouseButton1Click:Connect(function()
	local s = plugin:GetSetting("GitToolsSettings") or {}
	print("showRepoButton - Settings:", s)
	print("showRepoButton - s.repo:", s.repo, "type:", type(s.repo))
	local isValid = validateSettings(s)
	if not isValid then
		statusBar.Text = "❌ Please configure repo"
		settingsWidget.Enabled = true
		return
	end
	repoViewerWidget.Enabled = true
	fetchRepoStructure()
end)
copyTreeButton.MouseButton1Click:Connect(copyTree)

-- Right-click shortcuts
local pushAction = plugin:CreatePluginAction("PushViaGitTools", "Push via GitTools", "", "Push to GitHub", true)
pushAction.Triggered:Connect(pushSelected)

-- Toolbar buttons
local openButton = Toolbar:CreateButton("Open", "Open GitTools", "")
openButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

local settingsButton = Toolbar:CreateButton("Settings", "Configure token & repo", "")
settingsButton.Click:Connect(function()
	settingsWidget.Enabled = not settingsWidget.Enabled
end)

print("[GitTools] Plugin loaded. Use Settings button in toolbar to configure.")