if game.GameId ~= 6035872082 then
    return
end

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local zerohub = {
    Version = "4.1.0",
    Title = "zerohub.cc",
    SubTitle = "BETA: REPORT BUGS IN DISCORD | rivals",
    ConfigFolder = "zerohub_rivals_configs",
    Connections = {},
    LastPhase = "BOOT",
    FrameCount = 0,
    Toggles = {
        TeamCheck = true,
        WallCheck = true,
        ESPTeamCheck = true,
        WeaponESP = true,
    },
    Values = {
        AimbotKey = "MouseButton2 (Right Click)",
        AimbotMethod = "Camera",
        AimbotPart = "Head",
        AimbotSmoothness = 0.18,
        AimbotFOV = 160,
        PredictionAmount = 0.13,
        TriggerDelay = 0.04,
        SilentAimPart = "Head",
        SilentHitChance = 100,
        SilentHeadshotChance = 90,
        HitboxSize = 7,
        HitboxTransparency = 0.65,
        CustomFOV = 90,
        ThirdPersonDist = 12,
        VMOffsetX = 0,
        VMOffsetY = 0,
        VMOffsetZ = 0,
        ESPColorName = "Mint Green",
        TimeOfDay = 12,
        SpeedBoost = 1.4,
        JumpBoost = 60,
        FlySpeed = 75,
        SpinSpeed = 40,
        SelectedWrap = "Galaxy",
        SelectedHitSound = "Rust Headshot",
        HitSoundVolume = 1.5,
    },
    Controls = {},
    AimbotKeyEnum = Enum.UserInputType.MouseButton2,
    ESPColor = Color3.fromRGB(0, 255, 170),
    SelectedConfig = "default",
    ConfigNameInput = "default",
}

local function logEvent(category, msg, ...)
    local formatted = tostring(msg)
    if select("#", ...) > 0 then
        local ok, res = pcall(string.format, tostring(msg), ...)
        if ok then formatted = res end
    end
    print(string.format("[%s][zerohub][%s] %s", os.date("%X"), tostring(category), formatted))
end

local function safeRun(tag, fn, ...)
    zerohub.LastPhase = tag
    local ok, err = xpcall(fn, function(e)
        return tostring(e) .. "\n" .. debug.traceback("", 2)
    end, ...)
    if not ok then
        warn(string.format("[zerohub][ERROR][%s] %s", tostring(tag), tostring(err)))
    end
    return ok
end

logEvent("BOOT", "Initializing services... PlaceId=%d GameId=%d", game.PlaceId, game.GameId)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local function getCam()
    return Workspace.CurrentCamera
end

if type(getoriginalenv) == "function" then
    for k, v in pairs(getoriginalenv()) do
        if getfenv()[k] == nil or k == "loadstring" then
            getfenv()[k] = v
        end
    end
end

local loadstring = (type(getoriginalenv) == "function" and getoriginalenv().loadstring) or loadstring

local SafeGuiParent = (type(gethui) == "function" and gethui()) or CoreGui

if SafeGuiParent then
    for _, c in ipairs(SafeGuiParent:GetChildren()) do
        if c.Name == "WindUI" or c.Name:sub(1, 7) == "WindUI/" or c.Name == "Rayfield" or c.Name:sub(1, 8) == "Rayfield" or c.Name == "zerohub_Overlay" or c.Name == "ESPContainer" then
            pcall(function() c:Destroy() end)
        end
    end
end
pcall(function()
    local oldESP = Workspace:FindFirstChild("ESPContainer")
    if oldESP then oldESP:Destroy() end
end)

local function loadRayfield()
    local cacheFile = "zerohub/rayfield_gen2.lua"
    if typeof and typeof(isfile) == "function" and isfile(cacheFile) and typeof(readfile) == "function" then
        local ok, cached = pcall(readfile, cacheFile)
        if ok and type(cached) == "string" and #cached > 50000 then
            local loadOk, lib = pcall(function() return loadstring(cached)() end)
            if loadOk and lib and type(lib.CreateWindow) == "function" then
                return lib
            end
        end
    end

    local endpoints = {
        "https://github.com/SiriusSoftwareLtd/rayfield-gen2/releases/download/1.2.6/bundled.luau",
        "https://github.com/SiriusSoftwareLtd/rayfield-gen2/releases/latest/download/bundled.luau",
        "https://sirius.menu/gen2",
    }

    local req = (type(request) == "function" and request)
        or (type(http_request) == "function" and http_request)
        or (type(syn) == "table" and type(syn.request) == "function" and syn.request)
        or (type(http) == "table" and type(http.request) == "function" and http.request)

    for _, url in ipairs(endpoints) do
        local src = nil
        if req then
            local ok, res = pcall(req, { Url = url, Method = "GET" })
            if ok and type(res) == "table" and res.StatusCode == 200 and type(res.Body) == "string" and #res.Body > 50000 then
                src = res.Body
            end
        end
        if not src then
            local ok, res = pcall(function() return game:HttpGet(url) end)
            if ok and type(res) == "string" and #res > 50000 then
                src = res
            end
        end

        if src then
            local loadOk, lib = pcall(function() return loadstring(src)() end)
            if loadOk and lib and type(lib.CreateWindow) == "function" then
                if type(writefile) == "function" then
                    pcall(function()
                        if type(makefolder) == "function" and type(isfolder) == "function" and not isfolder("zerohub") then
                            makefolder("zerohub")
                        end
                        writefile(cacheFile, src)
                    end)
                end
                return lib
            end
        end
    end

    error("Failed to load Rayfield Gen2 from GitHub release mirrors and sirius.menu.", 0)
end

local Rayfield = loadRayfield()
local Window

local function notify(title, content, duration)
    pcall(function()
        if Window and Window.Notify and not Window.unloaded then
            Window:Notify({
                Title = title or "zerohub.cc",
                Content = content or "",
                Duration = duration or 2.5,
            })
        end
    end)
end

local OverlayGui = Instance.new("ScreenGui")
OverlayGui.Name = "zerohub_Overlay"
OverlayGui.IgnoreGuiInset = true
OverlayGui.ResetOnSpawn = false
OverlayGui.DisplayOrder = 999
OverlayGui.Parent = SafeGuiParent

local ESPHolder = Instance.new("Folder")
ESPHolder.Name = "ESPContainer"
-- 3D world-space instances (BillboardGui, Highlight) must be parented in Workspace, NEVER in a 2D ScreenGui container
ESPHolder.Parent = Workspace

local BoxHolder = Instance.new("Folder")
BoxHolder.Name = "BoxContainer"
BoxHolder.Parent = OverlayGui

local FOVFrame = Instance.new("Frame")
FOVFrame.Name = "FOVRing"
FOVFrame.BackgroundTransparency = 1
FOVFrame.AnchorPoint = Vector2.new(0.5, 0.5)
FOVFrame.Position = UDim2.fromScale(0.5, 0.5)
FOVFrame.Size = UDim2.fromOffset(zerohub.Values.AimbotFOV * 2, zerohub.Values.AimbotFOV * 2)
FOVFrame.Visible = false
FOVFrame.Parent = OverlayGui

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOVFrame

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Thickness = 1.5
FOVStroke.Color = Color3.fromRGB(255, 255, 255)
FOVStroke.Transparency = 0.15
FOVStroke.Parent = FOVFrame

local CrosshairHolder = Instance.new("Frame")
CrosshairHolder.Name = "Crosshair"
CrosshairHolder.BackgroundTransparency = 1
CrosshairHolder.AnchorPoint = Vector2.new(0.5, 0.5)
CrosshairHolder.Position = UDim2.fromScale(0.5, 0.5)
CrosshairHolder.Size = UDim2.fromOffset(18, 18)
CrosshairHolder.Visible = false
CrosshairHolder.Parent = OverlayGui

local CrossH = Instance.new("Frame")
CrossH.BorderSizePixel = 0
CrossH.BackgroundColor3 = Color3.fromRGB(0, 255, 170)
CrossH.AnchorPoint = Vector2.new(0.5, 0.5)
CrossH.Position = UDim2.fromScale(0.5, 0.5)
CrossH.Size = UDim2.fromOffset(14, 2)
CrossH.Parent = CrosshairHolder

local CrossV = Instance.new("Frame")
CrossV.BorderSizePixel = 0
CrossV.BackgroundColor3 = Color3.fromRGB(0, 255, 170)
CrossV.AnchorPoint = Vector2.new(0.5, 0.5)
CrossV.Position = UDim2.fromScale(0.5, 0.5)
CrossV.Size = UDim2.fromOffset(2, 14)
CrossV.Parent = CrosshairHolder

local function getChar(player)
    local p = player or LocalPlayer
    local char = p and p.Character
    if char and char.Parent then
        return char
    end
    return nil
end

local function getHRP(player)
    local char = getChar(player)
    if not char or not char.Parent then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    if hrp and hrp.Parent then
        return hrp
    end
    return nil
end

local function getHum(player)
    local char = getChar(player)
    if not char or not char.Parent then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Parent then
        return hum
    end
    return nil
end

local function isTeammate(player)
    if not player or player == LocalPlayer then return true end
    if not zerohub.Toggles.TeamCheck then return false end
    if not player.Neutral and not LocalPlayer.Neutral then
        if player.Team ~= nil and LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team then
            return true
        end
        if player.TeamColor == LocalPlayer.TeamColor and player.Team ~= nil then
            return true
        end
    end
    local pTeam = player:GetAttribute("Team") or player:GetAttribute("TeamId")
    local lTeam = LocalPlayer:GetAttribute("Team") or LocalPlayer:GetAttribute("TeamId")
    if pTeam ~= nil and lTeam ~= nil and pTeam ~= "" and pTeam == lTeam then
        return true
    end
    return false
end

local function isAlive(player)
    local char = getChar(player)
    if not char or not char.Parent then return false end
    local hrp = getHRP(player)
    if not hrp or not hrp.Parent then return false end
    local hum = getHum(player)
    if not hum or not hum.Parent or hum.Health <= 0 then return false end
    if char:FindFirstChildOfClass("ForceField") then return false end
    return true
end

local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Exclude
RayParams.IgnoreWater = true

local function isVisible(targetPart, targetChar)
    local cam = getCam()
    if not cam or not cam.Parent or not targetPart or not targetPart.Parent or not targetChar or not targetChar.Parent then
        return false
    end
    local origin = cam.CFrame.Position
    local targetPos = targetPart.Position
    local ignoreList = {}
    local myChar = getChar()
    if myChar then table.insert(ignoreList, myChar) end
    local vm = Workspace:FindFirstChild("ViewModels")
    if vm then table.insert(ignoreList, vm) end

    for _ = 1, 4 do
        RayParams.FilterDescendantsInstances = ignoreList
        local dir = targetPos - origin
        local ok, result = pcall(function()
            return Workspace:Raycast(origin, dir, RayParams)
        end)
        if not ok or not result or not result.Instance then
            return true
        end
        local hitInst = result.Instance
        if hitInst:IsDescendantOf(targetChar) then
            return true
        end
        if hitInst.Transparency >= 0.9 or not hitInst.CanCollide or hitInst:FindFirstAncestorOfClass("Accessory") then
            table.insert(ignoreList, hitInst)
        else
            return false
        end
    end
    return false
end

local function getAimReferencePoint()
    local cam = getCam()
    if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter and cam then
        return cam.ViewportSize / 2
    end
    return UserInputService:GetMouseLocation()
end

local function resolveTargetPart(char, preference, refPoint)
    local cam = getCam()
    if not char or not cam then return nil end
    if preference == "Closest" then
        local bestPart, bestDist = nil, math.huge
        for _, name in ipairs({"Head", "UpperTorso", "HumanoidRootPart", "LowerTorso", "Torso"}) do
            local p = char:FindFirstChild(name)
            if p and p:IsA("BasePart") then
                local screenPos, onScreen = cam:WorldToViewportPoint(p.Position)
                if onScreen and screenPos.Z > 0 then
                    local d = (Vector2.new(screenPos.X, screenPos.Y) - refPoint).Magnitude
                    if d < bestDist then
                        bestDist = d
                        bestPart = p
                    end
                end
            end
        end
        return bestPart
    end
    return char:FindFirstChild(preference) or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
end

local function getClosestTarget(fovRadius, partPref, wallCheck)
    local cam = getCam()
    if not cam then return nil, nil end
    local refPoint = getAimReferencePoint()
    local closestPlayer = nil
    local closestPart = nil
    local shortestDist = fovRadius or math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not isTeammate(player) and isAlive(player) then
            local char = getChar(player)
            local part = resolveTargetPart(char, partPref, refPoint)
            if part and part.Parent then
                local screenPos, onScreen = cam:WorldToViewportPoint(part.Position)
                if onScreen and screenPos.Z > 0 then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - refPoint).Magnitude
                    if dist <= shortestDist then
                        if not wallCheck or isVisible(part, char) then
                            shortestDist = dist
                            closestPlayer = player
                            closestPart = part
                        end
                    end
                end
            end
        end
    end

    return closestPlayer, closestPart
end

local function triggerPrimaryAction()
    local char = getChar()
    local tool = char and char:FindFirstChildOfClass("Tool")
    if tool then
        pcall(function() tool:Activate() end)
        return
    end
    if type(mouse1click) == "function" then
        pcall(mouse1click)
    end
end

local function triggerSecondaryAction()
    if type(mouse2click) == "function" then
        pcall(mouse2click)
    end
end

local HIT_SOUNDS = {
    ["Rust Headshot"] = 4764109000,
    ["CS:GO Headshot"] = 1347140027,
    ["Neverlose"] = 6534948092,
    ["Skeet / Gamesense"] = 5447626464,
    ["Bameware"] = 3124331820,
    ["Bell Ding"] = 160432334,
    ["TF2 Critical"] = 296102734,
    ["Bubble Pop"] = 198598793,
}

local WRAP_PRESETS = {
    ["Galaxy"] = { Color = Color3.fromRGB(115, 65, 255), Material = Enum.Material.ForceField },
    ["Neon Emerald"] = { Color = Color3.fromRGB(0, 255, 160), Material = Enum.Material.Neon },
    ["Crimson Gold"] = { Color = Color3.fromRGB(255, 55, 85), Material = Enum.Material.Glass },
    ["Cyber Ice"] = { Color = Color3.fromRGB(60, 210, 255), Material = Enum.Material.Neon },
    ["Obsidian Chrome"] = { Color = Color3.fromRGB(35, 35, 45), Material = Enum.Material.SmoothPlastic },
    ["Solar Flare"] = { Color = Color3.fromRGB(255, 165, 20), Material = Enum.Material.ForceField },
}

local ESP_COLOR_MAP = {
    ["Mint Green"] = Color3.fromRGB(0, 255, 170),
    ["Crimson Red"] = Color3.fromRGB(255, 65, 85),
    ["Electric Blue"] = Color3.fromRGB(50, 170, 255),
    ["Neon Purple"] = Color3.fromRGB(185, 75, 255),
    ["Pure White"] = Color3.fromRGB(255, 255, 255),
    ["Golden Yellow"] = Color3.fromRGB(255, 215, 50),
}

local AIM_KEY_MAP = {
    ["MouseButton2 (Right Click)"] = Enum.UserInputType.MouseButton2,
    ["MouseButton1 (Left Click)"] = Enum.UserInputType.MouseButton1,
    ["LeftShift"] = Enum.KeyCode.LeftShift,
    ["LeftAlt"] = Enum.KeyCode.LeftAlt,
    ["E"] = Enum.KeyCode.E,
    ["Q"] = Enum.KeyCode.Q,
    ["C"] = Enum.KeyCode.C,
}

local PooledHitSound = Instance.new("Sound")
PooledHitSound.Name = "ZH_HitSound"
PooledHitSound.SoundId = "rbxassetid://4764109000"
PooledHitSound.Volume = 1.5
PooledHitSound.Parent = game:GetService("SoundService")

local PooledHitmarker = Instance.new("TextLabel")
PooledHitmarker.Name = "ZH_Hitmarker"
PooledHitmarker.BackgroundTransparency = 1
PooledHitmarker.AnchorPoint = Vector2.new(0.5, 0.5)
PooledHitmarker.Size = UDim2.fromOffset(22, 22)
PooledHitmarker.Text = "×"
PooledHitmarker.TextColor3 = zerohub.ESPColor
PooledHitmarker.TextStrokeTransparency = 0.1
PooledHitmarker.TextSize = 22
PooledHitmarker.Font = Enum.Font.GothamBold
PooledHitmarker.Visible = false
PooledHitmarker.Parent = OverlayGui

local lastHitFeedbackTime = 0
local function playHitFeedback(targetPos)
    if (tick() - lastHitFeedbackTime) < 0.08 then return end
    lastHitFeedbackTime = tick()

    if zerohub.Toggles.HitSound then
        pcall(function()
            local id = HIT_SOUNDS[zerohub.Values.SelectedHitSound] or 4764109000
            PooledHitSound.SoundId = "rbxassetid://" .. id
            PooledHitSound.Volume = zerohub.Values.HitSoundVolume
            PooledHitSound:Play()
        end)
    end

    if zerohub.Toggles.Hitmarker2D and targetPos then
        local cam = getCam()
        if cam then
            pcall(function()
                local sp, onScreen = cam:WorldToViewportPoint(targetPos)
                if onScreen and sp.Z > 0 then
                    PooledHitmarker.Position = UDim2.fromOffset(sp.X, sp.Y)
                    PooledHitmarker.TextColor3 = zerohub.ESPColor
                    PooledHitmarker.Visible = true
                    task.delay(0.18, function()
                        PooledHitmarker.Visible = false
                    end)
                end
            end)
        end
    end
end

pcall(function() loadstring(game:HttpGet("https://scriptblox.com/ingest/clientv2.lua"))("proj_879959c742fe", "1.0.0", false) end)

Window = Rayfield:CreateWindow({
    Name = "zerohub.cc",
    Icon = "crosshair",
    Subtitle = "BETA: REPORT BUGS IN DISCORD | rivals",
    Theme = "Default",
})

if Window and not Window.Destroy then
    Window.Destroy = function(self)
        if self.Unload then
            self:Unload()
        end
    end
end

local function wrapTab(rawTab)
    local wrapped = {}

    function wrapped:Button(props)
        props = props or {}
        local ctrl = rawTab:CreateButton({
            Name = props.Title or props.Name or "Button",
            Description = props.Desc or props.Description,
            Callback = props.Callback,
        })
        return ctrl
    end

    function wrapped:Toggle(props)
        props = props or {}
        local defVal = false
        if props.Value ~= nil then
            defVal = props.Value
        elseif props.Default ~= nil then
            defVal = props.Default
        end
        local ctrl = rawTab:CreateToggle({
            Name = props.Title or props.Name or "Toggle",
            Description = props.Desc or props.Description,
            Value = defVal,
            Callback = props.Callback,
        })
        if ctrl and not ctrl.Set then
            function ctrl:Set(val, skipCallback)
                if typeof(val) ~= "boolean" then
                    val = not not val
                end
                self.value = val
                if self._animateIndicator then
                    pcall(function() self:_animateIndicator() end)
                end
                if not skipCallback and self.callback then
                    pcall(function() self.callback(self.value) end)
                end
                if self.window and self.window._persist then
                    pcall(function() self.window:_persist(self) end)
                end
            end
        end
        if ctrl and not ctrl.SetValue then
            ctrl.SetValue = ctrl.Set
        end
        return ctrl
    end

    function wrapped:Slider(props)
        props = props or {}
        local minVal = (props.Value and props.Value.Min) or (props.Range and props.Range[1]) or 0
        local maxVal = (props.Value and props.Value.Max) or (props.Range and props.Range[2]) or 100
        local defVal = (props.Value and props.Value.Default) or (props.Default ~= nil and props.Default) or (typeof(props.Value) == "number" and props.Value) or minVal
        local stepVal = props.Step or props.Increment or 1
        local ctrl = rawTab:CreateSlider({
            Name = props.Title or props.Name or "Slider",
            Description = props.Desc or props.Description,
            Range = { minVal, maxVal },
            Increment = stepVal,
            Value = defVal,
            Callback = props.Callback,
        })
        if ctrl and not ctrl.SetValue then
            ctrl.SetValue = ctrl.Set
        end
        return ctrl
    end

    function wrapped:Dropdown(props)
        props = props or {}
        local opts = props.Values or props.Options or {}
        local defVal = props.Value
        if defVal == nil then
            defVal = props.Default
        end
        local ctrl = rawTab:CreateDropdown({
            Name = props.Title or props.Name or "Dropdown",
            Description = props.Desc or props.Description,
            Options = opts,
            Value = defVal,
            MultiSelect = props.MultiSelect or false,
            Callback = props.Callback,
        })
        if ctrl then
            if not ctrl.Select then
                ctrl.Select = ctrl.Set
            end
            if not ctrl.SetValue then
                ctrl.SetValue = ctrl.Set
            end
        end
        return ctrl
    end

    function wrapped:Input(props)
        props = props or {}
        local ctrl = rawTab:CreateInput({
            Name = props.Title or props.Name or "Input",
            Placeholder = props.Placeholder or "",
            Numeric = props.Numeric or false,
            Value = props.Value or props.Default or "",
            Callback = props.Callback,
        })
        return ctrl
    end

    function wrapped:Section(props)
        props = props or {}
        return rawTab:CreateSection({
            Name = props.Title or props.Name or "Section",
        })
    end

    function wrapped:Paragraph(props)
        props = props or {}
        local ctrl = rawTab:CreateText({
            Name = props.Title or props.Name or "",
            Text = props.Desc or props.Text or "",
        })
        if ctrl then
            if not ctrl.SetDesc then
                ctrl.SetDesc = function(self, desc)
                    if self.Set then
                        pcall(function() self:Set(tostring(desc or "")) end)
                    end
                end
            end
            if not ctrl.SetTitle then
                ctrl.SetTitle = function(self, title)
                    if self.SetTitle then
                        pcall(function() self:SetTitle(tostring(title or "")) end)
                    end
                end
            end
        end
        return ctrl
    end

    function wrapped:Select()
        if rawTab.Select then
            pcall(function() rawTab:Select() end)
        end
    end

    setmetatable(wrapped, {
        __index = rawTab
    })

    return wrapped
end

local function createTab(props)
    local raw = Window:CreateTab({
        Name = props.Title or props.Name or "Tab",
        Icon = props.Icon or props.icon,
    })
    return wrapTab(raw)
end

Window.Tab = function(self, props)
    return createTab(props)
end

local Tabs = {
    Dashboard = createTab({ Title = "Dashboard", Icon = "home" }),
    Combat = createTab({ Title = "Aimbot", Icon = "crosshair" }),
    SilentAim = createTab({ Title = "Silent & Combat", Icon = "zap" }),
    Visuals = createTab({ Title = "Visuals & ESP", Icon = "eye" }),
    World = createTab({ Title = "World & View", Icon = "sun" }),
    Movement = createTab({ Title = "Movement", Icon = "wind" }),
    Skins = createTab({ Title = "Cosmetics", Icon = "sparkles" }),
    Configs = createTab({ Title = "Configs", Icon = "save" }),
    Settings = createTab({ Title = "Settings", Icon = "settings" }),
}

pcall(function()
    Tabs.Dashboard:Select()
end)

local InitializingUI = true

local function registerToggle(tab, key, info)
    local defaultVal = zerohub.Toggles[key] or info.Value or false
    zerohub.Toggles[key] = defaultVal
    local ctrl = tab:Toggle({
        Title = info.Title,
        Desc = info.Desc,
        Value = defaultVal,
        Callback = function(state)
            zerohub.Toggles[key] = state
            if InitializingUI then return end
            if info.Callback then
                safeRun("Toggle_" .. key, info.Callback, state)
            end
        end
    })
    zerohub.Controls["Toggle_" .. key] = ctrl
    return ctrl
end

local function registerSlider(tab, key, info)
    local defaultVal = zerohub.Values[key] or info.Value.Default
    zerohub.Values[key] = defaultVal
    local ctrl = tab:Slider({
        Title = info.Title,
        Desc = info.Desc,
        Step = info.Step or 1,
        Value = { Min = info.Value.Min, Max = info.Value.Max, Default = defaultVal },
        Callback = function(val)
            local num = tonumber(val) or defaultVal
            zerohub.Values[key] = num
            if InitializingUI then return end
            if info.Callback then
                safeRun("Slider_" .. key, info.Callback, num)
            end
        end
    })
    zerohub.Controls["Slider_" .. key] = ctrl
    return ctrl
end

local function registerDropdown(tab, key, info)
    local defaultVal = zerohub.Values[key] or info.Value
    zerohub.Values[key] = defaultVal
    local ctrl = tab:Dropdown({
        Title = info.Title,
        Values = info.Values,
        Value = defaultVal,
        Callback = function(val)
            zerohub.Values[key] = val
            if InitializingUI then return end
            if info.Callback then
                safeRun("Dropdown_" .. key, info.Callback, val)
            end
        end
    })
    zerohub.Controls["Dropdown_" .. key] = ctrl
    return ctrl
end

Tabs.Dashboard:Button({
    Title = "Copy Discord",
    Desc = "Copies invite link to clipboard",
    Callback = function()
        local clip = setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set)
        if clip then
            pcall(clip, "https://join.zerohub.cc/")
            notify("Discord", "Copied invite link to clipboard")
        else
            notify("Clipboard", "Clipboard function not supported")
        end
    end
})

Tabs.Dashboard:Section({ Title = "Server & Match Status" })

local StatsCard = Tabs.Dashboard:Paragraph({
    Title = "Match & Engine Status",
    Desc = string.format("Players: %d/%d  |  UniverseId: %d", #Players:GetPlayers(), Players.MaxPlayers, game.GameId)
})

Tabs.Dashboard:Button({
    Title = "Refresh Match Info",
    Desc = "Updates current FPS and player count",
    Callback = function()
        local fps = math.floor(Workspace:GetRealPhysicsFPS())
        local players = #Players:GetPlayers()
        StatsCard:SetDesc(string.format("Players: %d/%d  |  FPS: %d  |  UniverseId: %d", players, Players.MaxPlayers, fps, game.GameId))
    end
})

Tabs.Dashboard:Section({ Title = "Server Options" })

Tabs.Dashboard:Button({
    Title = "Rejoin Server",
    Desc = "Rejoins the current lobby or match instance",
    Callback = function()
        pcall(function()
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end)
    end
})

Tabs.Dashboard:Button({
    Title = "Server Hop",
    Desc = "Finds and joins a different public server",
    Callback = function()
        task.spawn(function()
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
            local success, result = pcall(function()
                return HttpService:JSONDecode(game:HttpGet(url))
            end)
            if success and result and result.data then
                for _, s in ipairs(result.data) do
                    if s.playing < s.maxPlayers and s.id ~= game.JobId then
                        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                        return
                    end
                end
            end
            notify("Server Hop", "No other servers found")
        end)
    end
})

Tabs.Combat:Section({ Title = "Precision Aimbot" })

local function isAimKeyDown()
    local key = zerohub.AimbotKeyEnum
    if typeof(key) == "EnumItem" then
        if key.EnumType == Enum.UserInputType then
            return UserInputService:IsMouseButtonPressed(key)
        elseif key.EnumType == Enum.KeyCode then
            return UserInputService:IsKeyDown(key)
        end
    end
    return false
end

registerToggle(Tabs.Combat, "Aimbot", {
    Title = "Enable Aimbot",
    Desc = "Locks onto enemies inside FOV with frame-independent smoothing",
    Value = false,
})

registerToggle(Tabs.Combat, "AimbotAlwaysOn", {
    Title = "Always On (No Key Required)",
    Desc = "Tracks targets automatically without holding the activation key",
    Value = false,
})

registerDropdown(Tabs.Combat, "AimbotMethod", {
    Title = "Aimbot Method",
    Values = { "Camera", "Mouse (mousemoverel)" },
    Value = "Camera",
})

registerDropdown(Tabs.Combat, "AimbotKey", {
    Title = "Aimbot Activation Key",
    Values = {
        "MouseButton2 (Right Click)",
        "MouseButton1 (Left Click)",
        "LeftShift",
        "LeftAlt",
        "E",
        "Q",
        "C",
    },
    Value = "MouseButton2 (Right Click)",
    Callback = function(val)
        zerohub.Values.AimbotKey = val
        zerohub.AimbotKeyEnum = AIM_KEY_MAP[val] or Enum.UserInputType.MouseButton2
    end
})

registerDropdown(Tabs.Combat, "AimbotPart", {
    Title = "Target Hitbox",
    Values = { "Head", "UpperTorso", "HumanoidRootPart", "Closest" },
    Value = "Head",
})

registerSlider(Tabs.Combat, "AimbotSmoothness", {
    Title = "Aimbot Smoothness",
    Desc = "0.05 = Instant lock, 0.80 = Ultra-smooth legit assist",
    Step = 0.05,
    Value = { Min = 0.05, Max = 0.95, Default = 0.18 },
})

registerToggle(Tabs.Combat, "AimPrediction", {
    Title = "Velocity Prediction",
    Desc = "Leads moving targets based on their real-time velocity",
    Value = false,
})

registerSlider(Tabs.Combat, "PredictionAmount", {
    Title = "Prediction Factor",
    Desc = "Lead multiplier for moving targets",
    Step = 0.01,
    Value = { Min = 0.02, Max = 0.35, Default = 0.13 },
})

registerSlider(Tabs.Combat, "AimbotFOV", {
    Title = "FOV Radius",
    Desc = "Targeting field of view radius in pixels",
    Step = 5,
    Value = { Min = 20, Max = 500, Default = 160 },
    Callback = function(val)
        FOVFrame.Size = UDim2.fromOffset(val * 2, val * 2)
    end
})

registerToggle(Tabs.Combat, "ShowFOV", {
    Title = "Show FOV Circle",
    Desc = "Draws the targeting radius ring on your screen",
    Value = false,
    Callback = function(state)
        FOVFrame.Visible = state
    end
})

Tabs.Combat:Section({ Title = "Target Checks & Triggerbot" })

registerToggle(Tabs.Combat, "TeamCheck", {
    Title = "Team Check (Smart FFA Safe)",
    Desc = "Ignores teammates while still targeting everyone in 1v1 / FFA",
    Value = true,
})

registerToggle(Tabs.Combat, "WallCheck", {
    Title = "Wall / Visibility Check",
    Desc = "Penetrates glass/accessories and only locks visible enemies",
    Value = true,
})

registerToggle(Tabs.Combat, "Triggerbot", {
    Title = "Triggerbot",
    Desc = "Automatically fires when your crosshair passes over an enemy",
    Value = false,
})

registerSlider(Tabs.Combat, "TriggerDelay", {
    Title = "Triggerbot Delay (s)",
    Desc = "Delay between automatic Triggerbot shots",
    Step = 0.01,
    Value = { Min = 0.01, Max = 0.40, Default = 0.04 },
})

Tabs.SilentAim:Section({ Title = "Full-Auto Silent Aim & Ragebot" })

registerToggle(Tabs.SilentAim, "SilentAim", {
    Title = "Enable Silent Aim",
    Desc = "Redirects shots toward enemy hitboxes without deferred camera race conditions",
    Value = false,
})

registerToggle(Tabs.SilentAim, "Ragebot", {
    Title = "Auto-Shoot Ragebot",
    Desc = "Automatically locks and fires at visible enemies inside FOV",
    Value = false,
})

registerDropdown(Tabs.SilentAim, "SilentAimPart", {
    Title = "Silent Aim Target Part",
    Values = { "Head", "UpperTorso", "HumanoidRootPart", "Closest" },
    Value = "Head",
})

registerSlider(Tabs.SilentAim, "SilentHitChance", {
    Title = "Hit Chance (%)",
    Desc = "Probability that a shot redirects to the target",
    Step = 1,
    Value = { Min = 1, Max = 100, Default = 100 },
})

registerSlider(Tabs.SilentAim, "SilentHeadshotChance", {
    Title = "Headshot Chance (%)",
    Desc = "Chance to prioritize Head over body parts",
    Step = 1,
    Value = { Min = 0, Max = 100, Default = 90 },
})

registerToggle(Tabs.SilentAim, "Wallbang", {
    Title = "Ignore Wall Check",
    Desc = "Allows silent aim to target enemies behind thin cover",
    Value = false,
})

Tabs.SilentAim:Section({ Title = "Hitbox Expander" })

local function updateEnemyHitboxes()
    if not zerohub.Toggles.HitboxExpander then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and not isTeammate(p) then
            local hrp = getHRP(p)
            if hrp and isAlive(p) then
                local sz = zerohub.Values.HitboxSize
                hrp.Size = Vector3.new(sz, sz, sz)
                hrp.Transparency = zerohub.Values.HitboxTransparency
                hrp.CanCollide = false
            end
        end
    end
end

registerToggle(Tabs.SilentAim, "HitboxExpander", {
    Title = "Hitbox Expander",
    Desc = "Enlarges enemy root hitboxes so shots register easily",
    Value = false,
    Callback = function()
        safeRun("HitboxUpdate", updateEnemyHitboxes)
    end
})

registerSlider(Tabs.SilentAim, "HitboxSize", {
    Title = "Hitbox Size",
    Desc = "Size in studs of expanded enemy hitboxes",
    Step = 0.5,
    Value = { Min = 2, Max = 18, Default = 7 },
    Callback = function()
        if zerohub.Toggles.HitboxExpander then
            safeRun("HitboxUpdate", updateEnemyHitboxes)
        end
    end
})

registerSlider(Tabs.SilentAim, "HitboxTransparency", {
    Title = "Hitbox Transparency",
    Desc = "Transparency of expanded hitboxes",
    Step = 0.05,
    Value = { Min = 0.1, Max = 1.0, Default = 0.65 },
    Callback = function()
        if zerohub.Toggles.HitboxExpander then
            safeRun("HitboxUpdate", updateEnemyHitboxes)
        end
    end
})

Tabs.SilentAim:Section({ Title = "Weapon & Melee" })

registerToggle(Tabs.SilentAim, "NoRecoil", {
    Title = "No Recoil (Camera Stabilizer)",
    Desc = "Counteracts vertical and horizontal weapon kickback while firing",
    Value = false,
})

registerToggle(Tabs.SilentAim, "AutoParry", {
    Title = "Auto Katana Parry",
    Desc = "Automatically deflects incoming shots when holding Katana",
    Value = false,
})

Tabs.Visuals:Section({ Title = "Stealth Player ESP Suite" })

local ESPPool = {}
local BoxPool = {}

local function cleanupPlayerVisuals(player)
    local entry = ESPPool[player]
    if entry then
        if entry.Highlight then
            pcall(function()
                entry.Highlight.Adornee = nil
                entry.Highlight:Destroy()
            end)
        end
        if entry.Billboard then
            pcall(function()
                entry.Billboard.Adornee = nil
                entry.Billboard:Destroy()
            end)
        end
        ESPPool[player] = nil
    end
    local boxEntry = BoxPool[player]
    if boxEntry then
        for _, inst in pairs(boxEntry) do
            pcall(function() inst:Destroy() end)
        end
        BoxPool[player] = nil
    end
end

Players.PlayerRemoving:Connect(cleanupPlayerVisuals)

local function syncPlayer3DESP(player)
    if player == LocalPlayer then return end
    local char = getChar(player)
    local head = char and char:FindFirstChild("Head")
    local alive = isAlive(player)
    local hide = zerohub.Toggles.ESPTeamCheck and isTeammate(player)

    local entry = ESPPool[player]
    if not char or not char.Parent or not head or not head.Parent or not alive or hide then
        if entry then
            if entry.Highlight and entry.Highlight.Parent then
                entry.Highlight.Enabled = false
                entry.Highlight.Adornee = nil
            end
            if entry.Billboard and entry.Billboard.Parent then
                entry.Billboard.Enabled = false
                entry.Billboard.Adornee = nil
            end
        end
        return
    end

    if not entry then
        entry = {}
        ESPPool[player] = entry
    end

    local col = isTeammate(player) and Color3.fromRGB(60, 160, 255) or zerohub.ESPColor

    -- Ensure ESPHolder is valid and parented in Workspace (never in a 2D ScreenGui)
    if not ESPHolder or not ESPHolder.Parent or ESPHolder.Parent:IsA("LayerCollector") or ESPHolder.Parent:IsA("ScreenGui") then
        ESPHolder = Workspace:FindFirstChild("ESPContainer") or Instance.new("Folder")
        ESPHolder.Name = "ESPContainer"
        ESPHolder.Parent = Workspace
    end

    if zerohub.Toggles.Chams then
        if not entry.Highlight or not entry.Highlight.Parent then
            local hl = Instance.new("Highlight")
            hl.Name = "ZH_HL_" .. player.Name
            hl.FillTransparency = 0.45
            hl.OutlineTransparency = 0.05
            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Parent = ESPHolder
            entry.Highlight = hl
        end
        if entry.Highlight.Adornee ~= char then
            entry.Highlight.Adornee = char
        end
        entry.Highlight.FillColor = col
        entry.Highlight.Enabled = true
    elseif entry.Highlight and entry.Highlight.Parent then
        entry.Highlight.Enabled = false
        entry.Highlight.Adornee = nil
    end

    if zerohub.Toggles.DistanceESP then
        if not entry.Billboard or not entry.Billboard.Parent then
            local bb = Instance.new("BillboardGui")
            bb.Name = "ZH_BB_" .. player.Name
            bb.Size = UDim2.new(0, 180, 0, 40)
            bb.StudsOffset = Vector3.new(0, 2.7, 0)
            bb.AlwaysOnTop = true

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Name = "NameLabel"
            nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.TextStrokeTransparency = 0.15
            nameLabel.TextSize = 13
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.Text = player.DisplayName or player.Name
            nameLabel.Parent = bb

            local infoLabel = Instance.new("TextLabel")
            infoLabel.Name = "InfoLabel"
            infoLabel.Size = UDim2.new(1, 0, 0.5, 0)
            infoLabel.Position = UDim2.new(0, 0, 0.5, 0)
            infoLabel.BackgroundTransparency = 1
            infoLabel.TextColor3 = col
            infoLabel.TextStrokeTransparency = 0.15
            infoLabel.TextSize = 11
            infoLabel.Font = Enum.Font.Gotham
            infoLabel.Text = ""
            infoLabel.Parent = bb

            bb.Parent = ESPHolder
            entry.Billboard = bb
        end

        local bb = entry.Billboard
        if bb.Adornee ~= head then
            bb.Adornee = head
        end
        bb.Enabled = true

        local myHRP = getHRP()
        local tHRP = getHRP(player)
        local hum = getHum(player)
        local infoLabel = bb:FindFirstChild("InfoLabel")

        if myHRP and myHRP.Parent and tHRP and tHRP.Parent and infoLabel and infoLabel.Parent then
            local dist = math.floor((myHRP.Position - tHRP.Position).Magnitude)
            local hp = (hum and hum.Parent and hum.Health > 0) and math.floor(hum.Health) or 100
            local tool = char:FindFirstChildOfClass("Tool")
            local weaponText = (zerohub.Toggles.WeaponESP and tool) and (" [" .. tool.Name .. "]") or ""
            infoLabel.Text = string.format("%d HP  |  %dm%s", hp, math.floor(dist * 0.28), weaponText)
            infoLabel.TextColor3 = col
        end
    elseif entry.Billboard and entry.Billboard.Parent then
        entry.Billboard.Enabled = false
        entry.Billboard.Adornee = nil
    end
end

registerToggle(Tabs.Visuals, "Chams", {
    Title = "Player Box ESP (Chams)",
    Desc = "Highlights enemy models through walls using stealth Adornee",
    Value = false,
})

registerToggle(Tabs.Visuals, "Box2D", {
    Title = "2D Box ESP",
    Desc = "Draws crisp 2D bounding boxes around players",
    Value = false,
})

registerToggle(Tabs.Visuals, "HealthBarESP", {
    Title = "Dynamic Side Health Bar",
    Desc = "Draws a vertical health bar next to each 2D box",
    Value = false,
})

registerToggle(Tabs.Visuals, "Tracers", {
    Title = "Tracers / Snaplines",
    Desc = "Draws snaplines from the bottom of your screen to enemies",
    Value = false,
})

registerToggle(Tabs.Visuals, "OOFArrows", {
    Title = "Out-Of-FOV Indicators",
    Desc = "Displays directional indicators pointing toward off-screen enemies",
    Value = false,
})

registerToggle(Tabs.Visuals, "DistanceESP", {
    Title = "Overhead Name, HP & Weapon Tag",
    Desc = "Displays name, health, distance, and held weapon above enemies",
    Value = false,
})

registerToggle(Tabs.Visuals, "WeaponESP", {
    Title = "Show Equipped Weapon",
    Desc = "Includes the enemy's equipped weapon in overhead tags",
    Value = true,
})

registerToggle(Tabs.Visuals, "ESPTeamCheck", {
    Title = "ESP Team Check",
    Desc = "Hides ESP visuals on teammates",
    Value = true,
})

registerDropdown(Tabs.Visuals, "ESPColorName", {
    Title = "ESP Accent Color",
    Values = { "Mint Green", "Crimson Red", "Electric Blue", "Neon Purple", "Pure White", "Golden Yellow" },
    Value = "Mint Green",
    Callback = function(val)
        zerohub.ESPColor = ESP_COLOR_MAP[val] or zerohub.ESPColor
    end
})

Tabs.World:Section({ Title = "Camera & Viewmodel" })

registerSlider(Tabs.World, "CustomFOV", {
    Title = "Field of View (FOV)",
    Desc = "Overrides default camera field of view",
    Step = 1,
    Value = { Min = 60, Max = 120, Default = 90 },
    Callback = function(val)
        local cam = getCam()
        if cam then cam.FieldOfView = val end
    end
})

registerToggle(Tabs.World, "LockFOV", {
    Title = "Lock Custom FOV",
    Desc = "Prevents sprinting or aiming from resetting your camera FOV",
    Value = false,
})

registerToggle(Tabs.World, "ThirdPerson", {
    Title = "Third Person Mode",
    Desc = "Unlocks third-person camera zoom distance",
    Value = false,
    Callback = function(state)
        if not state then
            pcall(function()
                LocalPlayer.CameraMaxZoomDistance = 0.5
                LocalPlayer.CameraMinZoomDistance = 0.5
                LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
            end)
        end
    end
})

registerSlider(Tabs.World, "ThirdPersonDist", {
    Title = "Third Person Distance",
    Desc = "Camera zoom distance when Third Person is enabled",
    Step = 1,
    Value = { Min = 5, Max = 30, Default = 12 },
})

registerToggle(Tabs.World, "ViewmodelOffset", {
    Title = "Enable Viewmodel Offset",
    Desc = "Shifts your first-person weapon model XYZ position",
    Value = false,
})

registerSlider(Tabs.World, "VMOffsetX", {
    Title = "Viewmodel Offset X",
    Desc = "Horizontal weapon offset",
    Step = 0.1,
    Value = { Min = -3.0, Max = 3.0, Default = 0 },
})

registerSlider(Tabs.World, "VMOffsetY", {
    Title = "Viewmodel Offset Y",
    Desc = "Vertical weapon offset",
    Step = 0.1,
    Value = { Min = -3.0, Max = 3.0, Default = 0 },
})

registerSlider(Tabs.World, "VMOffsetZ", {
    Title = "Viewmodel Offset Z",
    Desc = "Depth weapon offset",
    Step = 0.1,
    Value = { Min = -3.0, Max = 3.0, Default = 0 },
})

Tabs.World:Section({ Title = "Hit Feedback, Environment & Crosshair" })

registerToggle(Tabs.World, "Hitmarker2D", {
    Title = "Screen Hitmarkers",
    Desc = "Flashes a crisp hitmarker on target impact",
    Value = false,
})

registerToggle(Tabs.World, "HitSound", {
    Title = "Enable Custom Hit Sound",
    Desc = "Plays custom hitmarker audio when shooting enemies",
    Value = false,
})

local hitSoundNames = {}
for name in pairs(HIT_SOUNDS) do table.insert(hitSoundNames, name) end
table.sort(hitSoundNames)

registerDropdown(Tabs.World, "SelectedHitSound", {
    Title = "Select Hit Sound",
    Values = hitSoundNames,
    Value = "Rust Headshot",
})

registerSlider(Tabs.World, "HitSoundVolume", {
    Title = "Hit Sound Volume",
    Desc = "Volume level for custom hitmarker sounds",
    Step = 0.1,
    Value = { Min = 0.2, Max = 5.0, Default = 1.5 },
})

Tabs.World:Button({
    Title = "Preview Hit Sound",
    Desc = "Plays the selected hitmarker audio",
    Callback = function()
        local id = HIT_SOUNDS[zerohub.Values.SelectedHitSound] or 4764109000
        pcall(function()
            PooledHitSound.SoundId = "rbxassetid://" .. id
            PooledHitSound.Volume = zerohub.Values.HitSoundVolume
            PooledHitSound:Play()
        end)
    end
})

local origAmbient = Lighting.Ambient
local origBrightness = Lighting.Brightness
local origFogEnd = Lighting.FogEnd
local origClockTime = Lighting.ClockTime

registerToggle(Tabs.World, "Fullbright", {
    Title = "Fullbright",
    Desc = "Removes dark shadows and map fog for clear visibility",
    Value = false,
    Callback = function(state)
        if state then
            Lighting.Ambient = Color3.fromRGB(210, 210, 210)
            Lighting.Brightness = 2.2
            Lighting.FogEnd = 100000
        else
            Lighting.Ambient = origAmbient
            Lighting.Brightness = origBrightness
            Lighting.FogEnd = origFogEnd
        end
    end
})

registerToggle(Tabs.World, "CustomTime", {
    Title = "Override Time of Day",
    Desc = "Locks map sky lighting to your preferred hour",
    Value = false,
    Callback = function(state)
        if state then
            Lighting.ClockTime = zerohub.Values.TimeOfDay
        else
            Lighting.ClockTime = origClockTime
        end
    end
})

registerSlider(Tabs.World, "TimeOfDay", {
    Title = "Clock Time",
    Desc = "Hour of the day (0 = Midnight, 12 = Noon)",
    Step = 1,
    Value = { Min = 0, Max = 24, Default = 12 },
    Callback = function(val)
        if zerohub.Toggles.CustomTime then
            Lighting.ClockTime = val
        end
    end
})

registerToggle(Tabs.World, "Crosshair", {
    Title = "Custom Crosshair",
    Desc = "Displays a static center crosshair overlay",
    Value = false,
    Callback = function(state)
        CrosshairHolder.Visible = state
    end
})

Tabs.Movement:Section({ Title = "Speed & Jump" })

registerToggle(Tabs.Movement, "SpeedBoost", {
    Title = "Speed Boost (CFrame)",
    Desc = "Smoothly multiplies your horizontal movement speed",
    Value = false,
})

registerSlider(Tabs.Movement, "SpeedBoost", {
    Title = "Speed Multiplier",
    Desc = "Horizontal speed boost factor",
    Step = 0.1,
    Value = { Min = 0.2, Max = 4.5, Default = 1.4 },
})

registerToggle(Tabs.Movement, "JumpBoost", {
    Title = "Jump Boost",
    Desc = "Amplifies vertical jump height",
    Value = false,
})

registerSlider(Tabs.Movement, "JumpBoost", {
    Title = "Jump Velocity",
    Desc = "Vertical velocity applied when jumping",
    Step = 2,
    Value = { Min = 45, Max = 140, Default = 60 },
})

registerToggle(Tabs.Movement, "InfJump", {
    Title = "Infinite Jump",
    Desc = "Allows jumping repeatedly in mid-air",
    Value = false,
})

registerToggle(Tabs.Movement, "BHop", {
    Title = "Auto Bunny Hop",
    Desc = "Automatically hops on landing while holding Space",
    Value = false,
})

Tabs.Movement:Section({ Title = "Flight, Noclip & Spinbot" })

registerToggle(Tabs.Movement, "Flight", {
    Title = "Fly (Zero-Drift CFrame)",
    Desc = "Flies smoothly in any camera direction with zero vertical drift",
    Value = false,
})

registerSlider(Tabs.Movement, "FlySpeed", {
    Title = "Fly Speed",
    Desc = "Aerial flight velocity",
    Step = 5,
    Value = { Min = 20, Max = 220, Default = 75 },
})

registerToggle(Tabs.Movement, "Noclip", {
    Title = "Noclip",
    Desc = "Walk directly through arena walls and obstacles",
    Value = false,
})

registerToggle(Tabs.Movement, "Spinbot", {
    Title = "Spinbot / Anti-Aim",
    Desc = "Rapidly rotates your character root to throw off enemy aim",
    Value = false,
})

registerSlider(Tabs.Movement, "SpinSpeed", {
    Title = "Spinbot Speed",
    Desc = "Rotation degrees per frame",
    Step = 5,
    Value = { Min = 10, Max = 90, Default = 40 },
})

Tabs.Skins:Section({ Title = "Client Viewmodel Wraps" })

local wrapNames = {}
for name in pairs(WRAP_PRESETS) do table.insert(wrapNames, name) end
table.sort(wrapNames)

registerDropdown(Tabs.Skins, "SelectedWrap", {
    Title = "Select Weapon Wrap",
    Values = wrapNames,
    Value = "Galaxy",
})

local function styleModelParts(model, col, mat)
    if not model then return end
    for _, child in ipairs(model:GetChildren()) do
        if child:IsA("BasePart") then
            local n = child.Name:lower()
            if not n:find("arm") and not n:find("hand") and not n:find("glove") and not n:find("hum") then
                child.Color = col
                child.Material = mat
            end
        elseif child:IsA("Model") or child:IsA("Folder") then
            for _, sub in ipairs(child:GetChildren()) do
                if sub:IsA("BasePart") then
                    local n = sub.Name:lower()
                    if not n:find("arm") and not n:find("hand") and not n:find("glove") and not n:find("hum") then
                        sub.Color = col
                        sub.Material = mat
                    end
                end
            end
        end
    end
end

local function applyViewmodelWrap(presetName)
    local preset = WRAP_PRESETS[presetName]
    if not preset then return end
    pcall(function()
        local vmFolder = Workspace:FindFirstChild("ViewModels")
        if vmFolder then
            for _, vm in ipairs(vmFolder:GetChildren()) do
                styleModelParts(vm, preset.Color, preset.Material)
            end
        end
        local char = getChar()
        local tool = char and char:FindFirstChildOfClass("Tool")
        if tool then
            styleModelParts(tool, preset.Color, preset.Material)
        end
    end)
end

Tabs.Skins:Button({
    Title = "Apply Wrap to Equipped Weapon",
    Desc = "Applies the selected material & color wrap to your first-person weapon",
    Callback = function()
        applyViewmodelWrap(zerohub.Values.SelectedWrap)
        notify("Cosmetics", "Applied " .. zerohub.Values.SelectedWrap .. " wrap")
    end
})

registerToggle(Tabs.Skins, "AutoWrap", {
    Title = "Auto-Apply Wrap on Swap",
    Desc = "Continuously keeps your active viewmodel styled with the chosen wrap",
    Value = false,
})

registerToggle(Tabs.Skins, "RainbowVM", {
    Title = "Rainbow Viewmodel",
    Desc = "Cycles your held weapon through an RGB spectrum",
    Value = false,
})

Tabs.Configs:Section({ Title = "Configuration Manager" })

local hasFileSystem = type(isfolder) == "function" and type(makefolder) == "function" and type(writefile) == "function" and type(readfile) == "function" and type(listfiles) == "function"

local function ensureConfigDir()
    if hasFileSystem then
        pcall(function()
            if not isfolder(zerohub.ConfigFolder) then
                makefolder(zerohub.ConfigFolder)
            end
        end)
    end
end

local function getSavedConfigs()
    local list = { "default" }
    if hasFileSystem then
        pcall(function()
            ensureConfigDir()
            for _, file in ipairs(listfiles(zerohub.ConfigFolder)) do
                local name = file:match("([^/\\]+)%.json$")
                if name and name ~= "autoload" and not table.find(list, name) then
                    table.insert(list, name)
                end
            end
        end)
    end
    table.sort(list)
    return list
end

local function serializeConfig()
    return HttpService:JSONEncode({
        Toggles = zerohub.Toggles,
        Values = zerohub.Values,
    })
end

local function applyConfigData(decoded)
    if type(decoded) ~= "table" then return false end
    InitializingUI = true
    if type(decoded.Values) == "table" then
        for k, v in pairs(decoded.Values) do
            zerohub.Values[k] = v
            local sCtrl = zerohub.Controls["Slider_" .. k]
            if sCtrl then
                if sCtrl.Set then pcall(function() sCtrl:Set(v) end)
                elseif sCtrl.SetValue then pcall(function() sCtrl:SetValue(v) end) end
            end
            local dCtrl = zerohub.Controls["Dropdown_" .. k]
            if dCtrl then
                if dCtrl.Select then pcall(function() dCtrl:Select(v) end)
                elseif dCtrl.Set then pcall(function() dCtrl:Set(v) end)
                elseif dCtrl.SetValue then pcall(function() dCtrl:SetValue(v) end) end
            end
        end
    end
    if type(decoded.Toggles) == "table" then
        for k, v in pairs(decoded.Toggles) do
            zerohub.Toggles[k] = v == true
            local tCtrl = zerohub.Controls["Toggle_" .. k]
            if tCtrl then
                if tCtrl.Set then pcall(function() tCtrl:Set(v == true) end)
                elseif tCtrl.SetValue then pcall(function() tCtrl:SetValue(v == true) end) end
            end
        end
    end
    InitializingUI = false
    zerohub.AimbotKeyEnum = AIM_KEY_MAP[zerohub.Values.AimbotKey] or Enum.UserInputType.MouseButton2
    zerohub.ESPColor = ESP_COLOR_MAP[zerohub.Values.ESPColorName] or zerohub.ESPColor
    if FOVFrame and FOVFrame.Parent then
        FOVFrame.Size = UDim2.fromOffset(zerohub.Values.AimbotFOV * 2, zerohub.Values.AimbotFOV * 2)
        FOVFrame.Visible = zerohub.Toggles.ShowFOV == true
    end
    if CrosshairHolder and CrosshairHolder.Parent then
        CrosshairHolder.Visible = zerohub.Toggles.Crosshair == true
    end
    pcall(function()
        if zerohub.Toggles.Fullbright then
            Lighting.Ambient = Color3.fromRGB(210, 210, 210)
            Lighting.Brightness = 2.2
            Lighting.FogEnd = 100000
        end
        if zerohub.Toggles.CustomTime then
            Lighting.ClockTime = zerohub.Values.TimeOfDay
        end
        if zerohub.Toggles.LockFOV then
            local cam = getCam()
            if cam and cam.Parent then cam.FieldOfView = zerohub.Values.CustomFOV end
        end
    end)
    pcall(updateEnemyHitboxes)
    return true
end

Tabs.Configs:Input({
    Title = "Config Name",
    Placeholder = "Enter config name...",
    Value = "default",
    Callback = function(val)
        if val and val ~= "" then
            zerohub.ConfigNameInput = val:gsub("[^%w_%-]", "")
        end
    end
})

local initialConfigs = getSavedConfigs()
local initialSelected = (table.find(initialConfigs, "basic") and "basic") or "default"
zerohub.SelectedConfig = initialSelected

local ConfigDropdown = Tabs.Configs:Dropdown({
    Title = "Saved Configs",
    Values = initialConfigs,
    Value = initialSelected,
    Callback = function(val)
        zerohub.SelectedConfig = val
    end
})

local function refreshConfigDropdown()
    pcall(function()
        local list = getSavedConfigs()
        if ConfigDropdown and ConfigDropdown.Refresh then
            ConfigDropdown:Refresh(list)
            if zerohub.SelectedConfig then
                if ConfigDropdown.Select then
                    pcall(function() ConfigDropdown:Select(zerohub.SelectedConfig) end)
                elseif ConfigDropdown.Set then
                    pcall(function() ConfigDropdown:Set(zerohub.SelectedConfig) end)
                end
            end
        end
    end)
end

Tabs.Configs:Button({
    Title = "Save / Overwrite Config",
    Desc = "Saves all current toggles and sliders to the named or selected config",
    Callback = function()
        local name = (zerohub.ConfigNameInput ~= "" and zerohub.ConfigNameInput) or zerohub.SelectedConfig or "default"
        local ok, json = pcall(serializeConfig)
        if not ok then
            notify("Configs", "Failed to encode config")
            return
        end
        if hasFileSystem then
            pcall(function()
                ensureConfigDir()
                writefile(zerohub.ConfigFolder .. "/" .. name .. ".json", json)
            end)
            zerohub.SelectedConfig = name
            refreshConfigDropdown()
            notify("Configs", "Saved config: " .. name)
        else
            local clip = setclipboard or toclipboard
            if clip then
                pcall(clip, json)
                notify("Configs", "Copied config JSON to clipboard")
            end
        end
    end
})

Tabs.Configs:Button({
    Title = "Load Selected Config",
    Desc = "Loads and applies settings from the selected config",
    Callback = function()
        local name = zerohub.SelectedConfig or "default"
        local path = zerohub.ConfigFolder .. "/" .. name .. ".json"
        if hasFileSystem and isfile(path) then
            local ok, raw = pcall(readfile, path)
            if ok and raw then
                local okDec, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
                if okDec and applyConfigData(decoded) then
                    notify("Configs", "Loaded config: " .. name)
                    return
                end
            end
        end
        notify("Configs", "Config file not found: " .. name)
    end
})

Tabs.Configs:Button({
    Title = "Delete Selected Config",
    Desc = "Removes the selected config file from disk",
    Callback = function()
        local name = zerohub.SelectedConfig
        local path = zerohub.ConfigFolder .. "/" .. tostring(name) .. ".json"
        if hasFileSystem and type(delfile) == "function" and isfile(path) then
            pcall(delfile, path)
            zerohub.SelectedConfig = "default"
            refreshConfigDropdown()
            notify("Configs", "Deleted config: " .. tostring(name))
        else
            notify("Configs", "Cannot delete file")
        end
    end
})

Tabs.Configs:Button({
    Title = "Refresh Saved Configs",
    Desc = "Rescans the config folder for newly added files",
    Callback = function()
        refreshConfigDropdown()
        notify("Configs", "Config list refreshed")
    end
})

Tabs.Configs:Section({ Title = "Auto-Load & Clipboard Share" })

Tabs.Configs:Button({
    Title = "Set Selected as Auto-Load",
    Desc = "Automatically loads the selected config when zerohub starts",
    Callback = function()
        if hasFileSystem then
            pcall(function()
                ensureConfigDir()
                writefile(zerohub.ConfigFolder .. "/autoload.txt", zerohub.SelectedConfig or "default")
            end)
            notify("Configs", "Set auto-load to: " .. (zerohub.SelectedConfig or "default"))
        else
            notify("Configs", "Filesystem not supported on this executor")
        end
    end
})

Tabs.Configs:Button({
    Title = "Clear Auto-Load",
    Desc = "Disables automatic config loading on startup",
    Callback = function()
        local path = zerohub.ConfigFolder .. "/autoload.txt"
        if hasFileSystem and type(delfile) == "function" and isfile(path) then
            pcall(delfile, path)
        end
        notify("Configs", "Cleared auto-load config")
    end
})

Tabs.Configs:Button({
    Title = "Export Config to Clipboard",
    Desc = "Copies your current settings as a shareable JSON string",
    Callback = function()
        local clip = setclipboard or toclipboard or set_clipboard
        if clip then
            local ok, json = pcall(serializeConfig)
            if ok then
                pcall(clip, json)
                notify("Configs", "Exported config JSON to clipboard")
            end
        else
            notify("Configs", "Clipboard not supported")
        end
    end
})

local importJsonString = ""
Tabs.Configs:Input({
    Title = "Import Config JSON",
    Placeholder = "Paste exported JSON here...",
    Value = "",
    Callback = function(val)
        importJsonString = val
    end
})

Tabs.Configs:Button({
    Title = "Load Imported JSON",
    Desc = "Applies the pasted JSON config string",
    Callback = function()
        if importJsonString == "" then
            notify("Configs", "Paste a valid JSON string first")
            return
        end
        local ok, decoded = pcall(function() return HttpService:JSONDecode(importJsonString) end)
        if ok and applyConfigData(decoded) then
            notify("Configs", "Imported config successfully")
        else
            notify("Configs", "Invalid config JSON")
        end
    end
})

Tabs.Settings:Section({ Title = "Appearance" })

Tabs.Settings:Dropdown({
    Title = "Interface Theme",
    Values = { "Default", "Rose", "Ember", "Amethyst", "Cobalt", "Frost" },
    Value = "Default",
    Callback = function(theme)
        if InitializingUI then return end
        pcall(function()
            if Window and Window.ChangeTheme then
                Window:ChangeTheme(theme)
                notify("Theme", "Changed theme to " .. theme)
            end
        end)
    end
})

Tabs.Settings:Toggle({
    Title = "Acrylic Blur",
    Desc = "Toggles background glass blur (can cause UI lag when enabled)",
    Value = false,
    Callback = function(state)
        if InitializingUI then return end
        -- Background blur is handled natively by Rayfield Gen2
    end
})

Tabs.Settings:Section({ Title = "Script Session" })

Tabs.Settings:Button({
    Title = "Unload zerohub",
    Desc = "Cleans up all connections, overlays, and closes the interface",
    Callback = function()
        for k in pairs(zerohub.Toggles) do
            zerohub.Toggles[k] = false
        end
        for _, conn in pairs(zerohub.Connections) do
            pcall(function() conn:Disconnect() end)
        end
        pcall(updateEnemyHitboxes)
        for p in pairs(ESPPool) do
            cleanupPlayerVisuals(p)
        end
        if ESPHolder and ESPHolder.Parent then
            pcall(function() ESPHolder:Destroy() end)
        end
        pcall(function() OverlayGui:Destroy() end)
        pcall(function()
            if Window then
                if Window.Unload then
                    Window:Unload()
                elseif Window.Destroy then
                    Window:Destroy()
                end
            end
        end)
        notify("zerohub.cc", "Unloaded successfully")
    end
})

InitializingUI = false

pcall(function()
    Tabs.Dashboard:Select()
end)

if hasFileSystem then
    task.spawn(function()
        pcall(function()
            local autoPath = zerohub.ConfigFolder .. "/autoload.txt"
            if isfile(autoPath) then
                local autoName = readfile(autoPath):gsub("%s+", "")
                local cfgPath = zerohub.ConfigFolder .. "/" .. autoName .. ".json"
                if autoName ~= "" and isfile(cfgPath) then
                    -- Guard: Wait for game services, camera controller, and local character
                    -- to finish initializing before applying auto-loaded flags
                    if not game:IsLoaded() then
                        game.Loaded:Wait()
                    end
                    local cam = getCam()
                    local camTimeout = os.clock() + 10
                    while (not cam or not cam.Parent or cam.ViewportSize.X <= 1 or cam.ViewportSize.Y <= 1) and os.clock() < camTimeout do
                        task.wait(0.1)
                        cam = getCam()
                    end
                    local charTimeout = os.clock() + 5
                    while not (LocalPlayer and LocalPlayer.Character and LocalPlayer.Character.Parent and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) and os.clock() < charTimeout do
                        task.wait(0.1)
                    end
                    -- Brief breather for camera scripts and game scene graph to settle
                    task.wait(0.25)

                    local decoded = HttpService:JSONDecode(readfile(cfgPath))
                    if applyConfigData(decoded) then
                        zerohub.SelectedConfig = autoName
                        notify("Configs", "Auto-loaded config: " .. autoName)
                    end
                end
            end
        end)
    end)
end

zerohub.Connections.CameraWatch = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    for _, entry in pairs(ESPPool) do
        if entry.Highlight and entry.Highlight.Parent then entry.Highlight.Adornee = nil end
        if entry.Billboard and entry.Billboard.Parent then entry.Billboard.Adornee = nil end
    end
end)

zerohub.Connections.LocalCharWatch = LocalPlayer.CharacterAdded:Connect(function()
    for _, entry in pairs(ESPPool) do
        if entry.Highlight and entry.Highlight.Parent then entry.Highlight.Adornee = nil end
        if entry.Billboard and entry.Billboard.Parent then entry.Billboard.Adornee = nil end
    end
end)

local function getOrCreateBoxEntry(player)
    local entry = BoxPool[player]
    if entry then return entry end

    if not BoxHolder or not BoxHolder.Parent then
        BoxHolder = Instance.new("Folder")
        BoxHolder.Name = "BoxContainer"
        BoxHolder.Parent = OverlayGui
    end

    local box = Instance.new("Frame")
    box.BackgroundTransparency = 1
    box.Visible = false
    box.Parent = BoxHolder

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.5
    stroke.Color = zerohub.ESPColor
    stroke.Parent = box

    local hpBg = Instance.new("Frame")
    hpBg.BorderSizePixel = 0
    hpBg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    hpBg.Visible = false
    hpBg.Parent = BoxHolder

    local hpFill = Instance.new("Frame")
    hpFill.BorderSizePixel = 0
    hpFill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    hpFill.AnchorPoint = Vector2.new(0, 1)
    hpFill.Position = UDim2.fromScale(0, 1)
    hpFill.Size = UDim2.fromScale(1, 1)
    hpFill.Parent = hpBg

    local tracer = Instance.new("Frame")
    tracer.BorderSizePixel = 0
    tracer.AnchorPoint = Vector2.new(0.5, 0.5)
    tracer.Visible = false
    tracer.Parent = BoxHolder

    local oof = Instance.new("Frame")
    oof.BorderSizePixel = 0
    oof.AnchorPoint = Vector2.new(0.5, 0.5)
    oof.Size = UDim2.fromOffset(9, 9)
    oof.Visible = false
    oof.Parent = BoxHolder
    local oofCorner = Instance.new("UICorner")
    oofCorner.CornerRadius = UDim.new(1, 0)
    oofCorner.Parent = oof

    entry = {
        Box = box,
        Stroke = stroke,
        HPBg = hpBg,
        HPFill = hpFill,
        Tracer = tracer,
        OOF = oof,
    }
    BoxPool[player] = entry
    return entry
end

local lastTriggerTime = 0
local lastRageTime = 0
local lastSlowTick = tick()
local lastLookVec = Vector3.new(0, 0, -1)
local rainbowHue = 0

zerohub.Connections.ShotHook = UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if zerohub.Toggles.SilentAim then
            safeRun("SILENT_AIM_SHOT", function()
                local cam = getCam()
                if not cam or not cam.Parent then return end
                if math.random(1, 100) <= zerohub.Values.SilentHitChance then
                    local pref = (math.random(1, 100) <= zerohub.Values.SilentHeadshotChance) and "Head" or zerohub.Values.SilentAimPart
                    local _, targetPart = getClosestTarget(zerohub.Values.AimbotFOV, pref, not zerohub.Toggles.Wallbang)
                    if targetPart and targetPart.Parent and cam and cam.Parent then
                        local diff = targetPart.Position - cam.CFrame.Position
                        if diff.Magnitude > 0.1 then
                            local newCF = CFrame.new(cam.CFrame.Position, targetPart.Position)
                            if newCF.X == newCF.X and newCF.Y == newCF.Y and newCF.Z == newCF.Z then
                                cam.CFrame = newCF
                                playHitFeedback(targetPart.Position)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

zerohub.Connections.MainRender = RunService.RenderStepped:Connect(function(dt)
    zerohub.FrameCount += 1
    local cam = getCam()
    if not cam or not cam.Parent then return end

    safeRun("RENDER_HUD", function()
        local refPos = getAimReferencePoint()
        if zerohub.Toggles.ShowFOV and FOVFrame and FOVFrame.Parent then
            FOVFrame.Position = UDim2.fromOffset(refPos.X, refPos.Y)
        end
        if zerohub.Toggles.Crosshair and CrosshairHolder and CrosshairHolder.Parent then
            CrosshairHolder.Position = UDim2.fromOffset(refPos.X, refPos.Y)
        end
        if zerohub.Toggles.LockFOV and cam and cam.Parent then
            cam.FieldOfView = zerohub.Values.CustomFOV
        end
        if zerohub.Toggles.ThirdPerson and LocalPlayer then
            pcall(function()
                LocalPlayer.CameraMode = Enum.CameraMode.Classic
                local dist = zerohub.Values.ThirdPersonDist
                if LocalPlayer.CameraMaxZoomDistance < dist then
                    LocalPlayer.CameraMaxZoomDistance = dist
                    LocalPlayer.CameraMinZoomDistance = dist
                else
                    LocalPlayer.CameraMinZoomDistance = dist
                    LocalPlayer.CameraMaxZoomDistance = dist
                end
            end)
        end
    end)

    if zerohub.Toggles.ViewmodelOffset then
        safeRun("RENDER_VM_OFFSET", function()
            local vmFolder = Workspace:FindFirstChild("ViewModels")
            if vmFolder and vmFolder.Parent then
                local offsetCF = CFrame.new(zerohub.Values.VMOffsetX, zerohub.Values.VMOffsetY, zerohub.Values.VMOffsetZ)
                for _, vm in ipairs(vmFolder:GetChildren()) do
                    if vm:IsA("Model") and vm.Parent and vm.PrimaryPart and vm.PrimaryPart.Parent then
                        vm.PrimaryPart.CFrame = vm.PrimaryPart.CFrame * offsetCF
                    end
                end
            end
        end)
    end

    if zerohub.Toggles.NoRecoil then
        safeRun("RENDER_NORECOIL", function()
            if not cam or not cam.Parent then return end
            if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                local curCF = cam.CFrame
                local dy = curCF.LookVector.Y - lastLookVec.Y
                if dy > 0.004 and dy < 0.09 then
                    cam.CFrame = curCF * CFrame.Angles(-dy * 0.72, 0, 0)
                end
            end
            if cam and cam.Parent then
                lastLookVec = cam.CFrame.LookVector
            end
        end)
    end

    if zerohub.Toggles.Aimbot and (zerohub.Toggles.AimbotAlwaysOn or isAimKeyDown()) then
        safeRun("RENDER_AIMBOT", function()
            if not cam or not cam.Parent then return end
            local refPos = getAimReferencePoint()
            local _, targetPart = getClosestTarget(zerohub.Values.AimbotFOV, zerohub.Values.AimbotPart, zerohub.Toggles.WallCheck)
            if targetPart and targetPart.Parent and cam and cam.Parent then
                local aimPos = targetPart.Position
                if zerohub.Toggles.AimPrediction then
                    aimPos = aimPos + (targetPart.AssemblyLinearVelocity * zerohub.Values.PredictionAmount)
                end
                local smooth = math.clamp(zerohub.Values.AimbotSmoothness, 0.05, 0.95)
                local alpha = math.clamp(1 - math.pow(smooth, dt * 60), 0.05, 1)

                if zerohub.Values.AimbotMethod == "Mouse (mousemoverel)" and type(mousemoverel) == "function" then
                    local sp, onScreen = cam:WorldToViewportPoint(aimPos)
                    if onScreen and sp.Z > 0 then
                        pcall(mousemoverel, (sp.X - refPos.X) * alpha, (sp.Y - refPos.Y) * alpha)
                    end
                else
                    local diff = aimPos - cam.CFrame.Position
                    if diff.Magnitude > 0.1 then
                        local newCF = CFrame.new(cam.CFrame.Position, aimPos)
                        if newCF.X == newCF.X and newCF.Y == newCF.Y and newCF.Z == newCF.Z then
                            cam.CFrame = cam.CFrame:Lerp(newCF, alpha)
                        end
                    end
                end
            end
        end)
    end

    if zerohub.Toggles.Ragebot and (tick() - lastRageTime) >= 0.08 then
        safeRun("RENDER_RAGEBOT", function()
            if not cam or not cam.Parent then return end
            local _, targetPart = getClosestTarget(zerohub.Values.AimbotFOV, "Head", true)
            if targetPart and targetPart.Parent and cam and cam.Parent then
                lastRageTime = tick()
                local diff = targetPart.Position - cam.CFrame.Position
                if diff.Magnitude > 0.1 then
                    local newCF = CFrame.new(cam.CFrame.Position, targetPart.Position)
                    if newCF.X == newCF.X and newCF.Y == newCF.Y and newCF.Z == newCF.Z then
                        cam.CFrame = newCF
                    end
                end
                triggerPrimaryAction()
                playHitFeedback(targetPart.Position)
            end
        end)
    end

    if zerohub.Toggles.Triggerbot and (tick() - lastTriggerTime) >= zerohub.Values.TriggerDelay then
        safeRun("RENDER_TRIGGERBOT", function()
            if not cam or not cam.Parent then return end
            local myChar = getChar()
            if myChar and myChar.Parent then
                local refPos = getAimReferencePoint()
                RayParams.FilterDescendantsInstances = {myChar}
                local ray = cam:ViewportPointToRay(refPos.X, refPos.Y)
                local hit = Workspace:Raycast(ray.Origin, ray.Direction * 850, RayParams)
                if hit and hit.Instance and hit.Instance.Parent then
                    local model = hit.Instance:FindFirstAncestorOfClass("Model")
                    local plr = model and Players:GetPlayerFromCharacter(model)
                    if plr and plr ~= LocalPlayer and not isTeammate(plr) and isAlive(plr) then
                        lastTriggerTime = tick()
                        triggerPrimaryAction()
                        playHitFeedback(hit.Position)
                    end
                end
            end
        end)
    end

    if zerohub.Toggles.RainbowVM then
        safeRun("RENDER_RAINBOW_VM", function()
            rainbowHue = (rainbowHue + dt * 0.35) % 1
            local col = Color3.fromHSV(rainbowHue, 1, 1)
            local vmFolder = Workspace:FindFirstChild("ViewModels")
            if vmFolder and vmFolder.Parent then
                for _, vm in ipairs(vmFolder:GetChildren()) do
                    styleModelParts(vm, col, Enum.Material.Neon)
                end
            end
        end)
    end

    safeRun("RENDER_ESP_2D", function()
        if not cam or not cam.Parent then return end
        local vp = cam.ViewportSize
        if vp.X <= 1 or vp.Y <= 1 then return end
        local want2D = zerohub.Toggles.Box2D or zerohub.Toggles.HealthBarESP or zerohub.Toggles.Tracers or zerohub.Toggles.OOFArrows
        local center = vp / 2

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                if want2D then
                    local entry = getOrCreateBoxEntry(p)
                    local valid = isAlive(p) and not (zerohub.Toggles.ESPTeamCheck and isTeammate(p))
                    if valid then
                        local char = getChar(p)
                        local hrp = getHRP(p)
                        local head = char and char:FindFirstChild("Head")
                        local hum = getHum(p)
                        if char and char.Parent and hrp and hrp.Parent and head and head.Parent and cam and cam.Parent then
                            local rootPos, onScreen = cam:WorldToViewportPoint(hrp.Position)
                            local topPos = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 0.65, 0))
                            local botPos = cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3.0, 0))
                            local col = isTeammate(p) and Color3.fromRGB(60, 160, 255) or zerohub.ESPColor

                            if onScreen and rootPos.Z > 0 and topPos.Z > 0 and botPos.Z > 0 then
                                if entry.OOF and entry.OOF.Parent then entry.OOF.Visible = false end
                                local h = math.clamp(math.abs(botPos.Y - topPos.Y), 10, 2000)
                                local w = math.clamp(h * 0.6, 6, 1200)
                                local bx = rootPos.X - w / 2
                                local by = topPos.Y

                                if zerohub.Toggles.Box2D and entry.Box and entry.Box.Parent then
                                    entry.Box.Visible = true
                                    entry.Box.Position = UDim2.fromOffset(bx, by)
                                    entry.Box.Size = UDim2.fromOffset(w, h)
                                    if entry.Stroke and entry.Stroke.Parent then
                                        entry.Stroke.Color = col
                                    end
                                elseif entry.Box and entry.Box.Parent then
                                    entry.Box.Visible = false
                                end

                                if zerohub.Toggles.HealthBarESP and hum and hum.Parent and entry.HPBg and entry.HPBg.Parent then
                                    local maxHp = (hum.MaxHealth > 0 and hum.MaxHealth) or 100
                                    local pct = math.clamp(hum.Health / maxHp, 0, 1)
                                    entry.HPBg.Visible = true
                                    entry.HPBg.Position = UDim2.fromOffset(bx - 5, by)
                                    entry.HPBg.Size = UDim2.fromOffset(3, h)
                                    if entry.HPFill and entry.HPFill.Parent then
                                        entry.HPFill.Size = UDim2.fromScale(1, pct)
                                        entry.HPFill.BackgroundColor3 = Color3.fromHSV(pct * 0.33, 1, 1)
                                    end
                                elseif entry.HPBg and entry.HPBg.Parent then
                                    entry.HPBg.Visible = false
                                end

                                if zerohub.Toggles.Tracers and entry.Tracer and entry.Tracer.Parent then
                                    local from = Vector2.new(center.X, vp.Y)
                                    local to = Vector2.new(rootPos.X, botPos.Y)
                                    local delta = to - from
                                    local mid = (from + to) / 2
                                    entry.Tracer.Visible = true
                                    entry.Tracer.BackgroundColor3 = col
                                    entry.Tracer.Position = UDim2.fromOffset(mid.X, mid.Y)
                                    entry.Tracer.Size = UDim2.fromOffset(delta.Magnitude, 1.3)
                                    entry.Tracer.Rotation = math.deg(math.atan2(delta.Y, delta.X))
                                elseif entry.Tracer and entry.Tracer.Parent then
                                    entry.Tracer.Visible = false
                                end
                            else
                                if entry.Box and entry.Box.Parent then entry.Box.Visible = false end
                                if entry.HPBg and entry.HPBg.Parent then entry.HPBg.Visible = false end
                                if entry.Tracer and entry.Tracer.Parent then entry.Tracer.Visible = false end
                                if zerohub.Toggles.OOFArrows and entry.OOF and entry.OOF.Parent and cam and cam.Parent then
                                    local rel = cam.CFrame:PointToObjectSpace(hrp.Position)
                                    local angle = math.atan2(-rel.Y, rel.X)
                                    local pos = center + Vector2.new(math.cos(angle) * 170, math.sin(angle) * 170)
                                    entry.OOF.Visible = true
                                    entry.OOF.BackgroundColor3 = col
                                    entry.OOF.Position = UDim2.fromOffset(pos.X, pos.Y)
                                elseif entry.OOF and entry.OOF.Parent then
                                    entry.OOF.Visible = false
                                end
                            end
                        else
                            if entry.Box and entry.Box.Parent then entry.Box.Visible = false end
                            if entry.HPBg and entry.HPBg.Parent then entry.HPBg.Visible = false end
                            if entry.Tracer and entry.Tracer.Parent then entry.Tracer.Visible = false end
                            if entry.OOF and entry.OOF.Parent then entry.OOF.Visible = false end
                        end
                    else
                        if entry.Box and entry.Box.Parent then entry.Box.Visible = false end
                        if entry.HPBg and entry.HPBg.Parent then entry.HPBg.Visible = false end
                        if entry.Tracer and entry.Tracer.Parent then entry.Tracer.Visible = false end
                        if entry.OOF and entry.OOF.Parent then entry.OOF.Visible = false end
                    end
                elseif BoxPool[p] then
                    local entry = BoxPool[p]
                    if entry.Box and entry.Box.Parent then entry.Box.Visible = false end
                    if entry.HPBg and entry.HPBg.Parent then entry.HPBg.Visible = false end
                    if entry.Tracer and entry.Tracer.Parent then entry.Tracer.Visible = false end
                    if entry.OOF and entry.OOF.Parent then entry.OOF.Visible = false end
                end
            end
        end
    end)

    if (tick() - lastSlowTick) >= 0.4 then
        lastSlowTick = tick()
        safeRun("SLOW_TICK_ESP3D", function()
            if zerohub.Toggles.Chams or zerohub.Toggles.DistanceESP then
                for _, p in ipairs(Players:GetPlayers()) do
                    syncPlayer3DESP(p)
                end
            else
                for _, entry in pairs(ESPPool) do
                    if entry.Highlight and entry.Highlight.Parent then
                        entry.Highlight.Enabled = false
                        entry.Highlight.Adornee = nil
                    end
                    if entry.Billboard and entry.Billboard.Parent then
                        entry.Billboard.Enabled = false
                        entry.Billboard.Adornee = nil
                    end
                end
            end
            if zerohub.Toggles.HitboxExpander then
                updateEnemyHitboxes()
            end
            if zerohub.Toggles.AutoWrap and not zerohub.Toggles.RainbowVM then
                applyViewmodelWrap(zerohub.Values.SelectedWrap)
            end
        end)
    end
end)

zerohub.Connections.MainHeartbeat = RunService.Heartbeat:Connect(function(dt)
    safeRun("HEARTBEAT_MOVEMENT", function()
        local cam = getCam()
        local hrp = getHRP()
        local hum = getHum()
        local char = getChar()
        if not cam or not cam.Parent or not hrp or not hrp.Parent or not hum or not hum.Parent or not char or not char.Parent then
            return
        end

        if zerohub.Toggles.Flight then
            local dir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0, 1, 0) end
            if dir.Magnitude > 0 and hrp and hrp.Parent then
                hrp.CFrame = hrp.CFrame + (dir.Unit * zerohub.Values.FlySpeed * dt)
            end
            if hrp and hrp.Parent then
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
        elseif zerohub.Toggles.SpeedBoost and hum and hum.Parent and hrp and hrp.Parent and hum.MoveDirection.Magnitude > 0 then
            hrp.CFrame = hrp.CFrame + (hum.MoveDirection * zerohub.Values.SpeedBoost * dt * 24)
        end

        if zerohub.Toggles.Spinbot and hrp and hrp.Parent then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(zerohub.Values.SpinSpeed), 0)
        end

        if zerohub.Toggles.BHop and hum and hum.Parent and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            if hum.FloorMaterial ~= Enum.Material.Air then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end

        if zerohub.Toggles.AutoParry and hrp and hrp.Parent then
            for _, enemy in ipairs(Players:GetPlayers()) do
                if enemy ~= LocalPlayer and not isTeammate(enemy) and isAlive(enemy) then
                    local eHRP = getHRP(enemy)
                    if eHRP and eHRP.Parent and hrp and hrp.Parent then
                        local toEnemy = hrp.Position - eHRP.Position
                        local dist = toEnemy.Magnitude
                        if dist > 0.05 and dist < 65 then
                            local lookToMe = toEnemy.Unit:Dot(eHRP.CFrame.LookVector)
                            if lookToMe > 0.92 then
                                triggerSecondaryAction()
                                break
                            end
                        end
                    end
                end
            end
        end
    end)
end)

zerohub.Connections.MainStepped = RunService.Stepped:Connect(function()
    if zerohub.Toggles.Noclip then
        safeRun("STEPPED_NOCLIP", function()
            local char = getChar()
            if char and char.Parent then
                for _, part in ipairs(char:GetChildren()) do
                    if part:IsA("BasePart") and part.Parent and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
end)

zerohub.Connections.MainJump = UserInputService.JumpRequest:Connect(function()
    if zerohub.Toggles.InfJump or zerohub.Toggles.JumpBoost then
        safeRun("JUMP_REQUEST", function()
            local hrp = getHRP()
            local hum = getHum()
            if not hrp or not hrp.Parent or not hum or not hum.Parent then return end
            if zerohub.Toggles.InfJump then
                local v = hrp.AssemblyLinearVelocity
                hrp.AssemblyLinearVelocity = Vector3.new(v.X, zerohub.Values.JumpBoost, v.Z)
            elseif zerohub.Toggles.JumpBoost and hum.FloorMaterial ~= Enum.Material.Air then
                local v = hrp.AssemblyLinearVelocity
                hrp.AssemblyLinearVelocity = Vector3.new(v.X, zerohub.Values.JumpBoost, v.Z)
            end
        end)
    end
end)

logEvent("BOOT", "zerohub v%s initialization complete!", zerohub.Version)
notify("zerohub.cc", "Rivals edition loaded successfully", 3)