TDM = TDM or {}

hook.Add("Initialize", "TDM_Init", function()
    team.SetUp(1, "Red Team", Color(255, 0, 0, 255))
    team.SetUp(2, "Blue Team", Color(0, 0, 255, 255))
end)