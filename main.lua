local zmq = require("lzmq")
local json = require("dkjson")
local signal = require("posix.signal")
local unistd = require("posix.unistd")

local battery = require("components.battery")
local bluetooth = require("components.bluetooth")

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
    local capacity, status, e_full, e_full_design, p_now, e_now = battery.info()
    local powered, connected, d_name, s_results = bluetooth.info()

    local payload = {
        battery = {
            percent = capacity,
            stats = status,
            energy_full = e_full,
            energy_full_design = e_full_design,
            power_now = p_now,
            energy_now = e_now
        },
        bluetooth = {
            powered = powered, 
            connected = connected, 
            device_name = d_name, 
            scan_results = s_results
        }
    }

    publisher:send(json.encode(payload))

    unistd.sleep(1)
end
