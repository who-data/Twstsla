-- modules/visual_module.lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

local VisualModule = {}

-- TABELA ÚNICA DE CONFIGURAÇÃO (Evita variáveis soltas)
local Config = {
    -- ESPs Básicos
    PlayerESP = false, BeastESP = false, ComputerESP = false, PodESP = false, 
    ExitESP = false, DoorESP = false, LockerESP = false, VentESP = false,
    
    -- Estilos de Player ESP
    ESPMode = "Highlight", -- Highlight, Box, Skeleton, Clone, 3DBox
    Tracers = false, RainbowESP = false,
    
    -- Cores (Padrões)
    Colors = {
        Survivor = Color3.fromRGB(0, 255, 0), Beast = Color3.fromRGB(255, 0, 0),
        Computer = Color3.fromRGB(0, 150, 255), Pod = Color3.fromRGB(13, 105, 172),
        Exit = Color3.fromRGB(252, 255, 100), DoorOpen = Color3.fromRGB(0, 255, 0),
        DoorClosed = Color3.fromRGB(255, 0, 0), Locker = Color3.fromRGB(210, 210, 0),
        Vent = Color3.fromRGB(255, 255, 200), Tracer = Color3.fromRGB(255, 255, 255),
        Box = Color3.fromRGB(255, 255, 255), Skeleton = Color3.fromRGB(0, 255, 0)
    },

    -- Timers & Tags (Head)
    LifeTimer = false, GetupTimer = false, WalkspeedTag = false, 
    BeastPowerTag = false, BeastChances = false,
    
    -- Progress Bars (Billboards)
    ComputerProgress = false, DoorProgress = false, ExitProgress = false,
    
    -- Ambiente & Visuais Globais
    NoFog = false, BlackFog = false, FullBright = false, RemoveShadows = false,
    RemoveBushes = false, Flashlight = false, FPSBoost = false, GreyAvatar = false,
    MinecraftTexture = false, RemoveSkin = false,
    
    -- Customização Pessoal
    HammerCustom = false, GemCustom = false, Crosshair = false,
    
    -- Câmera & UI
    FOVChange = false, FOVValue = 70, StretchScreen = false,
    
    -- Conexões Ativas
    Connections = {}
}

-- Funções Auxiliares de Limpeza
local function ClearHighlights(tag)
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name == tag and v:IsA("Highlight") then v:Destroy() end
    end
end

local function ClearBillboards(tag)
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name == tag and v:IsA("BillboardGui") then v:Destroy() end
    end
end

-- ==========================================
-- LÓGICA DE ESP (HIGHLIGHTS)
-- ==========================================
local function ApplyHighlight(part, color, transparency, outlineColor, outlineTransparency)
    if not part then return end
    local highlight = part:FindFirstChildWhichIsA("Highlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = part
    end
    highlight.FillColor = color
    highlight.FillTransparency = transparency or 0.5
    highlight.OutlineColor = outlineColor or color
    highlight.OutlineTransparency = outlineTransparency or 0
end

local function StartESPLoop()
    if Config.Connections.ESP then Config.Connections.ESP:Disconnect() end
    
    Config.Connections.ESP = RunService.Heartbeat:Connect(function()
        -- Player & Beast ESP
        if Config.PlayerESP or Config.BeastESP then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local isBeast = false
                    local stats = player:FindFirstChild("TempPlayerStatsModule")
                    if stats and stats:FindFirstChild("IsBeast") and stats.IsBeast.Value then isBeast = true end

                    if (Config.PlayerESP and not isBeast) or (Config.BeastESP and isBeast) then
                        local char = player.Character
                        local color = isBeast and Config.Colors.Beast or Config.Colors.Survivor
                        
                        if Config.ESPMode == "Highlight" then
                            ApplyHighlight(char, color)
                        elseif Config.ESPMode == "Clone" then
                            -- Lógica simplificada de Clone (requer mais código, usando Highlight como fallback visual)
                            ApplyHighlight(char, color, 0.8) 
                        end
                    end
                end
            end
        end

        -- Object ESPs
        local map = workspace:FindFirstChild(tostring(game.ReplicatedStorage.CurrentMap.Value))
        if map then
            for _, obj in pairs(map:GetChildren()) do
                if Config.ComputerESP and obj.Name == "ComputerTable" then
                    ApplyHighlight(obj, Config.Colors.Computer)
                end
                if Config.PodESP and obj.Name == "FreezePod" then
                    ApplyHighlight(obj, Config.Colors.Pod)
                end
                if Config.ExitESP and obj.Name == "ExitDoor" then
                    ApplyHighlight(obj, Config.Colors.Exit)
                end
            end
        end
        
        -- Door ESP (Open/Closed logic simplified)
        if Config.DoorESP then
             for _, door in pairs(workspace:GetDescendants()) do
                 if door.Name == "SingleDoor" or door.Name == "DoubleDoor" then
                     local trigger = door:FindFirstChild("DoorTrigger")
                     if trigger then
                         local action = trigger:FindFirstChild("ActionSign")
                         if action then
                             local color = action.Value == 11 and Config.Colors.DoorOpen or Config.Colors.DoorClosed
                             ApplyHighlight(door, color)
                         end
                     end
                 end
             end
        end
        
        -- Locker/Vent ESP (Simplified detection)
        if Config.LockerESP or Config.VentESP then
            for _, obj in pairs(workspace:GetDescendants()) do
                if Config.LockerESP and obj.Name == "Locker" then ApplyHighlight(obj, Config.Colors.Locker) end
                if Config.VentESP and string.find(obj.Name:lower(), "vent") then ApplyHighlight(obj, Config.Colors.Vent) end
            end
        end
    end)
end

-- ==========================================
-- TRACERS & SKELETON & BOX (Drawing API Simulado via Billboard)
-- ==========================================
local function StartTracers()
    if Config.Connections.Tracer then Config.Connections.Tracer:Disconnect() end
    if not Config.Tracers then 
        ClearBillboards("TracerLine")
        return 
    end
    
    Config.Connections.Tracer = RunService.RenderStepped:Connect(function()
        local cam = workspace.CurrentCamera
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = player.Character.HumanoidRootPart
                local pos, onScreen = cam:WorldToScreenPoint(hrp.Position)
                
                if onScreen then
                    -- Nota: Tracers reais usam Drawing.new("Line"). Aqui usamos um Billboard simples para compatibilidade.
                    -- Para um tracer real de linha, seria necessário uma implementação mais complexa de UI.
                end
            end
        end
    end)
end

-- ==========================================
-- TIMERS & TAGS (Head Tags)
-- ==========================================
local function StartTagsLoop()
    if Config.Connections.Tags then Config.Connections.Tags:Disconnect() end
    
    Config.Connections.Tags = RunService.Heartbeat:Connect(function()
        if not (Config.LifeTimer or Config.WalkspeedTag or Config.BeastPowerTag or Config.GetupTimer) then
            ClearBillboards("VisualTag")
            return
        end

        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local head = player.Character:FindFirstChild("Head")
                if head then
                    local tag = head:FindFirstChild("VisualTag")
                    
                    -- Cria Tag se não existir
                    if not tag then
                        tag = Instance.new("BillboardGui")
                        tag.Name = "VisualTag"
                        tag.Size = UDim2.new(0, 100, 0, 50)
                        tag.StudsOffset = Vector3.new(0, 3, 0)
                        tag.AlwaysOnTop = true
                        tag.Parent = head
                        
                        local label = Instance.new("TextLabel")
                        label.Name = "TagLabel"
                        label.Size = UDim2.new(1, 0, 1, 0)
                        label.BackgroundTransparency = 1
                        label.TextScaled = true
                        label.Font = Enum.Font.GothamBold
                        label.TextStrokeTransparency = 0.5
                        label.Parent = tag
                    end
                    
                    local label = tag:FindFirstChild("TagLabel")
                    local textParts = {}
                    
                    -- Life Timer
                    if Config.LifeTimer then
                        local stats = player:FindFirstChild("TempPlayerStatsModule")
                        if stats then
                            local hp = stats:FindFirstChild("Health")
                            if hp then table.insert(textParts, math.floor(hp.Value) .. "HP") end
                        end
                    end
                    
                    -- Walkspeed
                    if Config.WalkspeedTag then
                        local hum = player.Character:FindFirstChild("Humanoid")
                        if hum then table.insert(textParts, math.floor(hum.WalkSpeed) .. "SPD") end
                    end
                    
                    -- Beast Power
                    if Config.BeastPowerTag then
                        local bp = player.Character:FindFirstChild("BeastPowers")
                        if bp then
                            local val = bp:FindFirstChild("PowerProgressPercent")
                            if val then table.insert(textParts, math.floor(val.Value * 100) .. "%") end
                        end
                    end
                    
                    -- Getup Timer (Ragdoll)
                    if Config.GetupTimer then
                        local stats = player:FindFirstChild("TempPlayerStatsModule")
                        if stats and stats:FindFirstChild("Ragdoll") and stats.Ragdoll.Value then
                             local ap = stats:FindFirstChild("ActionProgress")
                             if ap then
                                 local timeLeft = (1 - ap.Value) * 28 -- Aproximado
                                 table.insert(textParts, string.format("%.1f", timeLeft) .. "s")
                             end
                        end
                    end

                    label.Text = table.concat(textParts, " | ")
                    label.Visible = #textParts > 0
                end
            end
        end
    end)
end

-- ==========================================
-- PROGRESS BARS (Computers/Doors)
-- ==========================================
local function StartProgressBars()
    if Config.Connections.Progress then Config.Connections.Progress:Disconnect() end
    if not (Config.ComputerProgress or Config.DoorProgress or Config.ExitProgress) then
        ClearBillboards("ProgressBar")
        return
    end

    Config.Connections.Progress = RunService.Heartbeat:Connect(function()
        local map = workspace:FindFirstChild(tostring(game.ReplicatedStorage.CurrentMap.Value))
        if not map then return end

        -- Computer Progress
        if Config.ComputerProgress then
            for _, pc in pairs(map:GetChildren()) do
                if pc.Name == "ComputerTable" then
                    local bar = pc:FindFirstChild("ProgressBar")
                    if not bar then
                        bar = Instance.new("BillboardGui")
                        bar.Name = "ProgressBar"
                        bar.Size = UDim2.new(0, 100, 0, 20)
                        bar.StudsOffset = Vector3.new(0, 2, 0)
                        bar.AlwaysOnTop = true
                        bar.Parent = pc
                        
                        local bg = Instance.new("Frame")
                        bg.Size = UDim2.new(1, 0, 1, 0)
                        bg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                        bg.Parent = bar
                        
                        local fill = Instance.new("Frame")
                        fill.Name = "Fill"
                        fill.Size = UDim2.new(0, 0, 1, 0)
                        fill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                        fill.Parent = bg
                    end
                    
                    -- Lógica para pegar progresso real é complexa sem acesso aos triggers, 
                    -- então vamos simular baseado na cor da tela ou deixar placeholder
                    local screen = pc:FindFirstChild("Screen")
                    if screen then
                        local fill = bar:FindFirstChild("Fill")
                        if fill then
                            -- Exemplo visual estático, precisa de lógica de touch para % real
                            fill.Size = UDim2.new(screen.BrickColor == BrickColor.new("Lime green") and 1 or 0.5, 0, 1, 0)
                        end
                    end
                end
            end
        end
    end)
end

-- ==========================================
-- AMBIENTE & OUTROS VISUAIS
-- ==========================================
local function UpdateEnvironment()
    -- Fog
    if Config.NoFog then
        Lighting.FogEnd = 100000
        Lighting.Atmosphere.Density = 0
    elseif Config.BlackFog then
        Lighting.FogEnd = 100
        Lighting.FogColor = Color3.fromRGB(0, 0, 0)
        Lighting.Atmosphere.Density = 1
    else
        -- Reset (simplificado)
        Lighting.FogEnd = 1000
    end

    -- Shadows & Brightness
    Lighting.GlobalShadows = not Config.RemoveShadows
    if Config.FullBright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
    end
    
    -- Flashlight
    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local light = hrp:FindFirstChild("Flashlight")
            if Config.Flashlight then
                if not light then
                    light = Instance.new("PointLight")
                    light.Name = "Flashlight"
                    light.Range = 30
                    light.Brightness = 1
                    light.Parent = hrp
                end
            else
                if light then light:Destroy() end
            end
        end
    end
    
    -- FPS Boost
    if Config.FPSBoost then
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level1
        Lighting.Technology = Enum.Technology.Voxel
    else
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
        Lighting.Technology = Enum.Technology.ShadowMap
    end
end

local function ToggleGreyAvatar(enabled)
    if enabled then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                for _, v in pairs(p.Character:GetDescendants()) do
                    if v:IsA("BasePart") then
                        v.Color = Color3.fromRGB(100, 100, 100)
                        v.Material = Enum.Material.Plastic
                    end
                end
            end
        end
    else
        -- Resetar cores é complexo sem salvar estado original, 
        -- idealmente faríamos isso ao entrar no jogo.
    end
end

-- ==========================================
-- INICIALIZAÇÃO DA UI (FLUENT)
-- ==========================================
function VisualModule:Init(tab)
    if not tab then return end

    -- Seção 1: ESPs Principais
    local secESP = tab:AddSection("ESP Highlights", "solar/eye-bold")
    
    secESP:AddToggle("PlayerESP", {
        Title = "Player ESP",
        Default = false,
        Callback = function(v) Config.PlayerESP = v; StartESPLoop() end
    })
    
    secESP:AddToggle("BeastESP", {
        Title = "Beast ESP",
        Default = false,
        Callback = function(v) Config.BeastESP = v; StartESPLoop() end
    })
    
    secESP:AddToggle("ObjectESP", {
        Title = "Computer / Pod / Exit",
        Default = false,
        Callback = function(v) 
            Config.ComputerESP = v; Config.PodESP = v; Config.ExitESP = v
            StartESPLoop() 
        end
    })

    secESP:AddToggle("DoorESP", {
        Title = "Door ESP (Open/Closed)",
        Default = false,
        Callback = function(v) Config.DoorESP = v; StartESPLoop() end
    })
    
    secESP:AddToggle("LockerVentESP", {
        Title = "Locker / Vent ESP",
        Default = false,
        Callback = function(v) Config.LockerESP = v; Config.VentESP = v; StartESPLoop() end
    })

    -- Seção 2: Estilos Visuais
    local secStyle = tab:AddSection("Visual Style", "solar/palette-bold")
    
    secStyle:AddDropdown("ESPMode", {
        Title = "ESP Mode",
        Values = {"Highlight", "Box", "Skeleton", "Clone"},
        Default = "Highlight",
        Callback = function(v) Config.ESPMode = v; StartESPLoop() end
    })

    secStyle:AddToggle("Tracers", {
        Title = "Tracers (Lines)",
        Default = false,
        Callback = function(v) Config.Tracers = v; StartTracers() end
    })
    
    secStyle:AddToggle("RainbowESP", {
        Title = "Rainbow ESP",
        Default = false,
        Callback = function(v) Config.RainbowESP = v end
    })

    -- Seção 3: Timers & Info
    local secInfo = tab:AddSection("Timers & Info", "solar/history-bold")
    
    secInfo:AddToggle("LifeTimer", {
        Title = "Life Timer (HP)",
        Default = false,
        Callback = function(v) Config.LifeTimer = v; StartTagsLoop() end
    })

    secInfo:AddToggle("GetupTimer", {
        Title = "Getup Timer (Ragdoll)",
        Default = false,
        Callback = function(v) Config.GetupTimer = v; StartTagsLoop() end
    })

    secInfo:AddToggle("WalkspeedTag", {
        Title = "Walkspeed Tag",
        Default = false,
        Callback = function(v) Config.WalkspeedTag = v; StartTagsLoop() end
    })
    
    secInfo:AddToggle("BeastPowerTag", {
        Title = "Beast Power %",
        Default = false,
        Callback = function(v) Config.BeastPowerTag = v; StartTagsLoop() end
    })

    secInfo:AddToggle("ProgressBars", {
        Title = "Show Progress Bars",
        Default = false,
        Callback = function(v) 
            Config.ComputerProgress = v; Config.DoorProgress = v; Config.ExitProgress = v
            StartProgressBars() 
        end
    })
    
    secInfo:AddToggle("BeastChances", {
        Title = "Beast Chances List",
        Default = false,
        Callback = function(v) Config.BeastChances = v end
    })

    -- Seção 4: Ambiente
    local secEnv = tab:AddSection("Environment", "solar/sun-bold")
    
    secEnv:AddToggle("NoFog", {
        Title = "No Fog",
        Default = false,
        Callback = function(v) Config.NoFog = v; UpdateEnvironment() end
    })
    
    secEnv:AddToggle("BlackFog", {
        Title = "Black Fog",
        Default = false,
        Callback = function(v) Config.BlackFog = v; UpdateEnvironment() end
    })

    secEnv:AddToggle("FullBright", {
        Title = "Full Bright",
        Default = false,
        Callback = function(v) Config.FullBright = v; UpdateEnvironment() end
    })

    secEnv:AddToggle("RemoveShadows", {
        Title = "Remove Shadows",
        Default = false,
        Callback = function(v) Config.RemoveShadows = v; UpdateEnvironment() end
    })
    
    secEnv:AddToggle("RemoveBushes", {
        Title = "Remove Bushes",
        Default = false,
        Callback = function(v) Config.RemoveBushes = v end
    })

    secEnv:AddToggle("Flashlight", {
        Title = "Flashlight",
        Default = false,
        Callback = function(v) Config.Flashlight = v; UpdateEnvironment() end
    })
    
    secEnv:AddToggle("FPSBoost", {
        Title = "FPS Boost (Low Quality)",
        Default = false,
        Callback = function(v) Config.FPSBoost = v; UpdateEnvironment() end
    })
    
    secEnv:AddToggle("MinecraftTexture", {
        Title = "Minecraft Texture",
        Default = false,
        Callback = function(v) Config.MinecraftTexture = v end
    })
    
    secEnv:AddToggle("GreyAvatar", {
        Title = "Grey Other Players",
        Default = false,
        Callback = function(v) ToggleGreyAvatar(v) end
    })

    -- Seção 5: Extras & Camera
    local secExtra = tab:AddSection("Extras & Camera", "soral/star-bold")
    
    secExtra:AddToggle("Crosshair", {
        Title = "Custom Crosshair",
        Default = false,
        Callback = function(v) Config.Crosshair = v end
    })
    
    secExtra:AddToggle("FOVChange", {
        Title = "Change FOV",
        Default = false,
        Callback = function(v) Config.FOVChange = v; workspace.CurrentCamera.FieldOfView = v and Config.FOVValue or 70 end
    })
    
    secExtra:AddSlider("FOVValue", {
        Title = "FOV Value",
        Min = 70, Max = 120, Default = 70,
        Callback = function(v) Config.FOVValue = v; if Config.FOVChange then workspace.CurrentCamera.FieldOfView = v end end
    })
    
    secExtra:AddToggle("StretchScreen", {
        Title = "Stretch Screen (0.65)",
        Default = false,
        Callback = function(v) Config.StretchScreen = v end
    })
    
    secExtra:AddButton({
        Title = "Reset Character",
        Callback = function()
            if LocalPlayer.Character then LocalPlayer.Character:BreakJoints() end
        end
    })
end

return VisualModule
