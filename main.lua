local zmq = require("lzmq")
local json = require("dkjson")
local signal = require("posix.signal")
local unistd = require("posix.unistd")


local battery = require("components.battery")
local bluetooth = require("components.bluetooth")

local ipc_path = "ipc:///tmp/clio_bridge.ipc"
local res_path = "ipc:///tmp/clio_bridge_res.ipc"

local context = zmq.context()
local publisher = context:socket(zmq.PUB)
assert(publisher:bind(ipc_path))

local responder = context:socket(zmq.REP)
assert(responder:bind(res_path))

local poller = zmq.poller(1)
poller:add(responder, zmq.POLLIN)

signal.signal(signal.SIGINT, function()
    publisher:close()
    context:term()
    os.remove(ipc_path)
    os.exit(0)
end)

local modules = {["bluetooth"] = bluetooth}

while true do
    -- local mem_kb = collectgarbage("count")
    -- print(string.format("CLIO MEMORY USAGE: %.2f KB", mem_kb))
    local ready = poller:poll(0)
    if ready > 0 then
        local msg = responder:recv()
        print(msg)
        local req = json.decode(msg)
        if modules[req.sender] then
            modules[req.sender].listen(req)
        end
        local reply = {sender = req.sender, received = true, action = req.sender, status = "done"}
        responder:send(json.encode(reply))
    end

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

    unistd.sleep(0.5)
end
