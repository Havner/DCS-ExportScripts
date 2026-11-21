w_net = {}
package.path = package.path .. ";.\\LuaSocket\\?.lua"
package.cpath = package.cpath .. ";.\\LuaSocket\\?.dll"
-- 版本
g_wwtVersion = "2.0.3"
-- 全局变量
w_net.socket = {}
w_net.net = {}
w_net.json = loadfile("Scripts\\JSON.lua")()
w_net.addr = {{
    ip = "127.0.0.1",
    port = 16535 -- SimAppPro2
}, {
    ip = "127.0.0.1",
    port = 16536 -- SimAppPro1
}, {
    ip = "127.0.0.1",
    port = 16537, -- debug
    isDebug = false -- 需要调试程序主动请求开启调试模式
}}

-- 开启调试
function w_net.setDebug(ip, port, isDebug)
    for i, _addr in pairs(w_net.addr) do
        if _addr.ip == ip and _addr.port == port then
            w_net.addr[i].isDebug = isDebug
            break
        end
    end
end

-- module开始
function w_net.start()
    w_net.socket = require("socket")
    w_net.net = w_net.socket.udp()
    w_net.net:setsockname("*", 0)
    w_net.net:setoption('broadcast', true)
    w_net.net:settimeout(0)
end

-- module发送
function w_net.send(msg, ip, port)
    for i, _addr in pairs(w_net.addr) do
        if (ip == _addr.ip and port == _addr.port) or _addr.isDebug or (ip == nil and port == nil) then
            w_net.net:sendto(w_net.json:encode(msg), _addr.ip, _addr.port)
        end
    end
end

-- module接收
function w_net.get()
    local _msg, ip, port = w_net.net:receivefrom()
    local _table = {}
    if type(_msg) == "string" and #_msg > 0 then
        _table = w_net.json:decode(_msg)
        if type(_table) == "table" then
            return _table, ip, port
        else
            return _msg, ip, port
        end
    else
        return _msg, ip, port
    end
end

-- module结束
function w_net.stop()
    -- 关闭socket
    w_net.net:close()
end

return w_net
