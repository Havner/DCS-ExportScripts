-- DCS Export Script
--
-- Config File
--
-- Copyright by Michael aka McMicha 2014
-- Contact dcs2arcaze.micha@farbpigmente.org

ExportScript.Config = {}
ExportScript.Version.Config = "1.2.1"

-- Sender config
ExportScript.Config.Sender          = true          -- false for not use
ExportScript.Config.SenderHost      = "127.0.0.1"   -- Sender IP
ExportScript.Config.SenderPort      = 1725          -- Sender Port
ExportScript.Config.SenderSeparator = ":"

-- Listener config
ExportScript.Config.Listener         = true         -- false for not use
ExportScript.Config.ListenerPort     = 26027        -- Listener Port

-- Other
ExportScript.Config.ExportInterval         = 0.2	-- export evry 0.05 secounds
ExportScript.Config.ExportLowTickInterval  = 1.0	-- export evry 0.5 secounds
ExportScript.Config.LogPath                = lfs.writedir()..[[Logs\Export.log]]
ExportScript.Config.ExportModulePath       = lfs.writedir()..[[Scripts\DCS-ExportScript\ExportsModules\]]
ExportScript.Config.Debug                  = false
ExportScript.Config.DataDebug              = false
ExportScript.Config.SocketDebug            = false
