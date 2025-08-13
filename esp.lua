-- Render Module (ESP через стены)
local Render = {
    Enabled = false,
    ShowTeam = true,
    Boxes = {},
    Connections = {},
    Colors = {
        Ally = Color3.fromRGB(0, 255, 0),
        Enemy = Color3.fromRGB(255, 0, 0),
        Text = Color3.fromRGB(255, 255, 255)
    }
}

-- Создание ESP-бокса для игрока
function Render:CreateESP(player)
    if not player.Character then return end
    
    local Box = Drawing.new("Quad")
    Box.Visible = false
    Box.Color = Render.Colors.Enemy
    Box.Thickness = 1
    Box.Filled = false
    
    local NameLabel = Drawing.new("Text")
    NameLabel.Text = player.Name
    NameLabel.Color = Render.Colors.Text
    NameLabel.Size = 18
    NameLabel.Outline = true
    NameLabel.Visible = false
    
    self.Boxes[player] = {Box = Box, Label = NameLabel}
end

-- Обновление позиции ESP
function Render:UpdateESP(player)
    if not self.Boxes[player] then return end
    local character = player.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")
    if not rootPart or not head then return end
    
    local camera = workspace.CurrentCamera
    local rootPos, rootVis = camera:WorldToViewportPoint(rootPart.Position)
    local headPos = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
    
    if rootVis then
        local boxHeight = (headPos.Y - rootPos.Y) * 2
        local boxWidth = boxHeight * 0.6
        
        self.Boxes[player].Box.PointA = Vector2.new(rootPos.X - boxWidth/2, rootPos.Y)
        self.Boxes[player].Box.PointB = Vector2.new(rootPos.X + boxWidth/2, rootPos.Y)
        self.Boxes[player].Box.PointC = Vector2.new(rootPos.X + boxWidth/2, rootPos.Y + boxHeight)
        self.Boxes[player].Box.PointD = Vector2.new(rootPos.X - boxWidth/2, rootPos.Y + boxHeight)
        
        self.Boxes[player].Label.Position = Vector2.new(rootPos.X, rootPos.Y - 20)
        
        local shouldShow = self.Enabled and (self.ShowTeam or player.Team ~= LocalPlayer.Team)
        self.Boxes[player].Box.Visible = shouldShow
        self.Boxes[player].Label.Visible = shouldShow
        
        -- Цвет в зависимости от команды
        local color = (player.Team == LocalPlayer.Team) and self.Colors.Ally or self.Colors.Enemy
        self.Boxes[player].Box.Color = color
    else
        self.Boxes[player].Box.Visible = false
        self.Boxes[player].Label.Visible = false
    end
end

-- Основной цикл обновления ESP
function Render:UpdateAllESP()
    for player, esp in pairs(self.Boxes) do
        if player:IsA("Player") and player ~= LocalPlayer then
            self:UpdateESP(player)
        else
            esp.Box:Remove()
            esp.Label:Remove()
            self.Boxes[player] = nil
        end
    end
end

-- Включение/выключение ESP
function Render:Toggle(state)
    self.Enabled = state
    
    if state then
        -- Обработка новых игроков
        self.Connections.PlayerAdded = Players.PlayerAdded:Connect(function(player)
            player.CharacterAdded:Connect(function()
                self:CreateESP(player)
            end)
            if player.Character then
                self:CreateESP(player)
            end
        end)
        
        -- Обработка ушедших игроков
        self.Connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
            if self.Boxes[player] then
                self.Boxes[player].Box:Remove()
                self.Boxes[player].Label:Remove()
                self.Boxes[player] = nil
            end
        end)
        
        -- Инициализация существующих игроков
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                player.CharacterAdded:Connect(function()
                    self:CreateESP(player)
                end)
                if player.Character then
                    self:CreateESP(player)
                end
            end
        end
        
        -- Цикл обновления
        self.Connections.RenderStepped = RunService.RenderStepped:Connect(function()
            self:UpdateAllESP()
        end)
    else
        -- Очистка
        for _, connection in pairs(self.Connections) do
            connection:Disconnect()
        end
        self.Connections = {}
        
        for player, esp in pairs(self.Boxes) do
            esp.Box:Remove()
            esp.Label:Remove()
        end
        self.Boxes = {}
    end
end

-- UI элементы для управления ESP
local ESPToggle = CreateToggle(TabFrames["Render"], "ESP", UDim2.new(0, 20, 0, 50), function(state)
    Render:Toggle(state)
end)

local TeamToggle = CreateToggle(TabFrames["Render"], "Show Team", UDim2.new(0, 20, 0, 100), function(state)
    Render.ShowTeam = state
end)

-- Цветовые настройки
local AllyColorPicker = CreateColorPicker(TabFrames["Render"], "Ally Color", UDim2.new(0, 20, 0, 150), Render.Colors.Ally, function(color)
    Render.Colors.Ally = color
end)

local EnemyColorPicker = CreateColorPicker(TabFrames["Render"], "Enemy Color", UDim2.new(0, 20, 0, 200), Render.Colors.Enemy, function(color)
    Render.Colors.Enemy = color
end)
