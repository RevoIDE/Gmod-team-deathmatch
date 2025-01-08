TDM = TDM or {}
TDM.Config = {
    MinimumPlayers = 2,
    WaitingTime = 30,
    SpawnFreezeTime = 5,
    GameTimeInMinutes = 6,
    Teams = {
        [1] = {
            name = "Red Team",
            color = Color(255, 0, 0),
            model = "models/player/breen.mdl",
            weapons = {"m9k_m16a4_acog", "m9k_m416", "csgo_karambit_crimsonwebs", "m9k_scar", "m9k_m14sp", "m9k_minigun", "m9k_glock",  "m9k_sig_p229r", "m9k_coltpython", "m9k_deagle", "m9k_hk45", "m9k_remington870", "m9k_dbarrel", "m9k_aw50", "m9k_m24", "m9k_mp9", "m9k_honeybadger", "m9k_thompson", "weapon_crowbar",  "m9k_ak47"},
            ammo = {
                m9k_ak47 = 100
            },
            spawns = {
                Vector(-1411, -1514, 82),
                Vector(-693, -2248, 96),
                Vector(229, -1885, 12)
            } -- three required
        },
        [2] = {
            name = "Blue Team",
            color = Color(0, 0, 255),
            model = "models/player/kleiner.mdl",
            weapons = {"m9k_m16a4_acog", "m9k_m416", "csgo_karambit_crimsonwebs", "m9k_scar", "m9k_m14sp", "m9k_minigun", "m9k_glock",  "m9k_sig_p229r", "m9k_coltpython", "m9k_deagle", "m9k_hk45", "m9k_remington870", "m9k_dbarrel", "m9k_aw50", "m9k_m24", "m9k_mp9", "m9k_honeybadger", "m9k_thompson", "weapon_crowbar",  "m9k_ak47"},
            ammo = {
                tfa_mossberg590 = 140
            },
            spawns = {
                Vector(-1296, -55, -16),
                Vector(-1285, -802, 13),
                Vector(-1122, -987, 12),
            } -- three required
        }
    }
}