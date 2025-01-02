TDM = TDM or {}
TDM.Config = {
    MinimumPlayers = 2,
    WaitingTime = 30,
    SpawnFreezeTime = 5,
    Teams = {
        [1] = {
            name = "Red Team",
            color = Color(255, 0, 0),
            model = "models/player/combine_soldier.mdl",
            weapons = {"weapon_pistol"},
            ammo = {
                weapon_pistol = 36
            }
        },
        [2] = {
            name = "Blue Team",
            color = Color(0, 0, 255),
            model = "models/player/police.mdl",
            weapons = {"weapon_smg1"},
            ammo = {
                weapon_smg1 = 90
            }
        }
    }
}