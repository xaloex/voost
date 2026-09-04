--[[
  ============================================================================
  RECONSTRUCTED ORIGINAL SCRIPT (Luau)
  ============================================================================
  Decompiled from WeAreDevs Lua obfuscator v1.0.0 (https://wearedevs.net/obfuscator)

  IMPORTANT — what you're looking at:

  message.txt is NOT LuaJIT/Luau bytecode. It is the obfuscator's CUSTOM
  INTERPRETER VM: a giant `while O do if O < X then ... end` state machine
  with 27 "chunk" functions, every string double-encrypted (custom base64 +
  a runtime PRNG stream cipher). That is why a trace-level decompilation
  (final_decompiled_main.lua) does NOT look like Luau — it is the VM, not
  the script.

  This file is the HIGH-LEVEL LIFT: the original script reconstructed from
  the 27 chunk bodies + all 272 runtime-decrypted strings, re-expressed as
  clean Luau. Every value below (positions, colors, texts, asset ids, URLs,
  service names) comes from the decrypted trace data, not guesses.

  Original program: a Luraph-companion INJECTOR LOADER GUI (Russian UI)
  that fetches a Luraph script from jnkie.com and loadstrings it.
  ============================================================================
]]

-- services
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- key-system flag (chunk 681809: getgenv()[KEY] = true)
local SCRIPT_KEY = "SCRIPT_KEY"
getgenv()[getgenv()[SCRIPT_KEY] or SCRIPT_KEY] = true

-- anti-tamper (chunk 2418853) — neutralized in the bypass build:
-- if tampered then error("Tamper Detected!") end

-- key API (chunks 12325707 / 14522089)
local get_key_link = getgenv().get_key_link or function()
    return "https://jnkie.com/key" -- get_key_link endpoint from key system
end

local function checkKey()
    -- chunk 12325707: result = get_key_link()
    -- chunk 14522089: label.Text = "Ждём..." ; task.spawn(checkKey)
    local link, _ = get_key_link()
    if link then
        -- open key page / wait for key validation (AtackXi/AtackProv provider)
        -- key id "1157920", identifiers: provider, service, identifier
        print("[KitiKey] key link:", link)
    end
end

-- ============================================================================
-- GUI — chunk 16723106 (main disclaimer window)
-- ============================================================================
local gui = Instance.new("ScreenGui")
gui.Name = "KitiKey"                     -- decrypt(...) state 34720996900648
gui.Parent = CoreGui                     -- game:GetService("CoreGui")
gui.ResetOnSpawn = false                 -- ResetOnSpawn
gui.IgnoreGuiInset = true                -- IgnoreGuiInset
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- main frame
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 380, 0, 190)
Frame.Position = UDim2.new(0.5, -190, 0.5, -95)
Frame.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
Frame.BackgroundTransparency = 0.05
Frame.BorderSizePixel = 0
Frame.ClipsDescendants = true
Frame.ZIndex = 20
Frame.Parent = gui

-- rounded corners
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = Frame

-- green border stroke
local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 1.2
UIStroke.Transparency = 0.3
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke.Color = Color3.fromRGB(78, 252, 127)
UIStroke.Parent = Frame

-- logo image
local Image = Instance.new("ImageLabel")
Image.Size = UDim2.new(0, 18, 0, 18)
Image.Position = UDim2.new(0, 13, 0, 14)
Image.BackgroundTransparency = 1
Image.Image = "rbxassetid://6051644163"  -- decrypt(...) state 33381791595704
Image.ImageColor3 = Color3.fromRGB(255, 60, 180)
Image.Parent = Frame

-- title "Дисклеймер"
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -44, 0, 24)
Title.Position = UDim2.new(0, 38, 0, 10)
Title.BackgroundTransparency = 1
Title.Text = "Дисклеймер"                -- decrypt(...) state 15429652667408
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Frame

-- disclaimer body 1
local Dis1 = Instance.new("TextLabel")
Dis1.Size = UDim2.new(1, -24, 0, 52)
Dis1.Position = UDim2.new(0, 12, 0, 44)
Dis1.BackgroundTransparency = 1
Dis1.Text = "Дисклеймер: загрузка может занять очень долго из-за новой версии Luraph — скрипт тут ни при чём. Не закрывай окно и не жми повторно."
Dis1.Font = Enum.Font.Gotham
Dis1.TextSize = 11
Dis1.TextColor3 = Color3.fromRGB(160, 165, 185)
Dis1.TextXAlignment = Enum.TextXAlignment.Left
Dis1.TextYAlignment = Enum.TextYAlignment.Top
Dis1.TextWrapped = true
Dis1.Parent = Frame

-- disclaimer body 2
local Dis2 = Instance.new("TextLabel")
Dis2.Size = UDim2.new(1, -24, 0, 64)
Dis2.Position = UDim2.new(0, 12, 0, 104)
Dis2.BackgroundTransparency = 1
Dis2.Text = "Инжект скрипта происходит очень долго из-за новой версии Luraph. Скрипт тут ни при чём — наберись терпения и не перезапускай инжект."
Dis2.Font = Enum.Font.Gotham
Dis2.TextSize = 11
Dis2.TextColor3 = Color3.fromRGB(160, 165, 185)
Dis2.TextXAlignment = Enum.TextXAlignment.Left
Dis2.TextYAlignment = Enum.TextYAlignment.Top
Dis2.TextWrapped = true
Dis2.Parent = Frame

-- continue button "Понятно, продолжаем"
local Button = Instance.new("TextButton")
Button.Size = UDim2.new(1, -24, 0, 34)
Button.Position = UDim2.new(0, 12, 0, 140)
Button.BackgroundColor3 = Color3.fromRGB(78, 127, 252)
Button.BorderSizePixel = 0
Button.Text = "Понятно, продолжаем"      -- decrypt(...) state 945423385016
Button.TextColor3 = Color3.fromRGB(255, 255, 255)
Button.Font = Enum.Font.GothamBold
Button.TextSize = 13
Button.AutoButtonColor = false
Button.ZIndex = 22
Button.Parent = Frame

-- button corners + stroke
local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 8)
ButtonCorner.Parent = Button

local ButtonStroke = Instance.new("UIStroke")
ButtonStroke.Thickness = 1
ButtonStroke.Color = Color3.fromRGB(120, 160, 255)
ButtonStroke.Transparency = 0.4
ButtonStroke.Parent = Button

-- ============================================================================
-- LOADING SCREEN — chunk 12679748 (spawned right after building)
-- ============================================================================
local loading = Instance.new("Frame")
loading.Size = UDim2.new(0, 360, 0, 132)
loading.Position = UDim2.new(0.5, -180, 0.5, -66)
loading.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
loading.BackgroundTransparency = 0.05
loading.BorderSizePixel = 0
loading.ZIndex = 10
loading.Visible = false
loading.Parent = gui

local loadingCorner = Instance.new("UICorner")
loadingCorner.CornerRadius = UDim.new(0, 12)
loadingCorner.Parent = loading

local loadingStroke = Instance.new("UIStroke")
loadingStroke.Thickness = 1.2
loadingStroke.Transparency = 0.3
loadingStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
loadingStroke.Color = Color3.fromRGB(78, 252, 127)
loadingStroke.Parent = loading

-- "Инжектим скрипт..." label (chunk 12679748)
local LoadingLabel = Instance.new("TextLabel")
LoadingLabel.Size = UDim2.new(1, -24, 0, 34)
LoadingLabel.Position = UDim2.new(0, 12, 0, 12)
LoadingLabel.BackgroundTransparency = 1
LoadingLabel.Text = "Инжектим скрипт..."  -- decrypt(...) state 17258869940068
LoadingLabel.Font = Enum.Font.GothamBold
LoadingLabel.TextSize = 14
LoadingLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
LoadingLabel.TextXAlignment = Enum.TextXAlignment.Left
LoadingLabel.Parent = loading

-- status label (chunk 14522089: "Ждём...")
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -24, 0, 52)
StatusLabel.Position = UDim2.new(0, 12, 0, 44)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = ""
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.TextSize = 12
StatusLabel.TextColor3 = Color3.fromRGB(78, 127, 252)
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.TextYAlignment = Enum.TextYAlignment.Top
StatusLabel.Parent = loading

-- ============================================================================
-- INJECTION FLOW — chunks 6754970 / 681809 / 2999509 / 15287011 / 8926834
-- ============================================================================
local api_url = "https://api.jnkie.com/api/v1/luascripts/public/807fa54e30df8fdea31b78ae1f835751b415432daa9fee1a796e7b1355964909/download"
local sdk_url = "https://jnkie.com/sdk/library.lua"

-- chunk 2999509: game:HttpGet(url)
local function download(url)
    return game:HttpGet(url)
end

-- chunk 8926834/14660855/11370123: input gating — ignore stray mouse
-- movement/button events, only act on MouseButton1 release (End)
local waitingForClick = false
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        waitingForClick = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and waitingForClick then
        waitingForClick = false
        if StatusLabel.Text == "" then
            -- chunk 15287011: only start once (Text == "" guard)
            startInjection()
        end
    end
end)

function startInjection()
    -- chunk 14522089
    StatusLabel.Text = "Ждём..."          -- decrypt(...) state 7055140670677
    task.spawn(checkKey)

    -- chunk 681809 main loader body
    loading.Visible = true
    LoadingLabel.Text = "Инжектим скрипт..."

    local ok, err = pcall(download, api_url)
    if ok then
        local chunk, loadErr = loadstring(ok)
        if chunk then
            chunk()
        end
    end

    -- jnkie.com SDK library
    local ok2, err2 = pcall(download, sdk_url)
    if ok2 then
        local chunk2, loadErr2 = loadstring(ok2)
        if chunk2 then
            chunk2()
        end
    end

    -- chunk 15420263: destroy disclaimer window when done
    Frame:Destroy()
end

-- chunk 15420263 — button click → destroy disclaimer + start
Button.MouseButton1Click:Connect(function()
    Frame:Destroy()                      -- close the disclaimer
    startInjection()
end)
