-- Simple GitSync Plugin: Push only selected scripts with full hierarchy tree view
-- File: SimpleGitSync.lua
-- Place under \Plugins\SimpleGitSync\

local HttpService = game:GetService("HttpService")
local SelectionService = game:GetService("Selection")

-- Base64 encode implementation
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function base64Encode(data)
	return ((data:gsub('.', function(x)
		local r,binary='',x:byte()
		for i=8,1,-1 do r=r..(binary%2^i-binary%2^(i-1)>0 and '1' or '0') end
		return r
	end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
		if #x < 6 then return '' end
		local c=0
		for i=1,6 do c=c + (x:sub(i,i)=='1' and 2^(6-i) or 0) end
		return b:sub(c+1,c+1)
	end)..({ '', '==', '=' })[#data%3+1])
end

-- Create toolbar and buttons
local toolbar = plugin:CreateToolbar("SimpleGitSync")
local pushButton = toolbar:CreateButton("PushSelected", "Push selected scripts to GitHub", "")
local settingsButton = toolbar:CreateButton("Settings", "Configure token & repo", "")
local copyTreeButton = toolbar:CreateButton("Copy Tree", "Copy full hierarchy tree of the entire game", "")

-- Settings widget
local info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, true, true, 300, 120, 200, 100)
local widget = plugin:CreateDockWidgetPluginGui("SimpleGitSyncSettings", info)
widget.Title = "SimpleGitSync Settings"
widget.Enabled = false
local frame = Instance.new("Frame", widget)
frame.Size = UDim2.new(1,0,1,0)

-- Token input
local tokenLabel = Instance.new("TextLabel", frame)
tokenLabel.Text = "GitHub Token:"; tokenLabel.Position = UDim2.new(0,10,0,10); tokenLabel.Size = UDim2.new(0,100,0,20)
local tokenBox = Instance.new("TextBox", frame)
tokenBox.PlaceholderText = "token"; tokenBox.Position = UDim2.new(0,120,0,10); tokenBox.Size = UDim2.new(0,160,0,20)

-- Repo input
local repoLabel = Instance.new("TextLabel", frame)
repoLabel.Text = "Owner/Repo:"; repoLabel.Position = UDim2.new(0,10,0,40); repoLabel.Size = UDim2.new(0,100,0,20)
local repoBox = Instance.new("TextBox", frame)
repoBox.PlaceholderText = "user/repo"; repoBox.Position = UDim2.new(0,120,0,40); repoBox.Size = UDim2.new(0,160,0,20)

-- Save settings
local saveBtn = Instance.new("TextButton", frame)
saveBtn.Text = "Save"; saveBtn.Position = UDim2.new(0,10,0,70); saveBtn.Size = UDim2.new(0,80,0,30)
saveBtn.MouseButton1Click:Connect(function()
	local settings = { token = tokenBox.Text, repo = repoBox.Text }
	plugin:SetSetting("SimpleGitSyncSettings", settings)
	widget.Enabled = false
	print("[SimpleGitSync] Settings saved.")
end)

-- Load settings
local settings = plugin:GetSetting("SimpleGitSyncSettings") or {}
if settings.token then tokenBox.Text = settings.token end
if settings.repo then repoBox.Text = settings.repo end

-- Toggle settings panel
settingsButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

-- Function to generate the full hierarchy structure text (including all scripts, modules, and folders)
local function getHierarchyText(startInstance, indentLevel)
	indentLevel = indentLevel or 0
	local indent = string.rep("  ", indentLevel)  -- Two spaces per indentation level
	local result = ""

	-- Add the name of the current instance with its type
	local instanceType = startInstance.ClassName
	result = result .. indent .. startInstance.Name .. " (" .. instanceType .. ")\n"

	-- Recursively add child instances (exclude non-Script/ModuleScript unless it's a folder)
	for _, child in ipairs(startInstance:GetChildren()) do
		-- Only add Script/ModuleScript or Folder types to the result
		if child:IsA("Script") or child:IsA("ModuleScript") or child:IsA("Folder") then
			result = result .. getHierarchyText(child, indentLevel + 1)
		end
	end

	return result
end

-- Handle Copy Tree button click
copyTreeButton.Click:Connect(function()
	local startInstance = game
	local fullHierarchyText = getHierarchyText(startInstance, 0)

	-- Create a TextBox to display the tree structure for manual copy
	local copyBox = Instance.new("TextBox")
	copyBox.Size = UDim2.new(1, 0, 0.7, 0) -- Take up most of the panel's space
	copyBox.Position = UDim2.new(0, 0, 0.3, 0) -- Place below the buttons
	copyBox.Text = fullHierarchyText
	copyBox.TextSize = 14
	copyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	copyBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	copyBox.ClearTextOnFocus = false
	copyBox.TextWrapped = true
	copyBox.MultiLine = true
	copyBox.Parent = widget

	-- Show the widget with the TextBox for copy
	widget.Enabled = true
end)

-- Push only selected scripts
local function pushSelected()
	local s = plugin:GetSetting("SimpleGitSyncSettings") or {}
	if not s.token or s.token == "" or not s.repo or s.repo == "" then
		warn("Please configure token and repo via the Settings button.")
		return
	end
	local selection = SelectionService:Get()
	if #selection == 0 then
		warn("No scripts selected. Please select Script or ModuleScript instances in Explorer.")
		return
	end
	local count = 0
	for _, inst in ipairs(selection) do
		if inst:IsA("Script") or inst:IsA("ModuleScript") then
			local path = inst:GetFullName():gsub("[%.]", "/") .. ".lua"
			local content = inst.Source or ""
			local url = string.format("https://api.github.com/repos/%s/contents/%s", s.repo, path)

			-- Check if file exists to include sha for update, otherwise skip sha to create new
			local sha = nil
			local check = HttpService:RequestAsync({
				Url = url,
				Method = "GET",
				Headers = {
					Authorization = "token " .. s.token,
					Accept = "application/vnd.github+json"
				}
			})
			if check.StatusCode == 200 then
				local body = HttpService:JSONDecode(check.Body)
				sha = body.sha
			end

			local payload = {
				message = "Auto-sync " .. path,
				content = base64Encode(content),
				branch = "main",
				sha = sha -- only included if file already exists
			}

			local res = HttpService:RequestAsync({
				Url = url,
				Method = "PUT",
				Headers = {
					Authorization = "token " .. s.token,
					Accept = "application/vnd.github+json"
				},
				Body = HttpService:JSONEncode(payload)
			})

			if res.StatusCode >= 200 and res.StatusCode < 300 then
				count = count + 1
			else
				warn("Failed to push " .. path .. ": " .. res.StatusCode)
			end
		end
	end
	print(string.format("[SimpleGitSync] Pushed %d scripts to %s", count, s.repo))
end

-- Bind pushSelected to button click
pushButton.Click:Connect(pushSelected)

print("[SimpleGitSync] Plugin loaded. Select scripts and click PushSelected to sync, or Copy Tree to copy the entire hierarchy.")
