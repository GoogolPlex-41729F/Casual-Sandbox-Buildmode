-- Cache tables.
-- Faster than doing something like player.GetAll() and also allows us to append our own data.
local BM_CACHED_PLAYERS = {}
local BM_CACHED_ENTS = {}

-- Player state options as a table.
-- Not necessary to put these into a table, just felt like doing it this way.
local BM_PLAYER_STATES = {
    [0] = "pvp",
    [1] = "build",
}

local bm_timeout = 60 -- Todo: make this a server cvar.
local bm_admin_bypass = 0  -- Todo: make this a server cvar.

gameevent.Listen("player_connect")
gameevent.Listen("player_say")
gameevent.Listen("entity_killed")

-- Inserts our own player data table into the cache when a player connects to the server.
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

-- PlayerSpawnedSomething hooks add an entity entry to the cache.
-- Each data table only contains the index and owner of the entity.

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

-- Changes player state when a player says !build or !pvp, if the player isn't in timeout.
hook.Add("player_say", "BM_ChangePlayerState", function(data)
    local MSG = string.lower(data.text)
    local UID = data.userid
    local ply = Player(UID)

    if BM_CACHED_PLAYERS[UID].CanChangeState == true then
        if MSG == "!build" then
            if BM_CACHED_PLAYERS[UID].State == BM_PLAYER_STATES[0] then
                BM_CACHED_PLAYERS[UID].State = BM_PLAYER_STATES[1]
                BM_CACHED_PLAYERS[UID].CanChangeState = false

                for i, p in ipairs(player.GetAll()) do
                    p:ChatPrint(ply:Nick() .. " is now in Build mode.")
                end

                ply:GodEnable()

                if timer.Exists("bm_blocker_timer") then
                    timer.Start("bm_blocker_timer")
                else
                    timer.Create("bm_blocker_timer", bm_timeout, 1, function()
                        BM_CACHED_PLAYERS[UID].CanChangeState = true
                    end)
                end
            else
                ply:ChatPrint("You are already in Build mode.")
            end
        elseif MSG == "!pvp" then
            if BM_CACHED_PLAYERS[UID].State == BM_PLAYER_STATES[1] then
                BM_CACHED_PLAYERS[UID].State = BM_PLAYER_STATES[0]
                BM_CACHED_PLAYERS[UID].CanChangeState = false

                for i, p in ipairs(player.GetAll()) do
                    p:ChatPrint(ply:Nick() .. " is now in PvP mode.")
                end

                ply:GodDisable()
                ply:SetMoveType(MOVETYPE_WALK) -- Basically forces player out of noclip.

                if timer.Exists("bm_blocker_timer") then
                    timer.Start("bm_blocker_timer")
                else
                    timer.Create("bm_blocker_timer", bm_timeout, 1, function()
                        BM_CACHED_PLAYERS[UID].CanChangeState = true
                    end)
                end
            else
                ply:ChatPrint("You are already in PvP mode.")
            end
        end
    else
        if MSG == "!build" || MSG == "!pvp" then
            ply:ChatPrint("You must wait " .. string.NiceTime(timer.TimeLeft("bm_blocker_timer")) .. " before changing modes.")
        end
    end
end)

-- Checks if a player can toggle noclip.
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

-- Checks if a player should take damage from a given attacker.
-- If the attacker is in build mode, or is an entity owned by a player who is in build mode, this blocks the damage.
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

-- Restarts the blocker timer when the player kills another player.
-- Anti-trolling measure so that players can't just kill someone and then immediately enter build mode as a cheat.
hook.Add("entity_killed", "BM_RestartBlockerTimer", function(data)
    local aIndex = data.entindex_attacker
    local vIndex = data.entindex_killed

    if Entity(aIndex):IsPlayer() && Entity(vIndex):IsPlayer() then
        local UID = Entity(aIndex):UserID()

        BM_CACHED_PLAYERS[UID].CanChangeState = false

        if timer.Exists("bm_blocker_timer") then
            timer.Start("bm_blocker_timer")
        else
            timer.Create("bm_blocker_timer", bm_timeout, 1, function()
                BM_CACHED_PLAYERS[UID].CanChangeState = true
            end)
        end
    end
end)
