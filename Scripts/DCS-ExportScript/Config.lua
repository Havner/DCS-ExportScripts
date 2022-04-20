-- Ikarus and D.A.C. Export Script
--
-- Config File
--
-- Copyright by Michael aka McMicha 2014
-- Contact dcs2arcaze.micha@farbpigmente.org

ExportScript.Config = {}
ExportScript.Version.Config = "1.2.1"

-- Ikarus a Glass Cockpit Software
ExportScript.Config.IkarusExport    = true         -- false for not use
ExportScript.Config.IkarusHost      = "127.0.0.1"  -- IP for Ikarus
ExportScript.Config.IkarusPort      = 1725         -- Port Ikarus (1625)
ExportScript.Config.IkarusSeparator = ":"

-- Ikarus and D.A.C. can data send
ExportScript.Config.Listener         = true         -- false for not use
ExportScript.Config.ListenerPort     = 26027        -- Listener Port for D.A.C.

-- Other
ExportScript.Config.ExportInterval         = 0.05	-- export evry 0.05 secounds
ExportScript.Config.ExportLowTickInterval  = 0.1	-- export evry 0.5 secounds
ExportScript.Config.LogPath                = lfs.writedir()..[[Logs\Export.log]]
ExportScript.Config.ExportModulePath       = lfs.writedir()..[[Scripts\DCS-ExportScript\ExportsModules\]]
ExportScript.Config.Debug                  = false
ExportScript.Config.SocketDebug            = false
ExportScript.Config.FirstNewDataSend       = true
ExportScript.Config.FirstNewDataSendCount  = 100
