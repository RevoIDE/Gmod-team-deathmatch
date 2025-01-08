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

surface.CreateFont("TDM_Info", {
    font = "Lato",
    size = 28,
    weight = 400,
    antialias = true,
})

local function DrawFlatBox(x, y, w, h, bgColor, borderColor)
    draw.RoundedBox(0, x, y, w, h, borderColor)
    draw.RoundedBox(0, x + 2, y + 2, w - 4, h - 4, bgColor)
end

-- Draw HUD
hook.Add("HUDPaint", "TDM_HUDPaint", function()
    local ply = LocalPlayer()

    if playerTeamNotification > CurTime() then
        local teamColor = ply:Team() == 1 and Color(255, 75, 75, 200) or Color(75, 75, 255, 200)
        local teamName = ply:Team() == 1 and "RED TEAM" or "BLUE TEAM"

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

    -- Health and Ammo
    local health = ply:Health()
    local weapon = ply:GetActiveWeapon()
    local ammoText = ""
    if IsValid(weapon) then
        local ammoInClip = weapon:Clip1()
        local ammoType = weapon:GetPrimaryAmmoType()
        local reserveAmmo = ply:GetAmmoCount(ammoType)
        ammoText = "Ammo: " .. ammoInClip .. " / " .. reserveAmmo
    end

    -- Health Bar
    local healthWidth = math.Clamp(health, 0, 100) * 3
    DrawFlatBox(10, ScrH() - 70, 300, 30, Color(20, 20, 20), Color(255, 75, 75))
    draw.RoundedBox(0, 10, ScrH() - 70, healthWidth, 30, Color(255, 75, 75))

    -- Ammo Display
    draw.SimpleText(ammoText, "TDM_Info", 10, ScrH() - 110, Color(255, 255, 255), TEXT_ALIGN_LEFT)
    if ply:Team() == 1 or ply:Team() == 2 then
        draw.SimpleText("Team: " .. TDM.Config.Teams[ply:Team()].name, "TDM_Info", 10, ScrH() - 130, Color(255, 255, 255), TEXT_ALIGN_LEFT)
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
        ["CHudBattery"] = true,
        ["CHudAmmo"] = true,
        ["CHudSecondaryAmmo"] = true
    }
    if hide[name] then return false end
end)

local TeamSelectionMenu = nil

function CreateTeamMenu()
    if IsValid(TeamSelectionMenu) then
        TeamSelectionMenu:Remove()
    end

    TeamSelectionMenu = vgui.Create("DPanel")
    TeamSelectionMenu:SetSize(ScrW(), ScrH())
    TeamSelectionMenu:SetPos(0, 0)
    TeamSelectionMenu:MakePopup()

    TeamSelectionMenu:SetAlpha(0)
    TeamSelectionMenu:AlphaTo(255, 0.3, 0)

    TeamSelectionMenu.Paint = function(self, w, h)
        DrawBlur(self, 4)
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 180))
        draw.SimpleText("TEAM SELECTION", "DermaLarge", w/2, h * 0.2, Color(255, 255, 255), TEXT_ALIGN_CENTER)
    end

    local closeButton = vgui.Create("DButton", TeamSelectionMenu)
    closeButton:SetSize(40, 40)
    closeButton:SetPos(TeamSelectionMenu:GetWide() - 60, 20)
    closeButton:SetText("✕")
    closeButton:SetFont("DermaLarge")
    closeButton.Paint = function(self, w, h)
        if self:IsHovered() then
            draw.RoundedBox(4, 0, 0, w, h, Color(255, 255, 255, 10))
        end
    end
    closeButton.DoClick = function()
        TeamSelectionMenu:AlphaTo(0, 0.3, 0, function()
            TeamSelectionMenu:Remove()
        end)
    end

    local teamContainer = vgui.Create("DPanel", TeamSelectionMenu)
    local containerW = math.min(ScrW() * 0.8, 1200)
    local containerH = ScrH() * 0.5
    teamContainer:SetSize(containerW, containerH)
    teamContainer:Center()
    teamContainer.Paint = function() end

    local blueTeam = vgui.Create("DButton", teamContainer)
    blueTeam:SetSize(containerW * 0.45, containerH)
    blueTeam:SetPos(0, 0)
    blueTeam:SetText("")
    
    local blueHover = 0
    blueTeam.Paint = function(self, w, h)
        blueHover = Lerp(FrameTime() * 10, blueHover, self:IsHovered() and 1 or 0)
        
        draw.RoundedBox(12, 0, 0, w, h, Color(0, 0, 0, 150))
        draw.RoundedBox(12, 0, 0, w, h, Color(50, 100, 255, 30 + blueHover * 40))
        
        surface.SetDrawColor(50, 100, 255, 100 + blueHover * 155)
        surface.DrawOutlinedRect(0, 0, w, h, 3)
        
        draw.SimpleText("ÉQUIPE BLEUE", "DermaLarge", w/2, h/2, Color(255, 255, 255, 200 + blueHover * 55), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local redTeam = vgui.Create("DButton", teamContainer)
    redTeam:SetSize(containerW * 0.45, containerH)
    redTeam:SetPos(containerW * 0.55, 0)
    redTeam:SetText("")
    
    local redHover = 0
    redTeam.Paint = function(self, w, h)
        redHover = Lerp(FrameTime() * 10, redHover, self:IsHovered() and 1 or 0)
        
        draw.RoundedBox(12, 0, 0, w, h, Color(0, 0, 0, 150))
        draw.RoundedBox(12, 0, 0, w, h, Color(255, 50, 50, 30 + redHover * 40))
        
        surface.SetDrawColor(255, 50, 50, 100 + redHover * 155)
        surface.DrawOutlinedRect(0, 0, w, h, 3)
        
        draw.SimpleText("RED TEAM", "DermaLarge", w/2, h/2, Color(255, 255, 255, 200 + redHover * 55), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    blueTeam.DoClick = function()
        net.Start("TDM_TeamSelect")
        net.WriteString("blue")
        net.SendToServer()
        TeamSelectionMenu:AlphaTo(0, 0.3, 0, function()
            TeamSelectionMenu:Remove()
        end)
    end

    redTeam.DoClick = function()
        net.Start("TDM_TeamSelect")
        net.WriteString("red")
        net.SendToServer()
        TeamSelectionMenu:AlphaTo(0, 0.3, 0, function()
            TeamSelectionMenu:Remove()
        end)
    end

    TeamSelectionMenu.Think = function(self)
        if input.IsKeyDown(KEY_ESCAPE) then
            self:AlphaTo(0, 0.3, 0, function()
                self:Remove()
            end)
        end
    end
end

net.Receive("TDM_PlayerTeamMenu", function()
    CreateTeamMenu()
end)