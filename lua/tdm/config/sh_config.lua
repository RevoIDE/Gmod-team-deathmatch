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
            weapons = {"m9k_model3russian", "m9k_ump45", "csgo_karambit_crimsonwebs", "m9k_model500", "m9k_winchester73"},
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
            weapons = {"m9k_model3russian", "m9k_ump45", "csgo_karambit_crimsonwebs", "m9k_model500", "m9k_winchester73"},
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