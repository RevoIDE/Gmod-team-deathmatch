TDM = TDM or {}
TDM.SpawnPoints = {}
TDM.GameActive = false
TDM.RoundTimer = 0
TDM.FreezeTime = false

-- Network strings
util.AddNetworkString("TDM_CountdownStart")
util.AddNetworkString("TDM_CountdownUpdate")
util.AddNetworkString("TDM_RoundStart")
util.AddNetworkString("TDM_RoundEnd")

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

-- Physigun

hook.Add("PlayerGiveSWEP", "TDM_DisablePhysgun", function(ply, weapon)
    if weapon == "weapon_physgun" then
        return false
    end
end)

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
    
    ply:SetNWInt("Kills", 0)
    ply:SetNWInt("Deaths", 0)
    
    TDM:CheckGameStart()
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
end)

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
    
    net.Start("TDM_RoundStart")
    net.Broadcast()
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