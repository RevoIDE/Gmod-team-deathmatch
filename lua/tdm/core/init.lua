TDM = TDM or {}
TDM.SpawnPoints = {}
TDM.GameActive = false
TDM.RoundTimer = 0
TDM.FreezeTime = false
TDM.MinutesElapsed = 0
TDM.UsedSpawns = {}

-- Network strings
util.AddNetworkString("TDM_CountdownStart")
util.AddNetworkString("TDM_CountdownUpdate")
util.AddNetworkString("TDM_RoundStart")
util.AddNetworkString("TDM_RoundEnd")
util.AddNetworkString("TDM_RemainingTime")

-- Initialize spawn points
hook.Add("InitPostEntity", "TDM_InitSpawnPoints", function()
    for _, ent in pairs(ents.FindByClass("info_player_start")) do
        table.insert(TDM.SpawnPoints, ent)
    end
end)

-- Prevent object spawning

hook.Add("PlayerSpawnObject", "TDM_DisableSpawning", function(ply)
    return false
end)

hook.Add("PlayerSpawnProp", "TDM_DisableProps", function(ply)
    return false
end)

hook.Add("PlayerSpawnEffect", "TDM_DisableEffects", function(ply)
    return false
end)

hook.Add("PlayerSpawnVehicle", "TDM_DisableVehicles", function(ply)
    return false
end)

hook.Add("PlayerSpawnSWEP", "TDM_DisableSWEPS", function(ply)
    return false
end)

hook.Add("PlayerSpawnSENT", "TDM_DisableSENTS", function(ply)
    return false
end)

hook.Add("PlayerSpawnNPC", "TDM_DisableNPCS", function(ply)
    return false
end)

hook.Add("PlayerSpawnRagdoll", "TDM_DisableRagdolls", function(ply)
    return false
end)

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
    local redCount = team.NumPlayers(1)
    local blueCount = team.NumPlayers(2)
    
    if redCount <= blueCount then
        ply:SetTeam(1)
    else
        ply:SetTeam(2)
    end

    local playerTeam = ply:Team()
    
    if TDM.GameActive then
        local spawnPoint = TDM:FindBestSpawn(playerTeam)
        if spawnPoint then
            ply:SetPos(spawnPoint:GetPos())
            ply:SetAngles(spawnPoint:GetAngles())
        end
    end
    
    ply:SetNWInt("Kills", 0)
    ply:SetNWInt("Deaths", 0)
    
    TDM:CheckGameStart()
end)

timer.Create("TDM_CleanSpawns", 30, 0, function()
    local currentTime = CurTime()
    for spawn, time in pairs(TDM.UsedSpawns) do
        if currentTime - time > 5 then
            TDM.UsedSpawns[spawn] = nil
        end
    end
end)

-- Player spawn
hook.Add("PlayerSpawn", "TDM_PlayerSpawn", function(ply)

    if ply:Team() == 1 then
        ply:SetModel(TDM.Config.Teams[1].model)
    else
        ply:SetModel(TDM.Config.Teams[2].model)
    end

    TDM:GivePlayerLoadout(ply)
    
    if TDM.FreezeTime then
        ply:Lock()
    end

    if not TDM.GameActive then return end
    
    local playerTeam = ply:Team()
    local spawnPoint = TDM:FindBestSpawn(playerTeam)
    if spawnPoint then
        ply:SetPos(spawnPoint:GetPos())
        ply:SetAngles(spawnPoint:GetAngles())
    end
end)

function TDM:FindBestSpawn(team)
    local spawnPoints = TDM.Config.Teams[team].spawns
    if not spawnPoints or #spawnPoints == 0 then return nil end
    
    if table.Count(TDM.UsedSpawns) >= #spawnPoints then
        TDM.UsedSpawns = {}
    end
    
    local bestSpawn = nil
    local maxDistance = 0
    
    for _, spawn in ipairs(spawnPoints) do
        if TDM.UsedSpawns[spawn] then continue end
        
        local minDistToPlayer = math.huge
        
        for _, player in ipairs(player.GetAll()) do
            if player:IsValid() and player:Alive() then
                local dist = spawn:Distance(player:GetPos())
                minDistToPlayer = math.min(minDistToPlayer, dist)
            end
        end
        
        if minDistToPlayer > maxDistance then
            maxDistance = minDistToPlayer
            bestSpawn = spawn
        end
    end
    
    if not bestSpawn then
        local availableSpawns = {}
        for _, spawn in ipairs(spawnPoints) do
            if not TDM.UsedSpawns[spawn] then
                table.insert(availableSpawns, spawn)
            end
        end
        
        if #availableSpawns > 0 then
            bestSpawn = availableSpawns[math.random(#availableSpawns)]
        else
            bestSpawn = spawnPoints[math.random(#spawnPoints)]
            TDM.UsedSpawns = {}
        end
    end
    
    if bestSpawn then
        TDM.UsedSpawns[bestSpawn] = CurTime()
    end
    
    return bestSpawn
end

function TDM:GivePlayerLoadout(ply)
    ply:StripWeapons()
    ply:StripAmmo()
    
    local teamData = TDM.Config.Teams[ply:Team()]
    for _, weapon in ipairs(teamData.weapons) do
        ply:Give(weapon)
        if teamData.ammo[weapon] then
            ply:GiveAmmo(teamData.ammo[weapon], weapon, true)
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
    TDM.GameActive = true
    TDM.RoundTimer = TDM.Config.WaitingTime
    TDM.FreezeTime = true
    
    net.Start("TDM_CountdownStart")
    net.WriteInt(TDM.RoundTimer, 8)
    net.Broadcast()
    
    timer.Create("TDM_WaitingPeriodTimer", 1, TDM.RoundTimer, function()
        TDM.RoundTimer = TDM.RoundTimer - 1
        
        if TDM.RoundTimer <= 0 then
            TDM:StartRound()
        end
        
        net.Start("TDM_CountdownUpdate")
        net.WriteInt(TDM.RoundTimer, 8)
        net.Broadcast()
    end)
end

function TDM:StartRound()
    TDM.FreezeTime = false
    
    for _, ply in pairs(player.GetAll()) do
        ply:UnLock()
    end

    timer.Create("TDM_EndGameTimer", TDM.gameTimeInMinutes * 60, 1, function()
       TDM:EndRound() 
    end)
    
    net.Start("TDM_RoundStart")
    net.Broadcast()

    timer.Create("TDM_BroadCastTime", 60, TDM.gameTimeInMinutes, function()
        TDM.MinutesElapsed = TDM.MinutesElapsed + 1
        net.Start("TDM_RemainingTime")
        net.WriteInt(TDM.MinutesElapsed, 8)
        net.Broadcast()
    end)
end

hook.Add("PlayerDeath", "TDM_PlayerDeath", function(victim, inflictor, attacker)
    if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim then
        attacker:SetNWInt("Kills", attacker:GetNWInt("Kills") + 1)
    end
    
    victim:SetNWInt("Deaths", victim:GetNWInt("Deaths") + 1)
    
    TDM:CheckRoundEnd()
end)

function TDM:CheckRoundEnd()
    local redAlive = 0
    local blueAlive = 0
    
    for _, ply in pairs(player.GetAll()) do
        if ply:Alive() then
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
    TDM.GameActive = false
    TDM.MinutesElapsed = 0
    
    net.Start("TDM_RoundEnd")
    net.Broadcast()
    
    timer.Simple(5, function()
        self:CheckGameStart()
    end)
end

hook.Add("PlayerDisconnected", "TDM_PlayerDisconnected", function(ply)
    if TDM.GameActive then
        TDM:CheckRoundEnd()
    end
end)