-- ver 2.4
-- Add this line to Scripts/Export.lua to enable  :
-- local dcsRg=require('lfs');dofile(dcsRg.writedir()..[[Scripts\DCS-raygun.lua]])
--
-- Make sure you COPY this file to the same location as the Export.lua as well.
-- If an Export.lua doesn't exist, just create one and add the single line in it.


-- Special thanks to Matt Cahill, Miguel21 and PB0_Grizzlie

RgHost = "127.0.0.1"
RgPort = 8124
RgArguments = {[404]="%.1f"}

local RgMod = nil
local FC3 = false

-- Simulation id
RgSimID = string.format("%08x",os.time())

-- State data for export
RgSendStrings = {RgSimID, '*'}
RgLastData = {}

-- Prev Export functions.
local PastExport = {}
PastExport.ResetChangeValues = ResetChangeValues
PastExport.LuaExportStart = LuaExportStart
PastExport.LuaExportStop = LuaExportStop
PastExport.LuaExportAfterNextFrame = LuaExportAfterNextFrame

-- Status Gathering Functions
function RgProcessMainPanel()
	local lArgument , lFormat , lArgumentValue
	local lDevice = GetDevice(0)

	if type(lDevice) == "table" then
		lDevice:update_arguments()

		for lArgument, lFormat in pairs(RgArguments) do
			lArgumentValue = string.format(lFormat,lDevice:get_argument_value(lArgument))
			if tonumber(lArgumentValue) > 0 then lArgumentValue = "1.0" end
			RgSendData(lArgument, lArgumentValue)
		end
	end
end

function RgProcessMainPanelFC3()
		local lMCPState = LoGetMCPState() -- Warning Lights

		if lMCPState.MasterWarning  then
			RgSendData(404, "1.0")
		else
			RgSendData(404, "0.0")
		end
end

-- Network Functions
function RgSendData(id, value)
	local id = 404
	if string.len(value) > 3 and value == string.sub("-0.00000000",1, string.len(value)) then
		value = value:sub(2)
	end

	if RgLastData[id] ~= value then
		table.insert(RgSendStrings, id .. "=" .. value)
		RgLastData[id] = value

		if #RgSendStrings > 140 then
			-- log.write('RAYGUN.EXPORT RgSendData',log.INFO,table.concat(RgSendStrings, ":").."\n")
			socket.try(Rgc:send(table.concat(RgSendStrings, ":").."\n"))
			RgSendStrings = {RgSimID, '*'}
		end
	end
end

function RgFlushData()
	if #RgSendStrings > 0 then
		-- log.write('RAYGUN.EXPORT RgSendStrings',log.INFO,table.concat(RgSendStrings, ":").."\n")
		socket.try(Rgc:send(table.concat(RgSendStrings, ":").."\n"))
		RgSendStrings = {RgSimID, '*'}
	end
end

function ResetChangeValues()
	for lArgument, lFormat in pairs(RgArguments) do
		RgLastData[lArgument] = "99999"
	end

	-- Chain previously-included export as necessary
	if PastExport.ResetChangeValues then
		PastExport.ResetChangeValues()
	end
end

function RgProcessOutput()
	-- local aircraft  = LoGetObjectById(LoGetPlayerPlaneId())  -- ne fonctionne pas online si server bloque data
	local aircraft = LoGetSelfData()

	if aircraft and RgMod ~= aircraft.Name then
		FC3 = false
		if aircraft.Name == "FA-18C_hornet" then
			RgArguments = {[13]="%.1f"}
		elseif aircraft.Name == "F-14B" then
			RgArguments = {[9200]="%.1f", [2200]="%.1f"}
		elseif aircraft.Name == "L-39C" or aircraft.Name == "L-39ZA" then
			RgArguments = {[253]="%.1f", [455]="%.1f"}
		elseif aircraft.Name == "F-15C" then
			-- RgArguments = {[117]="%.1f"}
			FC3 = true
		elseif aircraft.Name == "F-5E-3" then
			RgArguments = {[169]="%.1f"}
		elseif aircraft.Name == "MB-339PAN" then
			RgArguments = {[209]="%.1f"}
		elseif aircraft.Name == "MiG-21Bis" then
			RgArguments = {[542]="%.1f"}
		elseif aircraft.Name == "JF-17" then
			RgArguments = {[130]="%.1f"}
		elseif aircraft.Name == "UH-1H" then
			RgArguments = {[277]="%.1f"}
		elseif aircraft.Name == "M-2000C" then
			RgArguments = {[199]="%.1f", [200]="%.1f"}
		elseif aircraft.Name == "A-4E-C" then
			gArguments = {[605]="%.1f", [150]="%.1f", [154]="%.1f", [155]="%.1f", [156]="%.1f", [157]="%.1f", [158]="%.1f", [159]="%.1f", [761]="%.1f"}																																	  
		elseif aircraft.Name == "AV8BNA" then
			RgArguments = {[196]="%.1f", [197]="%.1f"}
		elseif aircraft.Name == "Ka-50" then
			RgArguments = {[44]="%.1f"}
		elseif aircraft.Name == "F-16C 50" or aircraft.Name == "F-16C_50" then
			RgArguments = {[117]="%.1f"}
		elseif aircraft.Name == "AJS37" then
			RgArguments = {[444]="%.1f"}
		else
			RgArguments = {[404]="%.1f"}	--Default to A-10C
		end

		RgMod = aircraft.Name
		log.write('RAYGUN.EXPORT aircraft.Name',log.INFO,aircraft.Name)
		-- for i_expt, f_expt in pairs(RgArguments) do
			-- log.write('RAYGUN.EXPORT i_expt',log.INFO,i_expt)
		-- end
	end

	if FC3 then
		RgProcessMainPanelFC3()
		RgFlushData()
	else
		RgProcessMainPanel()
		RgFlushData()
	end
end

function LuaExportStart()
	package.path  = package.path..";.\\LuaSocket\\?.lua"
	package.cpath = package.cpath..";.\\LuaSocket\\?.dll"

	socket = require("socket")

	Rgc = socket.udp()
	Rgc:setpeername(RgHost, RgPort)
	Rgc:settimeout(.0001) -- set the timeout for reading the socket

	-- Chain previously-included export as necessary
	if PastExport.LuaExportStart then
		PastExport.LuaExportStart()
	end
end

function LuaExportAfterNextFrame()
	RgProcessOutput()

	-- Chain previously-included export as necessary
	if PastExport.LuaExportAfterNextFrame then
		PastExport.LuaExportAfterNextFrame()
	end
end

function LuaExportStop()
  Rgc:close()

	-- Chain previously-included export as necessary
	if PastExport.LuaExportStop then
		PastExport.LuaExportStop()
	end
end
