local wwtlfs=require('lfs')
dofile(wwtlfs.writedir()..'Scripts/wwt/wwtExport.lua')

-- Save the WinWing functions
WW_LuaExportActivityNextEvent = LuaExportActivityNextEvent;
WW_LuaExportStart = LuaExportStart;
WW_LuaExportStop = LuaExportStop;

-- load the DCS ExportScript
dofile(lfs.writedir()..[[Scripts\DCS-ExportScript\ExportScript.lua]])

DE_LuaExportActivityNextEvent = LuaExportActivityNextEvent;
DE_LuaExportStart = LuaExportStart;
DE_LuaExportStop = LuaExportStop;

-- load the Vled script
dofile(lfs.writedir()..[[Scripts\vled\VledExport.lua]])

VL_LuaExportActivityNextEvent = LuaExportActivityNextEvent;
VL_LuaExportStart = LuaExportStart;
VL_LuaExportStop = LuaExportStop;

-- load the Raygun script
dofile(lfs.writedir()..[[Scripts\raygun\DCS-raygun.lua]])
RG_LuaExportStart = LuaExportStart;
RG_LuaExportStop = LuaExportStop;

-- load the TelemFFB script
dofile(lfs.writedir()..[[Scripts\vpforce\TelemFFB.lua]])
VP_LuaExportStart = LuaExportStart;
VP_LuaExportStop = LuaExportStop;


function LuaExportActivityNextEvent(t)
    WW_LuaExportActivityNextEvent(t);
    DE_LuaExportActivityNextEvent(t);
    VL_LuaExportActivityNextEvent(t);

    return t + ExportScript.Config.ExportInterval;
end

function LuaExportStart()
    WW_LuaExportStart();
    DE_LuaExportStart();
    VL_LuaExportStart();
    RG_LuaExportStart();
    VP_LuaExportStart();
end

function LuaExportStop()
    WW_LuaExportStop();
    DE_LuaExportStop();
    VL_LuaExportStop();
    RG_LuaExportStop();
    VP_LuaExportStop();
end
