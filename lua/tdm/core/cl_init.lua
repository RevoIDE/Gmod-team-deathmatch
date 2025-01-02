TDM = TDM or {}
local countdown = 0
local roundActive = false

-- Receive countdown start
net.Receive("TDM_CountdownStart", function()
    countdown = net.ReadInt(8)
    roundActive = false
end)

-- Receive countdown update
net.Receive("TDM_CountdownUpdate", function()
    countdown = net.ReadInt(8)
end)

-- Receive round start
net.Receive("TDM_RoundStart", function()
    roundActive = true
    surface.PlaySound("ambient/alarms/klaxon1.wav")
end)

-- Receive round end
net.Receive("TDM_RoundEnd", function()
    roundActive = false
    surface.PlaySound("ambient/alarms/citadel_alert_loop2.wav")
end)

-- Draw HUD
hook.Add("HUDPaint", "TDM_HUDPaint", function()
    if countdown > 0 and not roundActive then
        draw.SimpleText(
            "Round starts in: " .. countdown,
            "DermaLarge",
            ScrW() / 2,
            ScrH() / 4,
            Color(255, 255, 255, 255),
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )
    end
    
    local redScore = team.GetScore(1)
    local blueScore = team.GetScore(2)
    
    draw.SimpleText(
        "Red Team: " .. redScore,
        "DermaLarge",
        10,
        10,
        Color(255, 0, 0, 255),
        TEXT_ALIGN_LEFT,
        TEXT_ALIGN_TOP
    )
    
    draw.SimpleText(
        "Blue Team: " .. blueScore,
        "DermaLarge",
        10,
        50,
        Color(0, 0, 255, 255),
        TEXT_ALIGN_LEFT,
        TEXT_ALIGN_TOP
    )
end)

-- Prevent weapons spawn

hook.Add("SpawnMenuOpen", "TDM_DisableSpawnMenu", function()
    return false
end)

hook.Add("ContextMenuOpen", "TDM_DisableContextMenu", function()
    return false
end)

-- Hide default HUD elements
hook.Add("HUDShouldDraw", "TDM_HUDShouldDraw", function(name)
    local hide = {
        ["CHudHealth"] = true,
        ["CHudBattery"] = true
    }
    if hide[name] then return false end
end)
