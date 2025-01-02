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
            model = "models/player/combine_soldier.mdl",
            weapons = {"m9k_ak47"},
            ammo = {
                m9k_ak47 = 100
            },
            spawns = {
                Vector(700, -908, 0),
                Vector(653, -723, 0),
                Vector(746, -622, 0)
            } -- three required
        },
        [2] = {
            name = "Blue Team",
            color = Color(0, 0, 255),
            model = "models/player/police.mdl",
            weapons = {"tfa_mossberg590"},
            ammo = {
                tfa_mossberg590 = 140
            },
            spawns = {
                Vector(-785, 1067, 0),
                Vector(-79, 886, 0),
                Vector(-762, 756, 0),
            } -- three required
        }
    }
}