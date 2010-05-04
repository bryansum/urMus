-----------------------------------------------------------------------------
-- TCP sample: Little program to dump lines received at a given port
-- LuaSocket sample files
-- Author: Diego Nehab
-- RCS ID: $Id: listener.lua,v 1.11 2005/01/02 22:44:00 diego Exp $
-----------------------------------------------------------------------------

local socket = require('socket')

str = ""
for k,v in pairs(socket) do str = str..k.."," end
DPrint(str)
-- host = host or "*"
-- port = port or 8080
-- if arg then
--  host = arg[1] or host
--  port = arg[2] or port
-- end
-- DPrint("Binding to host '" ..host.. "' and port " ..port.. "...")
-- s = assert(socket.bind(host, port))
-- i, p   = s:getsockname()
-- assert(i, p)
-- DPrint("Waiting connection from talker on " .. i .. ":" .. p .. "...")
-- c = assert(s:accept())
-- DPrint("Connected. Here is the stuff:")
-- l, e = c:receive()
-- while not e do
--  DPrint(l)
--  l, e = c:receive()
-- end
-- DPrint(e)
