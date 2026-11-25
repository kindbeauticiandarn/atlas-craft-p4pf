local Services = setmetatable({}, {
        __index = function(Self, Service)
            return cloneref(game:GetService(Service))
        end
    })

    local Players = Services.Players
    local UserInputService = Services.UserInputService
    local LocalPlayer = Players.LocalPlayer

    local App = require(game.ReplicatedStorage.ChessClient.App)
    local mastermindbotplayer = require(game.ReplicatedStorage.Chess.VortexBot)
    local BoardHelper = require(game.ReplicatedStorage.Chess.Engine)

    -- variables
    local Lasttimeplayed = -1
    local dragging       = false
    local dragStart      = nil
    local panelStartPos  = nil

    -- gui
    local gui = Instance.new("ScreenGui")
    gui.Name = "MoveAssist"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local panel = Instance.new("Frame")
    panel.Size = UDim2.fromOffset(190, 70)
    panel.Position = UDim2.fromOffset(12, 68)
    panel.BackgroundColor3 = Color3.fromRGB(15, 15, 17)
    panel.BorderSizePixel = 1
    panel.BorderColor3 = Color3.fromRGB(55, 55, 60)
    panel.Active = true
    panel.Parent = gui

    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 22)
    titleBar.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = panel

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -25, 1, 0)
    title.Position = UDim2.fromOffset(8, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.Code
    title.TextSize = 13
    title.TextColor3 = Color3.fromRGB(200, 200, 200)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "move assist"
    title.Parent = titleBar

    local close = Instance.new("TextButton")
    close.Size = UDim2.fromOffset(20, 22)
    close.Position = UDim2.new(1, -20, 0, 0)
    close.BackgroundTransparency = 1
    close.Font = Enum.Font.Code
    close.TextSize = 14
    close.TextColor3 = Color3.fromRGB(200, 200, 200)
    close.Text = "X"
    close.Parent = titleBar

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -16, 1, -28)
    status.Position = UDim2.fromOffset(8, 28)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.Code
    status.TextSize = 15
    status.TextColor3 = Color3.fromRGB(255, 255, 255)
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextYAlignment = Enum.TextYAlignment.Top
    status.Text = "Join a Game"
    status.Parent = panel

    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging       = true
            dragStart      = input.Position
            panelStartPos  = panel.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local d = input.Position - dragStart
            panel.Position = UDim2.new(panelStartPos.X.Scale, panelStartPos.X.Offset + d.X, panelStartPos.Y.Scale, panelStartPos.Y.Offset + d.Y)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    close.MouseButton1Click:Connect(function()
        pcall(function() App.board:setArrow("best", nil) end)
        gui:Destroy()
    end)


    -- logic / the main stuff

    local function clearArrow()
        pcall(function() App.board:setArrow("best", nil) end)
    end

    task.spawn(function()
        while task.wait(0.25) do
            if not gui.Parent then 
                break 
            end
            
            local sexsision = App.session

            if not sexsision or sexsision.kind ~= "online" or sexsision.over then
                status.Text = "Join a Game"
                clearArrow()
                Lasttimeplayed = -1

            elseif not sexsision:isMyTurn() then
                if #sexsision.ucis ~= Lasttimeplayed then
                    clearArrow()
                    Lasttimeplayed = -1
                end
                status.Text = "Wait for your turn"

            elseif #sexsision.ucis ~= Lasttimeplayed then
                local theSigmaMove = mastermindbotplayer.think(sexsision.startFen, table.clone(sexsision.ucis), { rating = 1200 }, {})
                local whereItWas, whereItGoes = theSigmaMove:sub(1, 2), theSigmaMove:sub(3, 4)

                App.board:setArrow("best", BoardHelper.algToIndex64(whereItWas), BoardHelper.algToIndex64(whereItGoes), Color3.fromRGB(120, 230, 130), 0.2)
                
                Lasttimeplayed = #sexsision.ucis
                status.Text = whereItWas .. " > " .. whereItGoes
            end
        end
    end)