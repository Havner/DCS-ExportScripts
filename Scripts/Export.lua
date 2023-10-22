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


function LuaExportActivityNextEvent(t)
    DE_LuaExportActivityNextEvent(t);
    VL_LuaExportActivityNextEvent(t);

    return t + ExportScript.Config.ExportInterval;
end

function LuaExportStart()
    DE_LuaExportStart();
    VL_LuaExportStart();
end

function LuaExportStop()
    DE_LuaExportStop();
    VL_LuaExportStop();
end
