-- InfinityGold public development test loader.
-- Build: magic-loot-0.1.0-compat.2+wi.2026.004.public-test.1
-- Private source ref: 475c4d3776edf066769a2a997852ed64e2200fdd
-- Public payload ref: 37847319879f4ad74d2df3ff5de401495b8bc4ef
-- This unsigned loader has no licensing and must never be treated as production.

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local BUILD_ID = 'magic-loot-0.1.0-compat.2+wi.2026.004.public-test.1'
local EXPIRES_AT = '2026-09-23T00:00:00Z'
local EXPIRES_UNIX = 1790121600
local BASE = 'https://raw.githubusercontent.com/InfinityControlR/Launcher/37847319879f4ad74d2df3ff5de401495b8bc4ef/releases/game.magic-loot/0.1.0-compat.2/'

local bannerGui

local function banner(text)
    pcall(function()
        local player = game:GetService('Players').LocalPlayer
        local playerGui = player and player:FindFirstChildOfClass('PlayerGui')
        if playerGui == nil then return end
        if bannerGui == nil or bannerGui.Parent == nil then
            bannerGui = Instance.new('ScreenGui')
            bannerGui.Name = 'InfinityGoldPublicTestStatus'
            bannerGui.ResetOnSpawn = false
            bannerGui.DisplayOrder = 1000000
            bannerGui.IgnoreGuiInset = true
            bannerGui.Parent = playerGui

            local label = Instance.new('TextLabel')
            label.Name = 'Status'
            label.AnchorPoint = Vector2.new(0.5, 1)
            label.Position = UDim2.new(0.5, 0, 1, -24)
            label.Size = UDim2.new(0.94, 0, 0, 34)
            label.BackgroundColor3 = Color3.fromRGB(13, 13, 18)
            label.BackgroundTransparency = 0.1
            label.TextColor3 = Color3.fromRGB(245, 197, 66)
            label.Font = Enum.Font.GothamBold
            label.TextSize = 13
            label.TextWrapped = true
            label.Parent = bannerGui

            local rounding = Instance.new('UICorner')
            rounding.CornerRadius = UDim.new(0, 8)
            rounding.Parent = label
        end
        bannerGui.Status.Text = '[InfinityGold TEST] ' .. tostring(text)
    end)
end

local function notify(text)
    banner(text)
    pcall(function()
        game:GetService('StarterGui'):SetCore('SendNotification', {
            Title = 'InfinityGold TEST',
            Text = tostring(text),
            Duration = 10,
        })
    end)
end

if os.time() >= EXPIRES_UNIX then
    notify('Build expired at ' .. EXPIRES_AT .. '; request a new test build')
    return
end

if game.PlaceId ~= 133188236593503 then
    notify('Unsupported PlaceId ' .. tostring(game.PlaceId) .. '; nothing loaded')
    return
end

local URLS = {
    ui = BASE .. 'ui/InfinityUI.lua',
    common = BASE .. 'games/magicloot_common.lua',
    locomotion = BASE .. 'games/magicloot_locomotion.lua',
    core = BASE .. 'games/magicloot.lua',
}

local function fetch(name, url)
    banner('downloading ' .. name .. '...')
    local ok, exported = pcall(function()
        local source = game:HttpGet(url)
        local chunk, compileError = loadstring(source)
        if type(chunk) ~= 'function' then
            error(tostring(compileError or 'compile failed'))
        end
        return chunk()
    end)
    if not ok then
        notify(name .. ' failed: ' .. tostring(exported))
        warn('[InfinityGold TEST] ' .. name .. ' failed @ ' .. url .. ': ' .. tostring(exported))
        return nil
    end
    return exported
end

notify('loading public development build ' .. BUILD_ID)

local Library = fetch('interface', URLS.ui)
if type(Library) ~= 'table' or type(Library.CreateWindow) ~= 'function' then
    notify('interface export invalid; aborting')
    return
end

local Common = fetch('shared helpers', URLS.common)
if type(Common) ~= 'table' then
    notify('shared helpers export invalid; aborting')
    return
end

local Locomotion = fetch('locomotion', URLS.locomotion)
if type(Locomotion) ~= 'table' or type(Locomotion.create) ~= 'function' then
    notify('locomotion export invalid; aborting')
    return
end

local Core = fetch('core', URLS.core)
if type(Core) ~= 'function' then
    notify('core export invalid; aborting')
    return
end

banner('starting core...')
local ok, result = pcall(Core, Locomotion, Library, Common)
if not ok then
    notify('core error: ' .. tostring(result))
    warn('[InfinityGold TEST] core error: ' .. tostring(result))
    return
end

notify('loaded ' .. BUILD_ID)
task.delay(15, function()
    if bannerGui ~= nil then
        pcall(function() bannerGui:Destroy() end)
        bannerGui = nil
    end
end)

return result
