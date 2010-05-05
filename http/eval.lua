
module("eval", package.seeall)

require "wsapi.request"
require "wsapi.response"

function run(wsapi_env)
  local headers = { ["Content-type"] = "text/html" }
  local req = wsapi.request.new(wsapi_env)
  local res = wsapi.response.new(200, headers)

  -- intercept output
  local tmp_io = io.write
  local str = ''
  io.write = function(...) 
    tmp_io(...) -- write to stdout
    for i,v in ipairs(...) do str = str..v; end
  end
  loadstring(req.GET['code'])()
  -- restore output
  io.write = tmp_io
  res:write(str or 'OK')
  return res:finish()
end

return _M
