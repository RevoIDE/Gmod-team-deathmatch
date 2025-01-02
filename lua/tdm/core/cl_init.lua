TDM = TDM or {}
local countdown = 0
local roundActive = false
local remainingTime = 0
local showRemainingTime = 0
local playerTeamNotification = 0
local winningTeam = nil
local showWinningTeam = 0

-- Receive player team assignment
net.Receive("TDM_PlayerTeam", function()
    local team = net.ReadInt(8)
    playerTeamNotification = CurTime() + 5
end)

-- Receive winning team
net.Receive("TDM_WinningTeam", function()
    winningTeam = net.ReadInt(8)
    showWinningTeam = CurTime() + 10
end)

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
    winningTeam = nil
    surface.PlaySound("ambient/alarms/klaxon1.wav")
end)

-- Receive round end
net.Receive("TDM_RoundEnd", function()
    roundActive = false
    surface.PlaySound("ambient/alarms/citadel_alert_loop2.wav")
end)

-- Receive remaining time
net.Receive('TDM_RemainingTime', function()
    remainingTime = TDM.Config.GameTimeInMinutes - net.ReadInt(8)
    showRemainingTime = CurTime() + 10
end)

-- Draw HUD
hook.Add("HUDPaint", "TDM_HUDPaint", function()
    surface.CreateFont("TDM_Large", {
        font = "Roboto",
        size = 48,
        weight = 500,
        antialias = true,
    })
    
    surface.CreateFont("TDM_Medium", {
        font = "Roboto",
        size = 32,
        weight = 500,
        antialias = true,
    })

    if playerTeamNotification > CurTime() then
        local teamColor = LocalPlayer():Team() == 1 and Color(255, 75, 75, 200) or Color(75, 75, 255, 200)
        local teamName = LocalPlayer():Team() == 1 and "RED TEAM" or "BLUE TEAM"
        
        draw.RoundedBox(8, ScrW()/2 - 200, 100, 400, 80, Color(0, 0, 0, 150))
        draw.RoundedBox(8, ScrW()/2 - 198, 102, 396, 76, teamColor)
        draw.SimpleText(
            "YOU ARE IN THE",
            "TDM_Medium",
            ScrW()/2,
            120,
            Color(255, 255, 255, 255),
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_TOP
        )
        draw.SimpleText(
            teamName,
            "TDM_Large",
            ScrW()/2,
            145,
            Color(255, 255, 255, 255),
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_TOP
        )
    end

    if winningTeam and showWinningTeam > CurTime() then
        local teamColor = winningTeam == 1 and Color(255, 75, 75, 200) or Color(75, 75, 255, 200)
        local teamName = winningTeam == 1 and "THE RED TEAM" or "THE BLUE TEAM"
        
        draw.RoundedBox(8, ScrW()/2 - 250, ScrH()/2 - 60, 500, 120, Color(0, 0, 0, 150))
        draw.RoundedBox(8, ScrW()/2 - 248, ScrH()/2 - 58, 496, 116, teamColor)
        draw.SimpleText(
            teamName,
            "TDM_Large",
            ScrW()/2,
            ScrH()/2 - 40,
            Color(255, 255, 255, 255),
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_TOP
        )
        draw.SimpleText(
            "WON THE GAME !",
            "TDM_Medium",
            ScrW()/2,
            ScrH()/2 + 10,
            Color(255, 255, 255, 255),
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_TOP
        )
    end

    local padding = 20
    local scoreHeight = 40
    local scoreWidth = 200
    
    draw.RoundedBox(8, padding, padding, scoreWidth, scoreHeight, Color(0, 0, 0, 150))
    draw.RoundedBox(8, padding + 2, padding + 2, scoreWidth - 4, scoreHeight - 4, Color(255, 75, 75, 200))
    draw.SimpleText(
        "RED: " .. team.GetScore(1),
        "TDM_Medium",
        padding + (scoreWidth/2),
        padding + (scoreHeight/2),
        Color(255, 255, 255, 255),
        TEXT_ALIGN_CENTER,
        TEXT_ALIGN_CENTER
    )
    
    draw.RoundedBox(8, padding, padding + scoreHeight + 10, scoreWidth, scoreHeight, Color(0, 0, 0, 150))
    draw.RoundedBox(8, padding + 2, padding + scoreHeight + 12, scoreWidth - 4, scoreHeight - 4, Color(75, 75, 255, 200))
    draw.SimpleText(
        "BLUE: " .. team.GetScore(2),
        "TDM_Medium",
        padding + (scoreWidth/2),
        padding + scoreHeight + 10 + (scoreHeight/2),
        Color(255, 255, 255, 255),
        TEXT_ALIGN_CENTER,
        TEXT_ALIGN_CENTER
    )

    if countdown > 0 and not roundActive then
        local countdownColor = Color(255, 255, 255, 200)
        draw.SimpleText(
            "THE GAME START IN",
            "TDM_Medium",
            ScrW() / 2,
            ScrH() / 4 - 30,
            countdownColor,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )
        draw.SimpleText(
            countdown,
            "TDM_Large",
            ScrW() / 2,
            ScrH() / 4 + 10,
            countdownColor,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )
    end

    if showRemainingTime > CurTime() then
        draw.SimpleText(
            "TIME REMAINING: " .. remainingTime .. " MINS",
            "TDM_Medium",
            ScrW() / 2,
            ScrH() / 3,
            Color(255, 255, 255, 200),
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )
    end
end)

hook.Add("SpawnMenuOpen", "TDM_DisableSpawnMenu", function()
    return false
end)

hook.Add("ContextMenuOpen", "TDM_DisableContextMenu", function()
    return false
end)

hook.Add("HUDShouldDraw", "TDM_HUDShouldDraw", function(name)
    local hide = {
        ["CHudHealth"] = true,
        ["CHudBattery"] = true
    }
    if hide[name] then return false end
end)