-- Ikarus and D.A.C. Export Script
--
-- Copyright by Michael aka McMicha 2014 - 2018
-- Contact dcs2arcaze.micha@farbpigmente.org


-- Main Table
ExportScript = {}
ExportScript.Version = {}
ExportScript.Version.ExportScript = "1.2.1"
-- Simulation id
ExportScript.SimID = string.format("%08x*",os.time())

-- State data for export
ExportScript.PacketSize     = 0
ExportScript.SendStrings    = {}
ExportScript.LastData       = {}

ExportScript.lastExportTimeHI       = 0
ExportScript.lastExportTimeLI       = 0

dofile(lfs.writedir()..[[Scripts\DCS-ExportScript\Config.lua]])
ExportScript.utf8 = dofile(lfs.writedir()..[[Scripts\DCS-ExportScript\lib\utf8.lua]])
dofile(lfs.writedir()..[[Scripts\DCS-ExportScript\lib\Tools.lua]])

-- Found DCS or FC Module
ExportScript.FoundDCSModule = false
ExportScript.FoundNoModul   = true

---------------------------------------------
-- DCS Export API Function Implementations --
---------------------------------------------

function LuaExportStart()
	-- Works once just before mission start.
	-- (and before player selects their aircraft, if there is a choice!)

	-- 2) Setup udp sockets to talk to GlassCockpit
	package.path  = package.path..";.\\LuaSocket\\?.lua"
	package.cpath = package.cpath..";.\\LuaSocket\\?.dll"

	--local lrename1, lrename2 = os.rename(ExportScript.Config.LogPath, ExportScript.Config.LogPath..".old")
	ExportScript.logFile = io.open(ExportScript.Config.LogPath, "wa") -- "W+"
	if ExportScript.logFile then
		ExportScript.logFile:write('\239\187\191') -- create a UTF-8 BOM
		ExportScript.logFile:write("ExportScript Version: "..ExportScript.Version.ExportScript.."\r\n")
	end
	--if lrenmae1 == nil then
	--    ExportScript.Tools.WriteToLog("Rename Error: "..lrename2)
	--end

	ExportScript.Tools.createUDPSender()
	ExportScript.Tools.createUDPListner()

	ExportScript.AF = {} -- Table for Auxiliary functions

	ExportScript.Tools.SelectModule()   -- point globals to Module functions and data.
end

function LuaExportActivityNextEvent(t)
	if ExportScript.Config.Debug then
		ExportScript.Tools.ProcessInput()
	else
		ExportScript.coProcessArguments_BeforeNextFrame = coroutine.create(ExportScript.Tools.ProcessInput)
		coStatus = coroutine.resume(ExportScript.coProcessArguments_BeforeNextFrame)
	end

	ExportScript.Tools.ProcessOutput()

	return t + ExportScript.Config.ExportInterval
end

function LuaExportStop()
	-- Works once just after mission stop.
	if ExportScript.Config.IkarusExport then
		ExportScript.Tools.SendData("Ikarus", "stop")
		ExportScript.Tools.FlushData()
	end

	ExportScript.UDPsender:close()
	if ExportScript.Config.Listener then
		ExportScript.UDPListener:close()
	end

	ExportScript.ModuleName   = nil
	ExportScript.FoundNoModul = false

	if ExportScript.logFile then
		ExportScript.Tools.WriteToLog("====== Logfile close ======")
		ExportScript.logFile:flush()
		ExportScript.logFile:close()
		ExportScript.logFile = nil
	end
end
