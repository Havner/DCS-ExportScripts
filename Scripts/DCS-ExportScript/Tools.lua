-- DCS Export Script
--
-- Tools
--
-- Copyright by Michael aka McMicha 2014 - 2018
-- Contact dcs2arcaze.micha@farbpigmente.org

ExportScript.Tools = {}
ExportScript.Version.Tools = "1.2.1"

function ExportScript.Tools.WriteToLog(message)
	if ExportScript.logFile then
		local ltmp, lMiliseconds = math.modf(os.clock())
		if lMiliseconds==0 then
			lMiliseconds='000'
		else
			lMiliseconds=tostring(lMiliseconds):sub(3,5)
		end
		ExportScript.logFile:write(os.date("%X")..":"..lMiliseconds.." : "..message.."\r\n")
	end
end

function ExportScript.Tools.createUDPSender()
	ExportScript.socket = require("socket")

	local lcreateUDPSender = ExportScript.socket.protect(function()
			ExportScript.UDPsender = ExportScript.socket.udp()
			ExportScript.socket.try(ExportScript.UDPsender:setsockname("*", 0))
			--ExportScript.socket.try(ExportScript.UDPsender:settimeout(.004)) -- set the timeout for reading the socket; 250 fps
	end)

	local ln, lerror = lcreateUDPSender()
	if lerror ~= nil then
		ExportScript.Tools.WriteToLog("createUDPSender protect: "..ExportScript.Tools.dump(ln)..", "..ExportScript.Tools.dump(lerror))
		return
	end

	ExportScript.Tools.WriteToLog("Create UDPSender")
end

function ExportScript.Tools.createUDPListner()
	if ExportScript.Config.Listener then
		ExportScript.socket = require("socket")

		local lcreateUDPListner = ExportScript.socket.protect(function()
				ExportScript.UDPListener = ExportScript.socket.udp()
				ExportScript.socket.try(ExportScript.UDPListener:setsockname("*", ExportScript.Config.ListenerPort))
				ExportScript.socket.try(ExportScript.UDPListener:settimeout(.001)) -- set the timeout for reading the socket; 250 fps
		end)

		local ln, lerror = lcreateUDPListner()
		if lerror ~= nil then
			ExportScript.Tools.WriteToLog("createUDPListner protect: "..ExportScript.Tools.dump(ln)..", "..ExportScript.Tools.dump(lerror))
			return
		end

		ExportScript.Tools.WriteToLog("Create UDPListner")
	end
end

function ExportScript.Tools.ProcessInput()
	local lCommand, lCommandArgs, lDevice
	-- C1,3001,4
	-- lComand = C
	-- lCommandArgs[1] = 1 => lDevice
	-- lCommandArgs[2] = 3001 => ButtonID
	-- lCommandArgs[3] = 4 => Value
	if ExportScript.Config.Listener then
		--local lInput,from,port = ExportScript.UDPListener:receivefrom()
		ExportScript.UDPListenerValues = {}

		local lUDPListenerReceivefrom = ExportScript.socket.protect(function()
				--[[
					local try = ExportScript.socket.newtry(function()
					ExportScript.UDPListener:close()
					ExportScript.Tools.createUDPListner()
					end)
					ExportScript.UDPListenerValues.Input, ExportScript.UDPListenerValues.from, ExportScript.UDPListenerValues.port = try(ExportScript.UDPListener:receivefrom())
				]] -- Bei einer newtry Funktion wird im fehlerfall deren inhalt ausgeführt.
				ExportScript.UDPListenerValues.Input, ExportScript.UDPListenerValues.from, ExportScript.UDPListenerValues.port = ExportScript.socket.try(ExportScript.UDPListener:receivefrom())
		end)

		local ln, lerror = lUDPListenerReceivefrom()
		if lerror ~= nil and lerror ~= "timeout" then
			ExportScript.Tools.WriteToLog("UDPListenerReceivefrom protect: "..ExportScript.Tools.dump(ln)..", "..ExportScript.Tools.dump(lerror))
			ExportScript.UDPListener:close()
			ExportScript.Tools.createUDPListner()
		end

		local lInput, from, port = ExportScript.UDPListenerValues.Input, ExportScript.UDPListenerValues.from, ExportScript.UDPListenerValues.port

		if ExportScript.Config.SocketDebug then
			ExportScript.Tools.WriteToLog("lInput: "..ExportScript.Tools.dump(lInput)..", from: "..ExportScript.Tools.dump(from)..", port: "..ExportScript.Tools.dump(port))
		end
		if lInput then
			lCommand = string.sub(lInput,1,1)

			if (lCommand == "C") then
				lCommandArgs = ExportScript.Tools.StrSplit(string.sub(lInput,2),",")
				lDeviceID = tonumber(lCommandArgs[1])
				if lDeviceID < 1000 then
					-- DCS Modules
					lDevice = GetDevice(lCommandArgs[1])
					if ExportScript.FoundDCSModule and type(lDevice) == "table" then
						lDevice:performClickableAction(lCommandArgs[2],lCommandArgs[3])
						if ExportScript.Config.Debug then
							ExportScript.Tools.WriteToLog("performClickableAction for Device: "..lCommandArgs[1]..", ButtonID: "..lCommandArgs[2]..", Value: "..lCommandArgs[3])
						end
					end
				elseif lDeviceID == 3000 then
					-- Raw
					local lCommandID = tonumber(lCommandArgs[2])
					local lCommandArgs = tonumber(lCommandArgs[3])
					if lCommandID >= 396 and lCommandID <= 405 and lCommandArgs == 0 then
						-- snap view reset
						LoSetCommand(406)
					else
						LoSetCommand(lCommandID)
					end
					if ExportScript.Config.Debug then
						ExportScript.Tools.WriteToLog("LoSetCommand RAW, CommandID: "..lCommandID)
					end
				end
			end
		end
	end
end

function ExportScript.Tools.ProcessOutput()
	local coStatus
	--local currentTime = LoGetModelTime()

	local lMyInfo = LoGetSelfData()
	if lMyInfo ~= nil then
		if ExportScript.ModuleName ~= lMyInfo.Name then
			ExportScript.Tools.SelectModule()  -- point globals to Module functions and data.
			return
		end
		lMyInfo = nil
	end

	local lDevice = GetDevice(0)
	if type(lDevice) == "table" and ExportScript.FoundDCSModule then

		lDevice:update_arguments()

		--if currentTime - ExportScript.lastExportTimeHI > ExportScript.Config.ExportInterval then
		if ExportScript.Config.Debug then
			ExportScript.Tools.WriteToLog("run hight importance export universally")
			ExportScript.Tools.ProcessArguments(lDevice, ExportScript.EveryFrameArguments) -- Module arguments as appropriate
		else
			ExportScript.coProcessArguments_EveryFrame = coroutine.create(ExportScript.Tools.ProcessArguments)
			coStatus = coroutine.resume( ExportScript.coProcessArguments_EveryFrame, lDevice, ExportScript.EveryFrameArguments)
		end

		--ExportScript.lastExportTimeHI = currentTime
		ExportScript.lastExportTimeHI = ExportScript.lastExportTimeHI + ExportScript.Config.ExportInterval
		--end

		--if currentTime - ExportScript.lastExportTimeLI > ExportScript.Config.ExportLowTickInterval then
		if ExportScript.lastExportTimeHI > ExportScript.Config.ExportLowTickInterval then
			if ExportScript.Config.Debug then
				ExportScript.Tools.WriteToLog("run low importance export universally")
				ExportScript.Tools.ProcessArguments(lDevice, ExportScript.Arguments) -- Module arguments as appropriate
			else
				ExportScript.coProcessArguments_Arguments = coroutine.create(ExportScript.Tools.ProcessArguments)
				coStatus = coroutine.resume( ExportScript.coProcessArguments_Arguments, lDevice, ExportScript.Arguments)
			end

			--ExportScript.lastExportTimeLI = currentTime
			ExportScript.lastExportTimeHI = 0
		end

		if ExportScript.Config.Sender then
			ExportScript.Tools.FlushData()
		end
	else -- No Module found
		if ExportScript.FoundNoModul then
			ExportScript.Tools.WriteToLog("No Module Found.")
			ExportScript.Tools.SelectModule()  -- point globals to Module functions and data.
		end
	end
end

function ExportScript.Tools.StrSplit(str, delim, maxNb)
	-- Eliminate bad cases...
	if string.find(str, delim) == nil then
		return { str }
	end
	if maxNb == nil or maxNb < 1 then
		maxNb = 0    -- No limit
	end
	local lResult = {}
	local lPat = "(.-)" .. delim .. "()"
	local lNb  = 0
	local lLastPos
	for part, pos in string.gfind(str, lPat) do
		-- for part, pos in string.gmatch(str, lPat) do -- Lua Version > 5.1
		lNb = lNb + 1
		lResult[lNb] = part
		lLastPos = pos
		if lNb == maxNb then break end
	end
	-- Handle the last field
	if lNb ~= maxNb then
		lResult[lNb + 1] = string.sub(str, lLastPos)
	end
	return lResult
end

-- Status Gathering Functions
function ExportScript.Tools.ProcessArguments(device, arguments)
	local lArgument , lFormat , lArgumentValue
	local lCounter = 0

	if ExportScript.Config.Debug then
		ExportScript.Tools.WriteToLog("======Begin========")
	end

	for lArgument, lFormat in pairs(arguments) do
		lArgumentValue = string.format(lFormat,device:get_argument_value(lArgument))
		if ExportScript.Config.Debug then
			lCounter = lCounter + 1
			ExportScript.Tools.WriteToLog(lCounter..". ID: "..lArgument..", Fromat: "..lFormat..", Value: "..lArgumentValue)
		end
		if ExportScript.Config.Sender then
			ExportScript.Tools.SendData(lArgument, lArgumentValue)
		end
	end

	if ExportScript.Config.Debug then
		ExportScript.Tools.WriteToLog("======End========")
	end
end

-- Network Functions for GlassCockpit
function ExportScript.Tools.SendData(id, value)
	if id == nil then
		ExportScript.Tools.WriteToLog("Export id is nil")
		return
	end
	if value == nil then
		ExportScript.Tools.WriteToLog("Value for id "..id.." is nil")
		return
	end

	if string.len(value) > 3 and value == string.sub("-0.00000000",1, string.len(value)) then
		value = value:sub(2)
	end

	if ExportScript.LastData[id] == nil or ExportScript.LastData[id] ~= value then
		local ldata    =  id .. "=" .. value
		local ldataLen = string.len(ldata)

		if ldataLen + ExportScript.PacketSize > 576 then
			ExportScript.Tools.FlushData()
		end

		table.insert(ExportScript.SendStrings, ldata)
		ExportScript.LastData[id] = value
		ExportScript.PacketSize   = ExportScript.PacketSize + ldataLen + 1
	end
end

function ExportScript.Tools.FlushData()
	local lFlushData = ExportScript.socket.protect(function()
			if #ExportScript.SendStrings > 0 then
				local lES_SimID = ""

				lES_SimID = ExportScript.SimID

				local lPacket = lES_SimID .. table.concat(ExportScript.SendStrings, ExportScript.Config.SenderSeparator) .. "\n"
				--ExportScript.socket.try(ExportScript.UDPsender:sendto(lPacket, ExportScript.Config.SenderHost, ExportScript.Config.SenderPort))
				local try = ExportScript.socket.newtry(function() ExportScript.UDPsender:close() ExportScript.Tools.createUDPSender() ExportScript.LastData = {} end)
				try(ExportScript.UDPsender:sendto(lPacket, ExportScript.Config.SenderHost, ExportScript.Config.SenderPort))

				if ExportScript.Config.SocketDebug then
					ExportScript.Tools.WriteToLog("FlushData: send to host: "..ExportScript.Config.SenderHost..", Port: "..ExportScript.Config.SenderPort..", Data: "..lPacket)
				end

				ExportScript.SendStrings = {}
				ExportScript.PacketSize  = 0
			else
				if ExportScript.Config.SocketDebug then
					ExportScript.Tools.WriteToLog("FlushData: nothing sent")
				end
			end
	end)

	local ln, lerror = lFlushData()
	if lerror ~= nil then
		ExportScript.Tools.WriteToLog("FlushData protect: "..ExportScript.Tools.dump(ln)..", "..ExportScript.Tools.dump(lerror))
	end
end

function ExportScript.Tools.SelectModule()
	-- Select Module...
	ExportScript.FoundDCSModule = false
	ExportScript.FoundNoModul   = true

	local lMyInfo      = LoGetSelfData()
	if lMyInfo == nil then  -- End SelectModule, if don't selected a aircraft
		return
	end

	if ExportScript.Config.Debug then
		ExportScript.Tools.WriteToLog("MyInfo: "..ExportScript.Tools.dump(lMyInfo))
	end

	ExportScript.ModuleName   = lMyInfo.Name
	local lModuleName         = ExportScript.ModuleName..".lua"
	local lModuleFile         = ""

	ExportScript.FoundNoModul = false

	for file in lfs.dir(ExportScript.Config.ExportModulePath) do
		if lfs.attributes(ExportScript.Config.ExportModulePath..file,"mode") == "file" then
			if file == lModuleName then
				lModuleFile = ExportScript.Config.ExportModulePath..file
			end
		end
	end

	ExportScript.Tools.WriteToLog("File Path: "..lModuleFile)

	if string.len(lModuleFile) > 1 then
		-- load Aircraft File
		dofile(lModuleFile)

		if ExportScript.Config.Sender then
			ExportScript.Tools.SendData("File", lMyInfo.Name)
		end

		ExportScript.Tools.WriteToLog("File '"..lModuleFile.."' loaded")

		ExportScript.Tools.WriteToLog("Version:")
		for k,v in pairs(ExportScript.Version) do
			ExportScript.Tools.WriteToLog(k..": "..v)
		end

		ExportScript.LastData = {}

		if ExportScript.FoundDCSModule then
			local lCounter = 0
			local lArray = {}
			for k, v in pairs(ExportScript.ConfigEveryFrameArguments) do
				lCounter = lCounter + 1
				local lV = v
				if lV == "%.4f" or lV == "%.3f" then
					lV = "%.2f"
				end
				lArray[k] = lV
			end
			if ExportScript.Config.Debug then
				ExportScript.Tools.WriteToLog("ExportScript.ConfigEveryFrameArguments Count: "..lCounter)
			end
			ExportScript.EveryFrameArguments = lArray

			lCounter = 0
			lArray = {}
			for k, v in pairs(ExportScript.ConfigArguments) do
				lCounter = lCounter + 1
				local lV = v
				if lV == "%.4f" or lV == "%.3f" then
					lV = "%.2f"
				end
				lArray[k] = lV
			end
			if ExportScript.Config.Debug then
				ExportScript.Tools.WriteToLog("ExportScript.ConfigArguments Count: "..lCounter)
			end
			ExportScript.Arguments = lArray
		else
			ExportScript.Tools.WriteToLog("Unknown Module Type: "..lMyInfo.Name)
		end

	else -- Unknown Module
		ExportScript.EveryFrameArguments            = {}
		ExportScript.Arguments                      = {}

		ExportScript.Tools.WriteToLog("Version:")
		for k,v in pairs(ExportScript.Version) do
			ExportScript.Tools.WriteToLog(k..": "..v)
		end
		ExportScript.Tools.WriteToLog("Unknown Module Name: "..lMyInfo.Name)
	end
end

-- The ExportScript.Tools.dump function show the content of the specified variable.
-- ExportScript.Tools.dump is similar to PHP function dump and show variables from type
-- "nil, "number", "string", "boolean, "table", "function", "thread" and "userdata"
function ExportScript.Tools.dump(var, depth)
	depth = depth or 0
	if type(var) == "string" then
		return 'string: "' .. var .. '"\n'
	elseif type(var) == "nil" then
		return 'nil\n'
	elseif type(var) == "number" then
		return 'number: "' .. var .. '"\n'
	elseif type(var) == "boolean" then
		return 'boolean: "' .. tostring(var) .. '"\n'
	elseif type(var) == "function" then
		if debug and debug.getinfo then
			fcnname = tostring(var)
			local info = debug.getinfo(var, "S")
			if info.what == "C" then
				return string.format('%q', fcnname .. ', C function') .. '\n'
			else
				if (string.sub(info.source, 1, 2) == [[./]]) then
					return string.format('%q', fcnname .. ', defined in (' .. info.linedefined .. '-' .. info.lastlinedefined .. ')' .. info.source) ..'\n'
				else
					return string.format('%q', fcnname .. ', defined in (' .. info.linedefined .. '-' .. info.lastlinedefined .. ')') ..'\n'
				end
			end
		else
			return 'a function\n'
		end
	elseif type(var) == "thread" then
		return 'thread\n'
	elseif type(var) == "userdata" then
		return tostring(var)..'\n'
	elseif type(var) == "table" then
		depth = depth + 1
		out = "{\n"
		for k,v in pairs(var) do
			out = out .. (" "):rep(depth*4).. "["..k.."] = " .. ExportScript.Tools.dump(v, depth)
		end
		return out .. (" "):rep((depth-1)*4) .. "}\n"
	else
		return tostring(var) .. "\n"
	end
end
