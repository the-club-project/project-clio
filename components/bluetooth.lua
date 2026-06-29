local bluetooth = {}

function bluetooth.info()
    local powered = false
    local connected = false
    local device_name = ""
    local scan_results = {}
    local connected_devices = {}

    local f_show = io.popen("bluetoothctl show 2>/dev/null")
    if f_show then
        local output = f_show:read("*a")
        f_show:close()
        if output:find("Powered: yes") then
            powered = true
        end
    end

    local f_cdevices = io.popen("bluetoothctl devices Connected 2>/dev/null")
    if f_cdevices then
        for line in f_cdevices:lines() do
            local mac, name = line:match("Device ([%w:]+) (.*)")
            if mac then
                connected_devices[mac] = {name = name, connected = true}
            end
        end
    end

    local f_devices = io.popen("bluetoothctl devices 2>/dev/null")
    if f_devices then
        for line in f_devices:lines() do
            local mac, name = line:match("Device ([%w:]+) (.*)")
            local is_connected = false
            if connected_devices[mac] then
                is_connected = connected_devices[mac].connected
                connected = true
            end
            if mac and name then
                table.insert(scan_results, {mac = mac, name = name, is_connected = is_connected})
            end
        end
    end

    local f_bt_output = io.popen("pactl get-default-sink 2>/dev/null")
    if f_bt_output then
        local output = f_bt_output:read("*a")
        local raw_mac = output:match("bluez_output%.([%w_]+)%.")
        if raw_mac then
            local active_audio_mac = raw_mac:gsub("_", ":")
            device_name = connected_devices[active_audio_mac].name
        end
    end

    return powered, connected, device_name, scan_results
end

function bluetooth.listen(cmd)
    if cmd.action == "power" then
        if cmd.value == "on" then
            os.execute("bluetoothctl power on 2>/dev/null &")
        else
            os.execute("bluetoothctl power off 2>/dev/null &")
        end
    end
    if cmd.action == "scan" then
        os.execute("bluetoothctl --timeout 10 scan on >/dev/null 2>&1 &")
    end
    if cmd.action == "connect" then
        os.execute("bluetoothctl connect " .. cmd.mac .. " >/dev/null 2>&1 &")
    end
    if cmd.action == "disconnect" then
        os.execute("bluetoothctl disconnect " .. cmd.mac .. " >/dev/null 2>&1 &")
    end
    if cmd.action == "forget" then
        os.execute("bluetoothctl remove " .. cmd.mac .. " >/dev/null 2>&1 &")
    end
end

return bluetooth