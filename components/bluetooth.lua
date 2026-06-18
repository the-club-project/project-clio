local bluetooth = {}

function bluetooth.info()
    local powered = false
    local connected = false
    local device_name = ""
    local scan_results = {}

    local f_show = io.popen("bluetoothctl show 2>/dev/null")
    if f_show then
        local output = f_show:read("*all")
        f_show:close()
        if output:find("Powered: yes") then
            powered = true
        end
    end

    if powered then
        local f_info = io.popen("bluetoothctl info 2>/dev/null")
        if f_info then
            local output = f_info:read("*a")
            if output and output:find("Device") then
                connected = true
                device_name = output:match("Name: ([^\n]+)")
            end
        end
    end

    local f_devices = io.popen("bluetoothctl devices Paired 2>/dev/null")
    if f_devices then
        for line in f_devices:lines() do
            local mac, name = line:match("Device ([%w:]+) (.*)")
            if mac and name then
                if name ~= device_name then
                    table.insert(scan_results, {mac = mac, name = name})
                end
            end
        end
    end

    return powered, connected, device_name, scan_results
end

return bluetooth