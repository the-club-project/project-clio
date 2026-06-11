local zmq = require("lzmq")
local struct = require("struct")

local battery = require("components/battery")

local context = zmq.context()
local publisher = context:socket(zmq.PUB)
assert(publisher:bind("ipc:///tmp/hypr_bridge.ipc"))

while true do
    local capacity, status = battery.info()
    local content = struct.pack("<Bc1", capacity, status)
    publisher:send(content)

    os.execute("sleep 1")
end
