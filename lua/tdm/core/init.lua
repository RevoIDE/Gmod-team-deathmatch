TDM = TDM or {}
TDM.SpawnPoints = {}
TDM.GameActive = false
TDM.RoundTimer = 0
TDM.FreezeTime = false
TDM.MinutesElapsed = 0
TDM.UsedSpawns = TDM.UsedSpawns or {}
TDM.ActiveTimers = {}

-- Network strings
util.AddNetworkString("TDM_CountdownStart")
util.AddNetworkString("TDM_CountdownUpdate")
util.AddNetworkString("TDM_RoundStart")
util.AddNetworkString("TDM_RoundEnd")
util.AddNetworkString("TDM_RemainingTime")
util.AddNetworkString("TDM_PlayerTeam")
util.AddNetworkString("TDM_WinningTeam")

local function DisableSpawning() return false end
hook.Add("PlayerSpawnObject", "TDM_DisableSpawning", DisableSpawning)
hook.Add("PlayerSpawnProp", "TDM_DisableProps", DisableSpawning)
hook.Add("PlayerSpawnEffect", "TDM_DisableEffects", DisableSpawning)
hook.Add("PlayerSpawnVehicle", "TDM_DisableVehicles", DisableSpawning)
hook.Add("PlayerSpawnSWEP", "TDM_DisableSWEPS", DisableSpawning)
hook.Add("PlayerSpawnSENT", "TDM_DisableSENTS", DisableSpawning)
hook.Add("PlayerSpawnNPC", "TDM_DisableNPCS", DisableSpawning)
hook.Add("PlayerSpawnRagdoll", "TDM_DisableRagdolls", DisableSpawning)

-- Disable physigun
hook.Add("PlayerGiveSWEP", "TDM_DisablePhysgun", function(ply, weapon)
    if weapon == "weapon_physgun" then
        return false
    end
end)

-- Not essential
hook.Add("PlayerLoadout", "TDM_RemovePhysgun", function(ply)
    ply:StripWeapon("weapon_physgun")
    return true
end)

-- Player initial spawn
hook.Add("PlayerInitialSpawn", "TDM_PlayerInitialSpawn", function(ply)

    if TDM.GameActive then
        TDM:TeleportAndEquipPlayer(ply)
    end
    
    ply:SetNWInt("Kills", 0)
    ply:SetNWInt("Deaths", 0)
    
    TDM:CheckGameStart()
end)

function TDM:CreateSafeTimer(name, delay, repetitions, func)
    if timer.Exists(name) then
        timer.Remove(name)
    end
    
    self.ActiveTimers[name] = true
    timer.Create(name, delay, repetitions, function()
        if not self.ActiveTimers[name] then
            timer.Remove(name)
            return
        end
        func()
    end)
end

function TDM:RemoveSafeTimer(name)
    self.ActiveTimers[name] = nil
    if timer.Exists(name) then
        timer.Remove(name)
    end
end

function TDM:ClearAllTimers()
    for name in pairs(self.ActiveTimers) do
        timer.Remove(name)
    end
    self.ActiveTimers = {}
end

local nextMemoryCheck = 0
local function CheckMemoryUsage()
    local curTime = CurTime()
    if curTime < nextMemoryCheck then return end
    nextMemoryCheck = curTime + 60
    
    collectgarbage("step", 100)
    local memory = collectgarbage("count")
    print("[TDM] Memory usage: " .. math.floor(memory / 1024) .. " MB")
end

hook.Add("Think", "TDM_MemoryCheck", CheckMemoryCheck)

function TDM:TeleportAndEquipPlayer(ply)
    local spawnPos = self:FindBestSpawn(ply:Team())
    if spawnPos then
        ply:SetPos(spawnPos)
        ply:SetAngles(Angle(0, math.random(0, 359), 0))
    else
        print("[TDM] Erreur: Impossible de trouver un point de spawn pour " .. ply:Nick())
    end
    self:GivePlayerLoadout(ply)
end

local nextAmmoCheck = {}
hook.Add("Think", "TDM_AmmoInfinite", function()
    local curTime = CurTime()
    
    for _, ply in ipairs(player.GetAll()) do
        if not IsValid(ply) or not ply:Alive() then continue end
        
        if not nextAmmoCheck[ply] or curTime >= nextAmmoCheck[ply] then
            nextAmmoCheck[ply] = curTime + 0.5
            
            for _, weapon in ipairs(ply:GetWeapons()) do
                if not IsValid(weapon) then continue end
                local maxClip = weapon:GetMaxClip1()
                if maxClip > 0 then
                    weapon:SetClip1(maxClip)
                end
            end
        end
    end
end)

-- Clean up ammo check table when player disconnects
hook.Add("PlayerDisconnected", "TDM_CleanAmmoCheck", function(ply)
    nextAmmoCheck[ply] = nil
    if TDM.GameActive then
        TDM:CheckRoundEnd()
    end
end)

-- Player spawn
hook.Add("PlayerSpawn", "TDM_PlayerSpawn", function(ply)
    
    if TDM.FreezeTime then
        ply:Lock()
    end

    if not TDM.GameActive then
        TDM:SetPlayerSpec(ply)
        return
    end

    TDM:TeleportAndEquipPlayer(ply)

    if ply:Team() == 1 then
        ply:SetModel(TDM.Config.Teams[1].model)
    else
        ply:SetModel(TDM.Config.Teams[2].model)
    end
end)

function TDM:AssignTeamToPlayers()
    for _, ply in ipairs(player.GetAll()) do
        if ply:IsValid() then
            if not TDM.Config.Teams[1] or not TDM.Config.Teams[2] then
                print("[TDM] Erreur de configuration des équipes.")
                return
            end
        
            local redCount = team.NumPlayers(1) or 0
            local blueCount = team.NumPlayers(2) or 0
            print("[TDM] Red Team count: " .. redCount)
            print("[TDM] Blue Team count: " .. blueCount)
            
            local assignedTeam
            if redCount <= blueCount then
                assignedTeam = 1
            else
                assignedTeam = 2
            end
            
            ply:SetTeam(assignedTeam)
            print("[TDM] " .. ply:Nick() .. " assigné à l'équipe " .. assignedTeam)
        end
    end
end

function TDM:FindBestSpawn(team)
    if not self.Config or not self.Config.Teams or not self.Config.Teams[team] then
        ErrorNoHalt("[TDM] Error: Invalid team configuration for team " .. tostring(team))
        return Vector(0, 0, 0)
    end
    
    local spawnPoints = self.Config.Teams[team].spawns
    if not spawnPoints or #spawnPoints == 0 then
        ErrorNoHalt("[TDM] Error: No spawn points for team " .. tostring(team))
        return Vector(0, 0, 0)
    end
    
    if table.Count(self.UsedSpawns) >= #spawnPoints then
        self.UsedSpawns = {}
    end
    
    local bestSpawn = nil
    local maxDistance = 0
    
    for _, spawnPos in ipairs(spawnPoints) do
        local spawnKey = string.format("%d_%d_%d", spawnPos.x, spawnPos.y, spawnPos.z)
        if self.UsedSpawns[spawnKey] then continue end
        
        local minDistToPlayer = math.huge
        
        for _, player in ipairs(player.GetAll()) do
            if IsValid(player) and player:Alive() then
                local dist = spawnPos:Distance(player:GetPos())
                minDistToPlayer = math.min(minDistToPlayer, dist)
            end
        end
        
        if minDistToPlayer > maxDistance then
            maxDistance = minDistToPlayer
            bestSpawn = spawnPos
        end
    end
    
    if not bestSpawn then
        bestSpawn = spawnPoints[math.random(#spawnPoints)]
    end
    
    if bestSpawn then
        local spawnKey = string.format("%d_%d_%d", bestSpawn.x, bestSpawn.y, bestSpawn.z)
        self.UsedSpawns[spawnKey] = CurTime()
    end
    
    return bestSpawn
end

function TDM:GivePlayerLoadout(ply)
    if not IsValid(ply) then 
        print("[TDM] Erreur: Joueur invalide dans GivePlayerLoadout")
        return 
    end
    
    local team = ply:Team()
    if team ~= 1 and team ~= 2 then
        print("[TDM] Erreur: Équipe invalide (" .. team .. ") pour " .. ply:Nick())
        ply:SetTeam(1)
        team = 1
    end
    
    if not TDM.Config then
        print("[TDM] Erreur: Configuration non chargée")
        return
    end
    
    local teamData = TDM.Config.Teams[team]
    if not teamData then
        print("[TDM] Erreur: Configuration manquante pour l'équipe " .. team)
        return
    end
    
    ply:StripWeapons()
    ply:StripAmmo()

    if not teamData.weapons then
        print("[TDM] Erreur: Pas d'armes définies pour l'équipe " .. team)
        return
    end
    
    for _, weapon in ipairs(teamData.weapons) do
        if not weapon then continue end
        ply:Give(weapon)
        if teamData.ammo and teamData.ammo[weapon] then
            ply:GiveAmmo(teamData.ammo[weapon], game.GetAmmoID(weapon) or weapon, true)
        end
    end
end

function TDM:CheckGameStart()
    local playerCount = #player.GetAll()
    
    if playerCount >= TDM.Config.MinimumPlayers and not TDM.GameActive then
        self:StartWaitingPeriod()
    end
end

function TDM:StartWaitingPeriod()
    self:ClearAllTimers()
    
    TDM.GameActive = true
    TDM.RoundTimer = TDM.Config.WaitingTime
    TDM.FreezeTime = true
    
    net.Start("TDM_CountdownStart")
    net.WriteInt(TDM.RoundTimer, 8)
    net.Broadcast()
    
    self:CreateSafeTimer("TDM_WaitingPeriodTimer", 1, TDM.Config.WaitingTime, function()
        TDM.RoundTimer = TDM.RoundTimer - 1
        
        if TDM.RoundTimer <= 0 then
            TDM:StartRound()
        else
            net.Start("TDM_CountdownUpdate")
            net.WriteInt(TDM.RoundTimer, 8)
            net.Broadcast()
        end
    end)
end

TDM:CreateSafeTimer("TDM_CleanSpawns", 30, 0, function()
    local currentTime = CurTime()
    for spawn, time in pairs(TDM.UsedSpawns) do
        if currentTime - time > 5 then
            TDM.UsedSpawns[spawn] = nil
        end
    end
end)

function TDM:SetAllPlayersToSpectator()
    for _, ply in ipairs(player.GetAll()) do
        local spectatorTeamID = 100
        
        if ply:Team() != spectatorTeamID then
            ply:SetTeam(spectatorTeamID)
        end
    end
end

function TDM:SetPlayerSpec(ply)
    local spectatorTeamID = 100

    if ply:Team() != spectatorTeamID then
        ply:SetTeam(spectatorTeamID)
    end
end

hook.Add("EntityTakeDamage", "NoDamageForSpectators", function(target, dmginfo)
    if target:IsPlayer() then
        local spectatorTeamID = 100

        if target:Team() == spectatorTeamID then
            return true
        end
    end
end)

hook.Add("PlayerShouldTakeDamage", "NoSuicideForSpectators", function(target, attacker)
    if target:IsPlayer() and target:Team() == 100 then
        return false
    end
end)

hook.Add("PlayerShouldTakeDamage", "TDM_PreventTeamDamage", function(target, attacker)
    if target:IsPlayer() and attacker:IsPlayer() then
        if target:Team() == attacker:Team() then
            return false
        end
    end
end)

function TDM:StartRound()
    self:ClearAllTimers()
    
    TDM.FreezeTime = false
    TDM.GameActive = true
    TDM.MinutesElapsed = 0
    TDM.RoundStartTime = CurTime()

    TDM:AssignTeamToPlayers()
    
    for _, ply in pairs(player.GetAll()) do
        if not IsValid(ply) then continue end
        
        net.Start("TDM_PlayerTeam")
        net.WriteInt(ply:Team(), 8)
        net.Send(ply)
        
        ply:UnLock()
        TDM:TeleportAndEquipPlayer(ply)
    end
    
    self:CreateSafeTimer("TDM_GameTimer", 1, 0, function()
        if not TDM.GameActive then return end
        
        local elapsedMinutes = math.floor((CurTime() - TDM.RoundStartTime) / 60)
        if elapsedMinutes ~= TDM.MinutesElapsed then
            TDM.MinutesElapsed = elapsedMinutes
            net.Start("TDM_RemainingTime")
            net.WriteInt(TDM.MinutesElapsed, 8)
            net.Broadcast()
        end
        
        if TDM.MinutesElapsed >= TDM.Config.GameTimeInMinutes then
            TDM:EndRound()
        end
    end)
    
    net.Start("TDM_RoundStart")
    net.Broadcast()
end

hook.Add("PlayerDeath", "TDM_PlayerDeath", function(victim, inflictor, attacker)
    if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim then
        attacker:SetNWInt("Kills", attacker:GetNWInt("Kills") + 1)
    end
    
    victim:SetNWInt("Deaths", victim:GetNWInt("Deaths") + 1)

    local killerTeam = attacker:Team()
    local currentScore = team.GetScore(killerTeam) or 0
    team.SetScore(killerTeam, currentScore + 1)
    
    TDM:CheckRoundEnd()
end)

function TDM:CheckRoundEnd()

    if team.GetScore(1) >= 10 or team.GetScore(2) >= 10 then
        self:EndRound()
        return
    end

    local redAlive = 0
    local blueAlive = 0
    
    for _, ply in pairs(player.GetAll()) do
        if ply:IsValid() or false then
            if ply:Team() == 1 then
                redAlive = redAlive + 1
            else
                blueAlive = blueAlive + 1
            end
        end
    end
    
    if redAlive == 0 or blueAlive == 0 then
        self:EndRound()
    end
end

function TDM:EndRound()
    self:ClearAllTimers()
    TDM.GameActive = false
    TDM.MinutesElapsed = 0
    
    local redScore = team.GetScore(1)
    local blueScore = team.GetScore(2)
    local winningTeam = 0
    
    if redScore > blueScore then
        winningTeam = 1
    elseif blueScore > redScore then
        winningTeam = 2
    end
    
    net.Start("TDM_WinningTeam")
    net.WriteInt(winningTeam, 8)
    net.Broadcast()
    
    net.Start("TDM_RoundEnd")
    net.Broadcast()
    
    team.SetScore(1, 0)
    team.SetScore(2, 0)
    
    TDM:SetAllPlayersToSpectator()
    
    self:CreateSafeTimer("TDM_RestartCheck", 5, 1, function()
        self:CheckGameStart()
    end)
end

hook.Add("PlayerDisconnected", "TDM_PlayerDisconnected", function(ply)
    if TDM.GameActive then
        TDM:CheckRoundEnd()
    end
end)
