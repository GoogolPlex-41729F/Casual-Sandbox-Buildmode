-- Cached colors.
local color_white = Color(255, 255, 255)
local color_semiopaque = Color(255, 255, 255, 100)

-- Cache of players in build mode.
local builders = {}

-- Adds a player to the builders cache.
net.Receive("BM_AddPlayerToClientCache", function()
    local UID = net.ReadInt(32)
    local ply = net.ReadPlayer()

    table.insert(builders, UID, ply)
end)

-- "Removes" a player from the builders cache by setting their data entry to nil.
-- Unlike table.remove(), this method preserves subsequent indicies.
net.Receive("BM_RemovePlayerFromClientCache", function()
    local UID = net.ReadInt(32)
    local ply = net.ReadPlayer()

    table.insert(builders, UID, nil)
end)

-- Draws halos around players who are listed in the builders cache.
hook.Add("PreDrawHalos", "BM_BuilderHalos", function()
    halo.Add(builders, color_white, 2, 2, 1, true, false)
end)

-- Adds a text notice at the top of a player's screen if they're in Build mode.
hook.Add("HUDPaintBackground", "BM_BuildModeNotice", function()
    local ply = LocalPlayer()

    if builders[ply:UserID()] != nil then
        draw.DrawText("BUILD MODE ACTIVE", "Trebuchet24", ScrW() * 0.5, 25, color_semiopaque, TEXT_ALIGN_CENTER)
    end
end)
