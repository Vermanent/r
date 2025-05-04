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

-- Base64 decode
function from_base64(data)
	local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
	data = string.gsub(data, '[^'..b..'=]', '')
	return (data:gsub('.', function(x)
		if (x == '=') then return '' end
		local r,f='',(b:find(x)-1)
		for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
		return r;
	end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
		if (#x ~= 8) then return '' end
		local c=0
		for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
		return string.char(c)
	end))
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
local settingsInfo = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, true, true, 300, 180, 200, 150)
local settingsWidget = plugin:CreateDockWidgetPluginGui("GitToolsSettings", settingsInfo)
settingsWidget.Title = "GitTools Settings"
settingsWidget.Enabled = false

local settingsFrame = Instance.new("Frame", settingsWidget)
settingsFrame.Size = UDim2.new(1, 0, 1, 0)
settingsFrame.BackgroundTransparency = 1

local tokenLabel = Instance.new("TextLabel", settingsFrame)
tokenLabel.Text = "GitHub Token:"; tokenLabel.Position = UDim2.new(0,10,0,10); tokenLabel.Size = UDim2.new(0,100,0,20)
local tokenBox = Instance.new("TextBox", settingsFrame)
tokenBox.PlaceholderText = "token"; tokenBox.Position = UDim2.new(0,120,0,10); tokenBox.Size = UDim2.new(0,160,0,20)

local repoLabel = Instance.new("TextLabel", settingsFrame)
repoLabel.Text = "Owner/Repo:"; repoLabel.Position = UDim2.new(0,10,0,40); repoLabel.Size = UDim2.new(0,100,0,20)
local repoBox = Instance.new("TextBox", settingsFrame)
repoBox.PlaceholderText = "user/repo"; repoBox.Position = UDim2.new(0,120,0,40); repoBox.Size = UDim2.new(0,160,0,20)

local includeNonScriptsLabel = Instance.new("TextLabel", settingsFrame)
includeNonScriptsLabel.Text = "Include Non-Scripts in Tree:"; includeNonScriptsLabel.Position = UDim2.new(0,10,0,70); includeNonScriptsLabel.Size = UDim2.new(0,150,0,20)
local includeNonScriptsBox = Instance.new("TextBox", settingsFrame)
includeNonScriptsBox.Text = "false"; includeNonScriptsBox.Position = UDim2.new(0,160,0,70); includeNonScriptsBox.Size = UDim2.new(0,50,0,20)

local configureServicesBtn = Instance.new("TextButton", settingsFrame)
configureServicesBtn.Text = "Tree Services"
configureServicesBtn.Position = UDim2.new(0,100,0,100)
configureServicesBtn.Size = UDim2.new(0,80,0,30)
configureServicesBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
configureServicesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
configureServicesBtn.AutoButtonColor = false

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
	if tokenText == "" then
		statusBar.Text = "❌ Token cannot be empty"
		print("saveBtn - Empty token")
		return
	end
	local settings = {
		token = tokenText,
		repo = repoText,
		includeNonScripts = includeNonScriptsBox.Text:lower() == "true"
	}
	print("saveBtn - Saving settings:", settings)
	plugin:SetSetting("GitToolsSettings", settings)
	settingsWidget.Enabled = false
	statusBar.Text = "✅ Settings saved"
	print("[GitTools] Settings saved successfully!")
end)

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

local statusBar = Instance.new("TextLabel", frame)
statusBar.Size = UDim2.new(1, 0, 0, 20)
statusBar.Position = UDim2.new(0, 0, 1, -20)
statusBar.Text = "Ready"
statusBar.TextScaled = true

local pushButton = Instance.new("TextButton", frame)
pushButton.Size = UDim2.new(1, 0, 0, 30)
pushButton.Position = UDim2.new(0, 0, 0, 0)
pushButton.Text = "Push Selected"
pushButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)

local showRepoButton = Instance.new("TextButton", frame)
showRepoButton.Size = UDim2.new(1, 0, 0, 30)
showRepoButton.Position = UDim2.new(0, 0, 0, 35)
showRepoButton.Text = "Show Repo"
showRepoButton.BackgroundColor3 = Color3.fromRGB(50, 50, 150)

local copyTreeButton = Instance.new("TextButton", frame)
copyTreeButton.Size = UDim2.new(1, 0, 0, 30)
copyTreeButton.Position = UDim2.new(0, 0, 0, 70)
copyTreeButton.Text = "Copy Tree"
copyTreeButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)

-- Repo Viewer GUI
local repoViewerInfo = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, true, true, 400, 600, 300, 400)
local repoViewerWidget = plugin:CreateDockWidgetPluginGui("GitToolsRepoViewer", repoViewerInfo)
repoViewerWidget.Title = "Repository Viewer"
repoViewerWidget.Enabled = false

local repoViewerFrame = Instance.new("Frame", repoViewerWidget)
repoViewerFrame.Size = UDim2.new(1, 0, 1, 0)
repoViewerFrame.BackgroundTransparency = 1

-- Define dependent functions
local function buildRepoTreeView(tree)
	for _, child in ipairs(repoViewerFrame:GetChildren()) do
		child:Destroy()
	end
	local scrollingFrame = Instance.new("ScrollingFrame", repoViewerFrame)
	scrollingFrame.Size = UDim2.new(1, 0, 1, -50)
	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollingFrame.ScrollBarThickness = 10
	local uiListLayout = Instance.new("UIListLayout", scrollingFrame)
	uiListLayout.Padding = UDim.new(0, 5)

	local selectedItems = {}
	local blobCount = 0

	for _, item in ipairs(tree) do
		if item.type == "blob" then
			blobCount = blobCount + 1
			local frame = Instance.new("Frame", scrollingFrame)
			frame.Size = UDim2.new(1, 0, 0, 20)
			frame.BackgroundTransparency = 1
			local checkBtn = Instance.new("TextButton", frame)
			checkBtn.Name = item.path
			checkBtn.Text = "□"
			checkBtn.TextColor3 = Color3.fromRGB(255, 255, 255) -- White dots
			checkBtn.Position = UDim2.new(0, 0, 0, 0)
			checkBtn.Size = UDim2.new(0, 20, 0, 20)
			checkBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			local shaValue = Instance.new("StringValue", checkBtn)
			shaValue.Name = "Sha"
			shaValue.Value = item.sha
			local label = Instance.new("TextLabel", frame)
			label.Text = item.path
			label.TextColor3 = Color3.fromRGB(255, 255, 255)
			label.Position = UDim2.new(0, 25, 0, 0)
			label.Size = UDim2.new(1, -25, 1, 0)
			label.BackgroundTransparency = 1
			label.TextXAlignment = Enum.TextXAlignment.Left
			checkBtn.MouseButton1Click:Connect(function()
				if selectedItems[item.path] then
					selectedItems[item.path] = nil
					checkBtn.Text = "□"
				else
					selectedItems[item.path] = checkBtn
					checkBtn.Text = "■"
				end
			end)
		end
	end
	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, blobCount * 25)

	local pullBtn = Instance.new("TextButton", repoViewerFrame)
	pullBtn.Text = "Pull Selected"
	pullBtn.Position = UDim2.new(0, 10, 1, -40)
	pullBtn.Size = UDim2.new(0, 100, 0, 30)
	pullBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 150)
	pullBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	pullBtn.MouseButton1Click:Connect(function()
		pullSelectedRepoItems(selectedItems)
	end)

	local deleteBtn = Instance.new("TextButton", repoViewerFrame)
	deleteBtn.Text = "Delete Selected"
	deleteBtn.Position = UDim2.new(0, 120, 1, -40)
	deleteBtn.Size = UDim2.new(0, 100, 0, 30)
	deleteBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
	deleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	deleteBtn.MouseButton1Click:Connect(function()
		deleteSelectedRepoItems(selectedItems)
	end)
end

local function pullSelectedRepoItems(selectedItems)
	local s = plugin:GetSetting("GitToolsSettings") or {}
	print("pullSelectedRepoItems - Settings:", s)
	print("pullSelectedRepoItems - s.token:", s.token, "type:", type(s.token))
	print("pullSelectedRepoItems - s.repo:", s.repo, "type:", type(s.repo))
	if not s.token or not s.repo or type(s.repo) ~= "string" or s.repo:match("^%s*$") then
		statusBar.Text = "❌ Configure token/repo in Settings"
		print("pullSelectedRepoItems - Invalid settings")
		settingsWidget.Enabled = true
		return
	end
	local owner, repo = s.repo:match("([^/]+)/([^/]+)")
	if not owner or not repo then
		statusBar.Text = "❌ Invalid repo format"
		print("pullSelectedRepoItems - Invalid repo format:", s.repo)
		settingsWidget.Enabled = true
		return
	end
	for path in pairs(selectedItems) do
		local instancePath = path:match("^src/(.*)%.lua$")
		if instancePath then
			local parts = split(instancePath, "/")
			local current = game
			for _, part in ipairs(parts) do
				current = current:FindFirstChild(part)
				if not current then
					statusBar.Text = "❌ Instance not found: " .. instancePath
					print("pullSelectedRepoItems - Instance not found:", instancePath)
					return
				end
			end
			if current:IsA("Script") or current:IsA("ModuleScript") then
				local url = string.format("https://raw.githubusercontent.com/%s/%s/main/%s", owner, repo, path)
				print("pullSelectedRepoItems - Fetching URL:", url)
				local success, response = pcall(function()
					return HttpService:GetAsync(url, true)
				end)
				if success then
					current.Source = response
					statusBar.Text = "✅ Pulled " .. path
				else
					statusBar.Text = "❌ Failed to pull " .. path .. ": " .. tostring(response)
					print("pullSelectedRepoItems - Failed:", response)
				end
			else
				statusBar.Text = "❌ Not a script: " .. instancePath
				print("pullSelectedRepoItems - Not a script:", instancePath)
			end
		else
			statusBar.Text = "❌ Invalid path: " .. path
			print("pullSelectedRepoItems - Invalid path:", path)
		end
	end
end

local function deleteSelectedRepoItems(selectedItems)
	local s = plugin:GetSetting("GitToolsSettings") or {}
	print("deleteSelectedRepoItems - Settings:", s)
	print("deleteSelectedRepoItems - s.token:", s.token, "type:", type(s.token))
	print("deleteSelectedRepoItems - s.repo:", s.repo, "type:", type(s.repo))
	if not s.token or not s.repo or type(s.repo) ~= "string" or s.repo:match("^%s*$") then
		statusBar.Text = "❌ Configure token/repo in Settings"
		print("deleteSelectedRepoItems - Invalid settings")
		settingsWidget.Enabled = true
		return
	end
	local owner, repo = s.repo:match("([^/]+)/([^/]+)")
	if not owner or not repo then
		statusBar.Text = "❌ Invalid repo format"
		print("deleteSelectedRepoItems - Invalid repo format:", s.repo)
		settingsWidget.Enabled = true
		return
	end
	for path, checkBtn in pairs(selectedItems) do
		local sha = checkBtn:FindFirstChild("Sha").Value
		local url = string.format("https://api.github.com/repos/%s/%s/contents/%s", owner, repo, path)
		local payload = {
			message = "Deleted " .. path,
			sha = sha,
			branch = "main"
		}
		print("deleteSelectedRepoItems - Deleting URL:", url)
		local success, response = pcall(function()
			return HttpService:RequestAsync({
				Url = url,
				Method = "DELETE",
				Headers = {
					Authorization = "token " .. s.token,
					Accept = "application/vnd.github+json"
				},
				Body = HttpService:JSONEncode(payload)
			})
		end)
		if success and response.StatusCode == 200 then
			statusBar.Text = "✅ Deleted " .. path
		else
			statusBar.Text = "❌ Failed to delete " .. path .. ": " .. (response and response.StatusCode or "Request failed")
			print("deleteSelectedRepoItems - Failed:", response and response.StatusCode or response)
		end
	end
end

local function fetchRepoStructure()
	local s = plugin:GetSetting("GitToolsSettings") or {}
	print("fetchRepoStructure - Settings:", s)
	print("fetchRepoStructure - s.token:", s.token, "type:", type(s.token))
	print("fetchRepoStructure - s.repo:", s.repo, "type:", type(s.repo))
	if not s.token or not s.repo or type(s.repo) ~= "string" or s.repo:match("^%s*$") then
		statusBar.Text = "❌ Configure token/repo in Settings"
		print("fetchRepoStructure - Invalid settings")
		settingsWidget.Enabled = true
		return
	end
	local owner, repo = s.repo:match("([^/]+)/([^/]+)")
	if not owner or not repo then
		statusBar.Text = "❌ Invalid repo format (use owner/repo)"
		print("fetchRepoStructure - Invalid repo format:", s.repo)
		settingsWidget.Enabled = true
		return
	end
	local url = string.format("https://api.github.com/repos/%s/%s/git/trees/main?recursive=1", owner, repo)
	print("fetchRepoStructure - Fetching URL:", url)
	local success, response = pcall(function()
		return HttpService:GetAsync(url, true, {
			Authorization = "token " .. s.token,
			Accept = "application/vnd.github+json"
		})
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
	if not s.token or not s.repo or type(s.repo) ~= "string" or s.repo:match("^%s*$") then
		statusBar.Text = "❌ Configure token/repo in Settings"
		print("pushSelected - Invalid settings")
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
			local owner, repo = s.repo:match("([^/]+)/([^/]+)")
			if not owner or not repo then
				statusBar.Text = "❌ Invalid repo format"
				print("pushSelected - Invalid repo format:", s.repo)
				settingsWidget.Enabled = true
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
	print("showRepoButton - s.token:", s.token, "type:", type(s.token))
	print("showRepoButton - s.repo:", s.repo, "type:", type(s.repo))
	if not s.token or not s.repo or type(s.repo) ~= "string" or s.repo:match("^%s*$") then
		settingsWidget.Enabled = true
		statusBar.Text = "❌ Please configure token and repo"
		print("showRepoButton - Invalid settings")
	else
		repoViewerWidget.Enabled = true
		fetchRepoStructure()
	end
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