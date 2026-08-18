-- Cached colors.
local color_halo_white = Color(255, 255, 255, 255)
local color_semiopaque = Color(255, 255, 255, 100)

-- Cache of players in build mode.
local builders = {}

local client_state = 0

net.Receive("BM_ClientStateChanged", function()
    local state = net.ReadBit()

    client_state = state
end)

-- Flashes a halo around a player in Build mode if the client attempts the damage them.
net.Receive("BM_TempClientHalo", function()
    local SID = net.ReadString()
    local ply = net.ReadPlayer()

    builders[SID] = ply

    if timer.Exists("bm_halo_timer") then
        timer.Start("bm_halo_timer")
    else
        timer.Create("bm_halo_timer", 2, 1, function()
            builders[SID] = nil
        end)
    end
end)

-- Draws halos around players who are listed in the builders cache.
hook.Add("PreDrawHalos", "BM_BuilderHalos", function()
    if timer.Exists("bm_halo_timer") then
        halo.Add(builders, ColorAlpha(color_halo_white, 255 * (timer.TimeLeft("bm_halo_timer") * 0.5)), 2, 2, 1, true, false)
    end
end)

-- Adds a text notice at the top of a player's screen if they're in Build mode.
hook.Add("HUDPaintBackground", "BM_BuildModeNotice", function()
    local ply = LocalPlayer()

    if client_state == 1 then
        draw.DrawText("BUILD MODE ACTIVE", "Trebuchet24", ScrW() * 0.5, 25, color_semiopaque, TEXT_ALIGN_CENTER)
    end
end)
