local BM_CACHED_PLAYERS = {}
local BM_CACHED_ENTS = {}
local BM_PLAYER_STATES = {
    [0] = "pvp",
    [1]= "build",
}

local bm_timeout = 60
local bm_admin_bypass = 0

gameevent.Listen("player_connect")
gameevent.Listen("player_say")

hook.Add("player_connect", "BM_SetupPlayerData", function(data)
    local plytbl = {
        Name = data.name,
        Index = data.index,
        UserID = data.userid,
        SteamID = data.networkid,
        State = BM_PLAYER_STATES[0],
        CanChangeState = true,
    }
    table.insert(BM_CACHED_PLAYERS, data.userid, plytbl)
    --PrintTable(BM_CACHED_PLAYERS)
end)

hook.Add("PlayerSpawnedNPC", "BM_SetupNPCData", function(ply, ent)
    local enttbl = {
        Index = ent:EntIndex(),
        Owner = ply,
    }
    table.insert(BM_CACHED_ENTS, ent:EntIndex(), enttbl)
    --PrintTable(BM_CACHED_ENTS)
end)

hook.Add("PlayerSpawnedProp", "BM_SetupPropData", function(ply, _, ent)
    local enttbl = {
        Index = ent:EntIndex(),
        Owner = ply,
    }
    table.insert(BM_CACHED_ENTS, ent:EntIndex(), enttbl)
    --PrintTable(BM_CACHED_ENTS)
end)

hook.Add("PlayerSpawnedRagdoll", "BM_SetupRagdollData", function(ply, _, ent)
    local enttbl = {
        Index = ent:EntIndex(),
        Owner = ply,
    }
    table.insert(BM_CACHED_ENTS, ent:EntIndex(), enttbl)
    --PrintTable(BM_CACHED_ENTS)
end)

hook.Add("PlayerSpawnedSENT", "BM_SetupEntityData", function(ply, ent)
    local enttbl = {
        Index = ent:EntIndex(),
        Owner = ply,
    }
    table.insert(BM_CACHED_ENTS, ent:EntIndex(), enttbl)
    --PrintTable(BM_CACHED_ENTS)
end)

hook.Add("PlayerSpawnedVehicle", "BM_SetupVehicleData", function(ply, ent)
    local enttbl = {
        Index = ent:EntIndex(),
        Owner = ply,
    }
    table.insert(BM_CACHED_ENTS, ent:EntIndex(), enttbl)
    --PrintTable(BM_CACHED_ENTS)
end)

hook.Add("player_say", "BM_ChangePlayerState", function(data)
    local MSG = string.lower(data.text)
    local UID = data.userid
    local player = Player(UID)

    if BM_CACHED_PLAYERS[UID].CanChangeState == true then
        if MSG == "!build" then
            BM_CACHED_PLAYERS[UID].State = BM_PLAYER_STATES[1]
            BM_CACHED_PLAYERS[UID].CanChangeState = false

            for id, tbl in ipairs(BM_CACHED_PLAYERS) do
                Player(id):ChatPrint(player:Nick() .. " is now in Build mode.")
            end

            player:GodEnable()

            timer.Simple(bm_timeout, function()
                BM_CACHED_PLAYERS[UID].CanChangeState = true
            end)
        elseif MSG == "!pvp" then
            BM_CACHED_PLAYERS[UID].State = BM_PLAYER_STATES[0]
            BM_CACHED_PLAYERS[UID].CanChangeState = false

            for id, tbl in ipairs(BM_CACHED_PLAYERS) do
                Player(id):ChatPrint(player:Nick() .. " is now in PvP mode.")
            end

            player:GodDisable()
            player:SetMoveType(MOVETYPE_WALK)

            timer.Simple(bm_timeout, function()
                BM_CACHED_PLAYERS[UID].CanChangeState = true
            end)
        end
    else
        player:ChatPrint("You must wait " .. bm_timeout .. " seconds after changing modes/killing before you can change modes again.")
    end
end)

hook.Add("PlayerNoClip", "BM_NoClip", function(ply, noclip)
    if BM_CACHED_PLAYERS[ply:UserID()].State == BM_PLAYER_STATES[1] then
        return true
    else
        if ply:IsAdmin() && bm_admin_bypass == 1 then
            return true
        else
            ply:ChatPrint("You can't noclip while in PvP mode. Type !build in chat to switch modes.")
            return false
        end
    end
end)

hook.Add("PlayerShouldTakeDamage", "BM_DamageFilter", function(victim, attacker)
    if attacker:IsPlayer() then
        if BM_CACHED_PLAYERS[attacker:UserID()].State == BM_PLAYER_STATES[1] then
            return false
        end
    elseif BM_CACHED_ENTS[attacker:EntIndex()] != nil then
        if BM_CACHED_ENTS[attacker:EntIndex()].Owner:UserID() != nil then
            if BM_CACHED_PLAYERS[BM_CACHED_ENTS[attacker:EntIndex()].Owner:UserID()].State == BM_PLAYER_STATES[1] then
                return false
            end
        end
    end
end)
