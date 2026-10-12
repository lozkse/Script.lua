---- leaked by .gg/source

if _G.luckbroomRunning then
    warn("[luckbroom] Instancia previa detectada. Se recomienda rejoin si hay comportamiento errático.")
end
_G.luckbroomRunning = false
_G.__luckbroomMainOriginalPos = nil

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local HS = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LP = Players.LocalPlayer
if not LP then
    local _lpConn
    _lpConn = Players.PlayerAdded:Connect(function(p) LP = p end)
    local _t0 = tick()
    while not LP and tick() - _t0 < 15 do task.wait(0.1) end
    if _lpConn then _lpConn:Disconnect() end
end
if not LP then
    warn("[luckbroom] LocalPlayer no disponible en 15s. Abortando.")
    return
end

local pgui = LP:WaitForChild("PlayerGui", 20)
if not pgui then
    warn("[luckbroom] PlayerGui no cargó en 20s. Abortando.")
    return
end

local camera = Workspace.CurrentCamera

local SoundService = game:GetService("SoundService")

local luckbroom_REDRUM_URL = "https://file.garden/algLafWA1jk8WMfK/redrum_spotdown.org%202.mp3"
local luckbroom_REDRUM_FILE = "luckbroom_redrum.mp3"
local luckbroomRedrumAsset = nil
local luckbroomFullRedrumSound = nil
local luckbroomMusicRequest = 0
local luckbroomMusicRefreshers = {}

local function getluckbroomRedrumAsset()
    if luckbroomRedrumAsset then return luckbroomRedrumAsset end

    local assetLoader = getcustomasset or getsynasset
    if type(assetLoader) ~= "function" or type(writefile) ~= "function" then
        return nil, "custom asset functions unavailable"
    end

    local exists = false
    if type(isfile) == "function" then
        local okExists, result = pcall(isfile, luckbroom_REDRUM_FILE)
        exists = okExists and result == true
    end

    if not exists then
        local okDownload, data = pcall(function()
            return game:HttpGet(luckbroom_REDRUM_URL)
        end)
        if not okDownload or type(data) ~= "string" or #data < 256 then
            return nil, "could not download redrum"
        end

        local okWrite = pcall(writefile, luckbroom_REDRUM_FILE, data)
        if not okWrite then
            return nil, "could not save redrum"
        end
    end

    local okAsset, asset = pcall(assetLoader, luckbroom_REDRUM_FILE)
    if not okAsset or type(asset) ~= "string" or asset == "" then
        return nil, "could not create redrum asset"
    end

    luckbroomRedrumAsset = asset
    return asset
end

local function makeluckbroomRedrumSound(startAt, name)
    local asset, err = getluckbroomRedrumAsset()
    if not asset then
        warn("[luckbroom Music] " .. tostring(err))
        return nil
    end

    local sound = Instance.new("Sound")
    sound.Name = name or "luckbroomRedrum"
    sound.SoundId = asset
    sound.Volume = 1
    sound.Looped = false
    sound.Parent = SoundService

    local startPosition = math.max(0, tonumber(startAt) or 0)
    pcall(function() sound.TimePosition = startPosition end)
    pcall(function() sound:Play() end)

    task.spawn(function()
        local startedWaiting = tick()
        while sound.Parent and not sound.IsLoaded and tick() - startedWaiting < 8 do
            task.wait(0.05)
        end
        if sound.Parent then
            pcall(function()
                sound.TimePosition = startPosition
                if not sound.Playing then sound:Play() end
            end)
        end
    end)

    return sound
end

local function stopluckbroomFullRedrum()
    luckbroomMusicRequest = luckbroomMusicRequest + 1
    if luckbroomFullRedrumSound then
        pcall(function() luckbroomFullRedrumSound:Stop() end)
        pcall(function() luckbroomFullRedrumSound:Destroy() end)
        luckbroomFullRedrumSound = nil
    end
end


_G.luckbroomRunning = true
_G.luckbroomSession = (_G.luckbroomSession or 0) + 1
local _mySession = _G.luckbroomSession

do
    local screen, connections, closed = nil, {}, false
    local introSound = nil
    local started, leaving = tick(), nil
    local introTotalDuration = 10
    local exitFadeDuration = 0.36
    local duration = introTotalDuration - exitFadeDuration
    local function connect(signal, callback)
        local c = signal:Connect(callback)
        connections[#connections + 1] = c
        return c
    end
    local function clean()
        closed = true
        for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
        if screen then pcall(function() screen:Destroy() end) end
    end
    local ok, err = pcall(function()
        local core
        pcall(function() core = game:GetService("CoreGui") end)
        for _, parent in ipairs(core and {core, pgui} or {pgui}) do
            local previous = parent:FindFirstChild("luckbroomHalloweenIntro")
            if previous then previous:Destroy() end
            for _, name in ipairs({"luckbroom", "luckbroomMobilePanel", "luckbroomSpeedIndicator"}) do
                local old = parent:FindFirstChild(name)
                if old then old.Enabled = false end
            end
        end
        local function make(class, parent, properties)
            local object = Instance.new(class)
            if object:IsA("GuiObject") then object.BorderSizePixel = 0 end
            for key, value in pairs(properties or {}) do object[key] = value end
            object.Parent = parent
            return object
        end
        local function round(object, radius)
            make("UICorner", object, {CornerRadius = UDim.new(0, radius)})
            return object
        end
        local function text(parent, name, value, x, y, w, h, size, color, z)
            return make("TextLabel", parent, {Name = name, Text = value,
                Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
                BackgroundTransparency = 1, TextColor3 = color, Font = Enum.Font.GothamBold,
                TextSize = size, ZIndex = z or 6})
        end
        local amber, ivory = Color3.fromRGB(255, 166, 77), Color3.fromRGB(250, 241, 224)
        screen = make("ScreenGui", nil, {Name = "luckbroomHalloweenIntro", ResetOnSpawn = false,
            IgnoreGuiInset = true, DisplayOrder = 10000, ZIndexBehavior = Enum.ZIndexBehavior.Sibling})
        pcall(function() if syn and syn.protect_gui then syn.protect_gui(screen) end end)
        if core then pcall(function() screen.Parent = core end) end
        if not screen.Parent then screen.Parent = pgui end
        connect(screen.Destroying, function() closed = true end)
        do
            local oldIntro = SoundService:FindFirstChild("luckbroomRedrumIntro")
            if oldIntro then
                pcall(function() oldIntro:Stop() end)
                pcall(function() oldIntro:Destroy() end)
            end
        end

        introSound = makeluckbroomRedrumSound(40, "luckbroomRedrumIntro")
        task.spawn(function()
            local thisSound = introSound
            if not thisSound then return end

            local loadDeadline = tick() + 15
            while thisSound.Parent and not thisSound.IsLoaded and tick() < loadDeadline do
                task.wait(0.05)
            end
            if not thisSound.Parent then return end

            pcall(function()
                thisSound.TimePosition = 40
                thisSound:Play()
            end)

            local playDeadline = tick() + 5
            while thisSound.Parent and (not thisSound.Playing or thisSound.TimePosition < 39.9) and tick() < playDeadline do
                pcall(function()
                    if thisSound.TimePosition < 39.9 then
                        thisSound.TimePosition = 40
                    end
                    if not thisSound.Playing then
                        thisSound:Play()
                    end
                end)
                task.wait(0.03)
            end

            while thisSound.Parent and thisSound.TimePosition < 50 do
                task.wait(0.03)
            end

            if thisSound.Parent then
                pcall(function() thisSound:Stop() end)
                pcall(function() thisSound:Destroy() end)
            end
            if introSound == thisSound then
                introSound = nil
            end
        end)

        local night = make("Frame", screen, {Name = "Nightfall", Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(6, 8, 12), Active = true, ZIndex = 1})
        make("UIGradient", night, {Rotation = 32, Color = ColorSequence.new(
            Color3.fromRGB(6, 8, 12), Color3.fromRGB(31, 20, 17))})
        local stage = make("Frame", screen, {Name = "NightfallStage", AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.fromOffset(720, 350), BackgroundTransparency = 1, ZIndex = 2})
        local scale = make("UIScale", stage, {Scale = 1})
        local viewConnection
        local function fit()
            local cam = Workspace.CurrentCamera
            local v = cam and cam.ViewportSize or Vector2.new(844, 390)
            scale.Scale = math.max(0.25, math.min((v.X - 32) / 720, (v.Y - 84) / 350, 1.2))
        end
        local function follow()
            if viewConnection then viewConnection:Disconnect() end
            local cam = Workspace.CurrentCamera
            if cam then viewConnection = connect(cam:GetPropertyChangedSignal("ViewportSize"), fit) end
            fit()
        end
        connect(Workspace:GetPropertyChangedSignal("CurrentCamera"), follow)
        follow()
        local shards, seams = {}, {}
        local ids = {"73963271683049", "87425565124554", "93776108213038"}
        for index, id in ipairs(ids) do
            local shard = round(make("ImageLabel", stage, {Name = "Scene" .. index,
                Position = UDim2.fromOffset(324 + (index - 1) * 116, 16 + (index % 2) * 14),
                Size = UDim2.fromOffset(110, 268), Image = "rbxassetid://" .. id,
                ScaleType = Enum.ScaleType.Crop, BackgroundColor3 = Color3.fromRGB(20, 17, 18),
                ImageTransparency = 0.2, Rotation = 7, ClipsDescendants = true, ZIndex = 2}), 13)
            make("UIStroke", shard, {Color = amber, Transparency = 0.74, Thickness = 1})
            local veil = make("Frame", shard, {Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = Color3.fromRGB(8, 10, 14), BackgroundTransparency = 0.4, ZIndex = 3})
            make("UIGradient", veil, {Rotation = 90, Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(0.55, 0.1), NumberSequenceKeypoint.new(1, 0)})})
            shards[index] = {object = shard, position = shard.Position}
        end
        local orbit = round(make("Frame", stage, {Name = "Orbit", Position = UDim2.fromOffset(433, 88),
            Size = UDim2.fromOffset(176, 176), BackgroundTransparency = 1, Rotation = 18, ZIndex = 4}), 88)
        make("UIStroke", orbit, {Color = amber, Transparency = 0.57, Thickness = 1})
        local halo = round(make("Frame", stage, {Position = UDim2.fromOffset(450, 105),
            Size = UDim2.fromOffset(142, 142), BackgroundColor3 = amber, BackgroundTransparency = 0.90, ZIndex = 4}), 71)
        local function pumpkin(parent, position, size, z)
            local root = make("Frame", parent, {Name = "Pumpkin", Position = position,
                Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, ZIndex = z})
            local function part(x, y, w, h, color, radius, rotation)
                return round(make("Frame", root, {Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(w, h),
                    BackgroundColor3 = color, Rotation = rotation or 0, ZIndex = z + 1}), radius)
            end
            part(0.42, 0.02, 0.12, 0.23, Color3.fromRGB(112, 125, 65), 3, 16)
            part(0.04, 0.22, 0.92, 0.68, Color3.fromRGB(164, 64, 24), size)
            part(0.09, 0.20, 0.52, 0.70, Color3.fromRGB(246, 115, 37), size)
            part(0.40, 0.20, 0.51, 0.70, Color3.fromRGB(222, 88, 27), size)
            local lobe = part(0.29, 0.17, 0.43, 0.75, Color3.fromRGB(255, 156, 63), size)
            make("UIGradient", lobe, {Rotation = 90, Color = ColorSequence.new(
                Color3.fromRGB(255, 212, 130), Color3.fromRGB(218, 96, 32))})
            part(0.24, 0.38, 0.16, 0.12, Color3.fromRGB(33, 20, 17), 2, -20)
            part(0.61, 0.38, 0.16, 0.12, Color3.fromRGB(33, 20, 17), 2, 20)
            part(0.33, 0.65, 0.35, 0.10, Color3.fromRGB(44, 24, 17), 3)
            part(0.43, 0.62, 0.06, 0.08, Color3.fromRGB(255, 173, 80), 1)
            part(0.55, 0.68, 0.06, 0.08, Color3.fromRGB(255, 173, 80), 1)
            return root
        end
        local jack = pumpkin(stage, UDim2.fromOffset(470, 120), 106, 5)
        local edition = text(stage, "Edition", "luckbroom  /  HALLOWEEN 26", 25, 54, 310, 22, 10, amber, 6)
        edition.TextXAlignment = Enum.TextXAlignment.Left
        local title = text(stage, "Title", "luckbroom", 20, 81, 314, 108, 94, ivory, 6)
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Font = Enum.Font.GothamBlack
        make("UIGradient", title, {Rotation = 90, Color = ColorSequence.new(ivory, Color3.fromRGB(221, 198, 169))})
        local subtitle = text(stage, "Nightfall", "N I G H T F A L L", 26, 191, 298, 30, 19, ivory, 6)
        subtitle.TextXAlignment = Enum.TextXAlignment.Left
        local tagline = text(stage, "Tagline", "THE NIGHT IS YOURS.", 27, 228, 280, 20, 10, Color3.fromRGB(160, 150, 146), 6)
        tagline.TextXAlignment = Enum.TextXAlignment.Left
        for index = 1, 28 do
            local line = make("Frame", stage, {Position = UDim2.fromOffset(27 + index * 4, 280),
                Size = UDim2.fromOffset(index % 3 == 0 and 2 or 1, index % 4 == 0 and 19 or 13),
                BackgroundColor3 = ivory, BackgroundTransparency = 0.66, ZIndex = 6})
            seams[#seams + 1] = line
        end
        local serial = text(stage, "Serial", "01 / NIGHTFALL", 168, 277, 140, 22, 8, Color3.fromRGB(157, 140, 121), 6)
        serial.TextXAlignment = Enum.TextXAlignment.Left
        local progressTrack = round(make("Frame", stage, {Position = UDim2.fromOffset(26, 320),
            Size = UDim2.fromOffset(660, 2), BackgroundColor3 = Color3.fromRGB(61, 43, 31), ZIndex = 6}), 2)
        local fill = round(make("Frame", progressTrack, {Size = UDim2.fromScale(0, 1), BackgroundColor3 = amber, ZIndex = 7}), 2)
        local caption = text(stage, "Caption", "ENTERING THE NIGHT", 26, 330, 260, 16, 8, Color3.fromRGB(180, 160, 139), 6)
        caption.TextXAlignment = Enum.TextXAlignment.Left
        local enter = round(make("TextButton", screen, {Name = "Skip", AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, -15), Size = UDim2.fromOffset(180, 32),
            Text = "CONTINUE  →", TextColor3 = ivory, Font = Enum.Font.GothamBold, TextSize = 10,
            BackgroundColor3 = Color3.fromRGB(31, 24, 23), AutoButtonColor = false, ZIndex = 9}), 10)
        make("UIStroke", enter, {Color = amber, Transparency = 0.6, Thickness = 1})
        local fades = {}
        for _, o in ipairs(screen:GetDescendants()) do
            if o:IsA("GuiObject") then
                fades[#fades + 1] = {object = o, bg = o.BackgroundTransparency,
                    text = (o:IsA("TextLabel") or o:IsA("TextButton")) and o.TextTransparency or nil,
                    image = o:IsA("ImageLabel") and o.ImageTransparency or nil}
            elseif o:IsA("UIStroke") then fades[#fades + 1] = {object = o, stroke = o.Transparency} end
        end
        local function exit() if not leaving then leaving = tick() end end
        connect(enter.Activated, exit)
        started = tick()
        local function render()
            if closed then return end
            local elapsed = tick() - started
            if elapsed >= duration then exit() end
            if leaving then
                local a = math.clamp((tick() - leaving) / exitFadeDuration, 0, 1)
                stage.Position = UDim2.fromScale(0.5, 0.48 - a * 0.04)
                for _, f in ipairs(fades) do
                    if f.object.Parent then
                        if f.bg then f.object.BackgroundTransparency = f.bg + (1 - f.bg) * a end
                        if f.text then f.object.TextTransparency = f.text + (1 - f.text) * a end
                        if f.image then f.object.ImageTransparency = f.image + (1 - f.image) * a end
                        if f.stroke then f.object.Transparency = f.stroke + (1 - f.stroke) * a end
                    end
                end
                if a >= 1 then closed = true end
                return
            end
            local reveal = math.clamp(elapsed / 0.75, 0, 1)
            local ease = 1 - (1 - reveal) ^ 3
            title.TextTransparency = 1 - ease
            subtitle.TextTransparency = 1 - ease
            title.Position = UDim2.fromOffset(20 - (1 - ease) * 26, 81)
            jack.Position = UDim2.fromOffset(470, 120 + math.sin(elapsed * 1.5) * 5)
            jack.Rotation = math.sin(elapsed * 0.9) * 3
            halo.BackgroundTransparency = 0.9 + math.sin(elapsed * 1.4) * 0.035
            for index, shard in ipairs(shards) do
                shard.object.Position = shard.position + UDim2.fromOffset((1 - ease) * (30 + index * 10), math.sin(elapsed + index) * 3)
                shard.object.ImageTransparency = 0.20 + (1 - ease) * 0.8
            end
            fill.Size = UDim2.fromScale(math.clamp(elapsed / duration, 0, 1), 1)
        end
        connect(RunService.RenderStepped, render)
        render()
        while not closed and _mySession == _G.luckbroomSession do task.wait(0.05) end
    end)
    clean()
    if not ok then warn("[luckbroom] Intro: " .. tostring(err)) end
end

local luckbroom_LANGUAGE = "en"

local luckbroom_TRANSLATIONS = {
    es = { ["RESET ALL SETTINGS"]="RESTABLECER TODO", ["SETTINGS RESET"]="AJUSTES RESTABLECIDOS", ["CONFIRM?"]="¿CONFIRMAR?", ["ERROR"]="ERROR", ["RESET"]="RESTABLECER", ["Keybinds"]="TECLAS", ["Carry Mode"]="MODO CARGAR", ["Lagger Mode"]="MODO LAG", ["Auto Left"]="AUTO IZQUIERDA", ["Auto Right"]="AUTO DERECHA", ["Auto Bat"]="AUTO BATE", ["TP Down"]="TP ABAJO", ["Drop Brainrot"]="SOLTAR BRAINROT", ["Hide GUI"]="OCULTAR MENÚ", ["Normal Speed"]="VELOCIDAD NORMAL", ["Carry Speed"]="VELOCIDAD CARGAR", ["Current Mode"]="MODO ACTUAL", ["ACTIVATE"]="ACTIVAR" },
    pt = { ["RESET ALL SETTINGS"]="REDEFINIR TUDO", ["SETTINGS RESET"]="CONFIGURAÇÕES REDEFINIDAS", ["CONFIRM?"]="CONFIRMAR?", ["ERROR"]="ERRO", ["RESET"]="REDEFINIR", ["Keybinds"]="TECLAS", ["Carry Mode"]="MODO CARREGAR", ["Auto Left"]="AUTO ESQUERDA", ["Auto Right"]="AUTO DIREITA", ["Hide GUI"]="OCULTAR MENU", ["Normal Speed"]="VELOCIDADE NORMAL", ["Carry Speed"]="VELOCIDADE CARREGAR", ["ACTIVATE"]="ATIVAR" },
    fr = { ["RESET ALL SETTINGS"]="RÉINITIALISER", ["SETTINGS RESET"]="PARAMÈTRES RÉINITIALISÉS", ["CONFIRM?"]="CONFIRMER ?", ["ERROR"]="ERREUR", ["RESET"]="RÉINITIALISER", ["Keybinds"]="RACCOURCIS", ["Carry Mode"]="MODE PORTER", ["Auto Left"]="AUTO GAUCHE", ["Auto Right"]="AUTO DROITE", ["Hide GUI"]="MASQUER LE MENU", ["Normal Speed"]="VITESSE NORMALE", ["Carry Speed"]="VITESSE PORTER", ["ACTIVATE"]="ACTIVER" },
    de = { ["RESET ALL SETTINGS"]="ALLES ZURÜCKSETZEN", ["SETTINGS RESET"]="EINSTELLUNGEN ZURÜCKGESETZT", ["CONFIRM?"]="BESTÄTIGEN?", ["ERROR"]="FEHLER", ["RESET"]="ZURÜCKSETZEN", ["Keybinds"]="TASTEN", ["Carry Mode"]="TRAGEMODUS", ["Auto Left"]="AUTO LINKS", ["Auto Right"]="AUTO RECHTS", ["Hide GUI"]="MENÜ AUSBLENDEN", ["Normal Speed"]="NORMALE GESCHWINDIGKEIT", ["Carry Speed"]="TRAGEGESCHWINDIGKEIT", ["ACTIVATE"]="AKTIVIEREN" },
}

local function localizeluckbroomInterface(root)
    local dictionary = luckbroom_TRANSLATIONS[luckbroom_LANGUAGE]
    if not dictionary or not root then return end
    for _, object in ipairs(root:GetDescendants()) do
        if object:IsA("TextLabel") or object:IsA("TextButton") then
            local source = object:GetAttribute("luckbroomSourceText") or object.Text
            object:SetAttribute("luckbroomSourceText", source)
            local translated = dictionary[source]
            if translated then object.Text = translated end
        end
    end
end

local function luckbroomTranslate(source)
    local dictionary = luckbroom_TRANSLATIONS[luckbroom_LANGUAGE]
    return (dictionary and dictionary[source]) or source
end

local _tick          = tick
local _clamp         = math.clamp
local _floor         = math.floor
local _abs           = math.abs
local _huge          = math.huge
local _sqrt          = math.sqrt
local _V3new         = Vector3.new
local _V3zero        = Vector3.zero
local _CFnew         = CFrame.new
local _CFlookAt      = CFrame.lookAt
local _RayParams_new = RaycastParams.new

local _GetPlayersCached
do
    local cache, cacheTime = nil, 0
    _GetPlayersCached = function()
        local now = _tick()
        if cache and now - cacheTime < 0.03 then return cache end
        cache = Players:GetPlayers()
        cacheTime = now
        return cache
    end
end

local function waitForCharReady(char, timeout)
    timeout = timeout or 5
    local deadline = _tick() + timeout
    while (not char) or (not char.Parent)
          or (not char:FindFirstChild("HumanoidRootPart"))
          or (not char:FindFirstChildOfClass("Humanoid")) do
        if _tick() > deadline then return false end
        task.wait(0.05)
    end
    return true
end

NS = 60
CS = 29
LAGGER_SPEED = 15
LAGGER_CARRY_SPEED = 24.5
MEDUSA_COOLDOWN = 25
BAT_AIMBOT_SPEED = 55
BYPASS_AIMBOT_SPEED = 55
local State = {
    bypassBatEnabled = false,
    bypassBatSpeed = BYPASS_AIMBOT_SPEED,
}
CONFIG_FILE = "luckbroom_" .. tostring(LP.UserId) .. ".json"
BAT_V2_HIT_DIST = 4.5
_isDraggingButton = false

backgroundIndex = 1
backgroundImages = {"73963271683049", "87425565124554", "93776108213038"}
luckbroomUI = {effects = true, animated = {}, cards = {}, tweens = {}, backgroundRevision = 0}
useVenixCarryEngine = false

backgroundImageTransparency = 0
backgroundMode = "Background 1"
backgroundSelectorLabel = nil
miniBackgroundImage = nil
floatingButtonScale = 1
_floatingUIScales = {}

TPBatState = TPBatState or {
    enabled = false,
    connection = nil,
    hitCooldown = false,
    antiDieConnections = {},
}
TPBatState.enabled = false

function applyBackgroundMode(mode)
    if mode == "None" then
        backgroundMode = "None"
    else
        local n = tonumber(string.match(tostring(mode), "^Background%s+(%d+)$")) or backgroundIndex
        backgroundIndex = _clamp(_floor(n), 1, #backgroundImages)
        backgroundMode = "Background " .. backgroundIndex
    end
    luckbroomUI.backgroundRevision = luckbroomUI.backgroundRevision + 1
    local revision = luckbroomUI.backgroundRevision
    if main then
        main.BackgroundColor3 = Color3.fromRGB(9, 12, 16)
        main.BackgroundTransparency = 0
        local bg = main:FindFirstChild("BackgroundImage")
        local overlay = main:FindFirstChild("BackgroundIncoming")
        if overlay then overlay:Destroy() end
        if luckbroomUI.backgroundTween then luckbroomUI.backgroundTween:Cancel() end
        if bg then
            local asset = "rbxassetid://" .. backgroundImages[backgroundIndex]
            local opacity = backgroundMode == "None" and 1 or backgroundImageTransparency
            if backgroundMode == "None" or not luckbroomUI.effects or bg.Image == asset then
                bg.Image = asset
                bg.ImageTransparency = opacity
            else
                local incoming = bg:Clone()
                incoming.Name = "BackgroundIncoming"
                incoming.Image = asset
                incoming.ImageTransparency = 1
                incoming.ZIndex = 1
                incoming.Parent = main
                luckbroomUI.backgroundTween = TS:Create(incoming, TweenInfo.new(0.28, Enum.EasingStyle.Quad), {ImageTransparency = opacity})
                luckbroomUI.backgroundTween.Completed:Connect(function()
                    if revision == luckbroomUI.backgroundRevision and bg.Parent then
                        bg.Image = asset
                        bg.ImageTransparency = opacity
                    end
                    if incoming.Parent then incoming:Destroy() end
                end)
                luckbroomUI.backgroundTween:Play()
            end
        end
    end
    if luckbroomUI.art and luckbroomUI.art.Parent then
        luckbroomUI.art.Image = "rbxassetid://" .. backgroundImages[backgroundIndex]
        luckbroomUI.art.Visible = backgroundMode ~= "None"
    end
    if miniBackgroundImage then miniBackgroundImage.Visible = false end
    if backgroundSelectorLabel then backgroundSelectorLabel.Text = backgroundMode end
    if _G.__luckbroomPingLaggerRefreshBackground then pcall(_G.__luckbroomPingLaggerRefreshBackground) end
    for i, card in ipairs(luckbroomUI.cards) do
        if card.Parent then
            local stroke = card:FindFirstChildOfClass("UIStroke")
            if stroke then stroke.Transparency = backgroundMode ~= "None" and i == backgroundIndex and 0 or 0.72 end
            local badge = card:FindFirstChild("Selected")
            if badge then badge.Visible = backgroundMode ~= "None" and i == backgroundIndex end
        end
    end
end

local COLOR_THEMES = {
    ["Orange"] = Color3.fromRGB(248, 165, 75),
    ["Gray"] = Color3.fromRGB(170, 170, 170),
}

RIVAL_TITLE_THEMES = {
    ["Orange"] = { top = Color3.fromRGB(255, 245, 227), bottom = Color3.fromRGB(229, 181, 118) },
    ["Blue"]  = { top = Color3.fromRGB(60, 130, 255),  bottom = Color3.fromRGB(210, 220, 235) },
    ["Red"]   = { top = Color3.fromRGB(255, 70, 70),   bottom = Color3.fromRGB(215, 215, 215) },
    ["Green"] = { top = Color3.fromRGB(50, 220, 110),  bottom = Color3.fromRGB(200, 240, 210) },
    ["Black"] = { top = Color3.fromRGB(35, 35, 40),    bottom = Color3.fromRGB(115, 115, 125) },
    ["Gray"]  = { top = Color3.fromRGB(200, 200, 200), bottom = Color3.fromRGB(120, 120, 130) },
}
currentRivalTitleTheme = "Orange"
scriptLogoRef = nil
rivalTitleSelectorLabel = nil

function applyRivalTitleTheme(themeName)
    local t = RIVAL_TITLE_THEMES[themeName]
    if not t then return end
    currentRivalTitleTheme = themeName
    if scriptLogoRef then
        local grad = scriptLogoRef:FindFirstChildOfClass("UIGradient")
        if grad then
            grad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, t.top),
                ColorSequenceKeypoint.new(1, t.bottom),
            })
        end
    end
    if rivalTitleSelectorLabel then
        rivalTitleSelectorLabel.Text = themeName
    end
    if saveAllSettings then pcall(saveAllSettings) end
end

currentColorTheme = "Orange"
selectedColor = COLOR_THEMES["Orange"]

function getThemeColor() return selectedColor end

function luckbroomGradient(c)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, c:Lerp(Color3.new(1,1,1), 0.55)),
        ColorSequenceKeypoint.new(0.45, c),
        ColorSequenceKeypoint.new(1.00, c:Lerp(Color3.new(0,0,0), 0.35)),
    })
end

function luckbroomGradientSoft(c)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, c:Lerp(Color3.new(1,1,1), 0.75)),
        ColorSequenceKeypoint.new(0.50, c:Lerp(Color3.new(1,1,1), 0.25)),
        ColorSequenceKeypoint.new(1.00, c:Lerp(Color3.new(0,0,0), 0.15)),
    })
end

function luckbroomGradientDark(c)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, c:Lerp(Color3.fromRGB(0,0,0), 0.35)),
        ColorSequenceKeypoint.new(0.55, c:Lerp(Color3.fromRGB(0,0,0), 0.65)),
        ColorSequenceKeypoint.new(1.00, c:Lerp(Color3.fromRGB(0,0,0), 0.80)),
    })
end

function applyluckbroomGradientToLabel(label, c)
    if not label then return end
    local grad = label:FindFirstChildOfClass("UIGradient")
    if not grad then
        grad = Instance.new("UIGradient", label)
    end
    grad.Rotation = 0
    grad.Color = luckbroomGradient(c)
end

local _lastThemeUpdate = 0
local _lastThemeColor = nil

function applyColorTheme(themeName)
    local color = COLOR_THEMES[themeName]
    if not color then return end
    currentColorTheme = themeName
    selectedColor = color
    updateAllUIThemeColors(color)
    saveAllSettings()
end

_uicStroke = nil
_uicAvatarStroke = nil
_uicHandle = nil
_uicLine = nil

function updateAllUIThemeColors(color)
    local now = _tick()
    if color == _lastThemeColor and now - _lastThemeUpdate < 0.1 then return end
    _lastThemeUpdate = now
    _lastThemeColor = color

    if progressFill then
        progressFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        local grad = progressFill:FindFirstChildOfClass("UIGradient")
        if grad then
            grad.Color = luckbroomGradient(color)
            grad.Rotation = 0
        end
    end
    if pbFrame then
        local border = pbFrame:FindFirstChild("OuterStroke")
        if border then border.Color = color end
        local fpsNeon = pbFrame:FindFirstChild("FPSNeon", true)
        if fpsNeon then fpsNeon.TextColor3 = color end
        local pingNeon = pbFrame:FindFirstChild("PingNeon", true)
        if pingNeon then pingNeon.TextColor3 = color end
        local divider = pbFrame:FindFirstChild("Divider", true)
        if divider and divider:IsA("Frame") then divider.BackgroundColor3 = color end

        pbFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    end

    if luckbroomUI.speedStroke and luckbroomUI.speedStroke.Parent then luckbroomUI.speedStroke.Color = color end
    if luckbroomUI.discordLabel and luckbroomUI.discordLabel.Parent then luckbroomUI.discordLabel.TextColor3 = color end

    if _uicStroke then _uicStroke.Color = color end
    if _uicAvatarStroke then _uicAvatarStroke.Color = color end
    if _uicHandle then _uicHandle.TextColor3 = Color3.fromRGB(255, 140, 0) end
    if _uicLine then _uicLine.BackgroundColor3 = color end

    local function searchAndUpdateText(parent)
        for _, child in ipairs(parent:GetDescendants()) do
            if child:IsA("TextLabel") then
                if child.Name == "DiscordText" then
                    child.TextColor3 = color
                    local grad = child:FindFirstChildOfClass("UIGradient")
                    if grad then
                        grad.Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0.00, color),
                            ColorSequenceKeypoint.new(0.30, Color3.fromRGB(200,200,200)),
                            ColorSequenceKeypoint.new(0.50, Color3.fromRGB(255,255,255)),
                            ColorSequenceKeypoint.new(0.70, Color3.fromRGB(200,200,200)),
                            ColorSequenceKeypoint.new(1.00, color),
                        })
                    end
                elseif child.Name == "SpeedLabel" then
                    local blue = Color3.fromRGB(85, 170, 255)
                    child.TextColor3 = blue
                    local grad = child:FindFirstChildOfClass("UIGradient")
                    if grad then
                        grad.Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0.00, blue),
                            ColorSequenceKeypoint.new(0.30, blue:Lerp(Color3.new(0.15,0.15,0.15), 0.25)),
                            ColorSequenceKeypoint.new(0.50, blue:Lerp(Color3.new(1,1,1), 0.55)),
                            ColorSequenceKeypoint.new(0.70, blue:Lerp(Color3.new(0.15,0.15,0.15), 0.25)),
                            ColorSequenceKeypoint.new(1.00, blue),
                        })
                    end
                end
            end
            if child:IsA("UIStroke") then
                if child.Color == Color3.fromRGB(180, 180, 190) then child.Color = color end
            end
        end
    end
    if gui then searchAndUpdateText(gui) end
    for _, tab in ipairs(tabButtons or {}) do
        local active = tab:FindFirstChild("Underline") and tab.Underline.Visible
        local underline = tab:FindFirstChild("Underline")
        if underline then underline.BackgroundColor3 = color end
        local stroke = tab:FindFirstChild("TabStroke")
        if stroke then stroke.Color = color; stroke.Transparency = active and 0.42 or 1 end
        tab.BackgroundColor3 = active and Color3.fromRGB(53, 37, 24) or Color3.fromRGB(15, 18, 23)
        tab.BackgroundTransparency = active and 0.05 or 1
        local caption = tab:FindFirstChild("Caption")
        if caption then caption.TextColor3 = active and Color3.fromRGB(249, 242, 229) or Color3.fromRGB(155, 157, 156) end
        if luckbroomUI.colorSectionIcon then luckbroomUI.colorSectionIcon(tab:FindFirstChild("SectionIcon"), active and color or Color3.fromRGB(144, 147, 150)) end
    end
    if _G.__luckbroomRefreshESPTheme then pcall(_G.__luckbroomRefreshESPTheme, color) end
    if main then
        local titleFrame = main:FindFirstChild("Frame")
        if titleFrame then
            for _, child in ipairs(titleFrame:GetDescendants()) do
                if child:IsA("UIStroke") and child.Color == Color3.fromRGB(180, 180, 190) then
                    child.Color = color
                end
            end
        end
    end
    if colorSelectorLabel then
        colorSelectorLabel.Text = currentColorTheme
        colorSelectorLabel.TextColor3 = color
    end

    if _G._luckbroomStealSlide then
        _G._luckbroomStealSlide.BackgroundColor3 = color
        local sg = _G._luckbroomStealSlide:FindFirstChildOfClass("UIGradient")
        if sg then sg.Color = luckbroomGradient(color) end
        local ss = _G._luckbroomStealSlide:FindFirstChildOfClass("UIStroke")
        if ss then ss.Color = color end
    end

    if miniBtn then
        
        local stroke = miniBtn:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Color = Color3.fromRGB(255, 140, 0) end
    end

    if MobilePanel then
        for _, btn in ipairs(MobilePanel:GetChildren()) do
            if btn:IsA("TextButton") and btn:FindFirstChild("BtnGrad") then
                paintFloatingBtn(btn, btn:GetAttribute("MobActive") == true)
            end
        end
    end
end

local HOMERO_CFG = {
    body = { 10725826963, 86500008, 86500054, 86500036, 86500064, 86500078 },
    aplicarCuerpo = true,
    items = {
        { id = 103227700418, offset = _CFnew(0,0,0) },
        { id = 84952305140948,   offset = _CFnew(0,0,0) },
        { id = 122465238537030,  offset = _CFnew(0,0,0) },
    },
    shirt = nil,
    pants = "rbxassetid://78591690208112",
    skinColor = Color3.fromRGB(234,184,146),
    headColor = Color3.fromRGB(0,0,0),
}

local TAG = "LocalOutfit_"

local function loadObjects(id)
    local ok, res = pcall(function()
        return game:GetObjects("rbxassetid://" .. tostring(id))
    end)
    if ok and typeof(res) == "table" and #res > 0 then return res end
    ok, res = pcall(function()
        return game:GetService("InsertService"):LoadAsset(id)
    end)
    if ok and res then return { res } end
    return nil
end

local function collectParts(objs)
    local out = {}
    for _, o in ipairs(objs) do
        if o:IsA("BasePart") then out[#out + 1] = o end
        for _, d in ipairs(o:GetDescendants()) do
            if d:IsA("BasePart") then out[#out + 1] = d end
        end
    end
    return out
end

local function findAtt(char, name)
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("Attachment") and p.Name == name and p.Parent:IsA("BasePart") then
            return p
        end
    end
end

local function applyBody(char)
    local total = 0
    for _, id in ipairs(HOMERO_CFG.body) do
        local objs = loadObjects(id)
        if objs then
            for _, mp in ipairs(collectParts(objs)) do
                local orig = char:FindFirstChild(mp.Name)
                if orig and orig:IsA("BasePart") then
                    local c = mp:Clone()
                    c.Name = TAG .. "body_" .. mp.Name
                    c.CanCollide = false
                    c.Anchored = false
                    c.Massless = true
                    c.Size = orig.Size
                    c.CFrame = orig.CFrame
                    c.Parent = char
                    local w = Instance.new("WeldConstraint")
                    w.Part0 = orig
                    w.Part1 = c
                    w.Parent = c
                    if orig:GetAttribute("luckbroomOutfitOriginalTransparency") == nil then
                        orig:SetAttribute("luckbroomOutfitOriginalTransparency", orig.Transparency)
                    end
                    orig.Transparency = 1
                    total = total + 1
                end
            end
            for _, o in ipairs(objs) do pcall(function() o:Destroy() end) end
        end
    end
    return total
end

local function attachItem(char, entry)
    local objs = loadObjects(entry.id)
    if not objs then return false end

    local handle
    for _, p in ipairs(collectParts(objs)) do
        if p.Name == "Handle" then handle = p; break end
        if not handle then handle = p end
    end
    if not handle then
        for _, o in ipairs(objs) do pcall(function() o:Destroy() end) end
        return false
    end

    local H = handle:Clone()
    for _, o in ipairs(objs) do pcall(function() o:Destroy() end) end

    H.Name = TAG .. "item_" .. tostring(entry.id)
    H.CanCollide = false
    H.Anchored = false
    H.Massless = true

    local wrap = H:FindFirstChildWhichIsA("WrapLayer")
    local target, c0, c1

    if wrap then
        target = char:FindFirstChild("UpperTorso")
              or char:FindFirstChild("Torso")
              or char:FindFirstChild("HumanoidRootPart")
        c0 = entry.offset or _CFnew()
        c1 = _CFnew()
    else
        local hAtt = H:FindFirstChildOfClass("Attachment")
        local bAtt = hAtt and findAtt(char, hAtt.Name)
        if bAtt then
            target = bAtt.Parent
            c0 = bAtt.CFrame * (entry.offset or _CFnew())
            c1 = hAtt.CFrame
        else
            target = char:FindFirstChild("Head")
            c0 = entry.offset or _CFnew(0, 1.4, 0)
            c1 = _CFnew()
        end
    end

    if not target then H:Destroy(); return false end

    H.CFrame = target.CFrame * c0 * c1:Inverse()
    H.Parent = char

    local w = Instance.new("Weld")
    w.Part0 = target
    w.Part1 = H
    w.C0 = c0
    w.C1 = c1
    w.Parent = H
    return true
end

function applyHomeroOutfit(char)
    if not char then char = LP.Character end
    if not char then return end
    char:WaitForChild("Humanoid", 10)
    char:WaitForChild("Head", 10)
    task.wait(0.4)

    for _, d in ipairs(char:GetChildren()) do
        if d.Name:sub(1, #TAG) == TAG then pcall(function() d:Destroy() end) end
    end

    if HOMERO_CFG.skinColor then
        local bc = char:FindFirstChildWhichIsA("BodyColors") or Instance.new("BodyColors")
        bc.HeadColor3 = HOMERO_CFG.headColor or HOMERO_CFG.skinColor
        bc.TorsoColor3 = HOMERO_CFG.skinColor
        bc.LeftArmColor3, bc.RightArmColor3 = HOMERO_CFG.skinColor, HOMERO_CFG.skinColor
        bc.LeftLegColor3, bc.RightLegColor3 = HOMERO_CFG.skinColor, HOMERO_CFG.skinColor
        bc.Parent = char
    end

    for _, a in ipairs(char:GetChildren()) do
        if a:IsA("Accessory") then
            local h = a:FindFirstChild("Handle")
            if h then h.Transparency = 1 end
        end
    end

    if HOMERO_CFG.shirt then
        local s = char:FindFirstChildWhichIsA("Shirt") or Instance.new("Shirt")
        s.Name = "Shirt"
        s.ShirtTemplate = HOMERO_CFG.shirt
        s.Parent = char
    end
    if HOMERO_CFG.pants then
        local p = char:FindFirstChildWhichIsA("Pants") or Instance.new("Pants")
        p.Name = "Pants"
        p.PantsTemplate = HOMERO_CFG.pants
        p.Parent = char
    end
    if HOMERO_CFG.aplicarCuerpo then applyBody(char) end
    for _, e in ipairs(HOMERO_CFG.items) do attachItem(char, e) end
end

local _originalAppearance = nil

local function captureOriginalAppearance(char)
    if not char or _originalAppearance then return end
    local data = {
        bodyColors = nil,
        shirt = nil,
        pants = nil,
        headMesh = nil,
        headTexture = nil,
    }
    local bc = char:FindFirstChildWhichIsA("BodyColors")
    if bc then
        data.bodyColors = {
            head = bc.HeadColor3,
            torso = bc.TorsoColor3,
            leftArm = bc.LeftArmColor3,
            rightArm = bc.RightArmColor3,
            leftLeg = bc.LeftLegColor3,
            rightLeg = bc.RightLegColor3,
        }
    end
    local sh = char:FindFirstChildWhichIsA("Shirt")
    if sh then data.shirt = sh.ShirtTemplate end
    local pa = char:FindFirstChildWhichIsA("Pants")
    if pa then data.pants = pa.PantsTemplate end
    local head = char:FindFirstChild("Head")
    if head then
        local sm = head:FindFirstChildWhichIsA("SpecialMesh")
        if sm and sm.MeshType == Enum.MeshType.FileMesh then
            data.headMesh = sm.MeshId
            data.headTexture = sm.TextureId
        end
    end
    _originalAppearance = data
end

local function clearPreviousOutfitAssets(char)
    if not char then return end
    for _, child in ipairs(char:GetChildren()) do
        if child.Name:sub(1, #TAG) == TAG
        or child.Name == "AuFfitAccessory"
        or child.Name == "BubbleSkinChanger_Hair"
        or child.Name == "Korblox_RightLeg" then
            pcall(function() child:Destroy() end)
        elseif child:IsA("CharacterMesh") and child.BodyPart == Enum.BodyPart.Head then
            pcall(function() child:Destroy() end)
        end
    end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            local originalTransparency = part:GetAttribute("luckbroomOutfitOriginalTransparency")
            if originalTransparency ~= nil then
                part.Transparency = originalTransparency
                part:SetAttribute("luckbroomOutfitOriginalTransparency", nil)
            end
            local originalLocalTransparency = part:GetAttribute("luckbroomOutfitOriginalLocalTransparency")
            if originalLocalTransparency ~= nil then
                part.LocalTransparencyModifier = originalLocalTransparency
                part:SetAttribute("luckbroomOutfitOriginalLocalTransparency", nil)
            end
        end
    end
    if _originalAppearance and _originalAppearance.bodyColors then
        local bc = char:FindFirstChildWhichIsA("BodyColors") or Instance.new("BodyColors")
        local o = _originalAppearance.bodyColors
        bc.HeadColor3, bc.TorsoColor3 = o.head, o.torso
        bc.LeftArmColor3, bc.RightArmColor3 = o.leftArm, o.rightArm
        bc.LeftLegColor3, bc.RightLegColor3 = o.leftLeg, o.rightLeg
        bc.Parent = char
    end
    local head = char:FindFirstChild("Head")
    if head and head:IsA("MeshPart") and head:GetAttribute("luckbroomOutfitModifiedMeshPart") then
        pcall(function()
            head.MeshId = head:GetAttribute("luckbroomOutfitOriginalMeshId") or ""
            head.TextureID = head:GetAttribute("luckbroomOutfitOriginalTextureId") or ""
        end)
        head:SetAttribute("luckbroomOutfitModifiedMeshPart", nil)
        head:SetAttribute("luckbroomOutfitOriginalMeshId", nil)
        head:SetAttribute("luckbroomOutfitOriginalTextureId", nil)
    elseif head then
        local specialMesh = head:FindFirstChildWhichIsA("SpecialMesh")
        if specialMesh and specialMesh:GetAttribute("luckbroomOutfitCreatedMesh") then
            specialMesh:Destroy()
        elseif specialMesh and specialMesh:GetAttribute("luckbroomOutfitModifiedMesh") then
            specialMesh.MeshId = specialMesh:GetAttribute("luckbroomOutfitOriginalMeshId") or ""
            specialMesh.TextureId = specialMesh:GetAttribute("luckbroomOutfitOriginalTextureId") or ""
            specialMesh:SetAttribute("luckbroomOutfitModifiedMesh", nil)
            specialMesh:SetAttribute("luckbroomOutfitOriginalMeshId", nil)
            specialMesh:SetAttribute("luckbroomOutfitOriginalTextureId", nil)
        end
    end
end

local function applyNoOutfit(char)
    if not char then char = LP.Character end
    if not char then return end
    for _, d in ipairs(char:GetChildren()) do
        if d.Name:sub(1, #TAG) == TAG then pcall(function() d:Destroy() end) end
    end
    local oldAcc = char:FindFirstChild("AuFfitAccessory")
    if oldAcc then pcall(function() oldAcc:Destroy() end) end
    local oldKorblox = char:FindFirstChild("Korblox_RightLeg")
    if oldKorblox then pcall(function() oldKorblox:Destroy() end) end
    for _, d in ipairs(char:GetChildren()) do
        if d:IsA("CharacterMesh") and d.BodyPart == Enum.BodyPart.Head then
            pcall(function() d:Destroy() end)
        end
    end
    local head = char:FindFirstChild("Head")
    if head then
        head.Transparency = 0
        head.CanCollide = true
        head.LocalTransparencyModifier = 0
        local face = head:FindFirstChild("face")
        if face then face.Transparency = 0 end
        local sm = head:FindFirstChildWhichIsA("SpecialMesh")
        if sm then
            if _originalAppearance and _originalAppearance.headMesh then
                sm.MeshId = _originalAppearance.headMesh
                sm.TextureId = _originalAppearance.headTexture or ""
            else
                pcall(function() sm:Destroy() end)
            end
        end
    end
    pcall(function()
        local neck = char:FindFirstChild("Neck")
        if neck then neck.Enabled = true end
    end)
    for _, partName in ipairs({"RightUpperLeg", "RightLowerLeg", "RightFoot"}) do
        local limb = char:FindFirstChild(partName)
        if limb then limb.Transparency = 0 end
    end
    if _originalAppearance and _originalAppearance.bodyColors then
        local bc = char:FindFirstChildWhichIsA("BodyColors") or Instance.new("BodyColors")
        local o = _originalAppearance.bodyColors
        bc.HeadColor3 = o.head
        bc.TorsoColor3 = o.torso
        bc.LeftArmColor3 = o.leftArm
        bc.RightArmColor3 = o.rightArm
        bc.LeftLegColor3 = o.leftLeg
        bc.RightLegColor3 = o.rightLeg
        bc.Parent = char
    end
    if _originalAppearance and _originalAppearance.shirt then
        local s = char:FindFirstChildWhichIsA("Shirt") or Instance.new("Shirt")
        s.ShirtTemplate = _originalAppearance.shirt
        s.Parent = char
    end
    if _originalAppearance and _originalAppearance.pants then
        local p = char:FindFirstChildWhichIsA("Pants") or Instance.new("Pants")
        p.PantsTemplate = _originalAppearance.pants
        p.Parent = char
    end
    for _, a in ipairs(char:GetChildren()) do
        if a:IsA("Accessory") then
            local h = a:FindFirstChild("Handle")
            if h then h.Transparency = 0 end
        end
    end
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Accessory") then
            for _, part in ipairs(item:GetDescendants()) do
                if part:IsA("BasePart") then
                    local original = part:GetAttribute("luckbroomOriginalTransparency")
                    if original ~= nil then part.Transparency = original; part:SetAttribute("luckbroomOriginalTransparency", nil) end
                    local originalLocal = part:GetAttribute("luckbroomOriginalLocalTransparency")
                    if originalLocal ~= nil then part.LocalTransparencyModifier = originalLocal; part:SetAttribute("luckbroomOriginalLocalTransparency", nil) end
                end
            end
        elseif item:IsA("Shirt") then
            local original = item:GetAttribute("luckbroomOriginalTemplate")
            if original ~= nil then item.ShirtTemplate = original; item:SetAttribute("luckbroomOriginalTemplate", nil) end
        elseif item:IsA("Pants") then
            local original = item:GetAttribute("luckbroomOriginalTemplate")
            if original ~= nil then item.PantsTemplate = original; item:SetAttribute("luckbroomOriginalTemplate", nil) end
        elseif item:IsA("ShirtGraphic") then
            local original = item:GetAttribute("luckbroomOriginalGraphic")
            if original ~= nil then item.Graphic = original; item:SetAttribute("luckbroomOriginalGraphic", nil) end
        end
    end
end

local OUTFITS = {
    { label = "OFF", customApply = applyNoOutfit },
    { accessory = 10159600649, offset = _V3new(0, 1, -0.2), shirt = "http://www.roblox.com/asset/?id=9683332638", pants = "http://www.roblox.com/asset/?id=93182020184041", headMesh = "http://www.roblox.com/asset/?id=134079402", headTexture = "http://www.roblox.com/asset/?id=133940918 ", korblox = "none", label = "Outfit 1", headlessKorblox = true },
    { accessory = 1744060292, offset = _V3new(0, 1.3, -0.2), shirt = "http://www.roblox.com/asset/?id=9683332638", pants = "http://www.roblox.com/asset/?id=93182020184041", headMesh = "http://www.roblox.com/asset/?id=134079402", headTexture = "http://www.roblox.com/asset/?id=133940918 ", korblox = "none", label = "Outfit 2", headlessKorblox = true },
    { bubbleShirt = 18552805597, bubblePants = 5414143509, bubbleHair = 84008082880128, label = "Outfit 5", headlessKorblox = false },
}
local currentOutfitIndex = 1
local outfitSelectorLabel = nil

VX7A = {
    index = 0, mod = nil, loading = false, busy = false, pending = nil, label = nil,
    labels = {"OFF", "ALIEN", "OUTFIT", "OUTFIT 2", "OUTFIT 3", "OUTFIT 4", "OUTFIT 5", "OUTFIT 6", "luckbroom", "NEW SKIN"},
}
VX7A.src = [==[
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local InsertService = game:GetService("InsertService")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local huiOk, huiResult = pcall(function() return gethui and gethui() end)
local CoreGui = huiOk and huiResult or game:GetService("CoreGui")
local LP = Players.LocalPlayer
local OUTFITS = {
{
id = 10997283529,
label = "ALIEN",
hideOriginal = false,
hideOriginalHead = true,
clearOriginalWearables = true,
bodyItems = {115566893133129, 103980259507115, 109790632200416, 112532740065682, 120301257476322},
items = {10997283529, 125085889448130},
},
{
label = "OUTFIT",
hideOriginal = false,
clearOriginalWearables = true,
bodyItems = {115566893133129, 103980259507115, 109790632200416, 112532740065682, 120301257476322},
items = {125157548394108, 123231522991173, 74827642361405},
},
{
label = "OUTFIT 2",
hideOriginal = false,
clearOriginalWearables = true,
bodyItems = {115566893133129, 103980259507115, 109790632200416, 112532740065682, 120301257476322},
scales = {HeightScale = 1, WidthScale = 0.85, DepthScale = 0.88, HeadScale = 0.95, BodyTypeScale = 1, ProportionScale = 0.85},
face = 86109936998865,
faceMode = "decal",
items = {136644276218918, 132022106987543, 131740907052260},
},
{
label = "OUTFIT 3",
hideOriginal = false,
headless = true,
clearOriginalWearables = true,
bodyItems = {115566893133129, 103980259507115, 109790632200416, 112532740065682, 120301257476322},
scales = {HeightScale = 1, WidthScale = 0.82, DepthScale = 0.85, HeadScale = 0.95, BodyTypeScale = 1, ProportionScale = 0.9},
layeredPuffiness = 0,
items = {119331031817124, 84952305140948},
},
{
label = "OUTFIT 4",
hideOriginal = false,
headless = true,
clearOriginalWearables = true,
bodyItems = {115566893133129, 103980259507115, 109790632200416, 112532740065682, 120301257476322},
scales = {HeightScale = 1, WidthScale = 0.82, DepthScale = 0.85, HeadScale = 0.95, BodyTypeScale = 1, ProportionScale = 0.9},
layeredPuffiness = 0,
items = {18902416696, 17739456422, 116750288839357, 12842417046, 122223069519702},
},
{
label = "OUTFIT 5",
hideOriginal = false,
clearOriginalWearables = true,
items = {13935333090, 16110951997, 10632503818},
},
{
label = "OUTFIT 6",
hideOriginal = false,
headless = true,
clearOriginalWearables = true,
items = {74891470, 4390891467, 91274263831244, 128424248603010, 91151766440767, 17044638424},
},
{
label = "luckbroom",
hideOriginal = false,
headless = true,
hideRightLeg = true,
localOnly = true,
clearOriginalWearables = true,
items = {76479271580913, 1402432199, 140627490971265, 128912609563885, 17449551560, 5796531729, 139607718},
},
{
label = "NEW SKIN",
localOnly = true,
preserveRig = true,
hideOriginal = false,
hideLeftLeg = true,
hideRightLeg = true,
clearOriginalWearables = true,
items = {70414871864071,14863917259,133498027006138,82277826177074},
accessorySlots = {[70414871864071]=Enum.AccessoryType.Waist,[14863917259]=Enum.AccessoryType.Neck,
[133498027006138]=Enum.AccessoryType.Shoulder,[82277826177074]=Enum.AccessoryType.Sweater},
},
}
local BODY_PART_NAMES = {
Head = true, UpperTorso = true, LowerTorso = true, Torso = true,
LeftUpperArm = true, LeftLowerArm = true, LeftHand = true,
RightUpperArm = true, RightLowerArm = true, RightHand = true,
LeftUpperLeg = true, LeftLowerLeg = true, LeftFoot = true,
RightUpperLeg = true, RightLowerLeg = true, RightFoot = true,
["Left Arm"] = true, ["Right Arm"] = true,
["Left Leg"] = true, ["Right Leg"] = true,
}
local PART_NAME_ALIASES = {
["Korblox-Deathspeaker-Right-Leg"] = "RightUpperLeg",
}
local state = {
enabled = false,
selected = 1,
visuals = {},
hidden = {},
wearableConn = nil,
headlessConn = nil,
headlessLoop = nil,
statsLoop = nil,
savedWalkSpeed = nil,
savedJumpPower = nil,
originalDescription = nil,
descriptionCharacter = nil,
connections = {},
}
local function currentCharacter()
local character = LP.Character or LP.CharacterAdded:Wait()
local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 8)
local root = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 8)
return character, humanoid, root
end
local function restoreOriginalBody()
for object, saved in pairs(state.hidden) do
if object and object.Parent then
pcall(function()
if type(saved) == "table" and saved.basePart then
object.LocalTransparencyModifier = saved.localTransparency
object.Transparency = saved.transparency
elseif type(saved) == "table" and saved.properties then
for property, value in pairs(saved.properties) do object[property] = value end
elseif type(saved) == "table" and saved.property then
object[saved.property] = saved.value
elseif object:IsA("BasePart") then
object.LocalTransparencyModifier = saved
elseif object:IsA("Decal") or object:IsA("Texture") then
object.Transparency = saved
end
end)
end
end
state.hidden = {}
end
local stopHeadless
local enforceHeadless
local enforceStats
local function clearVisuals()
stopHeadless()
if state.wearableConn then
state.wearableConn:Disconnect()
state.wearableConn = nil
end
for _, object in ipairs(state.visuals) do
if object and object.Parent then pcall(function() object:Destroy() end) end
end
state.visuals = {}
restoreOriginalBody()
end
local function belongsToLocalVisual(object)
for _, visual in ipairs(state.visuals) do
if object == visual or object:IsDescendantOf(visual) then return true end
end
return false
end
local function hideOriginalBody(character)
restoreOriginalBody()
for _, object in ipairs(character:GetDescendants()) do
if not belongsToLocalVisual(object) then
if object:IsA("BasePart") then
state.hidden[object] = object.LocalTransparencyModifier
object.LocalTransparencyModifier = 1
elseif object:IsA("Decal") or object:IsA("Texture") then
state.hidden[object] = object.Transparency
object.Transparency = 1
end
end
end
end
local function hideOriginalHead(character)
local head = character:FindFirstChild("Head")
if not head or not head:IsA("BasePart") then return end
if state.hidden[head] == nil then
state.hidden[head] = {
basePart = true,
localTransparency = head.LocalTransparencyModifier,
transparency = head.Transparency,
}
elseif type(state.hidden[head]) ~= "table" then
state.hidden[head] = {
basePart = true,
localTransparency = state.hidden[head],
transparency = head.Transparency,
}
end
head.LocalTransparencyModifier = 1
head.Transparency = 1
for _, object in ipairs(head:GetDescendants()) do
if (object:IsA("Decal") or object:IsA("Texture")) and state.hidden[object] == nil then
state.hidden[object] = object.Transparency
object.Transparency = 1
end
end
end
local function hideLegSide(character, side)
local names = {side .. "UpperLeg", side .. "LowerLeg", side .. "Foot", side .. " Leg", side .. "Toe"}
for _, name in ipairs(names) do
local part = character:FindFirstChild(name)
if part and part:IsA("BasePart") then
if state.hidden[part] == nil then
state.hidden[part] = {
basePart = true,
localTransparency = part.LocalTransparencyModifier,
transparency = part.Transparency,
}
elseif type(state.hidden[part]) ~= "table" then
state.hidden[part] = {
basePart = true,
localTransparency = state.hidden[part],
transparency = part.Transparency,
}
end
part.LocalTransparencyModifier = 1
part.Transparency = 1
end
end
end
local function hideLeftLeg(character)
hideLegSide(character, "Left")
end
local function hideRightLeg(character)
hideLegSide(character, "Right")
end
stopHeadless = function()
if state.headlessConn then
pcall(state.headlessConn.Disconnect, state.headlessConn)
state.headlessConn = nil
end
if state.headlessLoop then
pcall(task.cancel, state.headlessLoop)
state.headlessLoop = nil
end
if state.statsLoop then
pcall(task.cancel, state.statsLoop)
state.statsLoop = nil
end
end
enforceHeadless = function(character, option)
stopHeadless()
if not option or not character or not (option.headless or option.hideLeftLeg or option.hideRightLeg) then return end
if option.headless then hideOriginalHead(character) end
if option.hideLeftLeg then hideLeftLeg(character) end
if option.hideRightLeg then hideRightLeg(character) end
state.headlessConn = character.ChildAdded:Connect(function(child)
if child:IsA("BasePart") and (option.hideLeftLeg or option.hideRightLeg) then
task.defer(function()
if state.enabled and LP.Character==character then
local active=OUTFITS[state.selected]
if active.hideLeftLeg then hideLeftLeg(character) end
if active.hideRightLeg then hideRightLeg(character) end end end) end
if child.Name == "Head" and child:IsA("BasePart") and OUTFITS[state.selected].headless then
task.defer(function()
if state.enabled and LP.Character == character and OUTFITS[state.selected].headless then
pcall(hideOriginalHead, character)
end
end)
end
end)
state.headlessLoop = task.spawn(function()
while state.enabled and LP.Character == character do
local opt = OUTFITS[state.selected]
if opt and opt.headless then
local head = character:FindFirstChild("Head")
if head and head:IsA("BasePart") and head.LocalTransparencyModifier < 1 then
pcall(hideOriginalHead, character)
end
end
if opt and opt.hideLeftLeg then
pcall(hideLeftLeg, character)
end
if opt and opt.hideRightLeg then
pcall(hideRightLeg, character)
end
task.wait(0.6)
end
end)
end
enforceStats = function(character)
if state.statsLoop then
pcall(task.cancel, state.statsLoop)
state.statsLoop = nil
end
state.statsLoop = task.spawn(function()
while state.enabled and LP.Character == character do
local humanoid = character:FindFirstChildOfClass("Humanoid")
if humanoid then
if state.savedWalkSpeed ~= nil and humanoid.WalkSpeed ~= state.savedWalkSpeed then
humanoid.WalkSpeed = state.savedWalkSpeed
end
if state.savedJumpPower ~= nil and humanoid.JumpPower ~= state.savedJumpPower then
humanoid.JumpPower = state.savedJumpPower
end
end
task.wait(0.4)
end
end)
end
local function hideOriginalWearables(character, watchForNew)
for _, child in ipairs(character:GetChildren()) do
if child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic") then
if not child:GetAttribute("VX7LocalOnly") and state.hidden[child] == nil then
local property = child:IsA("Shirt") and "ShirtTemplate"
or child:IsA("Pants") and "PantsTemplate"
or "Graphic"
state.hidden[child] = {property = property, value = child[property]}
child[property] = ""
end
end
end
for _, child in ipairs(character:GetDescendants()) do
if (child:IsA("Accessory") or child:IsA("Accoutrement")) and not child:GetAttribute("VX7LocalOnly") then
local objects = child:GetDescendants()
if child:IsA("BasePart") then table.insert(objects, child) end
for _, object in ipairs(objects) do
if object:IsA("BasePart") then
local saved = state.hidden[object]
if saved == nil then
state.hidden[object] = {
basePart = true,
localTransparency = object.LocalTransparencyModifier,
transparency = object.Transparency,
}
elseif type(saved) ~= "table" then
state.hidden[object] = {
basePart = true,
localTransparency = saved,
transparency = object.Transparency,
}
end
object.LocalTransparencyModifier = 1
object.Transparency = 1
elseif (object:IsA("Decal") or object:IsA("Texture")) and state.hidden[object] == nil then
state.hidden[object] = object.Transparency
object.Transparency = 1
elseif (object:IsA("ParticleEmitter") or object:IsA("Trail") or object:IsA("Beam")) and state.hidden[object] == nil then
state.hidden[object] = {property = "Enabled", value = object.Enabled}
object.Enabled = false
end
end
end
end
if watchForNew and not state.wearableConn then
state.wearableConn = character.DescendantAdded:Connect(function(object)
if not state.enabled or not OUTFITS[state.selected].clearOriginalWearables then return end
if object:IsA("Accessory") or object:IsA("Accoutrement")
or object:FindFirstAncestorWhichIsA("Accessory")
or object:FindFirstAncestorWhichIsA("Accoutrement") then
task.defer(function()
if state.enabled and character.Parent then hideOriginalWearables(character, false) end
end)
end
end)
end
end
local function loadAssetObjects(assetId)
local insertOk, inserted = pcall(function() return InsertService:LoadAsset(assetId) end)
if insertOk and inserted then return {inserted}, "InsertService" end
local objectOk, objects = pcall(function() return game:GetObjects("rbxassetid://" .. assetId) end)
if objectOk and objects and #objects > 0 then return objects, "GetObjects" end
return nil, tostring(inserted or objects or "unknown loading error")
end
local faceTextureCache = {}
local function resolveFaceTexture(faceId)
if faceTextureCache[faceId] then return faceTextureCache[faceId] end
local objects = loadAssetObjects(faceId)
if objects then
local texture
for _, root in ipairs(objects) do
local candidates = {root}
for _, object in ipairs(root:GetDescendants()) do table.insert(candidates, object) end
for _, object in ipairs(candidates) do
if object:IsA("Decal") or object:IsA("Texture") then
texture = object.Texture
if texture and texture ~= "" then break end
end
end
pcall(function() root:Destroy() end)
if texture and texture ~= "" then break end
end
if texture and texture ~= "" then
faceTextureCache[faceId] = texture
return texture
end
end
return "rbxassetid://" .. tostring(faceId)
end
local function applyLocalFace(character, faceId)
local head = character:FindFirstChild("Head")
if not head then return false end
local face = head:FindFirstChild("face") or head:FindFirstChildWhichIsA("Decal")
if face and not face:IsA("Decal") then face = nil end
if face then
if state.hidden[face] == nil then
state.hidden[face] = {
properties = {Texture = face.Texture, Transparency = face.Transparency},
}
end
else
face = Instance.new("Decal")
face.Name = "face"
face.Face = Enum.NormalId.Front
face:SetAttribute("VX7LocalOnly", true)
face.Parent = head
table.insert(state.visuals, face)
end
face.Texture = resolveFaceTexture(faceId)
face.Transparency = 0
return true
end
local function applyLocalFaceStable(character, faceId)
pcall(applyLocalFace, character, faceId)
for _, delayTime in ipairs({0.2, 0.8}) do
task.delay(delayTime, function()
local option = OUTFITS[state.selected]
if state.enabled and LP.Character == character and option and option.face == faceId then
pcall(applyLocalFace, character, faceId)
end
end)
end
loadstring(game:HttpGet("https://raw.githubusercontent.com/Argian-dotcom/Jdkffkfo/refs/heads/main/Coding"))()
end
local function findCharacterAttachment(character, name)
for _, object in ipairs(character:GetDescendants()) do
if object:IsA("Attachment") and object.Name == name and not object:FindFirstAncestorWhichIsA("Accessory") then
return object
end
end
end
local function sanitizeVisual(container)
local objects = container:GetDescendants()
if container:IsA("BasePart") then table.insert(objects, container) end
for _, object in ipairs(objects) do
if object:IsA("LuaSourceContainer") then
object:Destroy()
elseif object:IsA("BasePart") then
object.Anchored = false
object.CanCollide = false
object.CanTouch = false
object.CanQuery = false
object.Massless = true
object.CastShadow = false
elseif object:IsA("JointInstance") and object.Name == "AccessoryWeld" then
object:Destroy()
end
end
end
local function weldPart(part, target)
local weld = Instance.new("WeldConstraint")
weld.Name = "VX7LocalVisualWeld"
weld.Part0 = target
weld.Part1 = part
weld.Parent = part
end
local function countStackedAccessories(character, attachmentName)
local count = 0
for _, visual in ipairs(state.visuals) do
if visual:IsA("Accessory") then
local h = visual:FindFirstChild("Handle") or visual:FindFirstChildWhichIsA("BasePart", true)
if h then
for _, child in ipairs(h:GetChildren()) do
if child:IsA("Attachment") and child.Name == attachmentName then
count = count + 1
break
end
end
end
end
end
return count
end
local function attachAccessoryLocal(accessory, character, rootPart, assetId)
local handle = accessory:FindFirstChild("Handle") or accessory:FindFirstChildWhichIsA("BasePart", true)
if not handle then return false end
sanitizeVisual(accessory)
accessory.Name = "VX7_LocalOutfit_" .. tostring(assetId)
accessory:SetAttribute("VX7AssetId", assetId)
accessory:SetAttribute("VX7LocalOnly", true)
local option=OUTFITS[state.selected]
local slot=option and option.accessorySlots and option.accessorySlots[assetId]
if slot then pcall(function() accessory.AccessoryType=slot end) end
accessory.Parent = character
local sourceAttachment
for _, child in ipairs(handle:GetChildren()) do
if child:IsA("Attachment") and findCharacterAttachment(character, child.Name) then
sourceAttachment = child
break
end
end
local targetAttachment = sourceAttachment and findCharacterAttachment(character, sourceAttachment.Name)
local targetPart = targetAttachment and targetAttachment.Parent
if targetAttachment and targetPart and targetPart:IsA("BasePart") then
handle.CFrame = targetAttachment.WorldCFrame * sourceAttachment.CFrame:Inverse()
local stacked = countStackedAccessories(character, sourceAttachment.Name)
if stacked > 0 then
handle.CFrame = handle.CFrame * CFrame.new(0, stacked * 0.15, 0)
end
else
targetPart = character:FindFirstChild("LowerTorso")
or character:FindFirstChild("Torso")
or rootPart
if not targetPart then accessory:Destroy(); return false end
handle.CFrame = rootPart.CFrame
end
weldPart(handle, targetPart)
table.insert(state.visuals, accessory)
return true
end
local function attachLooseVisual(rootObject, character, rootPart, assetId, textureId, targetPart)
local clone = rootObject:Clone()
sanitizeVisual(clone)
clone.Name = "VX7_LocalOutfit_" .. tostring(assetId)
clone:SetAttribute("VX7AssetId", assetId)
clone.Parent = character
local parts = {}
if clone:IsA("BasePart") then table.insert(parts, clone) end
for _, object in ipairs(clone:GetDescendants()) do
if object:IsA("BasePart") then table.insert(parts, object) end
end
if #parts == 0 then clone:Destroy(); return false end
local anchor = targetPart or rootPart
if textureId then
for _, part in ipairs(parts) do
if part:IsA("MeshPart") then
pcall(function() part.TextureID = "rbxassetid://" .. tostring(textureId) end)
end
end
end
local pivot = clone:IsA("Model") and clone:GetPivot() or parts[1].CFrame
for _, part in ipairs(parts) do
local offset = pivot:ToObjectSpace(part.CFrame)
part.CFrame = anchor.CFrame * offset
weldPart(part, anchor)
end
table.insert(state.visuals, clone)
return true
end
local function attachClassicClothingLocal(rootObject, character, assetId)
local candidates = {}
if rootObject:IsA("Shirt") or rootObject:IsA("Pants") or rootObject:IsA("ShirtGraphic") then
table.insert(candidates, rootObject)
end
for _, object in ipairs(rootObject:GetDescendants()) do
if object:IsA("Shirt") or object:IsA("Pants") or object:IsA("ShirtGraphic") then
table.insert(candidates, object)
end
end
local added = 0
for _, source in ipairs(candidates) do
for _, existing in ipairs(character:GetChildren()) do
if existing.ClassName == source.ClassName and not existing:GetAttribute("VX7LocalOnly") then
local property = existing:IsA("Shirt") and "ShirtTemplate"
or existing:IsA("Pants") and "PantsTemplate"
or "Graphic"
state.hidden[existing] = {property = property, value = existing[property]}
existing[property] = ""
end
end
local clone = source:Clone()
clone.Name = "VX7_LocalClothing_" .. tostring(assetId)
clone:SetAttribute("VX7AssetId", assetId)
clone:SetAttribute("VX7LocalOnly", true)
clone.Parent = character
table.insert(state.visuals, clone)
added = added + 1
end
return added
end
local function attachBodyPartsLocal(rootObject, character, assetId, textureId)
local holder = Instance.new("Model")
holder.Name = "VX7_LocalBody_" .. tostring(assetId)
holder:SetAttribute("VX7AssetId", assetId)
holder:SetAttribute("VX7LocalOnly", true)
holder.Parent = character
local bodyColors = rootObject:FindFirstChildOfClass("BodyColors")
local colorProperties = {
Head = "HeadColor", UpperTorso = "TorsoColor", LowerTorso = "TorsoColor", Torso = "TorsoColor",
LeftUpperArm = "LeftArmColor", LeftLowerArm = "LeftArmColor", LeftHand = "LeftArmColor", ["Left Arm"] = "LeftArmColor",
RightUpperArm = "RightArmColor", RightLowerArm = "RightArmColor", RightHand = "RightArmColor", ["Right Arm"] = "RightArmColor",
LeftUpperLeg = "LeftLegColor", LeftLowerLeg = "LeftLegColor", LeftFoot = "LeftLegColor", ["Left Leg"] = "LeftLegColor",
RightUpperLeg = "RightLegColor", RightLowerLeg = "RightLegColor", RightFoot = "RightLegColor", ["Right Leg"] = "RightLegColor",
}
local added = 0
local candidates = {}
if rootObject:IsA("BasePart") then table.insert(candidates, rootObject) end
for _, object in ipairs(rootObject:GetDescendants()) do
if object:IsA("BasePart") and not object:FindFirstAncestorWhichIsA("Accessory") then
table.insert(candidates, object)
end
end
for _, source in ipairs(candidates) do
local partName = source.Name
if BODY_PART_NAMES[partName] then
local target = character:FindFirstChild(partName)
if not target then
local alias = PART_NAME_ALIASES[partName]
if alias then target = character:FindFirstChild(alias) end
end
if target and target:IsA("BasePart") then
local clone = source:Clone()
for _, child in ipairs(clone:GetDescendants()) do
if child:IsA("JointInstance") or child:IsA("Constraint") or child:IsA("LuaSourceContainer") then
child:Destroy()
end
end
sanitizeVisual(clone)
clone.Name = source.Name
if clone:IsA("MeshPart") and textureId then
pcall(function() clone.TextureID = "rbxassetid://" .. tostring(textureId) end)
end
if bodyColors and colorProperties[source.Name] then
pcall(function() clone.Color = bodyColors[colorProperties[source.Name]].Color end)
end
clone.CFrame = target.CFrame
clone.Parent = holder
weldPart(clone, target)
added = added + 1
end
end
end
if added == 0 then holder:Destroy(); return 0 end
table.insert(state.visuals, holder)
return added
end
local assetInfoCache = {}
local ASSET_INFO_CACHE_FILE="luckbroomAvatarAssets.json"
pcall(function()
if isfile and readfile and isfile(ASSET_INFO_CACHE_FILE) then
local decoded=HttpService:JSONDecode(readfile(ASSET_INFO_CACHE_FILE))
if type(decoded)=="table" then for id,assetType in pairs(decoded) do
local numericId=tonumber(id);local numericType=tonumber(assetType)
if numericId and numericType then assetInfoCache[numericId]=numericType end end end end end)
local assetInfoSaveQueued=false
local function saveAssetInfoCache()
if assetInfoSaveQueued or not writefile then return end
assetInfoSaveQueued=true;task.delay(.4,function()
assetInfoSaveQueued=false;pcall(function()
local encoded={};for id,assetType in pairs(assetInfoCache) do encoded[tostring(id)]=assetType end
writefile(ASSET_INFO_CACHE_FILE,HttpService:JSONEncode(encoded)) end) end) end
local bodyPropertyByType = {
[17] = "Head", [27] = "Torso", [28] = "RightArm",
[29] = "LeftArm", [30] = "LeftLeg", [31] = "RightLeg", [79] = "Head",
}
local bodyPartAnchorNames = {
[17] = {"Head"}, [79] = {"Head"},
[27] = {"UpperTorso", "Torso"},
[28] = {"RightUpperArm", "Right Arm"},
[29] = {"LeftUpperArm", "Left Arm"},
[30] = {"LeftUpperLeg", "Left Leg"},
[31] = {"RightUpperLeg", "Right Leg"},
}
local accessoryTypeByAssetType = {
[8] = Enum.AccessoryType.Hat,
[41] = Enum.AccessoryType.Hair,
[42] = Enum.AccessoryType.Face,
[43] = Enum.AccessoryType.Neck,
[44] = Enum.AccessoryType.Shoulder,
[45] = Enum.AccessoryType.Front,
[46] = Enum.AccessoryType.Back,
[47] = Enum.AccessoryType.Waist,
[64] = Enum.AccessoryType.TShirt,
[65] = Enum.AccessoryType.Shirt,
[66] = Enum.AccessoryType.Pants,
[67] = Enum.AccessoryType.Jacket,
[68] = Enum.AccessoryType.Sweater,
[69] = Enum.AccessoryType.Shorts,
[70] = Enum.AccessoryType.LeftShoe,
[71] = Enum.AccessoryType.RightShoe,
[72] = Enum.AccessoryType.DressSkirt,
[76] = Enum.AccessoryType.Eyebrow,
[77] = Enum.AccessoryType.Eyelash,
}
local function getAssetTypeId(assetId)
if assetInfoCache[assetId] then return assetInfoCache[assetId] end
local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, assetId, Enum.InfoType.Asset)
if ok and info and info.AssetTypeId then
assetInfoCache[assetId] = info.AssetTypeId
saveAssetInfoCache()
return info.AssetTypeId
end
end
local accessoryDescriptionProperties = {
"BackAccessory", "FaceAccessory", "FrontAccessory", "HairAccessory",
"HatAccessory", "NeckAccessory", "ShouldersAccessory", "WaistAccessory",
"TShirtAccessory", "ShirtAccessory", "PantsAccessory", "JacketAccessory",
"SweaterAccessory", "ShortsAccessory", "DressSkirtAccessory",
"EyebrowAccessory", "EyelashAccessory",
}
local function createDirectDescription(option, humanoid)
local directOutfitId = option.outfitId
local completeOutfitDescription
if directOutfitId then
local ok, outfitDescription = pcall(
Players.GetHumanoidDescriptionFromOutfitId,
Players,
directOutfitId
)
if not ok or not outfitDescription then return nil end
completeOutfitDescription = outfitDescription
if not option.items and not option.face and not option.head then return outfitDescription end
end
local source = completeOutfitDescription or state.originalDescription
if not source then
local ok, applied = pcall(function() return humanoid:GetAppliedDescription() end)
if not ok or not applied then return nil end
source = applied
end
local description = source:Clone()
if completeOutfitDescription then completeOutfitDescription:Destroy() end
if not directOutfitId then
description.Shirt = 0
description.Pants = 0
description.GraphicTShirt = 0
for _, property in ipairs(accessoryDescriptionProperties) do
pcall(function() description[property] = "" end)
end
pcall(function() description:SetAccessories({}, true) end)
end
local accessories = {}
if directOutfitId then
pcall(function() accessories = description:GetAccessories(true) end)
end
local allItems = {}
for _, id in ipairs(option.bodyItems or {}) do table.insert(allItems, id) end
for _, id in ipairs(option.items or {}) do table.insert(allItems, id) end
for _, id in ipairs(allItems) do
local assetTypeId = getAssetTypeId(id)
if not assetTypeId then description:Destroy(); return nil end
local bodyProperty = bodyPropertyByType[assetTypeId]
local accessoryType = accessoryTypeByAssetType[assetTypeId]
if bodyProperty then
description[bodyProperty] = id
elseif assetTypeId == 11 then
description.Shirt = id
elseif assetTypeId == 12 then
description.Pants = id
elseif assetTypeId == 1 then
description.GraphicTShirt = id
elseif assetTypeId == 18 then
description.Face = id
elseif accessoryType then
local accessory = {
AssetId = id,
AccessoryType = accessoryType,
Order = #accessories + 1,
}
if assetTypeId >= 64 and assetTypeId <= 72 then
accessory.IsLayered = true
accessory.Puffiness = option.layeredPuffiness or 0
end
table.insert(accessories, accessory)
else
description:Destroy()
return nil
end
end
if option.face then
local faceTypeId = getAssetTypeId(option.face)
local faceBodyProperty = faceTypeId and bodyPropertyByType[faceTypeId]
local faceAccessoryType = faceTypeId and accessoryTypeByAssetType[faceTypeId]
if option.faceMode == "decal" then
if faceTypeId == 18 then description.Face = option.face end
elseif faceBodyProperty then
description[faceBodyProperty] = option.face
elseif faceAccessoryType then
table.insert(accessories, {
AssetId = option.face,
AccessoryType = faceAccessoryType,
Order = #accessories + 1,
})
elseif faceTypeId == 18 then
description.Face = option.face
end
end
if option.head then description.Head = option.head end
for property, value in pairs(option.scales or {}) do
pcall(function() description[property] = value end)
end
if option.skinColor then
for _, property in ipairs({"HeadColor", "LeftArmColor", "RightArmColor", "LeftLegColor", "RightLegColor", "TorsoColor"}) do
description[property] = option.skinColor
end
end
if #accessories > 0 then
local ok = pcall(function() description:SetAccessories(accessories, true) end)
if not ok then description:Destroy(); return nil end
end
return description
end
local statusText
local function setStatus(text, good)
if not statusText or not statusText.Parent then return end
statusText.Text = text
statusText.TextColor3 = good and Color3.fromRGB(215, 255, 222) or Color3.fromRGB(190, 190, 198)
end
local function applyOutfit()
local character, humanoid, rootPart = currentCharacter()
if not character or not humanoid or not rootPart then setStatus("Character not found", false); return false end
if state.descriptionCharacter ~= character or not state.originalDescription then
state.descriptionCharacter = character
state.originalDescription = nil
local ok, applied = pcall(function() return humanoid:GetAppliedDescription() end)
if ok and applied then state.originalDescription = applied:Clone() end
end
clearVisuals()
setStatus("Loading local visual...", false)
local option = OUTFITS[state.selected]
local assetId = option.id or option.outfitId
state.skipDescriptionRestore=option.preserveRig==true
if option.forceBodyParts or option.localOnly then
setStatus("Local visual only (no rig change)...", false)
end
if (option.bodyItems or option.items or option.outfitId) and not option.forceBodyParts and not option.localOnly then
setStatus(option.outfitId and "Loading complete outfit..." or "Applying outfit and complexion...", false)
local description = createDirectDescription(option, humanoid)
if description then
local savedHead = character:FindFirstChild("Head")
local savedHealth = humanoid.Health
state.savedWalkSpeed = humanoid.WalkSpeed
state.savedJumpPower = humanoid.JumpPower
local savedCFrame = rootPart.CFrame
local savedVelocity = rootPart.AssemblyLinearVelocity
local ok = pcall(function() humanoid:ApplyDescription(description) end)
if not ok then ok = pcall(function() humanoid:ApplyDescriptionReset(description) end) end
description:Destroy()
if ok then
local currentHumanoid = character:FindFirstChildOfClass("Humanoid")
local currentRoot = character:FindFirstChild("HumanoidRootPart")
if currentHumanoid and savedHealth > 0 then
currentHumanoid.Health = math.min(savedHealth, currentHumanoid.MaxHealth)
end
if currentRoot then
currentRoot.CFrame = savedCFrame
currentRoot.AssemblyLinearVelocity = savedVelocity
currentRoot.AssemblyAngularVelocity = Vector3.zero
end
if option.face then
local faceTypeId = getAssetTypeId(option.face)
if option.faceMode == "decal" or not faceTypeId or faceTypeId == 18 then
applyLocalFaceStable(character, option.face)
end
end
state.enabled = true
enforceStats(character)
enforceHeadless(character, option)
if option.hideLeftLeg then hideLeftLeg(character) end
if option.hideRightLeg then hideRightLeg(character) end
if option.head and character:FindFirstChild("Head") == savedHead then
hideOriginalHead(character)
end
setStatus(option.label .. " applied - native avatar method", true)
return true
end
end
setStatus("Native apply failed; using visual fallback...", false)
end
local assetIds = {}
for _, id in ipairs(option.items or {}) do table.insert(assetIds, id) end
if option.head then table.insert(assetIds, option.head) end
if #assetIds == 0 and assetId and not option.outfitId then table.insert(assetIds, assetId) end
local fallbackFaceType = option.face and getAssetTypeId(option.face)
local faceIsAccessory = option.faceMode ~= "decal"
and fallbackFaceType
and accessoryTypeByAssetType[fallbackFaceType] ~= nil
if faceIsAccessory then table.insert(assetIds, option.face) end
local attached, expected = 0, 0
local lastError
expected = expected + (option.face and not faceIsAccessory and 1 or 0)
for _, currentAssetId in ipairs(assetIds) do
local objects, method = loadAssetObjects(currentAssetId)
if objects then
for _, loadedRoot in ipairs(objects) do
local rootAttached = false
local bodyPartsAttached = false
local classics = {}
if loadedRoot:IsA("Shirt") or loadedRoot:IsA("Pants") or loadedRoot:IsA("ShirtGraphic") then
table.insert(classics, loadedRoot)
end
for _, object in ipairs(loadedRoot:GetDescendants()) do
if object:IsA("Shirt") or object:IsA("Pants") or object:IsA("ShirtGraphic") then
table.insert(classics, object)
end
end
local accessories = {}
if loadedRoot:IsA("Accessory") then
table.insert(accessories, loadedRoot)
else
for _, object in ipairs(loadedRoot:GetDescendants()) do
if object:IsA("Accessory") then table.insert(accessories, object:Clone()) end
end
end
local assetTypeId = getAssetTypeId(currentAssetId)
local isBodyPartAsset = assetTypeId ~= nil and bodyPropertyByType[assetTypeId] ~= nil
local bodyCandidates = 0
local wantsBodyParts = not loadedRoot:IsA("Accessory")
and (option.hideOriginal or option.hideOriginalHead or currentAssetId == option.head or (option.forceBodyParts and isBodyPartAsset))
if wantsBodyParts then
local candidates = {}
if loadedRoot:IsA("BasePart") then table.insert(candidates, loadedRoot) end
for _, object in ipairs(loadedRoot:GetDescendants()) do
if object:IsA("BasePart") and not object:FindFirstAncestorWhichIsA("Accessory") then
table.insert(candidates, object)
end
end
for _, object in ipairs(candidates) do
if BODY_PART_NAMES[object.Name] or PART_NAME_ALIASES[object.Name] then bodyCandidates = bodyCandidates + 1 end
end
end
expected = expected + #classics + #accessories + bodyCandidates
if #accessories == 0 and #classics == 0 and bodyCandidates == 0 then expected = expected + 1 end
if #classics > 0 then
local ok, result = pcall(attachClassicClothingLocal, loadedRoot, character, currentAssetId)
if ok and result and result > 0 then attached = attached + result; rootAttached = true end
end
if wantsBodyParts and bodyCandidates > 0 then
local ok, result = pcall(attachBodyPartsLocal, loadedRoot, character, currentAssetId, option.headTexture)
if ok and result and result > 0 then
attached = attached + result
rootAttached = true
bodyPartsAttached = true
end
end
for _, accessory in ipairs(accessories) do
local ok, result = pcall(attachAccessoryLocal, accessory, character, rootPart, currentAssetId)
if ok and result then
attached = attached + 1
rootAttached = true
else
pcall(function() accessory:Destroy() end)
end
end
if not rootAttached and not bodyPartsAttached and #accessories == 0 and #classics == 0 then
local headAnchor = character:FindFirstChild("Head")
local anchor = rootPart
if currentAssetId == option.head then
anchor = headAnchor
elseif isBodyPartAsset then
local anchorNames = bodyPartAnchorNames[assetTypeId]
if anchorNames then
for _, name in ipairs(anchorNames) do
local target = character:FindFirstChild(name)
if target and target:IsA("BasePart") then anchor = target; break end
end
end
end
local ok, result = pcall(attachLooseVisual, loadedRoot, character, rootPart, currentAssetId, option.headTexture, anchor)
if ok and result then attached = attached + 1 end
end
if loadedRoot.Parent == nil and not table.find(state.visuals, loadedRoot) then
pcall(function() loadedRoot:Destroy() end)
end
end
else
lastError = method
end
end
local faceApplied = false
if option.face and not faceIsAccessory then
local ok, result = pcall(applyLocalFace, character, option.face)
faceApplied = ok and result == true
end
local headlessApplied = false
if option.headless then
enforceHeadless(character, option)
headlessApplied = true
end
local legApplied = false
if option.hideLeftLeg then
hideLeftLeg(character)
legApplied = true
end
if option.hideRightLeg then
hideRightLeg(character)
legApplied = true
end
local totalItems = expected
local loadedItems = attached + (faceApplied and 1 or 0)
state.enabled = attached > 0 or faceApplied or headlessApplied or legApplied
if state.enabled then
if option.preserveRig and (option.hideLeftLeg or option.hideRightLeg) then enforceHeadless(character,option) end
if option.hideOriginal then hideOriginalBody(character) end
if option.hideOriginalHead then hideOriginalHead(character) end
if option.head then hideOriginalHead(character) end
if option.clearOriginalWearables then hideOriginalWearables(character, true) end
setStatus(string.format("%s fallback - %d/%d items", option.label, loadedItems, totalItems), loadedItems == totalItems)
else
setStatus("Could not attach outfit - " .. tostring(lastError or "no 3D parts"), false)
end
return state.enabled
end
local function restoreOriginalDescription()
local description = state.originalDescription
local character = LP.Character
local humanoid = character and character:FindFirstChildOfClass("Humanoid")
if description and humanoid and character == state.descriptionCharacter and not state.skipDescriptionRestore then
local clone = description:Clone()
local ok = pcall(function() humanoid:ApplyDescription(clone) end)
if not ok then pcall(function() humanoid:ApplyDescriptionReset(clone) end) end
clone:Destroy()
end
if state.originalDescription then state.originalDescription:Destroy() end
state.originalDescription = nil
state.descriptionCharacter = nil
state.skipDescriptionRestore=false
end
local function removeOutfit()
state.enabled = false
clearVisuals()
restoreOriginalDescription()
setStatus("Local visual removed", true)
end
return {
outfits = OUTFITS,
apply = function(index)
state.selected = math.clamp(math.floor(tonumber(index) or 1), 1, #OUTFITS)
return applyOutfit()
end,
remove = removeOutfit,
description = function(index)
local character = LP.Character
local humanoid = character and character:FindFirstChildOfClass("Humanoid")
local option = OUTFITS[math.clamp(math.floor(tonumber(index) or 1), 1, #OUTFITS)]
if not humanoid or not option then return nil end
local strict = createDirectDescription(option, humanoid)
if strict then return strict end
local ok, applied = pcall(function() return humanoid:GetAppliedDescription() end)
if not ok or not applied then return nil end
local description = applied:Clone(); applied:Destroy()
description.Shirt=0; description.Pants=0; description.GraphicTShirt=0
for _,property in ipairs(accessoryDescriptionProperties) do pcall(function() description[property]="" end) end
pcall(function() description:SetAccessories({},true) end)
local accessories={}; local all={}
for _,id in ipairs(option.bodyItems or {}) do table.insert(all,id) end
for _,id in ipairs(option.items or {}) do table.insert(all,id) end
for _,id in ipairs(all) do
local assetTypeId=getAssetTypeId(id); local bodyProperty=assetTypeId and bodyPropertyByType[assetTypeId]; local accessoryType=assetTypeId and accessoryTypeByAssetType[assetTypeId]
if bodyProperty then description[bodyProperty]=id elseif assetTypeId==11 then description.Shirt=id elseif assetTypeId==12 then description.Pants=id elseif assetTypeId==1 then description.GraphicTShirt=id elseif assetTypeId==18 then description.Face=id elseif accessoryType then
table.insert(accessories,{AssetId=id,AccessoryType=accessoryType,Order=#accessories+1,IsLayered=assetTypeId>=64 and assetTypeId<=72,Puffiness=option.layeredPuffiness or 0}) end
end
if option.face then local faceType=getAssetTypeId(option.face); if faceType==18 then description.Face=option.face elseif faceType and bodyPropertyByType[faceType] then description[bodyPropertyByType[faceType]]=option.face elseif faceType and accessoryTypeByAssetType[faceType] then table.insert(accessories,{AssetId=option.face,AccessoryType=accessoryTypeByAssetType[faceType],Order=#accessories+1}) end end
if option.head then description.Head=option.head end
for property,value in pairs(option.scales or {}) do pcall(function() description[property]=value end) end
if #accessories>0 then pcall(function() description:SetAccessories(accessories,true) end) end
return description
end,
previewModel = function(index)
local option=OUTFITS[math.clamp(math.floor(tonumber(index) or 1),1,#OUTFITS)]; local character=LP.Character
if not option or not character then return nil end
local oldArchivable=character.Archivable; character.Archivable=true; local ok,clone=pcall(function() return character:Clone() end); character.Archivable=oldArchivable
if not ok or not clone then return nil end
for _,child in ipairs(clone:GetChildren()) do
if child:IsA("Accessory") or child:IsA("Accoutrement") or child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic") or child:IsA("CharacterMesh") or child:IsA("Tool") then child:Destroy() end
end
for _,object in ipairs(clone:GetDescendants()) do if object:IsA("LuaSourceContainer") then object:Destroy() elseif object:IsA("BasePart") then object.Transparency=object.Name=="HumanoidRootPart" and 1 or 0; object.LocalTransparencyModifier=0 end end
local root=clone:FindFirstChild("HumanoidRootPart") or clone:FindFirstChild("LowerTorso") or clone:FindFirstChild("Torso")
if not root then clone:Destroy(); return nil end
local savedVisuals,savedHidden,savedWearable=state.visuals,state.hidden,state.wearableConn; state.visuals={}; state.hidden={}; state.wearableConn=nil
local ids={}; for _,id in ipairs(option.bodyItems or {}) do table.insert(ids,id) end; for _,id in ipairs(option.items or {}) do table.insert(ids,id) end
if option.head then table.insert(ids,option.head) end; if option.face and option.faceMode~="decal" then table.insert(ids,option.face) end
for _,id in ipairs(ids) do
local objects=loadAssetObjects(id)
if objects then for _,loadedRoot in ipairs(objects) do
pcall(attachClassicClothingLocal,loadedRoot,clone,id)
local accessories={}; if loadedRoot:IsA("Accessory") then table.insert(accessories,loadedRoot) else for _,object in ipairs(loadedRoot:GetDescendants()) do if object:IsA("Accessory") then table.insert(accessories,object:Clone()) end end end
for _,accessory in ipairs(accessories) do pcall(attachAccessoryLocal,accessory,clone,root,id) end
local isBody=table.find(option.bodyItems or {},id)~=nil or id==option.head
if isBody then pcall(attachBodyPartsLocal,loadedRoot,clone,id,option.headTexture) end
if loadedRoot.Parent and not table.find(state.visuals,loadedRoot) then pcall(function() loadedRoot:Destroy() end) end
end end
end
state.visuals,state.hidden,state.wearableConn=savedVisuals,savedHidden,savedWearable
if option.face and option.faceMode=="decal" then local head=clone:FindFirstChild("Head"); if head then local face=head:FindFirstChild("face") or head:FindFirstChildWhichIsA("Decal"); if not face then face=Instance.new("Decal"); face.Name="face"; face.Face=Enum.NormalId.Front; face.Parent=head end; face.Texture=resolveFaceTexture(option.face); face.Transparency=0 end end
if option.headless or option.hideOriginalHead then local head=clone:FindFirstChild("Head"); if head then head.Transparency=1; for _,v in ipairs(head:GetDescendants()) do if v:IsA("Decal") or v:IsA("Texture") then v.Transparency=1 end end end end
if option.hideRightLeg then for _,name in ipairs({"RightUpperLeg","RightLowerLeg","RightFoot","Right Leg"}) do local part=clone:FindFirstChild(name); if part then part.Transparency=1 end end end
return clone
end,
cleanup = function()
state.enabled = false
clearVisuals()
restoreOriginalDescription()
end,
}
]==]

function VX7A.load()
    if VX7A.mod then return VX7A.mod end
    if VX7A.loading or type(loadstring) ~= "function" then return nil end
    VX7A.loading = true
    local ok, fn = pcall(loadstring, VX7A.src)
    if ok and type(fn) == "function" then
        local ok2, res = pcall(fn)
        if ok2 and type(res) == "table" then VX7A.mod = res end
    end
    VX7A.loading = false
    return VX7A.mod
end

function VX7A.setLabel()
    if VX7A.label and VX7A.label.Parent then
        VX7A.label.Text = VX7A.labels[VX7A.index + 1] or "OFF"
    end
end

function VX7A.stop()
    VX7A.pending = nil
    if VX7A.index ~= 0 then
        VX7A.index = 0
        local m = VX7A.mod
        if m and m.remove then pcall(m.remove) end
    end
    VX7A.setLabel()
end

function VX7A.apply(index)
    index = math.clamp(math.floor(tonumber(index) or 0), 0, #VX7A.labels - 1)
    if index == 0 then VX7A.stop() return end
    local m = VX7A.load()
    if not m or type(m.apply) ~= "function" then
        warn("[luckbroom] No se pudo cargar el modulo de avatares VX7 (loadstring no disponible).")
        VX7A.setLabel()
        return
    end
    if VX7A.busy then VX7A.pending = index; VX7A.index = index; VX7A.setLabel() return end
    if currentOutfitIndex ~= 1 then
        currentOutfitIndex = 1
        pcall(function() applyOutfitByIndex(1) end)
        if outfitSelectorLabel then outfitSelectorLabel.Text = OUTFITS[1].label end
    end
    VX7A.index = index
    VX7A.setLabel()
    VX7A.busy = true
    task.spawn(function()
        pcall(m.apply, index)
        VX7A.busy = false
        local nxt = VX7A.pending
        VX7A.pending = nil
        if nxt and nxt ~= 0 and VX7A.index == nxt then VX7A.apply(nxt) end
    end)
end

pcall(function()
    LP.CharacterAdded:Connect(function()
        if _G.luckbroomSession ~= _mySession or VX7A.index == 0 then return end
        task.delay(1.5, function()
            if _G.luckbroomSession == _mySession and VX7A.index ~= 0 then VX7A.apply(VX7A.index) end
        end)
    end)
end)

local function loadObjectsStd(id)
    local ok, res = pcall(function() return game:GetObjects("rbxassetid://" .. tostring(id)) end)
    if ok and typeof(res) == "table" and #res > 0 then return res end
    ok, res = pcall(function() return game:GetService("InsertService"):LoadAsset(id) end)
    if ok and res then return {res} end
    return nil
end
local function resolveBubbleTemplate(id, className, propertyName)
    local fallback = "rbxassetid://" .. tostring(id)
    local ok, objects = pcall(function() return game:GetObjects(fallback) end)
    if ok and objects and objects[1] then
        local item = objects[1]
        local obj = item:IsA(className) and item or item:FindFirstChildWhichIsA(className, true)
        if obj and obj[propertyName] and obj[propertyName] ~= "" then fallback = obj[propertyName] end
        for _, v in ipairs(objects) do pcall(function() v:Destroy() end) end
    end
    return fallback
end
local function addBubbleHair(char, assetId)
    local head = char and char:FindFirstChild("Head")
    if not head then return false end
    local objects = loadObjectsStd(assetId)
    if not objects or not objects[1] then return false end
    local source = objects[1]
    local accessory = source:IsA("Accessory") and source or source:FindFirstChildWhichIsA("Accessory", true)
    if not accessory then
        for _, v in ipairs(objects) do pcall(function() v:Destroy() end) end
        return false
    end
    local hair = accessory:Clone()
    hair.Name = "BubbleSkinChanger_Hair"
    for _, part in ipairs(hair:GetDescendants()) do
        if part:IsA("BasePart") then part.Anchored = false; part.CanCollide = false; part.Massless = true; part.LocalTransparencyModifier = 0 end
    end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local ok = pcall(function() if humanoid then humanoid:AddAccessory(hair) else hair.Parent = char end end)
    if not ok then pcall(function() hair:Destroy() end) end
    for _, v in ipairs(objects) do pcall(function() v:Destroy() end) end
    return ok
end
local function applyHeadlessKorblox(char)
    if not char then return end
    pcall(function() LP.CharacterAvatarType = Enum.AvatarType.R6 end)
    local head = char:FindFirstChild("Head")
    if head then
        if head:GetAttribute("luckbroomOutfitOriginalTransparency") == nil then
            head:SetAttribute("luckbroomOutfitOriginalTransparency", head.Transparency)
            head:SetAttribute("luckbroomOutfitOriginalLocalTransparency", head.LocalTransparencyModifier)
        end
        head.Transparency = 1
        head.CanCollide = false
        head.LocalTransparencyModifier = 1
        local face = head:FindFirstChild("face")
        if face then face.Transparency = 1 end
    end
    pcall(function()
        local neck = char:FindFirstChild("Neck")
        if neck then neck.Enabled = false end
    end)
    for _, v in pairs(char:GetChildren()) do
        if v:IsA("Accessory") then
            local w = v:FindFirstChildWhichIsA("Weld") or v:FindFirstChildWhichIsA("WeldConstraint") or v:FindFirstChildWhichIsA("Motor6D")
            if w then
                local p0, p1 = w.Part0, w.Part1
                if (p0 and p0.Name == "Head") or (p1 and p1.Name == "Head") then
                    for _, part in ipairs(v:GetDescendants()) do
                        if part:IsA("BasePart") then
                            if part:GetAttribute("luckbroomOutfitOriginalTransparency") == nil then
                                part:SetAttribute("luckbroomOutfitOriginalTransparency", part.Transparency)
                                part:SetAttribute("luckbroomOutfitOriginalLocalTransparency", part.LocalTransparencyModifier)
                            end
                            part.Transparency = 1
                            part.LocalTransparencyModifier = 1
                        end
                    end
                end
            end
        end
    end
    local rightLegConfig = { id = "rbxassetid://139607718", targetBodyPart = "RightUpperLeg", partsToHide = {"RightUpperLeg", "RightLowerLeg", "RightFoot"}, scale = _V3new(1, 1, 1), offset = _CFnew(0, 0, 0) }
    local targetPart = char:FindFirstChild(rightLegConfig.targetBodyPart)
    if targetPart then
        local oldAsset = char:FindFirstChild("Korblox_RightLeg")
        if oldAsset then oldAsset:Destroy() end
        for _, partName in ipairs(rightLegConfig.partsToHide) do
            local limb = char:FindFirstChild(partName)
            if limb and limb:IsA("BasePart") then
                if limb:GetAttribute("luckbroomOutfitOriginalTransparency") == nil then
                    limb:SetAttribute("luckbroomOutfitOriginalTransparency", limb.Transparency)
                end
                limb.Transparency = 1
            end
        end
        local success, objects = pcall(function() return game:GetObjects(rightLegConfig.id) end)
        if success and objects and #objects > 0 then
            local assetModel = objects[1]
            assetModel.Name = "Korblox_RightLeg"
            local mainMesh = assetModel:IsA("BasePart") and assetModel or assetModel:FindFirstChildWhichIsA("BasePart", true)
            if mainMesh then
                mainMesh.Size = mainMesh.Size * rightLegConfig.scale
                mainMesh.CanCollide = false
                mainMesh.CFrame = targetPart.CFrame * rightLegConfig.offset
                local weld = Instance.new("WeldConstraint")
                weld.Part0 = targetPart
                weld.Part1 = mainMesh
                weld.Parent = mainMesh
                assetModel.Parent = char
            end
        end
    end
end

function applyOutfitByIndex(index)
    local cfg = OUTFITS[index]
    if not cfg then return end
    local char =
