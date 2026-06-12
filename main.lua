local zmq = require("lzmq")
local json = require("dkjson")
local signal = require("posix.signal")
local unistd = require("posix.unistd")

local battery = require("components.battery")

local ipc_path = "ipc:///tmp/hypr_bridge.ipc"

local context = zmq.context()
local publisher = context:socket(zmq.PUB)
assert(publisher:bind(ipc_path))

signal.signal(signal.SIGINT, function()
    publisher:close()
    context:term()
    os.remove(ipc_path)
    os.exit(0)
end)

while true do
    local capacity, status = battery.info()

    local payload = {
        module = "battery",
        metrics = {
            percent = capacity,
            stats = status
        }
    }

    publisher:send(json.encode(payload))

    unistd.sleep(1)
end
