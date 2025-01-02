if SERVER then
    AddCSLuaFile("tdm/core/cl_init.lua")
    AddCSLuaFile("tdm/core/shared.lua")
    AddCSLuaFile("tdm/config/sh_config.lua")
    AddCSLuaFile("tdm/commands/helper.lua")
    
    include("tdm/core/init.lua")
else
    include("tdm/core/cl_init.lua")
end

include("tdm/commands/helper.lua")
include("tdm/core/shared.lua")
include("tdm/config/sh_config.lua")