-- ==========================================
-- MÓDULO ESP / VISUAL (Para GitHub)
-- ==========================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local ESPModule = {}

-- Variáveis de Estado do ESP
local HighlightData = {
    Enabled = false,
    Mode = "Fill", -- Fill ou Outline
    Colors = {
        Player = Color3.fromRGB(0, 255, 0),
        Beast = Color3.fromRGB(255, 0, 0),
        Computer = Color3.fromRGB(0, 100, 255)
    }
}

local BeastGlowData = {
    Enabled = false,
    Connections = {}
}

-- Função auxiliar para aplicar Highlight
local function applyHighlight(part, color, mode)
    if not part then return end
    
    local highlight = part:FindFirstChildWhichIsA("Highlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = part
    end
    
    if mode == "Fill" then
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
    else
        highlight.FillTransparency = 1
        highlight.OutlineTransparency = 0
    end
    
    highlight.FillColor = color
    highlight.OutlineColor = color
end

local function removeHighlights(character)
    if character then
        for _, child in pairs(character:GetChildren()) do
            if child:IsA("Highlight") then
                child:Destroy()
            end
        end
    end
end

-- Loop principal do ESP
local espLoop = nil

function ESPModule:StartESP()
    if espLoop then return end -- Já está rodando
    
    espLoop = RunService.Heartbeat:Connect(function()
        if not HighlightData.Enabled then return end
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local char = player.Character
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                
                if humanoid and humanoid.Health > 0 then
                    -- Verifica se é Beast (lógica simplificada baseada no Eclipse)
                    local isBeast = false
                    local stats = player:FindFirstChild("TempPlayerStatsModule")
                    if stats then
                        local isBeastVal = stats:FindFirstChild("IsBeast")
                        if isBeastVal and isBeastVal.Value then
                            isBeast = true
                        end
                    end
                    
                    local color = isBeast and HighlightData.Colors.Beast or HighlightData.Colors.Player
                    applyHighlight(char, color, HighlightData.Mode)
                else
                    removeHighlights(char)
                end
            end
        end
    end)
end

function ESPModule:StopESP()
    if espLoop then
        espLoop:Disconnect()
        espLoop = nil
    end
    
    -- Limpa todos os highlights ao desativar
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character then
            removeHighlights(player.Character)
        end
    end
end

-- Função principal chamada pelo Script Principal
function ESPModule:Init(tab)
    if not tab then return end
    
    -- Adiciona Seção de Configurações Gerais
    local secGeneral = tab:AddSection("Configurações ESP", "solar/eye-bold")
    
    -- Toggle Principal
    secGeneral:AddToggle("EspEnabled", {
        Title = "Ativar ESP",
        Default = false,
        Callback = function(value)
            HighlightData.Enabled = value
            if value then
                self:StartESP()
            else
                self:StopESP()
            end
        end
    })
    
    -- Seleção de Modo (Fill/Outline)
    secGeneral:AddDropdown("EspMode", {
        Title = "Modo de Renderização",
        Values = {"Fill", "Outline"},
        Default = "Fill",
        Callback = function(value)
            HighlightData.Mode = value
        end
    })
    
    -- Color Pickers
    local secColors = tab:AddSection("Cores", "solar/palette-bold")
    
    secColors:AddColorpicker("PlayerColor", {
        Title = "Cor dos Jogadores",
        Default = HighlightData.Colors.Player,
        Callback = function(color)
            HighlightData.Colors.Player = color
        end
    })
    
    secColors:AddColorpicker("BeastColor", {
        Title = "Cor da Besta",
        Default = HighlightData.Colors.Beast,
        Callback = function(color)
            HighlightData.Colors.Beast = color
        end
    })

    -- Seção de Beast Glow (Adaptado do Eclipse)
    local secGlow = tab:AddSection("Beast Glow", "solar/star-bold")
    
    secGlow:AddToggle("BeastGlow", {
        Title = "Ativar Beast Glow",
        Default = false,
        Callback = function(enabled)
            BeastGlowData.Enabled = enabled
            
            -- Limpa conexões antigas
            for _, conn in pairs(BeastGlowData.Connections) do
                conn:Disconnect()
            end
            BeastGlowData.Connections = {}
            
            -- Remove glows existentes se desativado
            if not enabled then
                for _, p in pairs(Players:GetPlayers()) do
                    if p.Character then
                        local head = p.Character:FindFirstChild("Head")
                        if head then
                            local glow = head:FindFirstChild("BeastGlowLight")
                            if glow then glow:Destroy() end
                        end
                    end
                end
                return
            end
            
            -- Aplica em jogadores atuais
            for _, p in pairs(Players:GetPlayers()) do
                if p.Character then
                    ESPModule:ApplyGlowToCharacter(p.Character)
                end
                -- Monitora novos personagens
                table.insert(BeastGlowData.Connections, p.CharacterAdded:Connect(function(char)
                    if BeastGlowData.Enabled then
                        ESPModule:ApplyGlowToCharacter(char)
                    end
                end))
            end
        end
    })
end

-- Função auxiliar para o Glow
function ESPModule:ApplyGlowToCharacter(char)
    local head = char:FindFirstChild("Head")
    if not head then return end
    
    -- Remove glow antigo se existir
    local oldGlow = head:FindFirstChild("BeastGlowLight")
    if oldGlow then oldGlow:Destroy() end
    
    -- Cria novo PointLight
    local light = Instance.new("PointLight")
    light.Name = "BeastGlowLight"
    light.Color = Color3.fromRGB(0, 255, 255)
    light.Brightness = 5
    light.Range = 20
    light.Parent = head
    
    -- Lógica para verificar se é Beast e ajustar cor/intensidade pode ser adicionada aqui
    -- Baseado no Eclipse, ele verifica "BeastPowers". Vamos simplificar:
    local bp = char:FindFirstChild("BeastPowers")
    if bp then
        light.Color = Color3.fromRGB(255, 0, 0) -- Cor diferente se for beast ativa
    end
end

return ESPModule
